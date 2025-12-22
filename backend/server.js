const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const serviceAccount = require('./serviceAccountKey.json');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
    console.log(`[REQUEST] ${req.method} ${req.url}`);
    next();
});

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// API Endpoints

// GET /api/listings
// Returns a list of all listings (filtered by category and city)
// GET /api/listings
// Returns a list of all listings (filtered by category, city, and advanced filters)
app.get('/api/listings', async (req, res) => {
    try {
        const {
            city,
            category,
            ownerId,
            sortBy, // 'compatibility' or default
            userId, // Required for compatibility score
            // Premium Filters
            gender,
            hasPet,
            roomCount
        } = req.query;

        let query = db.collection('listings');

        // Basic Filters
        if (category) {
            query = query.where('category', '==', category);
        }
        if (city && city !== 'Tümü' && city !== 'All') {
            query = query.where('city', '==', city);
        }
        if (ownerId) {
            query = query.where('ownerId', '==', ownerId);
        }
        // Basic filter for roomCount accessible to everyone
        if (roomCount) {
            query = query.where('roomCount', '==', roomCount);
        }

        const snapshot = await query.get();
        let listings = [];

        // Fetch User for Premium Check & Compatibility
        let currentUser = null;
        if (userId) {
            const userDoc = await db.collection('users').doc(userId).get();
            if (userDoc.exists) {
                currentUser = userDoc.data();
            }
        }

        const isPremium = currentUser && currentUser.isPremium === true;

        for (const doc of snapshot.docs) {
            const data = doc.data();

            // --- PREMIUM FILTER CHECKS ---
            // If premium filters are requested but user is not premium, we ignore them (or could return error)
            // Here we only apply them if user IsPremium to enforce access control logic on server side too,
            // or simply allow them but frontend hides UI. Better to be permissive here for simplicity, 
            // OR strict. Let's strictly apply filters if params exist, but only valid if logic allows.
            // Requirement: "Restrict access...". 

            // Actually, usually we filter in Query if possible, but Firestore has limitations on multiple fields.
            // We'll filter in memory for complex attributes.

            let include = true;

            // Strict Premium Filters
            if (!isPremium && (gender || hasPet)) {
                // Non-premium users cannot use these filters. 
                // We decide: return error OR ignore filters. ignoring is friendlier.
                // For now, let's ignore them.
            } else if (isPremium) {
                if (gender) {
                    // Check listing owner's gender (need to fetch owner? or listing has ownerDetails?)
                    // Listing usually doesn't have owner gender. 
                    // Optimization: We need to fetch owner details for granular filtering which is expensive.
                    // Alternative: when creating listing, put ownerGender in listing.
                    // For now, we'll assume we skip this or fetch owner. Fetching owner for every listing is bad.
                    // Let's assume listing has 'ownerGender' if we updated it, OR we skip for now.
                    // Plan: We'll skip complex gender filtering on existing data unless we update listings.
                }
                if (hasPet === 'true') {
                    if (data.petsAllowed !== true) include = false;
                } else if (hasPet === 'false') {
                    if (data.petsAllowed !== false) include = false;
                }
            }

            if (include) {
                let compatibilityScore = 0;

                // --- COMPATIBILITY SCORING (For Ranking) ---
                if (userId && currentUser) {
                    // 1. Department Match
                    // We need owner's data. 
                    // Optimization: Store minimal owner info in listing or fetch efficiently.
                    // Since this is a prototype/small scale, we will fetch owner for Top N or just fetch.
                    // PROTOTYPE APPROACH: We will fetch owner data for all filtered results (careful with reads).

                    // To avoid N+1 reads, maybe we rely on what's in listing or just basic scoring on listing attributes.
                    // Requirement says: "match user profile with ... listing owner profile".

                    // Let's do a quick fetch of owner if we are sorting by compatibility.
                    if (sortBy === 'compatibility') {
                        /* 
                           For efficient batching, we should get all ownerIds and fetchAll, 
                           but for this task we'll do it individually or assume small dataset.
                        */
                        const ownerDoc = await db.collection('users').doc(data.ownerId).get();
                        if (ownerDoc.exists) {
                            const owner = ownerDoc.data();

                            // Department Match (+50)
                            if (currentUser.department && owner.department &&
                                currentUser.department.toLowerCase() === owner.department.toLowerCase()) {
                                compatibilityScore += 50;
                            }

                            // University Match (+30)
                            if (currentUser.university && owner.university &&
                                currentUser.university.toLowerCase() === owner.university.toLowerCase()) {
                                compatibilityScore += 30;
                            }

                            // Gender Preference/Match (Optional bonus +10)
                            if (currentUser.gender && owner.gender &&
                                currentUser.gender === owner.gender) {
                                compatibilityScore += 10;
                            }
                        }
                    }
                }

                listings.push({
                    id: doc.id,
                    ...data,
                    compatibilityScore
                });
            }
        }

        // Sorting
        if (sortBy === 'compatibility') {
            listings.sort((a, b) => b.compatibilityScore - a.compatibilityScore);
        } else {
            // Default sort: newest first (if not already by query, but Firestore query didn't sort)
            listings.sort((a, b) => {
                const tA = a.createdAt ? (a.createdAt._seconds || 0) : 0;
                const tB = b.createdAt ? (b.createdAt._seconds || 0) : 0;
                return tB - tA;
            });
        }

        res.json(listings);
    } catch (error) {
        console.error('Error fetching listings:', error);
        res.status(500).json({ error: 'Failed to fetch listings' });
    }
});

// POST /api/listings
// Create a new listing
app.post('/api/listings', async (req, res) => {
    try {
        const data = req.body;
        // Add server timestamps
        const now = admin.firestore.FieldValue.serverTimestamp();
        const docRef = await db.collection('listings').add({
            ...data,
            createdAt: now,
            updatedAt: now
        });

        // Premium Notification Trigger
        // Find matching premium users with active subscriptions
        try {
            const category = data.category;
            const city = data.city;
            // Additional matching fields
            // const district = data.district; // Need to add district to listing creation if we want to filter by it
            const type = data.category; // 'apartment', 'dormitory', etc.

            let subscriptionsQuery = db.collection('alert_subscriptions')
                .where('isActive', '==', true);

            // We can't do complex ORs easily, so we fetch potential matches
            // Filters: City AND Category basically.

            // Optimization: Filter in memory for granular matches
            const subsSnapshot = await subscriptionsQuery.get();

            const nowTime = new Date();

            for (const doc of subsSnapshot.docs) {
                const sub = doc.data();

                // 1. Check Expiry
                let expiryDate;
                if (sub.expiresAt) {
                    if (sub.expiresAt.toDate) expiryDate = sub.expiresAt.toDate();
                    else if (typeof sub.expiresAt === 'string') expiryDate = new Date(sub.expiresAt);
                }

                if (expiryDate && expiryDate < nowTime) continue; // Expired

                // 2. Check Criteria Match
                // Required: City
                if (sub.city && sub.city !== city) continue;

                // Required: Store Type/Category
                if (sub.category && sub.category !== category) continue;

                // Optional: Rooms? Price? (Not requested but good to have)

                // 3. Check User Premium Status
                const userId = sub.userId;
                const userDoc = await db.collection('users').doc(userId).get();
                if (!userDoc.exists) continue;
                const user = userDoc.data();

                if (user.isPremium === true) {
                    // Create Notification
                    await db.collection('notifications').add({
                        userId: userId,
                        type: 'new_listing_match',
                        title: 'Yeni İlan Eşleşmesi!',
                        body: `${data.city} konumunda aradığınız kriterlere uygun yeni bir ilan var: ${data.title}`,
                        listingId: docRef.id,
                        listingData: {
                            title: data.title,
                            price: data.price,
                            city: data.city,
                            imageUrl: data.imageUrl
                        },
                        isRead: false,
                        createdAt: admin.firestore.FieldValue.serverTimestamp()
                    });

                    console.log(`🔔 Notification created for User ${userId} for Listing ${docRef.id}`);
                }
            }

        } catch (notifError) {
            console.error('Error sending notifications:', notifError);
            // Don't fail the listing creation if notifications fail
        }

        res.status(201).json({ id: docRef.id, message: 'Listing created successfully' });
    } catch (error) {
        console.error('Error creating listing:', error);
        res.status(500).json({ error: 'Failed to create listing' });
    }
});

// PUT /api/listings/:id
// Update an existing listing
app.put('/api/listings/:id', async (req, res) => {
    try {
        const listingId = req.params.id;
        const data = req.body;
        const now = admin.firestore.FieldValue.serverTimestamp();

        await db.collection('listings').doc(listingId).update({
            ...data,
            updatedAt: now
        });
        res.json({ message: 'Listing updated successfully' });
    } catch (error) {
        console.error('Error updating listing:', error);
        res.status(500).json({ error: 'Failed to update listing' });
    }
});

// DELETE /api/listings/:id
// Delete a listing
app.delete('/api/listings/:id', async (req, res) => {
    try {
        const listingId = req.params.id;
        await db.collection('listings').doc(listingId).delete();
        res.json({ message: 'Listing deleted successfully' });
    } catch (error) {
        console.error('Error deleting listing:', error);
        res.status(500).json({ error: 'Failed to delete listing' });
    }
});


// --- USERS ---

// POST /api/users
// Create or Update user (Registration)
app.post('/api/users', async (req, res) => {
    try {
        const { uid, ...data } = req.body;
        if (!uid) return res.status(400).json({ error: 'UID is required' });

        const now = admin.firestore.FieldValue.serverTimestamp();
        await db.collection('users').doc(uid).set({
            ...data,
            createdAt: now,
            updatedAt: now
        }, { merge: true });

        res.status(201).json({ message: 'User created/updated successfully' });
    } catch (error) {
        console.error('Error creating user:', error);
        res.status(500).json({ error: 'Failed to create user' });
    }
});

// POST /api/payment/premium
// Upgrade user to premium
app.post('/api/payment/premium', async (req, res) => {
    try {
        const { userId, amount } = req.body;

        if (!userId) return res.status(400).json({ error: 'userId is required' });

        // Mock Payment Verification
        // In real app, verify Stripe/Iyzico/Apple token here.
        if (amount !== 10) {
            // For demo, just warning, or you could enforce checks
        }

        const now = admin.firestore.FieldValue.serverTimestamp();

        // Update User
        await db.collection('users').doc(userId).update({
            isPremium: true,
            premiumSince: now,
            updatedAt: now
        });

        res.json({ success: true, message: 'Premium membership activated!' });
    } catch (error) {
        console.error('Error processing premium payment:', error);
        res.status(500).json({ error: 'Payment failed' });
    }
});

// Mock Cancel Subscription Endpoint
app.post('/api/payment/cancel', async (req, res) => {
    try {
        const { userId } = req.body;
        console.log(`Processing cancellation for ${userId}`);

        if (!userId) {
            return res.status(400).json({ error: 'UserId is required' });
        }
        const now = admin.firestore.FieldValue.serverTimestamp();
        // Use set with merge to avoiding crashing if doc doesn't exist
        await db.collection('users').doc(userId).set({
            isPremium: false,
            premiumSince: null,
            updatedAt: now
        }, { merge: true });

        res.json({ success: true, message: 'Premium cancelled' });
    } catch (error) {
        console.error('Cancellation error:', error);
        res.status(500).json({ error: 'Cancellation failed' });
    }
});


// GET /api/users/:id
// Get user profile
app.get('/api/users/:id', async (req, res) => {
    try {
        const uid = req.params.id;
        const doc = await db.collection('users').doc(uid).get();
        if (!doc.exists) {
            return res.status(404).json({ error: 'User not found' });
        }
        res.json(doc.data());
    } catch (error) {
        console.error('Error fetching user:', error);
        res.status(500).json({ error: 'Failed to fetch user' });
    }
});

// PUT /api/users/:id
// Update user profile
app.put('/api/users/:id', async (req, res) => {
    try {
        const uid = req.params.id;
        const data = req.body;
        const now = admin.firestore.FieldValue.serverTimestamp();

        await db.collection('users').doc(uid).update({
            ...data,
            updatedAt: now
        });
        res.json({ message: 'User updated successfully' });
    } catch (error) {
        console.error('Error updating user:', error);
        res.status(500).json({ error: 'Failed to update user' });
    }
});

// --- MESSAGING ---

// GET /api/conversations
// Get conversations for a user (Requires userId query param)
app.get('/api/conversations', async (req, res) => {
    try {
        const { userId } = req.query;
        if (!userId) return res.status(400).json({ error: 'userId query param required' });

        const snapshot = await db.collection('conversations')
            .where('members', 'array-contains', userId)
            // .orderBy('updatedAt', 'desc') // Requires index, filtering in memory for now
            .get();

        const conversations = [];
        snapshot.forEach(doc => {
            conversations.push({ id: doc.id, ...doc.data() });
        });

        // Sort in memory
        conversations.sort((a, b) => {
            const tA = a.updatedAt ? (a.updatedAt._seconds || a.updatedAt.seconds || 0) : 0;
            const tB = b.updatedAt ? (b.updatedAt._seconds || b.updatedAt.seconds || 0) : 0;
            return tB - tA;
        });

        res.json(conversations);
    } catch (error) {
        console.error('Error fetching conversations:', error);
        res.status(500).json({ error: 'Failed to fetch conversations' });
    }
});

// GET /api/conversations/:id/messages
// Get messages for a conversation
app.get('/api/conversations/:id/messages', async (req, res) => {
    try {
        const conversationId = req.params.id;
        const snapshot = await db.collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .orderBy('createdAt', 'desc')
            .limit(200)
            .get();

        const messages = [];
        snapshot.forEach(doc => {
            messages.push({ id: doc.id, ...doc.data() });
        });
        // Reverse needed if client expects chronological, but listview.builder reverse=true usually expects desc order
        // We send as is (descending)
        res.json(messages);
    } catch (error) {
        console.error('Error fetching messages:', error);
        res.status(500).json({ error: 'Failed to fetch messages' });
    }
});

// POST /api/conversations/:id/messages
// Send a message
app.post('/api/conversations/:id/messages', async (req, res) => {
    try {
        const conversationId = req.params.id;
        const { senderId, text, members: providedMembers } = req.body;

        const convoRef = db.collection('conversations').doc(conversationId);

        // Check if exists, if not create (for first message flow)
        const convoDoc = await convoRef.get();
        let members = [];

        if (!convoDoc.exists && providedMembers) {
            // First message, create conversation
            members = providedMembers;
            const now = admin.firestore.FieldValue.serverTimestamp();
            await convoRef.set({
                members,
                createdAt: now,
                updatedAt: now,
                lastMessage: text,
                unreadCount: {}
            });
        } else if (convoDoc.exists) {
            members = convoDoc.data().members || [];
        }

        // Add message
        const now = admin.firestore.FieldValue.serverTimestamp();
        await convoRef.collection('messages').add({
            senderId,
            text,
            createdAt: now
        });

        // Update conversation
        const updateData = {
            updatedAt: now,
            lastMessage: text
        };

        // Increment unread count for other members
        members.forEach(memberId => {
            if (memberId !== senderId) {
                updateData[`unreadCount.${memberId}`] = admin.firestore.FieldValue.increment(1);
            }
        });

        await convoRef.update(updateData);

        res.status(201).json({ message: 'Message sent successfully' });
    } catch (error) {
        console.error('Error sending message:', error);
        res.status(500).json({ error: 'Failed to send message' });
    }
});

// POST /api/conversations/:id/mark-read
// Mark conversation as read for a user
app.post('/api/conversations/:id/mark-read', async (req, res) => {
    try {
        const conversationId = req.params.id;
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'userId is required' });
        }

        const convoRef = db.collection('conversations').doc(conversationId);
        // Use set with merge to avoid errors if unreadCount map is missing
        await convoRef.set({
            [`unreadCount.${userId}`]: 0
        }, { merge: true });

        res.json({ message: 'Marked as read' });
    } catch (error) {
        console.error('Error marking as read:', error);
        res.status(500).json({ error: 'Failed to mark as read' });
    }
});

// --- SUBSCRIPTIONS ---

// POST /api/subscriptions
app.post('/api/subscriptions', async (req, res) => {
    try {
        const data = req.body;
        // Ensure we use server timestamp for consistency if not provided (though client sends some, server should override/augment)
        const now = admin.firestore.FieldValue.serverTimestamp();

        // Use logic similar to what client did if needed, or trust client data.
        // Client sends full object.

        await db.collection('alert_subscriptions').add({
            ...data,
            createdAt: now
        });
        res.status(201).json({ message: 'Subscription created' });
    } catch (error) {
        console.error('Error creating subscription:', error);
        res.status(500).json({ error: 'Failed to create subscription' });
    }
});

// GET /api/subscriptions
// Check active subscriptions
app.get('/api/subscriptions', async (req, res) => {
    try {
        const { userId, criteriaKey, checkActive } = req.query;
        if (!userId) return res.status(400).json({ error: 'userId is required' });

        let query = db.collection('alert_subscriptions').where('userId', '==', userId);

        if (criteriaKey) {
            query = query.where('criteriaKey', '==', criteriaKey);
        }

        if (checkActive === 'true') {
            query = query.where('isActive', '==', true)
                .where('expiresAt', '>', admin.firestore.Timestamp.now());
        }

        const snapshot = await query.get();
        const subscriptions = [];
        snapshot.forEach(doc => {
            subscriptions.push({ id: doc.id, ...doc.data() });
        });

        res.json(subscriptions);
    } catch (error) {
        console.error('Error fetching subscriptions:', error);
        res.status(500).json({ error: 'Failed to fetch subscriptions' });
    }
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});

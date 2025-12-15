const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const serviceAccount = require('./serviceAccountKey.json');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Firebase Admin
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// API Endpoints

// GET /api/listings
// Returns a list of all listings (filtered by category and city)
app.get('/api/listings', async (req, res) => {
    try {
        const { city, category, ownerId } = req.query;
        let query = db.collection('listings');

        if (category) {
            query = query.where('category', '==', category);
        }
        if (city && city !== 'Tümü' && city !== 'All') {
            query = query.where('city', '==', city);
        }
        if (ownerId) {
            query = query.where('ownerId', '==', ownerId);
        }

        const snapshot = await query.get();
        const listings = [];
        snapshot.forEach(doc => {
            listings.push({ id: doc.id, ...doc.data() });
        });

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
        res.status(201).json({ id: docRef.id, message: 'Listing created successfully' });
    } catch (error) {
        console.error('Error creating listing:', error);
        res.status(500).json({ error: 'Failed to create listing' });
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
        const { senderId, text } = req.body;

        const convoRef = db.collection('conversations').doc(conversationId);

        // Check if exists, if not create (for first message flow)
        const convoDoc = await convoRef.get();
        let members = [];

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

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();
const firestore = admin.firestore();

/**
 * HTTPS callable endpoint that creates a new alert subscription.
 * Expects payload: { city, category, type, maxPrice }
 */
exports.createAlertSubscription = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Giriş yapmanız gerekiyor.');
  }

  const cost = 10;
  const duration = 30; // days
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + duration * 24 * 60 * 60 * 1000),
  );
  const sanitized = sanitizeCriteria(data);
  const criteriaKey = buildCriteriaKey(sanitized);

  await firestore.collection('alert_subscriptions').add({
    userId: context.auth.uid,
    criteria: sanitized,
    criteriaKey,
    city: sanitized.city || null,
    category: sanitized.category || null,
    type: sanitized.type || null,
    maxPrice: sanitized.maxPrice ?? null,
    cost,
    createdAt: admin.firestore.Timestamp.now(),
    expiresAt,
    isActive: true,
  });

  return { success: true, expiresAt };
});

/**
 * Triggered whenever a new listing is created.
 * Checks all active alert subscriptions and notifies matching users.
 */
exports.handleListingCreated = functions.firestore
  .document('listings/{listingId}')
  .onCreate(async (snap, context) => {
    const listing = snap.data();
    const listingId = context.params.listingId;
    const now = admin.firestore.Timestamp.now();

    let query = firestore
      .collection('alert_subscriptions')
      .where('isActive', '==', true)
      .where('expiresAt', '>', now);

    if (listing.city) {
      query = query.where('city', '==', listing.city);
    }
    if (listing.category) {
      query = query.where('category', '==', listing.category);
    }
    if (listing.type) {
      query = query.where('type', '==', listing.type);
    }

    const subscriptionSnapshot = await query.get();
    if (subscriptionSnapshot.empty) return null;

    const notificationWrites = [];
    subscriptionSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.maxPrice && listing.numericPrice && listing.numericPrice > data.maxPrice) {
        return;
      }
      notificationWrites.push(
        firestore.collection('notifications').add({
          userId: data.userId,
          listingId,
          listingTitle: listing.title,
          createdAt: now,
          message: `Yeni ilan: ${listing.title} (${listing.city ?? '-'})`,
          criteriaKey: data.criteriaKey,
        }),
      );
    });

    return Promise.all(notificationWrites);
  });

function sanitizeCriteria(criteria = {}) {
  const allowedKeys = ['city', 'category', 'type', 'maxPrice'];
  const sanitized = {};
  allowedKeys.forEach((key) => {
    const value = criteria[key];
    if (value === undefined || value === null) return;
    if (typeof value === 'string' && !value.trim()) return;
    sanitized[key] = key === 'maxPrice' ? Number(value) : value;
  });
  return sanitized;
}

function buildCriteriaKey(criteria) {
  const entries = Object.keys(criteria)
    .sort()
    .map((key) => [key, criteria[key]]);
  return JSON.stringify(Object.fromEntries(entries));
}


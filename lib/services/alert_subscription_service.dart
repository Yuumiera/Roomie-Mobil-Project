import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/alert_subscription.dart';

class AlertSubscriptionService {
  AlertSubscriptionService();

  static const double subscriptionCostUsd = 10;
  static const Duration subscriptionDuration = Duration(days: 30);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSubscription({required Map<String, dynamic> criteria}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Abonelik oluşturmak için giriş yapmalısınız.');
    }

    final sanitizedCriteria = _sanitizeCriteria(criteria);
    final criteriaKey = _criteriaKey(sanitizedCriteria);
    final now = Timestamp.now();

    final AlertSubscription subscription = AlertSubscription(
      id: '',
      userId: userId,
      criteria: sanitizedCriteria,
      criteriaKey: criteriaKey,
      cost: subscriptionCostUsd,
      createdAt: now,
      expiresAt: Timestamp.fromDate(DateTime.now().add(subscriptionDuration)),
      isActive: true,
      city: sanitizedCriteria['city'] as String?,
      category: sanitizedCriteria['category'] as String?,
      type: sanitizedCriteria['type'] as String?,
      maxPrice: (sanitizedCriteria['maxPrice'] as num?)?.toDouble(),
    );

    await _firestore.collection('alert_subscriptions').add(subscription.toMap());
  }

  Future<bool> hasActiveSubscription(Map<String, dynamic> criteria) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final criteriaKey = _criteriaKey(_sanitizeCriteria(criteria));
    final now = Timestamp.now();
    final snapshot = await _firestore
        .collection('alert_subscriptions')
        .where('userId', isEqualTo: userId)
        .where('criteriaKey', isEqualTo: criteriaKey)
        .where('isActive', isEqualTo: true)
        .where('expiresAt', isGreaterThan: now)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Map<String, dynamic> _sanitizeCriteria(Map<String, dynamic> criteria) {
    final sanitized = Map<String, dynamic>.from(criteria)
      ..removeWhere(
        (key, value) => value == null || (value is String && value.trim().isEmpty),
      );
    return sanitized;
  }

  String _criteriaKey(Map<String, dynamic> criteria) {
    final sorted = SplayTreeMap<String, dynamic>.from(criteria);
    return jsonEncode(sorted);
  }
}


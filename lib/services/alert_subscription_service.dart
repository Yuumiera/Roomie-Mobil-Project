import 'dart:collection';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';

class AlertSubscriptionService {
  AlertSubscriptionService();

  static const double subscriptionCostUsd = 10;
  static const Duration subscriptionDuration = Duration(days: 30);

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> createSubscription({required Map<String, dynamic> criteria}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Abonelik oluşturmak için giriş yapmalısınız.');
    }

    final sanitizedCriteria = _sanitizeCriteria(criteria);
    final criteriaKey = _criteriaKey(sanitizedCriteria);
    // dates handled by backend usually, but for expiresAt logic:
    // Backend creates 'createdAt'. But 'expiresAt' relies on duration.
    // Client should probably send 'expiresAt' or backend calculates it? 
    // Backend doesn't know about 'subscriptionDuration'.
    // So Client sends 'expiresAt'.
    // BUT we need to send it as ISO string for JSON safe transfer if backend expects date string or number.
    // FireStore timestamp is NOT json encodable directly.
    
    final now = DateTime.now();
    final expiresAt = now.add(subscriptionDuration);

    final Map<String, dynamic> subscriptionData = {
      'userId': userId,
      'criteria': sanitizedCriteria,
      'criteriaKey': criteriaKey,
      'cost': subscriptionCostUsd,
      'isActive': true,
      'city': sanitizedCriteria['city'] as String?,
      'category': sanitizedCriteria['category'] as String?,
      'type': sanitizedCriteria['type'] as String?,
      'maxPrice': (sanitizedCriteria['maxPrice'] as num?)?.toDouble(),
      // Send dates as ISO String for API compatibility
      'expiresAt': expiresAt.toIso8601String(), 
      // Backend sets createdAt
    };

    await ApiService.createSubscription(subscriptionData);
  }

  Future<bool> hasActiveSubscription(Map<String, dynamic> criteria) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final criteriaKey = _criteriaKey(_sanitizeCriteria(criteria));
    
    final subs = await ApiService.fetchSubscriptions(
      userId: userId,
      criteriaKey: criteriaKey,
      checkActive: true,
    );
    
    return subs.isNotEmpty;
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


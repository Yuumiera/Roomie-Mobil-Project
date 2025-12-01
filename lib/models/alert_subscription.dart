import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class AlertSubscription {
  AlertSubscription({
    required this.id,
    required this.userId,
    required this.criteria,
    required this.criteriaKey,
    required this.cost,
    required this.expiresAt,
    required this.isActive,
    required this.createdAt,
    this.city,
    this.category,
    this.type,
    this.maxPrice,
  });

  final String id;
  final String userId;
  final Map<String, dynamic> criteria;
  final String criteriaKey;
  final double cost;
  final Timestamp expiresAt;
  final Timestamp createdAt;
  final bool isActive;
  final String? city;
  final String? category;
  final String? type;
  final double? maxPrice;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'criteria': criteria,
      'criteriaKey': criteriaKey,
      'cost': cost,
      'expiresAt': expiresAt,
      'createdAt': createdAt,
      'isActive': isActive,
      'city': city,
      'category': category,
      'type': type,
      'maxPrice': maxPrice,
    }..removeWhere((key, value) => value == null);
  }

  factory AlertSubscription.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AlertSubscription(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      criteria: Map<String, dynamic>.from(data['criteria'] as Map? ?? {}),
      criteriaKey: data['criteriaKey'] as String? ?? '',
      cost: (data['cost'] as num?)?.toDouble() ?? 0,
      expiresAt: data['expiresAt'] as Timestamp? ?? Timestamp.now(),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      isActive: data['isActive'] as bool? ?? false,
      city: data['city'] as String?,
      category: data['category'] as String?,
      type: data['type'] as String?,
      maxPrice: (data['maxPrice'] as num?)?.toDouble(),
    );
  }

  static String criteriaKeyFrom(Map<String, dynamic> criteria) {
    final cleaned = Map<String, dynamic>.from(criteria)
      ..removeWhere(
        (key, value) => value == null || (value is String && value.trim().isEmpty),
      );
    final sorted = SplayTreeMap<String, dynamic>.from(cleaned);
    return jsonEncode(sorted);
  }
}


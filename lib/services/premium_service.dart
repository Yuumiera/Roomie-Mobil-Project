import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class PremiumService {
  static String get _baseUrl => ApiService.baseUrl;

  
  static Future<bool> upgradeToPremium(String userId) async {
    final url = Uri.parse('$_baseUrl/api/payment/premium');
    debugPrint('🔌 PREMIUM REQUEST TO: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'amount': 10,
          'currency': 'USD',
        }),
      );

      debugPrint('📡 RESPONSE CODE: ${response.statusCode}');
      debugPrint('📦 RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('❌ Premium failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('💥 Error upgrading to premium: $e');
      return false;
    }
  }


  
  static Future<bool> cancelSubscription(String userId) async {
    final url = Uri.parse('$_baseUrl/api/payment/cancel'); 
    debugPrint('🔌 CANCEL PREMIUM REQUEST TO: $url');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      debugPrint('📡 RESPONSE CODE: ${response.statusCode}');

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('❌ Cancel failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('💥 Error cancelling premium: $e');
      return false;
    }
  }
}

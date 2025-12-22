import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/chat_model.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web
  static String get baseUrl {
    // Local Development (Android Emulator)
    // return 'http://10.0.2.2:3000';
    // Production URL (Render.com)
    return 'https://roomie-mobil-project.onrender.com';
  }

  // --- LISTINGS ---

  static Future<List<Map<String, dynamic>>> fetchListings({
    String? city,
    String category = 'apartment',
    String? ownerId,
    String? sortBy, // 'compatibility'
    String? userId, // for compatibility scoring
    // Advanced Filters
    String? gender,
    bool? hasPet,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        if (category.isNotEmpty) 'category': category,
        if (city != null && city != 'Tümü') 'city': city,
        if (ownerId != null) 'ownerId': ownerId,
        if (sortBy != null) 'sortBy': sortBy,
        if (userId != null) 'userId': userId,
        if (gender != null) 'gender': gender,
        if (hasPet != null) 'hasPet': hasPet.toString(),
      };

      final uri = Uri.parse('$baseUrl/api/listings').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load listings: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching listings: $e');
      rethrow;
    }
  }

  static Future<void> createListing(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/listings');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create listing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating listing: $e');
      rethrow;
    }
  }

  static Future<void> updateListing(String listingId, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/listings/$listingId');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update listing: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating listing: $e');
      rethrow;
    }
  }

  static Future<void> deleteListing(String listingId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/listings/$listingId');
      debugPrint('🌐 DELETE URL: $uri');
      
      final response = await http.delete(uri);
      debugPrint('📡 DELETE Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ DELETE failed: ${response.body}');
        throw Exception('Failed to delete listing: ${response.statusCode}');
      }
      debugPrint('✅ DELETE successful');
    } catch (e) {
      debugPrint('💥 DELETE exception: $e');
      rethrow;
    }
  }

  // --- USERS ---

  static Future<void> createUser(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchUser(String uid) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$uid');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
      rethrow;
    }
  }

  static Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/users/$uid');
      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // --- MESSAGING ---

  static Future<List<Chat>> fetchConversations(String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/conversations').replace(queryParameters: {'userId': userId});
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Chat.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations');
      }
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMessages(String conversationId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/conversations/$conversationId/messages');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      rethrow;
    }
  }

  static Future<void> sendMessage(String conversationId, String senderId, String text, [List<String>? members]) async {
    try {
      final uri = Uri.parse('$baseUrl/api/conversations/$conversationId/messages');
      final body = {
        'senderId': senderId,
        'text': text,
        if (members != null) 'members': members,
      };
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  static Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      final uri = Uri.parse('$baseUrl/api/conversations/$conversationId/mark-read');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to mark as read');
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
      rethrow;
    }
  }

  // --- SUBSCRIPTIONS ---

  static Future<void> createSubscription(Map<String, dynamic> data) async {
    try {
      final uri = Uri.parse('$baseUrl/api/subscriptions');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 201) {
        throw Exception('Failed to create subscription');
      }
    } catch (e) {
      debugPrint('Error creating subscription: $e');
      rethrow;
    }
  }
  static Future<List<Map<String, dynamic>>> fetchSubscriptions({
    required String userId,
    String? criteriaKey,
    bool checkActive = false,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'userId': userId,
        if (criteriaKey != null) 'criteriaKey': criteriaKey,
        if (checkActive) 'checkActive': 'true',
      };
      
      final uri = Uri.parse('$baseUrl/api/subscriptions').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch subscriptions');
      }
    } catch (e) {
      debugPrint('Error fetching subscriptions: $e');
      rethrow;
    }
  }
}

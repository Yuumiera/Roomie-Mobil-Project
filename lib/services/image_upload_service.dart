import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ImageUploadService {
  /// Upload multiple images via backend to Firebase Storage
  /// Returns list of download URLs
  static Future<List<String>> uploadImages(List<String> imagePaths, String userId) async {
    try {
      // Convert images to base64
      List<String> base64Images = [];
      for (String imagePath in imagePaths) {
        final File imageFile = File(imagePath);
        final bytes = await imageFile.readAsBytes();
        final base64String = base64Encode(bytes);
        base64Images.add('data:image/jpeg;base64,$base64String');
      }

      // Send to backend
      final url = Uri.parse('${ApiService.baseUrl}/api/upload-images');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'images': base64Images,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<String> imageUrls = List<String>.from(data['imageUrls']);
        debugPrint('✅ ${imageUrls.length} images uploaded successfully');
        return imageUrls;
      } else {
        throw Exception('Failed to upload images: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ Image upload error: $e');
      rethrow;
    }
  }

  /// Delete images (not implemented yet)
  static Future<void> deleteImages(List<String> imageUrls) async {
    // TODO: Add backend endpoint for deletion if needed
    debugPrint('Delete images: $imageUrls');
  }
}

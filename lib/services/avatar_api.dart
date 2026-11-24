import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AvatarService {
  static const _avatarKey = 'avatar_path';
  static const _avatarUrlKey = 'avatar_url'; // Store the original URL for comparison
  static const _defaultAvatarUrl = 'https://i.pravatar.cc/300';

  // Save a new avatar image from camera/gallery
  static Future<void> saveAvatar(File imageFile) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();

      // Get the application documents directory
      final dir = await getApplicationDocumentsDirectory();

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'profile_avatar_$timestamp.png';
      final filePath = '${dir.path}/$fileName';

      // Copy the image file to the app directory
      final newFile = await imageFile.copy(filePath);

      // Save the path to shared preferences
      await prefs.setString(_avatarKey, newFile.path);

      debugPrint('Avatar saved to: ${newFile.path}');
    } catch (e) {
      debugPrint('Error saving avatar: $e');
      throw Exception('Failed to save avatar locally');
    }
  }

  // Get avatar - priority: local file > network URL
  static Future<File?> getAvatar() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? localPath = prefs.getString(_avatarKey);

      // Check if local file exists
      if (localPath != null) {
        final localFile = File(localPath);
        if (await localFile.exists()) {
          return localFile;
        } else {
          // Local file doesn't exist, clear the path
          await prefs.remove(_avatarKey);
        }
      }

      // No local file, return null (ProfileScreen will use network image)
      return null;
    } catch (e) {
      debugPrint('Error getting avatar: $e');
      return null;
    }
  }

  // Delete local avatar
  static Future<void> deleteAvatar() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? localPath = prefs.getString(_avatarKey);

      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
        await prefs.remove(_avatarKey);
        debugPrint('Local avatar deleted');
      }
    } catch (e) {
      debugPrint('Error deleting avatar: $e');
      throw Exception('Failed to delete local avatar');
    }
  }

  // Check if we have a local avatar
  static Future<bool> hasLocalAvatar() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? localPath = prefs.getString(_avatarKey);

      if (localPath != null) {
        final file = File(localPath);
        return await file.exists();
      }
      return false;
    } catch (e) {
      debugPrint('Error checking local avatar: $e');
      return false;
    }
  }

  // Get local avatar path (for debugging)
  static Future<String?> getLocalAvatarPath() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_avatarKey);
  }

  // Download default avatar (original functionality)
  static Future<File?> downloadDefaultAvatar() async {
    try {
      final response = await http.get(Uri.parse(_defaultAvatarUrl));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'default_avatar.png';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(_avatarKey, file.path);

        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error downloading default avatar: $e');
      return null;
    }
  }

  // Clear all avatar data
  static Future<void> clearAll() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? localPath = prefs.getString(_avatarKey);

      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await prefs.remove(_avatarKey);
      await prefs.remove(_avatarUrlKey);

      debugPrint('All avatar data cleared');
    } catch (e) {
      debugPrint('Error clearing avatar data: $e');
      throw Exception('Failed to clear avatar data');
    }
  }
}
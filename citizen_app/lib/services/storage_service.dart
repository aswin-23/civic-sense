import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  // Upload image file to Firebase Storage
  Future<String> uploadImage(File imageFile, {String? folder}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final fileExtension = path.extension(imageFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      
      // Create reference
      final ref = _storage
          .ref()
          .child(folder ?? 'complaints')
          .child(user.uid)
          .child(fileName);

      // Upload file
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Upload multiple images
  Future<List<String>> uploadImages(List<File> imageFiles, {String? folder}) async {
    final List<String> urls = [];
    
    for (final imageFile in imageFiles) {
      try {
        final url = await uploadImage(imageFile, folder: folder);
        urls.add(url);
      } catch (e) {
        print('Failed to upload image: $e');
        // Continue with other images
      }
    }
    
    return urls;
  }

  // Upload video file
  Future<String> uploadVideo(File videoFile, {String? folder}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Generate unique filename
      final fileExtension = path.extension(videoFile.path);
      final fileName = '${_uuid.v4()}$fileExtension';
      
      // Create reference
      final ref = _storage
          .ref()
          .child(folder ?? 'complaints')
          .child(user.uid)
          .child('videos')
          .child(fileName);

      // Upload file
      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload video: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Failed to delete file: $e');
    }
  }

  // Get file metadata
  Future<FullMetadata> getFileMetadata(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      return await ref.getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  // Check if file exists
  Future<bool> fileExists(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get storage usage for user
  Future<int> getUserStorageUsage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return 0;
      }

      final ref = _storage.ref().child('complaints').child(user.uid);
      final result = await ref.listAll();
      
      int totalSize = 0;
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }
      
      return totalSize;
    } catch (e) {
      print('Failed to get storage usage: $e');
      return 0;
    }
  }

  // Clean up old files (for admin use)
  Future<void> cleanupOldFiles({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final ref = _storage.ref().child('complaints');
      final result = await ref.listAll();
      
      for (final item in result.items) {
        final metadata = await item.getMetadata();
        if (metadata.timeCreated != null && 
            metadata.timeCreated!.isBefore(cutoffDate)) {
          await item.delete();
        }
      }
    } catch (e) {
      print('Failed to cleanup old files: $e');
    }
  }

  // Generate thumbnail for video (placeholder - would need video processing)
  Future<String> generateVideoThumbnail(File videoFile) async {
    // This would require video processing library
    // For now, return a placeholder
    throw UnimplementedError('Video thumbnail generation not implemented');
  }

  // Compress image before upload
  Future<File> compressImage(File imageFile, {int quality = 85}) async {
    // This would require image compression library
    // For now, return original file
    return imageFile;
  }

  // Validate file type
  bool isValidImageFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  bool isValidVideoFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension);
  }

  // Get file size in MB
  double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is within limits
  bool isFileSizeValid(File file, {double maxSizeMB = 10.0}) {
    return getFileSizeInMB(file) <= maxSizeMB;
  }
}

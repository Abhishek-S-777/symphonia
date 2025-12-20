import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../theme/app_colors.dart';

/// Profile Service Provider
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

/// Profile Image Cache Provider
final profileImageCacheProvider = Provider<ProfileImageCache>((ref) {
  return ProfileImageCache();
});

/// Profile Service for handling profile image operations
class ProfileService {
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Pick image from source and optionally crop it
  Future<File?> pickImage(ImageSource source) async {
    try {
      debugPrint('ProfileService: Picking image from $source');

      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        debugPrint('ProfileService: No image picked');
        return null;
      }

      debugPrint('ProfileService: Image picked: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('ProfileService: Error picking image: $e');
      return null;
    }
  }

  /// Crop an image file
  Future<File?> cropImage(File imageFile, BuildContext context) async {
    debugPrint('ProfileService: Starting crop for: ${imageFile.path}');
    debugPrint('ProfileService: File exists: ${imageFile.existsSync()}');

    try {
      final cropper = ImageCropper();

      final croppedFile = await cropper.cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: const Color(0xFF2D2D2D), // Dark gray toolbar
            toolbarWidgetColor: Colors.white,
            backgroundColor: const Color(0xFF121212), // Dark background
            activeControlsWidgetColor: AppColors.primary,
            dimmedLayerColor: Colors.black.withValues(alpha: 0.8),
            cropFrameColor: AppColors.white,
            cropGridColor: Colors.white.withValues(alpha: 0.5),
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            showCropGrid: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        debugPrint('ProfileService: Cropped successfully: ${croppedFile.path}');
        return File(croppedFile.path);
      }

      debugPrint('ProfileService: User cancelled cropping, using original');
      return imageFile; // Return original if user cancels crop
    } catch (e, stackTrace) {
      debugPrint('ProfileService: Crop error: $e');
      debugPrint('ProfileService: Stack trace: $stackTrace');
      // Return original image if cropping fails
      return imageFile;
    }
  }

  /// Show image source picker bottom sheet
  /// Returns the selected and cropped image, or null if cancelled
  Future<File?> pickAndCropImage(BuildContext context) async {
    File? result;

    // Step 1: Show source picker
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      enableDrag: false,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Text(
              'Choose Photo',
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceButton(
                  context: ctx,
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
                _buildSourceButton(
                  context: ctx,
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (source == null) {
      debugPrint('ProfileService: Source selection cancelled');
      return null;
    }

    debugPrint('ProfileService: Selected source: $source');

    // Step 2: Pick image
    final pickedImage = await pickImage(source);
    if (pickedImage == null) {
      return null;
    }

    // Step 3: Crop image (if context is still mounted)
    if (context.mounted) {
      result = await cropImage(pickedImage, context);
    } else {
      result = pickedImage;
    }

    debugPrint('ProfileService: Final result: ${result?.path}');
    return result;
  }

  Widget _buildSourceButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  /// Upload profile image to Firebase Storage
  Future<String?> uploadProfileImage({
    required File imageFile,
    required String userId,
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('ProfileService: Uploading image for user $userId');

      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to progress
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        debugPrint(
          'ProfileService: Upload progress: ${(progress * 100).toInt()}%',
        );
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('ProfileService: Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('ProfileService: Error uploading image: $e');
      return null;
    }
  }

  /// Delete old profile image from storage
  Future<void> deleteProfileImage(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return;

    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      debugPrint('ProfileService: Deleted old image');
    } catch (e) {
      debugPrint('ProfileService: Error deleting image: $e');
    }
  }
}

/// Profile Image Cache
class ProfileImageCache {
  static const String _cacheKeyPrefix = 'profile_image_cache_';
  static const String _cacheUrlPrefix = 'profile_image_url_';

  Future<File?> getCachedImage(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('$_cacheKeyPrefix$userId');

      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          return file;
        }
      }
    } catch (e) {
      debugPrint('ProfileImageCache: Error getting cached image: $e');
    }
    return null;
  }

  Future<String?> getCachedUrl(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_cacheUrlPrefix$userId');
  }

  Future<File?> cacheImageFromUrl({
    required String userId,
    required String photoUrl,
  }) async {
    try {
      final cachedUrl = await getCachedUrl(userId);
      if (cachedUrl == photoUrl) {
        final cachedFile = await getCachedImage(userId);
        if (cachedFile != null) return cachedFile;
      }

      final response = await http.get(Uri.parse(photoUrl));
      if (response.statusCode != 200) return null;

      final cacheDir = await getTemporaryDirectory();
      final fileName = 'profile_$userId.jpg';
      final file = File('${cacheDir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_cacheKeyPrefix$userId', file.path);
      await prefs.setString('$_cacheUrlPrefix$userId', photoUrl);

      return file;
    } catch (e) {
      debugPrint('ProfileImageCache: Error caching image: $e');
      return null;
    }
  }

  Future<void> invalidateCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedPath = prefs.getString('$_cacheKeyPrefix$userId');

      if (cachedPath != null) {
        final file = File(cachedPath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      await prefs.remove('$_cacheKeyPrefix$userId');
      await prefs.remove('$_cacheUrlPrefix$userId');
    } catch (e) {
      debugPrint('ProfileImageCache: Error invalidating cache: $e');
    }
  }
}

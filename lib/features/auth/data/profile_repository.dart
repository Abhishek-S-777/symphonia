import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:symphonia/core/logging/app_logger.dart';
import 'package:symphonia/core/providers/firebase_providers.dart';
import 'package:symphonia/core/theme/app_colors.dart';
import 'package:uuid/uuid.dart';

/// Profile Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(storage: ref.watch(firebaseStorageProvider));
});

/// Profile Image Cache Provider
final profileImageCacheProvider = Provider<ProfileImageCache>((ref) {
  return ProfileImageCache();
});

/// Repository for profile image operations.
class ProfileRepository {
  ProfileRepository({required FirebaseStorage storage}) : _storage = storage;

  final _picker = ImagePicker();
  final FirebaseStorage _storage;
  final _uuid = const Uuid();

  /// Pick image from source and optionally crop it
  Future<File?> pickImage(ImageSource source) async {
    try {
      AppLogger.debug('ProfileRepository: Picking image from $source');

      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        AppLogger.debug('ProfileRepository: No image picked');
        return null;
      }

      AppLogger.debug('ProfileRepository: Image picked: ${pickedFile.path}');
      return File(pickedFile.path);
    } catch (e) {
      AppLogger.error('ProfileRepository: Error picking image', error: e);
      return null;
    }
  }

  /// Crop an image file
  Future<File?> cropImage(File imageFile, BuildContext context) async {
    AppLogger.debug('ProfileRepository: Starting crop for: ${imageFile.path}');
    AppLogger.debug(
      'ProfileRepository: File exists: ${imageFile.existsSync()}',
    );

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
        AppLogger.info(
          'ProfileRepository: Cropped successfully: ${croppedFile.path}',
        );
        return File(croppedFile.path);
      }

      AppLogger.debug(
        'ProfileRepository: User cancelled cropping, using original',
      );
      return imageFile; // Return original if user cancels crop
    } catch (e, stackTrace) {
      AppLogger.error(
        'ProfileRepository: Crop error',
        error: e,
        stackTrace: stackTrace,
      );
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
      AppLogger.debug('ProfileRepository: Source selection cancelled');
      return null;
    }

    AppLogger.debug('ProfileRepository: Selected source: $source');

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

    AppLogger.debug('ProfileRepository: Final result: ${result?.path}');
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
      AppLogger.debug('ProfileRepository: Uploading image for user $userId');

      final fileName = '${_uuid.v4()}.jpg';
      final ref = _storage.ref().child('profile_images/$userId/$fileName');

      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Listen to progress
      uploadTask.snapshotEvents.listen((event) {
        final progress = event.bytesTransferred / event.totalBytes;
        AppLogger.debug(
          'ProfileRepository: Upload progress: ${(progress * 100).toInt()}%',
        );
        onProgress?.call(progress);
      });

      // Wait for upload to complete
      await uploadTask;

      // Get download URL
      final downloadUrl = await ref.getDownloadURL();
      AppLogger.info('ProfileRepository: Upload complete: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('ProfileRepository: Error uploading image', error: e);
      return null;
    }
  }

  /// Delete old profile image from storage
  Future<void> deleteProfileImage(String? photoUrl) async {
    if (photoUrl == null || photoUrl.isEmpty) return;

    try {
      final ref = _storage.refFromURL(photoUrl);
      await ref.delete();
      AppLogger.info('ProfileRepository: Deleted old image');
    } catch (e) {
      AppLogger.error('ProfileRepository: Error deleting image', error: e);
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
      AppLogger.error(
        'ProfileImageCache: Error getting cached image',
        error: e,
      );
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
      AppLogger.error('ProfileImageCache: Error caching image', error: e);
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
      AppLogger.error('ProfileImageCache: Error invalidating cache', error: e);
    }
  }
}

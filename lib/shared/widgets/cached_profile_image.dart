import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/services/profile_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';

/// A widget that displays a cached profile image
/// Uses local cache first, then falls back to network
class CachedProfileImage extends ConsumerStatefulWidget {
  final String? photoUrl;
  final String? userId;
  final double size;
  final Widget? placeholder;
  final BoxFit fit;

  const CachedProfileImage({
    super.key,
    this.photoUrl,
    this.userId,
    this.size = 64,
    this.placeholder,
    this.fit = BoxFit.cover,
  });

  @override
  ConsumerState<CachedProfileImage> createState() => _CachedProfileImageState();
}

class _CachedProfileImageState extends ConsumerState<CachedProfileImage> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCachedImage();
  }

  @override
  void didUpdateWidget(CachedProfileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if URL changed
    if (oldWidget.photoUrl != widget.photoUrl) {
      _loadCachedImage();
    }
  }

  Future<void> _loadCachedImage() async {
    if (widget.photoUrl == null || widget.userId == null) {
      setState(() {
        _isLoading = false;
        _cachedFile = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final imageCache = ref.read(profileImageCacheProvider);

      // Try to get from cache first
      final cachedUrl = await imageCache.getCachedUrl(widget.userId!);
      if (cachedUrl == widget.photoUrl) {
        final cachedFile = await imageCache.getCachedImage(widget.userId!);
        if (cachedFile != null) {
          setState(() {
            _cachedFile = cachedFile;
            _isLoading = false;
          });
          return;
        }
      }

      // Cache miss - download and cache
      final file = await imageCache.cacheImageFromUrl(
        userId: widget.userId!,
        photoUrl: widget.photoUrl!,
      );

      if (mounted) {
        setState(() {
          _cachedFile = file;
          _isLoading = false;
          _hasError = file == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder =
        widget.placeholder ??
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.heartNormal,
          ),
          child: Icon(
            Icons.person,
            color: AppColors.white,
            size: widget.size * 0.5,
          ),
        );

    if (widget.photoUrl == null) {
      return defaultPlaceholder;
    }

    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppGradients.heartNormal,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        ),
      );
    }

    if (_hasError || _cachedFile == null) {
      // Fall back to network image with cached_network_image
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: widget.photoUrl!,
          width: widget.size,
          height: widget.size,
          fit: widget.fit,
          placeholder: (context, url) => Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.heartNormal,
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.white,
              ),
            ),
          ),
          errorWidget: (context, url, error) => defaultPlaceholder,
        ),
      );
    }

    // Show cached file
    return ClipOval(
      child: Image.file(
        _cachedFile!,
        width: widget.size,
        height: widget.size,
        fit: widget.fit,
        errorBuilder: (_, __, ___) => defaultPlaceholder,
      ),
    );
  }
}

/// Simple profile avatar that just uses the network or shows placeholder
/// For cases where caching isn't critical (small avatars, etc.)
class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final Widget? placeholder;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.size = 48,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final defaultPlaceholder =
        placeholder ??
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.heartNormal,
          ),
          child: Icon(Icons.person, color: AppColors.white, size: size * 0.5),
        );

    if (photoUrl == null || photoUrl!.isEmpty) {
      return defaultPlaceholder;
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.white,
            ),
          ),
        ),
        errorWidget: (context, url, error) => defaultPlaceholder,
      ),
    );
  }
}

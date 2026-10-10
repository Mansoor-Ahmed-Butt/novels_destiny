import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

/// A robust image widget that gracefully handles both network URLs (http/https)
/// and local device file paths (including file:// URIs), with loading states
/// and aesthetic fallback placeholders.
class AppAdaptiveImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const AppAdaptiveImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final rawUrl = (url ?? '').trim();
    Widget content;

    if (rawUrl.isEmpty) {
      content = errorWidget ?? _buildDefaultFallback();
    } else if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      content = Image.network(
        rawUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) =>
            errorWidget ?? _buildDefaultFallback(),
      );
    } else {
      String cleanPath = rawUrl;
      if (cleanPath.startsWith('file://')) {
        try {
          cleanPath = Uri.parse(cleanPath).toFilePath();
        } catch (_) {
          cleanPath = cleanPath.replaceFirst('file://', '');
        }
      }

      final file = File(cleanPath);
      if (!kIsWeb && file.existsSync()) {
        content = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildDefaultFallback(),
        );
      } else {
        content = errorWidget ?? _buildDefaultFallback();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primaryLight,
        ),
      ),
    );
  }

  Widget _buildDefaultFallback() {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textTertiary,
        size: 24,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'app_shimmer.dart';

class AppImage extends StatelessWidget {
  const AppImage._({
    super.key,
    required this.path,
    required this.isNetwork,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.color,
    this.placeholder,
    this.errorWidget,
  });

  const AppImage.asset(
    String path, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? borderRadius,
    Color? color,
  }) : this._(
          key: key,
          path: path,
          isNetwork: false,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
          color: color,
        );

  const AppImage.network(
    String path, {
    Key? key,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    double? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) : this._(
          key: key,
          path: path,
          isNetwork: true,
          width: width,
          height: height,
          fit: fit,
          borderRadius: borderRadius,
          placeholder: placeholder,
          errorWidget: errorWidget,
        );

  final String path;
  final bool isNetwork;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double? borderRadius;
  final Color? color;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final imageWidth = width != null ? Responsive.getW(width!) : null;
    final imageHeight = height != null ? Responsive.getH(height!) : null;

    final image = isNetwork
        ? Image.network(
            path,
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              return placeholder ??
                  AppShimmer(
                    child: AppShimmerBox(
                      width: imageWidth,
                      height: imageHeight,
                      borderRadius: borderRadius ?? 8,
                    ),
                  );
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _defaultError(imageWidth, imageHeight);
            },
          )
        : Image.asset(
            path,
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            color: color,
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ?? _defaultError(imageWidth, imageHeight);
            },
          );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(Responsive.getR(borderRadius!)),
      child: image,
    );
  }

  Widget _defaultError(double? imageWidth, double? imageHeight) {
    return Container(
      width: imageWidth,
      height: imageHeight,
      alignment: Alignment.center,
      color: Colors.black12,
      child: Icon(
        Icons.broken_image_outlined,
        size: Responsive.getSize(24),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageWidget extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isBackground;
  final BoxFit fit;

  const CustomImageWidget({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.borderRadius,
    this.isBackground = false,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isNetworkImage =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    Widget imageWidget;
    if (isNetworkImage) {
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Container(
          color: Colors.black12,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 2,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.black12,
          child: const Icon(Icons.error, color: Colors.orange),
        ),
      );
    } else if (imagePath.isNotEmpty) {
      try {
        imageWidget = Image.file(
          File(imagePath),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Container(
            width: width,
            height: height,
            color: Colors.black12,
            child: const Icon(Icons.error, color: Colors.orange),
          ),
        );
      } catch (e) {
        imageWidget = Container(
          width: width,
          height: height,
          color: Colors.black12,
          child: const Icon(Icons.movie, color: Colors.orange),
        );
      }
    } else {
      imageWidget = Container(
        width: width,
        height: height,
        color: Colors.black12,
        child: const Icon(Icons.movie, color: Colors.orange),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

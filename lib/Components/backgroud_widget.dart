import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../Model/Movie.dart';

class BackgroundWidget extends StatelessWidget {
  final PageController controller;
  final List<Movie> movies; // Nhận danh sách phim từ HomeScreen

  const BackgroundWidget({
    required this.controller,
    required this.movies, // Nhận danh sách phim
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      reverse: true,
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      itemCount: movies.length, // Sử dụng danh sách phim từ HomeScreen
      itemBuilder: (context, index) {
        final Movie movie = movies[index];
        return buildBackground(movie);
      },
    );
  }

  Widget buildBackground(Movie movie) {
    return Stack(
      children: [
        // Background Image with Blur Effect
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ).createShader(bounds);
            },
            blendMode: BlendMode.darken,
            child: _buildBackgroundImage(movie.imagePath),
          ),
        ),
        // Gradient Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.7),
                  Colors.black.withOpacity(0.9),
                ],
              ),
            ),
          ),
        ),
        // Animated Gradient Border
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.orange.withOpacity(0.1),
                  Colors.transparent,
                  Colors.orange.withOpacity(0.1),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundImage(String imagePath) {
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        );
      } else if (imagePath.startsWith('file://')) {
        return Image.file(
          File(imagePath.replaceAll('file://', '')),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorPlaceholder(),
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorPlaceholder(),
        );
      }
    } catch (e) {
      print('Error loading background image: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildPlaceholder() => Container(
        color: Colors.black87,
        child: Center(
          child: Icon(
            Icons.movie_outlined,
            color: Colors.orange.withOpacity(0.3),
            size: 64,
          ),
        ),
      );

  Widget _buildLoadingPlaceholder() => Container(
        color: Colors.black87,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2,
          ),
        ),
      );

  Widget _buildErrorPlaceholder() => Container(
        color: Colors.black87,
        child: Center(
          child: Icon(
            Icons.error_outline,
            color: Colors.orange.withOpacity(0.3),
            size: 64,
          ),
        ),
      );
}

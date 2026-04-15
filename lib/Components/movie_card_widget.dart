import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Model/Movie.dart';
import '../View/user/movie_detail_screen.dart';
import 'dart:io';

class MovieCardWidget extends StatefulWidget {
  final Movie movie;

  const MovieCardWidget({
    required this.movie,
    Key? key,
  }) : super(key: key);

  @override
  State<MovieCardWidget> createState() => _MovieCardWidgetState();
}

class _MovieCardWidgetState extends State<MovieCardWidget> {
  double _rating = 0.0;

  @override
  void initState() {
    super.initState();
    _loadRating();
  }

  Future<void> _loadRating() async {
    final ratingData = await Movie.calculateRating(widget.movie.id);
    if (mounted) {
      setState(() {
        _rating = ratingData['rating'];
      });
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          // Điều hướng đến trang MovieDetailScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MovieDetailScreen(movie: widget.movie),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(3),
            child: Column(
              children: [
                Expanded(child: buildImage(movie: widget.movie)),
                const SizedBox(height: 8),
                Text(
                  widget.movie.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(height: 8),
                buildReleaseDateAndDuration(movie: widget.movie),
                const SizedBox(height: 8),
                buildGenre(movie: widget.movie),
                const SizedBox(height: 8),
                buildRating(),
              ],
            ),
          ),
        ),
      );

  Widget buildImage({required Movie movie}) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: _buildImageContent(movie.imagePath),
        ),
      );

  Widget _buildImageContent(String imagePath) {
    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      if (imagePath.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imagePath,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildLoadingPlaceholder(),
          errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        );
      } else if (imagePath.startsWith('file://')) {
        return Image.file(
          File(imagePath.replaceAll('file://', '')),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorPlaceholder(),
        );
      } else {
        return Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildErrorPlaceholder(),
        );
      }
    } catch (e) {
      print('Error loading image: $e');
      return _buildErrorPlaceholder();
    }
  }

  Widget _buildPlaceholder() => Container(
        color: Colors.black26,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie_outlined,
                color: Colors.orange.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No Image',
                style: TextStyle(
                  color: Colors.orange.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildLoadingPlaceholder() => Container(
        color: Colors.black26,
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
            strokeWidth: 2,
          ),
        ),
      );

  Widget _buildErrorPlaceholder() => Container(
        color: Colors.black26,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.orange,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading image',
                style: TextStyle(
                  color: Colors.orange.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );

  Widget buildReleaseDateAndDuration({required Movie movie}) =>
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        buildTag(movie.releaseDate),
        const SizedBox(width: 10),
        buildTag(movie.duration),
      ]);

  Widget buildGenre({required Movie movie}) =>
      buildTag(movie.genres.map((genre) => genre.name).join(" | "));

  Widget buildRating() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${_rating.toStringAsFixed(1)}/10',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.star,
            color: Colors.orangeAccent,
            size: 16,
          ),
        ],
      );

  Widget buildTag(String text) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orangeAccent),
          borderRadius: BorderRadius.circular(15),
          color: Colors.black54,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          text,
          style: const TextStyle(color: Colors.orangeAccent, fontSize: 14),
        ),
      );

  Widget buildTagWithIcon({required String text, required IconData icon}) =>
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orangeAccent),
          borderRadius: BorderRadius.circular(15),
          color: Colors.black54,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 5),
            Icon(icon, size: 18, color: Colors.orangeAccent),
          ],
        ),
      );
}

import 'package:flutter/material.dart';
import '../Services/favourites_service.dart';
import '../Models/movie.dart';
import '../Services/movie_service.dart';
import '../Utils/constants.dart';

class MovieDetailScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailScreen({Key? key, required this.movieId}) : super(key: key);

  @override
  _MovieDetailScreenState createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends State<MovieDetailScreen> {
  final MovieService _movieService = MovieService();
  final FavoriteService _favoriteService = FavoriteService.instance;
  late Future<Movie> _movieFuture;
  bool _isFavorite = false;
  bool _isFavoriteLoading = false;

  @override
  void initState() {
    super.initState();
    _movieFuture = _movieService.getMovieDetails(widget.movieId);
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoriteService.isFavorite(widget.movieId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite(Movie movie) async {
    if (_isFavoriteLoading) return;

    setState(() {
      _isFavoriteLoading = true;
    });

    final success = await _favoriteService.toggleFavorite(movie);
    
    if (mounted) {
      setState(() {
        _isFavoriteLoading = false;
        if (success) {
          _isFavorite = !_isFavorite;
        }
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorite 
                ? 'Dodano do ulubionych' 
                : 'Usunięto z ulubionych'
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wystąpił błąd podczas zapisywania'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading movie details',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final movie = snapshot.data!;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                actions: [
                  // Favorite button in app bar
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _isFavoriteLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              _isFavorite 
                                  ? Icons.favorite 
                                  : Icons.favorite_border,
                              color: _isFavorite 
                                  ? Colors.red 
                                  : Colors.white,
                            ),
                            onPressed: () => _toggleFavorite(movie),
                          ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      movie.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: movie.backdropPath.isNotEmpty
                      ? Image.network(
                          '${Constants.backdropBaseUrl}${movie.backdropPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[800]);
                          },
                        )
                      : Container(color: Colors.grey[800]),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Poster image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: movie.posterPath.isNotEmpty
                                ? Image.network(
                                    '${Constants.imageBaseUrl}${movie.posterPath}',
                                    height: 180,
                                    width: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) {
                                      return Container(
                                        height: 180,
                                        width: 120,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Text('No image'),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    height: 180,
                                    width: 120,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Text('No image'),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          // Movie info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${movie.voteAverage.toStringAsFixed(1)}/10',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Votes: ${movie.voteCount}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Release date: ${movie.releaseDate}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Original language: ${movie.originalLanguage.toUpperCase()}',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    style: TextStyle(color: Colors.grey[700]),
                                    children: [
                                      const TextSpan(text: 'Popularity: '),
                                      TextSpan(
                                        text:
                                            '${movie.popularity.toStringAsFixed(1)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const TextSpan(
                                        text: ' (TMDb score)',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Favorite button below info
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _isFavoriteLoading 
                                        ? null 
                                        : () => _toggleFavorite(movie),
                                    icon: _isFavoriteLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Icon(
                                            _isFavorite 
                                                ? Icons.favorite 
                                                : Icons.favorite_border,
                                          ),
                                    label: Text(
                                      _isFavorite 
                                          ? 'Usuń z ulubionych' 
                                          : 'Dodaj do ulubionych'
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isFavorite 
                                          ? Colors.red.shade100 
                                          : null,
                                      foregroundColor: _isFavorite 
                                          ? Colors.red.shade700 
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movie.overview.isNotEmpty
                            ? movie.overview
                            : 'No overview available',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
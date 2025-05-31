import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/movie.dart';

class FavoriteService {
  static final FavoriteService instance = FavoriteService._internal();
  static const String _favoritesKey = 'favorite_movies';
  
  FavoriteService._internal();

  Future<bool> addToFavorites(Movie movie) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = await getFavoriteIds();
      
      if (favoriteIds.contains(movie.id)) {
        return false; // Already in favorites
      }
      
      final favoriteMovies = await getFavoriteMovies();
      favoriteMovies.add(movie);
      
      final jsonString = jsonEncode(
        favoriteMovies.map((movie) => _movieToJson(movie)).toList(),
      );
      
      return await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(int movieId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteMovies = await getFavoriteMovies();
      
      favoriteMovies.removeWhere((movie) => movie.id == movieId);
      
      final jsonString = jsonEncode(
        favoriteMovies.map((movie) => _movieToJson(movie)).toList(),
      );
      
      return await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  Future<bool> toggleFavorite(Movie movie) async {
    final isFav = await isFavorite(movie.id);
    if (isFav) {
      return await removeFromFavorites(movie.id);
    } else {
      return await addToFavorites(movie);
    }
  }

  Future<List<Movie>> getFavoriteMovies() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => _movieFromJson(json)).toList();
    } catch (e) {
      print('Error getting favorite movies: $e');
      return [];
    }
  }

  Future<bool> isFavorite(int movieId) async {
    try {
      final favoriteIds = await getFavoriteIds();
      return favoriteIds.contains(movieId);
    } catch (e) {
      print('Error checking if favorite: $e');
      return false;
    }
  }

  Future<List<int>> getFavoriteIds() async {
    try {
      final favoriteMovies = await getFavoriteMovies();
      return favoriteMovies.map((movie) => movie.id).toList();
    } catch (e) {
      print('Error getting favorite IDs: $e');
      return [];
    }
  }

  // Helper methods to convert Movie to/from JSON
  Map<String, dynamic> _movieToJson(Movie movie) {
    return {
      'id': movie.id,
      'title': movie.title,
      'original_title': movie.originalTitle,
      'overview': movie.overview,
      'release_date': movie.releaseDate,
      'poster_path': movie.posterPath,
      'backdrop_path': movie.backdropPath,
      'vote_average': movie.voteAverage,
      'vote_count': movie.voteCount,
      'genre_ids': movie.genreIds,
      'popularity': movie.popularity,
      'original_language': movie.originalLanguage,
      'adult': movie.adult,
      'video': movie.video,
      'added_at': DateTime.now().toIso8601String(),
    };
  }

  Movie _movieFromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'],
      title: json['title'],
      originalTitle: json['original_title'],
      overview: json['overview'] ?? '',
      releaseDate: json['release_date'] ?? '',
      posterPath: json['poster_path'] ?? '',
      backdropPath: json['backdrop_path'] ?? '',
      voteAverage: (json['vote_average'] as num).toDouble(),
      voteCount: json['vote_count'] ?? 0,
      genreIds: List<int>.from(json['genre_ids'] ?? []),
      popularity: (json['popularity'] as num).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      adult: json['adult'] ?? false,
      video: json['video'] ?? false,
    );
  }
}
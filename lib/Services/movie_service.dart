import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Models/movie_response.dart';
import '../Models/movie.dart';
import '../Enums/movie_category.dart';
import '../Utils/constants.dart';

class MovieService {
  // Main method to get movies by category
  Future<MovieResponse> getMoviesByCategory(
    MovieCategory category, {
    int page = 1,
  }) async {
    String endpoint;
    switch (category) {
      case MovieCategory.popular:
        endpoint = '/movie/popular';
        break;
      case MovieCategory.topRated:
        endpoint = '/movie/top_rated';
        break;
      case MovieCategory.nowPlaying:
        endpoint = '/movie/now_playing';
        break;
      case MovieCategory.upcoming:
        endpoint = '/movie/upcoming';
        break;
    }

    final url = Uri.parse(
      '${Constants.apiBaseUrl}$endpoint?language=en-US&page=$page',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${Constants.apiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MovieResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movies: ${response.statusCode}');
    }
  }

  // Keep your existing methods for backward compatibility
  Future<MovieResponse> getTopRatedMovies({int page = 1}) async {
    return getMoviesByCategory(MovieCategory.topRated, page: page);
  }

  Future<MovieResponse> getPopularMovies({int page = 1}) async {
    return getMoviesByCategory(MovieCategory.popular, page: page);
  }

  Future<MovieResponse> getNowPlayingMovies({int page = 1}) async {
    return getMoviesByCategory(MovieCategory.nowPlaying, page: page);
  }

  Future<MovieResponse> getUpcomingMovies({int page = 1}) async {
    return getMoviesByCategory(MovieCategory.upcoming, page: page);
  }

  Future<Movie> getMovieDetails(int movieId) async {
    final url = Uri.parse(
      '${Constants.apiBaseUrl}/movie/$movieId?language=en-US',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${Constants.apiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Movie.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load movie details: ${response.statusCode}');
    }
  }

  Future<MovieResponse> searchMovies(String query, {int page = 1}) async {
    final url = Uri.parse(
      '${Constants.apiBaseUrl}/search/movie?language=en-US&query=$query&page=$page',
    );
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${Constants.apiKey}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return MovieResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search movies: ${response.statusCode}');
    }
  }

  // Helper method to get category display name
  static String getCategoryDisplayName(MovieCategory category) {
    switch (category) {
      case MovieCategory.popular:
        return 'Popular';
      case MovieCategory.topRated:
        return 'Top Rated';
      case MovieCategory.nowPlaying:
        return 'Now Playing';
      case MovieCategory.upcoming:
        return 'Upcoming';
    }
  }

  // Helper method to get category icon
  static IconData getCategoryIcon(MovieCategory category) {
    switch (category) {
      case MovieCategory.popular:
        return Icons.trending_up;
      case MovieCategory.topRated:
        return Icons.star;
      case MovieCategory.nowPlaying:
        return Icons.theaters;
      case MovieCategory.upcoming:
        return Icons.schedule;
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/movie_response.dart';
import '../models/movie.dart';
import '../utils/constants.dart';

class MovieService {
  Future<MovieResponse> getTopRatedMovies({int page = 1}) async {
    final url = Uri.parse('${Constants.apiBaseUrl}/movie/top_rated?language=en-US&page=$page');
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
      throw Exception('Failed to load top rated movies: ${response.statusCode}');
    }
  }

  Future<Movie> getMovieDetails(int movieId) async {
    final url = Uri.parse('${Constants.apiBaseUrl}/movie/$movieId?language=en-US');
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
    final url = Uri.parse('${Constants.apiBaseUrl}/search/movie?language=en-US&query=$query&page=$page');
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
}
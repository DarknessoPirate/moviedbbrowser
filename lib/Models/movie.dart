class Movie {
  final int id;
  final String title;
  final String originalTitle;
  final String overview;
  final String releaseDate;
  final String posterPath;
  final String backdropPath;
  final double voteAverage;
  final int voteCount;
  final List<int> genreIds;
  final double popularity;
  final String originalLanguage;
  final bool adult;
  final bool video;

  Movie({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.overview,
    required this.releaseDate,
    required this.posterPath,
    required this.backdropPath,
    required this.voteAverage,
    required this.voteCount,
    required this.genreIds,
    required this.popularity,
    required this.originalLanguage,
    required this.adult,
    required this.video,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    // Handle the difference between movie list and movie detail endpoints
    // Detail endpoint might not have genre_ids but instead have genres
    List<int> extractedGenreIds = [];
    if (json.containsKey('genre_ids') && json['genre_ids'] != null) {
      extractedGenreIds = List<int>.from(json['genre_ids']);
    } else if (json.containsKey('genres') && json['genres'] != null) {
      // For movie details, genres come as a list of objects with id and name
      extractedGenreIds = List<int>.from((json['genres'] as List).map((genre) => genre['id']));
    }

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
      genreIds: extractedGenreIds,
      popularity: (json['popularity'] as num).toDouble(),
      originalLanguage: json['original_language'] ?? '',
      adult: json['adult'] ?? false,
      video: json['video'] ?? false,
    );
  }
}
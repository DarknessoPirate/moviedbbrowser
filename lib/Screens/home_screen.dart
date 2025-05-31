import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../services/movie_service.dart';
import '../widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();
  List<Movie> _movies = [];
  List<Movie> _searchResults = [];
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMovies();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMorePages) {
        _loadMoreMovies();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _movieService.getTopRatedMovies(
        page: _currentPage,
      );
      setState(() {
        _movies = response.results;
        _hasMorePages = _currentPage < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading movies: $e')));
    }
  }

  Future<void> _loadMoreMovies() async {
    if (_isSearching) {
      await _searchMoreMovies();
      return;
    }

    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _movieService.getTopRatedMovies(
        page: _currentPage,
      );
      setState(() {
        _movies.addAll(response.results);
        _hasMorePages = _currentPage < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading more movies: $e')));
    }
  }

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
      _currentPage = 1;
    });

    try {
      final response = await _movieService.searchMovies(
        query,
        page: _currentPage,
      );
      setState(() {
        _searchResults = response.results;
        _hasMorePages = _currentPage < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching movies: $e')));
    }
  }

  Future<void> _searchMoreMovies() async {
    setState(() {
      _isLoading = true;
      _currentPage++;
    });

    try {
      final response = await _movieService.searchMovies(
        _searchController.text,
        page: _currentPage,
      );
      setState(() {
        _searchResults.addAll(response.results);
        _hasMorePages = _currentPage < response.totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _currentPage--;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more search results: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Movie> displayedMovies = _isSearching ? _searchResults : _movies;

    return Scaffold(
      appBar: AppBar(title: const Text('Movie DB Browser'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for movies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon:
                    _searchController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchMovies('');
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                _searchMovies(value);
              },
            ),
          ),
          Expanded(
            child:
                _isLoading && displayedMovies.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : displayedMovies.isEmpty
                    ? const Center(child: Text('No movies found'))
                    : GridView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            MediaQuery.of(context).size.width > 600
                                ? 4
                                : 2, // More columns on wider screens
                        childAspectRatio:
                            0.55, // Adjusted for better poster+info ratio
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 12,
                      ),
                      itemCount:
                          displayedMovies.length + (_hasMorePages ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= displayedMovies.length) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return MovieCard(movie: displayedMovies[index]);
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

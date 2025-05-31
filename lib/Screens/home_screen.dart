import 'package:flutter/material.dart';
import '../Services/favourites_service.dart';
import '../Models/movie.dart';
import '../Services/movie_service.dart';
import '../Widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  final FavoriteService _favoriteService = FavoriteService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  
  List<Movie> _movies = [];
  List<Movie> _searchResults = [];
  List<Movie> _favoriteMovies = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMovies();
    _loadFavoriteMovies();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent * 0.8 &&
          !_isLoading &&
          _hasMorePages &&
          _tabController.index == 0) { // Pagination only for "Wszystkie" tab
        _loadMoreMovies();
      }
    });

    _tabController.addListener(() {
      if (_tabController.index == 1) {
        // When switching to favorites tab, reload favorites
        _loadFavoriteMovies();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _tabController.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading movies: $e')),
      );
    }
  }

  Future<void> _loadFavoriteMovies() async {
    try {
      final favorites = await _favoriteService.getFavoriteMovies();
      setState(() {
        _favoriteMovies = favorites;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorite movies: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more movies: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching movies: $e')),
      );
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

  void _onFavoriteChanged() {
    // Refresh favorites when a movie is added/removed from favorites
    _loadFavoriteMovies();
  }

  Widget _buildMovieGrid(List<Movie> movies) {
    if (_isLoading && movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (movies.isEmpty) {
      String message = 'Brak filmów';
      if (_tabController.index == 1) {
        message = 'Brak ulubionych filmów';
      } else if (_isSearching) {
        message = 'Nie znaleziono filmów';
      }
      return Center(child: Text(message));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length + 
          ((_hasMorePages && _tabController.index == 0) ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= movies.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return MovieCard(
          movie: movies[index],
          onFavoriteChanged: _onFavoriteChanged,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie DB Browser'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.movie),
              text: 'Wszystkie',
            ),
            Tab(
              icon: const Icon(Icons.favorite),
              text: 'Ulubione (${_favoriteMovies.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar - only visible on "Wszystkie" tab
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _tabController.index == 0 ? 80 : 0,
            child: _tabController.index == 0
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Szukaj filmów...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
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
                  )
                : Container(),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Wszystkie filmy
                _buildMovieGrid(_isSearching ? _searchResults : _movies),
                
                // Ulubione filmy
                _buildMovieGrid(_favoriteMovies),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _loadFavoriteMovies,
              tooltip: 'Odśwież ulubione',
              child: const Icon(Icons.refresh),
            )
          : null,
    );
  }
}
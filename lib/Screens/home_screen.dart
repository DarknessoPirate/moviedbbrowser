import 'package:flutter/material.dart';
import '../Models/movie.dart';
import '../Services/movie_service.dart';
import '../Services/favourites_service.dart';
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
  List<Movie> _filteredFavoriteMovies = [];
  
  int _currentPage = 1;
  bool _isLoading = false;
  bool _isSearching = false;
  bool _hasMorePages = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filteredFavoriteMovies = []; // Inicjalizuj pustą listę
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
        // When switching to favorites tab, reload favorites and filter them
        _loadFavoriteMovies();
      }
      // Zaktualizuj hint w polu wyszukiwania
      setState(() {});
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
        _filterFavoriteMovies(); // Filtruj po załadowaniu
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorite movies: $e')),
      );
    }
  }

  Future<void> _loadMoreMovies() async {
    // Pagination tylko dla zakładki "Wszystkie" i tylko gdy wyszukujemy przez API
    if (_tabController.index != 0) return;
    
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
    // Jeśli puste zapytanie, wyczyść wyszukiwanie
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      _filterFavoriteMovies(); // Odfiltruj ulubione
      return;
    }

    // Jeśli jesteśmy w zakładce ulubionych, filtruj lokalnie
    if (_tabController.index == 1) {
      _filterFavoriteMovies();
      return;
    }

    // Wyszukuj filmy przez API (tylko dla zakładki "Wszystkie")
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

  void _filterFavoriteMovies() {
    final query = _searchController.text.toLowerCase();
    
    if (query.isEmpty) {
      setState(() {
        _filteredFavoriteMovies = List.from(_favoriteMovies);
      });
    } else {
      setState(() {
        _filteredFavoriteMovies = _favoriteMovies.where((movie) {
          return movie.title.toLowerCase().contains(query) ||
                 movie.originalTitle.toLowerCase().contains(query) ||
                 movie.overview.toLowerCase().contains(query);
        }).toList();
      });
    }
  }

  Future<void> _searchMoreMovies() async {
    // Search more tylko dla zakładki "Wszystkie"
    if (_tabController.index != 0) return;
    
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

  Widget _buildMovieGrid(List<Movie> movies, {bool showPagination = false}) {
    if (_isLoading && movies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (movies.isEmpty) {
      String message = 'Brak filmów';
      if (_tabController.index == 1) {
        message = _searchController.text.isNotEmpty 
            ? 'Brak ulubionych filmów pasujących do wyszukiwania'
            : 'Brak ulubionych filmów';
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
          ((showPagination && _hasMorePages) ? 1 : 0),
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
          // Search bar - zawsze widoczny
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _tabController.index == 0 
                    ? 'Szukaj filmów...' 
                    : 'Szukaj w ulubionych...',
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
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Wszystkie filmy
                _buildMovieGrid(
                  _isSearching ? _searchResults : _movies,
                  showPagination: true,
                ),
                
                // Ulubione filmy
                _buildMovieGrid(
                  _filteredFavoriteMovies,
                  showPagination: false,
                ),
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
import 'package:flutter/material.dart';
import '../Models/movie.dart';
import '../Enums/movie_category.dart';
import '../Services/movie_service.dart';
import '../Widgets/movie_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final MovieService _movieService = MovieService();
  final TextEditingController _searchController = TextEditingController();

  // Tab Controller
  late TabController _tabController;

  // Search state
  List<Movie> _searchResults = [];
  bool _isSearching = false;
  int _searchPage = 1;
  bool _searchHasMorePages = true;
  bool _searchLoading = false;

  // Category data - Map each category to its movie data
  Map<MovieCategory, List<Movie>> _categoryMovies = {};
  Map<MovieCategory, int> _categoryPages = {};
  Map<MovieCategory, bool> _categoryLoading = {};
  Map<MovieCategory, bool> _categoryHasMorePages = {};

  // Scroll controllers for each tab
  Map<MovieCategory, ScrollController> _scrollControllers = {};

  final List<MovieCategory> _categories = [
    MovieCategory.popular,
    MovieCategory.topRated,
    MovieCategory.nowPlaying,
    MovieCategory.upcoming,
  ];

  @override
  void initState() {
    super.initState();

    // Initialize tab controller
    _tabController = TabController(length: _categories.length, vsync: this);

    // Initialize data for each category
    for (var category in _categories) {
      _categoryMovies[category] = [];
      _categoryPages[category] = 1;
      _categoryLoading[category] = false;
      _categoryHasMorePages[category] = true;
      _scrollControllers[category] = ScrollController();

      // Add scroll listeners
      _scrollControllers[category]!.addListener(() => _onScroll(category));
    }

    // Load initial data for the first tab
    _loadMoviesForCategory(_categories[0]);

    // Listen to tab changes to load data when needed
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final currentCategory = _categories[_tabController.index];
        if (_categoryMovies[currentCategory]!.isEmpty && !_isSearching) {
          _loadMoviesForCategory(currentCategory);
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    for (var controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScroll(MovieCategory category) {
    final controller = _scrollControllers[category]!;
    if (controller.position.pixels >=
            controller.position.maxScrollExtent * 0.8 &&
        !(_categoryLoading[category] ?? false) &&
        (_categoryHasMorePages[category] ?? false)) {
      if (_isSearching) {
        _loadMoreSearchResults();
      } else {
        _loadMoreMoviesForCategory(category);
      }
    }
  }

  Future<void> _loadMoviesForCategory(MovieCategory category) async {
    if (_categoryLoading[category] ?? false) return;

    setState(() {
      _categoryLoading[category] = true;
    });

    try {
      final response = await _movieService.getMoviesByCategory(
        category,
        page: _categoryPages[category] ?? 1,
      );

      setState(() {
        _categoryMovies[category] = response.results;
        _categoryHasMorePages[category] =
            (_categoryPages[category] ?? 1) < response.totalPages;
        _categoryLoading[category] = false;
      });
    } catch (e) {
      setState(() {
        _categoryLoading[category] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading movies: $e')));
      }
    }
  }

  Future<void> _loadMoreMoviesForCategory(MovieCategory category) async {
    if (_categoryLoading[category] ?? false) return;

    setState(() {
      _categoryLoading[category] = true;
      _categoryPages[category] = (_categoryPages[category] ?? 1) + 1;
    });

    try {
      final response = await _movieService.getMoviesByCategory(
        category,
        page: _categoryPages[category] ?? 1,
      );

      setState(() {
        _categoryMovies[category]!.addAll(response.results);
        _categoryHasMorePages[category] =
            (_categoryPages[category] ?? 1) < response.totalPages;
        _categoryLoading[category] = false;
      });
    } catch (e) {
      setState(() {
        _categoryPages[category] = (_categoryPages[category] ?? 1) - 1;
        _categoryLoading[category] = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more movies: $e')),
        );
      }
    }
  }

  Future<void> _searchMovies(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _searchPage = 1;
      });
      return;
    }

    setState(() {
      _searchLoading = true;
      _isSearching = true;
      _searchPage = 1;
    });

    try {
      final response = await _movieService.searchMovies(
        query,
        page: _searchPage,
      );
      setState(() {
        _searchResults = response.results;
        _searchHasMorePages = _searchPage < response.totalPages;
        _searchLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching movies: $e')));
      }
    }
  }

  Future<void> _loadMoreSearchResults() async {
    if (_searchLoading) return;

    setState(() {
      _searchLoading = true;
      _searchPage++;
    });

    try {
      final response = await _movieService.searchMovies(
        _searchController.text,
        page: _searchPage,
      );
      setState(() {
        _searchResults.addAll(response.results);
        _searchHasMorePages = _searchPage < response.totalPages;
        _searchLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchPage--;
        _searchLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more search results: $e')),
        );
      }
    }
  }

  Widget _buildMovieGrid(
    List<Movie> movies,
    ScrollController scrollController,
    bool hasMorePages,
  ) {
    if (movies.isEmpty) {
      return const Center(child: Text('No movies found'));
    }

    return GridView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
        childAspectRatio: 0.55,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: movies.length + (hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= movies.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return MovieCard(movie: movies[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie DB Browser'),
        elevation: 0,
        bottom:
            _isSearching
                ? null
                : TabBar(
                  controller: _tabController,
                  isScrollable: false,
                  tabs:
                      _categories.map((category) {
                        return Tab(
                          icon: Icon(MovieService.getCategoryIcon(category)),
                          text: MovieService.getCategoryDisplayName(category),
                        );
                      }).toList(),
                ),
      ),
      body: Column(
        children: [
          // Search Bar
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
              onChanged: _searchMovies,
            ),
          ),

          // Content Area
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading && _searchResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentCategory = _categories[_tabController.index];
    return _buildMovieGrid(
      _searchResults,
      _scrollControllers[currentCategory]!,
      _searchHasMorePages,
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children:
          _categories.map((category) {
            final movies = _categoryMovies[category] ?? [];
            final isLoading = _categoryLoading[category] ?? false;
            final hasMorePages = _categoryHasMorePages[category] ?? true;
            final scrollController = _scrollControllers[category]!;

            if (isLoading && movies.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return _buildMovieGrid(movies, scrollController, hasMorePages);
          }).toList(),
    );
  }
}

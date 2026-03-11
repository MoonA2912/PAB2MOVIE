import 'package:flutter/material.dart';
import 'package:flutter_daftar_movie/models/movie.dart';
import 'package:flutter_daftar_movie/screens/detail_screen.dart';
import 'package:flutter_daftar_movie/services/api_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<Movie> _allMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _searchResults = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  // helper untuk animasi scroll
  void _scrollHorizontally(ScrollController ctrl, double offset) {
    final max = ctrl.position.maxScrollExtent;
    final min = ctrl.position.minScrollExtent;
    final target = (ctrl.offset + offset).clamp(min, max);
    ctrl.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovies() async {
    final all = await _apiService.getAllMovies();
    final trending = await _apiService.getTrendingMovies();
    final popular = await _apiService.getPopularMovies();

    setState(() {
      _allMovies = all.map((e) => Movie.fromJson(e)).toList();
      _trendingMovies = trending.map((e) => Movie.fromJson(e)).toList();
      _popularMovies = popular.map((e) => Movie.fromJson(e)).toList();
      _loading = false;
    });
  }

  void _onSearchChanged(String q) {
    if (q.trim().isEmpty) {
      setState(() => _searchResults.clear());
      return;
    }
    final lower = q.toLowerCase();
    setState(() {
      _searchResults = _allMovies
          .where((m) => m.title.toLowerCase().contains(lower))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Daftar Film',
          style: TextStyle(color: Colors.black87),
        ),
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Cari judul film...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchResults.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // jika sedang mencari, tampilkan hasil saja
                if (_searchResults.isNotEmpty) ...[
                  _buildSection('Search results', _searchResults),
                ] else ...[
                  _buildSection('Trending', _trendingMovies),
                  _buildSection('Popular', _popularMovies),
                  _buildSection('All Movies', _allMovies),
                ],

                SliverToBoxAdapter(
                  child: const SizedBox(height: 24),
                ), // bottom padding
              ],
            ),
    );
  }

  SliverToBoxAdapter _buildSection(String title, List<Movie> movies) {
    if (movies.isEmpty)
      return const SliverToBoxAdapter(child: SizedBox.shrink());

    final ctrl = ScrollController();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                Scrollbar(
                  controller: ctrl,
                  thumbVisibility: true,
                  radius: const Radius.circular(6),
                  child: ListView.builder(
                    controller: ctrl,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: movies.length,
                    itemBuilder: (context, idx) {
                      final m = movies[idx];
                      return _movieCard(m);
                    },
                  ),
                ),
                // tombol kiri
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _scrollHorizontally(ctrl, -200),
                      ),
                    ),
                  ),
                ),
                // tombol kanan
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _scrollHorizontally(ctrl, 200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _movieCard(Movie movie) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => DetailScreen(movie: movie))),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // tetapkan tinggi kartu poster
              SizedBox(
                height: 210,
                child: Card(
                  clipBehavior: Clip.hardEdge,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w500${movie.posterPath}',
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.movie,
                              color: Colors.white54,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withOpacity(0.0),
                                Colors.black45,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

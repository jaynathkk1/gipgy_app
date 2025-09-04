import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  bool isSearch = false;
  final searchController = TextEditingController();
  String query = '';
  List<String> gifUrl = [];
  List<String> trendGifs = [];
  bool isLoading = false;
  bool hasMore = true;
  int currentOffset = 0;
  final int limit = 25;
  final ScrollController _scrollController = ScrollController();

  final String api_key = "Q8y9zQPgdhgfVnoVE8Bhb4n8LMAdPzfR";

  @override
  void initState() {
    super.initState();
    fetchTrendGiphy();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!isLoading && hasMore) {
        if (query.isNotEmpty) {
          fetchGiphy(loadMore: true);
        } else {
          fetchTrendGiphy(loadMore: true);
        }
      }
    }
  }

  Future<void> fetchGiphy({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      int offset = loadMore ? currentOffset : 0;
      if (!loadMore) {
        currentOffset = 0;
        gifUrl.clear();
        hasMore = true;
      }

      final url = "https://api.giphy.com/v1/gifs/search?api_key=$api_key&q=$query&limit=$limit&offset=$offset&rating=g&lang=en&bundle=messaging_non_clips";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        var gifs = result['data'] as List;
        var totalCount = result['pagination']?['total_count'] ?? 0;

        List<String> newGifs = gifs
            .map((gif) => gif['images']?['fixed_height']?['url'] as String?)
            .where((url) => url != null)
            .cast<String>()
            .toList();

        setState(() {
          if (loadMore) {
            gifUrl.addAll(newGifs);
          } else {
            gifUrl = newGifs;
          }
          currentOffset += limit;
          hasMore = gifUrl.length < totalCount && newGifs.isNotEmpty;
        });
      }
    } catch (e) {
      log('Error loading search data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void onSearch(String value) {
    setState(() {
      query = value.trim();
    });
    if (query.isNotEmpty) {
      fetchGiphy();
    }
  }

  Future<void> fetchTrendGiphy({bool loadMore = false}) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      int offset = loadMore ? currentOffset : 0;
      if (!loadMore) {
        currentOffset = 0;
        trendGifs.clear();
        hasMore = true;
      }

      final url = "https://api.giphy.com/v1/gifs/trending?api_key=$api_key&limit=$limit&offset=$offset&rating=g&bundle=messaging_non_clips";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final trendsGifs = result['data'] as List;
        var totalCount = result['pagination']?['total_count'] ?? 0;

        List<String> newTrendGifs = trendsGifs
            .map((gif) => gif['images']?['fixed_height']?['url'] as String?)
            .where((url) => url != null)
            .cast<String>()
            .toList();

        setState(() {
          if (loadMore) {
            trendGifs.addAll(newTrendGifs);
          } else {
            trendGifs = newTrendGifs;
          }
          currentOffset += limit;
          hasMore = trendGifs.length < totalCount && newTrendGifs.isNotEmpty;
        });
      }
    } catch (e) {
      log('Error loading trending data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearch
            ? TextField(
          controller: searchController,
          onChanged: onSearch,
          decoration: InputDecoration(
            label: Text('Search...'),
            hintText: 'Search...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  isSearch = false;
                  searchController.clear();
                  query = '';
                  currentOffset = 0;
                  gifUrl.clear();
                });
              },
              icon: Icon(Icons.cancel),
            ),
          ),
        )
            : Text("Giphy"),
        actions: [
          if (!isSearch)
            IconButton(
              onPressed: () {
                setState(() {
                  isSearch = true;
                });
              },
              icon: Icon(Icons.search),
            )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: query.isEmpty
              ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Trending GIFs'),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: trendGifs.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < trendGifs.length) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          trendGifs[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.error),
                            );
                          },
                        ),
                      );
                    } else {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          )
              : GridView.builder(
            controller: _scrollController,
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: gifUrl.length + (isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < gifUrl.length) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    gifUrl[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error),
                      );
                    },
                  ),
                );
              } else {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}

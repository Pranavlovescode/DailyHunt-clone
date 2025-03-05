import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dailyhunt/NewsPageDetail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _newsArticles = [];
  bool _isLoading = false;
  
  Future<void> _searchNews(String query) async {
    if (query.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?q=$query&apiKey=5af2a63335954337b3c3baaa7f69d4a7'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _newsArticles = data['articles'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to fetch news'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF8F9FA), Color(0xFFE8F6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discover News',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                        fontFamily: "CustomPoppins",
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for news...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF7F8C8D),
                          fontFamily: "CustomPoppins",
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Color(0xFF7F8C8D)),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                      onSubmitted: _searchNews,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _newsArticles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 100,
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Search for news articles',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: "CustomPoppins",
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _newsArticles.length,
                            itemBuilder: (context, index) {
                              final article = _newsArticles[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => NewsDetailPage(
                                        title: article['title'] ?? '',
                                        source: article['source']['name'] ?? '',
                                        publishedAt: _formatDate(article['publishedAt']),
                                        image: article['urlToImage'] ?? '',
                                        content: article['content'] ?? article['description'] ?? '',
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (article['urlToImage'] != null)
                                        ClipRRect(
                                          borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                          child: Image.network(
                                            article['urlToImage'],
                                            height: 200,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                height: 200,
                                                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                child: Icon(
                                                  Icons.error_outline,
                                                  color: Theme.of(context).colorScheme.primary,
                                                  size: 32,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              article['title'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2C3E50),
                                                fontFamily: "CustomPoppins",
                                                height: 1.3,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              article['description'] ?? '',
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Color(0xFF7F8C8D),
                                                fontFamily: "CustomPoppins",
                                                height: 1.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    article['source']['name'] ?? '',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontSize: 12,
                                                      fontFamily: "CustomPoppins",
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  _formatDate(article['publishedAt']),
                                                  style: const TextStyle(
                                                    color: Color(0xFF7F8C8D),
                                                    fontSize: 12,
                                                    fontFamily: "CustomPoppins",
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }
}

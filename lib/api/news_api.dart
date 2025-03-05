import 'dart:convert';
import 'package:dailyhunt/model/news_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class NewsApi {
  Future<List<NewsModel>> getTopHeadlines(String lang) async {
    // Make API call
    // Parse JSON
    // Return NewsModel object
    final uri = Uri.parse(
        'https://gnews.io/api/v4/top-headlines?country=in&lang=$lang&max=100&apikey=36d3c5703163e8e264c57a90ec1220a9');
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      debugPrint(response.body);
      return jsonDecode(response.body)['articles']
          .map<NewsModel>((json) => NewsModel.fromJson(json))
          .toList();
    } else {
      throw Exception('Failed to load news');
    }
  }
}

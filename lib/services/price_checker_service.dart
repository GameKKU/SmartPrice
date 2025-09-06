import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class PriceAnalysisResult {
  final String imageUrl;
  final String identifiedItem;
  final String searchQuery;
  final List<SearchResult> searchResults;
  final String analysis;
  final TokenUsage tokenUsage;

  PriceAnalysisResult({
    required this.imageUrl,
    required this.identifiedItem,
    required this.searchQuery,
    required this.searchResults,
    required this.analysis,
    required this.tokenUsage,
  });

  factory PriceAnalysisResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PriceAnalysisResult(
      imageUrl: data['imageUrl'] ?? '',
      identifiedItem: data['identifiedItem'] ?? '',
      searchQuery: data['searchQuery'] ?? '',
      searchResults: (data['searchResults'] as List<dynamic>? ?? [])
          .map((item) => SearchResult.fromJson(item as Map<String, dynamic>))
          .toList(),
      analysis: data['analysis'] ?? '',
      tokenUsage: TokenUsage.fromJson(data['tokenUsage'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class SearchResult {
  final String title;
  final String link;
  final String snippet;

  SearchResult({
    required this.title,
    required this.link,
    required this.snippet,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      title: json['title'] ?? 'No title',
      link: json['link'] ?? 'No link',
      snippet: json['snippet'] ?? '',
    );
  }
}

class TokenUsage {
  final Usage? keyword;
  final Usage? analysis;

  TokenUsage({this.keyword, this.analysis});

  factory TokenUsage.fromJson(Map<String, dynamic> json) {
    return TokenUsage(
      keyword: json['keyword'] != null ? Usage.fromJson(json['keyword']) : null,
      analysis: json['analysis'] != null ? Usage.fromJson(json['analysis']) : null,
    );
  }
}

class Usage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;

  Usage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
  });

  factory Usage.fromJson(Map<String, dynamic> json) {
    return Usage(
      promptTokens: json['prompt_tokens'] ?? 0,
      completionTokens: json['completion_tokens'] ?? 0,
      totalTokens: json['total_tokens'] ?? 0,
    );
  }
}

class PriceCheckerService {
  // Platform-specific base URL
  static String get baseUrl {
    // For Android emulator, use 10.0.2.2 to connect to host machine
    // For other platforms (web, desktop, iOS simulator), use localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
  
  static const Duration timeoutDuration = Duration(seconds: 60);

  static Future<PriceAnalysisResult> analyzePrice(String imageUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/analyze-price'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'imageUrl': imageUrl,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return PriceAnalysisResult.fromJson(responseData);
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error occurred');
        }
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid request');
      } else if (response.statusCode == 500) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Server error');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
      } else {
        rethrow;
      }
    }
  }

  static Future<Map<String, dynamic>> identifyItem(String imageUrl) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/identify-item'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'imageUrl': imageUrl,
            }),
          )
          .timeout(timeoutDuration);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return responseData['data'];
        } else {
          throw Exception(responseData['message'] ?? 'Unknown error occurred');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to identify item');
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
      } else if (e.toString().contains('SocketException')) {
        throw Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต');
      } else {
        rethrow;
      }
    }
  }

  static Future<bool> checkServerHealth() async {
    try {
      print('Checking server health at: $baseUrl/health');
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      
      print('Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Health check error: $e');
      return false;
    }
  }

  static String getConnectionInfo() {
    return 'Platform: ${kIsWeb ? "Web" : Platform.operatingSystem}, Base URL: $baseUrl';
  }
}
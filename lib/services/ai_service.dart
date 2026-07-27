import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';

/// AI service with dual-provider support: Groq (primary) + Mistral (fallback).
/// Both use OpenAI-compatible chat completion APIs.
///
/// Providers:
///   - Groq: llama-3.3-70b-versatile (fast, structured extraction)
///   - Mistral: mistral-small-latest (reliable fallback)
///
/// Keys are passed via --dart-define=GROQ_API_KEY=xxx --dart-define=MISTRAL_API_KEY=xxx
class AIService {
  AIService._();

  // --- Provider configs ---
  static const _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const _groqModel = 'llama-3.3-70b-versatile';
  static const _mistralUrl = 'https://api.mistral.ai/v1/chat/completions';
  static const _mistralModel = 'mistral-small-latest';

  static const _timeout = Duration(seconds: 15);

  /// Parse a job description to extract category, urgency, budget, duration, skills.
  static Future<Map<String, dynamic>> parseJob(String description) async {
    final prompt = '''You are a job analysis assistant for a local services marketplace in Pakistan.
Analyze this job description and return a JSON object with exactly these fields:
- "category": best matching category from: Electrical Work, Plumbing, Carpentry, Painting, Masonry, AC/HVAC, Cleaning, Moving/Transport, Gardening, General Labor
- "urgency": one of "instant", "today", "scheduled"
- "suggestedBudget": reasonable budget in PKR (integer)
- "estimatedDuration": estimated hours (number)
- "requiredSkills": array of 2-4 skill strings

Job description: "$description"

Return ONLY valid JSON, no markdown, no explanation.''';

    try {
      final result = await _chat(prompt, jsonMode: true);
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      // Ensure all expected fields exist with sane defaults
      parsed.putIfAbsent('category', () => 'General Labor');
      parsed.putIfAbsent('urgency', () => 'today');
      parsed.putIfAbsent('suggestedBudget', () => 2500);
      parsed.putIfAbsent('estimatedDuration', () => 2);
      parsed.putIfAbsent('requiredSkills', () => <String>[]);
      return parsed;
    } catch (e) {
      debugPrint('AIService.parseJob error: $e');
      return _defaultJobParse();
    }
  }

  /// Generate a worker bio from rough experience text.
  static Future<Map<String, dynamic>> generateBio(
      String experience, String category) async {
    final prompt = '''You are a profile writer for a local services marketplace in Pakistan.
Write a professional worker bio based on this information.
Return a JSON object with:
- "bio": 2-3 sentence professional bio (English, concise, trustworthy tone)
- "suggestedSkills": array of 3-5 skill strings

Worker category: $category
Experience notes: "$experience"

Return ONLY valid JSON, no markdown, no explanation.''';

    try {
      final result = await _chat(prompt, jsonMode: true);
      final parsed = jsonDecode(result) as Map<String, dynamic>;
      parsed.putIfAbsent('bio', () => _defaultBio()['bio']);
      parsed.putIfAbsent('suggestedSkills', () => _defaultBio()['suggestedSkills']);
      return parsed;
    } catch (e) {
      debugPrint('AIService.generateBio error: $e');
      return _defaultBio();
    }
  }

  /// Generate a smart match note for a worker recommendation.
  static Future<String> getSmartMatchNote({
    required String workerName,
    required double rating,
    required double distanceKm,
    required String category,
    int responseTimeMins = 4,
    int totalJobs = 25,
  }) async {
    final prompt = '''Write a short (under 15 words) recommendation note for a worker on a local services app.
Worker: $workerName, Rating: ${rating.toStringAsFixed(1)}/5, Distance: ${distanceKm.toStringAsFixed(1)}km, Category: $category, Response time: ${responseTimeMins}min, Jobs done: $totalJobs.
Return ONLY the note text, no JSON, no quotes.''';

    try {
      return await _chat(prompt);
    } catch (e) {
      debugPrint('AIService.getSmartMatchNote error: $e');
      return '⚡ Highly recommended worker nearby.';
    }
  }

  // --- Core: chat completion with Groq → Mistral fallback ---

  /// Sends a chat completion request. Tries Groq first, falls back to Mistral.
  static Future<String> _chat(String prompt, {bool jsonMode = false}) async {
    final groqKey = AppConfig.groqApiKey;
    final mistralKey = AppConfig.mistralApiKey;

    // Try Groq (primary — fastest inference)
    if (groqKey.isNotEmpty) {
      try {
        return await _callProvider(
          url: _groqUrl,
          apiKey: groqKey,
          model: _groqModel,
          prompt: prompt,
          jsonMode: jsonMode,
        );
      } catch (e) {
        debugPrint('AIService: Groq failed, trying Mistral: $e');
      }
    }

    // Try Mistral (fallback)
    if (mistralKey.isNotEmpty) {
      return await _callProvider(
        url: _mistralUrl,
        apiKey: mistralKey,
        model: _mistralModel,
        prompt: prompt,
        jsonMode: jsonMode,
      );
    }

    throw StateError(
        'No AI provider configured. Set GROQ_API_KEY or MISTRAL_API_KEY via --dart-define.');
  }

  /// Calls a single OpenAI-compatible chat completion endpoint.
  static Future<String> _callProvider({
    required String url,
    required String apiKey,
    required String model,
    required String prompt,
    bool jsonMode = false,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.3,
      'max_tokens': 512,
    };
    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
          'AI provider returned ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const FormatException('AI provider returned empty choices');
    }
    final message =
        (choices.first as Map<String, dynamic>)['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const FormatException('AI provider returned empty content');
    }
    return content.trim();
  }

  // --- Defaults (used when no provider is configured or all fail) ---

  static Map<String, dynamic> _defaultJobParse() => {
        'category': 'Electrical Work',
        'urgency': 'today',
        'suggestedBudget': 2500,
        'estimatedDuration': 2,
        'requiredSkills': ['Wiring', 'Troubleshooting'],
      };

  static Map<String, dynamic> _defaultBio() => {
        'bio':
            'Experienced local technician in Lahore with high customer rating.',
        'suggestedSkills': ['Punctual', 'Honest Work', 'Experienced'],
      };
}

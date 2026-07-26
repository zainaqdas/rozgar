import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _baseUrl = '/api/ai';

  /// Parse a job description to extract category, urgency, budget, duration, skills
  static Future<Map<String, dynamic>> parseJob(String description) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/parse-job'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'description': description}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['summary'] as Map<String, dynamic>? ?? _defaultJobParse();
    } catch (_) {
      return _defaultJobParse();
    }
  }

  /// Generate a worker bio from rough experience text
  static Future<Map<String, dynamic>> generateBio(
      String experience, String category) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/generate-bio'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'experience': experience, 'category': category}),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['result'] as Map<String, dynamic>? ?? _defaultBio();
    } catch (_) {
      return _defaultBio();
    }
  }

  /// Generate a smart match note for employer view
  static Future<String> getSmartMatchNote({
    required String workerName,
    required double rating,
    required double distanceKm,
    required String category,
    int responseTimeMins = 4,
    int totalJobs = 25,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/smart-match-note'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workerName': workerName,
          'rating': rating,
          'distanceKm': distanceKm,
          'category': category,
          'responseTimeMins': responseTimeMins,
          'totalJobs': totalJobs,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['matchNote'] as String? ?? '⚡ Highly recommended worker nearby.';
    } catch (_) {
      return '⚡ Top match! Reliable local technician.';
    }
  }

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

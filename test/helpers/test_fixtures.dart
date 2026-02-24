import 'dart:convert';
import 'dart:io';

/// Helper class to load test fixtures and expected results
class TestFixtures {
  static const String _fixturesPath = 'test/fixtures';

  /// Load expected results from JSON fixture
  static Future<Map<String, dynamic>> loadExpectedResults() async {
    final file = File('$_fixturesPath/expected_results.json');
    if (!await file.exists()) {
      throw Exception('Fixtures file not found: ${file.path}');
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Get expected KTP result by sample name
  static Future<Map<String, dynamic>> getExpectedKTP(String sampleName) async {
    final fixtures = await loadExpectedResults();
    final ktpSamples = fixtures['ktp_samples'] as Map<String, dynamic>;

    if (!ktpSamples.containsKey(sampleName)) {
      throw Exception('KTP sample not found: $sampleName');
    }

    return ktpSamples[sampleName] as Map<String, dynamic>;
  }

  /// Get expected NPWP result by sample name
  static Future<Map<String, dynamic>> getExpectedNPWP(String sampleName) async {
    final fixtures = await loadExpectedResults();
    final npwpSamples = fixtures['npwp_samples'] as Map<String, dynamic>;

    if (!npwpSamples.containsKey(sampleName)) {
      throw Exception('NPWP sample not found: $sampleName');
    }

    return npwpSamples[sampleName] as Map<String, dynamic>;
  }

  /// Convert expected result to JSON string
  static String toJsonString(Map<String, dynamic> data) {
    return jsonEncode(data);
  }
}

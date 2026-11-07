import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class CareApiException implements Exception {
  const CareApiException(this.message);
  final String message;
}

class CareApi {
  CareApi({
    this.baseUrl = const String.fromEnvironment('TEMANRAWAT_API_BASE_URL'),
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  Future<({String status, List<Json> meals, List<String> messages})>
  generateMeals(Json input, int version) async {
    final response = await _post('api/meal-plans/generate', input, version);
    final meals = _objects(response['meals']);
    for (final meal in meals) {
      _require<String>(meal, 'recipe_name');
      _require<int>(meal, 'servings');
      _require<int>(meal, 'cooking_time');
      _require<String>(meal, 'instructions');
      for (final ingredient in _objects(meal['ingredients'] ?? [])) {
        _require<String>(ingredient, 'ingredient_name');
        _require<String>(ingredient, 'quantity');
      }
      final nutrition = meal['nutrition'];
      if (nutrition != null) {
        for (final key in ['calories', 'protein', 'carbohydrates', 'fat']) {
          _require<num>(_object(nutrition), key);
        }
      }
    }
    return (
      status: _require<String>(response, 'status'),
      meals: meals,
      messages: [
        ..._strings(response['questions']),
        ..._strings(response['review_notes']),
      ],
    );
  }

  Future<
    ({
      String status,
      List<Json> reminders,
      List<String> messages,
      bool hasConflicts,
    })
  >
  generateSchedule(Json input, int version) async {
    final response = await _post('api/schedules/generate', input, version);
    if (_require<int>(response, 'input_version') != version) {
      throw const CareApiException('Versi jadwal berbeda. Buat ulang jadwal.');
    }
    final reminders = _objects(response['reminders']);
    for (final reminder in reminders) {
      _require<String>(reminder, 'title');
      _require<String>(reminder, 'status');
      final scheduleAt = _require<String>(reminder, 'schedule_at');
      if (!scheduleAt.contains('T') || DateTime.tryParse(scheduleAt) == null) {
        throw const CareApiException(
          'Waktu pengingat dari server tidak valid.',
        );
      }
      for (final item in _objects(reminder['reminder_items'] ?? [])) {
        final medicationId = item['medication_id'];
        if (medicationId != null && medicationId is! int) {
          throw const CareApiException('ID obat dari server tidak valid.');
        }
      }
    }
    final conflicts = _strings(response['conflicts']);
    final questions = _strings(response['questions']);
    return (
      status: _require<String>(response, 'status'),
      reminders: reminders,
      messages: [...conflicts, ...questions],
      hasConflicts: conflicts.isNotEmpty || questions.isNotEmpty,
    );
  }

  Future<Json> _post(String path, Json input, int version) async {
    final base = Uri.tryParse(baseUrl);
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const CareApiException(
        'Alamat API belum valid. Atur TEMANRAWAT_API_BASE_URL.',
      );
    }
    final endpoint = base.replace(
      pathSegments: [
        ...base.pathSegments.where((part) => part.isNotEmpty),
        ...path.split('/'),
      ],
    );
    final random = Random.secure();
    final requestId = List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    try {
      final response = await _client
          .post(
            endpoint,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              ...input,
              'request_id': requestId,
              'input_version': version,
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 422) {
          throw const CareApiException(
            'Server menolak format data. Periksa input dan versi skema API.',
          );
        }
        throw CareApiException(
          'Server belum bisa memproses permintaan (HTTP ${response.statusCode}).',
        );
      }
      return _object(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      throw const CareApiException('Server terlalu lama merespons. Coba lagi.');
    } on http.ClientException {
      throw const CareApiException(
        'Server tidak bisa dihubungi. Periksa koneksi dan alamat API.',
      );
    } on FormatException {
      throw const CareApiException(
        'Respons server tidak sesuai skema TemanRawat.',
      );
    }
  }

  static T _require<T>(Json value, String key) {
    final field = value[key];
    if (field is T) return field;
    throw CareApiException(
      'Respons server tidak sesuai skema. Periksa kolom $key.',
    );
  }

  static Json _object(Object? value) {
    if (value is Json) return value;
    throw const CareApiException('Respons server bukan objek JSON yang valid.');
  }

  static List<Json> _objects(Object? value) {
    if (value is List) return value.map(_object).toList();
    throw const CareApiException('Daftar dari server tidak sesuai skema.');
  }

  static List<String> _strings(Object? value) {
    if (value is List && value.every((item) => item is String)) {
      return value.cast<String>().toList();
    }
    throw const CareApiException(
      'Daftar pesan dari server tidak sesuai skema.',
    );
  }

  void close() => _client.close();
}

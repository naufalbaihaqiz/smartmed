import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

const _envApiBaseUrl = String.fromEnvironment('TEMANRAWAT_API_BASE_URL');
const _envApiUrl = String.fromEnvironment('TEMANRAWAT_API_URL');
const _envAltApiUrl = String.fromEnvironment('TEMANRWAT_API_URL');

/// Resolves the default TemanRawat backend URL from `--dart-define` or
/// falls back to the local development server address.
String resolveDefaultApiUrl() {
  if (_envApiBaseUrl.trim().isNotEmpty) return _envApiBaseUrl.trim();
  if (_envApiUrl.trim().isNotEmpty) return _envApiUrl.trim();
  if (_envAltApiUrl.trim().isNotEmpty) return _envAltApiUrl.trim();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000';
  }
  return 'http://127.0.0.1:8000';
}

class CareApiException implements Exception {
  const CareApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class CareApi {
  CareApi({
    String? baseUrl,
    http.Client? client,
  }) : baseUrl = (baseUrl != null && baseUrl.trim().isNotEmpty)
           ? baseUrl.trim()
           : resolveDefaultApiUrl(),
       _client = client ?? http.Client();

  String baseUrl;
  final http.Client _client;

  Future<({String status, List<Json> meals, List<String> messages})>
  generateMeals(Json input, int version) async {
    final response = await _post('api/meal-plans/generate', {
      ...input,
      'budget': input['budget'] ?? 100000.0,
    }, version);
    final meals = _objects(response['meals']);
    for (final meal in meals) {
      _require<String>(meal, 'recipe_name');
      meal['servings'] = _require<num>(meal, 'servings').round();
      meal['cooking_time'] = _require<num>(meal, 'cooking_time').round();
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
        ..._strings(response['questions'] ?? const <String>[]),
        ..._strings(response['review_notes'] ?? const <String>[]),
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
    final responseVersion = response['input_version'];
    if (responseVersion is num && responseVersion.toInt() != version) {
      throw const CareApiException('Versi jadwal berbeda. Buat ulang jadwal.');
    }
    final reminders = _objects(response['reminders']);
    for (final reminder in reminders) {
      _require<String>(reminder, 'title');
      reminder['status'] = (reminder['status'] as String?) ?? 'pending';
      final scheduleAt = _scheduleDateTime(
        _require<String>(reminder, 'schedule_at'),
      );
      if (scheduleAt == null) {
        throw const CareApiException(
          'Waktu pengingat dari server tidak valid.',
        );
      }
      reminder['schedule_at'] = scheduleAt.toIso8601String();
      final rawItems = _objects(reminder['reminder_items'] ?? []);
      for (final item in rawItems) {
        final medicationId = item['medication_id'];
        if (medicationId != null) {
          if (medicationId is num) {
            item['medication_id'] = medicationId.toInt();
          } else {
            throw const CareApiException('ID obat dari server tidak valid.');
          }
        }
      }
      reminder['reminder_items'] = rawItems;
    }
    final conflicts = _strings(response['conflicts'] ?? const <String>[]);
    final questions = _strings(response['questions'] ?? const <String>[]);
    return (
      status: _require<String>(response, 'status'),
      reminders: reminders,
      messages: [...conflicts, ...questions],
      hasConflicts: conflicts.isNotEmpty || questions.isNotEmpty,
    );
  }

  Future<Json> _post(String path, Json input, int version) async {
    final base = Uri.tryParse(baseUrl.trim());
    if (base == null ||
        !['http', 'https'].contains(base.scheme) ||
        base.host.isEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const CareApiException(
        'Alamat API belum valid. Periksa pengaturan URL server TemanRawat.',
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
          .timeout(const Duration(seconds: 90));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (response.statusCode == 422) {
          final missingFields = _missingFields(response.body);
          if (missingFields.isNotEmpty) {
            throw CareApiException(
              'Data wajib belum terkirim: ${missingFields.join(', ')}.',
            );
          }
          throw const CareApiException(
            'Server menolak format data. Periksa input dan versi skema API.',
          );
        }
        if (response.statusCode >= 500) {
          final detail = _serverErrorDetail(response.body);
          throw CareApiException(
            'Layanan AI sedang bermasalah (HTTP ${response.statusCode})'
            '${detail == null ? '' : ': $detail'}',
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
      throw CareApiException(
        'Server tidak bisa dihubungi di $baseUrl. Pastikan backend TemanRawat aktif.',
      );
    } on FormatException {
      throw const CareApiException(
        'Respons server tidak sesuai skema TemanRawat.',
      );
    }
  }

  static List<String> _missingFields(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['detail'] is! List) return const [];
      return (decoded['detail'] as List)
          .whereType<Map>()
          .where((item) => item['type'] == 'missing')
          .map((item) {
            final location = item['loc'];
            if (location is List && location.isNotEmpty) {
              return location.skip(1).join('.');
            }
            return '';
          })
          .where((field) => field.isNotEmpty)
          .toSet()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static String? _serverErrorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map || decoded['detail'] is! String) return null;
      final detail = (decoded['detail'] as String).trim();
      if (detail.isEmpty) return null;
      return detail.length > 240 ? '${detail.substring(0, 240)}…' : detail;
    } on FormatException {
      return null;
    }
  }

  static DateTime? _scheduleDateTime(String value) {
    final cleaned = value.trim();
    final parsed = DateTime.tryParse(cleaned);
    if (parsed != null) return parsed;

    // Normalize daily times such as "07:30", "07.30", or "07:30 WIB".
    final normalized = cleaned
        .replaceAll(RegExp(r'\s*(WIB|WITA|WIT)\s*$', caseSensitive: false), '')
        .replaceAll('.', ':')
        .trim();
    final match = RegExp(
      r'^(0?\d|1\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$',
    ).firstMatch(normalized);
    if (match == null) return null;

    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3) ?? '0'),
    );
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
    if (value is Map) return Map<String, dynamic>.from(value);
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

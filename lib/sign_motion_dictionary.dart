import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'server_config.dart';

class SignMotion {
  const SignMotion({
    required this.animationName,
    required this.durationMs,
    required this.frames,
  });

  final String animationName;
  final int durationMs;
  final List<Map<String, dynamic>> frames;

  Duration get duration => Duration(milliseconds: durationMs);

  factory SignMotion.fromJson(Map<String, dynamic> json) {
    return SignMotion(
      animationName: json['animationName'] as String,
      durationMs: json['durationMs'] as int,
      frames: (json['frames'] as List<dynamic>)
          .map((frame) => Map<String, dynamic>.from(frame as Map))
          .toList(growable: false),
    );
  }
}

Future<Map<String, SignMotion>> loadSignMotionDictionary({
  String logPrefix = 'Sign motion',
}) async {
  String source;
  try {
    final response = await http
        .get(Uri.parse('$wesalServerBaseUrl/api/sign-dictionary'))
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    source = utf8.decode(response.bodyBytes);
    debugPrint('$logPrefix: dictionary loaded from server');
  } catch (_) {
    source = await rootBundle.loadString(
      'assets/signs/sign_motion_dictionary.json',
    );
    debugPrint('$logPrefix: dictionary loaded from local fallback');
  }
  final decoded = jsonDecode(source) as Map<String, dynamic>;
  return decoded.map(
    (word, motion) => MapEntry(
      word,
      SignMotion.fromJson(Map<String, dynamic>.from(motion as Map)),
    ),
  );
}

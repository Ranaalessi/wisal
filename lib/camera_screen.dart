import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'constants.dart';
import 'sidebar_and_about.dart';
import 'server_config.dart';


class CameraToSignScreen extends StatefulWidget {
  const CameraToSignScreen({super.key});

  @override
  State<CameraToSignScreen> createState() => _CameraToSignScreenState();
}

class _CameraToSignScreenState extends State<CameraToSignScreen>
    with WidgetsBindingObserver {
  static const int _captureDurationSeconds = 15;
  static const MethodChannel _handChannel = MethodChannel(
    'wisal/hand_landmarker',
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  CameraController? _cameraController;
  Timer? _translationTimer;
  Timer? _captureLimitTimer;
  Timer? _countdownTimer;

  bool _cameraReady = false;
  bool _templatesReady = false;
  bool _isRunning = false;
  bool _isProcessing = false;
  bool _captureReady = false;
  bool _captureFinished = false;
  int _remainingSeconds = 0;
  String _status = 'جاري تجهيز الكاميرا...';
  String _translationResult = '';
  List<Offset> _handPoints = const [];
  final Queue<List<double>> _sequenceBuffer = Queue<List<double>>();
  final Queue<List<double>> _mirroredSequenceBuffer = Queue<List<double>>();
  List<_CameraTemplate> _templates = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadCameraTemplates();
  }

  Future<void> _loadCameraTemplates() async {
    try {
      String source;
      try {
        final response = await http
            .get(Uri.parse('$wesalServerBaseUrl/api/camera-sign-dictionary'))
            .timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}');
        }
        source = utf8.decode(response.bodyBytes);
        debugPrint('Camera: dictionary loaded from server');
      } catch (_) {
        source = await rootBundle.loadString(
          'assets/signs/camera_motion_templates.json',
        );
        debugPrint('Camera: dictionary loaded from local fallback');
      }
      final decoded = jsonDecode(source) as List<dynamic>;
      if (!mounted) return;
      setState(() {
        _templates = decoded
            .map((item) => _CameraTemplate.fromJson(item as Map))
            .toList(growable: false);
        _templatesReady = _templates.isNotEmpty;
        if (!_templatesReady) _status = 'تعذر تحميل قوالب الكاميرا';
      });
    } catch (error) {
      debugPrint('تعذر تحميل قوالب الكاميرا: $error');
      if (!mounted) return;
      setState(() {
        _templatesReady = false;
        _status = 'تعذر تحميل قوالب الكاميرا';
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await _cameraController?.dispose();
      setState(() {
        _cameraController = controller;
        _cameraReady = true;
        _status = 'الكاميرا جاهزة';
      });
    } catch (error) {
      debugPrint('Camera initialization failed: $error');
      if (mounted) setState(() => _status = 'تعذر تشغيل الكاميرا');
    }
  }

  void _toggleTranslation() {
    if (!_cameraReady) return;
    if (_isRunning) {
      _finishCapture(manual: true);
      return;
    }

    _captureLimitTimer?.cancel();
    _countdownTimer?.cancel();
    setState(() {
      _isRunning = true;
      _captureReady = false;
      _captureFinished = false;
      _remainingSeconds = _captureDurationSeconds;
      _translationResult = '';
      _status = 'جاري التصوير: $_captureDurationSeconds ثانية';
      _sequenceBuffer.clear();
      _mirroredSequenceBuffer.clear();
      _handPoints = const [];
    });
    _detectCurrentFrame();
    _translationTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _detectCurrentFrame(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) return;
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
        _status = _remainingSeconds == 0
            ? 'انتهى التصوير، اضغط ترجمة'
            : 'جاري التصوير: $_remainingSeconds ثواني';
      });
    });
    _captureLimitTimer = Timer(
      const Duration(seconds: _captureDurationSeconds),
      () {
        _finishCapture();
      },
    );
  }

  void _restartCapture() {
    _translationTimer?.cancel();
    _captureLimitTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted || !_cameraReady) return;
    setState(() {
      _isRunning = true;
      _isProcessing = false;
      _captureReady = false;
      _captureFinished = false;
      _remainingSeconds = _captureDurationSeconds;
      _translationResult = '';
      _status = 'جاري التصوير: $_captureDurationSeconds ثانية';
      _sequenceBuffer.clear();
      _mirroredSequenceBuffer.clear();
      _handPoints = const [];
    });
    _detectCurrentFrame();
    _translationTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _detectCurrentFrame(),
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_isRunning) return;
      setState(() {
        _remainingSeconds = math.max(0, _remainingSeconds - 1);
        _status = _remainingSeconds == 0
            ? 'انتهى التصوير، اضغط ترجمة'
            : 'جاري التصوير: $_remainingSeconds ثواني';
      });
    });
    _captureLimitTimer = Timer(
      const Duration(seconds: _captureDurationSeconds),
      () {
        _finishCapture();
      },
    );
  }

  void _finishCapture({bool manual = false}) {
    _translationTimer?.cancel();
    _captureLimitTimer?.cancel();
    _countdownTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _isRunning = false;
      _isProcessing = false;
      _remainingSeconds = 0;
      _captureReady = _sequenceBuffer.length >= 8;
      _captureFinished = true;
      _status = manual
          ? 'تم إيقاف التصوير، اضغط ترجمة'
          : 'انتهى التصوير، اضغط ترجمة';
    });
  }

  void _translateRunningCapture() {
    if (!_isRunning) return;
    _translationTimer?.cancel();
    _captureLimitTimer?.cancel();
    _countdownTimer?.cancel();

    if (_sequenceBuffer.length < 8) {
      setState(() {
        _isRunning = false;
        _isProcessing = false;
        _remainingSeconds = 0;
        _translationResult = '';
        _status = 'لم يتم التقاط حركة واضحة، أعد التصوير';
        _captureReady = false;
        _captureFinished = false;
        _handPoints = const [];
      });
      return;
    }

    final matched = _matchCurrentSequence();
    setState(() {
      _isRunning = false;
      _isProcessing = false;
      _remainingSeconds = 0;
      _translationResult = matched ?? '';
      _status = matched == null
          ? 'الإشارة غير موجودة في القاموس'
          : 'تمت ترجمة الإشارة';
      _captureReady = false;
      _captureFinished = false;
      _handPoints = const [];
    });
  }

  void _translateCurrentSign() {
    if (_isRunning || !_captureFinished) return;
    if (!_captureReady) {
      setState(() {
      _translationResult = '';
      _status = 'لم يتم التقاط حركة واضحة، أعد التصوير';
      _captureFinished = false;
      _captureReady = false;
      _handPoints = const [];
      });
      return;
    }
    final matched = _matchCurrentSequence();
    setState(() {
      _translationResult = matched ?? '';
      _status = matched == null
          ? 'الإشارة غير موجودة في القاموس'
          : 'تمت ترجمة الإشارة';
      _captureReady = false;
      _captureFinished = false;
      _handPoints = const [];
    });
  }

  Future<void> _detectCurrentFrame() async {
    final controller = _cameraController;
    if (!_isRunning || _isProcessing || controller == null) return;
    _isProcessing = true;
    try {
      final picture = await controller.takePicture();
      final response = await _handChannel.invokeMapMethod<String, dynamic>(
        'detectHand',
        {'path': picture.path},
      );
      if (!mounted || !_isRunning) return;

      final coordinates = (response?['coordinates'] as List<dynamic>? ?? const [])
          .map((value) => (value as num).toDouble())
          .toList(growable: false);
      final points = (response?['points'] as List<dynamic>? ?? const [])
          .map((value) {
            final point = Map<dynamic, dynamic>.from(value as Map);
            return Offset(
              (point['x'] as num).toDouble(),
              (point['y'] as num).toDouble(),
            );
          })
          .toList(growable: false);

      if (coordinates.length != 63) {
        setState(() {
          _handPoints = const [];
          _status = 'أدخل يدك كاملة داخل إطار الكاميرا';
        });
        return;
      }

      _sequenceBuffer.add(_normalizeLandmarks(coordinates));
      _mirroredSequenceBuffer.add(_normalizeLandmarks(coordinates, mirror: true));
      while (_sequenceBuffer.length > 64) {
        _sequenceBuffer.removeFirst();
      }
      while (_mirroredSequenceBuffer.length > 64) {
        _mirroredSequenceBuffer.removeFirst();
      }
      final shouldAutoFinish = _hasEnoughMotionForQuickCapture();
      setState(() {
        _handPoints = points;
        if (_remainingSeconds > 0) {
          _status = shouldAutoFinish
              ? 'تم التقاط الحركة، اضغط ترجمة'
              : 'جاري التصوير: $_remainingSeconds ثواني';
        }
      });
      if (shouldAutoFinish) {
        _finishCapture();
      }
    } on PlatformException catch (error) {
      debugPrint('Hand tracking failed: ${error.message}');
      if (mounted) setState(() => _status = 'تعذر قراءة اليد');
    } catch (error) {
      debugPrint('Local translation failed: $error');
      if (mounted) setState(() => _status = 'تعذرت ترجمة الإشارة');
    } finally {
      _isProcessing = false;
    }
  }

  List<double> _normalizeLandmarks(List<double> values, {bool mirror = false}) {
    final points = <List<double>>[];
    for (var index = 0; index < values.length; index += 3) {
      points.add([values[index], values[index + 1], values[index + 2]]);
    }
    final wrist = List<double>.from(points.first);
    final normalized = <double>[];
    for (final point in points) {
      var x = point[0] - wrist[0];
      final y = point[1] - wrist[1];
      final z = point[2] - wrist[2];
      if (mirror) x *= -1;
      normalized.addAll([x, y, z]);
    }

    var palmSize = _distance3(normalized, 9 * 3);
    if (palmSize < 1e-6) palmSize = 1;
    for (var index = 0; index < normalized.length; index++) {
      normalized[index] = normalized[index] / palmSize;
    }
    final wristX = mirror ? 0.5 - wrist[0] : wrist[0] - 0.5;
    normalized.addAll([wristX, wrist[1] - 0.5, wrist[2]]);
    return normalized;
  }

  double _distance3(List<double> values, int offset) {
    final x = values[offset];
    final y = values[offset + 1];
    final z = values[offset + 2];
    return math.sqrt((x * x + y * y + z * z).abs());
  }

  String? _matchCurrentSequence() {
    if (_sequenceBuffer.length < 8 || _templates.isEmpty) return null;
    final rawSequence = _smoothSequence(_sequenceBuffer.toList());
    final rawMirroredSequence = _smoothSequence(_mirroredSequenceBuffer.toList());
    final sequences = <_CandidateSequence>[
      ..._candidateSequences(rawSequence),
      ..._candidateSequences(_trimQuietEdges(rawSequence)),
      if (rawMirroredSequence.length >= 8)
        ..._candidateSequences(rawMirroredSequence),
      if (rawMirroredSequence.length >= 8)
        ..._candidateSequences(_trimQuietEdges(rawMirroredSequence)),
    ];
    final bestScores = <String, double>{};
    for (final sequence in sequences) {
      for (final template in _templates) {
        final score =
            _sequenceScore(sequence.frames, template.sequence) + sequence.penalty;
        final previous = bestScores[template.label];
        if (previous == null || score < previous) {
          bestScores[template.label] = score;
        }
      }
    }
    final matches = bestScores.entries
        .map((entry) => _Match(entry.key, entry.value))
        .toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    final corrected = matches.isEmpty ? null : _resolveCameraMatch(matches, rawSequence);
    debugPrint(
      'Camera sign matches: ${matches.take(5).map((match) => '${match.label}=${match.score.toStringAsFixed(4)}').join(' | ')} | travel=${_wristTravel(rawSequence).toStringAsFixed(3)} | span=${_wristSpan(rawSequence).toStringAsFixed(3)} | corrected=${corrected ?? '-'}',
    );
    return corrected;
  }

  String? _resolveCameraMatch(
    List<_Match> matches,
    List<List<double>> rawSequence,
  ) {
    final best = matches.first;
    final wristTravel = _wristTravel(rawSequence);
    final wristSpan = _wristSpan(rawSequence);
    // This camera dictionary currently contains only "السلام عليكم".
    // Reject a movement that is too different instead of labelling it as السلام.
    if (best.score > 1.15 || wristTravel < 0.25 || wristSpan < 0.10) {
      return null;
    }
    return best.label;
  }

  List<List<double>> _smoothSequence(List<List<double>> sequence) {
    if (sequence.length < 3) return sequence;
    final smoothed = <List<double>>[List<double>.from(sequence.first)];
    for (var row = 1; row < sequence.length; row++) {
      final previous = smoothed.last;
      final current = sequence[row];
      smoothed.add([
        for (var column = 0; column < current.length; column++)
          previous[column] * 0.35 + current[column] * 0.65,
      ]);
    }
    return smoothed;
  }

  double _wristTravel(List<List<double>> sequence) {
    if (sequence.length < 2) return 0;
    var travel = 0.0;
    for (var index = 1; index < sequence.length; index++) {
      final dx = sequence[index][63] - sequence[index - 1][63];
      final dy = sequence[index][64] - sequence[index - 1][64];
      travel += math.sqrt(dx * dx + dy * dy);
    }
    return travel;
  }

  double _wristSpan(List<List<double>> sequence) {
    if (sequence.isEmpty) return 0;
    var minX = double.infinity;
    var maxX = -double.infinity;
    var minY = double.infinity;
    var maxY = -double.infinity;
    for (final row in sequence) {
      minX = math.min(minX, row[63]);
      maxX = math.max(maxX, row[63]);
      minY = math.min(minY, row[64]);
      maxY = math.max(maxY, row[64]);
    }
    return math.max(maxX - minX, maxY - minY);
  }

  bool _hasEnoughMotionForQuickCapture() {
    if (_sequenceBuffer.length < 16) return false;
    final sequence = _smoothSequence(_sequenceBuffer.toList());
    final travel = _wristTravel(sequence);
    final span = _wristSpan(sequence);
    return travel >= 0.42 && span >= 0.12;
  }

  List<List<double>> _trimQuietEdges(List<List<double>> sequence) {
    if (sequence.length < 12) return sequence;
    final speeds = <double>[];
    for (var index = 1; index < sequence.length; index++) {
      final dx = sequence[index][63] - sequence[index - 1][63];
      final dy = sequence[index][64] - sequence[index - 1][64];
      speeds.add(math.sqrt(dx * dx + dy * dy));
    }
    final threshold = speeds.fold<double>(0, math.max) * 0.18;
    if (threshold <= 0) return sequence;

    var start = 0;
    while (start < speeds.length && speeds[start] < threshold) {
      start++;
    }
    var end = speeds.length;
    while (end > start && speeds[end - 1] < threshold) {
      end--;
    }

    start = math.max(0, start - 2);
    end = math.min(sequence.length - 1, end + 2);
    if (end - start + 1 < 8) return sequence;
    return sequence.sublist(start, end + 1);
  }

  List<_CandidateSequence> _candidateSequences(List<List<double>> rawSequence) {
    if (rawSequence.length < 8) return const [];
    final candidates = <_CandidateSequence>[
      _CandidateSequence(_resample(rawSequence, 24), 0),
    ];

    final maxWindow = math.min(rawSequence.length, 44);
    final windowLengths = <int>{24, 28, 32, 36, 40, maxWindow}
        .where((length) => length >= 12 && length <= rawSequence.length)
        .toList()
      ..sort();

    for (final windowLength in windowLengths) {
      final coverage = windowLength / rawSequence.length;
      final penalty = (1 - coverage) * 0.18;
      final step = math.max(1, windowLength ~/ 3);
      for (var start = 0;
          start + windowLength <= rawSequence.length;
          start += step) {
        candidates.add(
          _CandidateSequence(
            _resample(rawSequence.sublist(start, start + windowLength), 24),
            penalty,
          ),
        );
      }
    }
    return candidates;
  }

  double _sequenceScore(List<List<double>> a, List<List<double>> b) {
    final poseScore = _sequenceDistance(a, b);
    final velocityScore = _sequenceDistance(_velocity(a), _velocity(b));
    return poseScore + velocityScore * 1.6;
  }

  List<List<double>> _velocity(List<List<double>> sequence) {
    if (sequence.isEmpty) return sequence;
    final output = <List<double>>[];
    for (var row = 0; row < sequence.length; row++) {
      if (row == 0) {
        output.add(List<double>.filled(sequence[row].length, 0));
        continue;
      }
      final values = <double>[];
      for (var column = 0; column < sequence[row].length; column++) {
        values.add(sequence[row][column] - sequence[row - 1][column]);
      }
      output.add(values);
    }
    return output;
  }

  List<List<double>> _resample(List<List<double>> sequence, int targetLength) {
    if (sequence.length == targetLength) return sequence;
    final output = <List<double>>[];
    for (var target = 0; target < targetLength; target++) {
      final denominator = math.max(targetLength - 1, 1);
      final position = target * (sequence.length - 1) / denominator;
      final left = position.floor();
      final right = position.ceil().clamp(0, sequence.length - 1);
      final amount = position - left;
      final row = <double>[];
      for (var column = 0; column < sequence.first.length; column++) {
        row.add(sequence[left][column] * (1 - amount) +
            sequence[right][column] * amount);
      }
      output.add(row);
    }
    return output;
  }

  double _sequenceDistance(
    List<List<double>> a,
    List<List<double>> b, {
    double wristWeight = 3,
  }) {
    var total = 0.0;
    var weightTotal = 0.0;
    for (var row = 0; row < a.length && row < b.length; row++) {
      for (var column = 0; column < a[row].length && column < b[row].length; column++) {
        final weight = column >= 63 ? wristWeight : 1.0;
        final delta = a[row][column] - b[row][column];
        total += delta * delta * weight;
        weightTotal += weight;
      }
    }
    return weightTotal == 0 ? double.infinity : total / weightTotal;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _translationTimer?.cancel();
      _captureLimitTimer?.cancel();
      _countdownTimer?.cancel();
      _isRunning = false;
      _cameraController?.dispose();
      _cameraController = null;
      _cameraReady = false;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _translationTimer?.cancel();
    _captureLimitTimer?.cancel();
    _countdownTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('وصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isRunning ? Colors.blueAccent : kPrimaryGreen,
                      width: 3,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_cameraReady && _cameraController != null)
                        CameraPreview(_cameraController!)
                      else
                        const Center(child: CircularProgressIndicator()),
                      if (_handPoints.isNotEmpty)
                        CustomPaint(painter: _BlueHandPainter(_handPoints)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _isRunning ? Colors.blueAccent : kPrimaryGreen,
              ),
            ),
            Container(
              constraints: const BoxConstraints(minHeight: 82),
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(16),
              color: isDark ? Colors.grey[900] : Colors.white,
              alignment: Alignment.center,
              child: Text(
                _translationResult.isEmpty
                    ? 'نتيجة الترجمة تظهر هنا'
                    : _translationResult,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: _isRunning
                    ? ElevatedButton.icon(
                        onPressed: () => _finishCapture(manual: true),
                        icon: const Icon(Icons.stop),
                        label: const Text('إنهاء التصوير'),
                      )
                    : _captureFinished
                    ? Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _translateCurrentSign,
                              icon: const Icon(Icons.translate),
                              label: const Text('ترجمة'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _cameraReady ? _restartCapture : null,
                              icon: const Icon(Icons.replay),
                              label: const Text('إعادة التصوير'),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                  onPressed: _cameraReady ? _toggleTranslation : null,
                        icon: const Icon(Icons.videocam),
                        label: const Text('بدء التصوير'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueHandPainter extends CustomPainter {
  const _BlueHandPainter(this.points);

  final List<Offset> points;

  static const connections = <(int, int)>[
    (0, 1), (1, 2), (2, 3), (3, 4),
    (0, 5), (5, 6), (6, 7), (7, 8),
    (5, 9), (9, 10), (10, 11), (11, 12),
    (9, 13), (13, 14), (14, 15), (15, 16),
    (13, 17), (17, 18), (18, 19), (19, 20), (0, 17),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.lightBlueAccent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final pointPaint = Paint()..color = Colors.blueAccent;

    Offset position(Offset point) =>
        Offset((1 - point.dx) * size.width, point.dy * size.height);
    for (final (start, end) in connections) {
      canvas.drawLine(position(points[start]), position(points[end]), linePaint);
    }
    for (final point in points) {
      canvas.drawCircle(position(point), 5, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BlueHandPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _CameraTemplate {
  const _CameraTemplate({required this.label, required this.sequence});

  final String label;
  final List<List<double>> sequence;

  factory _CameraTemplate.fromJson(Map<dynamic, dynamic> json) {
    return _CameraTemplate(
      label: (json['display'] ?? json['label']) as String,
      sequence: (json['sequence'] as List<dynamic>)
          .map(
            (row) => (row as List<dynamic>)
                .map((value) => (value as num).toDouble())
                .toList(growable: false),
          )
          .toList(growable: false),
    );
  }
}

class _CandidateSequence {
  const _CandidateSequence(this.frames, this.penalty);

  final List<List<double>> frames;
  final double penalty;
}

class _Match {
  const _Match(this.label, this.score);

  final String label;
  final double score;
}

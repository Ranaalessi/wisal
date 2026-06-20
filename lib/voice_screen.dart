import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'constants.dart';
import 'sidebar_and_about.dart';
import 'sign_motion_dictionary.dart';

class VoiceToSignScreen extends StatefulWidget {
  const VoiceToSignScreen({super.key});

  @override
  State<VoiceToSignScreen> createState() => _VoiceToSignScreenState();
}

class _VoiceWavePainter extends CustomPainter {
  const _VoiceWavePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final centerY = size.height / 2;
    const barCount = 7;
    final spacing = size.width / (barCount + 1);

    for (var index = 0; index < barCount; index++) {
      final phase = (progress + index / barCount) % 1.0;
      final height = 10 + (phase < 0.5 ? phase : 1 - phase) * 42;
      final x = spacing * (index + 1);
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceWavePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _VoiceToSignScreenState extends State<VoiceToSignScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SpeechToText _speech = SpeechToText();

  WebViewController? _webController;
  late final AnimationController _waveController;
  late final Future<void> _dictionaryReady;

  Map<String, SignMotion> _signMotionDictionary = const {};
  bool _speechReady = false;
  bool _isListening = false;
  bool _isAnimating = false;
  String _transcribedText = 'اضغط على الميكروفون وابدأ التحدث';
  String _characterStatus = 'جاهز';
  int _motionRunId = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _dictionaryReady = _loadDictionary();
    _initializeSpeech();
  }

  Future<void> _loadDictionary() async {
    _signMotionDictionary = await loadSignMotionDictionary(logPrefix: 'Voice');
  }

  Future<void> _initializeSpeech() async {
    final ready = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'done' || status == 'notListening') {
          _finishListening();
        }
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _isListening = false;
          _characterStatus = 'تعذر الاستماع';
          _transcribedText = error.errorMsg;
        });
        _waveController.stop();
      },
    );
    if (!mounted) return;
    setState(() {
      _speechReady = ready;
      if (!ready) {
        _characterStatus = 'الميكروفون غير متاح';
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isAnimating || !_speechReady) return;
    if (_isListening) {
      await _speech.stop();
      await _finishListening();
      return;
    }

    setState(() {
      _isListening = true;
      _characterStatus = 'يستمع...';
      _transcribedText = 'تكلم الآن';
    });
    _waveController.repeat(reverse: true);

    await _speech.listen(
      onResult: _onSpeechResult,
      listenOptions: SpeechListenOptions(
        localeId: 'ar_SA',
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      ),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (!mounted || text.isEmpty) return;
    setState(() {
      _transcribedText = text;
    });
    if (result.finalResult) {
      _finishListening();
    }
  }

  Future<void> _finishListening() async {
    if (!_isListening) return;
    _waveController.stop();
    if (_speech.isListening) await _speech.stop();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _characterStatus = 'يترجم...';
    });

    final spokenText = _transcribedText.trim();
    final normalizedText = _normalizeText(spokenText);
    if (normalizedText.isEmpty || normalizedText == _normalizeText('تكلم الآن')) {
      setState(() {
        _characterStatus = 'جاهز';
        _transcribedText = 'لم يتم التعرف على كلام واضح';
      });
      return;
    }
    await _playRecognizedText(spokenText);
  }

  String _normalizeText(String text) {
    return text
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[\u064B-\u065F\u0640]'), '')
        .replaceAll(RegExp(r'[،,.!؟?]'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  SignMotion? _findMotion(String text) {
    final normalizedText = _normalizeText(text);
    final aliases = <String>{
      normalizedText,
      if (normalizedText == _normalizeText('سلام عليكم'))
        _normalizeText('السلام عليكم'),
      if (normalizedText == _normalizeText('السلام عليكم'))
        _normalizeText('سلام عليكم'),
    };

    for (final alias in aliases) {
      final exact = _signMotionDictionary[alias];
      if (exact != null) return exact;
    }

    final exact = _signMotionDictionary[text];
    if (exact != null) return exact;
    for (final entry in _signMotionDictionary.entries) {
      final normalizedKey = _normalizeText(entry.key);
      if (aliases.contains(normalizedKey)) return entry.value;
    }
    return null;
  }

  Future<void> _playRecognizedText(String text) async {
    try {
      await _dictionaryReady;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _characterStatus = 'خطأ في القاموس';
      });
      return;
    }

    final motion = _findMotion(text);
    if (motion == null) {
      if (!mounted) return;
      setState(() {
        _characterStatus = 'غير موجود في القاموس';
        _transcribedText = text;
      });
      return;
    }

    final runId = ++_motionRunId;
    setState(() {
      _isAnimating = true;
      _characterStatus = 'يعرض الإشارة';
      _transcribedText = text;
    });

    try {
      final animationName = jsonEncode(motion.animationName);
      final durationMs = motion.durationMs;
      await _webController?.runJavaScript('''
        (async () => {
          const viewer = document.querySelector('model-viewer');
          if (!viewer) return;
          if (!viewer.loaded) {
            await new Promise(resolve => viewer.addEventListener('load', resolve, { once: true }));
          }
          await viewer.updateComplete;
          viewer.pause();
          viewer.animationName = $animationName;
          viewer.currentTime = 0;
          await viewer.updateComplete;
          viewer.play();
          window.clearTimeout(window.__wesalVoiceStopTimer);
          window.__wesalVoiceStopTimer = window.setTimeout(() => {
            viewer.pause();
          }, $durationMs);
        })();
      ''');
    } catch (error) {
      debugPrint('تعذر تشغيل حركة الصوت: $error');
    }

    await Future<void>.delayed(Duration(milliseconds: motion.durationMs - 50));
    if (!mounted || runId != _motionRunId) return;
    try {
      await _webController?.runJavaScript(
        "document.querySelector('model-viewer')?.pause();",
      );
    } catch (_) {}
    if (!mounted || runId != _motionRunId) return;
    setState(() {
      _isAnimating = false;
      _characterStatus = 'تمت الترجمة';
    });
  }

  @override
  void dispose() {
    _speech.cancel();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modelUrl = globalSelectedCharacter.trim() == 'نجد'
        ? 'assets/web_avatar/Najd_salam.glb'
        : 'assets/web_avatar/Salman_salam.glb';

    return PopScope(
      canPop: !_isListening && !_isAnimating,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        endDrawer: const WesalSidebar(),
        appBar: AppBar(
          backgroundColor: isDark
              ? Colors.black.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'وصال',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kPrimaryGreen, width: 3),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ModelViewer(
                        key: ValueKey(modelUrl),
                        src: modelUrl,
                        animationName: 'salam_alaykum_full',
                        autoPlay: false,
                        autoRotate: false,
                        cameraControls: false,
                        interactionPrompt: InteractionPrompt.none,
                        cameraOrbit: '0deg 75deg 105%',
                        cameraTarget: '0m 1.12m 0m',
                        backgroundColor: Colors.transparent,
                        onWebViewCreated: (controller) {
                          _webController = controller;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _transcribedText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _characterStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kPrimaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: _isAnimating ? null : _toggleListening,
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: _speechReady ? kPrimaryGreen : Colors.grey,
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_isListening)
                                BoxShadow(
                                  color: kPrimaryGreen.withValues(alpha: 0.3),
                                  blurRadius: 15 + (_waveController.value * 18),
                                  spreadRadius: _waveController.value * 10,
                                ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (_isListening)
                                CustomPaint(
                                  size: const Size(62, 42),
                                  painter: _VoiceWavePainter(
                                    progress: _waveController.value,
                                  ),
                                ),
                              Icon(
                                _isListening ? Icons.stop_rounded : Icons.mic,
                                color: Colors.white,
                                size: _isListening ? 30 : 38,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

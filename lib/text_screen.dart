import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'constants.dart';
import 'sidebar_and_about.dart';
import 'sign_motion_dictionary.dart';

class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({super.key});

  @override
  State<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final FlutterTts _flutterTts = FlutterTts();
  WebViewController? _webController;

  String? _submittedText;
  String? _translationStatus;
  bool _isModelLoaded = false;
  bool _isAnimating = false;
  int _translationRunId = 0;
  Map<String, SignMotion> _signMotionDictionary = const {};
  late final Future<void> _dictionaryReady;
  late final Future<void> _speechReady;

  @override
  void initState() {
    super.initState();
    _dictionaryReady = _loadDictionary();
    _speechReady = _configureSpeech();
  }

  Future<void> _configureSpeech() async {
    await _flutterTts.setLanguage('ar-SA');
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speakText(String text) async {
    try {
      await _speechReady;
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (error) {
      debugPrint('طھط¹ط°ط± ظ†ط·ظ‚ ط§ظ„ظ†طµ: $error');
    }
  }

  Future<void> _loadDictionary() async {
    _signMotionDictionary = await loadSignMotionDictionary(logPrefix: 'Text');
    debugPrint('طھظ… طھط­ظ…ظٹظ„ ظ‚ط§ظ…ظˆط³ ط§ظ„ط­ط±ظƒط§طھ: ${_signMotionDictionary.length} ظƒظ„ظ…ط§طھ');
  }

  Future<void> _executeProceduralBoneRotation(String text) async {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    try {
      await _dictionaryReady;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _translationStatus = 'تعذر تحميل قاموس الحركات';
      });
      debugPrint('فشل تحميل قاموس الحركات: $error');
      return;
    }

    final motion = _signMotionDictionary[trimmedText];
    if (motion == null) {
      if (!mounted) return;
      setState(() {
        _submittedText = null;
        _translationStatus = 'النص غير موجود في القاموس';
        _isAnimating = false;
      });
      return;
    }

    final runId = ++_translationRunId;
    setState(() {
      _submittedText = null;
      _translationStatus = 'جاري الترجمة...';
      _isAnimating = true;
    });

    debugPrint(
      'تم العثور على الحركة: $trimmedText | '
      'animation=${motion.animationName} | duration=${motion.duration.inMilliseconds}ms | '
      'frames=${motion.frames.length}',
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted || runId != _translationRunId) return;
    await _speakText(trimmedText);
    try {
      final animationName = jsonEncode(motion.animationName);
      await _webController?.runJavaScript('''
        (() => {
          const viewer = document.querySelector('model-viewer');
          if (!viewer) return;
          viewer.pause();
          viewer.animationName = $animationName;
          viewer.currentTime = 0;
          viewer.play({ repetitions: 1 });
        })();
      ''');
    } catch (error) {
      debugPrint('تعذر تشغيل حركة الشخصية: $error');
    }

    if (!mounted || runId != _translationRunId) return;
    setState(() {
      _submittedText = trimmedText;
      _translationStatus = null;
    });

    await Future<void>.delayed(motion.duration);
    if (!mounted || runId != _translationRunId) return;
    setState(() {
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assetPath = globalSelectedCharacter.trim() == 'نجد'
        ? 'assets/web_avatar/Najd_salam.glb'
        : 'assets/web_avatar/Salman_salam.glb';

    return Scaffold(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kPrimaryGreen, width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ModelViewer(
                    key: ValueKey(assetPath),
                    src: assetPath,
                    animationName: 'salam_alaykum_full',
                    autoPlay: false,
                    autoRotate: false,
                    cameraControls: false,
                    interactionPrompt: InteractionPrompt.none,
                    cameraOrbit: '0deg 75deg 105%',
                    cameraTarget: '0m 1.12m 0m',
                    backgroundColor: Colors.transparent,
                    javascriptChannels: {
                      JavascriptChannel(
                        'ModelLoaded',
                        onMessageReceived: (_) {
                          if (!mounted || _isModelLoaded) return;
                          setState(() => _isModelLoaded = true);
                        },
                      ),
                    },
                    relatedJs: '''
                      (() => {
                        const notifyLoaded = () => {
                          if (window.ModelLoaded) {
                            window.ModelLoaded.postMessage('loaded');
                          }
                        };
                        const waitForViewer = () => {
                          const viewer = document.querySelector('model-viewer');
                          if (!viewer) {
                            setTimeout(waitForViewer, 100);
                            return;
                          }
                          if (viewer.loaded) {
                            notifyLoaded();
                          } else {
                            viewer.addEventListener('load', notifyLoaded, { once: true });
                          }
                        };
                        waitForViewer();
                      })();
                    ''',
                    onWebViewCreated: (controller) {
                      _webController = controller;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: !_isModelLoaded
                    ? Text(
                        'جاري تحميل الشخصية...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      )
                    : _translationStatus == null
                    ? const SizedBox(height: 20)
                    : Text(
                        _translationStatus!,
                        key: ValueKey(_translationStatus),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              if (_submittedText != null) ...[
                const SizedBox(height: 5),
                Text(
                  _submittedText!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.keyboard_alt_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            hintText: 'اكتب النص المراد ترجمته هنا..',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.send_rounded,
                          color: kPrimaryGreen,
                        ),
                        onPressed: _isAnimating
                            ? null
                            : () {
                                final text = _textController.text;
                                _textController.clear();
                                _executeProceduralBoneRotation(text);
                              },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

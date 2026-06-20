import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'main.dart'; // تأكدي أنه يحتوي على kPrimaryGreen
import 'sidebar_and_about.dart';
import 'sign_translator.dart'; // يجب أن يحتوي هذا الملف على Map باسم signAnimations

class TextToSignScreen extends StatefulWidget {
  const TextToSignScreen({super.key});

  @override
  State<TextToSignScreen> createState() => _TextToSignScreenState();
}

class _TextToSignScreenState extends State<TextToSignScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();

  String _currentAnimation = "Animation";
  String _selectedAvatar = "salman";

  // دالة تنظيف النص
  String _normalizeText(String text) {
    return text
        .trim()
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  // دالة البحث في الـ Data Set
  void _startSignAnimation() {
    String text = _normalizeText(_textController.text);
    if (text.isEmpty) return;

    setState(() {
      // البحث في الـ Data Set (القاموس) مباشرة
      var signAnimations = {
        "مرحبا": "Hello",
        "شكرا": "Thank you",
        "نعم": "Yes",
        "لا": "No",
      };
      _currentAnimation = signAnimations[text] ?? "Animation";

      if (_currentAnimation == "Animation") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الكلمة غير موجودة في قاعدة البيانات')),
        );
      }
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),
      appBar: AppBar(
        title: const Text('وِصال'),
        actions: [
          // زر تبديل الشخصية (سلمان / نجد)
          IconButton(
            icon: Icon(_selectedAvatar == "salman" ? Icons.person : Icons.face),
            onPressed: () => setState(
              () => _selectedAvatar = (_selectedAvatar == "salman")
                  ? "najd"
                  : "salman",
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Spacer(),
          // منطقة العرض
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.grey[900] : Colors.white,
              ),
              child: ClipOval(
                child: ModelViewer(
                  key: ValueKey(
                    _currentAnimation + _selectedAvatar,
                  ), // يضمن التحديث الفوري
                  src: 'assets/$_selectedAvatar.glb',
                  autoPlay: true,
                  cameraControls: false,
                  animationName: _currentAnimation,
                  scale: "0.5 0.5 0.5",
                ),
              ),
            ),
          ),
          const Spacer(),
          // حقل الإدخال
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textAlign: TextAlign.right,
                      decoration: const InputDecoration(
                        hintText: 'اكتب هنا ليتم تحويله لإشارة',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _startSignAnimation(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: kPrimaryGreen),
                    onPressed: _startSignAnimation,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

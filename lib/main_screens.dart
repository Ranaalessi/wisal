import 'dart:async';
import 'package:flutter/material.dart';
import 'camera_screen.dart' show CameraToSignScreen;
import 'constants.dart'; // استيراد الثوابت للوصول لـ kPrimaryGreen و globalSelectedCharacter
import 'notes_screen.dart' show NotesScreen;
import 'sidebar_and_about.dart';
import 'text_screen.dart' show TextToSignScreen;
import 'voice_screen.dart' show VoiceToSignScreen;
import 'package:o3d/o3d.dart';

// دالة مساعدة للحصول على لون الهيدر الأغمق قليلاً
Color getHeaderColor(BuildContext context) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark
      ? Colors.black.withOpacity(0.3)
      : Colors.black.withOpacity(0.04);
}

// --- 1. شاشة اللوجو (Wesal SplashScreen) ---
class WesalSplashScreen extends StatefulWidget {
  const WesalSplashScreen({super.key});

  @override
  State<WesalSplashScreen> createState() => _WesalSplashScreenState();
}

class _WesalSplashScreenState extends State<WesalSplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const CharacterSelectionScreen(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const Spacer(flex: 3),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 1500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.8 + (value * 0.2),
                  child: child,
                ),
              );
            },
            child: Center(
              child: SizedBox(
                width: 220,
                height: 220,
                child: Image.asset(
                  'assets/images/Logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          TweenAnimationBuilder(
            duration: const Duration(milliseconds: 2500),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, double value, child) {
              double textOpacity = (value > 0.4) ? (value - 0.4) * 1.6 : 0;
              return Opacity(
                opacity: textOpacity.clamp(0.0, 1.0),
                child: child,
              );
            },
            child: Text(
              'وصال... لغة واحدة تجمعنا',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? Colors.white : kPrimaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Spacer(flex: 2),
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white38 : kPrimaryGreen.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

// --- 2. شاشة اختيار الشخصية (Character Selection) ---
class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});
  @override
  State<CharacterSelectionScreen> createState() =>
      _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  String selected = 'سلمان';

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: getHeaderColor(context),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'وِصال',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 26),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Text(
                'من فضلك اختر شخصيتك لتبدأ تجربتك',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  _buildCharCard(
                    'سلمان',
                    'assets/web_avatar/Salman.glb',
                    isDark,
                  ),
                  const SizedBox(width: 20),
                  _buildCharCard('نجد', 'assets/web_avatar/Najd.glb', isDark),
                ],
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // حفظ الاختيار الفعلي في المتغير العالمي لتطبيقه في باقي شاشات التطبيق
                    globalSelectedCharacter = selected;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            IntroScreen(characterName: selected),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: Text(
                    'التالي',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCharCard(String name, String modelPath, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selected = name;
          });
        },
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: selected == name ? kPrimaryGreen : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                // 🛠️ حل مشكلة حجب نقرة نجد عبر IgnorePointer
                child: IgnorePointer(
                  ignoring: true,
                  child: O3D(
                    src: modelPath,
                    autoPlay: false,
                    autoRotate: false,
                    cameraControls: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: selected == name
                    ? kPrimaryGreen
                    : (isDark ? Colors.white70 : Colors.black54),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. شاشة الترحيب (Intro Screen) ---
class IntroScreen extends StatelessWidget {
  final String characterName;
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();
  const IntroScreen({super.key, required this.characterName});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // ربط مسار الأفاتار بشكل ديناميكي صحيح مع اختيار المستخدم بدون عكس
    String welcomeModelPath = (characterName.trim() == 'نجد')
        ? 'assets/web_avatar/Najd.glb'
        : 'assets/web_avatar/Salman.glb';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),
      appBar: AppBar(
        backgroundColor: getHeaderColor(context),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'وِصال',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.white : kPrimaryGreen,
              size: 30,
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 50),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 5),
              ],
            ),
            child: Text(
              '${characterName == 'نجد' ? 'يا هلا' : 'ارحب'}، انا $characterName وبكون معك في رحلتك في وصال',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const Spacer(),
          // 🛠️ تثبيت نجد وسلمان تماماً في صفحة الترحيب بناء على طلبكِ
          SizedBox(
            height: 250,
            child: O3D(
              src: welcomeModelPath,
              autoPlay: false, // جعلها ثابتة وغير متحركة تلقائياً
              autoRotate: false, // منع الالتفاف التلقائي
              cameraControls: true, // تفعيل التحكم اليدوي فقط إذا رغبتِ باللف
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainSelectionScreen(),
                  ),
                ),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                label: Text(
                  'التالي',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// --- 4. الصفحة الرئيسية (Main Selection Screen) ---
class MainSelectionScreen extends StatelessWidget {
  const MainSelectionScreen({super.key});
  static final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),
      appBar: AppBar(
        backgroundColor: getHeaderColor(context),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'وِصال',
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 26),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.menu,
              color: isDark ? Colors.white : kPrimaryGreen,
              size: 30,
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              'اختار الوسيلة التي تناسبك لبدء رحلتك',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 40),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildOptionCard(
                    context,
                    Icons.mic,
                    'صوت الى اشارة',
                    const VoiceToSignScreen(),
                    isDark,
                  ),
                  _buildOptionCard(
                    context,
                    Icons.text_fields,
                    'نص الى اشارة',
                    const TextToSignScreen(),
                    isDark,
                  ),
                  _buildOptionCard(
                    context,
                    Icons.camera_alt_outlined,
                    'كاميرا الى نص',
                    const CameraToSignScreen(),
                    isDark,
                  ),
                  _buildOptionCard(
                    context,
                    Icons.description_outlined,
                    'الملاحظات',
                    const NotesScreen(),
                    isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget destination,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: isDark ? Colors.white70 : kPrimaryGreen.withOpacity(0.8),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

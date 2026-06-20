// sidebar_and_about.dart
import 'package:flutter/material.dart';
import 'main.dart';
import 'main_screens.dart';
import 'voice_screen.dart';
import 'text_screen.dart';
import 'notes_screen.dart';
import 'package:flutter_application_1/camera_screen.dart';
import 'package:url_launcher/url_launcher.dart';

const String _instagramUrl = 'https://www.instagram.com/wisal.004';
const String _tiktokUrl =
    'https://www.tiktok.com/@wisal.044?_r=1&_t=ZS-97Kfg5uCLgK';
const String _xUrl = 'https://x.com/wisal004?s=21';

Future<void> _openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// --- 1. المتحكم في الإعدادات ---
class SettingsController {
  static void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  static void updateFontSize(double newScale) {
    fontSizeNotifier.value = newScale;
  }
}

// --- 2. القائمة الجانبية (WesalSidebar) ---
class WesalSidebar extends StatelessWidget {
  const WesalSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: Container(
        color: isDark ? const Color(0xFF1A1A1A) : kPrimaryGreen,
        child: SafeArea(
          child: ValueListenableBuilder<double>(
            valueListenable: fontSizeNotifier,
            builder: (context, factor, _) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 50),
                          Center(
                            child: Text(
                              'وِصال',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36 * factor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tahoma',
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _sidebarItem(
                            context,
                            Icons.home_rounded,
                            'الصفحة الرئيسية',
                            const MainSelectionScreen(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.mic_rounded,
                            'صوت إلى إشارة',
                            const VoiceToSignScreen(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.text_fields_rounded,
                            'نص إلى إشارة',
                            const TextToSignScreen(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.camera_alt_rounded,
                            'كاميرا إلى نص',
                            const CameraToSignScreen(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.edit_note_rounded,
                            'الملاحظات',
                            const NotesScreen(),
                            factor,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Divider(
                              color: Colors.white24,
                              indent: 30,
                              endIndent: 30,
                            ),
                          ),

                          _sidebarItem(
                            context,
                            Icons.settings_rounded,
                            'الإعدادات',
                            const SettingsPage(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.info_outline_rounded,
                            'عن وصال',
                            const AboutWisalPage(),
                            factor,
                          ),
                          _sidebarItem(
                            context,
                            Icons.mail_outline_rounded,
                            'تواصل معنا',
                            const ContactScreen(),
                            factor,
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _sidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    Widget? destination,
    double factor,
  ) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
        leading: Icon(icon, color: Colors.white, size: 28 * factor),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18 * factor,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (destination != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          }
        },
      ),
    );
  }
}

// --- 3. شاشة الإعدادات (SettingsPage) ---
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : kLightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kPrimaryGreen),
        title: _dynamicTitle("الإعدادات"),
      ),
      body: ValueListenableBuilder<double>(
        valueListenable: fontSizeNotifier,
        builder: (context, factor, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _sectionHeader("عام", textColor, factor),
              _card([
                _listTile(
                  Icons.language,
                  "اللغة",
                  textColor,
                  factor,
                  trailing: _langLabel(textColor, factor),
                ),
              ], cardColor),
              const SizedBox(height: 25),
              _sectionHeader("المظهر", textColor, factor),
              _card([
                _themeToggle(textColor, factor),
                Divider(
                  height: 30,
                  color: isDark ? Colors.white24 : Colors.grey[200],
                ),
                _fontSizeSlider(textColor, factor),
              ], cardColor),
              const SizedBox(height: 25),
              _sectionHeader("حول", textColor, factor),
              _card([
                _listTile(
                  Icons.shield_outlined,
                  "سياسة الخصوصية",
                  textColor,
                  factor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyPage(),
                    ),
                  ),
                ),
                Divider(color: isDark ? Colors.white24 : Colors.grey[200]),
                _listTile(
                  Icons.description_outlined,
                  "شروط الخدمة",
                  textColor,
                  factor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServicePage(),
                    ),
                  ),
                ),
              ], cardColor),
            ],
          );
        },
      ),
    );
  }

  Widget _dynamicTitle(String txt) => ValueListenableBuilder<double>(
    valueListenable: fontSizeNotifier,
    builder: (context, factor, _) => Text(
      txt,
      style: TextStyle(
        color: kPrimaryGreen,
        fontWeight: FontWeight.bold,
        fontSize: 22 * factor,
      ),
    ),
  );

  Widget _sectionHeader(String title, Color color, double factor) => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 10, bottom: 10),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18 * factor,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    ),
  );

  Widget _card(List<Widget> children, Color color) => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(children: children),
  );

  Widget _fontSizeSlider(Color textColor, double factor) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Icon(Icons.format_size, color: kPrimaryGreen, size: 24 * factor),
        const SizedBox(width: 15),
        Text(
          "حجم الخط",
          style: TextStyle(fontSize: 16 * factor, color: textColor),
        ),
        Expanded(
          child: Slider(
            value: fontSizeNotifier.value,
            min: 0.8,
            max: 1.6,
            activeColor: kPrimaryGreen,
            onChanged: (v) => SettingsController.updateFontSize(v),
          ),
        ),
      ],
    );
  }

  Widget _themeToggle(Color textColor, double factor) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        bool isDark = mode == ThemeMode.dark;
        return Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: kPrimaryGreen,
              size: 24 * factor,
            ),
            const SizedBox(width: 15),
            Text(
              "النمط",
              style: TextStyle(fontSize: 16 * factor, color: textColor),
            ),
            const Spacer(),
            _toggleBody(isDark, factor),
          ],
        );
      },
    );
  }

  Widget _toggleBody(bool isDark, double factor) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: isDark ? Colors.black26 : Colors.grey[200],
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _tglBtn(
          "داكن",
          Icons.nightlight_round,
          isDark,
          factor,
          () => SettingsController.toggleTheme(true),
        ),
        _tglBtn(
          "فاتح",
          Icons.wb_sunny_rounded,
          !isDark,
          factor,
          () => SettingsController.toggleTheme(false),
        ),
      ],
    ),
  );

  Widget _tglBtn(
    String t,
    IconData icon,
    bool active,
    double factor,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * factor, vertical: 8),
      decoration: BoxDecoration(
        color: active
            ? (themeNotifier.value == ThemeMode.dark
                  ? kPrimaryGreen
                  : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        boxShadow: active
            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t,
            style: TextStyle(
              fontSize: 13 * factor,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active
                  ? (themeNotifier.value == ThemeMode.dark
                        ? Colors.white
                        : Colors.black)
                  : Colors.grey,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            icon,
            size: 14 * factor,
            color: active
                ? (themeNotifier.value == ThemeMode.dark
                      ? Colors.white
                      : Colors.orange)
                : Colors.grey,
          ),
        ],
      ),
    ),
  );

  Widget _listTile(
    IconData i,
    String t,
    Color textColor,
    double factor, {
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(i, color: kPrimaryGreen, size: 26 * factor),
            const SizedBox(width: 20),
            Text(
              t,
              style: TextStyle(fontSize: 16 * factor, color: textColor),
            ),
            const Spacer(),
            trailing ??
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 14 * factor,
                  color: Colors.grey[400],
                ),
          ],
        ),
      ),
    );
  }

  Widget _langLabel(Color color, double factor) => Text(
    "العربية",
    style: TextStyle(color: color.withOpacity(0.5), fontSize: 14 * factor),
  );
}

// --- 4. صفحة "عن وصال" ---
class AboutWisalPage extends StatelessWidget {
  const AboutWisalPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    const Color kDeepDark = Color(0xFF121212);
    const Color kCardDark = Color(0xFF1E1E1E);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? kDeepDark : kLightBackground,
        body: CustomScrollView(
          slivers: [
            _buildSliverAppBar(isDark),
            SliverToBoxAdapter(
              child: ValueListenableBuilder<double>(
                valueListenable: fontSizeNotifier,
                builder: (context, factor, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoCard(
                        "رؤيتنا",
                        "نطمح لأن نكون الجسر الرقمي الأول الذي يجمع بين التقنية والهوية الثقافية...",
                        Icons.visibility_rounded,
                        factor,
                        isDark,
                        kCardDark,
                      ),
                      _buildInfoCard(
                        "من نحن؟",
                        "وصال هو تطبيق إلكتروني مبتكر مدعوم بتقنيات الذكاء الاصطناعي...",
                        Icons.groups_rounded,
                        factor,
                        isDark,
                        kCardDark,
                      ),
                      _buildInfoCard(
                        "أبطال وصال",
                        "نعتز بشخصياتنا (سلمان ونجد) التي تمثل الزي السعودي الأصيل...",
                        Icons.workspace_premium_rounded,
                        factor,
                        isDark,
                        kCardDark,
                      ),
                      _buildInfoCard(
                        "ماذا نقدم؟",
                        "نقدم منصة متكاملة تتيح للمستخدمين أدوات تواصل متطورة...",
                        Icons.auto_awesome_rounded,
                        factor,
                        isDark,
                        kCardDark,
                      ),
                      _buildInfoCard(
                        "أهدافنا",
                        "نسعى لتحسين جودة حياة الصم والبكم وتعزيز اندмаجهم في المجتمع...",
                        Icons.track_changes_rounded,
                        factor,
                        isDark,
                        kCardDark,
                      ),
                      const SizedBox(height: 20),
                      _teamMemberCard(isDark, factor, kCardDark, kDeepDark),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(bool isDark) => SliverAppBar(
    expandedHeight: 240,
    pinned: true,
    flexibleSpace: FlexibleSpaceBar(
      background: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [kPrimaryGreen, kPrimaryGreen.withOpacity(0.8)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Image.asset(
                  'assets/images/Logo.png',
                  width: 100,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image, size: 60, color: kPrimaryGreen),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "وِصال",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildInfoCard(
    String title,
    String content,
    IconData icon,
    double factor,
    bool isDark,
    Color kCardDark,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? kCardDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: kPrimaryGreen.withOpacity(0.1)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: kPrimaryGreen, size: 28),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18 * factor,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryGreen,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15 * factor,
                  height: 1.5,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _teamMemberCard(
    bool isDark,
    double factor,
    Color kCardDark,
    Color kDeepDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [kCardDark, kDeepDark]
              : [Colors.white, const Color(0xFFF1F8E9)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20),
        ],
      ),
      child: Column(
        children: [
          Text(
            "صُنّاع وصال",
            style: TextStyle(
              fontSize: 20 * factor,
              fontWeight: FontWeight.bold,
              color: kPrimaryGreen,
            ),
          ),
          const Divider(height: 30),
          Text(
            "إشراف: د. جبريل عمر العماري",
            style: TextStyle(
              fontSize: 16 * factor,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children:
                [
                      "ناريمان مقبول العمري",
                      "ريناد عوض العمري",
                      "ريم عوض العمري",
                      "رغد محمد العمري",
                      "رنا محمد العيسي",
                    ]
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        backgroundColor: kPrimaryGreen.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

// --- 5. شاشة تواصل معنا (ContactScreen) ---
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color textColor = isDark ? Colors.white : Colors.black87;
    Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : kLightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: kPrimaryGreen),
          title: ValueListenableBuilder<double>(
            valueListenable: fontSizeNotifier,
            builder: (context, factor, _) => Text(
              "تواصل معنا",
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22 * factor,
              ),
            ),
          ),
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: fontSizeNotifier,
          builder: (context, factor, _) {
            return ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                const SizedBox(height: 10),
                _contactCardIcon(
                  Icons.email_rounded,
                  "البريد الإلكتروني",
                  "wisalhelp04@gmail.com",
                  kPrimaryGreen,
                  cardColor,
                  textColor,
                  factor,
                ),
                _contactCardImage(
                  'assets/images/instagram_logo.png',
                  "انستغرام",
                  "wisal.004",
                  cardColor,
                  textColor,
                  factor,
                  onTap: () => _openExternalUrl(_instagramUrl),
                  bgColor: const Color(0xFFE1306C).withOpacity(0.1),
                ),
                _contactCardImage(
                  'assets/images/tiktok_logo.png',
                  "تيك توك",
                  "wisal.044",
                  cardColor,
                  textColor,
                  factor,
                  onTap: () => _openExternalUrl(_tiktokUrl),
                  bgColor: isDark
                      ? Colors.white12
                      : Colors.black.withOpacity(0.05),
                  isTikTok: true,
                ),
                _contactCardImage(
                  'assets/images/x_logo.png',
                  "X",
                  "wisal004",
                  cardColor,
                  textColor,
                  factor,
                  onTap: () => _openExternalUrl(_xUrl),
                  bgColor: isDark
                      ? Colors.white12
                      : Colors.black.withOpacity(0.05),
                  isX: true,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _contactCardIcon(
    IconData icon,
    String platform,
    String handle,
    Color iconColor,
    Color cardColor,
    Color textColor,
    double factor,
  ) {
    return _baseCard(
      cardColor,
      factor,
      child: Row(
        children: [
          Container(
            width: 50 * factor,
            height: 50 * factor,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 26 * factor),
          ),
          _cardTextContent(platform, handle, textColor, factor),
        ],
      ),
    );
  }

  Widget _contactCardImage(
    String path,
    String platform,
    String handle,
    Color cardColor,
    Color textColor,
    double factor, {
    VoidCallback? onTap,
    required Color bgColor,
    bool isX = false,
    bool isTikTok = false,
  }) {
    return _baseCard(
      cardColor,
      factor,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 55 * factor,
            height: 55 * factor,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Image.asset(
              path,
              fit: BoxFit.contain,
              color: (isX || isTikTok) && textColor == Colors.white
                  ? Colors.white
                  : null,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, size: 20),
            ),
          ),
          _cardTextContent(platform, handle, textColor, factor),
        ],
      ),
    );
  }

  Widget _baseCard(
    Color cardColor,
    double factor, {
    required Widget child,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  Widget _cardTextContent(
    String platform,
    String handle,
    Color textColor,
    double factor,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              platform,
              style: TextStyle(
                fontSize: 13 * factor,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              handle,
              style: TextStyle(
                fontSize: 16 * factor,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================================================
// 🔒 1. شاشة سياسة الخصوصية بالبطاقات الثابتة والخط الفاصل وبدون أيقونات [مطابق لـ image_5903fe.jpg]
// ========================================================================
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final List<Map<String, dynamic>> privacyItems = [
      {
        "title": "البيانات الصوتية والنصية",
        "body":
            "يقوم التطبيق بمعالجة النصوص والمدخلات الصوتية التي يتم التقاطها عبر المايكروفون لغرض واحد فقط، وهو تحويلها برمجياً إلى حركات ديناميكية وتمريرها لمفصل الأفاتار الـ 3D (سلمان ونجد).",
      },
      {
        "title": "تخزين البيانات وسريتها",
        "body":
            "جميع عمليات معالجة الصوت وتحويله إلى نص تتم بشكل فوري ولحظي لتشغيل حركة الإشارة، ولا يتم تسجيل أو حفظ المحادثات الشخصية أو المدخلات داخل خوادم التطبيق لضمان السرية والأمان التام.",
      },
      {
        "title": "أذونات الهاتف",
        "body":
            "يتطلب التطبيق الحصول على إذن الوصول إلى المايكروفون (لتفعيل ميزة تحويل الكلام إلى إشارة) وإذن الاتصال بالإنترنت (لالتواصل مع القاموس المحلي).",
      },
      {
        "title": "مشاركة البيانات",
        "body":
            "نؤكد في إدارة مشروع (وِصال) أننا لا نقوم ببيع، تأجير، أو مشاركة أي بيانات أو مدخلات تخص المستخدمين مع أي جهات خارجية أو أطراف ثالثة لأغراض تجارية.",
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : kLightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: kPrimaryGreen),
          title: ValueListenableBuilder<double>(
            valueListenable: fontSizeNotifier,
            builder: (context, factor, _) => Text(
              "سياسة الخصوصية",
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22 * factor,
              ),
            ),
          ),
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: fontSizeNotifier,
          builder: (context, factor, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: privacyItems.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimaryGreen.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        privacyItems[index]["title"],
                        style: TextStyle(
                          fontSize: 18 * factor,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryGreen,
                        ),
                      ),
                      // 🎯 الخط الفاصل الأنيق والناعم بين العنوان ومحتوى الخصوصية
                      const Divider(
                        height: 20,
                        color: Colors.black12,
                        thickness: 1,
                      ),
                      Text(
                        privacyItems[index]["body"],
                        style: TextStyle(
                          fontSize: 15 * factor,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// ========================================================================
// 📜 2. شاشة شروط الخدمة بالبطاقات الثابتة والخط الفاصل وبدون أيقونات [مطابق لـ image_5903fe.jpg]
// ========================================================================
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    final List<Map<String, dynamic>> termsItems = [
      {
        "title": " طبيعة الخدمة والنطاق الأكاديمي",
        "body":
            "تطبيق 'وِصال' هو مشروع تخرج أكاديمي يهدف إلى خدمة مجتمع الصم والبكم عبر تسهيل التواصل وتقليص الفجوة باستخدام تقنيات التحريك البرمجي للأفاتار ثلاثي الأبعاد.",
      },
      {
        "title": " الاستخدام المقبول والنظامي",
        "body":
            "يُحظر تماماً استخدام التطبيق لإدخال أي نصوص، كلمات، أو أصوات تحتوي على إساءة، تفرقة، أو عبارات تخالف الآداب العامة والأنظمة المحلية المعمول بها.",
      },
      {
        "title": "إخلاء المسؤولية الحركية",
        "body":
            "إن حركات الأفاتار وترجمتها لِلُّغة الإشارية هي نتاج معالجة برمجية رياضية تهدف لتقريب المعنى؛ وبناءً عليه، لا يتحمل مطورو التطبيق مسؤولية أي سوء فهم قد ينتج عن اختلاف سياق الإشارة أو دقة المخرجات.",
      },
      {
        "title": " التعديلات والتحديثات",
        "body":
            "تحتفظ إدارة مشروع (وِصال) بالحق الكامل في تعديل وتحديث القاموس المحلي، أو إضافة حركات وإشارات جديدة بداخل التطبيق لأغراض التطوير الأكاديمي وتحسين الجودة في أي وقت دون إشعار مسبق.",
      },
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : kLightBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: kPrimaryGreen),
          title: ValueListenableBuilder<double>(
            valueListenable: fontSizeNotifier,
            builder: (context, factor, _) => Text(
              "شروط الخدمة",
              style: TextStyle(
                color: kPrimaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 22 * factor,
              ),
            ),
          ),
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: fontSizeNotifier,
          builder: (context, factor, _) {
            return ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: termsItems.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kPrimaryGreen.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        termsItems[index]["title"],
                        style: TextStyle(
                          fontSize: 18 * factor,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryGreen,
                        ),
                      ),
                      // 🎯 الخط الفاصل الأنيق والناعم بين العنوان ومحتوى الشروط
                      const Divider(
                        height: 20,
                        color: Colors.black12,
                        thickness: 1,
                      ),
                      Text(
                        termsItems[index]["body"],
                        style: TextStyle(
                          fontSize: 15 * factor,
                          height: 1.5,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// دالة التثبيت لغلق الأكواد بنجاح
Widget _buildInfoPage(BuildContext context, String title, String content) {
  bool isDark = Theme.of(context).brightness == Brightness.dark;
  return Scaffold(
    backgroundColor: isDark ? Colors.black : kLightBackground,
    appBar: AppBar(
      title: ValueListenableBuilder<double>(
        valueListenable: fontSizeNotifier,
        builder: (context, factor, _) => Text(
          title,
          style: TextStyle(
            color: kPrimaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 20 * factor,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: kPrimaryGreen),
    ),
    body: Center(
      child: ValueListenableBuilder<double>(
        valueListenable: fontSizeNotifier,
        builder: (context, factor, _) => Text(
          content,
          style: TextStyle(
            fontSize: 18 * factor,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    ),
  );
}

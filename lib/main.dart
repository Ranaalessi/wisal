import 'package:flutter/foundation.dart'; // مضافة لدعم الـ WriteBuffer
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart'; // 🔥 إضافة مكتبة الكاميرا

// استيراد الشاشات والملفات الأخرى
import 'sidebar_and_about.dart';
import 'main_screens.dart';
import 'camera_screen.dart';
import 'text_screen.dart';
import 'notes_screen.dart';
import 'voice_screen.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

// --- الثوابت والمنبهات العالمية ---
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);

// 🔥 المنبّه العالمي لحفظ الشخصية المختارة (يستمر ثابت وعابر لكل شاشات التطبيق)
final ValueNotifier<String> selectedAvatarNotifier = ValueNotifier('salman');

// 🔥 قائمة الكاميرات المتاحة عالمياً ليتم استخدامها في شاشة الكاميرا
List<CameraDescription> cameras = [];

const Color kPrimaryGreen = Color(0xFF4C7356);
const Color kLightBackground = Color(0xFFF9F5E7);

void main() async {
  // هذا السطر يضمن تهيئة كل إضافات النظام (مثل الـ 3D والميكروفون والكاميرا) قبل تشغيل الواجهات
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 🔥 جلب الكاميرات المتاحة في الجهاز عند تشغيل التطبيق وتخزينها في القائمة العالمية
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("خطأ أثناء تهيئة الكاميرا: $e");
  }

  runApp(const WesalApp());
}

class WesalApp extends StatelessWidget {
  const WesalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return ValueListenableBuilder<double>(
          valueListenable: fontSizeNotifier,
          builder: (context, fontFactor, _) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'وِصال',
              locale: const Locale('ar', 'SA'),
              themeMode: currentMode,

              // إعدادات النمط الفاتح
              theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Tahoma', // الخط الافتراضي
                brightness: Brightness.light,
                primaryColor: kPrimaryGreen,
                scaffoldBackgroundColor: kLightBackground,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: kPrimaryGreen),
                  titleTextStyle: TextStyle(
                    color: kPrimaryGreen,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tahoma', // توكيد الخط هنا
                  ),
                ),
                // تمرير الخط لجميع النصوص
                textTheme: _buildTextTheme(fontFactor, Brightness.light),
              ),

              // إعدادات النمط الداكن
              darkTheme: ThemeData(
                useMaterial3: true,
                fontFamily: 'Tahoma', // الخط الافتراضي
                brightness: Brightness.dark,
                primaryColor: Colors.tealAccent,
                scaffoldBackgroundColor: const Color(0xFF121212),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  iconTheme: IconThemeData(color: Colors.white),
                  titleTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Tahoma', // توكيد الخط هنا
                  ),
                ),
                // تمرير الخط لجميع النصوص
                textTheme: _buildTextTheme(fontFactor, Brightness.dark),
              ),

              home: const Directionality(
                textDirection: TextDirection.rtl,
                child: WesalSplashScreen(),
              ),
            );
          },
        );
      },
    );
  }

  // دالة بناء نصوص الثيم المحدثة لتوحيد الخط
  TextTheme _buildTextTheme(double factor, Brightness brightness) {
    Color color = brightness == Brightness.dark
        ? Colors.white
        : const Color(0xFF4A4A4A);

    // إنشاء الـ TextTheme الأساسي
    TextTheme baseTextTheme = TextTheme(
      displayLarge: TextStyle(
        fontSize: 32 * factor,
        fontWeight: FontWeight.bold,
        color: brightness == Brightness.dark ? Colors.white : kPrimaryGreen,
      ),
      titleLarge: TextStyle(
        fontSize: 22 * factor,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      titleMedium: TextStyle(
        fontSize: 18 * factor,
        color: color,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(fontSize: 16 * factor, color: color),
      bodyMedium: TextStyle(fontSize: 14 * factor, color: color),
    );

    // استخدام .apply لفرض الخط على كل نمط نصي دون استثناء
    return baseTextTheme.apply(
      fontFamily: 'Tahoma',
      displayColor: baseTextTheme.displayLarge?.color,
      bodyColor: baseTextTheme.bodyLarge?.color,
    );
  }
}

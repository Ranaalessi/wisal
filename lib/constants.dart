import 'package:flutter/material.dart';

// --- 1. المنبهات العالمية (Global Notifiers) ---
// هذي المتغيرات تكون خارج أي كلاس عشان الكل يشوفها مباشرة
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);
final ValueNotifier<double> fontSizeNotifier = ValueNotifier(1.0);

// 👇 هـذا السـطر الـناقص الـذي يسبب الـخطأ الأحمر.. أضيفيه هنا:
String globalSelectedCharacter = 'سلمان';

// --- 2. الألوان الثابتة لمشروع وصال ---
const Color kPrimaryGreen = Color(0xFF4C7356); // اللون الأخضر الأساسي
const Color kLightBackground = Color(0xFFF9F5E7); // لون الخلفية الكريمي

// --- 3. دوال مساعدة للتحكم ---
class SettingsController {
  // دالة تبديل الثيم
  static void toggleTheme(bool isDark) {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  // دالة تحديث حجم الخط
  static void updateFontSize(double newScale) {
    fontSizeNotifier.value = newScale;
  }

  // دالة لجلب لون القائمة الجانبية بناءً على الثيم الحالي
  static Color getSidebarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1A1A1A)
        : kPrimaryGreen;
  }
}

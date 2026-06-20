import 'package:flutter/material.dart';

class HandPainter extends CustomPainter {
  // استقبال النقاط القادمة من البايثون (عبارة عن قائمة فيها إحداثيات x و y)
  final List<Offset> points;

  HandPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. تحديد خصائص قلم الرسم للـ (Points / المفاصل)
    final pointPaint = Paint()
      ..color = Colors
          .cyan // لون نقاط مفاصل اليد
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0; // حجم النقطة

    // 2. تحديد خصائص قلم الرسم للـ (Lines / الخطوط الموصلة بين الأصابع)
    final linePaint = Paint()
      ..color = Colors
          .greenAccent // لون الخطوط الموصلة
      ..strokeWidth = 3.0;

    if (points.isEmpty) return;

    // 3. رسم النقاط على اللوحة الشفافة
    for (var point in points) {
      // تحجيم النقاط لتتناسب مع أبعاد شاشة الجوال الحالية
      double x = point.dx * size.width;
      double y = point.dy * size.height;
      canvas.drawCircle(Offset(x, y), 5, pointPaint);
    }

    // 4. توصيل النقاط ببعضها لرسم هيكل اليد (اختياري ويعطي مظهر ذكي جداً)
    // مصفوفة الاتصالات بمكتبة MediaPipe تتكون من 21 مفصل، هنا نصل النقاط المتتالية كمثال سريع:
    for (int i = 0; i < points.length - 1; i++) {
      // نتخطى قفزات الأصابع ليكون الرسم دقيقاً
      if (i == 4 || i == 8 || i == 12 || i == 16) continue;

      double x1 = points[i].dx * size.width;
      double y1 = points[i].dy * size.height;
      double x2 = points[i + 1].dx * size.width;
      double y2 = points[i + 1].dy * size.height;

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandPainter oldDelegate) {
    // إعادة الرسم فقط إذا تغيرت قيم النقاط مع حركة اليد
    return oldDelegate.points != points;
  }
}

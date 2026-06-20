import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart' show rootBundle;

class PredictionResult {
  const PredictionResult(this.label, this.confidence);

  final String label;
  final double confidence;
}

class ModelService {
  Interpreter? _interpreter;
  List<String> labels = [];

  bool get isLoaded => _interpreter != null && labels.isNotEmpty;

  // دالة تحميل المودل والقاموس
  Future<void> loadModel() async {
    try {
      // 1. تحميل ملف المودل .tflite
      _interpreter = await Interpreter.fromAsset('assets/wisal_model.tflite');

      // 2. تحميل ملف الكلمات labels.txt
      final labelData = await rootBundle.loadString('assets/labels.txt');
      labels = labelData
          .split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList(growable: false);

      print("✅ تم تحميل المودل والقاموس بنجاح!");
    } catch (e) {
      print("❌ فشل التحميل: $e");
    }
  }

  // دالة لإجراء التنبؤ
  PredictionResult predictWithConfidence(List<double> inputData) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Model is not loaded');
    }
    if (inputData.length != 63) {
      throw ArgumentError('Expected 63 hand landmark values');
    }
    // تجهيز مصفوفة المخرجات حسب عدد الكلمات في labels
    final outputSize = interpreter.getOutputTensor(0).shape.last;
    final output = [List<double>.filled(outputSize, 0)];

    // تشغيل المودل
    interpreter.run([inputData], output);

    // اختيار الحركة ذات الاحتمالية الأعلى
    final predictedIndex = output[0].indexOf(
      output[0].reduce((a, b) => a > b ? a : b),
    );

    if (predictedIndex >= labels.length) {
      throw StateError('Model output does not match labels.txt');
    }
    return PredictionResult(labels[predictedIndex], output[0][predictedIndex]);
  }

  PredictionResult predictFromAllowedLabels(
    List<double> inputData,
    Set<String> allowedLabels,
  ) {
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('Model is not loaded');
    }
    if (inputData.length != 63) {
      throw ArgumentError('Expected 63 hand landmark values');
    }

    final outputSize = interpreter.getOutputTensor(0).shape.last;
    final output = [List<double>.filled(outputSize, 0)];
    interpreter.run([inputData], output);

    var bestIndex = -1;
    var bestScore = double.negativeInfinity;
    for (var index = 0; index < output[0].length && index < labels.length; index++) {
      if (!allowedLabels.contains(labels[index])) continue;
      final score = output[0][index];
      if (score > bestScore) {
        bestScore = score;
        bestIndex = index;
      }
    }

    if (bestIndex == -1) {
      return predictWithConfidence(inputData);
    }
    return PredictionResult(labels[bestIndex], bestScore);
  }

  String predict(List<double> inputData) {
    return predictWithConfidence(inputData).label;
  }

  String predictEnglish(List<double> inputData) {
    final prediction = predict(inputData);
    return _englishLabels[prediction] ?? prediction;
  }

  void dispose() => _interpreter?.close();
}

const Map<String, String> _englishLabels = {
  'آسف': 'Sorry',
  'أب': 'Father',
  'أحبك': 'I love you',
  'أحتاج مساعدة': 'I need help',
  'أخ': 'Brother',
  'أخت': 'Sister',
  'أكل': 'Food',
  'ألم هنا': 'Pain here',
  'أم': 'Mother',
  'أنا': 'Me',
  'أنا تعبان': 'I am tired',
  'أنا جوعان': 'I am hungry',
  'أنا زعلان': 'I am upset',
  'أنا سعيد': 'I am happy',
  'أنا مريض': 'I am sick',
  'أنت': 'You',
  'الحمد لله': 'Thank God',
  'السلام عليكم': 'Peace be upon you',
  'الله يعافيك': 'May God keep you well',
  'انتظر شوي': 'Wait a moment',
  'بكرة': 'Tomorrow',
  'تعال هنا': 'Come here',
  'جوال': 'Phone',
  'حادث': 'Accident',
  'خايف': 'Afraid',
  'دكتور': 'Doctor',
  'دواء': 'Medicine',
  'سيارة': 'Car',
  'شكراً': 'Thank you',
  'صح': 'Correct',
  'صيدلية': 'Pharmacy',
  'فلوس': 'Money',
  'كيف الحال': 'How are you?',
  'لا ما أبي': 'No, I do not want it',
  'لو سمحت': 'Please',
  'ما أدري': 'I do not know',
  'مبروك': 'Congratulations',
  'مدرسة': 'School',
  'مستشفى': 'Hospital',
  'مفتاح': 'Key',
  'مو فاهم': 'I do not understand',
  'موافق': 'Agree',
  'موية': 'Water',
  'نعم موافق': 'Yes, I agree',
  'هنا': 'Here',
  'هناك': 'There',
  'وش اسمك': 'What is your name?',
  'وعليكم السلام': 'And peace be upon you',
  'وين الحمام': 'Where is the bathroom?',
  'يسار': 'Left',
  'يمين': 'Right',
};

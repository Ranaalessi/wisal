import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'main.dart'; // يحتوي على selectedAvatarNotifier

class WesalAvatar extends StatelessWidget {
  final String? animationName;

  const WesalAvatar({super.key, this.animationName});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: selectedAvatarNotifier,
      builder: (context, currentAvatar, _) {
        return ModelViewer(
          key: ValueKey(currentAvatar + (animationName ?? "idle")),
          src: 'assets/$currentAvatar.glb',
          autoPlay: true,
          animationName: animationName,
          cameraControls: false, // لا يمكن للمستخدم تحريك الشخصية
          cameraTarget: "0 1.2 0", // إحداثيات ثابتة لكل الشخصيات
          cameraOrbit: "0deg 75deg 2.5m",
          scale: "1 1 1",
        );
      },
    );
  }
}

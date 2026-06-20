import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../sidebar_and_about.dart';
import '../main.dart';

class LiveMotionScreen extends StatefulWidget {
  const LiveMotionScreen({super.key});

  @override
  State<LiveMotionScreen> createState() => _LiveMotionScreenState();
}

class _LiveMotionScreenState extends State<LiveMotionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),
      appBar: AppBar(
        backgroundColor: isDark
            ? Colors.black.withOpacity(0.3)
            : Colors.black.withOpacity(0.04),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            size: 20,
            color: isDark ? Colors.white : kPrimaryGreen,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'وصال - التتبع المباشر',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
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
          const SizedBox(height: 15),
          Text(
            "وجه الكاميرا نحو يدك لتحريك الأفتار حياً",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: kPrimaryGreen, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: const ModelViewer(
                    src: 'assets/web_avatar/avatar_engine.html',
                    autoPlay: true,
                    cameraControls: false,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

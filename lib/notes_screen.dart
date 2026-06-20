import 'package:flutter/material.dart';
import 'main.dart'; // استيراد buildWesalAppBar و kPrimaryGreen
import 'sidebar_and_about.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _notesController = TextEditingController();

  // دالة الحفظ الاختياري
  void _saveNote() {
    if (_notesController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ الملاحظة بنجاح '),
          backgroundColor: kPrimaryGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الملاحظة فارغة، لا يوجد شيء لحفظه'),
          backgroundColor: Color.fromARGB(255, 182, 0, 0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: const WesalSidebar(),

      // --- الهيدر الموحد الجديد ---
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
          'وِصال',
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // أيقونة الحفظ
          IconButton(
            icon: Icon(
              Icons.save_outlined,
              color: isDark ? Colors.white : kPrimaryGreen,
              size: 26,
            ),
            onPressed: _saveNote,
            tooltip: 'حفظ الملاحظة',
          ),
          // أيقونة المنيو
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

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // عنوان الشاشة الفرعي
              const SizedBox(height: 20),

              // صندوق الملاحظات
              Container(
                width: double.infinity,
                height: 400,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: kPrimaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        controller: _notesController,
                        maxLines: null,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 18,
                          height: 1.5,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'اكتب ملاحظاتك هنا...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white38 : Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 15,
                      left: 15,
                      child: Icon(
                        Icons.edit_note,
                        color: kPrimaryGreen.withOpacity(0.3),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "ملاحظة: يمكنك حفظ ما كتبت بالنقر على أيقونة الحفظ في الأعلى.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

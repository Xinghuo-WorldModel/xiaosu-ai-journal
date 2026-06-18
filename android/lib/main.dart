import 'package:flutter/material.dart';
import 'screens/chat_screen.dart';
import 'screens/diary_list_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'services/settings_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XiaosuApp());
}

class XiaosuApp extends StatelessWidget {
  const XiaosuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '小酥',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9B6A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF8F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF8B6F5C),
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _checkedKey = false;

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await SettingsService.hasApiKey();
    setState(() => _checkedKey = true);
    if (!hasKey && mounted) {
      Future.microtask(() {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_checkedKey) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const ChatScreen(),
          const DiaryListScreen(),
          const SearchScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFFFEED9), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFFFF9B6A),
          unselectedItemColor: const Color(0xFF8B6F5C).withOpacity(0.5),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Text('💬', style: TextStyle(fontSize: 22)), label: '聊天'),
            BottomNavigationBarItem(icon: Text('📖', style: TextStyle(fontSize: 22)), label: '日记'),
            BottomNavigationBarItem(icon: Text('🔍', style: TextStyle(fontSize: 22)), label: '搜索'),
            BottomNavigationBarItem(icon: Text('⚙️', style: TextStyle(fontSize: 22)), label: '设置'),
          ],
        ),
      ),
    );
  }
}

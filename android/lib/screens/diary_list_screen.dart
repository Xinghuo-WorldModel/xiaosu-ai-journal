import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import '../services/diary_events.dart';
import 'diary_edit_screen.dart';

class DiaryListScreen extends StatefulWidget {
  const DiaryListScreen({super.key});

  @override
  State<DiaryListScreen> createState() => _DiaryListScreenState();
}

class _DiaryListScreenState extends State<DiaryListScreen> with WidgetsBindingObserver {
  List<DiaryEntry> _diaries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    diaryUpdateNotifier.addListener(_onDiaryUpdated);
    _loadDiaries();
  }

  @override
  void dispose() {
    diaryUpdateNotifier.removeListener(_onDiaryUpdated);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onDiaryUpdated() {
    _loadDiaries();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDiaries();
    }
  }

  Future<void> _loadDiaries() async {
    final entries = await DatabaseService.getAllDiaries();
    if (mounted) setState(() => _diaries = entries);
  }

  void refresh() {
    _loadDiaries();
  }

  Future<void> _deleteDiary(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这篇日记吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await DatabaseService.deleteDiary(id);
      _loadDiaries();
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${date.month}月${date.day}日 ${weekdays[date.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的日记'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const DiaryEditScreen()));
              _loadDiaries();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('写日记'),
          ),
        ],
      ),
      body: _diaries.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('📖', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('还没有日记呢', style: TextStyle(color: Color(0x998B6F5C), fontSize: 14)),
                  SizedBox(height: 4),
                  Text('和小酥聊聊天，或者直接写一篇吧', style: TextStyle(color: Color(0x668B6F5C), fontSize: 12)),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDiaries,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _diaries.length,
                itemBuilder: (context, index) => _buildDiaryCard(_diaries[index]),
              ),
            ),
    );
  }

  Widget _buildDiaryCard(DiaryEntry diary) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryEditScreen(diary: diary)));
        _loadDiaries();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Text('${DateTime.parse(diary.date).day}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8B6F5C))),
                  Text('${DateTime.parse(diary.date).month}月', style: const TextStyle(fontSize: 11, color: Color(0xFFFF9B6A))),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(moodEmojis[diary.mood] ?? '😌', style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(diary.mood, style: const TextStyle(fontSize: 12, color: Color(0xFFFF9B6A))),
                        if (diary.source == 'chat') ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(4)),
                            child: const Text('AI', style: TextStyle(fontSize: 10, color: Color(0xFFFF9B6A))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      diary.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF4A3728)),
                    ),
                    if (diary.keywords.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        children: diary.keywords.take(3).map((kw) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFFFF8F0), borderRadius: BorderRadius.circular(4)),
                          child: Text('#$kw', style: const TextStyle(fontSize: 10, color: Color(0xFFFF9B6A))),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Color(0xFFFFDDB3)),
                onPressed: () => _deleteDiary(diary.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/database_service.dart';
import 'diary_edit_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  List<DiaryEntry> _results = [];
  bool _hasSearched = false;

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    final results = await DatabaseService.searchDiaries(query);
    setState(() {
      _results = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索日记')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: '搜索日记内容、关键词...',
                      hintStyle: TextStyle(color: const Color(0xFF8B6F5C).withOpacity(0.4)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFF9B6A))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF9B6A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Text('搜索'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !_hasSearched
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🔍', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('输入关键词搜索你的日记', style: TextStyle(color: Color(0x998B6F5C), fontSize: 14)),
                        ],
                      ),
                    )
                  : _results.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('😯', style: TextStyle(fontSize: 48)),
                              SizedBox(height: 12),
                              Text('没有找到相关日记', style: TextStyle(color: Color(0x998B6F5C), fontSize: 14)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _results.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('找到 ${_results.length} 篇相关日记', style: const TextStyle(fontSize: 12, color: Color(0xFFFF9B6A))),
                              );
                            }
                            final diary = _results[index - 1];
                            return _buildResultCard(diary);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, {int maxLines = 3}) {
    if (query.isEmpty) {
      return Text(text, maxLines: maxLines, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF4A3728)));
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final idx = lowerText.indexOf(lowerQuery, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: Color(0xFFFFE4CC),
          color: Color(0xFFD4612A),
          fontWeight: FontWeight.w600,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF4A3728)),
        children: spans,
      ),
    );
  }

  Widget _buildResultCard(DiaryEntry diary) {
    final query = _queryController.text.trim();
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryEditScreen(diary: diary)));
        if (_queryController.text.isNotEmpty) _search();
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(moodEmojis[diary.mood] ?? '😌', style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(diary.date, style: const TextStyle(fontSize: 12, color: Color(0xFFFF9B6A))),
                  const SizedBox(width: 6),
                  Text(diary.mood, style: const TextStyle(fontSize: 12, color: Color(0x998B6F5C))),
                ],
              ),
              const SizedBox(height: 8),
              _buildHighlightedText(diary.content, query),
              if (diary.keywords.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: diary.keywords.map((kw) {
                    final isMatch = kw.toLowerCase().contains(query.toLowerCase());
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isMatch ? const Color(0xFFFFE4CC) : const Color(0xFFFFF8F0),
                        borderRadius: BorderRadius.circular(4),
                        border: isMatch ? Border.all(color: const Color(0xFFFFB380), width: 1) : null,
                      ),
                      child: Text('#$kw', style: TextStyle(
                        fontSize: 10,
                        color: isMatch ? const Color(0xFFD4612A) : const Color(0xFFFF9B6A),
                        fontWeight: isMatch ? FontWeight.w600 : FontWeight.normal,
                      )),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }
}

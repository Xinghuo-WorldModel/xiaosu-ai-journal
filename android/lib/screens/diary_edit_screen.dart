import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';

class DiaryEditScreen extends StatefulWidget {
  final DiaryEntry? diary;
  const DiaryEditScreen({super.key, this.diary});

  @override
  State<DiaryEditScreen> createState() => _DiaryEditScreenState();
}

class _DiaryEditScreenState extends State<DiaryEditScreen> {
  final TextEditingController _contentController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _mood = '平静';
  bool _isPolishing = false;
  bool _isSaving = false;
  bool _isListening = false;
  bool _speechAvailable = false;

  final List<String> _moods = ['开心', '平静', '感动', '低落', '焦虑', '疲惫', '生气'];

  @override
  void initState() {
    super.initState();
    if (widget.diary != null) {
      _contentController.text = widget.diary!.content;
      _mood = widget.diary!.mood;
    }
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    setState(() {});
  }

  String _textBeforeListening = '';

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      _textBeforeListening = _contentController.text;
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _contentController.text = _textBeforeListening + result.recognizedWords;
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: _contentController.text.length),
            );
            if (result.finalResult) {
              _textBeforeListening = _contentController.text;
            }
          });
        },
        localeId: 'zh_CN',
      );
    }
  }

  Future<void> _saveDiary() async {
    if (_contentController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final timeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      final content = _contentController.text.trim();
      List<String> keywords = _extractKeywords(content);

      if (widget.diary != null) {
        final entry = DiaryEntry(
          id: widget.diary!.id,
          date: widget.diary!.date,
          content: content,
          mood: _mood,
          keywords: keywords,
          source: 'manual',
          conversations: widget.diary!.conversations,
          createdAt: widget.diary!.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
        await DatabaseService.saveDiary(entry);
      } else {
        final existing = await DatabaseService.getDiaryByDate(today);
        if (existing != null && existing.content.isNotEmpty) {
          final mergedContent = '${existing.content}\n\n[$timeStr] $content';
          final mergedKeywords = <String>{...existing.keywords, ...keywords}.toList();
          final entry = DiaryEntry(
            id: existing.id,
            date: today,
            content: mergedContent,
            mood: _mood,
            keywords: mergedKeywords,
            source: existing.source,
            conversations: existing.conversations,
            createdAt: existing.createdAt,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await DatabaseService.saveDiary(entry);
        } else {
          final entry = DiaryEntry(
            id: const Uuid().v4(),
            date: today,
            content: '[$timeStr] $content',
            mood: _mood,
            keywords: keywords,
            source: 'manual',
            conversations: [],
            createdAt: DateTime.now().millisecondsSinceEpoch,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          );
          await DatabaseService.saveDiary(entry);
        }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _polishDiary() async {
    if (_contentController.text.trim().isEmpty || _isPolishing) return;
    setState(() => _isPolishing = true);

    try {
      final result = await AIService.polishDiary(_contentController.text);
      setState(() {
        _contentController.text = result['content'] as String;
        _mood = result['mood'] as String;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('润色失败，请稍后重试')));
      }
    } finally {
      setState(() => _isPolishing = false);
    }
  }

  List<String> _extractKeywords(String text) {
    final regex = RegExp(r'[\u4e00-\u9fa5]{2,4}');
    final matches = regex.allMatches(text);
    final freq = <String, int>{};
    for (final m in matches) {
      final word = m.group(0)!;
      freq[word] = (freq[word] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).map((e) => e.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.diary != null ? '编辑日记' : '写日记'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveDiary,
            child: Text(_isSaving ? '保存中...' : '保存', style: const TextStyle(color: Color(0xFFFF9B6A))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('今天的心情', style: TextStyle(fontSize: 12, color: Color(0xFFFF9B6A))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _moods.map((m) => ChoiceChip(
                label: Text(m, style: TextStyle(fontSize: 12, color: _mood == m ? Colors.white : const Color(0xFF8B6F5C))),
                selected: _mood == m,
                selectedColor: const Color(0xFFFF9B6A),
                backgroundColor: const Color(0xFFFFF8F0),
                onSelected: (_) => setState(() => _mood = m),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Stack(
                children: [
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: InputDecoration(
                      hintText: '写下今天的故事...',
                      hintStyle: TextStyle(color: const Color(0xFF8B6F5C).withOpacity(0.3)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFF9B6A))),
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF4A3728)),
                  ),
                  if (_speechAvailable)
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: FloatingActionButton.small(
                        onPressed: _toggleListening,
                        backgroundColor: _isListening ? Colors.red.shade100 : const Color(0xFFFFF8F0),
                        child: Text(_isListening ? '🔴' : '🎤', style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isPolishing ? null : _polishDiary,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF9B6A),
                  side: const BorderSide(color: Color(0xFFFFDDB3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_isPolishing ? '小酥正在润色...' : '✨ 让小酥帮我润色'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }
}

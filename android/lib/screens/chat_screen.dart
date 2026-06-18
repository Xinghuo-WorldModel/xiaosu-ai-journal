import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:uuid/uuid.dart';
import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';
import '../services/diary_events.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isLoading = false;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _saveStatus = 'idle'; // idle, saving, saved, error

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _autoSaveDiary(List<ChatMessage> allMessages) async {
    if (allMessages.length < 2) return;

    setState(() => _saveStatus = 'saving');

    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final timeStr = '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}';
        final existing = await DatabaseService.getDiaryByDate(today);

        Map<String, dynamic> result;
        if (existing != null && existing.content.isNotEmpty) {
          result = await AIService.mergeDiary(existing.content, allMessages);
        } else {
          result = await AIService.generateDiary(allMessages);
        }

        final diaryContent = (result['content'] as String?) ?? '';
        if (diaryContent.trim().isEmpty) {
          if (attempt == 0) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          if (mounted) {
            setState(() => _saveStatus = 'error');
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) setState(() => _saveStatus = 'idle');
            });
          }
          return;
        }

        String finalContent;
        if (existing != null && existing.content.isNotEmpty) {
          finalContent = diaryContent;
        } else {
          finalContent = '[$timeStr] $diaryContent';
        }

        final entry = DiaryEntry(
          id: existing?.id ?? const Uuid().v4(),
          date: today,
          content: finalContent,
          mood: (result['mood'] as String?) ?? '平静',
          keywords: <String>{
            ...(existing?.keywords ?? <String>[]),
            ...((result['keywords'] as List?)?.map((e) => e.toString()) ?? <String>[])
          }.toList(),
          source: 'chat',
          conversations: [...(existing?.conversations ?? []), ...allMessages],
          createdAt: existing?.createdAt ?? DateTime.now().millisecondsSinceEpoch,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );

        await DatabaseService.saveDiary(entry);
        notifyDiaryUpdated();
        if (mounted) {
          setState(() => _saveStatus = 'saved');
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _saveStatus = 'idle');
          });
        }
        return;
      } catch (e) {
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        debugPrint('日记保存失败: $e');
        if (mounted) {
          setState(() => _saveStatus = 'error');
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) setState(() => _saveStatus = 'idle');
          });
        }
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final hasKey = await SettingsService.hasApiKey();
    if (!hasKey) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在「设置」中配置 API Key')),
        );
      }
      return;
    }

    final userMsg = ChatMessage(role: 'user', content: text, timestamp: DateTime.now().millisecondsSinceEpoch);
    setState(() {
      _messages.add(userMsg);
      _controller.clear();
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final reply = await AIService.chat(_messages);
      final assistantMsg = ChatMessage(role: 'assistant', content: reply, timestamp: DateTime.now().millisecondsSinceEpoch);
      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });
      _scrollToBottom();
      _autoSaveDiary(List.from(_messages));
    } catch (e) {
      final errMsg = e.toString().contains('API Key') ? '请先在设置中配置 API Key' : '连接失败，请检查网络或 API Key';
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: errMsg, timestamp: DateTime.now().millisecondsSinceEpoch));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _handleNewChat() {
    setState(() {
      _messages.clear();
      _saveStatus = 'idle';
    });
  }

  String _textBeforeListening = '';

  void _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      _textBeforeListening = _controller.text;
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = _textBeforeListening + result.recognizedWords;
          });
          if (result.finalResult) {
            _textBeforeListening = _controller.text;
          }
        },
        localeId: 'zh_CN',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🍪 小酥'),
        actions: [
          if (_messages.isNotEmpty)
            TextButton(
              onPressed: _handleNewChat,
              child: const Text('新对话', style: TextStyle(fontSize: 12, color: Color(0xFFFF9B6A))),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_saveStatus != 'idle')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFFFFF8F0),
              child: Text(
                _saveStatus == 'saving' ? '📝 小酥正在整理日记...'
                    : _saveStatus == 'saved' ? '✅ 日记已更新'
                    : '⚠️ 整理失败，下次会重试',
                style: TextStyle(fontSize: 12, color: _saveStatus == 'error' ? Colors.red : const Color(0xFFFF9B6A)),
              ),
            ),
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) return _buildLoadingBubble();
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🍪', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('嗨，我是小酥', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF8B6F5C))),
          SizedBox(height: 4),
          Text('跟我聊聊今天发生了什么吧～', style: TextStyle(fontSize: 13, color: Color(0x998B6F5C))),
          SizedBox(height: 4),
          Text('聊完后自动帮你整理成日记', style: TextStyle(fontSize: 11, color: Color(0x668B6F5C))),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? Colors.white : const Color(0xFFFFEED9),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              boxShadow: isUser ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
            child: Text(msg.content, style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF4A3728))),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEED9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 40,
              height: 16,
              child: Center(child: Text('...', style: TextStyle(fontSize: 16, color: Color(0xFFFF9B6A)))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: '跟小酥说点什么...',
                hintStyle: TextStyle(color: const Color(0xFF8B6F5C).withOpacity(0.4)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFFF9B6A))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: _speechAvailable
                    ? IconButton(
                        icon: Icon(_isListening ? Icons.stop_circle : Icons.mic, color: _isListening ? Colors.red : const Color(0xFFFF9B6A), size: 22),
                        onPressed: _toggleListening,
                      )
                    : null,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _sendMessage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9B6A),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(12),
              elevation: 2,
            ),
            child: const Icon(Icons.send, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

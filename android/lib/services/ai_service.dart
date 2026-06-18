import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/diary_entry.dart';
import 'settings_service.dart';

class AIService {
  static const String _model = 'kimi-k2.6';

  static Future<Map<String, String>> _getConfig() async {
    final apiKey = await SettingsService.getApiKey();
    final baseUrl = await SettingsService.getBaseUrl();
    final personality = await SettingsService.getPersonality();
    final diaryStyle = await SettingsService.getDiaryStyle();
    return {
      'apiKey': apiKey,
      'baseUrl': baseUrl,
      'personality': personality,
      'diaryStyle': diaryStyle,
    };
  }

  static String _buildChatPrompt(String personality) {
    if (personality.isEmpty) return _systemPrompt;
    return '$_systemPrompt\n\n【用户对你性格的额外要求】\n$personality';
  }

  static String _buildDiaryPrompt(String diaryStyle) {
    if (diaryStyle.isEmpty) return _diaryPrompt;
    return '$_diaryPrompt\n\n【用户对日记风格的额外要求】\n$diaryStyle';
  }

  static String _buildMergePrompt(String diaryStyle) {
    if (diaryStyle.isEmpty) return _mergeDiaryPrompt;
    return '$_mergeDiaryPrompt\n\n【用户对日记风格的额外要求】\n$diaryStyle';
  }

  static const String _systemPrompt = '''你是小酥，一个温暖、善解人意的 AI 日记伙伴。你的特点：
1. 你善于倾听，会用温暖的语气回应用户的心事
2. 你关注用户的情绪状态，在他们低落时给予鼓励和支持
3. 你像一个贴心的朋友，不会说教，而是陪伴
4. 你的回复简洁温暖，不超过 150 字
5. 如果用户提到心理压力大的问题，你会温柔地建议寻求专业帮助

记住：你是陪伴者，不是治疗师。保持温暖、真诚、简洁。''';

  static const String _diaryPrompt = '''请根据以下对话内容，整理成一篇简短的日记。要求：
1. 用第一人称书写
2. 只记录用户说的内容，忽略 AI 的回复部分
3. 保留用户自己的原话和表达方式，不要改写润色
4. 不要写"小酥说了什么""AI安慰了我"之类的内容
5. 朴实、口语化，像自己随手记的
6. 50-150字即可
7. 在最后单独一行用 JSON 格式输出：
{"mood": "情绪标签", "keywords": ["关键词1", "关键词2"]}
情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气''';

  static const String _mergeDiaryPrompt = '''你是日记整理助手。用户今天已有日记，现在又聊了新内容。
请将【已有日记】和【新对话】整合成一篇完整日记。要求：
1. 用第一人称，口语化，朴实记录
2. 只关注用户自己说了什么、经历了什么，不写 AI 的回复
3. 如果已有日记里有时间标记如 [14:30]，保留这些时间标记
4. 新内容也加上当前时间标记
5. 按时间顺序排列
6. 总长度 100-250 字
7. 在最后单独一行用 JSON 格式输出：
{"mood": "情绪标签", "keywords": ["关键词1", "关键词2", "关键词3"]}
情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气''';

  static Future<String> chat(List<ChatMessage> messages) async {
    final config = await _getConfig();
    if (config['apiKey']!.isEmpty) throw Exception('请先在设置中配置 API Key');

    final response = await http.post(
      Uri.parse('${config['baseUrl']}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config['apiKey']}',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': _buildChatPrompt(config['personality']!)},
          ...messages.map((m) => {'role': m.role, 'content': m.content}),
        ],
        'max_tokens': 512,
        'thinking': {'type': 'disabled'},
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('API 请求失败: ${response.statusCode}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return (data['choices'][0]['message']['content'] ?? '') as String;
  }

  static Future<Map<String, dynamic>> generateDiary(List<ChatMessage> conversations) async {
    final config = await _getConfig();
    if (config['apiKey']!.isEmpty) throw Exception('请先在设置中配置 API Key');

    final conversationText = conversations
        .map((m) => '${m.role == "user" ? "我" : "小酥"}: ${m.content}')
        .join('\n');

    final response = await http.post(
      Uri.parse('${config['baseUrl']}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config['apiKey']}',
      },
      body: jsonEncode({
        'model': 'moonshot-v1-8k',
        'messages': [
          {'role': 'system', 'content': _buildDiaryPrompt(config['diaryStyle']!)},
          {'role': 'user', 'content': conversationText},
        ],
        'max_tokens': 1024,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('日记生成失败(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = (data['choices'][0]['message']['content'] ?? '') as String;
    if (text.isEmpty) {
      throw Exception('AI 返回内容为空');
    }

    return _parseDiaryResponse(text);
  }

  static Future<Map<String, dynamic>> mergeDiary(String existingContent, List<ChatMessage> newConversations) async {
    final config = await _getConfig();
    if (config['apiKey']!.isEmpty) throw Exception('请先在设置中配置 API Key');

    final conversationText = newConversations
        .map((m) => '${m.role == "user" ? "我" : "小酥"}: ${m.content}')
        .join('\n');

    final userContent = '【已有日记】\n$existingContent\n\n【新对话】\n$conversationText';

    final response = await http.post(
      Uri.parse('${config['baseUrl']}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config['apiKey']}',
      },
      body: jsonEncode({
        'model': 'moonshot-v1-8k',
        'messages': [
          {'role': 'system', 'content': _buildMergePrompt(config['diaryStyle']!)},
          {'role': 'user', 'content': userContent},
        ],
        'max_tokens': 1024,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('日记合并失败(${response.statusCode}): ${utf8.decode(response.bodyBytes)}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = (data['choices'][0]['message']['content'] ?? '') as String;
    if (text.isEmpty) {
      throw Exception('AI 返回内容为空');
    }

    return _parseDiaryResponse(text);
  }

  static Future<Map<String, dynamic>> polishDiary(String rawContent) async {
    final config = await _getConfig();
    if (config['apiKey']!.isEmpty) throw Exception('请先在设置中配置 API Key');

    final response = await http.post(
      Uri.parse('${config['baseUrl']}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config['apiKey']}',
      },
      body: jsonEncode({
        'model': 'moonshot-v1-8k',
        'messages': [
          {
            'role': 'system',
            'content': '你是一个温暖的文字润色助手。请将用户的日记内容进行轻微润色，保持原意不变，让文字更流畅优美。\n在最后用 JSON 格式输出情绪标签和关键词：\n{"mood": "情绪标签", "keywords": ["关键词1", "关键词2"]}\n情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气'
          },
          {'role': 'user', 'content': rawContent},
        ],
        'max_tokens': 1024,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('润色失败(${response.statusCode})');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final text = (data['choices'][0]['message']['content'] ?? '') as String;
    if (text.isEmpty) {
      throw Exception('AI 返回内容为空');
    }

    return _parseDiaryResponse(text);
  }

  static Map<String, dynamic> _parseDiaryResponse(String text) {
    String mood = '平静';
    List<String> keywords = [];
    String content = text.trim();

    final lines = text.trim().split('\n');
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i].trim();
      if (line.contains('{') && line.contains('}')) {
        // 提取最外层 {} 内容，处理行首可能有其他字符的情况
        final braceStart = line.indexOf('{');
        final braceEnd = line.lastIndexOf('}');
        if (braceStart >= 0 && braceEnd > braceStart) {
          var jsonStr = line.substring(braceStart, braceEnd + 1);
          // 修复中文引号
          jsonStr = jsonStr
              .replaceAll('\u201c', '"')
              .replaceAll('\u201d', '"')
              .replaceAll('\u2018', "'")
              .replaceAll('\u2019', "'")
              .replaceAll('\uff1a', ':')
              .replaceAll('\uff0c', ',');
          try {
            final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (parsed.containsKey('mood') || parsed.containsKey('keywords')) {
              mood = parsed['mood'] as String? ?? '平静';
              keywords = (parsed['keywords'] as List<dynamic>?)
                      ?.map((e) => e.toString())
                      .toList() ??
                  [];
              content = lines.sublist(0, i).join('\n').trim();
              break;
            }
          } catch (_) {
            continue;
          }
        }
      }
    }

    return {'content': content.isNotEmpty ? content : text.trim(), 'mood': mood, 'keywords': keywords};
  }
}

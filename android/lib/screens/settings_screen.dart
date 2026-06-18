import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();
  final _urlController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final key = await SettingsService.getApiKey();
    final url = await SettingsService.getBaseUrl();
    _keyController.text = key;
    _urlController.text = url;
  }

  Future<void> _save() async {
    if (_keyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 API Key')),
      );
      return;
    }
    setState(() => _isSaving = true);
    await SettingsService.setApiKey(_keyController.text.trim());
    await SettingsService.setBaseUrl(_urlController.text.trim());
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('设置已保存 ✓'), backgroundColor: Color(0xFFFF9B6A)),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🍪 配置说明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF8B6F5C))),
                  SizedBox(height: 8),
                  Text(
                    '小酥需要 Kimi API Key 才能工作。\n\n'
                    '获取步骤：\n'
                    '1. 打开 platform.kimi.com\n'
                    '2. 注册/登录账号\n'
                    '3. 进入「API Keys」页面\n'
                    '4. 创建一个新 Key，复制到下方',
                    style: TextStyle(fontSize: 13, height: 1.6, color: Color(0xFF8B6F5C)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('API Key', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8B6F5C))),
            const SizedBox(height: 8),
            TextField(
              controller: _keyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                hintText: 'sk-xxxxxxxxxxxxxxxx',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF9B6A))),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility_off : Icons.visibility, size: 20, color: const Color(0xFF8B6F5C)),
                  onPressed: () => setState(() => _obscureKey = !_obscureKey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('API 地址', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF8B6F5C))),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://api.moonshot.cn/v1',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFFDDB3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF9B6A))),
              ),
            ),
            const SizedBox(height: 8),
            Text('默认为 Kimi 官方地址，一般不需要修改', style: TextStyle(fontSize: 11, color: const Color(0xFF8B6F5C).withOpacity(0.6))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF9B6A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(_isSaving ? '保存中...' : '保存设置'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}

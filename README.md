# 🍪 小酥 - AI 日记伙伴

小酥是一款温暖的 AI 日记应用，帮助你记录每天的生活、管理情绪，同时提供贴心的陪伴。

## 功能特色

- **和小酥聊天** - 与 AI 伙伴对话，小酥会自动将对话整理成温暖的日记
- **手动写日记** - 跳过对话，直接用打字或语音输入编写日记
- **语音输入** - 支持语音转文字，说出你的心情
- **AI 润色** - 让小酥帮你润色手写的日记
- **关键词搜索** - 快速找到过去的记忆
- **情绪记录** - 自动标记每篇日记的情绪状态
- **本地存储** - 所有数据保存在本地，保护你的隐私

## 项目结构

```
xiaosu/
├── web/        # Web 版本 (React + Vite + TailwindCSS)
├── android/    # Android 版本 (Flutter)
└── README.md
```

## Web 版本

### 技术栈
- React 18 + TypeScript
- Vite 5
- TailwindCSS 3
- IndexedDB (via idb)
- Web Speech API

### 运行方式

```bash
cd web

# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

### 配置

编辑 `web/.env` 文件配置 API Key：

```env
VITE_KIMI_API_KEY=你的API密钥
VITE_KIMI_BASE_URL=https://api.moonshot.ai/v1
VITE_KIMI_MODEL=kimi-k2.6
```

## Android 版本 (Flutter)

### 技术栈
- Flutter 3.x / Dart 3.x
- SQLite (sqflite)
- speech_to_text
- Provider

### 运行方式

```bash
cd android

# 获取依赖
flutter pub get

# 运行到设备/模拟器
flutter run

# 构建 APK
flutter build apk
```

### 权限说明
- 麦克风权限 - 语音输入功能
- 网络权限 - 调用 AI API

## API 说明

本项目使用 [Kimi API](https://platform.kimi.ai/)（Moonshot AI），兼容 OpenAI 格式。

### 安全提示

⚠️ Web 版本直接在前端调用 API，API Key 可能被浏览器开发者工具看到。
如果用于生产环境，建议搭建一个后端代理服务来保护 API Key。

## 环境要求

### Web 版本
- Node.js >= 18
- 现代浏览器（Chrome/Edge/Safari）
- 语音功能需要 Chrome 或 Edge 浏览器

### Android 版本
- Flutter SDK >= 3.2.0
- Android SDK
- Android 设备或模拟器

## 设计风格

- 暖色调配色（米白 #FFF8F0 + 暖橙 #FF9B6A + 温棕 #8B6F5C）
- 圆角卡片设计
- 简洁无干扰的界面
- 柔和的阴影和过渡动画

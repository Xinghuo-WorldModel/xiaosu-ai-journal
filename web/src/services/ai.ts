import { Message } from '../utils/types'

const API_KEY = import.meta.env.VITE_KIMI_API_KEY
const BASE_URL = '/api/ai'
const MODEL = import.meta.env.VITE_KIMI_MODEL
const FAST_MODEL = 'moonshot-v1-8k'

function _parseDiaryResponse(text: string): { content: string; mood: string; keywords: string[] } {
  let mood = '平静'
  let keywords: string[] = []
  let content = text.trim()

  const lines = text.trim().split('\n')
  for (let i = lines.length - 1; i >= 0; i--) {
    const line = lines[i].trim()
    if (line.startsWith('{') && line.endsWith('}')) {
      try {
        const parsed = JSON.parse(line)
        if (parsed.mood || parsed.keywords) {
          mood = parsed.mood || '平静'
          keywords = parsed.keywords || []
          content = lines.slice(0, i).join('\n').trim()
          break
        }
      } catch {
        continue
      }
    }
  }

  return { content: content || text.trim(), mood, keywords }
}

function _getUserPersonality(): string {
  return localStorage.getItem('xiaosu_personality') || ''
}

function _getUserDiaryStyle(): string {
  return localStorage.getItem('xiaosu_diary_style') || ''
}

function _buildChatPrompt(): string {
  const personality = _getUserPersonality()
  if (!personality) return SYSTEM_PROMPT
  return `${SYSTEM_PROMPT}\n\n【用户对你性格的额外要求】\n${personality}`
}

function _buildDiaryPrompt(): string {
  const style = _getUserDiaryStyle()
  if (!style) return DIARY_PROMPT
  return `${DIARY_PROMPT}\n\n【用户对日记风格的额外要求】\n${style}`
}

function _buildMergePrompt(): string {
  const style = _getUserDiaryStyle()
  if (!style) return MERGE_DIARY_PROMPT
  return `${MERGE_DIARY_PROMPT}\n\n【用户对日记风格的额外要求】\n${style}`
}

const SYSTEM_PROMPT = `你是小酥，一个温暖、善解人意的 AI 日记伙伴。你的特点：
1. 你善于倾听，会用温暖的语气回应用户的心事
2. 你关注用户的情绪状态，在他们低落时给予鼓励和支持
3. 你像一个贴心的朋友，不会说教，而是陪伴
4. 你的回复简洁温暖，不超过 150 字
5. 如果用户提到心理压力大的问题，你会温柔地建议寻求专业帮助

记住：你是陪伴者，不是治疗师。保持温暖、真诚、简洁。`

const DIARY_PROMPT = `请根据以下对话内容，整理成一篇简短的日记。要求：
1. 用第一人称书写
2. 只记录用户说的内容，忽略 AI 的回复部分
3. 保留用户自己的原话和表达方式，不要改写润色
4. 不要写"小酥说了什么""AI安慰了我"之类的内容
5. 朴实、口语化，像自己随手记的
6. 50-150字即可
7. 在最后单独一行用 JSON 格式输出：
{"mood": "情绪标签", "keywords": ["关键词1", "关键词2"]}
情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气`

const MERGE_DIARY_PROMPT = `你是日记整理助手。用户今天已有日记，现在又聊了新内容。
请将【已有日记】和【新对话】整合成一篇完整日记。要求：
1. 用第一人称，口语化，朴实记录
2. 只关注用户自己说了什么、经历了什么，不写 AI 的回复
3. 如果已有日记里有时间标记如 [14:30]，保留这些时间标记
4. 新内容也加上当前时间标记
5. 按时间顺序排列
6. 总长度 100-250 字
7. 在最后单独一行用 JSON 格式输出：
{"mood": "情绪标签", "keywords": ["关键词1", "关键词2", "关键词3"]}
情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气`

export async function chat(messages: Message[]): Promise<string> {
  const response = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: 'system', content: _buildChatPrompt() },
        ...messages.map(m => ({ role: m.role, content: m.content })),
      ],
      max_tokens: 512,
      thinking: { type: 'disabled' },
    }),
  })

  if (!response.ok) {
    const errBody = await response.text()
    throw new Error(`API 请求失败 (${response.status}): ${errBody}`)
  }

  const data = await response.json()
  return data.choices[0].message.content || '暂时无法回复，请稍后再试'
}

export async function generateDiary(conversations: Message[]): Promise<{
  content: string
  mood: string
  keywords: string[]
}> {
  const conversationText = conversations
    .map(m => `${m.role === 'user' ? '我' : '小酥'}: ${m.content}`)
    .join('\n')

  const response = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`,
    },
    body: JSON.stringify({
      model: FAST_MODEL,
      messages: [
        { role: 'system', content: _buildDiaryPrompt() },
        { role: 'user', content: conversationText },
      ],
      max_tokens: 1024,
    }),
  })

  if (!response.ok) {
    throw new Error(`API 请求失败: ${response.status}`)
  }

  const data = await response.json()
  const text = data.choices[0].message.content || ''

  return _parseDiaryResponse(text)
}

export async function mergeDiary(existingContent: string, newConversations: Message[]): Promise<{
  content: string
  mood: string
  keywords: string[]
}> {
  const conversationText = newConversations
    .map(m => `${m.role === 'user' ? '我' : '小酥'}: ${m.content}`)
    .join('\n')

  const userContent = `【已有日记】\n${existingContent}\n\n【新对话】\n${conversationText}`

  const response = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`,
    },
    body: JSON.stringify({
      model: FAST_MODEL,
      messages: [
        { role: 'system', content: _buildMergePrompt() },
        { role: 'user', content: userContent },
      ],
      max_tokens: 1024,
    }),
  })

  if (!response.ok) {
    throw new Error(`API 请求失败: ${response.status}`)
  }

  const data = await response.json()
  const text = data.choices[0].message.content || ''

  return _parseDiaryResponse(text)
}

export async function polishDiary(rawContent: string): Promise<{
  content: string
  mood: string
  keywords: string[]
}> {
  const response = await fetch(`${BASE_URL}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${API_KEY}`,
    },
    body: JSON.stringify({
      model: FAST_MODEL,
      messages: [
        {
          role: 'system',
          content: `你是一个温暖的文字润色助手。请将用户的日记内容进行轻微润色，保持原意不变，让文字更流畅优美。
在最后用 JSON 格式输出情绪标签和关键词：
{"mood": "情绪标签", "keywords": ["关键词1", "关键词2"]}
情绪标签从以下选择：开心、平静、感动、低落、焦虑、疲惫、生气`,
        },
        { role: 'user', content: rawContent },
      ],
      max_tokens: 1024,
    }),
  })

  if (!response.ok) {
    throw new Error(`API 请求失败: ${response.status}`)
  }

  const data = await response.json()
  const text = data.choices[0].message.content || ''

  return _parseDiaryResponse(text)
}

export interface Message {
  role: 'user' | 'assistant'
  content: string
  timestamp: number
}

export interface DiaryEntry {
  id: string
  date: string
  content: string
  mood: string
  keywords: string[]
  source: 'chat' | 'manual'
  conversations: Message[]
  createdAt: number
  updatedAt: number
}

export type MoodType = '开心' | '平静' | '感动' | '低落' | '焦虑' | '疲惫' | '生气'

export const MOOD_EMOJIS: Record<string, string> = {
  '开心': '😊',
  '平静': '😌',
  '感动': '🥺',
  '低落': '😢',
  '焦虑': '😰',
  '疲惫': '😴',
  '生气': '😤',
}

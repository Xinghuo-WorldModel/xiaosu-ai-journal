import { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import { DiaryEntry } from '../utils/types'
import { getDiary, saveDiary, getDiaryByDate } from '../services/storage'
import { polishDiary } from '../services/ai'
import { notifyDiaryUpdate } from '../services/diaryEvents'
import { useSpeechRecognition } from '../hooks/useSpeechRecognition'

export default function DiaryEditPage() {
  const { id } = useParams()
  const navigate = useNavigate()
  const [content, setContent] = useState('')
  const [mood, setMood] = useState('平静')
  const [isPolishing, setIsPolishing] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [existingEntry, setExistingEntry] = useState<DiaryEntry | null>(null)
  const { isListening, transcript, startListening, stopListening, resetTranscript, isSupported } = useSpeechRecognition()

  useEffect(() => {
    if (id) {
      getDiary(id).then(entry => {
        if (entry) {
          setExistingEntry(entry)
          setContent(entry.content)
          setMood(entry.mood)
        }
      })
    }
  }, [id])

  useEffect(() => {
    if (transcript) {
      setContent(prev => prev + transcript)
      resetTranscript()
    }
  }, [isListening]) // eslint-disable-line

  const handleSave = async () => {
    if (!content.trim() || isSaving) return
    setIsSaving(true)

    try {
      const today = new Date().toISOString().split('T')[0]
      const timeStr = new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })

      if (existingEntry) {
        const entry: DiaryEntry = {
          id: existingEntry.id,
          date: existingEntry.date,
          content: content.trim(),
          mood,
          keywords: extractKeywords(content),
          source: existingEntry.source,
          conversations: existingEntry.conversations,
          createdAt: existingEntry.createdAt,
          updatedAt: Date.now(),
        }
        await saveDiary(entry)
      } else {
        const existing = await getDiaryByDate(today)
        const newContent = `[${timeStr}] ${content.trim()}`

        if (existing) {
          const mergedContent = existing.content + '\n\n' + newContent
          const entry: DiaryEntry = {
            id: existing.id,
            date: today,
            content: mergedContent,
            mood,
            keywords: [...new Set([...existing.keywords, ...extractKeywords(content)])],
            source: existing.source,
            conversations: existing.conversations,
            createdAt: existing.createdAt,
            updatedAt: Date.now(),
          }
          await saveDiary(entry)
        } else {
          const entry: DiaryEntry = {
            id: crypto.randomUUID(),
            date: today,
            content: newContent,
            mood,
            keywords: extractKeywords(content),
            source: 'manual',
            conversations: [],
            createdAt: Date.now(),
            updatedAt: Date.now(),
          }
          await saveDiary(entry)
        }
      }

      notifyDiaryUpdate()
      navigate('/diary')
    } catch {
      alert('保存失败')
    } finally {
      setIsSaving(false)
    }
  }

  const handlePolish = async () => {
    if (!content.trim() || isPolishing) return
    setIsPolishing(true)

    try {
      const result = await polishDiary(content)
      setContent(result.content)
      setMood(result.mood)
    } catch {
      alert('润色失败，请稍后再试')
    } finally {
      setIsPolishing(false)
    }
  }

  const moods = ['开心', '平静', '感动', '低落', '焦虑', '疲惫', '生气']

  return (
    <div className="px-4 py-4 flex flex-col h-[calc(100vh-8rem)]">
      <div className="flex items-center justify-between mb-4">
        <button onClick={() => navigate('/diary')} className="text-warm-500 text-sm">
          ← 返回
        </button>
        <h2 className="text-base font-semibold text-warm-800">
          {id ? '编辑日记' : '写日记'}
        </h2>
        <button
          onClick={handleSave}
          disabled={!content.trim() || isSaving}
          className="btn-primary text-sm px-3 py-1 disabled:opacity-50"
        >
          {isSaving ? '保存中...' : '保存'}
        </button>
      </div>

      <div className="mb-3">
        <label className="text-xs text-warm-500 mb-1 block">今天的心情</label>
        <div className="flex flex-wrap gap-2">
          {moods.map(m => (
            <button
              key={m}
              onClick={() => setMood(m)}
              className={`text-xs px-2.5 py-1 rounded-full transition-colors ${
                mood === m
                  ? 'bg-warm-400 text-white'
                  : 'bg-warm-100 text-warm-600 hover:bg-warm-200'
              }`}
            >
              {m}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 relative">
        <textarea
          value={content}
          onChange={e => setContent(e.target.value)}
          placeholder="写下今天的故事..."
          className="input-field h-full resize-none text-sm leading-relaxed"
        />
        {isSupported && (
          <button
            onClick={isListening ? stopListening : startListening}
            className={`absolute right-3 bottom-3 p-2 rounded-full transition-all ${
              isListening
                ? 'bg-red-100 text-red-500 animate-pulse shadow-md'
                : 'bg-warm-100 text-warm-500 hover:bg-warm-200'
            }`}
            title={isListening ? '停止录音' : '语音输入'}
          >
            🎤
          </button>
        )}
      </div>

      <div className="mt-3">
        <button
          onClick={handlePolish}
          disabled={!content.trim() || isPolishing}
          className="w-full py-2.5 text-sm text-warm-500 border border-warm-200 
                     rounded-xl hover:bg-warm-100 transition-colors disabled:opacity-50"
        >
          {isPolishing ? '小酥正在润色...' : '✨ 让小酥帮我润色'}
        </button>
      </div>
    </div>
  )
}

function extractKeywords(text: string): string[] {
  const words = text.match(/[\u4e00-\u9fa5]{2,4}/g) || []
  const freq = new Map<string, number>()
  words.forEach(w => freq.set(w, (freq.get(w) || 0) + 1))
  return [...freq.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 5)
    .map(([word]) => word)
}

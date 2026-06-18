import { useState, useRef, useEffect, useCallback } from 'react'
import { Message } from '../utils/types'
import { chat, generateDiary, mergeDiary } from '../services/ai'
import { saveDiary, getDiaryByDate } from '../services/storage'
import { notifyDiaryUpdate, setSavingStatus } from '../services/diaryEvents'
import { useSpeechRecognition } from '../hooks/useSpeechRecognition'

export default function ChatPage() {
  const [messages, setMessages] = useState<Message[]>([])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [saveStatus, setSaveState] = useState<'idle' | 'saving' | 'saved' | 'error'>('idle')
  const messagesEndRef = useRef<HTMLDivElement>(null)
  const { isListening, transcript, startListening, stopListening, resetTranscript, isSupported } = useSpeechRecognition()

  useEffect(() => {
    if (transcript) setInput(transcript)
  }, [transcript])

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const autoSaveDiary = useCallback(async (allMessages: Message[]) => {
    if (allMessages.length < 2) return

    setSaveState('saving')
    setSavingStatus(true)

    try {
      const today = new Date().toISOString().split('T')[0]
      const timeStr = new Date().toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
      const existing = await getDiaryByDate(today)

      let result: { content: string; mood: string; keywords: string[] }
      if (existing && existing.content) {
        result = await mergeDiary(existing.content, allMessages)
      } else {
        result = await generateDiary(allMessages)
      }

      if (!result.content || result.content.trim().length === 0) {
        console.warn('AI 返回的日记内容为空，跳过保存')
        setSaveState('error')
        setSavingStatus(false)
        setTimeout(() => setSaveState('idle'), 3000)
        return
      }

      const stampedContent = existing && existing.content
        ? result.content
        : `[${timeStr}] ${result.content}`

      const entry = {
        id: existing?.id || crypto.randomUUID(),
        date: today,
        content: stampedContent,
        mood: result.mood || '平静',
        keywords: result.keywords || [],
        source: 'chat' as const,
        conversations: [...(existing?.conversations || []), ...allMessages],
        createdAt: existing?.createdAt || Date.now(),
        updatedAt: Date.now(),
      }

      await saveDiary(entry)
      setSaveState('saved')
      setSavingStatus(false)
      notifyDiaryUpdate()
      setTimeout(() => setSaveState('idle'), 3000)
    } catch (err) {
      console.error('日记自动保存失败:', err)
      setSaveState('error')
      setSavingStatus(false)
      setTimeout(() => setSaveState('idle'), 5000)
    }
  }, [])

  const sendMessage = async () => {
    const text = input.trim()
    if (!text || isLoading) return

    const userMsg: Message = { role: 'user', content: text, timestamp: Date.now() }
    const updatedMessages = [...messages, userMsg]
    setMessages(updatedMessages)
    setInput('')
    resetTranscript()
    setIsLoading(true)

    try {
      const reply = await chat(updatedMessages)
      const assistantMsg: Message = { role: 'assistant', content: reply, timestamp: Date.now() }
      const finalMessages = [...updatedMessages, assistantMsg]
      setMessages(finalMessages)
      autoSaveDiary(finalMessages)
    } catch (err) {
      const errMessage = err instanceof Error ? err.message : '未知错误'
      setMessages(prev => [...prev, {
        role: 'assistant', content: `连接失败：${errMessage}`, timestamp: Date.now()
      }])
    } finally {
      setIsLoading(false)
    }
  }

  const handleNewChat = () => {
    setMessages([])
    setSaveState('idle')
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault()
      sendMessage()
    }
  }

  return (
    <div className="flex flex-col h-[calc(100vh-8rem)]">
      <div className="px-4 py-1.5 flex items-center justify-between border-b border-warm-100">
        <div className="text-xs text-warm-400">
          {saveStatus === 'saving' && '📝 小酥正在整理日记...'}
          {saveStatus === 'saved' && '✅ 日记已更新'}
          {saveStatus === 'error' && '⚠️ 整理失败，下次会重试'}
          {saveStatus === 'idle' && messages.length > 0 && `对话中`}
        </div>
        {messages.length > 0 && (
          <button onClick={handleNewChat} className="text-xs text-warm-400 hover:text-warm-600 transition-colors">
            开启新对话
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 space-y-3">
        {messages.length === 0 && (
          <div className="text-center py-12">
            <p className="text-4xl mb-3">🍪</p>
            <p className="text-warm-700 font-medium">嗨，我是小酥</p>
            <p className="text-warm-700/60 text-sm mt-1">跟我聊聊今天发生了什么吧～</p>
            <p className="text-warm-700/40 text-xs mt-2">聊完后自动帮你整理成日记</p>
          </div>
        )}

        {messages.map((msg, i) => (
          <div key={i} className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}>
            <div className={`max-w-[80%] px-4 py-2.5 rounded-2xl text-sm leading-relaxed ${
              msg.role === 'user'
                ? 'bg-white shadow-sm text-warm-900 rounded-br-md'
                : 'bg-warm-200/60 text-warm-900 rounded-bl-md'
            }`}>
              {msg.content}
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-warm-200/60 px-4 py-2.5 rounded-2xl rounded-bl-md">
              <span className="inline-flex gap-1">
                <span className="w-1.5 h-1.5 bg-warm-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                <span className="w-1.5 h-1.5 bg-warm-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                <span className="w-1.5 h-1.5 bg-warm-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
              </span>
            </div>
          </div>
        )}

        <div ref={messagesEndRef} />
      </div>

      <div className="px-4 pb-4">
        <div className="flex items-end gap-2">
          <div className="flex-1 relative">
            <textarea
              value={input}
              onChange={e => setInput(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="跟小酥说点什么..."
              rows={1}
              className="input-field pr-10 resize-none min-h-[44px] max-h-[120px]"
            />
            {isSupported && (
              <button
                onClick={isListening ? stopListening : startListening}
                className={`absolute right-2 bottom-2.5 p-1 rounded-full transition-colors ${
                  isListening ? 'text-red-500 animate-pulse' : 'text-warm-400 hover:text-warm-600'
                }`}
                title={isListening ? '停止录音' : '语音输入'}
              >
                🎤
              </button>
            )}
          </div>
          <button
            onClick={sendMessage}
            disabled={!input.trim() || isLoading}
            className="btn-primary px-4 py-2.5 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            发送
          </button>
        </div>
      </div>
    </div>
  )
}

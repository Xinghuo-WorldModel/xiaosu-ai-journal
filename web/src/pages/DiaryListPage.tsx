import { useState, useEffect, useCallback } from 'react'
import { useNavigate } from 'react-router-dom'
import { DiaryEntry, MOOD_EMOJIS } from '../utils/types'
import { getAllDiaries, deleteDiary } from '../services/storage'
import { onDiaryUpdate, onSavingChange } from '../services/diaryEvents'

export default function DiaryListPage() {
  const [diaries, setDiaries] = useState<DiaryEntry[]>([])
  const [isSyncing, setIsSyncing] = useState(false)
  const navigate = useNavigate()

  const loadDiaries = useCallback(async () => {
    const entries = await getAllDiaries()
    setDiaries(entries)
  }, [])

  useEffect(() => {
    loadDiaries()
    const unsubUpdate = onDiaryUpdate(() => loadDiaries())
    const unsubSaving = onSavingChange((saving) => setIsSyncing(saving))

    const handleVisibility = () => {
      if (!document.hidden) loadDiaries()
    }
    document.addEventListener('visibilitychange', handleVisibility)

    const interval = setInterval(loadDiaries, 3000)

    return () => {
      unsubUpdate()
      unsubSaving()
      document.removeEventListener('visibilitychange', handleVisibility)
      clearInterval(interval)
    }
  }, [loadDiaries])

  const handleDelete = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation()
    if (confirm('确定删除这篇日记吗？')) {
      await deleteDiary(id)
      await loadDiaries()
    }
  }

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr)
    const weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return {
      month: `${date.getMonth() + 1}月`,
      day: date.getDate(),
      weekday: weekdays[date.getDay()],
    }
  }

  return (
    <div className="px-4 py-4">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-lg font-semibold text-warm-800">我的日记</h2>
        <button
          onClick={() => navigate('/diary/edit')}
          className="btn-primary text-sm px-3 py-1.5"
        >
          + 写日记
        </button>
      </div>

      {isSyncing && (
        <div className="mb-3 px-3 py-2 bg-warm-100 rounded-xl flex items-center gap-2 text-xs text-warm-600 animate-pulse">
          <span>📝</span>
          <span>小酥正在整理日记，稍等一下...</span>
        </div>
      )}

      {diaries.length === 0 && !isSyncing ? (
        <div className="text-center py-16">
          <p className="text-4xl mb-3">📖</p>
          <p className="text-warm-700/60 text-sm">还没有日记呢</p>
          <p className="text-warm-700/40 text-xs mt-1">和小酥聊聊天，或者直接写一篇吧</p>
        </div>
      ) : (
        <div className="space-y-3">
          {diaries.map(diary => {
            const { month, day, weekday } = formatDate(diary.date)
            return (
              <div
                key={diary.id}
                onClick={() => navigate(`/diary/edit/${diary.id}`)}
                className="card cursor-pointer hover:shadow-md transition-shadow flex gap-3"
              >
                <div className="flex-shrink-0 w-12 text-center">
                  <div className="text-xs text-warm-500">{month}</div>
                  <div className="text-xl font-bold text-warm-800">{day}</div>
                  <div className="text-xs text-warm-500">{weekday}</div>
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm">{MOOD_EMOJIS[diary.mood] || '😌'}</span>
                    <span className="text-xs text-warm-500">{diary.mood}</span>
                    {diary.source === 'chat' && (
                      <span className="text-xs bg-warm-100 text-warm-500 px-1.5 py-0.5 rounded">AI</span>
                    )}
                  </div>
                  <p className="text-sm text-warm-800 line-clamp-2 leading-relaxed">
                    {diary.content}
                  </p>
                  {diary.keywords.length > 0 && (
                    <div className="flex flex-wrap gap-1 mt-2">
                      {diary.keywords.slice(0, 3).map((kw, i) => (
                        <span key={i} className="text-xs bg-warm-50 text-warm-500 px-1.5 py-0.5 rounded">
                          #{kw}
                        </span>
                      ))}
                    </div>
                  )}
                </div>
                <button
                  onClick={(e) => handleDelete(diary.id, e)}
                  className="flex-shrink-0 text-warm-300 hover:text-red-400 transition-colors self-start"
                  title="删除"
                >
                  ✕
                </button>
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

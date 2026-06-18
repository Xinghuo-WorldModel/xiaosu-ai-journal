import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { DiaryEntry, MOOD_EMOJIS } from '../utils/types'
import { searchDiaries } from '../services/storage'

export default function SearchPage() {
  const [query, setQuery] = useState('')
  const [results, setResults] = useState<DiaryEntry[]>([])
  const [hasSearched, setHasSearched] = useState(false)
  const navigate = useNavigate()

  const handleSearch = async () => {
    if (!query.trim()) return
    const entries = await searchDiaries(query.trim())
    setResults(entries)
    setHasSearched(true)
  }

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      handleSearch()
    }
  }

  const highlightText = (text: string, keyword: string) => {
    if (!keyword) return text
    const regex = new RegExp(`(${keyword})`, 'gi')
    const parts = text.split(regex)
    return parts.map((part, i) =>
      regex.test(part) ? (
        <mark key={i} className="bg-warm-200 text-warm-800 rounded px-0.5">
          {part}
        </mark>
      ) : (
        part
      )
    )
  }

  return (
    <div className="px-4 py-4">
      <div className="flex gap-2 mb-4">
        <input
          type="text"
          value={query}
          onChange={e => setQuery(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder="搜索日记内容、关键词..."
          className="input-field flex-1"
        />
        <button onClick={handleSearch} className="btn-primary px-4">
          搜索
        </button>
      </div>

      {!hasSearched ? (
        <div className="text-center py-16">
          <p className="text-4xl mb-3">🔍</p>
          <p className="text-warm-700/60 text-sm">输入关键词搜索你的日记</p>
        </div>
      ) : results.length === 0 ? (
        <div className="text-center py-16">
          <p className="text-4xl mb-3">😯</p>
          <p className="text-warm-700/60 text-sm">没有找到相关日记</p>
        </div>
      ) : (
        <div className="space-y-3">
          <p className="text-xs text-warm-500">找到 {results.length} 篇相关日记</p>
          {results.map(diary => (
            <div
              key={diary.id}
              onClick={() => navigate(`/diary/edit/${diary.id}`)}
              className="card cursor-pointer hover:shadow-md transition-shadow"
            >
              <div className="flex items-center gap-2 mb-2">
                <span className="text-sm">{MOOD_EMOJIS[diary.mood] || '😌'}</span>
                <span className="text-xs text-warm-500">{diary.date}</span>
                <span className="text-xs text-warm-400">{diary.mood}</span>
              </div>
              <p className="text-sm text-warm-800 leading-relaxed line-clamp-3">
                {highlightText(diary.content, query)}
              </p>
              {diary.keywords.length > 0 && (
                <div className="flex flex-wrap gap-1 mt-2">
                  {diary.keywords.map((kw, i) => (
                    <span key={i} className="text-xs bg-warm-50 text-warm-500 px-1.5 py-0.5 rounded">
                      #{kw}
                    </span>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

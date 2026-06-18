import { useState, useEffect } from 'react'

const KEYS = {
  personality: 'xiaosu_personality',
  diaryStyle: 'xiaosu_diary_style',
}

export default function SettingsPage() {
  const [personality, setPersonality] = useState('')
  const [diaryStyle, setDiaryStyle] = useState('')
  const [saved, setSaved] = useState(false)

  useEffect(() => {
    setPersonality(localStorage.getItem(KEYS.personality) || '')
    setDiaryStyle(localStorage.getItem(KEYS.diaryStyle) || '')
  }, [])

  const handleSave = () => {
    localStorage.setItem(KEYS.personality, personality)
    localStorage.setItem(KEYS.diaryStyle, diaryStyle)
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="max-w-lg mx-auto p-4 space-y-6">
      <div className="bg-[#FFF8F0] rounded-xl p-4">
        <h3 className="text-sm font-medium text-[#8B6F5C]">🎨 个性化设置</h3>
        <p className="text-xs text-[#8B6F5C]/60 mt-1">
          自定义小酥的聊天性格和日记整理风格，不填则使用默认设定
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-[#8B6F5C] mb-2">
          小酥性格
        </label>
        <textarea
          className="w-full rounded-xl border border-[#FFDDB3] bg-white px-4 py-3 text-sm text-[#4A3728] placeholder:text-[#8B6F5C]/40 focus:outline-none focus:border-[#FF9B6A] resize-none"
          rows={3}
          placeholder="例如：简洁回应，少说安慰的话，像个理性的朋友"
          value={personality}
          onChange={e => setPersonality(e.target.value)}
        />
        <p className="text-xs text-[#8B6F5C]/50 mt-1">
          影响小酥和你聊天时的说话方式和风格
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-[#8B6F5C] mb-2">
          日记风格
        </label>
        <textarea
          className="w-full rounded-xl border border-[#FFDDB3] bg-white px-4 py-3 text-sm text-[#4A3728] placeholder:text-[#8B6F5C]/40 focus:outline-none focus:border-[#FF9B6A] resize-none"
          rows={3}
          placeholder="例如：尽量多保留我的原话，少添加修饰，朴实记录就好"
          value={diaryStyle}
          onChange={e => setDiaryStyle(e.target.value)}
        />
        <p className="text-xs text-[#8B6F5C]/50 mt-1">
          影响 AI 整理日记时的内容风格和详略偏好
        </p>
      </div>

      <button
        onClick={handleSave}
        className="w-full py-3 rounded-xl bg-[#FF9B6A] text-white font-medium hover:bg-[#FF8A55] transition-colors"
      >
        {saved ? '已保存 ✓' : '保存设置'}
      </button>
    </div>
  )
}

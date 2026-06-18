import { Routes, Route, Navigate } from 'react-router-dom'
import Layout from './components/Layout'
import ChatPage from './pages/ChatPage'
import DiaryListPage from './pages/DiaryListPage'
import DiaryEditPage from './pages/DiaryEditPage'
import SearchPage from './pages/SearchPage'

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Layout />}>
        <Route index element={<Navigate to="/chat" replace />} />
        <Route path="chat" element={<ChatPage />} />
        <Route path="diary" element={<DiaryListPage />} />
        <Route path="diary/edit/:id?" element={<DiaryEditPage />} />
        <Route path="search" element={<SearchPage />} />
      </Route>
    </Routes>
  )
}

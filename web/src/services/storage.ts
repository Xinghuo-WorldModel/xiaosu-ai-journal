import { openDB, DBSchema, IDBPDatabase } from 'idb'
import { DiaryEntry } from '../utils/types'

interface XiaosuDB extends DBSchema {
  diaries: {
    key: string
    value: DiaryEntry
    indexes: {
      'by-date': string
    }
  }
}

let dbInstance: IDBPDatabase<XiaosuDB> | null = null

async function getDB() {
  if (dbInstance) return dbInstance
  dbInstance = await openDB<XiaosuDB>('xiaosu-diary', 1, {
    upgrade(db) {
      const store = db.createObjectStore('diaries', { keyPath: 'id' })
      store.createIndex('by-date', 'date')
    },
  })
  return dbInstance
}

export async function saveDiary(entry: DiaryEntry): Promise<void> {
  const db = await getDB()
  await db.put('diaries', entry)
}

export async function getDiary(id: string): Promise<DiaryEntry | undefined> {
  const db = await getDB()
  return db.get('diaries', id)
}

export async function getDiaryByDate(date: string): Promise<DiaryEntry | undefined> {
  const db = await getDB()
  const entries = await db.getAllFromIndex('diaries', 'by-date', date)
  return entries[0]
}

export async function getAllDiaries(): Promise<DiaryEntry[]> {
  const db = await getDB()
  const entries = await db.getAll('diaries')
  return entries.sort((a, b) => b.createdAt - a.createdAt)
}

export async function deleteDiary(id: string): Promise<void> {
  const db = await getDB()
  await db.delete('diaries', id)
}

export async function searchDiaries(keyword: string): Promise<DiaryEntry[]> {
  const db = await getDB()
  const all = await db.getAll('diaries')
  const lower = keyword.toLowerCase()
  return all.filter(entry =>
    entry.content.toLowerCase().includes(lower) ||
    entry.keywords.some(k => k.toLowerCase().includes(lower)) ||
    entry.mood.includes(lower)
  ).sort((a, b) => b.createdAt - a.createdAt)
}

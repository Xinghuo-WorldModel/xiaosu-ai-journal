type Listener = () => void

const listeners = new Set<Listener>()

export function onDiaryUpdate(fn: Listener) {
  listeners.add(fn)
  return () => listeners.delete(fn)
}

export function notifyDiaryUpdate() {
  listeners.forEach(fn => fn())
}

let _saving = false
const savingListeners = new Set<(saving: boolean) => void>()

export function onSavingChange(fn: (saving: boolean) => void) {
  savingListeners.add(fn)
  fn(_saving)
  return () => savingListeners.delete(fn)
}

export function setSavingStatus(saving: boolean) {
  _saving = saving
  savingListeners.forEach(fn => fn(saving))
}

export function isSaving() {
  return _saving
}

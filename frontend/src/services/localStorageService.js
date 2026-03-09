const STORAGE_KEY = 'checkout_progress'

/**
 * Saves checkout progress to localStorage.
 * NEVER saves cardToken for security reasons.
 */
export function saveCheckoutProgress(state) {
  const { cardToken: _omit, ...safeState } = state
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(safeState))
  } catch {
    // Silently ignore storage errors (private mode, quota exceeded)
  }
}

/**
 * Loads previously saved checkout progress.
 * @returns {object|null}
 */
export function loadCheckoutProgress() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

/**
 * Clears all saved checkout progress.
 */
export function clearCheckoutProgress() {
  localStorage.removeItem(STORAGE_KEY)
}

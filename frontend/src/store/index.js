import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from './checkoutSlice'
import { loadCheckoutProgress } from '../services/localStorageService'

const preloadedState = (() => {
  const saved = loadCheckoutProgress()
  return saved ? { checkout: { ...saved, cardToken: null } } : {}
})()

const store = configureStore({
  reducer: {
    checkout: checkoutReducer
  },
  preloadedState
})

// Persist checkout progress to localStorage on every state change
store.subscribe(() => {
  const { checkout } = store.getState()
  import('../services/localStorageService').then(({ saveCheckoutProgress }) => {
    saveCheckoutProgress(checkout)
  })
})

export default store

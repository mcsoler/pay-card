import { describe, it, expect, beforeEach } from 'vitest'
import {
  saveCheckoutProgress,
  loadCheckoutProgress,
  clearCheckoutProgress
} from '../../services/localStorageService'

describe('localStorageService', () => {
  const mockState = {
    product:       { id: 1, name: 'MacBook' },
    customer:      { id: 1, name: 'Juan', token: 'jwt.tok' },
    cardToken:     'tok_test',
    delivery:      { address: 'Calle 123' },
    transaction:   { id: 1, status: 'PENDING' },
    paymentStatus: null
  }

  describe('saveCheckoutProgress', () => {
    it('saves state to localStorage', () => {
      saveCheckoutProgress(mockState)
      const raw = localStorage.getItem('checkout_progress')
      expect(raw).not.toBeNull()
      const parsed = JSON.parse(raw)
      expect(parsed.product.id).toBe(1)
    })

    it('never saves cardToken (security)', () => {
      saveCheckoutProgress(mockState)
      const raw = localStorage.getItem('checkout_progress')
      const parsed = JSON.parse(raw)
      expect(parsed.cardToken).toBeUndefined()
    })
  })

  describe('loadCheckoutProgress', () => {
    it('returns null when nothing saved', () => {
      expect(loadCheckoutProgress()).toBeNull()
    })

    it('returns saved state', () => {
      saveCheckoutProgress(mockState)
      const loaded = loadCheckoutProgress()
      expect(loaded.product.name).toBe('MacBook')
      expect(loaded.customer.token).toBe('jwt.tok')
    })
  })

  describe('clearCheckoutProgress', () => {
    it('removes data from localStorage', () => {
      saveCheckoutProgress(mockState)
      clearCheckoutProgress()
      expect(localStorage.getItem('checkout_progress')).toBeNull()
    })
  })
})

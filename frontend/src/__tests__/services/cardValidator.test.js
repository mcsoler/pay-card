import { describe, it, expect } from 'vitest'
import {
  detectCardBrand,
  validateLuhn,
  formatCardNumber,
  maskCardNumber
} from '../../services/cardValidator'

describe('cardValidator', () => {
  describe('detectCardBrand', () => {
    it('detects VISA (starts with 4)', () => {
      expect(detectCardBrand('4111111111111111')).toBe('VISA')
      expect(detectCardBrand('4532015112830366')).toBe('VISA')
    })

    it('detects MasterCard (starts with 51-55)', () => {
      expect(detectCardBrand('5500005555555559')).toBe('MASTERCARD')
      expect(detectCardBrand('5105105105105100')).toBe('MASTERCARD')
    })

    it('detects MasterCard (starts with 2221-2720)', () => {
      expect(detectCardBrand('2221000000000009')).toBe('MASTERCARD')
    })

    it('returns UNKNOWN for unrecognized cards', () => {
      expect(detectCardBrand('3714496353984731')).toBe('UNKNOWN')
      expect(detectCardBrand('')).toBe('UNKNOWN')
    })
  })

  describe('validateLuhn', () => {
    it('validates correct Luhn numbers', () => {
      expect(validateLuhn('4111111111111111')).toBe(true)
      expect(validateLuhn('5500005555555559')).toBe(true)
      expect(validateLuhn('4532015112830366')).toBe(true)
    })

    it('rejects invalid Luhn numbers', () => {
      expect(validateLuhn('1234567890123456')).toBe(false)
      expect(validateLuhn('0000000000000000')).toBe(false)
    })

    it('handles numbers with spaces', () => {
      expect(validateLuhn('4111 1111 1111 1111')).toBe(true)
    })
  })

  describe('formatCardNumber', () => {
    it('formats a 16-digit number into groups of 4', () => {
      expect(formatCardNumber('4111111111111111')).toBe('4111 1111 1111 1111')
    })

    it('handles partial input', () => {
      expect(formatCardNumber('411111')).toBe('4111 11')
    })

    it('strips non-numeric characters before formatting', () => {
      expect(formatCardNumber('4111-1111-1111-1111')).toBe('4111 1111 1111 1111')
    })
  })

  describe('maskCardNumber', () => {
    it('shows only last 4 digits', () => {
      expect(maskCardNumber('4111111111111111')).toBe('**** **** **** 1111')
    })
  })
})

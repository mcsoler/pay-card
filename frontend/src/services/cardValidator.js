/**
 * Detects card brand from card number prefix.
 * @param {string} number - raw card number
 * @returns {'VISA'|'MASTERCARD'|'UNKNOWN'}
 */
export function detectCardBrand(number) {
  const cleaned = number.replace(/\D/g, '')
  if (/^4/.test(cleaned)) return 'VISA'
  if (/^5[1-5]/.test(cleaned)) return 'MASTERCARD'
  if (/^2(2[2-9][1-9]|[3-6]\d{2}|7[01]\d|720)/.test(cleaned)) return 'MASTERCARD'
  return 'UNKNOWN'
}

/**
 * Validates card number using Luhn algorithm.
 * @param {string} number
 * @returns {boolean}
 */
export function validateLuhn(number) {
  const digits = number.replace(/\D/g, '').split('').reverse().map(Number)
  const sum = digits.reduce((acc, digit, index) => {
    if (index % 2 === 1) {
      const doubled = digit * 2
      return acc + (doubled > 9 ? doubled - 9 : doubled)
    }
    return acc + digit
  }, 0)
  return sum % 10 === 0
}

/**
 * Formats a card number string into groups of 4.
 * @param {string} value
 * @returns {string}
 */
export function formatCardNumber(value) {
  const cleaned = value.replace(/\D/g, '').slice(0, 16)
  return cleaned.replace(/(.{4})/g, '$1 ').trim()
}

/**
 * Returns a masked card number showing only last 4 digits.
 * @param {string} number
 * @returns {string}
 */
export function maskCardNumber(number) {
  const cleaned = number.replace(/\D/g, '')
  const last4   = cleaned.slice(-4)
  return `**** **** **** ${last4}`
}

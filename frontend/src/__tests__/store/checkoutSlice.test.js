import { describe, it, expect } from 'vitest'
import checkoutReducer, {
  setProduct,
  setCustomer,
  setCardToken,
  setDelivery,
  setTransaction,
  setPaymentStatus,
  resetCheckout,
  selectProduct,
  selectCustomer,
  selectCardToken,
  selectDelivery,
  selectTransaction,
  selectPaymentStatus
} from '../../store/checkoutSlice'

const initialState = {
  product:       null,
  customer:      null,
  cardToken:     null,
  delivery:      null,
  transaction:   null,
  paymentStatus: null // 'APPROVED' | 'DECLINED' | 'PENDING' | null
}

describe('checkoutSlice', () => {
  describe('initial state', () => {
    it('returns the correct initial state', () => {
      const state = checkoutReducer(undefined, { type: '@@INIT' })
      expect(state).toEqual(initialState)
    })
  })

  describe('setProduct', () => {
    it('sets the selected product', () => {
      const product = { id: 1, name: 'MacBook', price: 8_999_000, stock: 5 }
      const state = checkoutReducer(initialState, setProduct(product))
      expect(state.product).toEqual(product)
    })
  })

  describe('setCustomer', () => {
    it('sets customer data', () => {
      const customer = { id: 1, name: 'Juan', email: 'juan@x.com', token: 'jwt.tok' }
      const state = checkoutReducer(initialState, setCustomer(customer))
      expect(state.customer).toEqual(customer)
    })
  })

  describe('setCardToken', () => {
    it('sets card token (never raw card data)', () => {
      const state = checkoutReducer(initialState, setCardToken('tok_stagtest_xxxx'))
      expect(state.cardToken).toBe('tok_stagtest_xxxx')
    })
  })

  describe('setDelivery', () => {
    it('sets delivery information', () => {
      const delivery = { address: 'Calle 123', estimated_date: '2026-03-15' }
      const state = checkoutReducer(initialState, setDelivery(delivery))
      expect(state.delivery).toEqual(delivery)
    })
  })

  describe('setTransaction', () => {
    it('sets transaction data', () => {
      const tx = { id: 1, status: 'PENDING', amount: 9_318_970 }
      const state = checkoutReducer(initialState, setTransaction(tx))
      expect(state.transaction).toEqual(tx)
    })
  })

  describe('setPaymentStatus', () => {
    it('sets payment status to APPROVED', () => {
      const state = checkoutReducer(initialState, setPaymentStatus('APPROVED'))
      expect(state.paymentStatus).toBe('APPROVED')
    })

    it('sets payment status to DECLINED', () => {
      const state = checkoutReducer(initialState, setPaymentStatus('DECLINED'))
      expect(state.paymentStatus).toBe('DECLINED')
    })
  })

  describe('resetCheckout', () => {
    it('resets all checkout state to initial', () => {
      const filledState = {
        product:       { id: 1 },
        customer:      { id: 1 },
        cardToken:     'tok',
        delivery:      { address: 'Addr' },
        transaction:   { id: 1 },
        paymentStatus: 'APPROVED'
      }
      const state = checkoutReducer(filledState, resetCheckout())
      expect(state).toEqual(initialState)
    })
  })

  describe('selectors', () => {
    const rootState = {
      checkout: {
        product:       { id: 1, name: 'MacBook' },
        customer:      { id: 1, name: 'Juan' },
        cardToken:     'tok',
        delivery:      { address: 'Calle 1' },
        transaction:   { id: 1, status: 'APPROVED' },
        paymentStatus: 'APPROVED'
      }
    }

    it('selectProduct returns the product', () => {
      expect(selectProduct(rootState)).toEqual({ id: 1, name: 'MacBook' })
    })

    it('selectCustomer returns the customer', () => {
      expect(selectCustomer(rootState)).toEqual({ id: 1, name: 'Juan' })
    })

    it('selectCardToken returns the card token', () => {
      expect(selectCardToken(rootState)).toBe('tok')
    })

    it('selectDelivery returns delivery info', () => {
      expect(selectDelivery(rootState)).toEqual({ address: 'Calle 1' })
    })

    it('selectTransaction returns transaction', () => {
      expect(selectTransaction(rootState)).toEqual({ id: 1, status: 'APPROVED' })
    })

    it('selectPaymentStatus returns payment status', () => {
      expect(selectPaymentStatus(rootState)).toBe('APPROVED')
    })
  })
})

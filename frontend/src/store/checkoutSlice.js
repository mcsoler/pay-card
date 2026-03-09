import { createSlice } from '@reduxjs/toolkit'

const initialState = {
  product:       null,
  customer:      null,
  cardToken:     null,
  delivery:      null,
  transaction:   null,
  paymentStatus: null
}

const checkoutSlice = createSlice({
  name: 'checkout',
  initialState,
  reducers: {
    setProduct:       (state, action) => { state.product       = action.payload },
    setCustomer:      (state, action) => { state.customer      = action.payload },
    setCardToken:     (state, action) => { state.cardToken     = action.payload },
    setDelivery:      (state, action) => { state.delivery      = action.payload },
    setTransaction:   (state, action) => { state.transaction   = action.payload },
    setPaymentStatus: (state, action) => { state.paymentStatus = action.payload },
    resetCheckout:    ()              => initialState
  }
})

export const {
  setProduct,
  setCustomer,
  setCardToken,
  setDelivery,
  setTransaction,
  setPaymentStatus,
  resetCheckout
} = checkoutSlice.actions

// Selectors
export const selectProduct       = state => state.checkout.product
export const selectCustomer      = state => state.checkout.customer
export const selectCardToken     = state => state.checkout.cardToken
export const selectDelivery      = state => state.checkout.delivery
export const selectTransaction   = state => state.checkout.transaction
export const selectPaymentStatus = state => state.checkout.paymentStatus

export default checkoutSlice.reducer

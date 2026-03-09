import { describe, it, expect, vi } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import PaymentResult from '../../../features/payment/PaymentResult'

const makeStore = (paymentStatus = 'APPROVED', product = { id: 1, name: 'MacBook', stock: 9 }) =>
  configureStore({
    reducer: { checkout: checkoutReducer },
    preloadedState: {
      checkout: {
        product,
        customer:    { id: 1, name: 'Juan' },
        cardToken:   null,
        delivery:    { address: 'Calle 1' },
        transaction: { id: 1, status: paymentStatus, amount: 9_318_970 },
        paymentStatus
      }
    }
  })

const renderResult = (store) =>
  render(
    <Provider store={store}>
      <MemoryRouter initialEntries={['/result']}>
        <Routes>
          <Route path="/result" element={<PaymentResult />} />
          <Route path="/"       element={<div>Product page</div>} />
        </Routes>
      </MemoryRouter>
    </Provider>
  )

describe('PaymentResult', () => {
  describe('when payment is APPROVED', () => {
    it('shows success message', () => {
      renderResult(makeStore('APPROVED'))
      expect(screen.getByText(/aprobado|exitoso|gracias/i)).toBeInTheDocument()
    })

    it('shows transaction ID or confirmation', () => {
      renderResult(makeStore('APPROVED'))
      expect(screen.getByText(/transacción|confirmación/i)).toBeInTheDocument()
    })

    it('shows a green success indicator', () => {
      renderResult(makeStore('APPROVED'))
      const indicator = screen.getByTestId('payment-status-icon')
      expect(indicator).toHaveClass('text-success-500', 'text-success-600')
    })
  })

  describe('when payment is DECLINED', () => {
    it('shows failure message', () => {
      renderResult(makeStore('DECLINED'))
      expect(screen.getByText(/rechazado|fallido|error/i)).toBeInTheDocument()
    })

    it('shows a red failure indicator', () => {
      renderResult(makeStore('DECLINED'))
      const indicator = screen.getByTestId('payment-status-icon')
      expect(indicator).toHaveClass('text-danger-500', 'text-danger-600')
    })
  })

  describe('navigation', () => {
    it('navigates back to product page on "Volver" click', () => {
      renderResult(makeStore('APPROVED'))
      fireEvent.click(screen.getByRole('button', { name: /volver|inicio/i }))
      expect(screen.getByText('Product page')).toBeInTheDocument()
    })

    it('clears checkout state when going back to product', () => {
      const store = makeStore('APPROVED')
      renderResult(store)
      fireEvent.click(screen.getByRole('button', { name: /volver|inicio/i }))
      const state = store.getState().checkout
      expect(state.transaction).toBeNull()
      expect(state.cardToken).toBeNull()
    })
  })
})

import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import PaymentResult from '../../../features/payment/PaymentResult'

const makeStore = (paymentStatus, wompi_id = null) =>
  configureStore({
    reducer: { checkout: checkoutReducer },
    preloadedState: {
      checkout: {
        product:       { id: 1, name: 'MacBook Pro M3', price: 8_999_000, total_amount: 9_318_970 },
        customer:      null,
        cardToken:     null,
        delivery:      null,
        transaction:   { id: 1, status: paymentStatus, amount: 9_318_970, wompi_transaction_id: wompi_id },
        paymentStatus
      }
    }
  })

const renderResult = (paymentStatus, wompi_id = null) =>
  render(
    <Provider store={makeStore(paymentStatus, wompi_id)}>
      <MemoryRouter>
        <PaymentResult />
      </MemoryRouter>
    </Provider>
  )

describe('PaymentResult — status handling', () => {
  it('shows approved screen for APPROVED status', () => {
    renderResult('APPROVED', 'w-abc')
    expect(screen.getByText(/pago aprobado/i)).toBeInTheDocument()
    expect(screen.queryByText(/rechazado/i)).not.toBeInTheDocument()
  })

  it('shows rejected screen for DECLINED status', () => {
    renderResult('DECLINED')
    expect(screen.getByRole('heading', { name: /rechazado/i })).toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: /aprobado/i })).not.toBeInTheDocument()
  })

  it('shows processing screen for PENDING status (not "Pago rechazado")', () => {
    renderResult('PENDING')
    expect(screen.queryByRole('heading', { name: /pago rechazado/i })).not.toBeInTheDocument()
    expect(screen.getByRole('heading', { name: /pendiente|procesando|verificando/i })).toBeInTheDocument()
  })

  it('shows wompi transaction id when available', () => {
    renderResult('APPROVED', '15113-123-456')
    expect(screen.getByText(/15113-123-456/)).toBeInTheDocument()
  })
})

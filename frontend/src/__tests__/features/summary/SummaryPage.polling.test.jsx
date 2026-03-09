import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import SummaryPage from '../../../features/summary/SummaryPage'
import * as apiService from '../../../services/apiService'

vi.mock('../../../services/apiService')

// VITE_POLL_INTERVAL=0 is set in vitest env config (vite.config.js),
// so polling delays are 0ms during tests

const checkoutState = {
  product:     { id: 1, name: 'MacBook Pro M3', price: 8_999_000, base_fee: 269_970, delivery_fee: 50_000, total_amount: 9_318_970 },
  customer:    { id: 1, name: 'Juan Pérez', email: 'juan@x.com', token: 'jwt.tok' },
  cardToken:   'tok_stagtest_xxxx',
  delivery:    { address: 'Calle 123, Bogotá' },
  transaction: { id: 1, status: 'PENDING', amount: 9_318_970 },
  paymentStatus: null
}

const makeStore = (checkout = checkoutState) =>
  configureStore({ reducer: { checkout: checkoutReducer }, preloadedState: { checkout } })

const renderSummary = (store = makeStore()) =>
  render(
    <Provider store={store}>
      <MemoryRouter initialEntries={['/summary']}>
        <Routes>
          <Route path="/summary" element={<SummaryPage />} />
          <Route path="/result"  element={<div data-testid="result-page">Result page</div>} />
        </Routes>
      </MemoryRouter>
    </Provider>
  )

describe('SummaryPage — polling behavior', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('polls status endpoint when Wompi returns PENDING and resolves to APPROVED', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'PENDING', wompi_id: 'w-123', transaction_id: 1 })
    apiService.getTransactionStatus.mockResolvedValue({ status: 'APPROVED', id: 'w-123' })

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    await waitFor(() => {
      expect(screen.getByTestId('result-page')).toBeInTheDocument()
    })

    expect(apiService.getTransactionStatus).toHaveBeenCalledWith('w-123')
  })

  it('polls multiple times until final status is received', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'PENDING', wompi_id: 'w-456', transaction_id: 2 })
    apiService.getTransactionStatus
      .mockResolvedValueOnce({ status: 'PENDING', id: 'w-456' })
      .mockResolvedValueOnce({ status: 'PENDING', id: 'w-456' })
      .mockResolvedValueOnce({ status: 'APPROVED', id: 'w-456' })

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    await waitFor(() => {
      expect(screen.getByTestId('result-page')).toBeInTheDocument()
    })

    expect(apiService.getTransactionStatus).toHaveBeenCalledTimes(3)
  })

  it('navigates to result when Wompi returns DECLINED immediately (no polling needed)', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'DECLINED', wompi_id: 'w-dec', transaction_id: 5 })

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    await waitFor(() => {
      expect(screen.getByTestId('result-page')).toBeInTheDocument()
    })

    expect(apiService.getTransactionStatus).not.toHaveBeenCalled()
  })

  it('calls updateTransaction with the final status after polling resolves', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'PENDING', wompi_id: 'w-123', transaction_id: 1 })
    apiService.getTransactionStatus.mockResolvedValue({ status: 'APPROVED', id: 'w-123' })
    apiService.updateTransaction.mockResolvedValue({ id: 1, status: 'APPROVED' })

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    await waitFor(() => {
      expect(screen.getByTestId('result-page')).toBeInTheDocument()
    })

    expect(apiService.updateTransaction).toHaveBeenCalledWith(1, { status: 'APPROVED' })
  })

  it('calls updateTransaction with ERROR status when Wompi returns ERROR', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'PENDING', wompi_id: 'w-err', transaction_id: 7 })
    apiService.getTransactionStatus.mockResolvedValue({ status: 'ERROR', id: 'w-err' })
    apiService.updateTransaction.mockResolvedValue({ id: 7, status: 'ERROR' })

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    await waitFor(() => {
      expect(screen.getByTestId('result-page')).toBeInTheDocument()
    })

    expect(apiService.updateTransaction).toHaveBeenCalledWith(7, { status: 'ERROR' })
  })

  it('disables pay button while processing', async () => {
    let resolveCreate
    apiService.createTransaction.mockImplementation(
      () => new Promise(resolve => { resolveCreate = resolve })
    )

    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))

    expect(screen.getByRole('button', { name: /procesando/i })).toBeDisabled()

    resolveCreate({ status: 'APPROVED', wompi_id: null })
    await waitFor(() => screen.getByTestId('result-page'))
  })
})

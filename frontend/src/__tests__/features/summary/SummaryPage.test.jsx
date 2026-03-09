import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import SummaryPage from '../../../features/summary/SummaryPage'
import * as apiService from '../../../services/apiService'

vi.mock('../../../services/apiService')

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
          <Route path="/result"  element={<div>Result page</div>} />
        </Routes>
      </MemoryRouter>
    </Provider>
  )

describe('SummaryPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('shows the product name', () => {
    renderSummary()
    expect(screen.getByText('MacBook Pro M3')).toBeInTheDocument()
  })

  it('shows product price', () => {
    renderSummary()
    expect(screen.getByText(/8\.999\.000|8,999,000/)).toBeInTheDocument()
  })

  it('shows base fee', () => {
    renderSummary()
    expect(screen.getByText(/269\.970|269,970/)).toBeInTheDocument()
  })

  it('shows delivery fee', () => {
    renderSummary()
    expect(screen.getByText(/50\.000|50,000/)).toBeInTheDocument()
  })

  it('shows total amount', () => {
    renderSummary()
    expect(screen.getByText(/9\.318\.970|9,318,970/)).toBeInTheDocument()
  })

  it('shows customer delivery address', () => {
    renderSummary()
    expect(screen.getByText(/Calle 123/)).toBeInTheDocument()
  })

  it('shows masked card number', () => {
    renderSummary()
    expect(screen.getByText(/\*{4}|\*\*\*\*/)).toBeInTheDocument()
  })

  it('renders "Pagar" button', () => {
    renderSummary()
    expect(screen.getByRole('button', { name: /pagar/i })).toBeInTheDocument()
  })

  it('navigates to result page on successful payment', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'APPROVED', wompi_id: 'w-abc' })
    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))
    await waitFor(() => {
      expect(screen.getByText('Result page')).toBeInTheDocument()
    })
  })

  it('navigates to result page even on DECLINED (shows result with failure)', async () => {
    apiService.createTransaction.mockResolvedValue({ status: 'DECLINED', wompi_id: 'w-def' })
    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))
    await waitFor(() => {
      expect(screen.getByText('Result page')).toBeInTheDocument()
    })
  })

  it('shows loading state while processing payment', async () => {
    apiService.createTransaction.mockImplementation(() => new Promise(() => {}))
    renderSummary()
    fireEvent.click(screen.getByRole('button', { name: /pagar/i }))
    expect(screen.getByText(/procesando|cargando/i)).toBeInTheDocument()
  })
})

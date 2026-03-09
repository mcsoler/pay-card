import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Provider } from 'react-redux'
import { MemoryRouter } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import CheckoutModal from '../../../features/checkout/CheckoutModal'
import * as apiService from '../../../services/apiService'

vi.mock('../../../services/apiService')

// Mock Wompi tokenization service
vi.mock('../../../services/wompiService', () => ({
  tokenizeCard: vi.fn().mockResolvedValue('tok_stagtest_mock_token')
}))

const product = {
  id: 1, name: 'MacBook Pro M3', price: 8_999_000,
  base_fee: 269_970, delivery_fee: 50_000, total_amount: 9_318_970, stock: 5
}

const makeStore = (preloaded = {}) =>
  configureStore({
    reducer: { checkout: checkoutReducer },
    preloadedState: { checkout: { product, customer: null, cardToken: null, delivery: null, transaction: null, paymentStatus: null, ...preloaded.checkout } }
  })

const renderModal = (onClose = vi.fn(), store = makeStore()) =>
  render(
    <Provider store={store}>
      <MemoryRouter>
        <CheckoutModal product={product} onClose={onClose} />
      </MemoryRouter>
    </Provider>
  )

describe('CheckoutModal', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    apiService.createCustomer.mockResolvedValue({ customer: { id: 1, name: 'Juan' }, token: 'jwt.tok' })
  })

  it('renders as a dialog with accessible role', () => {
    renderModal()
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })

  it('renders card number input', () => {
    renderModal()
    expect(screen.getByLabelText(/número de tarjeta/i)).toBeInTheDocument()
  })

  it('renders delivery address field', () => {
    renderModal()
    expect(screen.getByLabelText(/dirección de entrega/i)).toBeInTheDocument()
  })

  it('detects VISA card brand on input', async () => {
    const user = userEvent.setup()
    renderModal()
    const input = screen.getByLabelText(/número de tarjeta/i)
    await user.type(input, '4111111111111111')
    expect(screen.getByText(/visa/i)).toBeInTheDocument()
  })

  it('detects MasterCard brand on input', async () => {
    const user = userEvent.setup()
    renderModal()
    const input = screen.getByLabelText(/número de tarjeta/i)
    await user.type(input, '5500005555555559')
    expect(screen.getByText(/mastercard/i)).toBeInTheDocument()
  })

  it('shows validation error for invalid card number', async () => {
    const user = userEvent.setup()
    renderModal()
    const input = screen.getByLabelText(/número de tarjeta/i)
    await user.type(input, '1234567890123456')
    fireEvent.blur(input)
    expect(screen.getByText(/número de tarjeta inválido/i)).toBeInTheDocument()
  })

  it('shows required error for empty name', async () => {
    renderModal()
    fireEvent.click(screen.getByRole('button', { name: /continuar|siguiente/i }))
    await waitFor(() => {
      expect(screen.getByText(/nombre.*requerido|requerido.*nombre/i)).toBeInTheDocument()
    })
  })

  it('calls onClose when cancel button is clicked', () => {
    const onClose = vi.fn()
    renderModal(onClose)
    fireEvent.click(screen.getByRole('button', { name: /cancelar|cerrar/i }))
    expect(onClose).toHaveBeenCalled()
  })

  it('formats card number with spaces on input', async () => {
    const user = userEvent.setup()
    renderModal()
    const input = screen.getByLabelText(/número de tarjeta/i)
    await user.type(input, '4111111111111111')
    expect(input.value).toMatch(/4111 1111 1111 1111/)
  })
})

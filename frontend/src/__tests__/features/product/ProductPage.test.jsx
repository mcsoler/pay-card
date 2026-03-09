import { describe, it, expect, vi, beforeEach } from 'vitest'
import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { Provider } from 'react-redux'
import { MemoryRouter } from 'react-router-dom'
import { configureStore } from '@reduxjs/toolkit'
import checkoutReducer from '../../../store/checkoutSlice'
import ProductPage from '../../../features/product/ProductPage'
import * as apiService from '../../../services/apiService'

vi.mock('../../../services/apiService')

const makeStore = (preloaded = {}) =>
  configureStore({ reducer: { checkout: checkoutReducer }, preloadedState: preloaded })

const renderWithProviders = (ui, store = makeStore()) =>
  render(<Provider store={store}><MemoryRouter>{ui}</MemoryRouter></Provider>)

const mockProduct = {
  id:           1,
  name:         'MacBook Pro M3',
  description:  'Laptop Apple con chip M3',
  price:        8_999_000,
  stock:        10,
  base_fee:     269_970,
  delivery_fee: 50_000,
  total_amount: 9_318_970,
  available:    true
}

describe('ProductPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    apiService.getProducts.mockResolvedValue([mockProduct])
  })

  it('shows loading state initially', () => {
    renderWithProviders(<ProductPage />)
    expect(screen.getByText(/cargando/i)).toBeInTheDocument()
  })

  it('renders product name after loading', async () => {
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByText('MacBook Pro M3')).toBeInTheDocument()
    })
  })

  it('shows product price formatted in COP', async () => {
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByText(/8\.999\.000|8,999,000|\$ ?8/i)).toBeInTheDocument()
    })
  })

  it('shows stock availability', async () => {
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByText(/10|disponible/i)).toBeInTheDocument()
    })
  })

  it('renders "Pagar con tarjeta" button', async () => {
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByRole('button', { name: /pagar con tarjeta/i })).toBeInTheDocument()
    })
  })

  it('opens checkout modal when button is clicked', async () => {
    renderWithProviders(<ProductPage />)
    await waitFor(() => screen.getByRole('button', { name: /pagar con tarjeta/i }))
    fireEvent.click(screen.getByRole('button', { name: /pagar con tarjeta/i }))
    await waitFor(() => {
      expect(screen.getByRole('dialog')).toBeInTheDocument()
    })
  })

  it('shows out of stock message when stock is 0', async () => {
    apiService.getProducts.mockResolvedValue([{ ...mockProduct, stock: 0, available: false }])
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByText(/agotado|sin stock/i)).toBeInTheDocument()
    })
  })

  it('shows error state when API fails', async () => {
    apiService.getProducts.mockRejectedValue(new Error('Network error'))
    renderWithProviders(<ProductPage />)
    await waitFor(() => {
      expect(screen.getByText(/error|intenta/i)).toBeInTheDocument()
    })
  })
})

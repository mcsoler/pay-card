import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_URL || '/api'

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' }
})

// Attach JWT token from Redux store on every request
api.interceptors.request.use((config) => {
  const customer = JSON.parse(localStorage.getItem('checkout_progress') || '{}')?.customer
  if (customer?.token) {
    config.headers.Authorization = `Bearer ${customer.token}`
  }
  return config
})

// ── Products ──────────────────────────────────────────────────────────────
export const getProducts = () =>
  api.get('/products').then(r => r.data.data)

export const getProduct = (id) =>
  api.get(`/products/${id}`).then(r => r.data.data)

// ── Customers ─────────────────────────────────────────────────────────────
export const createCustomer = (data) =>
  api.post('/customers', data).then(r => r.data.data)

// ── Transactions ──────────────────────────────────────────────────────────
export const createTransaction = (data) =>
  api.post('/transactions', data).then(r => r.data.data)

export const updateTransaction = (id, data) =>
  api.put(`/transactions/${id}`, data).then(r => r.data.data)

// ── Deliveries ────────────────────────────────────────────────────────────
export const createDelivery = (data) =>
  api.post('/deliveries', data).then(r => r.data.data)

export default api

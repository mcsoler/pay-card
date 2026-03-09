import { useState } from 'react'
import { useSelector, useDispatch } from 'react-redux'
import { useNavigate } from 'react-router-dom'
import {
  selectProduct, selectCustomer, selectCardToken,
  selectDelivery, selectTransaction, setPaymentStatus, setTransaction
} from '../../store/checkoutSlice'
import { createTransaction, getTransactionStatus } from '../../services/apiService'
import CurrencyDisplay from '../../components/CurrencyDisplay'
import Spinner from '../../components/Spinner'
import { maskCardNumber } from '../../services/cardValidator'

export default function SummaryPage() {
  const dispatch  = useDispatch()
  const navigate  = useNavigate()
  const product   = useSelector(selectProduct)
  const customer  = useSelector(selectCustomer)
  const cardToken = useSelector(selectCardToken)
  const delivery  = useSelector(selectDelivery)
  const transaction = useSelector(selectTransaction)

  const [loading, setLoading] = useState(false)
  const [error, setError]     = useState(null)

  // Guard: redirect if state is missing
  if (!product || !customer) {
    navigate('/')
    return null
  }

  const FINAL_STATUSES = new Set(['APPROVED', 'DECLINED', 'VOIDED', 'ERROR'])
  const MAX_POLLS      = 10
  const POLL_INTERVAL  = parseInt(import.meta.env.VITE_POLL_INTERVAL ?? '2000', 10)

  const pollStatus = async (wompiId) => {
    for (let attempt = 0; attempt < MAX_POLLS; attempt++) {
      await new Promise(resolve => setTimeout(resolve, POLL_INTERVAL))
      try {
        const statusResult = await getTransactionStatus(wompiId)
        if (FINAL_STATUSES.has(statusResult.status)) return statusResult.status
      } catch {
        // keep polling on transient errors
      }
    }
    return 'DECLINED'
  }

  const handlePay = async () => {
    setLoading(true)
    setError(null)
    try {
      const result = await createTransaction({
        product_id:   product.id,
        card_token:   cardToken,
        installments: 1
      })

      let finalStatus = result.status

      if (finalStatus === 'PENDING' && result.wompi_id) {
        finalStatus = await pollStatus(result.wompi_id)
      }

      dispatch(setTransaction({ ...transaction, ...result, status: finalStatus }))
      dispatch(setPaymentStatus(finalStatus))
      navigate('/result')
    } catch (err) {
      const message = err?.response?.data?.error || err.message || 'Error al procesar el pago'
      setError(message)
      dispatch(setPaymentStatus('DECLINED'))
      dispatch(setTransaction({ id: null, status: 'DECLINED', amount: product.total_amount }))
      navigate('/result')
    } finally {
      setLoading(false)
    }
  }

  return (
    <main className="min-h-dvh bg-surface-50">
      {/* Header */}
      <header className="bg-white border-b border-surface-100">
        <div className="max-w-lg mx-auto px-4 py-4 flex items-center gap-3">
          <button onClick={() => navigate(-1)} className="text-surface-500 hover:text-surface-700 transition-colors">
            ← Atrás
          </button>
          <span className="font-semibold text-surface-800">Resumen de compra</span>
        </div>
      </header>

      <div className="max-w-lg mx-auto px-4 py-6 space-y-4">
        {/* Product */}
        <section className="card">
          <h2 className="font-semibold text-surface-800 mb-3 text-sm uppercase tracking-wide text-surface-400">Producto</h2>
          <div className="flex gap-4">
            <div className="w-16 h-16 bg-primary-50 rounded-xl flex items-center justify-center flex-shrink-0">
              <span className="text-2xl">💻</span>
            </div>
            <div className="flex-1">
              <p className="font-semibold text-surface-900">{product.name}</p>
              <p className="text-surface-500 text-sm mt-0.5">1 unidad</p>
            </div>
          </div>
        </section>

        {/* Price breakdown */}
        <section className="card">
          <h2 className="font-semibold text-surface-800 mb-3 text-sm uppercase tracking-wide text-surface-400">Desglose de pago</h2>
          <div className="space-y-2">
            <div className="flex justify-between text-sm">
              <span className="text-surface-500">Precio del producto</span>
              <CurrencyDisplay amount={product.price} className="text-surface-700" />
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-surface-500">Tarifa base</span>
              <CurrencyDisplay amount={product.base_fee} className="text-surface-700" />
            </div>
            <div className="flex justify-between text-sm">
              <span className="text-surface-500">Costo de envío</span>
              <CurrencyDisplay amount={product.delivery_fee} className="text-surface-700" />
            </div>
            <div className="border-t border-surface-100 pt-2 flex justify-between">
              <span className="font-bold text-surface-900">Total</span>
              <CurrencyDisplay amount={product.total_amount} className="font-bold text-primary-700 text-lg" />
            </div>
          </div>
        </section>

        {/* Delivery info */}
        <section className="card">
          <h2 className="font-semibold text-surface-800 mb-3 text-sm uppercase tracking-wide text-surface-400">Entrega</h2>
          <div className="space-y-2 text-sm">
            <div className="flex justify-between">
              <span className="text-surface-500">Destinatario</span>
              <span className="text-surface-700 font-medium">{customer.name}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-surface-500">Dirección</span>
              <span className="text-surface-700 font-medium text-right max-w-[60%]">{delivery?.address}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-surface-500">Estimado</span>
              <span className="text-surface-700 font-medium">{delivery?.estimated_date}</span>
            </div>
          </div>
        </section>

        {/* Payment method */}
        <section className="card">
          <h2 className="font-semibold text-surface-800 mb-3 text-sm uppercase tracking-wide text-surface-400">Método de pago</h2>
          <div className="flex items-center gap-3">
            <div className="w-10 h-7 bg-surface-100 rounded flex items-center justify-center">
              <span className="text-xs font-bold text-surface-600">💳</span>
            </div>
            <span className="text-surface-700 font-mono text-sm">
              {cardToken ? maskCardNumber('xxxxxxxxxxxx0000') : '**** **** **** ****'}
            </span>
          </div>
        </section>

        {error && (
          <div className="bg-danger-500/10 border border-danger-200 rounded-xl p-3">
            <p className="text-danger-600 text-sm">{error}</p>
          </div>
        )}

        {/* CTA */}
        <div className="pt-2 pb-6">
          <button
            className="btn-primary"
            onClick={handlePay}
            disabled={loading}
          >
            {loading
              ? <span className="flex items-center justify-center gap-2"><Spinner size="sm" /> Procesando pago...</span>
              : <span className="flex items-center justify-center gap-2">🔒 Pagar <CurrencyDisplay amount={product.total_amount} /></span>
            }
          </button>
          <p className="text-center text-surface-400 text-xs mt-3">
            Pago seguro procesado por Wompi
          </p>
        </div>
      </div>
    </main>
  )
}

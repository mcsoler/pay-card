import { useSelector, useDispatch } from 'react-redux'
import { useNavigate } from 'react-router-dom'
import {
  selectPaymentStatus, selectTransaction, selectProduct,
  resetCheckout
} from '../../store/checkoutSlice'
import { clearCheckoutProgress } from '../../services/localStorageService'
import CurrencyDisplay from '../../components/CurrencyDisplay'

export default function PaymentResult() {
  const dispatch       = useDispatch()
  const navigate       = useNavigate()
  const paymentStatus  = useSelector(selectPaymentStatus)
  const transaction    = useSelector(selectTransaction)
  const product        = useSelector(selectProduct)

  const isApproved = paymentStatus === 'APPROVED'
  const isPending  = paymentStatus === 'PENDING'

  const handleGoBack = () => {
    dispatch(resetCheckout())
    clearCheckoutProgress()
    navigate('/')
  }

  return (
    <main className="min-h-dvh bg-surface-50 flex flex-col items-center justify-center px-4 py-10">
      <div className="w-full max-w-sm space-y-6 text-center">

        {/* Status icon */}
        <div className="flex justify-center">
          <div className={`w-24 h-24 rounded-full flex items-center justify-center
            ${isApproved ? 'bg-success-500/10' : isPending ? 'bg-primary-100' : 'bg-danger-500/10'}`}>
            <span
              data-testid="payment-status-icon"
              className={`text-5xl ${isApproved ? 'text-success-500' : isPending ? 'text-primary-500' : 'text-danger-500'}`}
            >
              {isApproved ? '✓' : isPending ? '⏳' : '✕'}
            </span>
          </div>
        </div>

        {/* Title */}
        <div className="space-y-2">
          <h1 className="text-2xl font-bold text-surface-900">
            {isApproved ? '¡Pago aprobado!' : isPending ? 'Pago pendiente' : 'Pago rechazado'}
          </h1>
          <p className="text-surface-500 text-sm">
            {isApproved
              ? '¡Gracias por tu compra! Tu pedido está siendo procesado.'
              : isPending
              ? 'Tu transacción está verificándose. Recibirás confirmación por correo.'
              : 'Tu transacción fue rechazada. Verifica los datos de tu tarjeta e intenta de nuevo.'}
          </p>
        </div>

        {/* Transaction details */}
        {transaction && (
          <div className="card text-left space-y-3">
            <h2 className="font-semibold text-surface-700 text-sm uppercase tracking-wide text-surface-400">
              Detalle de transacción
            </h2>
            {product && (
              <div className="flex justify-between text-sm">
                <span className="text-surface-500">Producto</span>
                <span className="text-surface-700 font-medium text-right max-w-[60%]">{product.name}</span>
              </div>
            )}
            {transaction.amount && (
              <div className="flex justify-between text-sm">
                <span className="text-surface-500">Monto</span>
                <CurrencyDisplay amount={transaction.amount} className="text-surface-700 font-semibold" />
              </div>
            )}
            <div className="flex justify-between text-sm">
              <span className="text-surface-500">Estado</span>
              <span className={`font-semibold ${isApproved ? 'text-success-600' : isPending ? 'text-primary-600' : 'text-danger-600'}`}>
                {isApproved ? 'Aprobado' : isPending ? 'Pendiente' : 'Rechazado'}
              </span>
            </div>
            {transaction.wompi_transaction_id && (
              <div className="flex justify-between text-sm">
                <span className="text-surface-500">ID Wompi</span>
                <span className="text-surface-600 font-mono text-xs">{transaction.wompi_transaction_id}</span>
              </div>
            )}
          </div>
        )}

        {/* CTA */}
        <button className="btn-primary" onClick={handleGoBack}>
          Volver a productos
        </button>

        {!isApproved && (
          <button
            className="btn-secondary"
            onClick={() => {
              dispatch(resetCheckout())
              navigate('/')
            }}
          >
            Intentar de nuevo
          </button>
        )}
      </div>
    </main>
  )
}

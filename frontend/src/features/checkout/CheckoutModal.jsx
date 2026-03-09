import { useState } from 'react'
import { useDispatch } from 'react-redux'
import { useNavigate } from 'react-router-dom'
import {
  setCustomer, setCardToken, setDelivery, setTransaction
} from '../../store/checkoutSlice'
import { createCustomer } from '../../services/apiService'
import { tokenizeCard } from '../../services/wompiService'
import {
  detectCardBrand, validateLuhn, formatCardNumber
} from '../../services/cardValidator'
import Spinner from '../../components/Spinner'
import CurrencyDisplay from '../../components/CurrencyDisplay'

const CARD_BRAND_ICONS = {
  VISA:       '💳 VISA',
  MASTERCARD: '💳 Mastercard',
  UNKNOWN:    ''
}

export default function CheckoutModal({ product, onClose }) {
  const dispatch  = useDispatch()
  const navigate  = useNavigate()
  const [loading, setLoading] = useState(false)
  const [errors, setErrors]   = useState({})

  const [form, setForm] = useState({
    cardNumber:  '',
    cardHolder:  '',
    expMonth:    '',
    expYear:     '',
    cvc:         '',
    name:        '',
    email:       '',
    phone:       '',
    address:     ''
  })

  const cardBrand = detectCardBrand(form.cardNumber.replace(/\s/g, ''))

  const updateField = (field) => (e) => {
    const value = field === 'cardNumber'
      ? formatCardNumber(e.target.value)
      : e.target.value
    setForm(prev => ({ ...prev, [field]: value }))
    if (errors[field]) setErrors(prev => ({ ...prev, [field]: '' }))
  }

  const validate = () => {
    const newErrors = {}
    const rawCard = form.cardNumber.replace(/\s/g, '')

    if (!rawCard) newErrors.cardNumber = 'Número de tarjeta requerido'
    else if (!validateLuhn(rawCard)) newErrors.cardNumber = 'Número de tarjeta inválido'

    if (!form.cardHolder.trim()) newErrors.cardHolder = 'Nombre en tarjeta requerido'
    if (!form.expMonth || !form.expYear) newErrors.expiry = 'Fecha de vencimiento requerida'
    if (!form.cvc || form.cvc.length < 3) newErrors.cvc = 'CVC inválido'

    if (!form.name.trim()) newErrors.name = 'Nombre requerido'
    if (!form.email.match(/\S+@\S+\.\S+/)) newErrors.email = 'Email inválido'
    if (!form.address.trim()) newErrors.address = 'Dirección de entrega requerida'

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!validate()) return

    setLoading(true)
    try {
      // 1. Tokenize card with Wompi (public key, never sends CVV to our backend)
      const token = await tokenizeCard({
        number:     form.cardNumber.replace(/\s/g, ''),
        cvc:        form.cvc,
        expMonth:   form.expMonth.padStart(2, '0'),
        expYear:    form.expYear,
        cardHolder: form.cardHolder
      })

      // 2. Register customer → get JWT
      const { customer, token: jwt } = await createCustomer({
        name:    form.name,
        email:   form.email,
        phone:   form.phone,
        address: form.address
      })

      // 3. Store in Redux (never store CVC)
      dispatch(setCustomer({ ...customer, token: jwt }))
      dispatch(setCardToken(token))
      dispatch(setDelivery({
        address:        form.address,
        estimated_date: new Date(Date.now() + 5 * 86_400_000).toISOString().split('T')[0]
      }))
      dispatch(setTransaction({ id: null, status: 'PENDING', amount: product.total_amount }))

      onClose()
      navigate('/summary')
    } catch (err) {
      setErrors({ submit: err.message || 'Error al procesar. Intenta nuevamente.' })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label="Formulario de pago"
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center"
    >
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />

      {/* Modal */}
      <div className="relative bg-white w-full max-w-lg rounded-t-3xl sm:rounded-2xl max-h-[92dvh] overflow-y-auto shadow-2xl">
        {/* Handle bar */}
        <div className="sm:hidden flex justify-center pt-3 pb-1">
          <div className="w-10 h-1 bg-surface-200 rounded-full" />
        </div>

        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-surface-100">
          <div>
            <h2 className="font-bold text-surface-900 text-lg">Datos de pago</h2>
            <p className="text-surface-500 text-xs">{product.name}</p>
          </div>
          <button
            aria-label="Cerrar modal"
            onClick={onClose}
            className="text-surface-400 hover:text-surface-600 p-1 rounded-lg transition-colors"
          >
            ✕
          </button>
        </div>

        <form onSubmit={handleSubmit} className="px-5 py-5 space-y-5">
          {/* ── Card Section ── */}
          <section>
            <h3 className="text-sm font-semibold text-surface-700 mb-3 flex items-center gap-2">
              <span className="w-5 h-5 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-xs font-bold">1</span>
              Datos de tarjeta
            </h3>

            <div className="space-y-3">
              {/* Card number */}
              <div>
                <div className="flex items-center justify-between mb-1">
                  <label htmlFor="cardNumber" className="text-sm font-medium text-surface-700">
                    Número de tarjeta
                  </label>
                  {cardBrand !== 'UNKNOWN' && (
                    <span className="text-xs font-semibold text-primary-600">{CARD_BRAND_ICONS[cardBrand]}</span>
                  )}
                </div>
                <input
                  id="cardNumber"
                  inputMode="numeric"
                  maxLength={19}
                  placeholder="1234 5678 9012 3456"
                  value={form.cardNumber}
                  onChange={updateField('cardNumber')}
                  className={`input-field ${errors.cardNumber ? 'input-error' : ''}`}
                />
                {errors.cardNumber && <p className="text-danger-500 text-xs mt-1">{errors.cardNumber}</p>}
              </div>

              {/* Card holder */}
              <div>
                <label htmlFor="cardHolder" className="block text-sm font-medium text-surface-700 mb-1">
                  Nombre en la tarjeta
                </label>
                <input
                  id="cardHolder"
                  placeholder="JUAN PÉREZ"
                  value={form.cardHolder}
                  onChange={updateField('cardHolder')}
                  className={`input-field uppercase ${errors.cardHolder ? 'input-error' : ''}`}
                />
                {errors.cardHolder && <p className="text-danger-500 text-xs mt-1">{errors.cardHolder}</p>}
              </div>

              {/* Expiry + CVC */}
              <div className="grid grid-cols-3 gap-3">
                <div>
                  <label htmlFor="expMonth" className="block text-sm font-medium text-surface-700 mb-1">Mes</label>
                  <input
                    id="expMonth"
                    inputMode="numeric"
                    maxLength={2}
                    placeholder="MM"
                    value={form.expMonth}
                    onChange={updateField('expMonth')}
                    className={`input-field text-center ${errors.expiry ? 'input-error' : ''}`}
                  />
                </div>
                <div>
                  <label htmlFor="expYear" className="block text-sm font-medium text-surface-700 mb-1">Año</label>
                  <input
                    id="expYear"
                    inputMode="numeric"
                    maxLength={2}
                    placeholder="AA"
                    value={form.expYear}
                    onChange={updateField('expYear')}
                    className={`input-field text-center ${errors.expiry ? 'input-error' : ''}`}
                  />
                </div>
                <div>
                  <label htmlFor="cvc" className="block text-sm font-medium text-surface-700 mb-1">CVC</label>
                  <input
                    id="cvc"
                    inputMode="numeric"
                    maxLength={4}
                    placeholder="•••"
                    type="password"
                    value={form.cvc}
                    onChange={updateField('cvc')}
                    className={`input-field text-center ${errors.cvc ? 'input-error' : ''}`}
                  />
                </div>
              </div>
              {errors.expiry && <p className="text-danger-500 text-xs">{errors.expiry}</p>}
              {errors.cvc    && <p className="text-danger-500 text-xs">{errors.cvc}</p>}
            </div>
          </section>

          {/* ── Delivery Section ── */}
          <section>
            <h3 className="text-sm font-semibold text-surface-700 mb-3 flex items-center gap-2">
              <span className="w-5 h-5 bg-primary-100 text-primary-700 rounded-full flex items-center justify-center text-xs font-bold">2</span>
              Datos de entrega
            </h3>

            <div className="space-y-3">
              <div>
                <label htmlFor="name" className="block text-sm font-medium text-surface-700 mb-1">Nombre completo</label>
                <input
                  id="name"
                  placeholder="Juan Pérez"
                  value={form.name}
                  onChange={updateField('name')}
                  className={`input-field ${errors.name ? 'input-error' : ''}`}
                />
                {errors.name && <p className="text-danger-500 text-xs mt-1">{errors.name}</p>}
              </div>

              <div>
                <label htmlFor="email" className="block text-sm font-medium text-surface-700 mb-1">Email</label>
                <input
                  id="email"
                  type="email"
                  inputMode="email"
                  placeholder="juan@ejemplo.com"
                  value={form.email}
                  onChange={updateField('email')}
                  className={`input-field ${errors.email ? 'input-error' : ''}`}
                />
                {errors.email && <p className="text-danger-500 text-xs mt-1">{errors.email}</p>}
              </div>

              <div>
                <label htmlFor="phone" className="block text-sm font-medium text-surface-700 mb-1">Teléfono</label>
                <input
                  id="phone"
                  type="tel"
                  inputMode="tel"
                  placeholder="+57 300 123 4567"
                  value={form.phone}
                  onChange={updateField('phone')}
                  className="input-field"
                />
              </div>

              <div>
                <label htmlFor="address" className="block text-sm font-medium text-surface-700 mb-1">
                  Dirección de entrega
                </label>
                <input
                  id="address"
                  placeholder="Calle 123 # 45-67, Bogotá"
                  value={form.address}
                  onChange={updateField('address')}
                  className={`input-field ${errors.address ? 'input-error' : ''}`}
                />
                {errors.address && <p className="text-danger-500 text-xs mt-1">{errors.address}</p>}
              </div>
            </div>
          </section>

          {/* Order summary (mini) */}
          <div className="bg-primary-50 rounded-xl p-4">
            <div className="flex justify-between items-center">
              <span className="text-sm text-primary-700 font-medium">Total a pagar</span>
              <CurrencyDisplay amount={product.total_amount} className="font-bold text-primary-800 text-lg" />
            </div>
          </div>

          {errors.submit && (
            <div className="bg-danger-500/10 border border-danger-200 rounded-xl p-3">
              <p className="text-danger-600 text-sm">{errors.submit}</p>
            </div>
          )}

          {/* Actions */}
          <div className="flex flex-col gap-3 pt-1">
            <button type="submit" className="btn-primary" disabled={loading}>
              {loading
                ? <span className="flex items-center justify-center gap-2"><Spinner size="sm" /> Procesando...</span>
                : 'Continuar al resumen'
              }
            </button>
            <button type="button" aria-label="Cancelar" className="btn-secondary" onClick={onClose} disabled={loading}>
              Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

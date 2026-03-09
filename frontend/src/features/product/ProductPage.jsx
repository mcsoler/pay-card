import { useEffect, useState } from 'react'
import { useDispatch } from 'react-redux'
import { setProduct } from '../../store/checkoutSlice'
import { getProducts } from '../../services/apiService'
import CurrencyDisplay from '../../components/CurrencyDisplay'
import Spinner from '../../components/Spinner'
import CheckoutModal from '../checkout/CheckoutModal'

export default function ProductPage() {
  const dispatch = useDispatch()
  const [products, setProducts]       = useState([])
  const [loading, setLoading]         = useState(true)
  const [error, setError]             = useState(null)
  const [selected, setSelected]       = useState(null)
  const [modalOpen, setModalOpen]     = useState(false)

  useEffect(() => {
    getProducts()
      .then(data => {
        setProducts(data)
        setLoading(false)
      })
      .catch(err => {
        setError(err.message || 'Error al cargar productos. Intenta nuevamente.')
        setLoading(false)
      })
  }, [])

  const handleBuyClick = (product) => {
    setSelected(product)
    dispatch(setProduct(product))
    setModalOpen(true)
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-dvh gap-4">
        <Spinner size="lg" />
        <p className="text-surface-500 text-sm">Cargando productos...</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center min-h-dvh gap-4 px-4 text-center">
        <div className="text-danger-500 text-4xl">⚠️</div>
        <p className="text-surface-700">{error}</p>
        <button className="btn-primary max-w-xs" onClick={() => window.location.reload()}>
          Intentar de nuevo
        </button>
      </div>
    )
  }

  return (
    <main className="min-h-dvh bg-surface-50">
      {/* Header */}
      <header className="bg-white border-b border-surface-100 sticky top-0 z-10">
        <div className="max-w-lg mx-auto px-4 py-4 flex items-center gap-3">
          <div className="w-8 h-8 bg-primary-600 rounded-lg flex items-center justify-center">
            <span className="text-white text-sm font-bold">O</span>
          </div>
          <span className="font-semibold text-surface-800 text-lg">OrionCore Pay</span>
        </div>
      </header>

      {/* Products */}
      <div className="max-w-lg mx-auto px-4 py-6 space-y-4">
        <h1 className="text-xl font-bold text-surface-900">Productos disponibles</h1>

        {products.map(product => (
          <article key={product.id} className="card flex flex-col gap-4">
            {/* Product image placeholder */}
            <div className="w-full h-40 bg-gradient-to-br from-primary-50 to-accent-500/10 rounded-xl flex items-center justify-center">
              <span className="text-5xl">💻</span>
            </div>

            <div className="flex flex-col gap-2">
              <div className="flex items-start justify-between gap-2">
                <h2 className="font-semibold text-surface-900 text-base leading-tight">{product.name}</h2>
                {product.available
                  ? <span className="text-xs font-medium text-success-600 bg-success-500/10 px-2 py-0.5 rounded-full whitespace-nowrap">
                      {product.stock} en stock
                    </span>
                  : <span className="text-xs font-medium text-danger-600 bg-danger-500/10 px-2 py-0.5 rounded-full whitespace-nowrap">
                      Agotado
                    </span>
                }
              </div>

              <p className="text-surface-500 text-sm leading-relaxed">{product.description}</p>

              {/* Price breakdown */}
              <div className="bg-surface-50 rounded-xl p-3 space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="text-surface-500">Precio</span>
                  <CurrencyDisplay amount={product.price} className="font-medium text-surface-700" />
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-surface-500">Tarifa base</span>
                  <CurrencyDisplay amount={product.base_fee} className="font-medium text-surface-700" />
                </div>
                <div className="flex justify-between text-sm">
                  <span className="text-surface-500">Envío</span>
                  <CurrencyDisplay amount={product.delivery_fee} className="font-medium text-surface-700" />
                </div>
                <div className="border-t border-surface-200 pt-1 flex justify-between">
                  <span className="font-semibold text-surface-800">Total</span>
                  <CurrencyDisplay amount={product.total_amount} className="font-bold text-primary-700 text-base" />
                </div>
              </div>
            </div>

            <button
              className="btn-primary"
              onClick={() => handleBuyClick(product)}
              disabled={!product.available}
            >
              {product.available ? 'Pagar con tarjeta de crédito' : 'Sin stock disponible'}
            </button>
          </article>
        ))}
      </div>

      {/* Checkout Modal */}
      {modalOpen && selected && (
        <CheckoutModal
          product={selected}
          onClose={() => setModalOpen(false)}
        />
      )}
    </main>
  )
}

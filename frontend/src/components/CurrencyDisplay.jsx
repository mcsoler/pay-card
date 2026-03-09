/**
 * Formats a number as Colombian Pesos (COP).
 */
export default function CurrencyDisplay({ amount, className = '' }) {
  const formatted = new Intl.NumberFormat('es-CO', {
    style:    'currency',
    currency: 'COP',
    minimumFractionDigits: 0
  }).format(amount)

  return <span className={className}>{formatted}</span>
}

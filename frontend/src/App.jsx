import { Routes, Route, Navigate } from 'react-router-dom'
import ProductPage    from './features/product/ProductPage'
import SummaryPage    from './features/summary/SummaryPage'
import PaymentResult  from './features/payment/PaymentResult'

export default function App() {
  return (
    <div className="min-h-dvh flex flex-col">
      <Routes>
        <Route path="/"          element={<ProductPage />} />
        <Route path="/summary"   element={<SummaryPage />} />
        <Route path="/result"    element={<PaymentResult />} />
        <Route path="*"          element={<Navigate to="/" replace />} />
      </Routes>
    </div>
  )
}

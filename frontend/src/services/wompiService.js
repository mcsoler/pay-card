const WOMPI_PUBLIC_KEY = import.meta.env.VITE_WOMPI_PUBLIC_KEY || 'pub_stagtest_g2u0HQd3ZMh05hsSgTS2lUV8t3s4mOt7'

/**
 * Tokenizes card data using Wompi's REST API (sandbox).
 * This is done client-side with the public key — CVV never leaves the browser.
 */
export async function tokenizeCard({ number, cvc, expMonth, expYear, cardHolder }) {
  const response = await fetch('https://api-sandbox.co.uat.wompi.dev/v1/tokens/cards', {
    method:  'POST',
    headers: {
      'Content-Type':  'application/json',
      'Authorization': `Bearer ${WOMPI_PUBLIC_KEY}`
    },
    body: JSON.stringify({
      number:      number.replace(/\s/g, ''),
      cvc,
      exp_month:   expMonth,
      exp_year:    expYear,
      card_holder: cardHolder
    })
  })

  if (!response.ok) {
    const error = await response.json().catch(() => ({}))
    throw new Error(error?.error?.reason || 'Error al tokenizar la tarjeta')
  }

  const data = await response.json()
  return data.data?.id
}

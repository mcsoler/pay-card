# OrionCore Pay

Plataforma de pagos con tarjeta de crédito integrada con **Wompi (Sandbox)**. Permite a los usuarios explorar productos, completar un flujo de compra de 5 pasos y procesar pagos de forma segura sin que los datos sensibles de la tarjeta pasen por el backend propio.

---

## Tabla de contenidos

1. [Stack tecnológico](#stack-tecnológico)
2. [Arquitectura del sistema](#arquitectura-del-sistema)
3. [Estructura de carpetas](#estructura-de-carpetas)
4. [Flujo de pago](#flujo-de-pago)
5. [Backend — API REST](#backend--api-rest)
6. [Frontend — SPA React](#frontend--spa-react)
7. [Base de datos](#base-de-datos)
8. [Seguridad](#seguridad)
9. [Testing (TDD)](#testing-tdd)
10. [Despliegue con Docker](#despliegue-con-docker)
11. [Desarrollo local](#desarrollo-local)
12. [Variables de entorno](#variables-de-entorno)
13. [Integración Wompi](#integración-wompi)

---

## Stack tecnológico

| Capa | Tecnología | Versión |
|---|---|---|
| Frontend | React + Redux Toolkit | 19 / 2.x |
| Estilos | Tailwind CSS | 3.x |
| Bundler | Vite | 6.x |
| Backend | Ruby + Sinatra | 3.3 / 4.x |
| ORM | Sequel | 5.x |
| Base de datos | PostgreSQL | 16 |
| Servidor web | Puma | 6.x |
| Proxy / Static | Nginx | 1.27 |
| Autenticación | JWT (HS256) | — |
| Tests backend | RSpec + FactoryBot + WebMock | 3.x |
| Tests frontend | Vitest + React Testing Library | 2.x |
| Contenedores | Docker + Docker Compose | — |

---

## Arquitectura del sistema

### Visión general

```
┌─────────────────────────────────────────────────────────────────┐
│                         Docker Compose                          │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐  │
│  │   Frontend   │    │   Backend    │    │   PostgreSQL 16  │  │
│  │  React SPA   │───▶│ Ruby/Sinatra │───▶│                  │  │
│  │  Nginx :8080 │    │  Puma :4567  │    │     :5432        │  │
│  └──────────────┘    └──────────────┘    └──────────────────┘  │
│         │                   │                                   │
│         │                   ▼                                   │
│         │         ┌──────────────────┐                         │
│         └────────▶│  Wompi Sandbox   │                         │
│   (tokenización   │  api-sandbox...  │                         │
│    con public key)│  wompi.dev/v1    │                         │
│                   └──────────────────┘                         │
└─────────────────────────────────────────────────────────────────┘
```

### Backend — Arquitectura Hexagonal

La lógica de negocio está completamente aislada de los frameworks, la base de datos y servicios externos. Cualquier adaptador puede ser reemplazado sin tocar el dominio.

```
┌─────────────────────────────────────────────────────────┐
│                   DOMAIN (núcleo)                        │
│                                                         │
│  Entities          Ports (interfaces)   Use Cases       │
│  ─────────         ────────────────     ─────────────   │
│  Product       ←── ProductRepository   GetProducts      │
│  Customer      ←── CustomerRepository  CreateCustomer   │
│  Transaction   ←── TransactionRepo     CreateTransaction│
│  Delivery      ←── DeliveryRepository  ProcessPayment   │
│                ←── PaymentGateway      UpdateTransaction │
│                                        CreateDelivery   │
└────────────────────────┬────────────────────────────────┘
                         │ implementan
┌────────────────────────▼────────────────────────────────┐
│                  ADAPTERS (infraestructura)              │
│                                                         │
│  Controllers          Repositories        HTTP Client   │
│  ─────────────        ───────────────     ───────────   │
│  ProductsCtrl    ───▶ ProductRepo(Sequel) WompiClient   │
│  CustomersCtrl   ───▶ CustomerRepo        (Faraday)     │
│  TransactionsCtrl───▶ TransactionRepo               │
│  DeliveriesCtrl  ───▶ DeliveryRepo                  │
│  WebhooksCtrl                                       │
└─────────────────────────────────────────────────────────┘
```

### Railway Oriented Programming (ROP)

Todos los casos de uso retornan `Dry::Monads::Result` (`Success` / `Failure`). El encadenamiento con `do notation` hace que el primer fallo cortocircuite el flujo:

```ruby
def call(params:)
  transaction = yield find_transaction(params[:transaction_id])   # Failure → stop
  product     = yield find_product(transaction.product_id)        # Failure → stop
  gateway_res = yield charge_gateway(params, transaction)         # Failure → stop
  yield persist_result(transaction, product, gateway_res)

  Success({ status: gateway_res[:status], ... })
end
```

---

## Estructura de carpetas

```
pay/                          # Monorepo raíz
├── docker-compose.yml
├── .gitignore
│
├── backend/
│   ├── Gemfile
│   ├── Dockerfile
│   ├── config.ru             # Rack entry point + routing
│   ├── .env.example
│   ├── config/
│   │   └── puma.rb
│   ├── app/
│   │   ├── domain/           # ← Núcleo de negocio (sin dependencias externas)
│   │   │   ├── errors.rb
│   │   │   ├── entities/
│   │   │   │   ├── product.rb
│   │   │   │   ├── customer.rb
│   │   │   │   ├── transaction.rb
│   │   │   │   └── delivery.rb
│   │   │   ├── ports/        # ← Interfaces (contratos)
│   │   │   │   ├── product_repository.rb
│   │   │   │   ├── customer_repository.rb
│   │   │   │   ├── transaction_repository.rb
│   │   │   │   ├── delivery_repository.rb
│   │   │   │   └── payment_gateway.rb
│   │   │   └── use_cases/    # ← Casos de uso (ROP con dry-monads)
│   │   │       ├── get_products.rb
│   │   │       ├── get_product.rb
│   │   │       ├── create_customer.rb
│   │   │       ├── create_transaction.rb
│   │   │       ├── process_payment.rb
│   │   │       ├── update_transaction.rb
│   │   │       └── create_delivery.rb
│   │   ├── adapters/         # ← Implementaciones concretas
│   │   │   ├── controllers/  # Sinatra controllers
│   │   │   │   ├── application_controller.rb
│   │   │   │   ├── products_controller.rb
│   │   │   │   ├── customers_controller.rb
│   │   │   │   ├── transactions_controller.rb
│   │   │   │   ├── deliveries_controller.rb
│   │   │   │   └── webhooks_controller.rb
│   │   │   ├── repositories/ # Sequel ORM → domain entities
│   │   │   │   ├── product_repository.rb
│   │   │   │   ├── customer_repository.rb
│   │   │   │   ├── transaction_repository.rb
│   │   │   │   └── delivery_repository.rb
│   │   │   └── http/
│   │   │       └── wompi_client.rb   # Faraday → Wompi API
│   │   └── infrastructure/
│   │       ├── database/
│   │       │   ├── connection.rb
│   │       │   ├── migrate.rb
│   │       │   ├── seeds.rb
│   │       │   └── migrations/
│   │       │       ├── 001_create_products.rb
│   │       │       ├── 002_create_customers.rb
│   │       │       ├── 003_create_transactions.rb
│   │       │       └── 004_create_deliveries.rb
│   │       └── jwt/
│   │           └── jwt_service.rb
│   └── spec/                 # RSpec — TDD
│       ├── spec_helper.rb
│       ├── support/
│       │   ├── database.rb
│       │   └── factories.rb
│       ├── domain/
│       │   ├── entities/     # 25 specs
│       │   └── use_cases/    # 40 specs
│       └── adapters/
│           ├── controllers/  # 8 specs
│           ├── repositories/ # 12 specs
│           └── http/         # 4 specs
│
└── frontend/
    ├── package.json
    ├── vite.config.js
    ├── tailwind.config.js
    ├── Dockerfile
    ├── nginx.conf
    ├── index.html
    └── src/
        ├── main.jsx          # Entry point React + Redux + Router
        ├── App.jsx           # Routes
        ├── index.css         # Tailwind + custom components
        ├── store/
        │   ├── index.js      # configureStore + localStorage rehydration
        │   └── checkoutSlice.js
        ├── features/         # Feature-based structure
        │   ├── product/
        │   │   └── ProductPage.jsx
        │   ├── checkout/
        │   │   └── CheckoutModal.jsx
        │   ├── summary/
        │   │   └── SummaryPage.jsx
        │   └── payment/
        │       └── PaymentResult.jsx
        ├── services/
        │   ├── apiService.js         # Axios → backend API
        │   ├── wompiService.js       # Tokenización cliente (public key)
        │   ├── cardValidator.js      # Luhn, VISA/MC, format, mask
        │   └── localStorageService.js
        ├── components/
        │   ├── CurrencyDisplay.jsx   # Intl.NumberFormat COP
        │   └── Spinner.jsx
        └── __tests__/        # Vitest — TDD
            ├── setup.js
            ├── store/        # 14 tests
            ├── services/     # 15 tests
            └── features/     # 32 tests
```

---

## Flujo de pago

El checkout sigue 5 pasos definidos en el spec:

```
┌──────────────┐    ┌──────────────────────┐    ┌───────────────┐
│  Pantalla 1  │    │     Pantalla 2        │    │  Pantalla 3   │
│              │    │                      │    │               │
│  Producto    │───▶│  Modal: Tarjeta +    │───▶│   Resumen     │
│  descripción │    │  Datos de entrega    │    │   + Pagar     │
│  precio      │    │  → Tokeniza en       │    │               │
│  stock       │    │    Wompi (front)     │    │               │
└──────────────┘    │  → Registra cliente  │    └───────┬───────┘
                    │  → Recibe JWT        │            │
                    └──────────────────────┘            │ POST /transactions
                                                        ▼
                                              ┌───────────────────┐
                                              │  Backend:         │
                                              │  1. Crea PENDING  │
                                              │  2. Llama Wompi   │
                                              │  3. APPROVED /    │
                                              │     DECLINED      │
                                              │  4. Actualiza TX  │
                                              │  5. Reduce stock  │
                                              └────────┬──────────┘
                                                       │
                    ┌──────────────┐    ┌──────────────▼───────────┐
                    │  Pantalla 5  │    │       Pantalla 4          │
                    │              │    │                           │
                    │  Volver al  │◀───│  Estado final:            │
                    │  catálogo   │    │  ✓ Aprobado / ✕ Rechazado│
                    │  (stock     │    │                           │
                    │  actualizado)│    └───────────────────────────┘
                    └──────────────┘
```

### Flujo técnico detallado

```
Frontend                           Backend                        Wompi API
    │                                 │                               │
    │── GET /api/products ───────────▶│                               │
    │◀─ [{ id, name, price, stock }] ─│                               │
    │                                 │                               │
    │   (usuario hace clic en Pagar)  │                               │
    │                                 │                               │
    │── POST tokenize (public_key) ───────────────────────────────────▶│
    │◀─ { token: "tok_stagtest_..." } ───────────────────────────────│
    │                                 │                               │
    │── POST /api/customers ─────────▶│                               │
    │   { name, email, address, phone}│                               │
    │◀─ { customer, token: JWT } ─────│                               │
    │                                 │                               │
    │── POST /api/transactions ──────▶│                               │
    │   Authorization: Bearer JWT     │                               │
    │   { product_id, card_token,     │                               │
    │     installments, email }       │                               │
    │                                 │── POST /transactions ─────────▶│
    │                                 │   { amount, token, email }    │
    │                                 │◀─ { id, status: APPROVED } ──│
    │◀─ { status, wompi_id } ─────────│                               │
    │                                 │                               │
    │   (webhook opcional)            │◀── POST /api/webhooks/wompi ──│
    │                                 │    confirmación asíncrona     │
```

---

## Backend — API REST

### Endpoints

| Método | Ruta | Auth | Descripción |
|---|---|---|---|
| `GET` | `/api/products` | No | Lista todos los productos con stock |
| `GET` | `/api/products/:id` | No | Detalle de un producto |
| `PUT` | `/api/products/:id/stock` | JWT | Actualiza stock (uso interno) |
| `POST` | `/api/customers` | No | Registra cliente → retorna JWT |
| `POST` | `/api/transactions` | JWT | Crea transacción PENDING + procesa con Wompi |
| `PUT` | `/api/transactions/:id` | JWT | Actualiza resultado de transacción (idempotente) |
| `POST` | `/api/deliveries` | JWT | Registra entrega (solo para TX aprobadas) |
| `POST` | `/api/webhooks/wompi` | Firma SHA256 | Confirmación asíncrona de Wompi |

### Formato de respuestas

**Éxito:**
```json
{
  "data": { ... }
}
```

**Error de validación (422):**
```json
{
  "errors": ["Name is required", "Email is invalid"]
}
```

**Error (400/401/404/500):**
```json
{
  "error": "Mensaje descriptivo"
}
```

### Ejemplos de requests

**Registrar cliente:**
```bash
curl -X POST http://localhost:4567/api/customers \
  -H "Content-Type: application/json" \
  -d '{
    "name":    "Juan Pérez",
    "email":   "juan@ejemplo.com",
    "address": "Calle 123 #45-67, Bogotá",
    "phone":   "+573001234567"
  }'
```

**Crear transacción:**
```bash
curl -X POST http://localhost:4567/api/transactions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT>" \
  -d '{
    "product_id":     1,
    "card_token":     "tok_stagtest_xxxx",
    "installments":   1,
    "customer_email": "juan@ejemplo.com"
  }'
```

**Actualizar transacción:**
```bash
curl -X PUT http://localhost:4567/api/transactions/1 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT>" \
  -d '{
    "status":               "APPROVED",
    "wompi_transaction_id": "wompi-abc-123"
  }'
```

---

## Frontend — SPA React

### Estado global (Redux)

El store mantiene el progreso completo del checkout:

```javascript
{
  checkout: {
    product:       Product | null,   // producto seleccionado
    customer:      Customer | null,  // datos + JWT token
    cardToken:     string | null,    // token Wompi (nunca CVV)
    delivery:      Delivery | null,  // dirección + fecha estimada
    transaction:   Transaction | null,
    paymentStatus: 'PENDING' | 'APPROVED' | 'DECLINED' | null
  }
}
```

> **Seguridad:** `cardToken` se guarda en Redux (memoria de sesión) pero **nunca** se persiste en `localStorage`. El CVV nunca sale del navegador.

### Persistencia en localStorage

Al cambiar el estado, se serializa a `localStorage` (sin `cardToken`) para recuperación ante refresh:

```javascript
// localStorageService.js
export function saveCheckoutProgress(state) {
  const { cardToken: _omit, ...safeState } = state
  localStorage.setItem('checkout_progress', JSON.stringify(safeState))
}
```

### Validación de tarjetas

- **Detección de marca**: VISA (prefijo 4), Mastercard (51-55, 2221-2720)
- **Algoritmo de Luhn**: validación del número de tarjeta
- **Formateo**: `4111111111111111` → `4111 1111 1111 1111`
- **Enmascarado**: `**** **** **** 1111`

### Rutas

| Ruta | Componente | Descripción |
|---|---|---|
| `/` | `ProductPage` | Catálogo con stock y precios |
| `/summary` | `SummaryPage` | Resumen de compra + botón Pagar |
| `/result` | `PaymentResult` | Estado final de la transacción |

---

## Base de datos

### Modelo de datos

```sql
products
  id            SERIAL PRIMARY KEY
  name          VARCHAR(255) NOT NULL
  description   TEXT
  price         NUMERIC(12,2) NOT NULL
  stock         INTEGER NOT NULL DEFAULT 0
  base_fee      NUMERIC(12,2) NOT NULL DEFAULT 0
  delivery_fee  NUMERIC(12,2) NOT NULL DEFAULT 0
  created_at    TIMESTAMP NOT NULL
  updated_at    TIMESTAMP NOT NULL

customers
  id            SERIAL PRIMARY KEY
  name          VARCHAR(255) NOT NULL
  email         VARCHAR(255) NOT NULL UNIQUE
  address       VARCHAR(500)
  phone         VARCHAR(50)
  created_at    TIMESTAMP NOT NULL
  updated_at    TIMESTAMP NOT NULL

transactions
  id                    SERIAL PRIMARY KEY
  product_id            INTEGER REFERENCES products(id)
  customer_id           INTEGER REFERENCES customers(id)
  amount                NUMERIC(12,2) NOT NULL
  status                VARCHAR(50) NOT NULL DEFAULT 'PENDING'
  wompi_transaction_id  VARCHAR(255)
  created_at            TIMESTAMP NOT NULL
  updated_at            TIMESTAMP NOT NULL

deliveries
  id              SERIAL PRIMARY KEY
  transaction_id  INTEGER REFERENCES transactions(id)
  status          VARCHAR(50) NOT NULL DEFAULT 'PENDING'
  address         VARCHAR(500) NOT NULL
  estimated_date  DATE
  created_at      TIMESTAMP NOT NULL
  updated_at      TIMESTAMP NOT NULL
```

### Seeds (datos de prueba)

Se incluyen 5 productos de tecnología pre-cargados:

| Producto | Precio | Stock |
|---|---|---|
| MacBook Pro M3 14" | $ 8.999.000 | 10 |
| iPhone 15 Pro 256GB | $ 4.599.000 | 25 |
| Sony WH-1000XM5 | $ 1.199.000 | 50 |
| Samsung Galaxy Tab S9 Ultra | $ 3.499.000 | 15 |
| LG UltraWide 34" QHD | $ 2.299.000 | 8 |

---

## Seguridad

| Aspecto | Implementación |
|---|---|
| Datos de tarjeta | Tokenizados en el **frontend** con la public key de Wompi. El CVV nunca sale del navegador ni llega al backend propio |
| JWT | HS256, emitido al registrar cliente, expira en 24h. Todos los endpoints de escritura requieren `Authorization: Bearer <token>` |
| Webhook Wompi | Validado con `HMAC-SHA256` usando `WOMPI_EVENTS_SECRET`. Comparación segura con `Rack::Utils.secure_compare` para evitar timing attacks |
| localStorage | `cardToken` nunca se persiste. Solo se mantiene en memoria Redux durante la sesión |
| Headers HTTP | Nginx sirve `X-Frame-Options`, `X-Content-Type-Options`, `X-XSS-Protection`, `Referrer-Policy` |
| CORS | Configurado para aceptar solo el origen del frontend (`ALLOWED_ORIGINS`) |

---

## Testing (TDD)

El proyecto fue desarrollado con metodología **Test-Driven Development**: cada spec fue escrito **antes** del código de producción (ciclo RED → GREEN).

### Backend (RSpec)

```
spec/
├── domain/
│   ├── entities/          ← 25 specs
│   │   ├── product_spec.rb
│   │   ├── customer_spec.rb
│   │   ├── transaction_spec.rb
│   │   └── delivery_spec.rb
│   └── use_cases/         ← 40 specs
│       ├── get_products_spec.rb
│       ├── get_product_spec.rb
│       ├── create_customer_spec.rb
│       ├── create_transaction_spec.rb
│       ├── process_payment_spec.rb
│       ├── update_transaction_spec.rb
│       ├── create_delivery_spec.rb
│       └── jwt_service_spec.rb
└── adapters/
    ├── repositories/      ← 12 specs
    ├── http/              ←  4 specs (WebMock)
    └── controllers/       ←  8 specs (Rack::Test)
```

**Ejecutar tests:**
```bash
cd backend
bundle install
bundle exec rspec                          # todos los specs
bundle exec rspec spec/domain/             # solo dominio
bundle exec rspec --format documentation   # salida detallada
bundle exec rspec --format documentation --order random  # orden aleatorio
```

**Cobertura (SimpleCov, mínimo 80%):**
```bash
bundle exec rspec  # genera coverage/index.html
open coverage/index.html
```

### Frontend (Vitest)

```
src/__tests__/
├── store/
│   └── checkoutSlice.test.js     ← 14 tests (reducer + selectors)
├── services/
│   ├── cardValidator.test.js     ← 10 tests (Luhn, VISA/MC, format)
│   └── localStorage.test.js     ←  5 tests (sin cardToken)
└── features/
    ├── product/ProductPage.test.jsx      ←  8 tests
    ├── checkout/CheckoutModal.test.jsx   ←  9 tests
    ├── summary/SummaryPage.test.jsx      ← 10 tests
    └── payment/PaymentResult.test.jsx    ←  5 tests
```

**Ejecutar tests:**
```bash
cd frontend
npm install
npm test                    # ejecución única
npm run test:watch          # modo watch (desarrollo)
npm run test:coverage       # con reporte de cobertura
```

---

## Despliegue con Docker

### Requisitos previos

- Docker Engine 24+
- Docker Compose 2.x

### Inicio rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/mcsoler/pay-card.git
cd pay-card

# 2. Crear archivo de variables de entorno
cp backend/.env.example .env
# Editar .env con tus valores (las claves sandbox ya están incluidas)

# 3. Construir e iniciar todos los servicios
docker-compose up --build

# 4. Verificar servicios
curl http://localhost:4567/api/products   # backend
curl http://localhost:8080                # frontend
```

> Las migraciones y seeds se ejecutan automáticamente al iniciar el backend.

### Servicios

| Servicio | Puerto externo | Descripción |
|---|---|---|
| `frontend` | `8080` | SPA React servida por Nginx |
| `backend` | `4567` | API REST Ruby/Sinatra con Puma |
| `db` | `5432` | PostgreSQL 16 |

### Comandos útiles

```bash
# Levantar en segundo plano
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver logs de un servicio específico
docker-compose logs -f backend
docker-compose logs -f frontend

# Ejecutar migraciones manualmente
docker-compose exec backend bundle exec ruby app/infrastructure/database/migrate.rb

# Ejecutar seeds manualmente
docker-compose exec backend bundle exec ruby app/infrastructure/database/seeds.rb

# Ejecutar tests del backend
docker-compose exec backend bundle exec rspec

# Acceder al intérprete de Ruby con acceso a la DB
docker-compose exec backend bundle exec irb -r ./app/infrastructure/database/connection

# Reiniciar un servicio
docker-compose restart backend

# Detener y eliminar contenedores
docker-compose down

# Detener y eliminar contenedores + volúmenes (borra la DB)
docker-compose down -v

# Reconstruir un servicio específico
docker-compose up --build backend
```

### Health checks

El servicio `db` tiene un healthcheck integrado. El `backend` espera a que PostgreSQL esté disponible antes de arrancar:

```yaml
depends_on:
  db:
    condition: service_healthy
```

---

## Desarrollo local

### Requisitos

- Ruby 3.3.x
- Node.js 22.x
- PostgreSQL 16 corriendo localmente

### Backend

```bash
cd backend

# Instalar dependencias
bundle install

# Configurar variables de entorno
cp .env.example .env
# Editar .env con DB_HOST=localhost y las demás variables

# Crear base de datos de desarrollo
createdb pay_development
createdb pay_test

# Ejecutar migraciones
bundle exec ruby app/infrastructure/database/migrate.rb

# Cargar datos de prueba
bundle exec ruby app/infrastructure/database/seeds.rb

# Iniciar servidor de desarrollo
bundle exec puma -C config/puma.rb

# O directamente con rackup
bundle exec rackup config.ru -p 4567
```

### Frontend

```bash
cd frontend

# Instalar dependencias
npm install

# Iniciar servidor de desarrollo (proxy al backend en :4567)
npm run dev

# El frontend queda disponible en http://localhost:5173
```

> El `vite.config.js` tiene configurado un proxy: todas las peticiones a `/api` se redirigen automáticamente a `http://localhost:4567`.

---

## Variables de entorno

### Backend (`.env`)

| Variable | Descripción | Valor por defecto |
|---|---|---|
| `RACK_ENV` | Entorno de ejecución | `development` |
| `DB_HOST` | Host de PostgreSQL | `localhost` |
| `DB_PORT` | Puerto de PostgreSQL | `5432` |
| `DB_NAME` | Nombre de la base de datos | `pay_development` |
| `DB_USER` | Usuario de PostgreSQL | `postgres` |
| `DB_PASSWORD` | Contraseña de PostgreSQL | `postgres` |
| `JWT_SECRET` | Clave secreta para firmar JWT | ⚠️ Cambiar en producción |
| `JWT_EXPIRATION_HOURS` | Horas de validez del JWT | `24` |
| `WOMPI_PUBLIC_KEY` | Clave pública Wompi (sandbox) | `pub_stagtest_...` |
| `WOMPI_PRIVATE_KEY` | Clave privada Wompi (sandbox) | `prv_stagtest_...` |
| `WOMPI_EVENTS_SECRET` | Secret para validar webhooks | `stagtest_events_...` |
| `WOMPI_INTEGRITY_SECRET` | Secret de integridad | `stagtest_integrity_...` |
| `WOMPI_API_URL` | URL base de la API Wompi | `https://api-sandbox.co.uat.wompi.dev/v1` |
| `ALLOWED_ORIGINS` | CORS — orígenes permitidos | `http://localhost:5173` |
| `PORT` | Puerto del servidor | `4567` |

### Frontend (variables Vite)

| Variable | Descripción |
|---|---|
| `VITE_API_URL` | URL base del backend API |
| `VITE_WOMPI_PUBLIC_KEY` | Clave pública Wompi para tokenización |

---

## Integración Wompi

### Entorno Sandbox

Todas las operaciones se realizan en el entorno **sandbox** (sin dinero real):

- **API URL:** `https://api-sandbox.co.uat.wompi.dev/v1`
- **Tokenización de tarjeta (frontend):** `POST /v1/tokens/cards`
- **Crear transacción (backend):** `POST /v1/transactions`

### Flujo de tokenización

```
Frontend (navegador)
    │
    │── POST https://api-sandbox.co.uat.wompi.dev/v1/tokens/cards
    │   Headers: Authorization: Bearer pub_stagtest_...
    │   Body: { number, cvc, exp_month, exp_year, card_holder }
    │
    │◀─ { data: { id: "tok_stagtest_xxxx", ... } }
    │
    │   El token se envía al backend propio (nunca el número real ni el CVC)
```

### Tarjetas de prueba (Wompi Sandbox)

| Número | Marca | Resultado |
|---|---|---|
| `4111 1111 1111 1111` | VISA | APPROVED |
| `4000 0000 0000 0002` | VISA | DECLINED |
| `5500 0055 5555 5559` | Mastercard | APPROVED |

> CVC: cualquier número de 3 dígitos. Vencimiento: cualquier fecha futura.

### Webhook (opcional)

Wompi puede confirmar el resultado de la transacción vía webhook. El endpoint implementado es:

```
POST /api/webhooks/wompi
```

La firma se valida con `SHA256(timestamp + event + events_secret)` y se compara con el header `checksum` de forma segura para evitar timing attacks.

---

## Estrategia de ramas

El proyecto usa una rama por funcionalidad con Pull Requests:

| Rama | Descripción |
|---|---|
| `main` | Código estable, siempre deployable |
| `feature/project-structure` | Scaffolding, Docker, configuración |
| `feature/backend-domain` | Entidades, puertos, casos de uso, JWT |
| `feature/backend-adapters` | Repositorios, WompiClient, controllers |
| `feature/frontend-setup` | Redux, servicios, infraestructura de tests |
| `feature/frontend-screens` | Las 5 pantallas del flujo de pago |

---

## Licencia

Proyecto de prueba técnica — uso interno OrionCore.

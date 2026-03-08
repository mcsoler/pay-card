Este documento sirve como guía para que el asistente de IA comprenda los requisitos técnicos y genere el código apropiado para la prueba técnica de Wompi.

📱 1. FRONTEND (SPA)
Tecnologías Obligatorias
Framework: ReactJS (NO otros frameworks)

Estado Global: Redux (para React) 

CSS: Flexbox o Grid API (cualquier framework adicional es opcional) y Tailwind CSS

Requisitos de Diseño
Orientación: Mobile-first

Pantalla mínima de referencia: iPhone SE (2020) - 1334 x 750 píxeles

Responsive: Debe adaptarse correctamente a pantallas más grandes (tablet/desktop)

UI/UX: Diseño libre, pero debe respetar los límites de la pantalla sin desbordamientos

Flujo de Pantallas (5 pasos)
Página de Producto → Mostrar producto, descripción, precio y stock disponible

Modal de Tarjeta y Entrega → Formulario de tarjeta de crédito + datos de entrega

Resumen de Pago → Producto + tarifa base + envío. Botón "Pagar"

Estado Final → Resultado de la transacción (éxito/fallo)

Volver a Producto → Redirigir con stock actualizado

Funcionalidades Clave
Botón "Pagar con tarjeta de crédito" que abre un modal

Validación de tarjeta de crédito (detección de VISA/MasterCard es un plus)

Almacenamiento seguro del progreso en localStorage (para recuperación en caso de refresh)

Integración con API backend para:

Crear transacción en estado PENDING

Consultar stock

Actualizar transacción y stock post-pago

Estado Global (Redux/Vuex)
Almacenar:

Producto seleccionado

Datos de tarjeta (nunca CVV completo en texto plano)

Datos de entrega

Token de transacción

Estado del pago

🖥️ 2. BACKEND (API)
Tecnologías Obligatorias
Lenguaje: JavaScript/TypeScript o Ruby

Frameworks permitidos:


Sinatra (Ruby)

Arquitectura Requerida
Hexagonal Architecture + Puertos y Adaptadores

Dominio (Entidades, Use Cases)

Adaptadores (Controladores, Repositorios, Clientes HTTP)

Puertos (Interfaces)

Railway Oriented Programming (ROP) para los casos de uso

Separación de capas: La lógica de negocio NO debe estar en controladores/ruteo

Base de Datos
Opciones recomendadas: PostgreSQL

Modelo de datos mínimo:

products (id, name, description, price, stock, base_fee, delivery_fee)

customers (id, name, email, address, phone)

transactions (id, product_id, customer_id, amount, status, wompi_transaction_id, created_at, updated_at)

deliveries (id, transaction_id, status, address, estimated_date)

Seeders: Debe incluir datos de prueba (productos)

Endpoints Requeridos
Método	Ruta	Descripción
GET	/api/products	Listar productos con stock
GET	/api/products/:id	Detalle de producto
POST	/api/transactions	Crear transacción (estado PENDING)
PUT	/api/transactions/:id	Actualizar transacción (resultado de Wompi)
POST	/api/customers	Registrar cliente
POST	/api/deliveries	Asignar entrega
PUT	/api/products/:id/stock	Actualizar stock (uso interno)
Integración con Wompi (Sandbox)
URL Base: https://api-sandbox.co.uat.wompi.dev/v1

Llamadas:

POST /payment - Crear pago (con token de tarjeta)

Manejo de estados:

PENDING → APROBADO / RECHAZADO

Webhook (opcional): Endpoint para recibir confirmación de Wompi

🐳 3. DOCKER COMPOSE PARA DESPLIEGUE
Estructura de Servicios
Frontend: Servido con Nginx (build de producción)

Backend API: Ruby (Sinatra)

Base de Datos: PostgreSQL o DynamoDB (local con DynamoDB Local)

4. CRITERIOS DE CALIDAD PARA EL ASISTENTE
Validaciones: Todos los endpoints deben validar entrada de datos (ej: email válido, tarjeta Luhn)

Manejo de errores: Respuestas HTTP coherentes (200, 400, 404, 500)

Seguridad: Nunca guardar CVV, usar HTTPS, headers de seguridad, Token JWT regenerativos para comunicacion entre servicios

Testing: El código debe ser testeable (unitario >80% cobertura) se debe programar metodologia TDD


# Construir y levantar todos los servicios
docker-compose up --build

# Levantar en segundo plano
docker-compose up -d

# Ver logs
docker-compose logs -f

# Detener servicios
docker-compose down

# Reiniciar un servicio específico
docker-compose restart backend

# Ejecutar migraciones o seeders
docker-compose exec backend npm run seed


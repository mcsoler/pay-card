### Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

COPY . .

ARG VITE_API_URL=/api
ARG VITE_WOMPI_PUBLIC_KEY=pub_stagtest_g2u0HQd3ZMh05hsSgTS2lUV8t3s4mOt7

ENV VITE_API_URL=$VITE_API_URL
ENV VITE_WOMPI_PUBLIC_KEY=$VITE_WOMPI_PUBLIC_KEY

RUN npm run build

### Stage 2: Serve with Nginx
FROM nginx:1.27-alpine

COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]

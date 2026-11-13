# DriveRent demo image: React build + Express API + MariaDB in one container.
# Built for free hosting (Render). The database is recreated from schema.sql + seed-demo.sql
# on every start, so the demo always resets to clean fictional data.

FROM node:22-alpine AS web
WORKDIR /web
COPY package.json package-lock.json* ./
RUN npm install --no-audit --no-fund
COPY . .
ENV VITE_API_URL=/api
RUN npx vite build

FROM node:22-alpine
RUN apk add --no-cache mariadb mariadb-client
WORKDIR /app
COPY car-rental-backend/package.json car-rental-backend/package-lock.json* ./
RUN npm install --omit=dev --no-audit --no-fund
COPY car-rental-backend/ ./
COPY --from=web /web/dist ./public
COPY docker/start.sh /start.sh
RUN chmod +x /start.sh
ENV NODE_ENV=production STATIC_DIR=/app/public DB_HOST=127.0.0.1 DB_USER=app DB_PASSWORD=app DB_NAME=rcrent
EXPOSE 5000
CMD ["/start.sh"]

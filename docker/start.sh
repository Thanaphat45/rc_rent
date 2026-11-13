#!/bin/sh
set -e

# With DATABASE_URL (Supabase/PostgreSQL) the data is persistent and no local DB is needed.
if [ -n "$DATABASE_URL" ]; then
  export PORT="${PORT:-5000}"
  export FRONTEND_URL="${FRONTEND_URL:-http://localhost:${PORT}}"
  exec node server.js
fi

# --- start a private MariaDB inside the container (demo only, data resets on restart)
mkdir -p /run/mysqld /var/lib/mysql
chown -R mysql:mysql /run/mysqld /var/lib/mysql
if [ ! -d /var/lib/mysql/mysql ]; then
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi
mariadbd --user=mysql --datadir=/var/lib/mysql --bind-address=127.0.0.1 --skip-networking=0 \
  --innodb-buffer-pool-size=32M --performance-schema=OFF \
  --character-set-server=utf8mb4 --collation-server=utf8mb4_general_ci \
  --character-set-collations=utf8mb4=utf8mb4_general_ci &

for i in $(seq 1 60); do mariadb-admin ping --silent 2>/dev/null && break; sleep 1; done

mariadb -uroot <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';
GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

# fresh demo data each boot
if [ "$(mariadb -uroot -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='${DB_NAME}'")" = "0" ]; then
  mariadb -uroot "${DB_NAME}" < /app/database/schema.sql
  mariadb -uroot "${DB_NAME}" < /app/database/seed-demo.sql
fi

# --- API + built front end on $PORT (Render injects PORT)
export PORT="${PORT:-5000}"
export JWT_SECRET="${JWT_SECRET:-change-me-in-render-env}"
export FRONTEND_URL="${FRONTEND_URL:-http://localhost:${PORT}}"
exec node server.js

-- DriveRent on PostgreSQL (Supabase). Same API surface as the MySQL stored procedures:
-- every sp_* is a function returning rows with the same camelCase column names.
-- Everything lives in its own schema so it can share a database with other apps.

CREATE SCHEMA IF NOT EXISTS driverent;
SET search_path TO driverent;

CREATE TABLE IF NOT EXISTS users (
  id          SERIAL PRIMARY KEY,
  username    VARCHAR(50)  NOT NULL UNIQUE,
  password    VARCHAR(255) NOT NULL,
  role        VARCHAR(10)  NOT NULL DEFAULT 'user' CHECK (role IN ('user','admin')),
  "createdAt" TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS cars (
  id            SERIAL PRIMARY KEY,
  brand         VARCHAR(100)  NOT NULL,
  type          VARCHAR(50)   NOT NULL,
  "pricePerDay" NUMERIC(10,2) NOT NULL,
  available     INT NOT NULL DEFAULT 0 CHECK (available >= 0)
);

CREATE TABLE IF NOT EXISTS rentals (
  id           SERIAL PRIMARY KEY,
  "carId"      INT NOT NULL REFERENCES cars(id)  ON DELETE CASCADE,
  "userId"     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       VARCHAR(10) NOT NULL DEFAULT 'active' CHECK (status IN ('pending','active','completed','cancelled')),
  days         INT NOT NULL DEFAULT 1,
  "totalPrice" NUMERIC(10,2) NOT NULL DEFAULT 0,
  "renterName" VARCHAR(100),
  phone        VARCHAR(20),
  email        VARCHAR(120),
  address      VARCHAR(255),
  "createdAt"  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------- users ----------
CREATE OR REPLACE FUNCTION sp_get_user_by_username(p_username TEXT)
RETURNS TABLE(id INT, username VARCHAR, password VARCHAR, role VARCHAR) LANGUAGE sql STABLE AS $$
  SELECT u.id, u.username, u.password, u.role FROM driverent.users u WHERE u.username = p_username;
$$;

CREATE OR REPLACE FUNCTION sp_register_user(p_username TEXT, p_password TEXT, p_role TEXT)
RETURNS TABLE(id INT, username VARCHAR, role VARCHAR) LANGUAGE sql AS $$
  INSERT INTO driverent.users (username, password, role) VALUES (p_username, p_password, p_role)
  RETURNING users.id, users.username, users.role;
$$;

CREATE OR REPLACE FUNCTION sp_update_user_password(p_id INT, p_password TEXT)
RETURNS TABLE("affectedRows" INT) LANGUAGE plpgsql AS $$
DECLARE n INT;
BEGIN
  UPDATE driverent.users SET password = p_password WHERE users.id = p_id;
  GET DIAGNOSTICS n = ROW_COUNT; RETURN QUERY SELECT n;
END $$;

CREATE OR REPLACE FUNCTION sp_get_all_users()
RETURNS TABLE(id INT, username VARCHAR, role VARCHAR, "createdAt" TIMESTAMPTZ) LANGUAGE sql STABLE AS $$
  SELECT u.id, u.username, u.role, u."createdAt" FROM driverent.users u ORDER BY u.id;
$$;

CREATE OR REPLACE FUNCTION sp_update_user_role(p_id INT, p_role TEXT)
RETURNS TABLE(id INT, username VARCHAR, role VARCHAR) LANGUAGE sql AS $$
  UPDATE driverent.users SET role = p_role WHERE users.id = p_id RETURNING users.id, users.username, users.role;
$$;

CREATE OR REPLACE FUNCTION sp_delete_user(p_id INT)
RETURNS TABLE("affectedRows" INT) LANGUAGE plpgsql AS $$
DECLARE n INT;
BEGIN
  DELETE FROM driverent.users WHERE users.id = p_id;
  GET DIAGNOSTICS n = ROW_COUNT; RETURN QUERY SELECT n;
END $$;

-- ---------- cars ----------
CREATE OR REPLACE FUNCTION sp_get_all_cars()
RETURNS TABLE(id INT, brand VARCHAR, type VARCHAR, "pricePerDay" DOUBLE PRECISION, available INT) LANGUAGE sql STABLE AS $$
  SELECT c.id, c.brand, c.type, c."pricePerDay"::float8, c.available FROM driverent.cars c ORDER BY c.id;
$$;

CREATE OR REPLACE FUNCTION sp_get_car_by_id(p_id INT)
RETURNS TABLE(id INT, brand VARCHAR, type VARCHAR, "pricePerDay" DOUBLE PRECISION, available INT) LANGUAGE sql STABLE AS $$
  SELECT c.id, c.brand, c.type, c."pricePerDay"::float8, c.available FROM driverent.cars c WHERE c.id = p_id;
$$;

CREATE OR REPLACE FUNCTION sp_add_car(p_brand TEXT, p_type TEXT, p_price NUMERIC, p_available INT)
RETURNS TABLE(id INT, brand VARCHAR, type VARCHAR, "pricePerDay" DOUBLE PRECISION, available INT) LANGUAGE sql AS $$
  INSERT INTO driverent.cars (brand, type, "pricePerDay", available) VALUES (p_brand, p_type, p_price, p_available)
  RETURNING cars.id, cars.brand, cars.type, cars."pricePerDay"::float8, cars.available;
$$;

CREATE OR REPLACE FUNCTION sp_update_car(p_id INT, p_brand TEXT, p_type TEXT, p_price NUMERIC, p_available INT)
RETURNS TABLE(id INT, brand VARCHAR, type VARCHAR, "pricePerDay" DOUBLE PRECISION, available INT) LANGUAGE sql AS $$
  UPDATE driverent.cars SET brand = p_brand, type = p_type, "pricePerDay" = p_price, available = p_available
  WHERE cars.id = p_id
  RETURNING cars.id, cars.brand, cars.type, cars."pricePerDay"::float8, cars.available;
$$;

CREATE OR REPLACE FUNCTION sp_delete_car(p_id INT)
RETURNS TABLE("affectedRows" INT) LANGUAGE plpgsql AS $$
DECLARE n INT;
BEGIN
  DELETE FROM driverent.cars WHERE cars.id = p_id;
  GET DIAGNOSTICS n = ROW_COUNT; RETURN QUERY SELECT n;
END $$;

-- ---------- rentals ----------
CREATE OR REPLACE FUNCTION sp_create_rental(p_car INT, p_user INT, p_days INT, p_name TEXT, p_phone TEXT, p_email TEXT, p_address TEXT)
RETURNS TABLE(id INT, "carId" INT, "userId" INT, status VARCHAR, days INT, "totalPrice" DOUBLE PRECISION, "renterName" VARCHAR, "createdAt" TIMESTAMPTZ)
LANGUAGE plpgsql AS $$
DECLARE v_available INT; v_price NUMERIC; v_id INT;
BEGIN
  -- row lock so two renters can't both take the last car
  SELECT c.available, c."pricePerDay" INTO v_available, v_price FROM driverent.cars c WHERE c.id = p_car FOR UPDATE;
  IF v_available IS NULL THEN RAISE EXCEPTION 'Car not found'; END IF;
  IF v_available <= 0 THEN RAISE EXCEPTION 'Car not available'; END IF;
  UPDATE driverent.cars SET available = cars.available - 1 WHERE cars.id = p_car;
  -- total is computed from the stored price, never trusted from the client
  INSERT INTO driverent.rentals ("carId", "userId", status, days, "totalPrice", "renterName", phone, email, address)
  VALUES (p_car, p_user, 'active', p_days, v_price * p_days, p_name, p_phone, p_email, p_address)
  RETURNING rentals.id INTO v_id;
  RETURN QUERY SELECT r.id, r."carId", r."userId", r.status, r.days, r."totalPrice"::float8, r."renterName", r."createdAt"
               FROM driverent.rentals r WHERE r.id = v_id;
END $$;

CREATE OR REPLACE FUNCTION sp_get_my_rentals(p_user INT)
RETURNS TABLE(id INT, "carId" INT, "userId" INT, status VARCHAR, days INT, "totalPrice" DOUBLE PRECISION, "renterName" VARCHAR, "createdAt" TIMESTAMPTZ)
LANGUAGE sql STABLE AS $$
  SELECT r.id, r."carId", r."userId", r.status, r.days, r."totalPrice"::float8, r."renterName", r."createdAt"
  FROM driverent.rentals r WHERE r."userId" = p_user ORDER BY r.id DESC;
$$;

CREATE OR REPLACE FUNCTION sp_cancel_rental(p_id INT, p_user INT)
RETURNS TABLE("affectedRows" INT) LANGUAGE plpgsql AS $$
DECLARE v_car INT;
BEGIN
  SELECT r."carId" INTO v_car FROM driverent.rentals r
  WHERE r.id = p_id AND r."userId" = p_user AND r.status = 'active' FOR UPDATE;
  IF v_car IS NULL THEN RETURN QUERY SELECT 0; RETURN; END IF;
  UPDATE driverent.rentals SET status = 'cancelled' WHERE rentals.id = p_id;
  UPDATE driverent.cars SET available = cars.available + 1 WHERE cars.id = v_car;
  RETURN QUERY SELECT 1;
END $$;

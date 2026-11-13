-- Rc Rent: schema + stored procedures used by car-rental-backend (MySQL 8)
-- Creates a fresh database for local Docker runs and demo deploys.
-- It does NOT touch an existing database unless you point it at one.

SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS users (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  username   VARCHAR(50)  NOT NULL UNIQUE,
  password   VARCHAR(255) NOT NULL,
  role       ENUM('user','admin') NOT NULL DEFAULT 'user',
  createdAt  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS cars (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  brand       VARCHAR(100)  NOT NULL,
  type        VARCHAR(50)   NOT NULL,
  pricePerDay DECIMAL(10,2) NOT NULL,
  available   INT NOT NULL DEFAULT 0,
  CHECK (available >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS rentals (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  carId      INT NOT NULL,
  userId     INT NOT NULL,
  status     ENUM('pending','active','completed','cancelled') NOT NULL DEFAULT 'active',
  createdAt  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_rentals_car  FOREIGN KEY (carId)  REFERENCES cars(id)  ON DELETE CASCADE,
  CONSTRAINT fk_rentals_user FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

DELIMITER //

-- ---------- users ----------
DROP PROCEDURE IF EXISTS sp_get_user_by_username //
CREATE PROCEDURE sp_get_user_by_username(IN p_username VARCHAR(50))
BEGIN
  SELECT id, username, password, role FROM users WHERE username = p_username;
END //

DROP PROCEDURE IF EXISTS sp_register_user //
CREATE PROCEDURE sp_register_user(IN p_username VARCHAR(50), IN p_password VARCHAR(255), IN p_role VARCHAR(10))
BEGIN
  INSERT INTO users (username, password, role) VALUES (p_username, p_password, p_role);
  SELECT id, username, role FROM users WHERE id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS sp_update_user_password //
CREATE PROCEDURE sp_update_user_password(IN p_id INT, IN p_password VARCHAR(255))
BEGIN
  UPDATE users SET password = p_password WHERE id = p_id;
  SELECT ROW_COUNT() AS affectedRows;
END //

DROP PROCEDURE IF EXISTS sp_get_all_users //
CREATE PROCEDURE sp_get_all_users()
BEGIN
  SELECT id, username, role, createdAt FROM users ORDER BY id;
END //

DROP PROCEDURE IF EXISTS sp_update_user_role //
CREATE PROCEDURE sp_update_user_role(IN p_id INT, IN p_role VARCHAR(10))
BEGIN
  UPDATE users SET role = p_role WHERE id = p_id;
  SELECT id, username, role FROM users WHERE id = p_id;
END //

DROP PROCEDURE IF EXISTS sp_delete_user //
CREATE PROCEDURE sp_delete_user(IN p_id INT)
BEGIN
  DELETE FROM users WHERE id = p_id;
  SELECT ROW_COUNT() AS affectedRows;
END //

-- ---------- cars ----------
DROP PROCEDURE IF EXISTS sp_get_all_cars //
CREATE PROCEDURE sp_get_all_cars()
BEGIN
  SELECT id, brand, type, CAST(pricePerDay AS DOUBLE) AS pricePerDay, available FROM cars ORDER BY id;
END //

DROP PROCEDURE IF EXISTS sp_get_car_by_id //
CREATE PROCEDURE sp_get_car_by_id(IN p_id INT)
BEGIN
  SELECT id, brand, type, CAST(pricePerDay AS DOUBLE) AS pricePerDay, available FROM cars WHERE id = p_id;
END //

DROP PROCEDURE IF EXISTS sp_add_car //
CREATE PROCEDURE sp_add_car(IN p_brand VARCHAR(100), IN p_type VARCHAR(50), IN p_price DECIMAL(10,2), IN p_available INT)
BEGIN
  INSERT INTO cars (brand, type, pricePerDay, available) VALUES (p_brand, p_type, p_price, p_available);
  CALL sp_get_car_by_id(LAST_INSERT_ID());
END //

DROP PROCEDURE IF EXISTS sp_update_car //
CREATE PROCEDURE sp_update_car(IN p_id INT, IN p_brand VARCHAR(100), IN p_type VARCHAR(50), IN p_price DECIMAL(10,2), IN p_available INT)
BEGIN
  UPDATE cars SET brand = p_brand, type = p_type, pricePerDay = p_price, available = p_available WHERE id = p_id;
  CALL sp_get_car_by_id(p_id);
END //

DROP PROCEDURE IF EXISTS sp_delete_car //
CREATE PROCEDURE sp_delete_car(IN p_id INT)
BEGIN
  DELETE FROM cars WHERE id = p_id;
  SELECT ROW_COUNT() AS affectedRows;
END //

-- ---------- rentals ----------
DROP PROCEDURE IF EXISTS sp_create_rental //
CREATE PROCEDURE sp_create_rental(IN p_car INT, IN p_user INT)
BEGIN
  DECLARE v_available INT;
  START TRANSACTION;
  SELECT available INTO v_available FROM cars WHERE id = p_car FOR UPDATE;
  IF v_available IS NULL THEN
    ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not found';
  ELSEIF v_available <= 0 THEN
    ROLLBACK; SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Car not available';
  END IF;
  UPDATE cars SET available = available - 1 WHERE id = p_car;
  INSERT INTO rentals (carId, userId, status) VALUES (p_car, p_user, 'active');
  COMMIT;
  SELECT id, carId, userId, status, createdAt FROM rentals WHERE id = LAST_INSERT_ID();
END //

DROP PROCEDURE IF EXISTS sp_get_my_rentals //
CREATE PROCEDURE sp_get_my_rentals(IN p_user INT)
BEGIN
  SELECT id, carId, userId, status, createdAt FROM rentals WHERE userId = p_user ORDER BY id DESC;
END //

DROP PROCEDURE IF EXISTS sp_cancel_rental //
CREATE PROCEDURE sp_cancel_rental(IN p_id INT, IN p_user INT)
BEGIN
  DECLARE v_car INT;
  SELECT carId INTO v_car FROM rentals WHERE id = p_id AND userId = p_user AND status = 'active';
  IF v_car IS NULL THEN
    SELECT 0 AS affectedRows;
  ELSE
    START TRANSACTION;
    UPDATE rentals SET status = 'cancelled' WHERE id = p_id;
    UPDATE cars SET available = available + 1 WHERE id = v_car;
    COMMIT;
    SELECT 1 AS affectedRows;
  END IF;
END //

DELIMITER ;

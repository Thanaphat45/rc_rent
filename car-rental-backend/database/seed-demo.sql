-- Demo data for a fresh database only (fictional). Password for both accounts: Demo@2026
INSERT INTO users (username, password, role) VALUES
  ('demo_admin', '$2b$10$Ds2f1b3xWY04E.UtU9s6be/K59O79GnqUlSV7kt4Zivo7NP7Ccjpi', 'admin'),
  ('demo_user',  '$2b$10$Ds2f1b3xWY04E.UtU9s6be/K59O79GnqUlSV7kt4Zivo7NP7Ccjpi', 'user');

INSERT INTO cars (brand, type, pricePerDay, available) VALUES
  ('Toyota Camry',   'Sedan', 1200, 3),
  ('Honda Civic',    'Sedan', 1000, 2),
  ('Ford Ranger',    'Truck', 1800, 1),
  ('Toyota Fortuner','SUV',   2200, 2),
  ('Honda City',     'Sedan',  900, 4),
  ('Isuzu D-Max',    'Truck', 1500, 2),
  ('Mazda CX-5',     'SUV',   2000, 1),
  ('Nissan Almera',  'Sedan',  850, 0);


CREATE database restaurant_case_study;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales (customer_id, order_date, product_id) VALUES
  ('A', '2025-01-01', 1),
  ('A', '2025-01-01', 2),
  ('A', '2025-01-07', 2),
  ('A', '2025-01-10', 3),
  ('A', '2025-01-11', 3),
  ('A', '2025-01-11', 3),
  ('B', '2025-01-01', 2),
  ('B', '2025-01-02', 2),
  ('B', '2025-01-04', 1),
  ('B', '2025-01-11', 1),
  ('B', '2025-01-16', 3),
  ('B', '2025-02-01', 3),
  ('C', '2025-01-01', 3),
  ('C', '2025-01-01', 3),
  ('C', '2025-01-07', 3);

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(20),
  price INTEGER
);

INSERT INTO menu (product_id, product_name, price) VALUES
  (1, 'biryani', 10),
  (2, 'paneer', 15),
  (3, 'dosai', 12);

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members (customer_id, join_date) VALUES
  ('A', '2025-01-07'),
  ('B', '2025-01-09');


  select * from sales;
  select * from menu;
  select * from members;


CREATE TABLE IF NOT EXISTS hive.lakehouse.orders (
  order_id BIGINT,
  customer_id BIGINT,
  status VARCHAR,
  order_total DOUBLE,
  order_date DATE
)
WITH (
  format = 'PARQUET'
);

INSERT INTO hive.lakehouse.orders
SELECT *
FROM (
  VALUES
    (1, 1001, 'NEW', 125.25, DATE '2026-01-10'),
    (2, 1002, 'SHIPPED', 89.99, DATE '2026-01-11'),
    (3, 1003, 'DELIVERED', 240.00, DATE '2026-01-12')
) AS seed(order_id, customer_id, status, order_total, order_date)
WHERE NOT EXISTS (
  SELECT 1
  FROM hive.lakehouse.orders
  LIMIT 1
);

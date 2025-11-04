WITH orders AS (
    SELECT 
    ID as order_id,
    USER_ID	as customer_id,
    ORDER_DATE AS order_placed_at,
    STATUS AS order_status
    FROM {{ source('jaffle_shop', 'orders') }} 
)

SELECT *
FROM orders
WITH customers as (
    SELECT 
    id as customer_id,
    first_name AS customer_first_name,
    last_name as customer_last_name
    FROM {{ source('jaffle_shop', 'customers') }} 


)

SELECT *
FROM customers
with payments as (
    SELECT 
    ORDERID as order_id,
    PAYMENTMETHOD as payment_method,
    STATUS as payment_status,
    AMOUNT as amount,
    CREATED AS created_date
    FROM {{ source('stripe', 'stripe_payments') }}
)

SELECT *
FROM payments
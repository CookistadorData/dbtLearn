SELECT 
    ORDERID,
    sum(AMOUNT) as total_amount
FROM {{ ref('stg_raw_stripe_payment') }}
GROUP BY ORDERID
HAVING SUM(AMOUNT) < 0
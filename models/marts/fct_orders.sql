with tempo as 
(
    SELECT o.order_id,
	   o.customer_id ,
	   p.AMOUNT as amount
    FROM {{ ref('stg_raw_stripe_payment') }} AS p
    JOIN {{ ref('stg_jaffle_shop__orders') }} AS o
    ON p.ORDERID = o.order_id   
)

SELECT * 
FROM tempo



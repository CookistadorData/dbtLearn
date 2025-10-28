with source as  (
    SELECT *
    FROM {{ source('stripe_data', 'stripe_payments') }}
)
SELECT      [ORDERID],
			[PAYMENTMETHOD],
			[STATUS],
			[AMOUNT]/100 as AMOUNT ,
			[CREATED] as created_at,
			[ID]
FROM source
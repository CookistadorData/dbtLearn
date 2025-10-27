
SELECT      [ORDERID],
			[PAYMENTMETHOD],
			[STATUS],
			[AMOUNT]/100 as AMOUNT ,
			[CREATED] as created_at,
			[ID]
FROM [raw].[stripe_payments]
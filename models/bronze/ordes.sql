WITH Orders as (
SELECT      [id],
			[created_at],
			[user_id],
			[product_id],
			[quantity],
			[unit_price]
FROM [dbt_project_catalog].[landing].[orders]
)

SELECT * FROM Orders
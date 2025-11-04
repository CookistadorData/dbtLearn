WITH orders AS (
    SELECT *
    FROM {{ ref('Jaffle_shop_orders') }}
) ,

customers as (
    SELECT *
    FROM {{ ref('Jaffle_shop_customers') }}

),

payments as (
    SELECT *
    FROM {{ ref('stripe_payments') }}
),

customer_orders 
as (
    select 
    customers.customer_id
    , min(order_placed_at) as first_order_date
    , max(order_placed_at) as most_recent_order_date
    , count(order_id) AS number_of_orders
from customers
left join orders
on orders.customer_id = customers.customer_id 
group by customers.customer_id),

Payment_Date as (
    select 
            order_id, 
            max(created_date) as payment_finalized_date, 
            sum(amount) / 100.0 as total_amount_paid
        from payments
        where payment_status <> 'fail'
        group by order_id
),


paid_orders as (
    select 
    orders.*,
    Payment_Date.total_amount_paid,
    Payment_Date.payment_finalized_date,
    customers.customer_first_name,
    customers.customer_last_name
FROM  orders
left join Payment_Date ON orders.order_id = Payment_Date.order_id
left join customers on orders.customer_id = customers.customer_id )


select
p.*,
ROW_NUMBER() OVER (ORDER BY p.order_id) as transaction_seq,
ROW_NUMBER() OVER (PARTITION BY p.customer_id ORDER BY p.order_id) as customer_sales_seq,
CASE WHEN c.first_order_date = p.order_placed_at
THEN 'new'
ELSE 'return' END as nvsr,
x.clv_bad as customer_lifetime_value,
c.first_order_date as fdos
FROM paid_orders p
left join customer_orders as c ON c.customer_id = p.customer_id
LEFT OUTER JOIN 
(
        select
        p.order_id,
        sum(t2.total_amount_paid) as clv_bad
    from paid_orders p
    left join paid_orders t2 on p.customer_id = t2.customer_id and p.order_id >= t2.order_id
    group by p.order_id
) x on x.order_id = p.order_id
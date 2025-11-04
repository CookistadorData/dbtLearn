---Imports CTEs
with 

base_customers as (
    select * FROM {{ source('jaffle_shop', 'customers') }} 

),

orders as(
    select * FROM  {{ source('jaffle_shop', 'orders') }}

),

payments as(

    select * FROM {{ source('stripe', 'stripe_payments') }}

),

customers as (
      select 
        id as customer_id,
        last_name as surname,
        first_name as givenname,
        first_name + ' ' +  last_name as full_name
      FROM base_customers
),

a as (
      SELECT 
        row_number() over (partition by USER_ID order by ORDER_DATE, ID) as user_order_seq,
        *
      from orders
    ) ,

customer_order_history as (

    select 
        customers.id as customer_id,
        customers.name as full_name,
        customers.last_name as surname,
        customers.first_name as givenname,
        min(ORDER_DATE) as first_order_date,

        min(case 
            when a.STATUS NOT IN ('returned','return_pending') 
            then ORDER_DATE 
        end) as first_non_returned_order_date,
        
        max(case 
            when a.STATUS NOT IN ('returned','return_pending') 
            then ORDER_DATE 
        end) as most_recent_non_returned_order_date,
        COALESCE(max(user_order_seq),0) as order_count,
        COALESCE(count(case 
            when a.STATUS != 'returned' 
            then 1 
        end),0) as non_returned_order_count,
        sum(case when a.STATUS NOT IN ('returned','return_pending') then ROUND(payments.AMOUNT/100.0,2) else 0 end) as total_lifetime_value,
        sum(case 
            when a.STATUS NOT IN ('returned','return_pending') 
            then ROUND(payments.AMOUNT/100.0,2) else 0 
        end)
        /NULLIF(count(case 
            when a.STATUS NOT IN ('returned','return_pending') 
            then 1 
        end),0) as avg_non_returned_order_value

    from  a

    join  customers 
    on a.USER_ID = customers.customer_id

    left outer join payments
    on a.ID = payments.ORDERID

    where a.STATUS NOT IN ('pending') and payments.STATUS != 'fail'

    group by customers.customer_id, customers.full_name, customers.surname, customers.givenname

),
-- Logical CTEs

-- Fianl CTEs
final as (
select 
    orders.ID as order_id,
    orders.USER_ID as customer_id,
    last_name as surname,
    first_name as givenname,
    first_order_date,
    order_count,
    total_lifetime_value,
    round(AMOUNT/100.0,2) as order_value_dollars,
    orders.STATUS as order_status,
    payments.STATUS as payment_status

from  orders

join  customers
on orders.USER_ID = customers.customer_id

join  customer_order_history
on orders.USER_ID = customer_order_history.customer_id

left outer join payments
on orders.ID = payments.ORDERID

where payments.STATUS != 'fail'
)

SELECT *
FROM final
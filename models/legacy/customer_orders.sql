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
from {{ source('jaffle_shop', 'orders') }} as orders

join (
      select 
        first_name + ' ' +  last_name as name, 
        * 
      from {{ source('jaffle_shop', 'customers') }}
) customers
on orders.USER_ID = customers.id

join (

    select 
        b.id as customer_id,
        b.name as full_name,
        b.last_name as surname,
        b.first_name as givenname,
        min(ORDER_DATE) as first_order_date,
        min(case when a.STATUS NOT IN ('returned','return_pending') then ORDER_DATE end) as first_non_returned_order_date,
        max(case when a.STATUS NOT IN ('returned','return_pending') then ORDER_DATE end) as most_recent_non_returned_order_date,
        COALESCE(max(user_order_seq),0) as order_count,
        COALESCE(count(case when a.STATUS != 'returned' then 1 end),0) as non_returned_order_count,
        sum(case when a.STATUS NOT IN ('returned','return_pending') then ROUND(c.AMOUNT/100.0,2) else 0 end) as total_lifetime_value,
        sum(case when a.STATUS NOT IN ('returned','return_pending') then ROUND(c.AMOUNT/100.0,2) else 0 end)/NULLIF(count(case when a.STATUS NOT IN ('returned','return_pending') then 1 end),0) as avg_non_returned_order_value

    from (
      select 
        row_number() over (partition by USER_ID order by ORDER_DATE, ID) as user_order_seq,
        *
      from {{ source('jaffle_shop', 'orders') }}
    ) a

    join ( 
      select 
        first_name + ' '+  last_name as name, 
        * 
      from {{ source('jaffle_shop', 'customers') }}
    ) b
    on a.USER_ID = b.id

    left outer join {{ source('stripe', 'stripe_payments') }} c
    on a.ID = c.ORDERID

    where a.STATUS NOT IN ('pending') and c.STATUS != 'fail'

    group by b.id, b.name, b.last_name, b.first_name

) customer_order_history
on orders.USER_ID = customer_order_history.customer_id

left outer join {{ source('stripe', 'stripe_payments') }} payments
on orders.ID = payments.ORDERID

where payments.STATUS != 'fail'
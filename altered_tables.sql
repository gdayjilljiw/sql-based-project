-- change 'sub-category' name in products
alter table products
rename "sub-category" to sub_category;

-- add foreign key in orders
alter table orders 
add constraint fk_customer
foreign key (customer_id) references customers(customer_id)
on delete cascade;

-- add foreign key in orders
alter table orders
add constraint fk_order_post 
foreign key (postal_code) references ship_locations(postal_code)
on delete cascade;

-- add pk in product sales
alter table product_sales
add constraint pk_prod_sales primary key (order_id, customer_id, product_id)

-- create indexes
create index prod_index
on products (product_id, sub_category, product_name)

create index order_index
on orders (order_id, order_date, ship_date);

create index product_sales_index
on product_sales (sales, profit);

-- check for duplicates
with cte_duplicates as
(select *, Row_Number() OVER (PARTITION BY order_id, customer_id, product_id) as duplicates
from product_sales
)
select order_id, customer_id, product_id from cte_duplicates
where duplicates > 1

-- drop view if exists order_sales_overview
-- drop view unit_price_overview;

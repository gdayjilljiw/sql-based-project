-- top cities/ states with most orders
select distinct city from ship_locations order by city;
select distinct state from ship_locations order by state;
-- top 10 cities
select count(o.order_id) total_orders, s.city
from orders o join ship_locations s 
on o.postal_code = s.postal_code
group by s.city
order by total_orders desc 
limit 10;
-- top 10 states
select count(o.order_id) total_orders, s.state
from orders o join ship_locations s 
on o.postal_code = s.postal_code
group by s.state
order by total_orders desc 
limit 10;


-- count customer segment
select segment, count(segment) from customers
group by segment;


-- product category and sub_category
select sub_category, category,  count(sub_category) total 
from products 
group by sub_category, category
order by total desc;

select category,  count(category) total 
from products 
group by category
order by total desc

select distinct category from products
select distinct sub_category from products

-- return orders
--- counts
select count(order_id) as "Number of Returns" from returns;
--- return products
with order_returns as(
	select o.order_id, r.returned, ps.product_id, p.product_name,
	count(ps.product_id) over(partition by ps.product_id) num_return, ps.customer_id
	from returns r 
	join orders o using(order_id)
	join product_sales ps using(order_id)
	join products p using(product_id)
	order by 5 desc
)
-- product_returns as(
select distinct product_id, product_name, num_return
from order_returns order by 3 desc, 1
	-- )

-- view product names and sales data
create or replace view order_sales_overview as 
	select ps.*, pd.product_name, pd.sub_category, pd.category, to_date(o.order_date, 'DD/MM/YY') order_date, 
	to_date(o.ship_date, 'DD/MM/YY') ship_date, o.ship_mode  from product_sales ps
	join products pd using (product_id)
	join orders o using (order_id);
-- drop view order_sales_overview;-- if needed

-- compute unit price for each product i.e before discount and create view
create or replace view unit_price_overview as
	with unit_prices as(
		select order_id, order_date, customer_id, product_id, product_name, sub_category,category, sales, quantity, discount, profit,  
		round(cast( sales / (1- discount) / quantity as numeric), 2) as unit_price
		from order_sales_overview
		),
		product_unit_prices as(
		select distinct product_id, unit_price, product_name, sub_category, category from unit_prices
		)
	select * from product_unit_prices order by sub_category;

---- unit prioces for each category 
select product_id, unit_price, sub_category, category from unit_price_overview
where category = 'Technology' order by unit_price;

select product_id, unit_price, sub_category, category from unit_price_overview
where category = 'Furniture' order by unit_price

-- max profit products
select product_name, profit, sales, quantity, discount from order_sales_overview
where profit = (select max(profit) from order_sales_overview);

-- max sales products
select product_name, sales, quantity, profit, discount from order_sales_overview
where sales = (select max(sales) from order_sales_overview);

-- top 10 most orderd products
with join_orders as (
	select o.order_id, pd.product_id, pd.product_name, pd.sub_category, ps.sales
	from orders o
	join product_sales ps
	using (order_id)
	join products pd
	using (product_id) order by product_id
	), top_ordered_products as(
	select product_id, product_name, count(order_id) count_orders, round(cast(sum(sales) as numeric), 2) total_sales  
	from join_orders
	group by product_name, product_id order by count_orders, total_sales desc
	)
select *, rank() over(order by count_orders desc) from top_ordered_products;

-- top most profitable sub category product
select sub_category, round(cast(sum(profit) as numeric), 2)  total_profits
from order_sales_overview 
group by sub_category order by total_profits desc limit 5

-- top most profit product
select product_id ,product_name, round(cast(sum(profit) as numeric), 2)  total_profits
from order_sales_overview 
group by product_name, product_id order by total_profits desc limit 10;

--
-- orders-customers: customers who made top 5 most orders
with shipment_orders as(
	select o.customer_id, c.customer_name, c.segment, o.order_id, 
	to_date(o.order_date, 'DD/MM/YY') order_date, to_date(o.ship_date, 'DD/MM/YY') ship_date
	,s.city, s.state, s.postal_code
	from orders o 
	join customers c
	using (customer_id)
	join ship_locations s
	using (postal_code)
	),
	top_customers as(
	select customer_id, customer_name, count(customer_id) num_orders 
	from shipment_orders
	group by customer_id, customer_name
	order by num_orders desc)
select * from top_customers

-- monthly sales/ profits
with year_month_day as(
	select order_id, customer_id, product_id, sales, quantity, profit, order_date,
	extract(year from order_date) as years,
	extract(month from order_date) as months
	from order_sales_overview
	order by order_date),
	sales_profits as (
	select months, years, case
			when months = 1 then 'JAN'
			when months = 2 then 'FEB'
			when months = 3 then 'MAR'
			when months = 4 then 'APR'
			when months = 5 then 'MAY'
			when months = 6 then 'JUN'
			when months = 7 then 'JUL'
			when months = 8 then 'AUG'
			when months = 9 then 'SEP'
			when months = 10 then 'OCT'
			when months = 11 then 'NOV'
			when months = 12 then 'DEC'
			end as month_name,
	round(cast(sum(sales) as numeric),2) total_sales, 
	round(cast(sum(profit) as numeric),2) total_profits,
	round(cast(lag(sum(sales), 12) over(order by years, months) as numeric),2) prev_year_sales,
	round(cast(lag(sum(profit), 12) over(order by years, months) as numeric),2) as prev_year_profits
	
	from year_month_day
	group by years, months order by years, months)
select concat(month_name,'-',years) month_year, total_sales,
	case 
		when prev_year_sales is not null then round((total_sales-prev_year_sales)*100/prev_year_sales,2) 
		end as yoy_sales,
	total_profits, 
	case
		when prev_year_profits is not null then round((total_profits-prev_year_profits)*100/prev_year_profits,2) 
		end as yoy_profits
from sales_profits

--- days of week orders
with days_of_week as(
	select order_id, extract(dow from order_date) dow, order_date
	from order_sales_overview
	order by order_date),
	day_names as(
	select order_id, dow,
	case
		when dow = 0 then 'SUN'
		when dow = 1 then 'MON'
		when dow = 2 then 'TUE'
		when dow = 3 then 'WED'
		when dow = 4 then 'THU'
		when dow = 5 then 'FRI'
		when dow = 6 then 'SAT'
	end as day_of_week, order_date
	from days_of_week)
	select count(order_id), day_of_week from day_names
	group by day_of_week, dow order by dow

-- 10 most sold products
select product_id, product_name, cast(sum(quantity) as int) total_quanitity
from order_sales_overview
group by product_id, product_name order by sum(quantity) desc
limit 10

--- RFM - recency freqeuncy monetary
--- most recent customers
select customer_id, max(order_date) most_recent_purchase,
rank() over(order by max(order_date)) recency_score
from order_sales_overview
group by customer_id 
order by recency_score desc, most_recent_purchase desc

-- most frequent customers
select customer_id, count(order_id) order_frequency, 
rank() over (order by count(order_id)) as frequency_score
from order_sales_overview
group by customer_id 
order by frequency_score desc, order_frequency desc

-- top spenders(
select customer_id,  round(cast(sum(sales) as numeric),2) total_purchases, 
rank() over(order by sum(sales)) as monetary_score 
from order_sales_overview
group by customer_id
order by monetary_score desc, total_purchases desc

with rfm_scores as(
	select os.customer_id, c.customer_name, 
	ntile(5) over (order by max(os.order_date) desc) as recency_score,
	ntile(5) over (order by count(os.order_id) desc) as frequency_score,
	ntile(5) over( order by sum(os.sales) desc) as monetary_score 
	from order_sales_overview os
	join customers c
	using (customer_id)
	group by customer_id, customer_name order by customer_id
	),
	segments as(
	select customer_id, customer_name, r,f, m, rfm,
	case
		when rfm ~ '^[4-5][4-5][4-5]$' and rfm !~'444' then 'Champion'
		when rfm ~'^543|444|435|355|354|345|344|335$' then 'Loyalist'
		when rfm ~ '^[3-5][3-5][1-3]|323|423$' and rfm !~'^331|332|343|443$' then 'Potential Loyalist'
		when rfm ~ '^[4][1-2][1-2]|512|511|311$' then 'New Customer'
		when rfm ~ '^535|534|443|434|343|334|325|324$' then 'Need Attention'
		when rfm ~ '^155|154|144|214|215|115|114|113$' then 'Cannot Lose'
		when rfm ~ '^331|321|312|221|213$' then 'About To Sleep'
		when rfm in('525', '524', '523', '522', '521', '515', '514', '513', 
					'425','424', '413','414','415', '315', '314', '313') then 'Promising'
		when rfm in('255', '254', '245', '244', '253', '252', '243', '242', '235', '234', '225', '224', 
					'153', '152', '145', '143', '142', '135', '134', '133', '125', '124') then 'At Risk'
		when rfm in('332', '322', '231', '241', '251', '233', '232', '223', '222', 
					'132', '123', '122', '212', '211') then 'Hibernating'
		-- when rfm ~'^111|112|121|131|141|151$' then 'Lost'
		else 'Lost'
		
	end as customer_segment
	from (select customer_id, customer_name, recency_score r, 
			frequency_score f, monetary_score m, 
			concat(recency_score,frequency_score, monetary_score) rfm from rfm_scores)
	)
	select customer_id, customer_name, r,f,m, rfm, customer_segment, 
	count(customer_segment) over(partition by customer_segment) counts
	from segments order by counts ; 


select product_name, row_number() over (partition by product_name) rows from products
order by rows desc;



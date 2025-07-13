--write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 
select top 5 city, sum(amount) as total_spend,
round(sum(amount) * 100.0/ (select sum(amount) from credit_card_transactions), 3) as spend_percentage
from credit_card_transactions
group by city
order by spend_percentage desc;


--write a query to print highest spend month and amount spent in that month for each card type
with cte as (
select card_type,
datepart(month, transaction_date) as month,
datepart(year, transaction_date) as year,
sum(amount) as amount_spent,
rank() over(partition by card_type order by sum(amount) desc) as rnk
from credit_card_transactions
group by card_type, datepart(month, transaction_date), datepart(year, transaction_date)
)
select card_type, month, year, amount_spent
from cte
where rnk = 1;


-- write a query to print the transaction details(all columns from the table) for each card type when
-- it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as (
select *, sum(amount) over(partition by card_type order by transaction_date, transaction_id) as running_sum
from credit_card_transactions
),
cte2 as (
select *, rank() over(partition by card_type order by running_sum) as rnk
from cte
where running_sum >= 1000000
)
select *
from cte2
where rnk = 1;


--write a query to find city which had lowest percentage spend for gold card type
select top 1 city, sum(case when card_type = 'Gold' then amount else 0 end) * 100.0/sum(amount) as lowest_percent
from credit_card_transactions
group by city
having sum(case when card_type = 'Gold' then amount else 0 end) * 100.0/sum(amount) > 0
order by lowest_percent;


--write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte as (
select city, exp_type, sum(amount) as amount_spent,
rank() over(partition by city order by sum(amount)) as rnkl,
rank() over(partition by city order by sum(amount) desc) as rnkh
from credit_card_transactions
group by city, exp_type
),
h as (
select city, exp_type as highest_expense_type
from cte 
where rnkh = 1),
l as (
select city, exp_type as lowest_expense_type
from cte 
where rnkl = 1
)
select h.city, 
highest_expense_type, 
lowest_expense_type
from h 
inner join l on h.city = l.city
order by h.city;


--write a query to find percentage contribution of spends by females for each expense type
select exp_type,
sum(case when gender = 'F' then amount else 0 end) * 100.0 / sum(amount) as spend_percentage
from credit_card_transactions
group by exp_type;


--which card and expense type combination saw highest month over month growth in Jan-2014
with cte as (
select card_type, exp_type, sum(amount) as spent
from credit_card_transactions
where datepart(month, transaction_date) = 1 and datepart(year, transaction_date) = 2014
group by card_type, exp_type
),
cte2 as (
select card_type, exp_type, sum(amount) as spent
from credit_card_transactions
where datepart(month, transaction_date) = 12 and datepart(year, transaction_date) = 2013
group by card_type, exp_type
)
select top 1 cte.card_type, cte.exp_type, round((cte.spent - cte2.spent) * 100.0 / cte2.spent, 2) as highest
from cte 
inner join cte2 on cte.card_type = cte2.card_type and cte.exp_type = cte2.exp_type
order by highest desc


--which city took least number of days to reach its 500th transaction after the first transaction in that city
select top 1 city, datediff(day, min(transaction_date), max(transaction_date)) as days
from (
select *, row_number() over(partition by city order by transaction_date) as rw from credit_card_transactions
) k
where rw = 1 or rw = 500
group by city
having count(*) = 2
order by days


--during weekends which city has highest total spend to total no of transactions ratio 
select top 1 city, sum(amount)/count(*) as Ratio
from credit_card_transactions
where datepart(weekday, transaction_date) in (1, 7)
group by city
order by Ratio desc

--total spent by month
select transaction_date, sum(amount) as amount from credit_card_transactions
group by transaction_date
order by transaction_date
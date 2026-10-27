create table customer_support_tickets(
      ticket_id varchar(50) primary key,
	  cust_name varchar(100),
	  cust_email varchar(100),
	  cust_age int,
	  cust_gender varchar(50),
	  product_purchased varchar(100),
	  date_of_purchase date,
	  ticket_type varchar(50),
	  ticket_sub varchar(100),
	  ticket_description text,
	  ticket_status varchar(50),
	  resolution text,
	  ticket_priority varchar(50),
	  ticket_channel varchar(50),
	  first_response_time text,
	  time_to_resolution text,
	  cust_satisfaction_rating text
)

select * from customer_support_tickets

--row count
select count(ticket_id)
from customer_support_tickets

--check for missing values
select *
from customer_support_tickets
where ticket_id is null

 --check for null customer satisfaction rating
select *
from customer_support_tickets
where cust_satisfaction_rating is null

--Compare total tickets vs unique customers
select count (ticket_id), count(distinct cust_name)
from customer_support_tickets

--Find data anomalies where first response time occurs after resolution time
select count(ticket_id)
from customer_support_tickets
where first_response_time>= time_to_resolution



--ticket volume by channel
select ticket_channel, count(ticket_id) as tot_tickets
from customer_support_tickets
group by ticket_channel
order by tot_tickets desc

--support ticket count and satisfaction by priority level
select ticket_priority,count(ticket_id) as tot_tickets,
       round(avg(cust_satisfaction_rating::numeric),2)
from customer_support_tickets
group by ticket_priority
order by tot_tickets desc

--avg resolution time by channel
select ticket_channel, count(ticket_id),avg(time_to_resolution::timestamp-first_response_time::timestamp) as average_time
from customer_support_tickets
where time_to_resolution::timestamp>first_response_time::timestamp
group by ticket_channel
order by average_time


--Check database date boundaries (project timeline span)
select min(date_of_purchase), max(date_of_purchase)
from customer_support_tickets

--Ticket Volume Breakdown by Communication Channel
select ticket_channel,count(ticket_id) as tot_tickets
from customer_support_tickets
group by ticket_channel
order by tot_tickets desc


--Unresolved High-Priority Tickets Backlog Tracking
select ticket_priority,ticket_status,count(ticket_id)
from customer_support_tickets
where ticket_priority='High' and ticket_status!='Closed'
group by ticket_priority,ticket_status

--Resolution Speed Categorization & Percentage Distribution
select 
   case when extract(epoch from(to_timestamp(time_to_resolution,'dd-mm-yyyy hh24:mi')-to_timestamp(first_response_time, 'dd-mm-yyyy hh24:mi')))/3600 <=24  then 'Fast'
        when extract(epoch from(to_timestamp(time_to_resolution,'dd-mm-yyyy hh24:mi')-to_timestamp(first_response_time,'dd-mm-yyyy hh24:mi')))/3600 between 24 and 72  then 'Moderate'
	    else 'Slow'
	end,
	count(ticket_id),
	round(count(ticket_id)*100/sum(count(ticket_id)) over(),2) as round
from customer_support_tickets
where time_to_resolution is not null and date_of_purchase is not null
group by case when extract(epoch from(to_timestamp(time_to_resolution,'dd-mm-yyyy hh24:mi')-to_timestamp(first_response_time, 'dd-mm-yyyy hh24:mi')))/3600 <=24  then 'Fast'
              when extract(epoch from(to_timestamp(time_to_resolution,'dd-mm-yyyy hh24:mi')-to_timestamp(first_response_time, 'dd-mm-yyyy hh24:mi')))/3600 between 24 and 72  then 'Moderate'
	    else 'Slow'
	end 

--Top Ticket Sub-Categories per Channel using DENSE_RANK()
with cte as(select ticket_channel,ticket_sub,count(ticket_id) as tot_ticket
from customer_support_tickets
group by ticket_channel,ticket_sub)

select ticket_channel,ticket_sub,dense_rank() over(partition by ticket_channel order by tot_ticket desc)
from cte

--Customer Segmentation (VIP vs Moderate vs One-Time Callers) ranked by volume
with cte as (
with cte as (select count(cust_name) as tot_tickets, cust_name
from customer_support_tickets
group by cust_name),


ab as(select case when tot_tickets>3 then 'vip'
            when tot_tickets between 2 and 3 then 'moderate'
		else 'one-time caller'
		end as cust_rate,tot_tickets, cust_name
from cte)

select tot_tickets,cust_name,cust_rate,dense_rank() over(order by tot_tickets desc )
from ab

--7-Day Moving Average & Volume Spike Detection (Anomaly Alert)
with cte as(
select date_of_purchase, count(ticket_id) as tot_tickets
from customer_support_tickets
group by date_of_purchase),

abc as(select date_of_purchase,tot_tickets,
              round(avg(tot_tickets) over(order by date_of_purchase 
			  rows between 6 preceding and current row),2) as rolling_avg,
			  avg(tot_tickets) over() as overall_avg
	   from cte)

select date_of_purchase,tot_tickets,rolling_avg,
       case when tot_tickets>(1.5*overall_avg) then 'Spike Alert'
	        else 'Normal'
	   end
from abc

--Day-over-Day Momentum Shift Analysis using LAG()
with cte as(
     select date_of_purchase, count(ticket_id) as tot_tickets
	 from customer_support_tickets
	 group by date_of_purchase
),
abc as(
      select date_of_purchase,tot_tickets,
	  lag(tot_tickets,1) over(order by date_of_purchase) as previous_day_tickets
	  from cte
)

select date_of_purchase,tot_tickets,previous_day_tickets,
       tot_tickets-previous_day_tickets as diff,
	   round((tot_tickets-previous_day_tickets::numeric)/nullif(previous_day_tickets,0)*100,2)
from abc
order by date_of_purchase
	



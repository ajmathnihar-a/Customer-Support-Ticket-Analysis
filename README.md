# Customer Support Ticket Analysis

## Project Overview

This project analyzes customer support ticket data to understand ticket volume, resolution performance, customer satisfaction, and SLA compliance. The goal is to identify support trends and highlight areas where ticket handling could be improved.

I used Excel for basic data cleaning, Power Query for data type corrections and ticket status classification, PostgreSQL for SQL analysis, and Power BI to create DAX measures and an interactive dashboard.

## Dashboard Preview

![Customer Support Ticket Analysis Dashboard](Customer%20Support%20Tickets.png)

## Business Problems

* How many support tickets were received, and how many remain unresolved?
* How many unresolved tickets are waiting on the support team versus the customer?
* Which support channels receive the highest number of tickets?
* Which ticket types generate the most support requests?
* What percentage of tickets are resolved, and how well does the support team meet its SLA target?
* Do resolution rate and SLA compliance differ across ticket priority levels?
  
## Tools & Technologies

* **Excel:** Basic data cleaning and preparation
* **Power Query:** Data type corrections and conditional column creation
* **PostgreSQL:** SQL queries, aggregations, CTEs, and window functions
* **Power BI:** DAX measures, KPI calculations, and dashboard development

## Data Preparation

* Performed basic data cleaning in Excel.
* Corrected data types in Power Query.
* Created conditional columns in Power Query to classify tickets as **Resolved** (Closed), **Waiting on Support** (Open) or **Waiting on Customer** (Pending Customer Response).

## SQL Analysis

Used PostgreSQL to analyze ticket volume, customer satisfaction, ticket priorities, and daily ticket volume (based on the dataset's date_of_purchase field).

### 1. Ticket Volume by Support Channel

Identifies which communication channels receive the most support tickets.

```sql
select ticket_channel, count(ticket_id) as tot_tickets
from customer_support_tickets
group by ticket_channel
order by tot_tickets desc
```

### 2. Customer Satisfaction by Ticket Priority

Compares ticket volume and average customer satisfaction across priority levels.

```sql
select ticket_priority,count(ticket_id) as tot_tickets,
       round(avg(cust_satisfaction_rating::numeric),2)
from customer_support_tickets
group by ticket_priority
order by tot_tickets desc
```

### 3. Top Ticket Subcategories by Channel

Uses a CTE and `DENSE_RANK()` to rank ticket subcategories within each support channel.

```sql
with cte as(select ticket_channel,ticket_sub,count(ticket_id) as tot_ticket
from customer_support_tickets
group by ticket_channel,ticket_sub)

select ticket_channel,ticket_sub,dense_rank() over(partition by ticket_channel order by tot_ticket desc)
from cte
```

### 4. Ticket Status Breakdown

Splits tickets into Resolved, Waiting on Support, and Waiting on Customer, with each group's share of the total.

```sql
select
    case when ticket_status = 'Closed' then 'Resolved'
         when ticket_status = 'Open' then 'Waiting on Support'
         when ticket_status = 'Pending Customer Response' then 'Waiting on Customer'
    end as status_group,
    count(ticket_id) as tot_tickets,
    round(100.0 * count(ticket_id) / sum(count(ticket_id)) over (), 1) as pct_of_total
from customer_support_tickets
group by 1
order by tot_tickets desc;
```

Additional SQL analysis included high-priority unresolved ticket tracking, data quality checks, customer segmentation, moving averages, and ticket volume comparisons using `LAG()`. The complete queries are available in the SQL file in this repository.

## Power BI Dashboard

Developed an interactive dashboard to monitor customer support ticket volume, ticket status, support channels, ticket types, and priority-wise resolution and SLA performance.

### Key DAX Measures

* **Total Tickets:** Counts all tickets.
* **Unresolved Tickets:** Counts tickets whose status is not Closed (Open + Pending Customer Response).
* **Resolution Rate %:** Proportion of tickets with status Closed.
* **SLA Compliance %:** Proportion of eligible tickets meeting the defined first-response threshold.
* **Waiting on Support / Waiting on Customer:** Splits unresolved tickets by who the ticket is waiting on.
* **Average Satisfaction:** Average customer satisfaction rating.


## Definitions
* **Resolved:** status is Closed
* **Unresolved:** status is Open or Pending Customer Response
* **Waiting on Support:** Open tickets
* **Waiting on Customer:** Pending Customer Response tickets

## Key Outcomes
* **Unresolved backlog:** 5,700 of 8,469 tickets (67.3%) were not yet closed.
* **Who the backlog is waiting on:** 2,819 tickets (33.3% of all tickets) were waiting on the support team and 2,881 (34.0%) on customer responses, so the true team backlog was about one third of total volume.
* **SLA compliance:** First-response SLA compliance was 49.9%, and the resolution rate was 32.7%.
* **Priority:** Resolution rate (31.2% to 34.1%) and SLA compliance (48.2% to 51.0%) were nearly flat across priority levels. Critical tickets had the lowest SLA compliance at 48.2%, which may indicate that triage and escalation rules need review.
* **Support channels:** Email had the most tickets (2,143) and Chat the fewest (2,073), a relatively even distribution.
* **Ticket types:** All five types (refund requests, technical issues, cancellation requests, product inquiries, billing inquiries) each made up about 19% to 21% of tickets, so no single issue type dominates.
* **Customer satisfaction:** Average satisfaction was nearly identical across priority levels, ranging from 2.96 (Critical) to 3.05 (Low), so priority had little visible effect on customer experience.


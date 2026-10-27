# Customer Support Ticket Analysis

## Project Overview

This project analyzes customer support ticket data to understand ticket volume, resolution performance, customer satisfaction, and SLA compliance. The goal is to identify support trends and highlight areas where ticket handling could be improved.

I used Excel for basic data cleaning, Power Query for data type corrections and ticket status classification, PostgreSQL for SQL analysis, and Power BI to create DAX measures and an interactive dashboard.

## Business Problems

* How many support tickets were received, and how many remain unresolved?
* Which support channels receive the highest number of tickets?
* Which ticket subcategories generate the most support requests?
* How does customer satisfaction vary across ticket priority levels?
* How many high-priority tickets remain unresolved?
* What percentage of tickets are resolved, and how well does the support team meet its SLA target?
* Are there noticeable changes or spikes in ticket volume over time?

## Tools & Technologies

* **Excel:** Basic data cleaning and preparation
* **Power Query:** Data type corrections and conditional column creation
* **PostgreSQL:** SQL queries, aggregations, CTEs, and window functions
* **Power BI:** DAX measures, KPI calculations, and dashboard development

## Data Preparation

* Performed basic data cleaning in Excel.
* Corrected data types in Power Query.
* Created a conditional column to classify tickets into Pending and Resolved categories.

## SQL Analysis

Used PostgreSQL to analyze ticket volume, customer satisfaction, ticket priorities, and ticket trends.

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

Additional SQL analysis included high-priority unresolved ticket tracking, data quality checks, customer segmentation, moving averages, and ticket volume comparisons using `LAG()`. The complete queries are available in the SQL file in this repository.

## Power BI Dashboard

Developed an interactive dashboard to monitor customer support ticket volume, ticket status, support channels, ticket types, and priority-wise resolution and SLA performance.

### Key DAX Measures

* **Average Satisfaction:** Calculates the average customer satisfaction rating.
* **High Priority %:** Calculates the proportion of tickets classified as high priority.
* **Open/Unresolved Tickets:** Counts tickets whose status is not Closed.
* **Resolution Rate %:** Calculates the proportion of tickets classified as Resolved.
* **SLA Compliance %:** Calculates the proportion of eligible tickets meeting the defined first-response threshold.

## Dashboard Preview

![Customer Support Ticket Analysis Dashboard](customer_support_tickets.png)

## Key Outcomes

* **Unresolved Ticket Backlog:** Identified 5,700 unresolved tickets, representing 67.3% of the 8,469 total tickets. This highlights the need to investigate resolution delays and prioritize outstanding cases.
* **SLA Compliance:** Measured first-response SLA compliance at 50%, highlighting a potential gap against the defined service-level target. 
* **Support Channel Analysis:** Compared ticket volumes across Email, Phone, Social Media, and Chat. Email recorded the highest volume at 2,143 tickets, while Chat recorded the lowest at 2,073, showing a relatively even distribution across channels.
* **Ticket Type Analysis:** Compared support request volumes across refunds, technical issues, billing, and product inquiries to identify the categories generating customer support demand.


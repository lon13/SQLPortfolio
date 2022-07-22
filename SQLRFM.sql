--inspecting data

select *
from sales$

--checking unique values
select distinct status from sales$ --nice to plot
select distinct YEAR_ID from sales$
select distinct PRODUCTLINE from sales$ --nice to plot
select distinct COUNTRY from sales$ --nice to plot
select distinct DEALSIZE from sales$ --nice to plot
select distinct TERRITORY from sales$ --nice to plot

--Analysis
----Start by grouping sales by productline

select productline , sum(sales) Revenue
from PortfolioProject.dbo.sales$
group by PRODUCTLINE
order by 2 desc

select YEAR_ID , sum(sales) Revenue
from PortfolioProject.dbo.sales$
group by YEAR_ID
order by 2 desc

--sum of 2005 revenue is for 5 months operation

--what was the best month for sales in a specific year? how much was earned that month?

select MONTH_ID, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sales$
where YEAR_ID = 2005 --change year to see the rest
group by MONTH_ID
order by 2 desc

--November seems to be the month, what product do they sell in November

select MONTH_ID, PRODUCTLINE, sum(sales) Revenue, count(ORDERNUMBER) Frequency
from sales$
where YEAR_ID = 2004 and MONTH_ID = 11 --change year/month to see the rest
group by MONTH_ID, PRODUCTLINE 
order by 3 desc

--who is our best customer (RFM)

Drop Table If exists #rfm

;with rfm as
(
	select
			CUSTOMERNAME,
			sum(sales) MonetaryValue,
			avg(sales) AvgMonetaryValue,
			count(ordernumber) frequency,
			max(orderdate) last_order_date,
			(select max(orderdate) from sales$) max_order_date,
			datediff(DD,max(orderdate),(select max(orderdate) from sales$)) Recency
		from sales$
		group by CUSTOMERNAME
),
rfm_calc as
(
select r.*,
	NTILE(4) OVER (order by Recency desc) rfm_recency,
	NTILE(4) OVER (order by frequency) rfm_frequency,
	NTILE(4) OVER (order by MonetaryValue) rfm_monetary
from rfm r
)

select 
	c.*, rfm_recency + rfm_frequency + rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar) rfm_cell_string

into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency , rfm_frequency , rfm_monetary,
	CASE
		when rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) then 'lost_customers' --lost customers
		when rfm_cell_string in (133,134,143,244,334,343,344) then 'slipping away' --Big spenders who havent purchased lately
		when rfm_cell_string in (311,411,331) then 'new_customers'
		when rfm_cell_string in (222,223,233,322) then 'potential_churners'
		when rfm_cell_string in (323,333,321,422,332,432) then 'active' --customers who buy often , but at a low price points
		when rfm_cell_string in (433,434,443,444) then 'loyal'
	end rfm_segment
from #rfm

--What products are most often sold together

--select * from sales$ where ORDERNUMBER = 10411

select distinct OrderNumber, stuff(
	(select ',' + PRODUCTCODE
	from sales$ p
	where ORDERNUMBER in
		(
		select ORDERNUMBER
		from (
			select ORDERNUMBER, count(*) rn
			from sales$
			where STATUS = 'Shipped'
			group by ORDERNUMBER
			)m
			where rn = 2
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')), 1,1,'') ProductCodes

from sales$ s
order by 2 desc


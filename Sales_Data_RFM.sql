
-- Inspecting data
Select * from dbo.Sales_Data_RFM;

-- Checking unique values

Select distinct STATUS from dbo.Sales_Data_RFM; -- Nice one to plot
Select distinct YEAR_ID from dbo.Sales_Data_RFM;
Select distinct PRODUCTLINE from dbo.Sales_Data_RFM; -- Nice to plot 
Select distinct COUNTRY from dbo.Sales_Data_RFM; -- Nice to plot 
Select distinct DEALSIZE from dbo.Sales_Data_RFM; -- Nice to plot
Select distinct TERRITORY from dbo.Sales_Data_RFM;  -- Nice to plot 


Select distinct MONTH_ID from Sales_Data_RFM
Where YEAR_ID = 2003

-- Analysis 
-- lets calculate sales by productline

Select PRODUCTLINE, SUM(SALES)  as 'Revenue'
from Sales_Data_RFM
Group by PRODUCTLINE
Order by 2 desc; -- 2 is position of column

-- lets calculate the sales by the year

Select YEAR_ID, SUM(SALES)  as 'Revenue'
from Sales_Data_RFM
Group by YEAR_ID
Order by 2 desc; -- 2 is position of column

-- lets calculate the sales by the dealsize

Select DEALSIZE, SUM(SALES)  as 'Revenue'
from Sales_Data_RFM
Group by DEALSIZE
Order by 2 desc; -- 2 is position of column


-- What was the best month for sales in specific year? How much that month earned

Select MONTH_ID, SUM(SALES) Revenue, COUNT(ORDERNUMBER) Frequency
from Sales_Data_RFM
Where YEAR_ID = 2004 -- Change year to see rest
Group by MONTH_ID 
Order by 2 desc;


-- Noveber is the best month in sales, What product do they sell in noverber,classic I believe 

Select MONTH_ID,PRODUCTLINE,SUM(SALES) Revenue, Count(ORDERNUMBER) Frequency  
from Sales_Data_RFM
Where YEAR_ID = 2003 and MONTH_ID = 11
Group By MONTH_ID,PRODUCTLINE
Order by 3 desc;


-- Who is our best customer(this could be answered on the basis of RFM)

Drop table if exists #rfm;
With rfm 
as (
	Select 
		CUSTOMERNAME,
		SUM(SALES) as Monetary_Value,
		AVG(SALES) as Avg_Monetary_Value,
		COUNT(ORDERNUMBER) as Frequency,
		MAX(ORDERDATE) as Last_Order,
		(Select MAX(ORDERDATE)  from Sales_Data_RFM) max_order_date ,
		DATEDIFF(DD,MAX(ORDERDATE),(Select MAX(ORDERDATE) max_order_date from Sales_Data_RFM)) as Recency 
	From Sales_Data_RFM
    Group by CUSTOMERNAME
   ),
rfm_calc 
as (
	Select r.*,
	NTILE(4) Over(Order by Recency desc) as rfm_recency,
	NTILE(4) Over(Order by Monetary_Value) as rfm_monetary,
	NTILE(4) Over(Order by Frequency) as rfm_frequency
	From rfm r
)
Select c.*,rfm_recency+rfm_monetary+rfm_frequency as rfm_cell,
Cast(rfm_recency AS varchar)+Cast(rfm_monetary AS varchar)+cast(rfm_frequency AS varchar) as rfm_cell_string
into #rfm
from rfm_calc c;

-- Categories the customers on their rfm_cell value
Select CUSTOMERNAME,rfm_frequency,rfm_monetary,rfm_recency,rfm_cell,rfm_cell_string,
CASE 
   When rfm_cell <=3 then 'At Risk Customer'
   When rfm_cell <=6 then 'Attention Please'
   When rfm_cell <=9 then 'Loyal Customer'
   When rfm_cell <=12 then 'Best Customer'
   Else 'Other'
   End as Customer_Segment
from #rfm;


-- categories the customers

Select CUSTOMERNAME, rfm_recency,rfm_frequency,rfm_monetary,rfm_cell_string,
Case 
    When rfm_cell_string In (111,121,112,211,122,221,212,222,141,213,132,123) then 'Lost Customer' -- Lost Customer
	When rfm_cell_string In (133,144,143,244,233,234,243) then 'Sleeping away, cannot lose' -- Big spendors who haven't purchase lately, slipping away
	When rfm_cell_String In (411,421,412,422,311,321,312) then 'New Customers' -- New Customer
	When rfm_cell_string In (232,322,423,333,323,223) then 'Potential Customers' 
	When rfm_cell_string In (431,432,331,332) then 'active' -- the customer who purchase buy oftenly and recently but at spent low costs
	When rfm_cell_string In (444,433,344,343,434,334,443) then 'Loyal Customers' 
	End as Customer_Segmentation
from #rfm


-- What product most often sold together ?
 
Select distinct ORDERNUMBER,STUFF(
	(Select ',', PRODUCTCODE 
	from Sales_Data_RFM p
	Where ORDERNUMBER in (
	Select ORDERNUMBER from 
	(
		Select ORDERNUMBER, COUNT(*) rn 
		from Sales_Data_RFM
		Where STATUS = 'shipped'
		Group by ORDERNUMBER
	) m
	Where rn =2
	) and
	s.ORDERNUMBER = p.ORDERNUMBER
FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Product_Codes
from Sales_Data_RFM s
Order by 2 desc




SELECT 
    s.ORDERNUMBER,
    STUFF((
        SELECT ',' + p.PRODUCTCODE 
        FROM Sales_Data_RFM p
        WHERE p.ORDERNUMBER = s.ORDERNUMBER
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 1, '') AS Product_Codes
FROM Sales_Data_RFM s
WHERE s.ORDERNUMBER IN (
    SELECT ORDERNUMBER 
    FROM (
        SELECT ORDERNUMBER, COUNT(*) AS rn 
        FROM Sales_Data_RFM
        WHERE STATUS = 'shipped'
        GROUP BY ORDERNUMBER
    ) m
    WHERE rn = 2
)
GROUP BY s.ORDERNUMBER;




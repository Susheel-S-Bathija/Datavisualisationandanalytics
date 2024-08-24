Create database Retailstoreanalysis_04082024
-- uploaded the file on SQL server into two different tables named dbo.Ordersdata and dbo.customers

-- Total revenue
Select 
Round(sum(order_total),0) as 'Revenue'
From dbo.Ordersdata
--Q1 end--

-- Total revenue by top 25 customers
-- First, aggregate total revenue by each customer
WITH CustomerRevenue AS (
    SELECT
        CUSTOMER_KEY,
        SUM(ORDER_TOTAL) AS TotalRevenue
    FROM dbo.Ordersdata
    GROUP BY CUSTOMER_KEY
),

-- Rank customers by their total revenue
RankedCustomers AS (
    SELECT
        CUSTOMER_KEY,
        TotalRevenue,
        ROW_NUMBER() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank
    FROM CustomerRevenue
)

-- Select the sum of the top 25 customers' total revenue
SELECT
    SUM(TotalRevenue) AS Top25Revenue
FROM RankedCustomers
WHERE RevenueRank <= 25

--Q2 end--
--
Select
count(order_number) as 'total count of orders'
from dbo.Ordersdata
-- Q3 end

-- Calculate the count of orders for each customer
WITH CustomerOrderCounts AS (
    SELECT
        CUSTOMER_KEY,
        COUNT(ORDER_NUMBER) AS CountOfOrders
    FROM dbo.Ordersdata
    GROUP BY CUSTOMER_KEY
),

-- Rank customers by their order count
RankedCustomers AS (
    SELECT
        CUSTOMER_KEY,
        CountOfOrders,
        ROW_NUMBER() OVER (ORDER BY CountOfOrders DESC) AS OrderRank
    FROM CustomerOrderCounts
)

-- Select the sum of order counts for the top 10 customers
SELECT
    SUM(CountOfOrders) AS Top10CustomerOrderCount
FROM RankedCustomers
WHERE OrderRank <= 10;
--Q4 end

-- Number of customers ordered once
-- Find customers with exactly one order
WITH SingleOrderCustomers AS (
    SELECT
        CUSTOMER_KEY,
        COUNT(ORDER_NUMBER) AS CountOfOrders
    FROM dbo.Ordersdata
    GROUP BY CUSTOMER_KEY
    HAVING COUNT(ORDER_NUMBER) = 1
)
-- count the number of such customers
SELECT
    COUNT(*) AS 'NumberOfSingleOrderCustomers'
FROM SingleOrderCustomers
-- Q6 end
-- Number of customers ordered multiple times
-- Find customers with more than one order
WITH MultiOrderCustomers AS (
    SELECT
        CUSTOMER_KEY,
        COUNT(ORDER_NUMBER) AS CountOfOrders
    FROM dbo.Ordersdata
    GROUP BY CUSTOMER_KEY
    HAVING COUNT(ORDER_NUMBER) > 1
)
-- count the number of such customers
SELECT
    COUNT(*) AS 'NumberOfMultiOrderCustomers'
FROM MultiOrderCustomers
-- Q7 end

-- Number of customers referred to other customers
SELECT
    COUNT(Customer_key) AS CountOfReferredCustomers
FROM dbo.customers
WHERE Referred_Other_Customers = 1;
-- Q8 end

-- Month with maximum revenue
Select
Year(order_date) as 'Year',
Month(Order_date) as 'Month',
sum(Order_total) as 'total_revenue'
from dbo.Ordersdata
Group by Year(order_date),Month(Order_date)
Order by total_revenue desc
-- Q9 end

-- Number of inactive customers
SELECT COUNT(DISTINCT CUSTOMER_KEY) AS NumberOfInactiveCustomers
FROM dbo.Ordersdata
WHERE ORDER_DATE < DATEADD(DAY, -60, '2016-07-30')
-- Q10 end

--Growth rate (%) in Orders (from Nov15 to Jul16)
WITH OrdersCount AS (
    SELECT
        COUNT(CASE WHEN ORDER_DATE BETWEEN '2015-11-01' AND '2015-11-30' THEN 1 END) AS Orders_Nov_2015,
        COUNT(CASE WHEN ORDER_DATE BETWEEN '2016-07-01' AND '2016-07-31' THEN 1 END) AS Orders_Jul_2016
    FROM dbo.Ordersdata
)

-- Calculate the growth rate percentage
SELECT
    Orders_Nov_2015,
    Orders_Jul_2016,
    CASE 
        WHEN Orders_Nov_2015 = 0 THEN NULL -- Avoid division by zero
        ELSE ((Orders_Jul_2016 - Orders_Nov_2015) * 100.0 / Orders_Nov_2015) 
    END AS GrowthRatePercentage
FROM OrdersCount
--Q11 end

--Growth Rate (%) in Revenue (from Nov'15 to July'16)

-- Calculate the total revenue for each period
WITH RevenueCount AS (
    SELECT
        SUM(CASE WHEN ORDER_DATE BETWEEN '2015-11-01' AND '2015-11-30' THEN ORDER_TOTAL ELSE 0 END) AS Revenue_Nov_2015,
        SUM(CASE WHEN ORDER_DATE BETWEEN '2016-07-01' AND '2016-07-31' THEN ORDER_TOTAL ELSE 0 END) AS Revenue_Jul_2016
    FROM dbo.Ordersdata
)

-- Calculate the growth rate percentage
SELECT
    Revenue_Nov_2015,
    Revenue_Jul_2016,
    CASE 
        WHEN Revenue_Nov_2015 = 0 THEN NULL -- Avoid division by zero
        ELSE ((Revenue_Jul_2016 - Revenue_Nov_2015) * 100.0 / Revenue_Nov_2015) 
    END AS GrowthRatePercentage
FROM RevenueCount
--Q12 end

-- % of male customers
-- Calculate the percentage of male customers who have placed orders
WITH CustomerOrders AS (
    SELECT DISTINCT
        c.CUSTOMER_KEY,
        c.Gender
    FROM dbo.customers c
    JOIN dbo.ordersdata o
    ON c.CUSTOMER_KEY = o.CUSTOMER_KEY
),

CustomerCounts AS (
    SELECT
        COUNT(CASE WHEN Gender = 'M' THEN 1 END) AS MaleCustomerCount,
        COUNT(*) AS TotalCustomerCount
    FROM CustomerOrders
)

-- Calculate the percentage of male customers
SELECT
    MaleCustomerCount,
    TotalCustomerCount,
    CASE
        WHEN TotalCustomerCount = 0 THEN NULL -- Avoid division by zero
        ELSE (MaleCustomerCount * 100.0 / TotalCustomerCount)
    END AS MaleCustomerPercentage
FROM CustomerCounts
-- Q13 end

-- Location with Maximum number of customers
SELECT TOP 1
    Location,
    COUNT(Distinct CUSTOMER_KEY) AS CustomerCount
FROM dbo.customers
GROUP BY Location
ORDER BY CustomerCount DESC
--Q14 end

-- Orders returned 
SELECT
    COUNT(*) AS ReturnedOrdersCount
FROM dbo.ordersdata
WHERE ORDER_TOTAL < 0
--Q15 end

-- Which Acquisition channel is more efficient in terms of customer acquisition?
SELECT
    Acquired_Channel,
    COUNT(Distinct CUSTOMER_KEY) AS CustomerCount
FROM dbo.customers
GROUP BY Acquired_Channel
ORDER BY CustomerCount DESC
--Q16 end

--Which location having more orders with discount amount?
SELECT
    c.Location,
    COUNT(o.ORDER_NUMBER) AS DiscountedOrdersCount
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE o.DISCOUNT > 0
GROUP BY c.Location
ORDER BY DiscountedOrdersCount DESC
--Q17 end

-- Which location having maximum orders delivered in delay?
SELECT
    c.Location,
    COUNT(o.ORDER_NUMBER) AS DelayedOrdersCount
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE o.DELIVERY_STATUS = 'LATE'
GROUP BY c.Location
ORDER BY DelayedOrdersCount DESC
--Q18 end
--What is the percentage of customers who are males acquired by APP channel?
WITH AppChannelCustomers AS (
    SELECT
        COUNT(CASE WHEN Gender = 'M' THEN 1 END) AS MaleCustomerCount,
        COUNT(*) AS TotalCustomerCount
    FROM dbo.customers
    WHERE Acquired_Channel = 'APP'
)
SELECT
    MaleCustomerCount,
    TotalCustomerCount,
    CASE 
        WHEN TotalCustomerCount = 0 THEN NULL -- Avoid division by zero
        ELSE (MaleCustomerCount * 100.0 / TotalCustomerCount)
    END AS MaleCustomerPercentage
FROM AppChannelCustomers
--Q19 end

--What is the percentage of orders got canceled?

WITH OrderCounts AS (
    SELECT
        COUNT(*) AS TotalOrders,
        COUNT(CASE WHEN ORDER_STATUS = 'CANCELLED' THEN 1 END) AS CanceledOrders
    FROM dbo.ordersdata
)
SELECT
    TotalOrders,
    CanceledOrders,
    CASE
        WHEN TotalOrders = 0 THEN NULL -- Avoid division by zero
        ELSE (CanceledOrders * 100.0 / TotalOrders)
    END AS CanceledOrdersPercentage
FROM OrderCounts
--Q20 end

-- What is the percentage of orders done by happy customers (Note: Happy customers mean customer who referred other customers)
WITH HappyCustomers AS (
    SELECT DISTINCT CUSTOMER_KEY
    FROM dbo.customers
    WHERE Referred_Other_customers = '1'
),
OrdersByHappyCustomers AS (
    SELECT
        COUNT(o.ORDER_NUMBER) AS OrdersByHappyCustomers
    FROM dbo.ordersdata o
    JOIN HappyCustomers hc
    ON o.CUSTOMER_KEY = hc.CUSTOMER_KEY
),
TotalOrders AS (
    SELECT
        COUNT(ORDER_NUMBER) AS TotalOrders
    FROM dbo.ordersdata
)
SELECT
    OrdersByHappyCustomers,
    TotalOrders,
    CASE
        WHEN TotalOrders = 0 THEN NULL
        ELSE (OrdersByHappyCustomers * 100.0 / TotalOrders)
    END AS PercentageOrdersByHappyCustomers
FROM OrdersByHappyCustomers, TotalOrders
-- Q21 end

--Which Location having maximum customers through reference?
SELECT
    Location,
    COUNT(CUSTOMER_KEY) AS ReferredCustomersCount
FROM dbo.customers
WHERE Referred_Other_customers = '1'
GROUP BY Location
ORDER BY ReferredCustomersCount DESC
--Q22 end

--What is order_total value of male customers who are belongs to Chennai and Happy customers
SELECT
    SUM(o.ORDER_TOTAL) AS TotalOrderValue
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE c.Gender = 'M'
  AND c.Location = 'Chennai'
  AND c.Referred_Other_customers = '1'
 --Q23 end

SELECT Top 1
    FORMAT(o.ORDER_DATE, 'yyyy-MM') AS OrderMonth,
    SUM(o.ORDER_TOTAL) AS TotalOrderValue
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE c.Gender = 'M'
  AND c.Location = 'Chennai'
GROUP BY FORMAT(o.ORDER_DATE, 'yyyy-MM')
ORDER BY TotalOrderValue DESC
--Q24 end

--Prepare 5 analysis on your own
--1st analysis Monthly orders
SELECT
    FORMAT(o.ORDER_DATE, 'yyyy-MM') AS OrderMonth,
    COUNT(o.ORDER_NUMBER) AS TotalOrders
FROM dbo.ordersdata o
GROUP BY FORMAT(o.ORDER_DATE, 'yyyy-MM')
ORDER BY OrderMonth
--2nd analysis Top 3 locations by total revenue
SELECT TOP 3
    c.Location,
    SUM(o.ORDER_TOTAL) AS TotalRevenue
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY c.Location
ORDER BY TotalRevenue DESC

--3rd analysis Repeat customers count

WITH CustomerOrderCounts AS (
    SELECT
        o.CUSTOMER_KEY,
        COUNT(o.ORDER_NUMBER) AS OrderCount
    FROM dbo.ordersdata o
    GROUP BY o.CUSTOMER_KEY
)
SELECT
    COUNT(*) AS RepeatCustomers
FROM CustomerOrderCounts
WHERE OrderCount > 1

--4th analysis AoV per customer
SELECT
    c.CUSTOMER_KEY,
    AVG(o.ORDER_TOTAL) AS 'AverageOrderValue'
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY c.CUSTOMER_KEY
ORDER BY AverageOrderValue DESC

--5th analysis AoV with discount and without discount

SELECT
    CASE 
        WHEN DISCOUNT > 0 THEN 'With Discount'
        ELSE 'No Discount'
    END AS DiscountStatus,
    AVG(ORDER_TOTAL) AS AverageOrderValue
FROM dbo.ordersdata
GROUP BY
    CASE 
        WHEN DISCOUNT > 0 THEN 'With Discount'
        ELSE 'No Discount'
    END

--Q26 and Q39 end

--What are number of discounted orders ordered by female customers who were acquired by website from Bangalore delivered on time
SELECT
    COUNT(o.ORDER_NUMBER) AS DiscountedOrdersCount
FROM dbo.ordersdata o
JOIN dbo.customers c
ON o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE c.Gender = 'F'
  AND c.Acquired_Channel = 'WEBSITE'
  AND c.Location = 'Bangalore'
  AND o.DISCOUNT > 0
  AND o.DELIVERY_STATUS = 'ON-TIME'
--Q25 end

--Number of orders by month based on order status (Delivered vs. canceled vs. etc.) - Split of order status by month
SELECT
    FORMAT(ORDER_DATE, 'yyyy-MM') AS OrderMonth,
    ORDER_STATUS,
    COUNT(ORDER_NUMBER) AS OrderCount
FROM dbo.ordersdata
GROUP BY FORMAT(ORDER_DATE, 'yyyy-MM'), ORDER_STATUS
ORDER BY OrderMonth, ORDER_STATUS
--Q26 end
--Number of orders by month based on delivery status
SELECT
    FORMAT(ORDER_DATE, 'yyyy-MM') AS OrderMonth,
    DELIVERY_STATUS,
    COUNT(ORDER_NUMBER) AS OrderCount
FROM dbo.ordersdata
GROUP BY FORMAT(ORDER_DATE, 'yyyy-MM'), DELIVERY_STATUS
ORDER BY OrderMonth, DELIVERY_STATUS
--Q27 end

-- Month-on-month growth in OrderCount and Revenue (from Nov’15 to July’16)
WITH MonthlyData AS (
    SELECT
        FORMAT(ORDER_DATE, 'yyyy-MM') AS OrderMonth,
        COUNT(ORDER_NUMBER) AS OrderCount,
        SUM(ORDER_TOTAL) AS TotalRevenue
    FROM dbo.ordersdata
    WHERE ORDER_DATE >= '2015-11-01' AND ORDER_DATE < '2016-08-01'
    GROUP BY FORMAT(ORDER_DATE, 'yyyy-MM')
),
MonthlyGrowth AS (
    SELECT
        OrderMonth,
        OrderCount,
        TotalRevenue,
        LAG(OrderCount) OVER (ORDER BY OrderMonth) AS PrevOrderCount,
        LAG(TotalRevenue) OVER (ORDER BY OrderMonth) AS PrevRevenue
    FROM MonthlyData
)
SELECT
    OrderMonth,
    OrderCount,
    TotalRevenue,
    CASE
        WHEN PrevOrderCount IS NULL THEN NULL
        ELSE (OrderCount - PrevOrderCount) * 100.0 / PrevOrderCount
    END AS OrderCountGrowthPercentage,
    CASE
        WHEN PrevRevenue IS NULL THEN NULL
        ELSE (TotalRevenue - PrevRevenue) * 100.0 / PrevRevenue
    END AS RevenueGrowthPercentage
FROM MonthlyGrowth
ORDER BY OrderMonth
--Q28 end

--Total Revenue, total orders by each location
SELECT
    c.Location,
    COUNT(o.ORDER_NUMBER) AS TotalOrders,
    SUM(o.ORDER_TOTAL) AS TotalRevenue
FROM
    dbo.ordersdata o
JOIN
    dbo.customers c
ON
    o.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY
    c.Location
ORDER BY
    TotalRevenue DESC
-- Q33 end

--Total revenue, total orders by customer gender
SELECT
    c.Gender,
    COUNT(o.ORDER_NUMBER) AS TotalOrders,
    SUM(o.ORDER_TOTAL) AS TotalRevenue
FROM
    dbo.ordersdata o
JOIN
    dbo.customers c
ON
    o.CUSTOMER_KEY = c.CUSTOMER_KEY
GROUP BY
    c.Gender
ORDER BY
    TotalRevenue DESC
--Q34 end

--Which location of customers cancelling orders maximum
SELECT Top 1
    c.Location,
    COUNT(o.ORDER_NUMBER) AS CanceledOrders
FROM
    dbo.ordersdata o
INNER JOIN
    dbo.customers c
ON
    o.CUSTOMER_KEY = c.CUSTOMER_KEY
WHERE
    o.ORDER_STATUS = 'Cancelled'
GROUP BY
    c.Location
ORDER BY
    CanceledOrders DESC
--Q35 end

--Total customers, Revenue, Orders by each Acquisition channel
WITH ChannelData AS (
    SELECT
        c.Acquired_Channel,
        COUNT(DISTINCT c.CUSTOMER_KEY) AS TotalCustomers,
        COUNT(o.ORDER_NUMBER) AS TotalOrders,
        SUM(o.ORDER_TOTAL) AS TotalRevenue
    FROM
        dbo.customers c
    LEFT JOIN
        dbo.ordersdata o
    ON
        c.CUSTOMER_KEY = o.CUSTOMER_KEY
    GROUP BY
        c.Acquired_Channel
)
SELECT
    Acquired_Channel,
    TotalCustomers,
    TotalOrders,
    TotalRevenue
FROM
    ChannelData
ORDER BY
    TotalRevenue DESC
--Q36 end

-- Which acquisition channel is good in terms of revenue generation, maximum orders, repeat purchasers
WITH CustomerOrders AS (
    SELECT
        c.Acquired_Channel,
        c.CUSTOMER_KEY,
        COUNT(o.ORDER_NUMBER) AS OrderCount,
        SUM(o.ORDER_TOTAL) AS TotalRevenue
    FROM
        dbo.customers c
    LEFT JOIN
        dbo.ordersdata o
    ON
        c.CUSTOMER_KEY = o.CUSTOMER_KEY
    GROUP BY
        c.Acquired_Channel, c.CUSTOMER_KEY
),
ChannelMetrics AS (
    SELECT
        Acquired_Channel,
        COUNT(CUSTOMER_KEY) AS TotalCustomers,
        SUM(OrderCount) AS TotalOrders,
        SUM(TotalRevenue) AS TotalRevenue,
        COUNT(CASE WHEN OrderCount > 1 THEN CUSTOMER_KEY END) AS RepeatPurchasers
    FROM
        CustomerOrders
    GROUP BY
        Acquired_Channel
)
SELECT
    Acquired_Channel,
    TotalRevenue,
    TotalOrders,
    RepeatPurchasers
FROM
    ChannelMetrics
ORDER BY
    TotalRevenue DESC, 
	TotalOrders DESC, 
	RepeatPurchasers DESC

--Q37 end

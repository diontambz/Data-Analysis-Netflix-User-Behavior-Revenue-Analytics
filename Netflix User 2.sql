-- 1. Revenue Analysis by Country and Subscription Type
WITH RevenueAnalysis AS (
    SELECT 
        Country,
        [Subscription Type] as Subscription_Type,
        COUNT(*) as Total_Subscribers,
        ROUND(SUM([Monthly Revenue]), 2) as Total_Revenue,
        ROUND(AVG([Monthly Revenue]), 2) as Avg_Revenue_Per_User,
        CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY Country) as DECIMAL(10,1)) as Subscription_Share_Percentage
    FROM [Netflix User]..Netflix_User
    GROUP BY Country, [Subscription Type]
)
SELECT 
    *,
    RANK() OVER(PARTITION BY Country ORDER BY Total_Revenue DESC) as Revenue_Rank
FROM RevenueAnalysis
ORDER BY Total_Revenue DESC;

-- 2. User Acquisition Analysis by Month
WITH UserAcquisition AS (
    SELECT 
        FORMAT(CONVERT(datetime, [Join Date], 105), 'yyyy-MM') as Join_Month,
        COUNT(*) as New_Users,
        ROUND(SUM([Monthly Revenue]), 2) as New_Revenue,
        CAST(AVG([Monthly Revenue]) as DECIMAL(10,1)) as Avg_Revenue_New_Users
    FROM [Netflix User]..Netflix_User
    GROUP BY FORMAT(CONVERT(datetime, [Join Date], 105), 'yyyy-MM')
),
CumulativeCalc AS (
    SELECT 
        Join_Month,
        New_Users,
        New_Revenue,
        Avg_Revenue_New_Users,
        SUM(New_Users) OVER(ORDER BY Join_Month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Cumulative_Users
    FROM UserAcquisition
),
GrowthCalc AS (
    SELECT 
        Join_Month,
        New_Users,
        New_Revenue,
        Avg_Revenue_New_Users,
        Cumulative_Users,
        LAG(Cumulative_Users, 1) OVER(ORDER BY Join_Month) as Previous_Month_Cumulative
    FROM CumulativeCalc
)
SELECT 
    Join_Month,
    New_Users,
    New_Revenue,
    Avg_Revenue_New_Users,
    Cumulative_Users,
    Previous_Month_Cumulative,
    CAST(CASE 
        WHEN Previous_Month_Cumulative = 0 OR Previous_Month_Cumulative IS NULL THEN NULL
        ELSE ((Cumulative_Users - Previous_Month_Cumulative) / Previous_Month_Cumulative) * 100 
    END as DECIMAL(10,1)) as Growth_Rate
FROM GrowthCalc
ORDER BY Join_Month;

-- 3. Device Usage Analysis
SELECT 
    Device,
    COUNT(*) as Total_Users,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM [Netflix User]..Netflix_User) as DECIMAL(10,1)) as Usage_Percentage,
    ROUND(AVG([Monthly Revenue]), 2) as Avg_Revenue_Per_Device,
    COUNT(CASE WHEN [Subscription Type] = 'Premium' THEN 1 END) as Premium_Users,
    COUNT(CASE WHEN [Subscription Type] = 'Standard' THEN 1 END) as Standard_Users,
    COUNT(CASE WHEN [Subscription Type] = 'Basic' THEN 1 END) as Basic_Users
FROM [Netflix User]..Netflix_User
GROUP BY Device
ORDER BY Total_Users DESC;

-- 4. Age Demographics
WITH AgeBrackets AS (
    SELECT 
        CASE 
            WHEN Age < 25 THEN '18-24'
            WHEN Age BETWEEN 25 AND 34 THEN '25-34'
            WHEN Age BETWEEN 35 AND 44 THEN '35-44'
            WHEN Age BETWEEN 45 AND 54 THEN '45-54'
            ELSE '55+'
        END as Age_Group,
        *
    FROM [Netflix User]..Netflix_User
)
SELECT 
    Age_Group,
    COUNT(*) as Total_Users,
    ROUND(AVG([Monthly Revenue]), 2) as Avg_Revenue,
    ROUND(SUM([Monthly Revenue]), 2) as Total_Revenue,
    CAST(COUNT(CASE WHEN [Subscription Type] = 'Premium' THEN 1 END) * 100.0 / COUNT(*) as DECIMAL(10,1)) as Premium_Percentage
FROM AgeBrackets
GROUP BY Age_Group
ORDER BY Age_Group;

-- 5. Customer Lifetime Analysis Based on Country
SELECT 
    u.Country,
    u.[Subscription Type] as Subscription_Type,
    ROUND(AVG(DATEDIFF(day, CONVERT(datetime, u.[Join Date], 105), 
        CONVERT(datetime, u.[Last Payment Date], 105))), 0) as Avg_Customer_Lifetime_Days,
    COUNT(*) as Total_Users,
    ROUND(SUM([Monthly Revenue]), 2) as Total_Revenue,
    ROUND(SUM([Monthly Revenue]) / COUNT(*), 2) as Revenue_Per_User
FROM [Netflix User]..Netflix_User u
GROUP BY u.Country, u.[Subscription Type]
ORDER BY u.Country, Avg_Customer_Lifetime_Days DESC;

-- 6. Gender Distribution Analysis
SELECT 
    Gender,
    [Subscription Type] as Subscription_Type,
    COUNT(*) as User_Count,
    ROUND(AVG(Age), 1) as Avg_Age,
    ROUND(AVG([Monthly Revenue]), 2) as Avg_Revenue
FROM [Netflix User]..Netflix_User
GROUP BY Gender, [Subscription Type]
ORDER BY Gender, User_Count DESC;
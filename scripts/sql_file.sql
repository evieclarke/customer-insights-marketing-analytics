--OBJECTIVE 1
--What: identify the total spend and number of purchases at 2Market by age, marital status and country
--Why: to establish high-revenue customer demographics

--goal: total spend by age
--insight: top spending demographic is 50-55
SELECT
	"Age",
	SUM("TotalSales")
FROM marketing_data_wide
GROUP BY "Age"
ORDER BY SUM("TotalSales") DESC;

--goal: total spend by marital_status
--insight: top spending demographic is Married.
SELECT
	"Marital_Status",
	SUM("TotalSales")
FROM marketing_data_wide
GROUP BY "Marital_Status"
ORDER BY SUM("TotalSales") DESC;

--goal: total spend by country
--insight: top spending demographic is Spain.
SELECT
	"Country",
	SUM("TotalSales")
FROM marketing_data_wide
GROUP BY "Country"
ORDER BY SUM("TotalSales") DESC;

--goal: total spend by combined demographic
--insight: high-revenue customer is married, mid-50s in Spain particularly
SELECT
	"Country",
	"Marital_Status",
	ROUND(AVG("Age"),0),
	SUM("TotalSales")
FROM marketing_data_wide
GROUP BY "Country", "Marital_Status"
ORDER BY SUM("TotalSales") DESC;



--OBJECTIVE 2
--What: determine which advertising channels have the most lead conversions by country and average age
--Why: to inform stakeholders on effective advertising channels to utilise in future campaigns

--created a pivoted version of the data to make it long and thin
CREATE TABLE ad_data_thin AS
SELECT 
	w."ID",
	v."AdType",
	v."Successful_Leads"
FROM ad_data_wide w
CROSS JOIN LATERAL (
	VALUES
		('Bulkmail', w."Bulkmail_ad"),
		('Twitter', w."Twitter_ad"),
		('Instagram', w."Instagram_ad"),
		('Facebook', w."Facebook_ad"),
		('Brochure', w."Brochure_ad")
) AS v("AdType", "Successful_Leads");

--goal: highest conversions by ad type
--insight: twitter narrowly has the most conversions, Instagram next, FB least
SELECT
	"AdType",
	SUM("Successful_Leads")
FROM ad_data_thin
GROUP BY "AdType"
HAVING "AdType" IN ('Twitter', 'Instagram', 'Facebook')
ORDER BY SUM("Successful_Leads") DESC;


--goal: highest conversions by country and ad type
--insight: use insta and twitter, facebook in US
WITH Joined_data AS (
	SELECT 	m."Country",
			a."AdType",
			COUNT(a."Successful_Leads") AS "Successful_Leads",
			RANK()OVER(PARTITION BY m."Country" ORDER BY COUNT(a."Successful_Leads") DESC) AS "rank"
FROM ad_data_thin a
INNER JOIN marketing_data_wide m USING ("ID")
GROUP BY a."AdType", a."Successful_Leads", m."Country"
HAVING a."Successful_Leads" = '1'
AND a."AdType" IN ('Twitter', 'Instagram','Facebook')
)
SELECT
	"Country",
	"AdType",
	"Successful_Leads",
	"rank"
FROM Joined_data
WHERE "AdType" IN ('Twitter', 'Instagram','Facebook')
AND "rank" = 1
ORDER BY "Successful_Leads" DESC;


--goal: highest lead conversions by marital_status
--insight: insta and twitter for married people too
WITH Joined_data AS (
	SELECT 	m."Marital_Status",
			a."AdType",
			COUNT(a."Successful_Leads") AS "Successful_Leads",
			RANK()OVER(PARTITION BY m."Marital_Status" ORDER BY COUNT(a."Successful_Leads") DESC) AS "rank"
FROM ad_data_thin a
INNER JOIN marketing_data_wide m USING ("ID")
GROUP BY a."AdType", a."Successful_Leads", m."Marital_Status"
HAVING a."Successful_Leads" = '1'
AND "AdType" IN ('Twitter', 'Instagram','Facebook')
)
SELECT
	"Marital_Status",
	"AdType",
	"Successful_Leads",
	"rank"
FROM Joined_data
WHERE "AdType" IN ('Twitter', 'Instagram','Facebook')
AND "rank" = 1
ORDER BY "Successful_Leads" DESC;



--goal: highest lead conversions by country and average age
--insight: most effective is insta until late 50s then twitter
WITH Joined_data AS (
	SELECT  m."Country",
			a."AdType",
			ROUND(AVG(m."Age"),0) AS average_age,
			COUNT(a."Successful_Leads") AS "Successful_Leads",
			RANK()OVER(PARTITION BY m."Country" ORDER BY COUNT(a."Successful_Leads") DESC) AS "rank"
FROM ad_data_thin a
INNER JOIN marketing_data_wide m USING ("ID")
GROUP BY a."AdType", a."Successful_Leads", m."Country"
HAVING a."Successful_Leads" = '1'
AND "AdType" IN ('Twitter', 'Instagram','Facebook')
)
SELECT
	"Country",
	"AdType",
	"average_age",
	"Successful_Leads",
	"rank"
FROM Joined_data
WHERE "rank" = 1
ORDER BY "AdType" DESC;
 

--OBJECTIVE 3
--What: determine top 2 most popular products by country and their share of total sales 
--Why: to establish regional preferences and assess over-reliance on a product
CREATE TABLE marketing_data_thin AS
SELECT 
	w."ID",
	w."Age",
	w."Education",
	w."Marital_Status",
	w."Country",
	v."Product",
	v."Sales"
FROM marketing_data_wide w
CROSS JOIN LATERAL (
	VALUES
		('alcoholic_beverages', w."alcoholic_beverages"),
		('vegetables', w."vegetables"),
		('meat', w."meat"),
		('fish', w."fish"),
		('chocolates', w."chocolates"),
		('commodities', w."commodities")
) AS v("Product", "Sales");


--goal: most high-revenue product by country
--insight: alcohol in all cases
SELECT DISTINCT ON ("Country")
	"Country", 
	"Product", 
	SUM("Sales") AS total_sales
FROM marketing_data_thin
GROUP BY "Country", "Product"
ORDER BY "Country", total_sales DESC;


--goal: alcohol share of sales by country
--insight: alcohol is ~50% of revenue in all countries
SELECT 
	"Country", 
	"Product", 
	SUM("Sales") AS total_sales,
	ROUND(100 * SUM("Sales") :: numeric / SUM(SUM("Sales")) OVER (PARTITION BY "Country"),0) AS share_sales
FROM marketing_data_thin
GROUP BY "Country", "Product"
ORDER BY "Country", share_sales DESC;


--goal: full list of the spend on products by target demographic
--insight: alcohol still comes out top in this view
SELECT
	"Country", 
	"Marital_Status",
	ROUND(AVG("Age"),0),
	"Product", 
	SUM("Sales") AS total_sales
FROM marketing_data_thin
GROUP BY "Country", "Product", "Marital_Status"
HAVING "Marital_Status" = 'Married'
ORDER BY "Country", total_sales DESC;
--- a) Display a list of all property names and their property ids for Owner Id: 1426. 

SELECT p.Name AS 'Property Name', p.Id AS 'Property Id'
FROM [dbo].[Property] p 
INNER JOIN [dbo].[OwnerProperty] o
ON p.Id = o.PropertyId
WHERE o.OwnerId = 1426
  
--- Display the current home value for each property in question a)

SELECT p.Name AS 'Proeprty Name', h.Value AS 'Property Value'
FROM [dbo].[Property] p 
INNER JOIN [dbo].[OwnerProperty] o
ON p.Id = o.PropertyId
INNER JOIN [dbo].[PropertyHomeValue] h
ON p.Id = h.PropertyId
WHERE o.OwnerId = 1426
AND h.IsActive = 1 -- current home value 

--a.	For each property in question a), return the following:                                                                      -- i. Using rental payment amount, rental payment frequency, tenant start date and tenant end date to write a query that returns the sum of all payments from start date to end date. 
/*Approach - 
-1. Get the properties, rent frequency types for the owner 1426
 2. If Rent Frequency is Weekly, then calculate the no. of weeks during the tenancy tenure , multiplied by the rent 
	If Rent Frequency is Fortnightly, then -
										calculate the no. of weeks during the tenancy tenure. 
										divide no of weeks by 2 as to match fortnightly payment
										multiply by the rent payment
	If Rent Frequency is Monthly, then calculate the no. of months during the tenancy tenure , multiply by the rent
-*/
SELECT p.Name AS 'Property Name' , p.Id AS 'Property Id'
, tp.StartDate AS 'Tenancy Start Date', tp.EndDate AS 'Tenancy End Date'
, trt.Name AS 'Rent Payment Frequency', prp.Amount AS 'Rent Amount'
, CASE
	WHEN trt.Name ='Weekly' THEN (DATEDIFF(ww,tp.StartDate, tp.EndDate) * prp.Amount) -- no. of weekes * weekly payment
	WHEN trt.[Name] ='Fortnightly' THEN ((DATEDIFF(ww,tp.StartDate, tp.EndDate)/2) * prp.Amount)
	ELSE (DATEDIFF(mm,tp.StartDate, tp.EndDate) * prp.Amount)
 END AS 'Total Rent Payment'
FROM Property AS p
INNER JOIN OwnerProperty  op 
ON p.Id=op.PropertyId
INNER JOIN PropertyRentalPayment  prp 
ON p.Id=prp.PropertyId
INNER JOIN TargetRentType trt 
ON prp.FrequencyType=trt.Id
INNER JOIN TenantProperty tp 
ON p.Id=tp.PropertyId
WHERE op.OwnerId=1426

---ii.	Display the yield for all properties from a.
-- Yield = ((Total income from rent - Property expense) / Property Value) *100

SELECT p.Name AS 'Property Name'
, p.Id AS 'Property Id'
, tp.StartDate AS 'Tenancy Start Date'
, tp.EndDate AS 'Tenancy End Date'
, trt.Name AS 'Rent Payment Frequency'
, prp.Amount AS 'Rent Amount'
,((
(CASE
WHEN trt.Name ='Weekly' THEN (DATEDIFF(ww,tp.StartDate, tp.EndDate) * prp.Amount)
WHEN trt.Name ='Fortnightly' THEN ((DATEDIFF(ww,tp.StartDate, tp.EndDate)/2) * prp.Amount)
ELSE (DATEDIFF(mm,tp.StartDate, tp.EndDate) * prp.Amount)
 END
 )- COALESCE(SUM(pe.Amount),0)
 )/phv.Value
)*100 AS Yield

FROM Property AS p
INNER JOIN OwnerProperty  op 
ON p.Id=op.PropertyId
INNER JOIN PropertyRentalPayment prp 
ON p.Id=prp.PropertyId
INNER JOIN TargetRentType trt 
ON prp.FrequencyType=trt.Id
INNER JOIN TenantProperty  tp 
ON p.Id=tp.PropertyId
INNER JOIN PropertyHomeValue  phv 
ON p.Id=phv.PropertyId
LEFT JOIN PropertyExpense  pe 
ON p.Id=pe.PropertyId
WHERE  phv.IsActive=1
AND op.OwnerId=1426 
GROUP BY p.Name,p.Id,trt.Name,prp.Amount,tp.StartDate,tp.EndDate, phv.Value

--- Display all the jobs available
--- Available jobs .. treating all jobs which are NOT (Finished, Cancelled , Deleted )

	SELECT p.Name AS 'Property Name' , p.Description AS 'Property Description',  
	CONCAT(a.Number, ' ' , a.Street, ' ', a.Suburb, ' ', a.City, ' ' , a.Region,' ' , a.PostCode) AS 'Address',
	CONCAT(person.FirstName, ' ', person.LastName) AS 'Property Owner', 
	ISNULL(person.MobilePhone,'') AS 'Contact Number (M)',
	ISNULL(js.Status,'') AS 'Job Status' ,
	j.JobDescription AS 'Job Description' , 
	j.CreatedOn AS 'Job Creation Date',
	j.JobStartDate AS 'Job Start Date',
	j.PaymentAmount AS 'Payment Amount', 
	ISNULL(j.Note,'') AS 'Note'
	FROM Job j 
	INNER JOIN [dbo].[Property] p
	ON j.PropertyId = p.Id
	INNER JOIN [dbo].[OwnerProperty] o
	ON p.Id = o.PropertyId	
	AND j.PropertyId = o.PropertyId
	INNER JOIN [dbo].[Person] person
	ON person.Id = o.OwnerId 
	AND j.OwnerId = o.OwnerId
	INNER JOIN [dbo].[Address] a
	ON a.AddressId = p.AddressId
	INNER JOIN [dbo].[JobStatus] js
	ON js.Id = j.JobStatusId
	WHERE  o.OwnerId=1426
	AND js.Id NOT IN (4,5,6)

--- Display all property names, current tenants first and last names and rental payments per week/ fortnight/month for the properties in question a). 

SELECT  p.Name AS 'Property Name',
p.Description AS 'Property Description', 
CONCAT(person.FirstName,' ' ,person.LastName) AS 'Tenant Name', 
CONCAT(a.Number, ' ' , a.Street, ' ', a.Suburb, ' ', a.City, ' ' , a.Region,' ' , a.PostCode) AS 'Address',
tf.Name AS 'Rent Payment Frequency',
tp.PaymentAmount AS 'Rent',
CASE WHEN tp.IsActive=0 THEN 'No'
     WHEN tp.IsActive=1 THEN 'Yes'
	 END AS 'Is Tenant Occupied?'
FROM [dbo].[Property] p
INNER JOIN [dbo].[OwnerProperty] o
ON p.Id = o.PropertyId
INNER JOIN [dbo].[Address] a
ON a.AddressId = p.AddressId
INNER JOIN [dbo].[TenantProperty] tp
ON tp.PropertyId = p.Id
INNER JOIN [dbo].[Person] person
ON person.Id = tp.TenantId
INNER JOIN [dbo].[TenantPaymentFrequencies] tf
ON tf.Id = tp.PaymentFrequencyId
WHERE o.OwnerId = 1426


-- Task2 (Report) query

SELECT p.Name, CONCAT(person.FirstName, ' ', person.LastName) As Owner, 
p.Bedroom, p.Bathroom, CONCAT(a.Number, ' ', a.Street, ' ',  a.City, ' ', a.PostCode) as Address,
prp.Amount,
CASE tf.Id
When 1 Then 'per week'
When 2 Then 'per fortnightly'
When 3 Then 'per month'
END AS PaymentFrequency,
pe.Description AS ExpenseDescription, pe.Date
FROM [dbo].[Property] p
INNER JOIN [dbo].[Address] a
ON p.AddressId = a.AddressId
INNER JOIN [dbo].[OwnerProperty] o
ON p.Id = o.PropertyId
INNER JOIN [dbo].[Person] person
ON o.OwnerId = person.Id
INNER JOIN [dbo].[PropertyRentalPayment] prp
ON p.Id = prp.PropertyId
INNER JOIN [dbo].[TenantPaymentFrequencies] tf
ON prp.FrequencyType = tf.Id
INNER JOIN [dbo].[PropertyExpense] pe
ON prp.PropertyId = pe.PropertyId
WHERE 
o.OwnerId=1426
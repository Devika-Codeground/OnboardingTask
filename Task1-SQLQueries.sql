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
-1. First get the rented properties by the owner
-2. It was notied that the payment frequencies are (or can be) different for same property, e.g propertyId 5638 
-3. TenantProperty seems to have the latest frquency type for the payment. So, PropertyRentalPayment and TenantProperty will not exactly match on frequency id
-4. As the excercise specifies using the Payment Frequency, perform right join to take care of missed records with previous frequency
-*/
WITH cte_RentalPropertiesByOwner AS
   (
   SELECT p.Id, p.Name,TenantId, StartDate AS 'Tenancy Start Date', EndDate AS 'Tenancy End Date', tp.[PaymentFrequencyId] AS 'Payment Frequency'
   FROM [dbo].[TenantProperty] tp 
   INNER JOIN [dbo].[Property] p
   ON tp.PropertyId = p.Id
	   INNER JOIN [dbo].[OwnerProperty] o
   ON p.Id = o.PropertyId
   WHERE o.OwnerId = 1426   )

   SELECT  cte_rp.Name,cte_rp.[Tenancy Start Date], cte_rp.[Tenancy End Date],
   tpf.Name As 'Rent Payment Frequency', SUM(Amount) AS 'Total Payment'
   FROM [dbo].[PropertyRentalPayment] rp
   INNER JOIN cte_RentalPropertiesByOwner cte_rp
   ON rp.PropertyId = cte_rp.Id
   RIGHT OUTER JOIN cte_RentalPropertiesByOwner cte_rp1
   ON rp.FrequencyType = cte_rp1.[Payment Frequency]
   INNER JOIN [dbo].[TenantPaymentFrequencies] tpf
   ON tpf.Id = rp.FrequencyType
   AND tpf.Id = cte_rp1.[Payment Frequency]
   WHERE   
   Date BETWEEN cte_rp1.[Tenancy Start Date] AND cte_rp1.[Tenancy End Date]
   GROUP BY cte_rp.Name, cte_rp.[Tenancy Start Date], cte_rp.[Tenancy End Date],  rp.FrequencyType, tpf.Name

---ii.	Display the yield for all properties from a.
-- Observation - PropertyId 5638 has Frequency types Weekly  in [PropertyFinance] but Weekly and Monthly in [PropertyRentalPayment]....
SELECT q.[Property Name], q.[Property Description], q.Address,q.[Property Owner],q.[Rent Payment Frequency],
SUM(q.yield) AS 'Total Yield'
FROM (
   SELECT p.Name AS 'Property Name', 
p.Description AS 'Property Description', 
CONCAT(a.Number, ' ' , a.Street, ' ', a.Suburb, ' ', a.City, ' ' , a.Region,' ' , a.PostCode) AS 'Address', 
CONCAT(person.FirstName,' ' ,person.LastName) AS 'Property Owner', 
tf.Name AS 'Rent Payment Frequency',
pf.yield 
FROM [dbo].[PropertyFinance] pf
INNER JOIN [dbo].[Property] p
ON pf.PropertyId = p.Id
INNER JOIN [dbo].[OwnerProperty] o
ON o.PropertyId = p.Id
AND o.PropertyId = pf.PropertyId
INNER JOIN [dbo].[Person] person
ON person.Id = o.OwnerId
INNER JOIN [dbo].[Address] a
ON a.AddressId = p.AddressId
INNER JOIN [dbo].[PropertyRentalPayment] rp
ON rp.PropertyId = p.Id
AND rp.PropertyId = o.PropertyId
INNER JOIN [dbo].[TenantPaymentFrequencies] tf
ON tf.Id = rp.FrequencyType
WHERE o.OwnerId = 1426
    ) q
GROUP BY q.[Property Name], q.[Property Description], q.Address,q.[Property Owner], q.[Rent Payment Frequency]

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
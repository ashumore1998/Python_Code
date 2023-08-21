/*
Problem Statement 1: 
“HealthDirect” pharmacy finds it difficult to deal with the product type of medicine being displayed in numerical form, they want the product type in words. Also, they want to filter the medicines based on tax criteria. 
Display only the medicines of product categories 1, 2, and 3 for medicines that come under tax category I and medicines of product categories 4, 5, and 6 for medicines that come under tax category II.
Write a SQL query to solve this problem.
ProductType numerical form and ProductType in words are given by
1 - Generic, 
2 - Patent, 
3 - Reference, 
4 - Similar, 
5 - New, 
6 - Specific,
7 - Biological, 
8 – Dinamized

3 random rows and the column names of the Medicine table are given for reference.
Medicine (medicineID, companyName, productName, description, substanceName, productType, taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice)


12	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	OXALIPLATINA	100 MG PO LIOFILIZADO FR/AMP X 1000 MG	NC/NI	1	I	N	N	N	2373.63
13	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	SULBACTAM SODICO + AMPICILINA SODICA	1 G + 2 G CT FR AMP VD INC	NC/NI	4	II	N	N	N	29.59
14	LIBRA COMERCIO DE PRODUTOS FARMACEUTICOS LTDA	PACLITAXEL	6 MG/ML SOL INJ CT FR/AMP X 50 ML	NC/NI	1	I	N	N	N	4122.12

*/
WITH tax_I AS 
( 
SELECT 
medicineID, companyName, productName, description, substanceName, CASE 
WHEN productType = 1 THEN 'Generic'
WHEN productType = 2 THEN 'Patent'
WHEN productType = 3 THEN 'Reference'
ELSE NULL
END AS productType, taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice
FROM medicine 
WHERE taxCriteria = 'I' AND productType IN (1, 2, 3)
),
tax_II AS 
( 
    SELECT  medicineID,  companyName,  productName,  description,  substanceName, 
 CASE 
 WHEN productType = 4 THEN 'Similar'
 WHEN productType = 5 THEN 'New'
 WHEN productType = 6 THEN 'Specific'
 ELSE NULL
 END AS productType,taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice
 FROM medicine 
 WHERE taxCriteria = 'II' AND productType IN (4,5,6)
)
(select medicineID, companyName, productName, description, substanceName, productType, taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice
from pharmacy p
join keep k using(pharmacyID)
join tax_I t1 using(medicineID)
where pharmacyName = 'HealthDirect'
UNION
select medicineID, companyName, productName, description, substanceName, productType, taxCriteria, hospitalExclusive, governmentDiscount, taxImunity, maxPrice
from pharmacy p
join keep k using(pharmacyID)
join tax_II t2 using(medicineID)
where pharmacyName = 'HealthDirect' );

/*
Problem Statement 2:  
'Ally Scripts' pharmacy company wants to find out the quantity of medicine prescribed in each of its prescriptions.
Write a query that finds the sum of the quantity of all the medicines in a prescription and if the total quantity of medicine is less than 20 tag it as “low quantity”. If the quantity of medicine is from 20 to 49 (both numbers including) tag it as “medium quantity“ and if the quantity is more than equal to 50 then tag it as “high quantity”.
Show the prescription Id, the Total Quantity of all the medicines in that prescription, and the Quantity tag for all the prescriptions issued by 'Ally Scripts'.
3 rows from the resultant table may be as follows:
prescriptionID	totalQuantity	Tag
1147561399		43			Medium Quantity
1222719376		71			High Quantity
1408276190		48			Medium Quantity
*/

select prescriptionID,sum(quantity) as totalQuantity,
case when sum(quantity)<20 then 'Less Quantity'
	 when sum(quantity)>=20 and sum(quantity)<=49 then 'Medium Quantity'
	 else 'High Quantity'
	 end as Tag
from prescription p 
join contain c using(prescriptionID)
join pharmacy ph using(pharmacyID)
where ph.pharmacyName = 'Ally Scripts' 
group by prescriptionID
;

/*
Problem Statement 3: 
In the Inventory of a pharmacy 'Spot Rx' the quantity of medicine is considered ‘HIGH QUANTITY’ when the quantity exceeds 7500 and ‘LOW QUANTITY’ when the quantity falls short of 1000. The discount is considered “HIGH” if the discount rate on a product is 30% or higher, and the discount is considered “NONE” when the discount rate on a product is 0%.
 'Spot Rx' needs to find all the Low quantity products with high discounts and all the high-quantity products with no discount so they can adjust the discount rate according to the demand. 
Write a query for the pharmacy listing all the necessary details relevant to the given requirement.
Hint: Inventory is reflected in the Keep table.
*/
with tagging AS
(
 select medicineID,productName,
 case when k.quantity>7500 then 'HIGH QUANTITY'
	  when (k.quantity<=7500 and k.quantity>1000) then 'MEDIUM QUANTITY'
	  else 'LOW QUANTITY'
	  end as Tag,
 case when k.discount=0 then 'NONE'
	  when k.discount>0.3 then 'HIGH'
	  when (k.discount<=0.3 and k.discount>0) then 'MEDIUM'
	  end as discount_tag
	from medicine m
	join keep k using(medicineID)
)
(select t.medicineID,t.productName,t.Tag,t.discount_tag
from tagging t
join keep k using(medicineID)
join pharmacy p using(pharmacyID)
where pharmacyName = 'Spot Rx'
and t.Tag = 'LOW QUANTITY'
and t.discount_tag='HIGH'
UNION
select t.medicineID,t.productName,t.Tag,t.discount_tag
from tagging t
join keep k using(medicineID)
join pharmacy p using(pharmacyID)
where pharmacyName = 'Spot Rx'
and t.Tag = 'HIGH QUANTITY'
and t.discount_tag='NONE')
;

/*
Problem Statement 4: 
Mack, From HealthDirect Pharmacy, wants to get a list of all the affordable and costly, hospital-exclusive medicines in the database. Where affordable medicines are the medicines that have a maximum price of less than 50% of the avg maximum price of all the medicines in the database, and costly medicines are the medicines that have a maximum price of more than double the avg maximum price of all the medicines in the database.  Mack wants clear text next to each medicine name to be displayed that identifies the medicine as affordable or costly. The medicines that do not fall under either of the two categories need not be displayed.
Write a SQL query for Mack for this requirement.
*/
with price_comp as (
 select medicineID,productName,
 case when maxPrice<(select avg(maxPrice) as avg_price from medicine)*0.5 then 'affordable'
	  when maxPrice>(select avg(maxPrice) as avg_price from medicine)*2 then 'costly'
	  else 'normal'
	  end as price_tag
	from medicine m
	where m.hospitalExclusive = 'S'
)

select t.medicineID,t.productName,price_tag
from price_comp t
join keep k using(medicineID)
join pharmacy p using(pharmacyID)
where pharmacyName = 'HealthDirect'
and price_tag in ('affordable','costly')
;

/*
Problem Statement 5:  
The healthcare department wants to categorize the patients into the following category.
YoungMale: Born on or after 1st Jan  2005  and gender male.
YoungFemale: Born on or after 1st Jan  2005  and gender female.
AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
ElderMale: Born before 1st Jan 1970, and gender male.
ElderFemale: Born before 1st Jan 1970, and gender female.

Write a SQL query to list all the patient name, gender, dob, and their category.
*/

select pr.personID,pr.personName,pr.gender,p.dob,
	case when (year(p.dob)>2005 and pr.gender='male') then 'YoungMale'
		 when (year(p.dob)>2005 and pr.gender='female') then 'YoungFemale'
		 when (year(p.dob)<2005 and year(p.dob)>=1985 and pr.gender='male') then 'AdultMale'
		 when (year(p.dob)<2005 and year(p.dob)>=1985 and pr.gender='female') then 'AdultFemale'
		 when (year(p.dob)<1985 and year(p.dob)>=1970 and pr.gender='male') then 'MidAgeMale'
		 when (year(p.dob)<1985 and year(p.dob)>=1970 and pr.gender='female') then 'MidAgeFemale'
		 when (year(p.dob)<1970 and pr.gender='male') then 'ElderMale'
		 when (year(p.dob)<1970 and pr.gender='female') then 'ElderFemale'
		 end as age_category
		 
from person pr
join patient p
on pr.personID = p.patientID
;
/* 
Problem Statement 1:  Jimmy, from the healthcare department, has requested a report that shows how the number of treatments each age category of patients has gone through in the year 2022. 
The age category is as follows, Children (00-14 years), Youth (15-24 years), Adults (25-64 years), and Seniors (65 years and over).
Assist Jimmy in generating the report. 
*/
with age_group(age_category,patientID) as 
(
select case when year(t.date)-year(p.dob) < 14 then 'Children'
	when (year(t.date)-year(p.dob) >= 15 and year(t.date)-year(p.dob) <= 24) then 'Youth'
    when (year(t.date)-year(p.dob) >= 25 and year(t.date)-year(p.dob) <= 64) then 'Adults'
    else 'Seniors'
    end as age_category,p.patientID
    from patient p
    join treatment t
	on p.patientID=t.patientID
)
select ag.age_category,count(t.treatmentID) as count
from patient p
join age_group ag
on p.patientID=ag.patientID
join treatment t
on p.patientID=t.patientID
where t.date between '2022-02-01' and '2022-12-31'
group by age_category
;

/* 
Problem Statement 2:  Jimmy, from the healthcare department, wants to know which disease is infecting people of which gender more often.
Assist Jimmy with this purpose by generating a report that shows for each disease the male-to-female ratio. Sort the data in a way that is helpful for Jimmy.
*/

with 
male_data(diseaseName,gender) as 
(
select d.diseaseName,count(pr.gender) from disease d join treatment t on d.diseaseID=t.diseaseID 
join patient p on p.patientID=t.patientID join person pr on p.patientID = pr.personID where pr.gender='male' GROUP by d.diseaseName
),
female_data(diseaseName,gender) as 
(
select d.diseaseName,count(pr.gender) from disease d join treatment t on d.diseaseID=t.diseaseID 
join patient p on p.patientID=t.patientID join person pr on p.patientID = pr.personID where pr.gender='female' GROUP by d.diseaseName
)

select d.diseaseName,m.gender as male_count,f.gender as female_count,(m.gender/f.gender) as ratio
from disease d
join male_data m
on m.diseaseName = d.diseaseName
join female_data f
on f.diseaseName = d.diseaseName
group by d.diseaseName
;

/*
Problem Statement 3: Jacob, from insurance management, has noticed that insurance claims are not made for all the treatments. He also wants to figure out if the gender of the patient has any impact on the insurance claim. Assist Jacob in this situation by generating a report that finds for each gender the number of treatments, number of claims, and treatment-to-claim ratio. And notice if there is a significant difference between the treatment-to-claim ratio of male and female patients.
*/

select pr.gender,count(distinct treatmentID) as treatment_count,count(distinct c.claimID) as claim_count,(count(distinct treatmentID)/count(distinct c.claimID)) as ratio
from treatment t 
join claim c 
on t.claimID = c.claimID
join person pr 
on t.patientID = pr.personID 
GROUP by pr.gender;

/*
| gender | treatment_count | claim_count | ratio  |
+--------+-----------------+-------------+--------+
| female |            4206 |        2676 | 1.5717 |
| male   |            6679 |        4287 | 1.5580
*/

/*
Problem Statement 4: The Healthcare department wants a report about the inventory of pharmacies. Generate a report on their behalf that shows how many units of medicine each pharmacy has in their inventory, the total maximum retail price of those medicines, and the total price of all the medicines after discount. 
Note: discount field in keep signifies the percentage of discount on the maximum price.
*/

-- Considering for each medicine approach
SELECT p.pharmacyName,m.productName,k.quantity,m.maxPrice,((m.maxPrice*k.discount)/100) as discount_amount,((m.maxPrice) - ((m.maxPrice*k.discount)/100)) as price_after_discount
from pharmacy p
join keep k
on p.pharmacyID = k.pharmacyID
join medicine m 
on k.medicineID = m.medicineID
;

-- Considering all total availability
SELECT
    p.pharmacyID,
    p.pharmacyName,
    SUM(k.quantity) AS total_units,
    SUM(m.maxPrice) AS total_mrp,
    SUM(m.maxPrice * (1 - k.discount / 100)) AS total_price_after_discount
FROM
    pharmacy p
join keep k
on p.pharmacyID = k.pharmacyID
join medicine m 
on k.medicineID = m.medicineID
GROUP by  p.pharmacyID,p.pharmacyName 
;

/*
Problem Statement 5:  The healthcare department suspects that some pharmacies prescribe more medicines than others in a single prescription, for them, generate a report that finds for each pharmacy the maximum, minimum and average number of medicines prescribed in their prescriptions. 
*/

with con_qty(pharmacyID,prescriptionID,contain_qty) as 
	(
	select p.pharmacyID,p.prescriptionID,sum(c.Quantity) as contain_qty
	from prescription p 
	join contain c 
	on c.prescriptionID=p.prescriptionID
	group by p.pharmacyID,p.prescriptionID
	)
	
select pharmacyID,max(contain_qty) as maximum_prescription,min(contain_qty)as minimum_prescription,round(avg(contain_qty),2) as average_prescription from con_qty
group by pharmacyID;

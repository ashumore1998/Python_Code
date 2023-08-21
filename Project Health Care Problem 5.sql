/*
Problem Statement 1: 
Johansson is trying to prepare a report on patients who have gone through treatments more than once. Help Johansson prepare a report that shows the patient's name, the number of treatments they have undergone, and their age, Sort the data in a way that the patients who have undergone more treatments appear on top.

*/

select personName,(year(t.date)-year(pt.dob)) as age ,count(treatmentID) as treatment_count
from person p 
join patient pt 
on p.personID = pt.patientID
join treatment t using(patientID)
group by personName,age
having treatment_count>1
;

/*
Problem Statement 2:  
Bharat is researching the impact of gender on different diseases, He wants to analyze if a certain disease is more likely to infect a certain gender or not.
Help Bharat analyze this by creating a report showing for every disease how many males and females underwent treatment for each in the year 2021. It would also be helpful for Bharat if the male-to-female ratio is also shown.
*/
with male_detail as 
(
select d.diseaseName,count(t.treatmentID) as male_count
from disease d
join treatment t USING(diseaseID)
join patient p using(patientID)
join person pr 
on p.patientID = pr.personID
where year(date)=2021
and pr.gender = 'male'
group by d.diseaseName
),
female_detail as 
(
select d.diseaseName,count(t.treatmentID) as female_count
from disease d
join treatment t USING(diseaseID)
join patient p using(patientID)
join person pr 
on p.patientID = pr.personID
where year(date)=2021
and pr.gender = 'female'
group by d.diseaseName
)

select d.diseaseName,male_count,female_count,(male_count/female_count) as male_to_female_ratio
from disease d
join male_detail m using(diseaseName)
join female_detail f using(diseaseName)
;

/*
Problem Statement 3:  
Kelly, from the Fortis Hospital management, has requested a report that shows for each disease, the top 3 cities that had the most number treatment for that disease.
Generate a report for Kelly’s requirement.
*/

WITH disease_rnk AS (
    SELECT
        diseaseName,
        city,
        treatment_count,
        DENSE_RANK() OVER (PARTITION BY diseaseName ORDER BY treatment_count DESC) AS city_rank
    FROM (
        SELECT
            diseaseName,
            city,
            COUNT(*) AS treatment_count
        from disease d
			join treatment t USING(diseaseID)
			join patient p using(patientID)
			join person pr 
			on p.patientID = pr.personID
			join address a using(addressID)
        GROUP BY diseaseName, city
    ) AS grouped_treatments
)
SELECT diseaseName,city,treatment_count
FROM disease_rnk
WHERE city_rank <= 3
ORDER BY diseaseName, city_rank;

/*
Problem Statement 4: 
Brooke is trying to figure out if patients with a particular disease are preferring some pharmacies over others or not, For this purpose, she has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for each disease in 2021 and 2022, She expects the number of prescriptions prescribed in 2021 and 2022 be displayed in two separate columns.
Write a query for Brooke’s requirement.
*/
with 2021_details as 
(
select pharmacyName,diseaseName,count(pr.prescriptionID) as 2021_prescription_count
from disease d 
join treatment t using(diseaseID)
join prescription pr using(treatmentID)
join pharmacy ph using(pharmacyID)
where year(t.date)=2021
group by pharmacyName,diseaseName
)
,
2022_details as 
(
select pharmacyName,diseaseName,count(pr.prescriptionID) as 2022_prescription_count
from disease d 
join treatment t using(diseaseID)
join prescription pr using(treatmentID)
join pharmacy ph using(pharmacyID)
where year(t.date)=2022
group by pharmacyName,diseaseName
)

(select a.diseaseName,a.pharmacyName,2021_prescription_count,2022_prescription_count 
from 2021_details a
left join 2022_details b
on a.pharmacyName = b.pharmacyName
and a.diseaseName=b.diseaseName
UNION
select a.diseaseName,a.pharmacyName,2021_prescription_count,2022_prescription_count 
from 2021_details a
right join 2022_details b
on a.pharmacyName = b.pharmacyName
and a.diseaseName=b.diseaseName)
limit 5;

/*
Problem Statement 5:  
Walde, from Rock tower insurance, has sent a requirement for a report that presents which insurance company is targeting the patients of which state the most. 
Write a query for Walde that fulfills the requirement of Walde.
Note: We can assume that the insurance company is targeting a region more if the patients of that region are claiming more insurance of that company.
*/
with max_cnt as (
select a.state,companyName,count(claimID) as claim_count
,dense_rank() over(partition by a.state order by count(claimID) desc) as rnk
from insuranceCompany ic
join insurancePlan ip using(companyID)
join claim c using(UIN)
join treatment t using(claimID)
join patient p using(patientID)
join person pr 
on pr.personID = p.patientID
join address a 
on a.addressID=pr.addressID
group by a.state,companyName
)
select distinct state,companyName,claim_count
from max_cnt
where rnk=1
group by state,companyName
;


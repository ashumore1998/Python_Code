/*
Problem Statement 1: A company needs to set up 3 new pharmacies, they have come up with an idea that the pharmacy can be set up in cities where the pharmacy-to-prescription ratio is the lowest and the number of prescriptions should exceed 100. Assist the company to identify those cities where the pharmacy can be set up.*/

WITH each_city_count AS
(SELECT a.city, COUNT(DISTINCT p.pharmacyid) AS pharmacy_count, COUNT(prescriptionid) AS prescription_count
FROM pharmacy p
JOIN address a USING(addressid)
JOIN prescription pr USING(pharmacyid)
GROUP BY a.city)

SELECT *, (pharmacy_count / prescription_count) AS pharmacy_to_prescription_ratio
FROM each_city_count
WHERE prescription_count > 100
ORDER BY pharmacy_to_prescription_ratio
LIMIT 3;

/* 
Problem Statement 2: The State of Alabama (AL) is trying to manage its healthcare resources more efficiently. For each city in their state, they need to identify the disease for which the maximum number of patients have gone for treatment. Assist the state for this purpose.
Note: The state of Alabama is represented as AL in Address Table.

*/
with patient_count(city,diseaseName,treatment_count,rnk_salary) as (
SELECT a.city,d.diseaseName,count(treatmentID) as treatment_count,dense_RANK() OVER (PARTITION BY a.city ORDER BY count(treatmentID) desc) AS rnk_salary
from treatment t
join disease d 
on t.diseaseID = d.diseaseID
join patient p
on p.patientID = t.patientID
join person pr 
on p.patientID = pr.personID
join Address a 
on pr.addressID = a.addressID
where a.state = 'AL'
group by a.city,d.diseaseName
)

select pc.city,pc.diseaseName,max(pc.treatment_count) as count
from patient_count pc
where pc.rnk_salary = 1
group by pc.city,pc.diseaseName
;

/* 
Problem Statement 3: The healthcare department needs a report about insurance plans. The report is required to include the insurance plan, which was claimed the most and least for each disease.  Assist to create such a report.
*/

with max_plan AS
(
select diseaseName,planName,count(t.claimID) as claim_per_disease,ROW_NUMBER()
 over(PARTITION BY diseaseName order  by count(t.claimID) desc,planName) as most_claim_rank from insuranceplan ip
join claim c 
on ip.UIN=c.UIN
join treatment t 
on t.claimID = c.claimID
join disease d
on t.diseaseID = d.diseaseID
group by d.diseaseName,planName
),
min_plan AS
(
select diseaseName,planName,count(t.claimID) as claim_per_disease,ROW_NUMBER()
 over(PARTITION BY diseaseName order  by count(t.claimID),planName) as least_claim_rank from insuranceplan ip
join claim c 
on ip.UIN=c.UIN
join treatment t 
on t.claimID = c.claimID
join disease d
on t.diseaseID = d.diseaseID
group by d.diseaseName,planName
)

select d.diseaseName,m.planName,mip.planName 
from disease d 
left join max_plan m 
on m.diseaseName = d.diseaseName
left join min_plan mip 
on mip.diseaseName = d.diseaseName
where m.most_claim_rank=1 and mip.least_claim_rank=1
;

/*
Problem Statement 4: The Healthcare department wants to know which disease is most likely to infect multiple people in the same household. For each disease find the number of households that has more than one patient with the same disease. 
Note: 2 people are considered to be in the same household if they have the same address. 
*/


WITH patient_count_add AS 
( SELECT d.diseasename, pr.addressid, COUNT(DISTINCT pr.personid) AS patient_count
FROM disease d
JOIN treatment t USING(diseaseid)
JOIN patient pt USING(patientid)
JOIN person pr ON pt.patientid = pr.personid
GROUP BY d.diseasename, pr.addressid )

SELECT diseasename, COUNT(*) AS address_count
FROM patient_count_add
WHERE patient_count > 1
GROUP BY diseasename;

/*
Problem Statement 5:  An Insurance company wants a state wise report of the treatments to claim ratio between 1st April 2021 and 31st March 2022 (days both included). Assist them to create such a report.
*/

SELECT a.state, COUNT(t.treatmentid) AS treatment_count, COUNT(t.claimid) AS claim_count, 
COUNT(t.treatmentid)/COUNT(t.claimid) AS treatment_to_claim_ratio
FROM address a
JOIN person pr USING(addressid)
JOIN patient pt ON pr.personid = pt.patientid
JOIN treatment t USING(patientid)
WHERE t.date BETWEEN '2021-04-01' AND '2022-03-31'
GROUP BY a.state
ORDER BY treatment_to_claim_ratio;

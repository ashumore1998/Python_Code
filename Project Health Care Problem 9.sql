/*
Problem Statement 1: 
Brian, the healthcare department, has requested for a report that shows for each state how many people underwent treatment for the disease “Autism”.  He expects the report to show the data for each state as well as each gender and for each state and gender combination. 
Prepare a report for Brian for his requirement.

*/

select state,gender,count(treatmentID) as treatment_count
from address a 
left join person p using(addressID)
join patient pt 
on pt.patientID=p.personID
join treatment t using(patientID)
join disease d using(diseaseID)
where diseaseName = 'Autism'
group by state,gender with ROLLUP
;

/*
Problem Statement 2:  
Insurance companies want to evaluate the performance of different insurance plans they offer. 
Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for. The report would be more relevant if the data compares the performance for different years(2020, 2021 and 2022) and if the report also includes the total number of claims in the different years, as well as the total number of claims for each plan in all 3 years combined.
*/

select companyName,planName,Year(t.date) as treatment_year,count(ClaimID) claim_count
from insuranceCompany ic
join InsurancePlan ip using(companyID)
join claim c using(UIN)
join treatment t using(ClaimID)
WHERE Year(t.date) in (2020,2021,2022)
group by companyName,planName,treatment_year WITH ROLLUP
;

/*
Problem Statement 3:  
Sarah, from the healthcare department, is trying to understand if some diseases are spreading in a particular region. Assist Sarah by creating a report which shows each state the number of the most and least treated diseases by the patients of that state in the year 2022. It would be helpful for Sarah if the aggregation for the different combinations is found as well. Assist Sarah to create this report. 
*/

select state,diseaseName,count(treatmentID) as patient_count
from disease d 
join treatment t using(diseaseID)
join patient pt using(patientID)
join person p 
on p.personID = pt.patientID
join address a using(addressID)
where year(t.date) = 2022
group by state,diseaseName with ROLLUP
;

/*
Problem Statement 4: 
Jackson has requested a detailed pharmacy report that shows each pharmacy name, and how many prescriptions they have prescribed for each disease in the year 2022, along with this Jackson also needs to view how many prescriptions were prescribed by each pharmacy, and the total number prescriptions were prescribed for each disease.
Assist Jackson to create this report. 
*/
select pharmacyName,diseaseName,count(prescriptionID) as prescription_count
from disease d 
join treatment t using(diseaseID)
join prescription pr using(treatmentID)
join pharmacy p using(pharmacyID)
WHERE year(t.date) = 2022
group by p.pharmacyID,pharmacyName,d.diseaseID,diseaseName with rollup
;

/*
Problem Statement 5:  
Praveen has requested for a report that finds for every disease how many males and females underwent treatment for each in the year 2022. It would be helpful for Praveen if the aggregation for the different combinations is found as well.
Assist Praveen to create this report. 
*/
select diseaseName,gender,count(treatmentID) as treated_count
from disease d 
join treatment t using(diseaseID)
join patient pt using(patientID)
join person p 
on p.personID = pt.patientID
where year(t.date)=2022
GROUP by diseaseName,gender with rollup
;
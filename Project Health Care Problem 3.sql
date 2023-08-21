/* 
Problem Statement 1:  Some complaints have been lodged by patients that they have been prescribed hospital-exclusive medicine that they can’t find elsewhere and facing problems due to that. Joshua, from the pharmacy management, wants to get a report of which pharmacies have prescribed hospital-exclusive medicines the most in the years 2021 and 2022. Assist Joshua to generate the report so that the pharmacies who prescribe hospital-exclusive medicine more often are advised to avoid such practice if possible.   
*/

select p.pharmacyID,p.pharmacyName,count(p.pharmacyID) as count_of_hospital_exclusive 
from pharmacy p
join keep k
on k.pharmacyID = p.pharmacyID
join medicine m
on k.medicineID = m.medicineID
join prescription pr 
on pr.pharmacyID = p.pharmacyID
join treatment t 
on  pr.treatmentID = t.treatmentID
where hospitalExclusive = 'S'
and YEAR(t.date) In (2022,2021)
group by p.pharmacyID,p.pharmacyName
order by count_of_hospital_exclusive desc
;

/*
Problem Statement 2: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance plan, the company that issues the plan, and the number of treatments the plan was claimed for.
*/

select ip.planName,ic.companyName,count(treatmentID)
from insurancePlan ip
join insuranceCompany ic
on ip.companyID = ic.companyID
join claim c 
on c.UIN=ip.UIN
join treatment t 
on c.claimID = t.claimID
group by ip.planName,ic.companyName
;

/*
Problem Statement 3: Insurance companies want to assess the performance of their insurance plans. Generate a report that shows each insurance company's name with their most and least claimed insurance plans.
*/
with claim_count as
(
select ip.planName,ic.companyName,count(c.UIN) claimed
from insuranceCompany ic
join insurancePlan ip
on ip.companyID = ic.companyID
join claim c 
on c.UIN=ip.UIN
group by ip.planName,ic.companyName
)

select companyName,max(planName) as most_claimed_plan,min(planName) as least_claimed_plan
from claim_count 
group by companyName
;

/*
Problem Statement 4:  The healthcare department wants a state-wise health report to assess which state requires more attention in the healthcare sector. Generate a report for them that shows the state name, number of registered people in the state, number of registered patients in the state, and the people-to-patient ratio. sort the data by people-to-patient ratio. 
*/

select a.state,count(distinct pr.personID) as person_count,count(distinct p.patientID) as patient_count,(count(distinct pr.personID)/count(distinct p.patientID)) as person_to_patient_ratio
from address a 
left join person pr
on a.addressID = pr.addressID
left join patient p 
on p.patientID = pr.personID
group by a.state
order by person_to_patient_ratio
;

/*
Problem Statement 5:  Jhonny, from the finance department of Arizona(AZ), has requested a report that lists the total quantity of medicine each pharmacy in his state has prescribed that falls under Tax criteria I for treatments that took place in 2021. Assist Jhonny in generating the report. 
*/

select a.state,p.pharmacyID,p.pharmacyName,sum(ct.quantity)  as medicine_count
from pharmacy p
join prescription pr using(pharmacyID)
join contain ct using(prescriptionID)
join treatment t using(treatmentID)
join medicine m using(medicineID)
join address a using(addressID)
where taxCriteria = 'I'
and a.state = 'AZ'
and YEAR(t.date)=2021
group by a.state,p.pharmacyID,p.pharmacyName
;

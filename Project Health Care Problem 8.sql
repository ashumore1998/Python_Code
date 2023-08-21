/*
Query 1: 
-- For each age(in years), how many patients have gone for treatment?
SELECT DATEDIFF(hour, dob , GETDATE())/8766 AS age, count(*) AS numTreatments
FROM Person
JOIN Patient ON Patient.patientID = Person.personID
JOIN Treatment ON Treatment.patientID = Patient.patientID
group by DATEDIFF(hour, dob , GETDATE())/8766
order by numTreatments desc;
*/

select TIMESTAMPDIFF(YEAR, dob, CURDATE()) AS age, count(*) As numTreatments
from treatment t 
join patient p using(patientID)
group by age
order by numTreatments desc
;

/*
Query 2: 
-- For each city, Find the number of registered people, number of pharmacies, and number of insurance companies.

drop table if exists T1;
drop table if exists T2;
drop table if exists T3;

select Address.city, count(Pharmacy.pharmacyID) as numPharmacy
into T1
from Pharmacy right join Address on Pharmacy.addressID = Address.addressID
group by city
order by count(Pharmacy.pharmacyID) desc;

select Address.city, count(InsuranceCompany.companyID) as numInsuranceCompany
into T2
from InsuranceCompany right join Address on InsuranceCompany.addressID = Address.addressID
group by city
order by count(InsuranceCompany.companyID) desc;

select Address.city, count(Person.personID) as numRegisteredPeople
into T3
from Person right join Address on Person.addressID = Address.addressID
group by city
order by count(Person.personID) desc;

select T1.city, T3.numRegisteredPeople, T2.numInsuranceCompany, T1.numPharmacy
from T1, T2, T3
where T1.city = T2.city and T2.city = T3.city
order by numRegisteredPeople desc;
*/

WITH PharmacyCount AS (
    SELECT Address.city, COUNT(Pharmacy.pharmacyID) AS numPharmacy
    FROM Pharmacy
    RIGHT JOIN Address ON Pharmacy.addressID = Address.addressID
    GROUP BY city
),
InsuranceCompanyCount AS (
    SELECT Address.city, COUNT(InsuranceCompany.companyID) AS numInsuranceCompany
    FROM InsuranceCompany
    RIGHT JOIN Address ON InsuranceCompany.addressID = Address.addressID
    GROUP BY city
),
RegisteredPeopleCount AS (
    SELECT Address.city, COUNT(Person.personID) AS numRegisteredPeople
    FROM Person
    RIGHT JOIN Address ON Person.addressID = Address.addressID
    GROUP BY city
)
SELECT city,
       COALESCE(SUM(numRegisteredPeople), 0) AS numRegisteredPeople,
       COALESCE(SUM(numInsuranceCompany), 0) AS numInsuranceCompany,
       COALESCE(SUM(numPharmacy), 0) AS numPharmacy
FROM (
    SELECT city, numRegisteredPeople, NULL AS numInsuranceCompany, NULL AS numPharmacy
    FROM RegisteredPeopleCount
    UNION
    SELECT city, NULL AS numRegisteredPeople, numInsuranceCompany, NULL AS numPharmacy
    FROM InsuranceCompanyCount
    UNION
    SELECT city, NULL AS numRegisteredPeople, NULL AS numInsuranceCompany, numPharmacy
    FROM PharmacyCount
) AS combined_counts
GROUP BY city
ORDER BY numRegisteredPeople DESC;


/*
Query 3: 
-- Total quantity of medicine for each prescription prescribed by Ally Scripts
-- If the total quantity of medicine is less than 20 tag it as "Low Quantity".
-- If the total quantity of medicine is from 20 to 49 (both numbers including) tag it as "Medium Quantity".
-- If the quantity is more than equal to 50 then tag it as "High quantity".

select 
C.prescriptionID, sum(quantity) as totalQuantity,
CASE WHEN sum(quantity) < 20 THEN 'Low Quantity'
WHEN sum(quantity) < 50 THEN 'Medium Quantity'
ELSE 'High Quantity' END AS Tag

FROM Contain C
JOIN Prescription P 
on P.prescriptionID = C.prescriptionID
JOIN Pharmacy on Pharmacy.pharmacyID = P.pharmacyID
where Pharmacy.pharmacyName = 'Ally Scripts'
group by C.prescriptionID;
*/
SELECT 
    c.prescriptionID,
    SUM(c.quantity) AS totalQuantity,
    CASE 
        WHEN SUM(C.quantity) < 20 THEN 'Low Quantity'
        WHEN SUM(C.quantity) < 50 THEN 'Medium Quantity'
        ELSE 'High Quantity'
    END AS Tag
FROM Contain c
JOIN Prescription pr using(prescriptionID)
WHERE P.pharmacyID IN (SELECT pharmacyID FROM Pharmacy WHERE pharmacyName = 'Ally Scripts')
GROUP BY c.prescriptionID;

/*
Query 4: 
-- The total quantity of medicine in a prescription is the sum of the quantity of all the medicines in the prescription.
-- Select the prescriptions for which the total quantity of medicine exceeds
-- the avg of the total quantity of medicines for all the prescriptions.

drop table if exists T1;


select Pharmacy.pharmacyID, Prescription.prescriptionID, sum(quantity) as totalQuantity
into T1
from Pharmacy
join Prescription on Pharmacy.pharmacyID = Prescription.pharmacyID
join Contain on Contain.prescriptionID = Prescription.prescriptionID
join Medicine on Medicine.medicineID = Contain.medicineID
join Treatment on Treatment.treatmentID = Prescription.treatmentID
where YEAR(date) = 2022
group by Pharmacy.pharmacyID, Prescription.prescriptionID
order by Pharmacy.pharmacyID, Prescription.prescriptionID;


select * from T1
where totalQuantity > (select avg(totalQuantity) from T1);
*/

WITH PrescriptionTotalQuantity AS (
    SELECT
        p.pharmacyID,
        pr.prescriptionID,
        SUM(quantity) AS totalQuantity
    FROM Pharmacy p
    JOIN Prescription pr using(pharmacyID)
    JOIN Contain c ON using(prescriptionID)
    JOIN Medicine m ON using(medicineID)
    JOIN Treatment t ON using(treatmentID)
    WHERE YEAR(date) = 2022
    GROUP BY p.pharmacyID, pr.prescriptionID
)

SELECT *
FROM PrescriptionTotalQuantity
WHERE totalQuantity > (SELECT AVG(totalQuantity) FROM PrescriptionTotalQuantity);

/*Query 5: 

-- Select every disease that has 'p' in its name, and 
-- the number of times an insurance claim was made for each of them. 

SELECT Disease.diseaseName, COUNT(*) as numClaims
FROM Disease
JOIN Treatment ON Disease.diseaseID = Treatment.diseaseID
JOIN Claim On Treatment.claimID = Claim.claimID
WHERE diseaseName IN (SELECT diseaseName from Disease where diseaseName LIKE '%p%')
GROUP BY diseaseName;
*/

WITH p_Diseases AS (
    SELECT diseaseID
    FROM disease
    WHERE diseaseName LIKE '%p%'
)
SELECT d.diseaseName, COUNT(*) AS num_of_claims
FROM Disease d
JOIN Treatment t ON d.diseaseID = t.diseaseID
JOIN Claim c ON t.claimID = c.claimID
JOIN p_Diseases pd ON d.diseaseID = pd.diseaseID
GROUP BY d.diseaseName;

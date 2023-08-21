/*
Problem Statement 1:
The healthcare department has requested a system to analyze the performance of insurance companies and their plan.
For this purpose, create a stored procedure that returns the performance of different insurance plans of an insurance company. When passed the insurance company ID the procedure should generate and return all the insurance plan names the provided company issues, the number of treatments the plan was claimed for, and the name of the disease the plan was claimed for the most. The plans which are claimed more are expected to appear above the plans that are claimed less.
*/

DROP PROCEDURE IF EXISTS insurance_company_detail_proc;
DELIMITER //
CREATE PROCEDURE insurance_company_detail_proc(IN input_companyID INT)
BEGIN
	select ic.companyID,ic.companyName,ip.planName,count(t.claimID) as claim_count
	from insuranceCompany ic
	join insurancePlan ip using (companyID)
	join claim c using(UIN)
	join treatment t using(claimID)
	join disease d using(diseaseID)
	where ic.companyID=input_companyID
	group by ic.companyID,ic.companyName,ip.planName
	order by ic.companyID,claim_count desc
	;
	with details as
	(
	select ic.companyID,ic.companyName,ip.planName,d.diseaseName,count(t.claimID) as claim_count,
	DENSE_RANK() over(PARTITION by d.diseaseName order by count(t.claimID) desc) as rnk
	from insuranceCompany ic
	join insurancePlan ip using (companyID)
	join claim c using(UIN)
	join treatment t using(claimID)
	join disease d using(diseaseID)
	where ic.companyID=input_companyID
	group by ic.companyID,ic.companyName,ip.planName,d.diseaseName
	order by ic.companyID,rnk
	)
	select distinct * from details where rnk=1
	;
	
END //

DELIMITER ;

CALL insurance_company_detail_proc(3489);

/*
Problem Statement 2:
It was reported by some unverified sources that some pharmacies are more popular for certain diseases. The healthcare department wants to check the validity of this report.
Create a stored procedure that takes a disease name as a parameter and would return the top 3 pharmacies the patients are preferring for the treatment of that disease in 2021 as well as for 2022.
Check if there are common pharmacies in the top 3 list for a disease, in the years 2021 and the year 2022.
Call the stored procedure by passing the values “Asthma” and “Psoriasis” as disease names and draw a conclusion from the result.
*/
DROP PROCEDURE IF EXISTS disease_pharmacy_detail_proc;
DELIMITER //

CREATE PROCEDURE disease_pharmacy_detail_proc(IN input_diseaseName VARCHAR(50))
BEGIN
with 2021_disease_data as (
select diseaseName,pharmacyName,count(pr.prescriptionID) count_of_pharma,DENSE_RANK() over(order by count(pr.prescriptionID) desc) as rnk
from disease d 
join treatment t using(diseaseID)
join prescription pr using(treatmentID)
join pharmacy p using(pharmacyID)
where year(t.date)=2021 
and diseaseName = input_diseaseName
group by diseaseName,pharmacyName
order by rnk 
)
select diseaseName,pharmacyName,count_of_pharma from 2021_disease_data where rnk<=3;

with 2022_disease_data as (
select diseaseName,pharmacyName,count(pr.prescriptionID) count_of_pharma,DENSE_RANK() over(order by count(pr.prescriptionID) desc) as rnk
from disease d 
join treatment t using(diseaseID)
join prescription pr using(treatmentID)
join pharmacy p using(pharmacyID)
where year(t.date)=2022 
and diseaseName = input_diseaseName
group by diseaseName,pharmacyName
order by rnk 
)
select diseaseName,pharmacyName,count_of_pharma from 2022_disease_data where rnk<=3;

END //

DELIMITER ;

CALL disease_pharmacy_detail_proc('Asthma');

/*
Problem Statement 3:
Jacob, as a business strategist, wants to figure out if a state is appropriate for setting up an insurance company or not.
Write a stored procedure that finds the num_patients, num_insurance_companies, and insurance_patient_ratio, the stored procedure should also find the avg_insurance_patient_ratio and if the insurance_patient_ratio of the given state is less than the avg_insurance_patient_ratio then it Recommendation section can have the value “Recommended” otherwise the value can be “Not Recommended”.

Description of the terms used:
num_patients: number of registered patients in the given state
num_insurance_companies:  The number of registered insurance companies in the given state
insurance_patient_ratio: The ratio of registered patients and the number of insurance companies in the given state
avg_insurance_patient_ratio: The average of the ratio of registered patients and the number of insurance for all the states.
*/
DROP PROCEDURE IF EXISTS new_insurance_company_reccomendation_proc;
DELIMITER //

CREATE PROCEDURE new_insurance_company_reccomendation_proc(IN input_state VARCHAR(10))
BEGIN
	with patient_details as 
	(
		select DISTINCT state ,count(patientID) as patient_count_by_state
		from address a
		join person pr using(addressID)
		join patient pt 
		on pt.patientID = pr.personID
		group by state
	),
	company_details as 
	(
		select DISTINCT state ,count(companyName) as company_count_by_state
		from address a
		join insuranceCompany ic using(addressID)
		group by state
	),
	insurance_patient_ratio_table as (
	select distinct a.state,patient_count_by_state,company_count_by_state, 
	case when (patient_count_by_state IS NULL or company_count_by_state IS NULL) then 0
		 else (patient_count_by_state/company_count_by_state) 
		 end as insurance_patient_ratio
	 from address a
	left join patient_details pd 
	on a.state = pd.state
	left join company_details cd 
	on a.state = cd.state
	)

	select state,insurance_patient_ratio,case when insurance_patient_ratio<(select avg(insurance_patient_ratio) from insurance_patient_ratio_table) then 'Recommended'
		   else 'Not Recommended'
		   end as Reccomendation
	from insurance_patient_ratio_table
	where state= input_state
	;
	
END //

DELIMITER ;

CALL new_insurance_company_reccomendation_proc('VT');

/*
Problem Statement 4:
Currently, the data from every state is not in the database, The management has decided to add the data from other states and cities as well. It is felt by the management that it would be helpful if the date and time were to be stored whenever new city or state data is inserted.
The management has sent a requirement to create a PlacesAdded table if it doesn’t already exist, that has four attributes. placeID, placeName, placeType, and timeAdded.
Description
placeID: This is the primary key, it should be auto-incremented starting from 1
placeName: This is the name of the place which is added for the first time
placeType: This is the type of place that is added for the first time. The value can either be ‘city’ or ‘state’
timeAdded: This is the date and time when the new place is added

You have been given the responsibility to create a system that satisfies the requirements of the management. Whenever some data is inserted in the Address table that has a new city or state name, the PlacesAdded table should be updated with relevant data. 
*/
CREATE TABLE IF NOT EXISTS PlacesAdded (
    placeID INT AUTO_INCREMENT PRIMARY KEY,
    placeName VARCHAR(255) NOT NULL,
    placeType ENUM('city', 'state') NOT NULL,
    timeAdded DATETIME NOT NULL
);

DELIMITER //

CREATE TRIGGER address_after_insert
AFTER INSERT ON Address
FOR EACH ROW
BEGIN
    DECLARE place_id INT;
    SELECT placeID INTO place_id
    FROM PlacesAdded
    WHERE placeName = NEW.city OR placeName = NEW.state
    LIMIT 1;

    IF place_id IS NULL THEN
        -- Insert the new city/state into PlacesAdded
        INSERT INTO PlacesAdded (placeName, placeType, timeAdded)
        VALUES (NEW.city, 'city', NOW());

        INSERT INTO PlacesAdded (placeName, placeType, timeAdded)
        VALUES (NEW.state, 'state', NOW());
    END IF;
END;
//

DELIMITER ;

/*
Problem Statement 5:
Some pharmacies suspect there is some discrepancy in their inventory management. The quantity in the ‘Keep’ is updated regularly and there is no record of it. They have requested to create a system that keeps track of all the transactions whenever the quantity of the inventory is updated.
You have been given the responsibility to create a system that automatically updates a Keep_Log table which has  the following fields:
id: It is a unique field that starts with 1 and increments by 1 for each new entry
medicineID: It is the medicineID of the medicine for which the quantity is updated.
quantity: The quantity of medicine which is to be added. If the quantity is reduced then the number can be negative.
For example:  If in Keep the old quantity was 700 and the new quantity to be updated is 1000, then in Keep_Log the quantity should be 300.
Example 2: If in Keep the old quantity was 700 and the new quantity to be updated is 100, then in Keep_Log the quantity should be -600.
*/

CREATE TABLE IF NOT EXISTS Keep_Log (
    id INT AUTO_INCREMENT PRIMARY KEY,
    medicineID INT NOT NULL,
    quantity INT NOT NULL
);

DELIMITER //

CREATE TRIGGER keep_after_update
AFTER UPDATE ON Keep
FOR EACH ROW
BEGIN
    DECLARE updated_qty INT;

    SET updated_qty = NEW.quantity - OLD.quantity;

    INSERT INTO Keep_Log (medicineID, quantity)
    VALUES (NEW.medicineID, updated_quantity);
END;
//

DELIMITER ;
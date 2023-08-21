/*
Problem Statement 1:
Patients are complaining that it is often difficult to find some medicines. They move from pharmacy to pharmacy to get the required medicine. A system is required that finds the pharmacies and their contact number that have the required medicine in their inventory. So that the patients can contact the pharmacy and order the required medicine.
Create a stored procedure that can fix the issue.
*/


DROP PROCEDURE IF EXISTS find_pharmacy_proc;
DELIMITER //
CREATE PROCEDURE find_pharmacy_proc(IN medicine_name VARCHAR(50))
BEGIN
	select productName,pharmacyName,phone
	from medicine m 
	join keep k using(medicineID)
	join pharmacy p using(pharmacyID)
	where productName = medicine_name
	and k.quantity>0
	;
END //
DELIMITER ;

CALL find_pharmacy_proc('DEXAMETASONA');

/*
Problem Statement 2:
The pharmacies are trying to estimate the average cost of all the prescribed medicines per prescription, for all the prescriptions they have prescribed in a particular year. Create a stored function that will return the required value when the pharmacyID and year are passed to it. Test the function with multiple values.
*/
DROP FUNCTION CalculateAverageMedCost;
DELIMITER //

CREATE FUNCTION CalculateAverageMedCost(
    in_pharmacyID INT,
    in_year INT
) 
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE total_cost DECIMAL(10, 2);
    DECLARE total_prescriptions INT;
    
    SELECT SUM(maxprice), 
           COUNT(DISTINCT prescriptionID)
    INTO total_cost, total_prescriptions
    FROM prescription pr
	join treatment t using(treatmentID)
	join contain c using(prescriptionID)
	join medicine m using(medicineID)
    WHERE pharmacyID = in_pharmacyID
	AND YEAR(t.date) = in_year;
	
	IF total_prescriptions > 0 THEN
        RETURN total_cost / total_prescriptions;
    ELSE
        RETURN 0.00;
    END IF;
END;
//

DELIMITER ;

SELECT CalculateAverageMedCost(1008, 2022) AS average_cost_2022_pharmacy_1008 ;

/*
Problem Statement 3:
The healthcare department has requested an application that finds out the disease that was spread the most in a state for a given year. So that they can use the information to compare the historical data and gain some insight.
Create a stored function that returns the name of the disease for which the patients from a particular state had the most number of treatments for a particular year. Provided the name of the state and year is passed to the stored function.
*/

-- DROP FUNCTION max_disease_of_patient_state;
DELIMITER //

CREATE FUNCTION max_disease_of_patient_state(
    in_state VARCHAR(10),
    in_year INT
) 
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
    DECLARE disease_name VARCHAR(50);

	select state,diseaseName into disease_name,count(diseaseName)
	from address a 
	join person p using(addressID)
	join patient pt 
	on p.personID = pt.patientID
	join treatment t using(patientID)
	join disease d using(diseaseID)
	where state=in_state
	AND YEAR(t.date) = in_year
	order by count(diseaseName) desc
	limit 1
	;
	
	RETURN disease_name;
END;
//

DELIMITER ;

SELECT max_disease_of_patient_state('CA', 2022) AS average_cost_2022_pharmacy_1008 ;

/*
Problem Statement 4:
The representative of the pharma union, Aubrey, has requested a system that she can use to find how many people in a specific city have been treated for a specific disease in a specific year.
Create a stored function for this purpose.
*/
DROP FUNCTION IF EXISTS city_wise_disease_treatment;
DELIMITER //

CREATE FUNCTION IF NOT EXISTS city_wise_disease_treatment(
    in_city VARCHAR(25),
	in_disease_id INT,
    in_year INT
) 
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE count_of_patients INT;	
	select count(treatmentID) into count_of_patients
	from disease d 
	join treatment t using(diseaseID)
	join patient pt using(patientID)
	join person p 
	on p.personID = pt.patientID
	join address a using(addressID)
	where city= in_city
	and year(t.date)=in_year
	and diseaseID=in_disease_id
	group by city, d.diseaseName;
	
	RETURN count_of_patients;
	
END;
//

DELIMITER ;

SELECT city_wise_disease_treatment('Washington',20, 2021) AS count_of_patients_in_city ;

/*
Problem Statement 5:
The representative of the pharma union, Aubrey, is trying to audit different aspects of the pharmacies. She has requested a system that can be used to find the average balance for claims submitted by a specific insurance company in the year 2022. 
Create a stored function that can be used in the requested application. 
*/

DROP FUNCTION IF EXISTS company_wise_average_balance;
DELIMITER //

CREATE FUNCTION IF NOT EXISTS company_wise_average_balance(
    in_company_id INT
) 
RETURNS VARCHAR(50)
DETERMINISTIC
BEGIN
	DECLARE avg_balance DECIMAL(11,2);
	select avg(balance) into avg_balance
	from claim c 
	join treatment t using(claimID)
	join insurancePlan ip using(UIN)
	join insuranceCompany ic using(companyID)
	where year(t.date)=2022
	and ic.companyID = in_company_id
	;
	return avg_balance;
END;
//

DELIMITER ;

SELECT company_wise_average_balance(5173) AS company_wise_average_balance_for_this_year ;
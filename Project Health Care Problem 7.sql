/*
Problem Statement 1: 
Insurance companies want to know if a disease is claimed higher or lower than average.  Write a stored procedure that returns “claimed higher than average” or “claimed lower than average” when the diseaseID is passed to it. 
Hint: Find average number of insurance claims for all the diseases.  If the number of claims for the passed disease is higher than the average return “claimed higher than average” otherwise “claimed lower than average”.
*/

DROP PROCEDURE CheckClaimStatus;
DELIMITER //
CREATE PROCEDURE CheckClaimStatus(IN diseaseID INT)
BEGIN
    DECLARE avgClaims INT;
    DECLARE diseaseClaims INT;
    
    SELECT COUNT(*) INTO avgClaims
    FROM claim c
    WHERE EXISTS (
        SELECT 1
        FROM treatment t
        WHERE t.claimID = c.claimID
        AND t.diseaseID = diseaseID
    );

    SELECT COUNT(*) INTO diseaseClaims
    FROM claim
    WHERE treatmentID IN (
        SELECT treatmentID
        FROM treatment
        WHERE diseaseID = diseaseID
    );

    IF diseaseClaims > avgClaims THEN
        SELECT 'claimed higher than average' AS claim_status;
    ELSE
        SELECT 'claimed lower than average' AS claim_status;
    END IF;s
END //
DELIMITER ;

call CheckClaimStatus(100);

/* 
Problem Statement 2:  
Joseph from Healthcare department has requested for an application which helps him get genderwise report for any disease. 
Write a stored procedure when passed a disease_id returns 4 columns,
disease_name, number_of_male_treated, number_of_female_treated, more_treated_gender
Where, more_treated_gender is either ‘male’ or ‘female’ based on which gender underwent more often for the disease, if the number is same for both the genders, the value should be ‘same’.

*/
DELIMITER //

CREATE PROCEDURE male_and_female_disease_ratio(IN input_diseaseID INT)
BEGIN
    WITH male_data AS (
        SELECT diseaseName, COUNT(patientID) AS number_of_male_treated
        FROM disease d 
        JOIN treatment t USING (diseaseID)
        JOIN patient p USING (patientID)
        JOIN person pr ON pr.personID = p.patientID
        WHERE gender = 'male'
        AND d.diseaseID = input_diseaseID
        GROUP BY diseaseName
    ),
    female_data AS (
        SELECT diseaseName, COUNT(patientID) AS number_of_female_treated
        FROM disease d 
        JOIN treatment t USING (diseaseID)
        JOIN patient p USING (patientID)
        JOIN person pr ON pr.personID = p.patientID
        WHERE gender = 'female'
        AND d.diseaseID = input_diseaseID
        GROUP BY diseaseName
    )
    SELECT d.diseaseName, number_of_male_treated, number_of_female_treated,
           IF(number_of_male_treated > number_of_female_treated, 'male', 
              IF(number_of_male_treated < number_of_female_treated, 'female', 'same')) AS more_treated_gender
    FROM disease d
    JOIN male_data m USING (diseaseName)
    JOIN female_data f USING (diseaseName);
END //

DELIMITER ;

CALL male_and_female_disease_ratio(1);

/*
Problem Statement 3:  
The insurance companies want a report on the claims of different insurance plans. 
Write a query that finds the top 3 most and top 3 least claimed insurance plans.
The query is expected to return the insurance plan name, the insurance company name which has that plan, and whether the plan is the most claimed or least claimed. 
*/

with ins_pln AS
(
select ip.uin , ip.planName , ic.companyID , ic.companyName , count(*) as total_claim,
dense_rank() over (order by count(*) desc) as claim_high_rank , 
dense_rank() over (order by count(*) ) as claim_low_rank  
from treatment t
inner join claim c on c.claimID = t.claimID
inner join insuranceplan ip on ip.uin = c.uin
inner join insurancecompany ic on ic.companyID = ip.companyID
group by companyID , uin 
)

select  planName, companyName, total_claim,
case 
	when claim_high_rank <=3 then 'most_claimed_plan' 
    when claim_low_rank<=3 then 'least_claimed_plan'
    end as category
 from ins_pln
where claim_high_rank <=3 or claim_low_rank<=3
;

/*
Problem Statement 4: 
The healthcare department wants to know which category of patients is being affected the most by each disease.
Assist the department in creating a report regarding this.
Provided the healthcare department has categorized the patients into the following category.
YoungMale: Born on or after 1st Jan  2005  and gender male.
YoungFemale: Born on or after 1st Jan  2005  and gender female.
AdultMale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender male.
AdultFemale: Born before 1st Jan 2005 but on or after 1st Jan 1985 and gender female.
MidAgeMale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender male.
MidAgeFemale: Born before 1st Jan 1985 but on or after 1st Jan 1970 and gender female.
ElderMale: Born before 1st Jan 1970, and gender male.
ElderFemale: Born before 1st Jan 1970, and gender female.
*/
SELECT
    pr.personID,
    pr.personName,
    pr.gender,
    p.dob,
    IF (YEAR(p.dob) > 2005 AND pr.gender = 'male', 'YoungMale',
        IF (YEAR(p.dob) > 2005 AND pr.gender = 'female', 'YoungFemale',
            IF (YEAR(p.dob) < 2005 AND YEAR(p.dob) >= 1985 AND pr.gender = 'male', 'AdultMale',
                IF (YEAR(p.dob) < 2005 AND YEAR(p.dob) >= 1985 AND pr.gender = 'female', 'AdultFemale',
                    IF (YEAR(p.dob) < 1985 AND YEAR(p.dob) >= 1970 AND pr.gender = 'male', 'MidAgeMale',
                        IF (YEAR(p.dob) < 1985 AND YEAR(p.dob) >= 1970 AND pr.gender = 'female', 'MidAgeFemale',
                            IF (YEAR(p.dob) < 1970 AND pr.gender = 'male', 'ElderMale',
                                IF (YEAR(p.dob) < 1970 AND pr.gender = 'female', 'ElderFemale', NULL)
                            )
                        )
                    )
                )
            )
        )
    ) AS age_category
FROM
    person pr
JOIN
    patient p ON pr.personID = p.patientID
limit 5
;

/*
Problem Statement 5:  
Anna wants a report on the pricing of the medicine. She wants a list of the most expensive and most affordable medicines only. 
Assist anna by creating a report of all the medicines which are pricey and affordable, listing the companyName, productName, description, maxPrice, and the price category of each. Sort the list in descending order of the maxPrice.
Note: A medicine is considered to be “pricey” if the max price exceeds 1000 and “affordable” if the price is under 5. Write a query to find 
*/

WITH price_comp AS (
    SELECT
        companyName, productName, description, maxPrice,medicineID,
        IF(maxPrice < 5, 'affordable',
           IF(maxPrice > 1000, 'pricey', 'normal')) AS price_tag
    FROM
        medicine m
)

SELECT
    companyName, productName, description, maxPrice,price_tag
FROM
    price_comp t
JOIN
    keep k USING (medicineID)
JOIN
    pharmacy p USING (pharmacyID)
WHERE
    price_tag IN ('affordable', 'pricey');
/*
John G. Moran
"Cleaning and Analyzing a Library Dataset"
This project concerns two years of synthetic data for a fictious four-branch library system; 
it investigates the quality of that data, validates business rules, and 
identifies potential opportunities to improve inventory allocation across the system.
*/

-- BUSINESS-RULE VALIDATION

-- The following queries tallied various anomalies and business-rule violations.

-- RegistrationDate preceding BirthYear or being within four years of BirthYear in Patrons table
-- (i.e., based on an assumed rule that the minimum age for registration is five):

SELECT
	COUNT(patronID)
FROM patrons
WHERE YEAR(RegistrationDate) < BirthYear;

SELECT
	COUNT(patronID)
FROM patrons
WHERE YEAR(RegistrationDate) <= BirthYear + 4
;

-- ReturnDate preceding CheckoutDate in Checkouts table:

SELECT
	COUNT(*)
FROM checkouts
WHERE ReturnDate < CheckoutDate;

-- FulfilledDate accompanying "Active" HoldStatus in Holds table:

SELECT
	COUNT(*)
FROM holds
WHERE FulfilledDate IS NOT NULL
  AND HoldStatus = 'Active';
  
-- "Fulfilled" HoldStatus without accompanying FulfilledDate:
 
SELECT
	COUNT(*)
FROM holds
WHERE HoldStatus = 'Fulfilled'
  AND FulfilledDate IS NULL;
  
-- Transfers from branches to themselves:

SELECT
	COUNT(*)
FROM inventory_transfer
WHERE FromBranchID = ToBranchID;

-- The query below questioned whether there was a connection between "glitch transfers"
-- (i.e., transfers from a branch to itself) and actual transfers: The query checks
-- if such an erroneously listed transfer occured within 31 days of an actual transfer
-- of the same title.

WITH glitch_transfers AS (
    SELECT *
    FROM inventory_transfer
    WHERE FromBranchID = ToBranchID
)
SELECT
    gt.titleid AS Glitch_TitleID,
    gt.transferdate AS Glitch_Date,
    it.transferdate AS Regular_Date
FROM glitch_transfers gt
JOIN inventory_transfer it
    ON gt.titleid = it.titleid
   AND it.FromBranchID <> it.ToBranchID
   AND ABS(DATEDIFF(gt.transferdate, it.transferdate)) < 31;
   
-- InventoryTransfers with quantity <= 0:

SELECT
	COUNT(*)
FROM inventory_transfer
WHERE Quantity <= 0;   
   
-- The following adapts a previous query to make a similar check whether instances of
-- a transfer quantity being listed as <= 0 have any correspondence with actual
-- transers of the same title within 31 days.

WITH glitch_transfers AS (
    SELECT *
    FROM inventory_transfer
    WHERE Quantity <= 0
)
SELECT
    gt.titleid AS Glitch_TitleID,
    gt.transferdate AS Glitch_Date,
    it.transferdate AS Regular_Date
FROM glitch_transfers gt
JOIN inventory_transfer it
    ON gt.titleid = it.titleid
   AND it.Quantity > 0
   AND ABS(DATEDIFF(gt.transferdate, it.transferdate)) < 31;

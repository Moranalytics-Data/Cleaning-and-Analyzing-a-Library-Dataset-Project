/*
John G. Moran
"Cleaning and Analyzing a Library Dataset"
This project concerns two years of synthetic data for a fictious four-branch library system; 
it investigates the quality of that data, validates business rules, and 
identifies potential opportunities to improve inventory allocation across the system.
*/

-- DATA CLEANING

-- Correcting inconsistent capitalization within the one-word "HoldStatus" field:

UPDATE holds
SET HoldStatus = CONCAT(
    UPPER(LEFT(HoldStatus, 1)),
    LOWER(SUBSTRING(HoldStatus, 2))
);

-- Checking for misformatted dates:

SELECT CheckoutDate
FROM checkouts
WHERE STR_TO_DATE(CheckoutDate, '%Y-%m-%d') IS NULL;

-- Correcting misformatted dates:

UPDATE checkouts
SET CheckoutDate = STR_TO_DATE(CheckoutDate, '%m/%d/%Y')
WHERE CheckoutDate LIKE '%/%';

-- Finding and converting impossible birthdates to NULLs:

SELECT *
FROM patrons
WHERE BirthYear < 1920;

UPDATE patrons
SET BirthYear = NULL
WHERE BirthYear IN (-1,1800,1900);

-- Changing outlier Genre category names:

UPDATE titles
SET genre = 'Science Fiction'
WHERE genre = 'Sci-Fi';

UPDATE titles
SET genre = 'Mystery/Thriller'
WHERE genre = 'Mystery';

UPDATE titles
SET genre = 'Historical Fiction'
WHERE genre = 'Hist Fic';

UPDATE titles
SET genre = 'Biography'
WHERE genre = 'BIO';

-- Standardizing author name formatting:

UPDATE titles
SET author =
    CONCAT(
    SUBSTRING(author,LOCATE(',',author) +2),    
    ' ',
    LEFT(author,LOCATE(',',author) -1)
    )
WHERE author LIKE '%,%';

-- While attempting to convert (what I thought were) empty strings,
-- the following query stumbled onto some fields that only *appeared* empty:

UPDATE patrons
SET StatusChangeDate = NULL
WHERE StatusChangeDate = '';

-- I went looking for offenders...

SELECT StatusChangeDate, LENGTH(StatusChangeDate)
FROM patrons
WHERE StatusChangeDate IS NOT NULL
  AND LENGTH(StatusChangeDate) < 5;

-- ...and attempted to adjust them like so:

UPDATE patrons
SET StatusChangeDate = NULL
WHERE TRIM(StatusChangeDate) = '';

-- The troublemaker remained resilient, though. I searched further:

SELECT 
    StatusChangeDate,
    LENGTH(StatusChangeDate),
    HEX(StatusChangeDate)
FROM patrons
WHERE LENGTH(StatusChangeDate) = 1
LIMIT 10;

-- Having determined the culprit was a carriage return (0D ... ASCII character 13),
-- I applied this query to clean the field as thoroughly as possible:

UPDATE patrons
SET StatusChangeDate = NULL
WHERE TRIM(REPLACE(StatusChangeDate, CHAR(13), '')) = '';

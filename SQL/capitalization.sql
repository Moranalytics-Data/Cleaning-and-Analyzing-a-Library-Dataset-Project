/*
John G. Moran
"Cleaning and Analyzing a Library Dataset"
This project concerns two years of synthetic data for a fictious four-branch library system; 
it investigates the quality of that data, validates business rules, and 
identifies potential opportunities to improve inventory allocation across the system.
*/

-- CAPITALIZATION

-- Realizing that the TitleName field was going to need extensive work,
-- I created a new version in which to make those revisions:

ALTER TABLE titles
ADD COLUMN TitleName_Standardized VARCHAR(105);

UPDATE titles
SET TitleName_Standardized = TitleName;

-- This query, below, was written to either relocate an introductory "The" to the end of the title,
-- after a comma; or relocate it to the end of the title but *before* the "[Id: XXXXX]" tag
-- (in those instances in which an existing title included such a tag). The query is also 
-- designed to maintain whatever existing form of capitalization the title had originally.

UPDATE titles
SET	TitleName_Standardized = 
	CASE WHEN TitleName_Standardized NOT LIKE '%[Id%'
		THEN
			CONCAT(
			SUBSTRING(
				TitleName_Standardized,
				5
				-- 5 = starting postition of the title after 'The '
				),
			CASE WHEN BINARY TitleName_Standardized = BINARY LOWER(TitleName_Standardized)
				THEN ', the'
				WHEN BINARY TitleName_Standardized = BINARY UPPER(TitleName_Standardized)
				THEN ', THE'
				ELSE ', The'
			END
			-- This is to keep consistent those instances of titles in either all caps or in all lowercase
			)
		ELSE
			CONCAT(
			SUBSTRING(
				TitleName_Standardized,
				5,
				LENGTH(TitleName_Standardized)-16
				-- 5 = starting position of the title after 'The '
				-- 16 = sum of 4 (length of 'The ') + 1 (space before ID) + 11 (length of '[Id: XXXXX]')
				-- Remove both from the original length to get the title length
				),
			CASE WHEN BINARY TitleName_Standardized = BINARY LOWER(TitleName_Standardized)
				THEN ', the '
				WHEN BINARY TitleName_Standardized = BINARY UPPER(TitleName_Standardized)
				THEN ', THE '
				ELSE ', The '
			END
			-- This is to keep consistent those instances of titles in either all caps or in all lowercase
			,
				SUBSTRING(
					TitleName_Standardized,
					LOCATE('[Id',TitleName_Standardized),
					11
					-- 11 is the length of the "[Id: XXXXX]" portion that is being relocated to the end of the string
					) 
			)
			END
WHERE TitleName_Standardized LIKE 'The %';

-- This query was designed to fix those existing instances in which the "[Id: XXXXX]" tag
-- separated the title and its introductory article (e.g., "Big Sleep [Id: XXXXX], The").
-- This query converts the example into "Big Sleep, The [Id: XXXXX]".

UPDATE titles
SET TitleName_Standardized =
    CONCAT(
		LEFT(
			Titlename_Standardized,
            LOCATE('[Id:',TitleName_Standardized)-2
            ),
        ', The ',
        LEFT(
			SUBSTRING(
					TitleName_Standardized,
                    LOCATE('Id:',TitleName_Standardized)-1),
                    11
                    -- 11 is the length of the "[Id: XXXXX]" string
                    )
        )
WHERE TitleName_Standardized LIKE '%[Id:%'
  AND TitleName_Standardized LIKE '%, The';

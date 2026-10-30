/*
John G. Moran
"Cleaning and Analyzing a Library Dataset"
This project concerns two years of synthetic data for a fictious four-branch library system; 
it investigates the quality of that data, validates business rules, and 
identifies potential opportunities to improve inventory allocation across the system.
*/

-- DATA ANALYSES

-- This query, below, examined the "Top 131" books (aka, those books with more
-- than 31 checkouts system-wide in the dataset's two-year time period)
-- to see which branches had zero copies of any given title on the list.
-- The query is sorted according to the number of holds placed for 
-- the title in question at the branch without a copy of said title.

WITH top_131_books AS(
	SELECT
		titleID,
        COUNT(checkoutID) AS top_count
	FROM checkouts
    GROUP BY titleID
		HAVING COUNT(checkoutID) >= 31
	)
SELECT
	tb.titleID,
    t.titlename_standardized,
    b.branchID,
    COUNT(h.holdID) AS holds_requested
FROM top_131_books tb
	CROSS JOIN branches b
    JOIN titles t
		ON tb.titleId = t.titleId
	LEFT JOIN holds h
		ON tb.titleID = h.titleID
	   AND h.branchID = b.branchID
WHERE NOT EXISTS
	(SELECT 1
    FROM branch_inventory bi
    WHERE bi.titleId = tb.titleID
      AND bi.branchId = b.branchID
    )
GROUP BY tb.titleID, t.titlename_standardized, b.branchID
ORDER BY holds_requested DESC;

-- This query, below, sought to determine titles, by branch, meeting the following criteria:
--   • a turnover ratio (i.e., checkouts / branch inventory) of at least 10.0
--   • a hold request in the final 3 months of 2024 (i.e., the last year covered by the dataset)
--   • no copies at any other branch

WITH checkout_to_inventory_ratio AS (
    SELECT
        c.titleID,
        c.branchID,
        COUNT(c.checkoutid) / bi.copycount AS check_to_inv_rat
    FROM checkouts c
    JOIN branch_inventory bi
        ON c.titleid = bi.titleid
	   AND c.branchID = bi.branchID
    GROUP BY c.titleID, c.branchID, bi.copycount
    HAVING check_to_inv_rat >= 10
)
SELECT
    ctir.titleID,
    ctir.branchID,
    ctir.check_to_inv_rat
FROM checkout_to_inventory_ratio ctir
WHERE EXISTS (
    SELECT 1
    FROM holds h
    WHERE h.titleID = ctir.titleID
      AND h.branchID = ctir.branchID
      AND h.holddate >= '2024-10-01'
)
AND NOT EXISTS (
    SELECT 1
    FROM branch_inventory bi
    WHERE bi.titleid = ctir.titleid
      AND bi.branchid <> ctir.branchid
)
ORDER BY
	ctir.branchID ASC,
	ctir.check_to_inv_rat DESC;

-- The following is the above query, but modified for individual branch use
-- (in this example, Branch 1), in order to allow for individual adjustment
-- of the turnover-ratio criterion.

WITH checkout_to_inventory_ratio AS (
    SELECT
        c.titleID,
        COUNT(c.checkoutid) / bi.copycount AS check_to_inv_rat
    FROM checkouts c
    JOIN branch_inventory bi
        ON c.titleid = bi.titleid
       AND bi.branchid = 1
    WHERE c.branchid = 1
    GROUP BY c.titleID, bi.copycount
    HAVING check_to_inv_rat >= 10
)
SELECT
    ctir.titleID,
    ctir.check_to_inv_rat
FROM checkout_to_inventory_ratio ctir
WHERE EXISTS (
    SELECT 1
    FROM holds h
    WHERE h.titleid = ctir.titleid
      AND h.branchid = 1
      AND h.holddate >= '2024-10-01'
)
AND NOT EXISTS (
    SELECT 1
    FROM branch_inventory bi
    WHERE bi.titleid = ctir.titleid
      AND bi.branchid IN (2, 3, 4)
)
ORDER BY ctir.check_to_inv_rat DESC;

-- The following query was written to determine, for each branch,
-- those titles with over two copies in inventory that had not been
-- checked out in the previous eighteen months:

SELECT
    bi.titleID,
    t.titlename_standardized,
    bi.branchID,
    bi.copycount,
    t.publicationyear,
    CONCAT(t.publicationyear,' • ',copycount) AS pubyear_count
FROM branch_inventory bi
JOIN titles t
    ON bi.titleID = t.titleID
WHERE bi.copycount >= 2
  AND NOT EXISTS (
      SELECT 1
      FROM checkouts c
      WHERE c.titleID = bi.titleID
        AND c.branchID = bi.branchID
        AND c.checkoutdate >= '2023-07-01'
  )
	AND t.genre <> 'Reference'
ORDER BY t.publicationyear ASC;

-- This query's intent was generate turnover ratios (i.e., checkouts / inventory)
-- for each title, then find those instances with the greatest disparity between
-- two branches with the same title in each's inventory. (The disparity criterion
-- here is set to 10.) Note also that that CopyCount in the "donor_branch_turnover_ratio"
-- CTE requires that potential donor branches have at least 2 copies of the title in question.

WITH 
	all_branch_turnover_ratio AS (
    SELECT 
        i.titleid,
        i.branchid,
        i.copycount,
        ROUND(COUNT(c.checkoutid) * 1.0 / NULLIF(i.copycount, 0), 2) AS turnover_ratio
    FROM branch_inventory i
    LEFT JOIN checkouts c 
        ON i.titleid = c.titleid 
       AND i.branchid = c.branchid
    WHERE i.copycount > 0
    GROUP BY i.titleid, i.branchid, i.copycount
),
donor_branch_turnover_ratio AS (
    SELECT 
        titleid,
        branchid,
        turnover_ratio
    FROM all_branch_turnover_ratio
    WHERE copycount >= 2
-- CopyCount requirement to ensure potential donor branch has inventory to spare
),
turnover_ratio_disparity AS (
    SELECT 
        abu.titleid,
        MAX(abu.turnover_ratio) AS max_turnover,
        MIN(dbu.turnover_ratio) AS min_turnover,
        (MAX(abu.turnover_ratio) - MIN(dbu.turnover_ratio)) AS disparity
    FROM all_branch_turnover_ratio abu
		LEFT JOIN donor_branch_turnover_ratio dbu
			ON abu.titleid = dbu.titleid
    GROUP BY abu.titleid
)
SELECT 
    trd.titleid,
    trd.max_turnover,
    GROUP_CONCAT(DISTINCT abtr.branchid ORDER BY abtr.branchid SEPARATOR ', ') AS high_demand_branches,
    trd.min_turnover,
    GROUP_CONCAT(DISTINCT dbtr.branchid ORDER BY dbtr.branchid SEPARATOR ', ') AS donor_branches,
    trd.disparity
FROM turnover_ratio_disparity trd
    LEFT JOIN all_branch_turnover_ratio abtr
		ON trd.max_turnover = abtr.turnover_ratio
	   AND trd.titleid = abtr.titleid
	LEFT JOIN donor_branch_turnover_ratio dbtr
		ON trd.min_turnover = dbtr.turnover_ratio
	   AND trd.titleid = dbtr.titleid
WHERE trd.disparity >= 10
GROUP BY 
    trd.titleid, 
    trd.max_turnover, 
    trd.min_turnover, 
    trd.disparity
ORDER BY trd.disparity DESC;

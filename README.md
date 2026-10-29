# Cleaning-and-Analyzing-a-Library-Dataset-Project
This project concerns two years of synthetic data for a fictious four-branch library system; it investigates the quality of that data, validates business rules, and identifies potential opportunities to improve inventory allocation across the system.

### Tools used

I used Excel and MySQL for the data cleaning, MySQL for the analysis, and PowerBI for an interactive report that allows users to explore checkout behavior and branch-level inventory issues.

### Findings

The analysis would eventually concentrate on four main inventory questions: 

-  Which titles merited additional promotion? 
-  Which titles were candidates for additional purchase? 
-  Which titles were candidates for weeding (i.e., removal)? 
-  Where might transfers better align branches’ inventory with demand?

*These findings, of course, are based on synthetic data and are therefore greatly proscribed: In the real-world analog to this analysis, many additional factors would need to be weighed. The data furthermore suffer from limitations — and, in places, flaws — which inhibit certain analyses; these systemic issues will be addressed later. (See “Limitations,” below.)*

### Data creation

I enlisted Google Gemini to write a Python script to generate the following CSV files:​

-  Branches
-  Branch_inventory
-  Checkouts
-  Holds
-  Inventory_transfer
-  Patrons
-  Titles

This dataset — based on a series of preliminary discussions with Gemini about the underlying structures that would guide how its components should behave and interact — would initially prove an (admittedly simplified, but) satisfactorily plausible facsimile of a small, four-branch library system. (The **Checkouts** dataset, for example, contains over 250,000 individual records for the two-year time period in question.)​

However, while this synthetic data offered ample opportunity to practice data cleaning, relational analysis, and exploratory SQL, deeper dives would reveal irregularities — or, in some cases, *overly* regular behavior — that would curtail certain analytical avenues.

### Data cleaning

Among Gemini’s instructions was a request that it inject elements of “dirtiness” into the data so that the output might better reflect the sort of challenges that handling real-world data would involve.

And indeed, in the resulting dataset, I would discover the following:​

-  inconsistent capitalization in certain text fields (i.e., proper case, all caps, and all lowercase);
-  dates in non-SQL-compatible formats;
-  impossible dates (such as patron `BirthDate` fields that included 1800, 1900, and ‑1);
-  `Genre` types in the **Titles** table inconsistently written (“BIO” and “biography”; “Hist Fic” and “Historical Fiction”; etc.);
-  authors’ names in inconsistent formats (“FirstName LastName” as well as “LastName, FirstName”); and
-  title inconsistencies, which have earned their own section, below.

Each of these was addressed in the standard fashion — inconsistencies were made consistent; date formats adjusted for SQL compliance and then converted; illogical dates converted to NULLs — examples of which are included in SQL component of this report.

As irony would have it, the data’s most insidious and tenacious bit of dirtiness was not part of the original Gemini design, but an element that presumably manifested itself in the importing process from CSV to SQL.

In the process of converting the dataset’s various blank cells to NULLs for consistency’s sake, I discovered that the seemingly “blank cells” in the **Patrons** table, in fact, contained a hidden character.

I would eventually determine the stowaway was a carriage return (`CHAR(13)`) and take the necessary steps to eradicate it (more details at the link below) — having been given in the process a good reminder that the naked eye is not always one’s best tool to spot elements that may make mischief with SQL’s computations.

<details>
  
<summary>Full “hidden characters” SQL</summary>​

### Hidden characters

I realized there was an issue when the following query on one such afflicted field, “StatusChangeDate” —

```sql
UPDATE patrons
SET StatusChangeDate = NULL
WHERE TRIM(StatusChangeDate) = '';
```

— did not produce the desired effect and, instead, affected zero rows.

This investigatory query —

```sql
SELECT StatusChangeDate,
       LENGTH(StatusChangeDate),
       HEX(StatusChangeDate)
FROM patrons
WHERE LENGTH(StatusChangeDate) = 1
LIMIT 10;
```

— would elicit that the stubborn culprit was a carriage return, aka `CHAR(13)`. Having made this determination, the following cleansing process was applied:

```sql
UPDATE patrons
SET StatusChangeDate = NULL
WHERE TRIM(REPLACE(StatusChangeDate, CHAR(13), '')) = '';
```

</details>

### Title inconsistency

**An unwanted barnacle**

The **Titles** table contained a more complex issue. Despite a uniqueness check to confirm all 24,763 `Title` entries were indeed distinct strings, I discovered that there were, in fact, numerous instances of duplicate titles distinguished only by the inclusion of their “TitleID” within the `Title` field, itself. (For example, instead of “Dune”, the entry would read “Dune [Id: 20234]”. But there were also lookalikes along the lines of “Dune [Id: 10353]”, “Dune [Id:3153]”, etc.)

​My first instinct was remove these intrusions, until I realized that doing so would result in hundreds of duplicate-title groups containing titles that the system was otherwise treating as distinct entities. (To clarify: These were not intended as identifiers of multiple copies of the same title; the system was treating them as *separate* titles – an unfortunate side effect of the Python script’s limited ability to create the necessary number of unique items.)

Ultimately, to maintain the system’s functionality, I decided it was necessary to preserve the ID tags’ inclusion within the title names (and accept that, within this synthetic reality, “Dune [Id: 3153]” and “Dune [Id: 20234]” were two different books).

<details>

<summary>A note on formatting</summary>

### A note on formatting

Because, in many instances, the precise verbatim reproduction of certain book titles is necessary to illustrate particular arguments, commas and periods have been placed outside those titles’ quotation marks (despite that being inconsistent with standard American English practice) to avoid potential confusion.​

Whereas an argument could be made that, as book titles, these might better be formatted in italics rather than placed inside quotes, it seemed more appropriate — in that they are fictitious titles being discussed here specifically as strings within Excel and SQL fields — to employ quotation marks.
  
</details>

### Other issues

Lesser issues included the question of addressing all-caps and no-caps entries in the `Title` field and the process of relocating titles’ initial articles to the end of the string (e.g., converting “The Deep” to “Deep, The”). The latter concern was complicated by the aforementioned problem with ID numbers being included within the title string (e.g., converting “The Big Sleep [Id: 25000]” to “Big Sleep, The [Id: 25000]” as opposed to “Big Sleep [Id: 25000], The”).

<details>

<summary>A more detailed look at capitalization</summary>

### A close-up look at capitalization

As with such fields as `HoldStatus` in the **Holds** table, or `CardStatus` in the **Patrons** table, the `Title` field in the **Titles** table included many entries either in all caps or in all lowercase.

Unlike the `HoldStatus` and `CardStatus` fields, however — which consisted of such single-word entries as “Cancelled,” “Fulfilled,” “Active,” or “Expired” — the `Title` field, of course, regularly featured multi-word entries, which do not lend themselves as easily to the process of converting a field from no- or all-caps to “proper” capitalization.

Nor, for that matter, does MySQL even have its own `PROPER` function — which might suggest that such corrections would be better made in Excel. However, Excel’s own `PROPER` function capitalizes every word within an item, which cannot, then, accommodate the standardized capitalization format for book titles — i.e., rendering articles and prepositions in lowercase.

Which is to say, the Excel function —

`=PROPER(“ALL QUIET ON THE WESTERN FRONT”)`

— will result in “All Quiet *On The* Western Front” (emphasis mine) rather than the preferred “All Quiet on the Western Front”.

Ultimately, I decided that these capitalization inconsistencies were aesthetically unfortunate but would not have any functional negative effect and, therefore, were best left as-is, since any corrections I could apply to them would be, themselves, imperfect.

That said, there were other title formatting issues that indeed could be successfully addressed, although not without some convolutions (see below.)

**Introductory articles**

While some entries were correctly formatted to relocate any introductory article to the end of the title after a comma (e.g., “Farewell to Arms, A”), the majority were not (e.g., “The Long Goodbye”). Typical library practice shifts the article to the end so that titles can be alphabetized by their initial keyword, rather than, for example, having hundreds, if not thousands, of titles grouped under **T** because they happen to begin with “The,” or under **A** because they begin with “A.”

(I would discover that — at the whim of Google Gemini — none of the fictitious titles began with “An.”)

Relocating such articles was a straightforward enough business, but I realized that those titles that included an “[Id: XXXXX]” tag would require separate treatment.

For example, a title such as “The Wake Guide to Survival [Id: 24297]” would, were the initial article simply moved to the end and placed after a comma, be rendered “Wake Guide to Survival [Id: 24297], The”, which only adds to its tortured appearance. (And makes it appear that the ID is, in fact, part of the title.)

Clearly, if the `Title` field was stuck with this intrusive ID tag — whose removal I had decided was unwise — it should at least be located at the end of the title, rather than within it. This meant, then, that the required modification would need to render the above example as “Wake Guide to Survival, The [Id: 24297]”, necessitating a more versatile SQL query strategy to make such an accommodation.

Hesitant to embark upon such extensive modification on so many potential titles without preserving their original incarnation, I began by creating a “TitleName_Standardized” column in the **Titles** table.

I then applied the following query:

```sql
UPDATE titles
SET TitleName_Standardized =
    CASE
        WHEN TitleName_Standardized NOT LIKE '%[Id%'
        THEN
             CONCAT(
             SUBSTRING(
                TitleName_Standardized,
                5
                -- 5 = starting postition of the title after 'The '
                ),
             CASE
                WHEN BINARY TitleName_Standardized = BINARY LOWER(TitleName_Standardized)
                THEN
                   ', the'
                WHEN BINARY TitleName_Standardized = BINARY UPPER(TitleName_Standardized)
                THEN
                   ', THE'
                ELSE                  
                   ', The'
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
             CASE
                WHEN BINARY TitleName_Standardized = BINARY LOWER(TitleName_Standardized)
                THEN
                   ', the '
                WHEN BINARY TitleName_Standardized = BINARY UPPER(TitleName_Standardized)
                THEN
                   ', THE '
                ELSE                  
                   ', The '
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
```

This query took any title beginning with “The” and either moved the article to the end of the title string after a comma (in the event there was no ID tag included in the title) or moved the article to the end of the title, after a comma but before the “[Id: XXXXX]” tag, in the event that such a tag was previously included in the title.

(The query was also designed to retain the title’s original capitalization formatting. As unfortunate as the circumstances are that prevent the correction of those titles that appear in either all-caps or all-lowercase [see capitalization section, above], creating new hybrids such as “farewell to arms, A” or “BELL JAR, The” would only add additional visual distraction to the mix.)

A similarly worded such query was then also applied to perform the same conversion on those titles beginning with “A.” (As noted before, there were no such titles beginning with “An.”)

</details>

### Business-rule validation

In addition to the text-level examples of “built-in dirtiness” discussed above, the dataset also included multiple instances of business-rule issues that required consideration.

Examples included:​

-  Some **Patrons** records indicated that they had registered before the age of five; other such records indicated a `RegistrationDate` preceding their `BirthYear` entirely.
-  Some **Checkouts** records indicated a ReturnDate before the respective `CheckoutDate`.
-  Some **Holds** records included a `FulfilledDate` while the `Status` field still indicated the hold was “Active” (and not “Fulfilled”).
-  Conversely, some “Fulfilled” holds were unaccompanied by a `Fulfilled Date`.
-  Some **Inventory_transfer** records suggested a transfer being made from a branch to itself, or in a quantity of zero.

Full profiles of each of these issues can be viewed below, including explorations of potential explanations. Some cases required the creation of special categories, while others necessitated exclusion of certain criteria for various related calculations.

<details>

<summary>Business-rule validation examples</summary>

### Business-rule validation examples

​*A note on this section: The process of addressing errors that one has had a hand in creating is, to some degree, a performative act. In this project, I have endeavored to address concerns in the same way that I would have done with comparable real-world data — even though many of my investigations here could, of course, be quickly enough wrapped up with the diagnosis, “It’s this way because the dataset is synthetic.”*

**RegistrationDate < BirthYear**

One of the more prominent business-rule issues was that of numerous improbable-unto-impossible combinations found in the **Patrons** table that indicated some of the libraries’ users were as young as a single year old — nay, some even younger than that, into the negative years.

(In a follow-up discussion, Google Gemini would allow that it had failed to “enforce a floor [on the registration date] relative to the patron’s birth year — resulting in … time traveling patrons registering before being born.”)

​Unfortunately, this was no minor error. Assuming — and this is arbitrary, of course, but seems plausible based on a sampling of actual libraries — a minimum patron age requirement of five years, our synthetic dataset is left with over 1,000 records with unacceptable conflicts between their patron `RegistrationDate`s and `BirthYears`.

Of course, in a real-world scenario, one would want to investigate the source of such a chronic error, hopeful in particular to determine if the cause originates specifically with one field or the other. (In such a scenario, naturally, one would not only be seeking to fix the problem in order to preclude further such errors but also hoping perhaps to rehabilitate the flawed past data to whatever degree possible.)

​In the event of an analytics project in which the error can be traced back to a forgetful AI, we will treat it is as analogous to a real-world situation in which the source of the error is unknown and we cannot authoritatively determine whether it is the `RegistrationDate` or `BirthYear` that cannot be trusted.

​Obviously, we do not want to lose checkout data for over seven percent of our patrons, so we will retain these records but create special carve-outs in those areas (for the purposes of this report, specifically the age-group and length-of-membership categories) that would be affected by this erroneous data.

​In addition, then, to an “Unknown” category for those records with no `BirthYear` listed, we create also an “Invalid” category for those instances `WHERE YEAR(RegistrationDate) - BirthYear >= 5`.

**ReturnDate < CheckoutDate**

Another example of impossibly timed events occurred in the **Checkouts table**, which saw instances of its `ReturnDate` field pre-dating its respective `CheckoutDate` field.

Of the approximately 250,000 records in the *Checkouts* table, this anomaly appeared in about 7,400 instances — just slightly less than 3% of the time.

A profile of this phenomenon showed that, in every instance of a `ReturnDate` preceding the `CheckoutDate`, the amount of time separating the two dates ranged from one day to a maximum of 30 days. A count of the numbers of occurrences for each span (one day, two days, three days, etc.) showed them to be roughly approximate to one another, suggesting no pattern but for the fact none was longer than a month.

These discrepancies occurred consistently throughout the two-year period encompassed by the dataset. A comparison of their frequency over time showed a pattern very much in keeping with the overall checkout frequency for the same period, suggesting a recurring error that happened consistently with no discernible variation across date. (See graphs, below.)

<p align="center">
  <img src="IMAGES/ReturnDate before CheckoutDate.png" width="750">
</p>

As compared to a very similarly shaped overall checkout pattern:

<p align="center">
  <img src="IMAGES/Total Checkouts over Time.png" width="750">
</p>

Nor was there any indication that these anomalies occurred more frequently at any one branch than another: Instances of this error appeared at each branch in approximately the same proportion as each’s respective checkout level.

​The fact that the number of days separating the two dates was always fewer than 30 days initially tempted me to wonder if perhaps the “glitch” was a mere case of these `ReturnDate`s being somehow backdated a month. (Or the `CheckoutDate`s foredated the same amount.)

Eventually, however, I realized that it was precisely the 30-day maximum that argued *against* this theory, since — were one to add one month to each of the otherwise impossibly dated `ReturnDate`s — the resulting corrected dates would, in every single instance, depict the title being returned within 30 days … very much *not* in keeping with typical patron behavior, which commonly sees returns past the 30-day mark (instances of up to 80 days after checkout being not unheard of).

In a real-world situation, of course, one would want to pursue whatever additional avenues might be available — presumably engaging with the manufacturer of the relevant software for their input, for one. (A major question being, naturally, which of the two dates, return or checkout, was at issue — or if it was possible there were alternating failures between the two.)

In the case of this report, I resolved that the number of records was significant enough that I did not want to lose the non-date-related information that they contained otherwise, and I therefore decided not to eliminate them. Rather, I made a note to myself that any date-related calculations should include a criterion eliminating any instance WHERE ReturnDate <= CheckoutDate.

**FulfilledDate + “Active” status**

A not dissimilar disconnect appeared in the **Holds** table. Among this table’s fields are `HoldStatus` — whose options are “Active,” “Fulfilled,” and “Cancelled” — and a `FulfilledDate`.

In theory, those records with a date in the `FulfilledDate` field should have a corresponding `HoldStatus` of “Fulfilled.” (In turn, those records with a `HoldStatus` of “Active” would be expected to have a blank in the `FulfilledDate` field.)

However, a small handful of 2023 records — roughly 300 out of approximately 16,500 — showed a status of “Active” despite the record having a non-blank FulfilledDate. (No such instances of this anomaly appear in 2024.)

As with the previously described issue with return dates preceding checkout dates, I tracked this glitch over time and found that the frequency of its occurrence roughly conformed to overall-checkout frequency for the same period. Similarly, this phenomenon did not occur at any branch or branches in numbers that were out of keeping with similar overall-checkout ratios.

Like the `ReturnDate`/`CheckoutDate` situation, this appeared to be an anomaly that occurred regularly over time without any particular date- or location-specific tendencies. Happily, as it was a 2023-specific phenomenon, one would have been tempted — in a comparable real-world situation — to infer that whatever was the cause of the glitch resolved itself as of 1/1/2024.

Barring any input from the branches or the software-system manufacturer that would suggest otherwise, my recommendation, then, would be to treat the presence of a `FulfilledDate` as adequate indication that these instances of 2023 “Active” hold statuses can be changed to “Fulfilled.”

**“Fulfilled” status + no “FulfilledDate”**

The last such **Holds**-table-related issue — also a 2023-only phenomenon — is infrequent enough to be a footnote. Of the aforementioned 16,400 holds in 2023, there were approximately 60 occasions of the `HoldStatus` listed as “Fulfilled,” but the `FulfilledDate` being blank.

Although instances of this behavior could not be mapped neatly onto overall-checkout behavior (unlike the previous two issues, which clearly mirrored overall checkouts), the sample size was ultimately too small to support any meaningful analysis of other possible patterns.

Since a blank in the `FulfilledDate` field typically indicates that `HoldStatus` is either “Active” or “Cancelled,” it is tempting — as with the previous, similar issue — to assume that the blank date is adequate indication that the contradictory status should, in fact, be changed to “Cancelled” (since a 2023 hold could not reasonably expected to still be “Active”).

**Self-to-self Inventory_transfers**

This was another 2023-only phenomenon. Of the approximately 3,000 transfers that occurred that year, approximately 60 were recorded as having occurred from a particular branch to itself (e.g., from Branch 1 *to* Branch 1).

Analyzing the timing of such “self-transfers” suggested that — but for a single month, December 2023, which saw an unusually high number — they occurred at roughly the same frequency as regular monthly transfer totals. Likewise, there was no strong indication that any branch or branches saw an unusually higher number of such glitches than the others (although the numbers were so small as to render such judgments difficult).

Curious to see if perhaps these “glitch transfers” were connected to actual transfers — i.e., might the glitches occur in proximity to legitimate such transactions? — I investigated for instances in which the impossible transfer of a title from a branch to itself occurred within 31 days of an actual transfer of the same title.

I found nine such instances: two on the same day; four in which the glitch preceded the actual transfer; and three in which it followed. Ultimately, these numbers were not substantial enough to support a theory that there was indeed such a temporal connection between “glitch transfers” and actual transfers.

**Inventory_transfer quantity ≤ 0**

This is another 2023-centric issue. Of the approximately 3,000 transfers that occurred that year, there were roughly 60 instances in which the `Quantity` of the transfer — i.e., the number of copies transferred — was listed as zero.

While the per-branch totals of such instances did not correlate with each branch’s overall checkout figures, said totals were so small (none over 20) as to render such an imbalance statistically insignificant. (For what it was worth, overall per-month glitch totals across the branches did correlate with regular overall checkout figures.)

I ran a similar test to see if there was any notable timing proximity between instances of “zero quantity” transfers and regular transfers of the same title: Six such instances of occurrences within 31 days were noted — too few to infer any sort of connection.

Being that there were approximately the same number of these glitches as there were of the aforementioned self-branch-to-branch transfers, I immediately checked if any of the “zero quantity” transfers were from the same branch to itself: None were.

</details>

### An important structural limitation

The most significant business-rule issue to be found in this dataset was not intentionally injected by Gemini’s Python script. Instead, it is a legitimate and significant failing: There is no causal connection between the **Holds** and **Checkouts** tables.

Whereas one might reasonably expect a title whose hold status appears as “Fulfilled” to soon thereafter appear as a checkout in the **Checkouts** table, this is not the case. Disappointingly, Google Gemini’s Python script did not account for this necessary relationship.

Accordingly, the **Holds** table is largely an outlier in this project and has been invoked in only a single instance — one in which the **Holds** -> **Checkouts** cause-and-effect breakdown is moot. (See Question 4 below, “Are popular system-wide titles missing from some branches?,” in which the **Holds** table is consulted to determine whether patron interest exists for certain titles.)

### Inventory analysis / Recommendations  • Four exploratory questions

An inventory analysis determined some clear differentiations separating the branches into two distinct pairs: Branches 1 & 3 on the one hand (the Downtown and College District branches), and Branches 2 & 4 on the other (the Riverside and North Hills branches). As noted before, these distinctions would be highlighted across four primary questions.

*Of course, any real-world library system or even individual branch would have its own proprietary algorithms to make decisions in such areas as purchasing, transferring, and weeding. I am, for the sake of this “synthetic system,” selecting arbitrary criteria for the inquiries that follow.*

### 1. What existing titles might warrant additional purchase?

I applied three criteria to determine titles that a branch might want to consider making additional purchases of: a turnover ratio (i.e., checkouts / branch inventory) of at least 10.0; a hold request in the past three months; and no copies at any other branch.

<details>

<summary>Full “additional purchase” SQL</summary>

As noted — minus any real-world purchasing rules that would guide us in an actual library system — here we will use arbitrarily selected criteria: A title in need of purchase must have—​

-  a turnover ratio (i.e., checkouts / branch inventory) of at least 10.0;
-  a hold request in the past three months; and
-  no copies at any other branch.

The following SQL query will make these determinations:

```sql
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
```

Running this query sparks some interesting observations. For one, no titles are returned in the results for Branch 4. (This would suggest that it would be helpful to modify this query for individual branch use, so that the turnover-ratio criterion could be adjusted separately as need be: An example of an individual such query appears in the SQL section of this report.)

As to these particular results, though — as noted in the main report — Branch 4 (our North Hills Branch) returns zero titles, while Branch 2 (Riverside) returns 12. By contrast, our remaining branches, Downtown and College District, return 236 and 180 titles, respectively.

(A related, more basic version of this query — to simply count number of titles per branch with a turnover ratio of 10 or over — highlights the disparity even more: Branch 1 & 3 each have over 1,000 such titles, as compared to Branch 2 & 4, which each have under 200.)
  
</details>

Evaluated by these standards, Branches 1 & 3 – our Downtown and College District branches – return 236 and 180 titles, respectively, while Branch 2 (Riverside) returns 12 and Branch 4 (North Hills) returns zero titles.

​Tempting, then, to think that Branches 2 & 4 are making superior purchasing decisions, such that they have so few instances of titles seemingly in need of supplementing in their respective inventories.

**Recommendation 1: As noted previously, real-world recommendations would need to take into account such other factors as budget, replacement costs, current title availability, and branch-specific purchasing policies — i.e., details that fall outside the scope of our synthetic data.**

​**That said — within the boundaries of our synthetically generated library system — a recommendation would be made that a review be undertaken of each branch’s respective purchasing policies, specifically with an eye towards any particular practices that distinguish the Riverside and North Hills branches (Branches 2 & 4) from the Downtown and College District branches (Branches 1 & 3), to see if there are approaches that the latter might find worthy of incorporating into their own procedures.**


### 2. What titles are potential candidates for weeding?

Again, an arbitrary standard was applied here — i.e., any branch with more than two copies of a title not checked out in the past 18 months would be encouraged to make it available to any other interested branch and, otherwise, consider removing it from its inventory. (Older titles would be prioritized for such removal first.)​

<details>
  
<summary>Full “weeding” SQL</summary>  

The following query determines those titles at each branch that (a) have not been checked out in the past 18 months and (b) have more than two copies in inventory.

```sql
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
```

</details>

Interestingly, these results show a flipside to the aforementioned distinction between the Downtown and College District branches (i.e., Branches 1 & 3) and the Riverside and North Hills branches (2 & 4).

In terms of titles meeting the above criteria, Riverside and North Hills have 24 and 127 titles, respectively, while the remaining branches have only a *single* such title apiece. This would suggest that Branches 1 & 3 are the superior stewards in the art of keeping their shelves free of idle materials.

**Recommendation 2: Again, real-world considerations would of course include other factors such as whether a title was part of collection requirement. Within our system, though, we would propose that Branches 2 & 4 should consider possible removal of the older titles flagged by the above analysis and, as well, potentially consult with Branches 1 & 3 to see if any of their weeding strategies could be beneficially applied system-wide.**

### 3. Where might transfers better align branches’ inventory with demand?

To make determinations in this area, I generated turnover ratios (i.e., checkouts divided by inventory) for each title, then sought those instances with the greatest disparity in those ratios between two branches sharing said title.​

Of course, the number of titles recommended for transfer increases as the size of the required disparity decreases. (A minimum disparity requirement of 10 points provides for approximately 150 titles that might benefit from a new home.)​

<details>

<summary>Full “transfer” SQL​</summary>

The following query determines disparities between branches based on turnover ratios:​

```sql
WITH all_branch_turnover_ratio AS (
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
```

</details>

A review of these results suggests that Branches 1 & 3 are, with a single exception, inevitably the potential recipients of the proposed transfers (and that Branches 2 & 4 are the primary donors).

<p align="center">
  <img src="IMAGES/Proposed Transfers.png" width="500">
</p>

This is an additional example of where the Downtown and College District branches have been less successful at maintaining inventory rosters of potential interest to their patrons. (In addition to their having a greater number of titles in potential need for additional purchase, as compared to the Riverside and North Hill branches.)​

**Recommendation 3: As noted earlier, it would be of potential benefit for the respective branches to compare their purchasing strategies to see if — in this instance, for example, as with the aforementioned issue of additional purchasing needs — Branches 1 & 3 might benefit from applying any of their peers’ approaches in these areas.**

​**(Again, as noted with previous recommendations, a real-world scenario would assuredly need to apply a variety of other logistical considerations, as well, in addition to simply this analytic formula.)**

### 4. Are popular system-wide titles missing from some branches?

I identified 131 titles with at least 31 checkouts across the system — i.e., our fictitious small town’s most popular books for the years 2023 & 2024. Notably, Branches 2 & 4 (i.e., the Riverside and North Hills branches) were far more likely to not have, in their respective inventories, copies of the system’s “top” books.​

Whereas we would not expect any given branch’s list of most popular books to be a carbon copy of another, it is still striking that the North Hills branch (Branch 4) did not have in its inventory over *half* of these top 131 books, while the Riverside branch (Branch 2) did not possess any copies of 30% of them.​

Meanwhile, the Downtown branch (Branch 1) had all but five of these titles in their inventory, while the College District branch (Branch 3) had all but *two*.​

A check into whether patrons at these latter two branches were submitting hold requests for these titles indicated only one such instance of a hold being placed on any such book by a patron of a branch not currently stocking it.​​

<details>

<summary>Full “missing” SQL​</summary>

This query determines instances of patrons requesting holds on popular titles not available at their own branch:​

```sql
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
ORDER BY titleID ASC;
```

</details>

​​Two possibilities here spring to mind. One, that the purchasers for Branches 2 & 4 are simply very accurate predictors of their respective patrons’ interests — or lack of interest — and correctly anticipated that these titles would not be desirous to their selective audience.​

Another possibility is the “out of sight, out of mind” argument — i.e., that the patrons’ lack of interest in these titles (clearly very popular at the system’s other branches) may have been due to simple ignorance of their existence.​

**Recommendation 4: A program in which each month’s most popular books system-wide be featured in promotional material (on prominent bulletin boards, e.g.) in those branches not currently stocking said titles — with encouragement that patrons submit requests if interested. If no such interest is demonstrated on a significant level, we can lean further towards an interpretation that Branches 2 & 4 are indeed simply very adept at forecasting their patrons’ inclinations.**

### Recommendations overview

Interestingly, the system’s branches divide very neatly into pairs, each of which appears to have its own respective long & short suits.​

Branches 2 & 4 (Riverside & North Hills, respectively) seem to be meeting their patrons’ needs better overall — they have fewer titles in need of purchase and are less likely to need titles transferred to them — although they do seem surprisingly understocked of titles that are popular system-wide.​

Meanwhile, Branches 1 & 3 are in greater need of additional titles (be it via purchase or transfer), but they do seem superior at stocking “popular” books and are more fastidious about removing low-interest titles from their shelves.

### Limitations

Viewed through a glass-is-half-full perspective, this project’s synthetic dataset indeed provided me with the opportunity to practice applying a variety of analytical approaches, much as I would in real-world circumstances.​

The downside, of course, was *what* my analyses determined — i.e., the various ways, time & time again, in which this particular dataset behaved in conspicuously *non*-real-world ways.​

A lack of causal connectivity between **Holds** and **Checkouts** tables was noted earlier. Other, less serious issues included the fact that every branch-to-branch transfer recorded in the **Inventory_transfer** table was, in each instance, that of a single, solitary book — an impossibly impractical bit of logistics.​

However, the most common drawbacks to this dataset were not so much errors as repeated findings of excessive *regularity*.​

Examples — fuller explorations of which appear at the link below — included:​​

-  No seasonal variations in checkout activity across the dataset’s two-year time period
-  Near mirror-image checkout behavior from 2023 to 2024
-  Branch patron totals nearly identical
-  Patron populations by age almost identical across branches
-  Patron populations by length of membership almost identical across branches
-  Overdue book behavior largely identical across branches
-  Little distinction in genre preferences across different age groups
-  Branch inventory percentages by title age largely identical​​​​

<details>

<summary>Synthetic data issues in detail</summary>

**Limitations**

Overly regular results are not, of course, inherently a side-effect of all synthetic data, but it is certainly a common way that inadequately complex systems will reveal their limitations. A case in point, for example, was my analysis into what sort of seasonal variations we might see among the genres across the dataset’s two-year time period. (An October bump in the horror section, perhaps, one might whimsically speculate?)

As can be seen below — although the data are, at least, sophisticated enough to reflect different levels of popularity among the genres — it is not so nuanced as to suggest that each’s behavior over time is anything other than a variation on the system’s overall checkout levels.

<p align="center">
  <img src="IMAGES/Checkouts over Time by Genre.png" width="1000">
</p>

<p align="center">
  <img src="IMAGES/Total Checkouts over Time.png" width="500">
</p>


Similarly — although it is not unreasonable to think that seasonal fluctuations in checkout activity might repeat themselves from year to year — one might hope that the conformity between 2023 and 2024 be a *bit* less slavish:

<p align="center">
  <img src="IMAGES/Total Checkouts over Time _ 2023 v 2024.png" width="750">
</p>


In a similar vein, I was dismayed to find virtually all of my patrons-based analyses reaching the same conclusion — i.e., that the library system that Google Gemini had created might as well have been located in the fictitious town of Stepford (so lockstep were its residents’ behaviors with one another).

An attempt to analyze the patrons’ age breakdown by branches, for example, to see if the results might have anything interesting to tell us about each branch’s respective user demographics, showed only that — while the data at least differentiated among the various age ranges in terms of overall patron population totals — those shades of gray did not apply to the branches’ makeup, which were largely mirror images of one another:

<p align="center">
  <img src="IMAGES/Age Breakdown _ Branch 1 to 4.png" width="750">
</p>

*A note here, to bring full circle an earlier discussion — from the section about violations in the dataset’s business logic — about records that had to be excluded from certain analyses because their respective `RegistrationDate`s and `BirthYear`s were, in conjunction with one another, either illogical or impossible: These records can be see reflected — in the charts above and in a discussion below about patrons’ lengths of membership — by the category labeled “Invalid.”*

​*Note also that this is distinct from another category seen above, “Unknown,” in which the `BirthYear` was either not listed, listed as 1800 or 1900, or listed as -1. The “Invalid” category, by comparison, describes those records in which it is impossible to determine whether it is the `RegistrationDate` or the `BirthYear` that is in error (only that both cannot be correct).*

The charts above also hint at another disappointing bit of statistical monotony, i.e., that all of the branches’ overall membership totals are within 150 patrons of one another. (3658, 3794, 3733, and 3700 at Branches 1 through 4, respectively.)

Unfortunately, we also see similarly uninteresting results across the branches when we subdivide our patrons into groups according to length of library membership:

<p align="center">
  <img src="IMAGES/Branch Populations according to Time of Library Membership.png" width="750">
</p>


Other checkout-behavior analyses garnered similarly beige results. A study of overdue books finds the habit largely consisent across branches — both in the per-branch percentage of books returned late, as well as in the per-branch average of days late — as well as across genres. (Sadly, no intriguiging genre-specific factoids were to be had, say, about Travel books being more likely to come back late after accompanying their borrowers on their vacations, for example.)

Combining these various elements only produces further undistinguished findings — i.e., no particular age group more or less likely to return books late, nor any such peaks or valleys among patrons as classified by length of library membership.

​Likewise, an investigation into which genre is favored by each age group produced equally homogenous results (the undisputed favorite in every age range, from 10 & Under to Over 80: Mystery/Thriller), highlighting yet another area in which the synthetic-data design has divvied the population up into all-but-equivalent subdivisions.

​Similarly oversmooth findings result from an analysis of branches’ respective inventories in terms of title age. (Because the dataset does not contain information about titles’ purchase dates, here we are treating publication date as an equivalent.) The chart below presents an almost comically robotized breakdown in inventories by title-age range:

<p align="center">
  <img src="IMAGES/Inventory Breakdown by Title Age per Branch.png" width="750">
</p>

These, and all of the disappointingly uniform results cataloged here, only serve to remind us of how unpredictable and unruly real-life human behavior really is: There’s nothing like a batch of eerily consistent data to immediately trigger a suspicious response. (“Wait, *that* can’t be right….”)

</details>

### Next steps

This very introductory foray into the field of speculative library management offered a crash course in the wide variety of criteria that can be applied to evaluating and juggling the inventory of even a handful of branches.​

The analyses here, then, were only a very small handful of possible approaches that could be taken to such a system. A real-world equivalent, of course, would have to deal with countless specific day-to-day exigencies that would assuredly necessitate a wide assortment of ad hoc inquiries.

### What I’ve learned

This report has chronicled at length the potential hazards of employing synthetic data for the purposes to which they have been put here. Also noted has been the valuable lesson that an open-ended analytical exploration, by its nature — in fact, by its very name — runs the risk of lacking a clear endpoint: The author comes away from this endeavor with a greater understanding of the importance of some guardrails, even within a looser framework.​

I was also grateful for the opportunity to apply certain business-rule validations to the data at hand: I gained a better appreciation for the sort of causal relationships that can exist between fields — i.e., how data can be ostensibly “clean” when evaluated solely against itself, but potentially problematic when interacting illogically with other, related data (e.g., patrons returning books before checking them out or — in a far more extreme example — obtaining library cards literally before they were born).

### FULL DISCLOSURE: Some SQL queries and DAX measures employed in this project have benefited from suggestions and contributions from ChatGPT.


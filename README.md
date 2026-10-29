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

I would eventually determine the stowaway was a carriage return (CHAR(13)) and take the necessary steps to eradicate it (more details at the link below) — having been given in the process a good reminder that the naked eye is not always one’s best tool to spot elements that may make mischief with SQL’s computations.

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

— would elicit that the stubborn culprit was a carriage return, aka CHAR(13). Having made this determination, the following cleansing process was applied:

```sql
UPDATE patrons
SET StatusChangeDate = NULL
WHERE TRIM(REPLACE(StatusChangeDate, CHAR(13), '')) = '';
```

</details>

### Title inconsistency

**An unwanted barnacle**

The Titles table contained a more complex issue. Despite a uniqueness check to confirm all 24,763 Title entries were indeed distinct strings, I discovered that there were, in fact, numerous instances of duplicate titles distinguished only by the inclusion of their “TitleID” within the Title field, itself. (For example, instead of “Dune”, the entry would read “Dune [Id: 20234]”. But there were also lookalikes along the lines of “Dune [Id: 10353]”, “Dune [Id:3153]”, etc.)

​My first instinct was remove these intrusions, until I realized that doing so would result in hundreds of duplicate-title groups containing titles that the system was otherwise treating as distinct entities. (To clarify: These were not intended as identifiers of multiple copies of the same title; the system was treating them as separate titles – an unfortunate side effect of the Python script’s limited ability to create the necessary number of unique items.)

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
</details>

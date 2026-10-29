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


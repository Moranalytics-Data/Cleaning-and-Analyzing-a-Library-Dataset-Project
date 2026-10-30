/*
John G. Moran
"Cleaning and Analyzing a Library Dataset"
This project concerns two years of synthetic data for a fictious four-branch library system; 
it investigates the quality of that data, validates business rules, and 
identifies potential opportunities to improve inventory allocation across the system.
*/

-- DATA CREATION

CREATE TABLE branches(
    BranchID INT,
    BranchName VARCHAR(25) NULL,
    NeighborhoodType VARCHAR(25) NULL,
    CommunityProfile VARCHAR(50) NULL,
    OpenedYear VARCHAR(10) NULL,
    PatronCapacity INT,
    InventoryCapacity INT
);

CREATE TABLE branch_inventory(
    BranchID INT,
    TitleID INT,
    CopyCount INT
);

CREATE TABLE checkouts(
    CheckoutID VARCHAR(15) NULL,
    PatronID INT,
    BranchID INT,
    TitleID INT,
    CheckoutDate VARCHAR(10) NULL,
    DueDate VARCHAR(10) NULL,
    ReturnDate VARCHAR(10) NULL,
    RenewalCount INT
);

CREATE TABLE holds(
    HoldID VARCHAR(15) NULL,
    PatronID INT,
    BranchID INT,
    TitleID INT,
    HoldDate VARCHAR(10) NULL,
    FulfilledDate VARCHAR(10) NULL,
    HoldStatus VARCHAR(15) NULL
);

CREATE TABLE inventory_transfer(
    TransferID VARCHAR(15) NULL,
    TitleID INT, 
    FromBranchID INT,
    ToBranchID INT,
    Quantity INT,
    TransferDate VARCHAR(10) NULL
);

CREATE TABLE patrons(
    PatronID INT,
    HomeBranchID INT,
    RegistrationDate VARCHAR(10) NULL,
    BirthYear VARCHAR(10) NULL,
    ZIPCode VARCHAR(15) NULL,
    CardStatus VARCHAR(15) NULL,
    StatusChangeDate VARCHAR(10) NULL
);

CREATE TABLE titles(
    TitleID INT,
    TitleName VARCHAR(110) NULL,
    Author VARCHAR(25) NULL,
    Genre VARCHAR(20) NULL,
    SuperGenre VARCHAR(15) NULL,
    AudienceCategory VARCHAR(15) NULL,
    PublicationYear VARCHAR(10) NULL,
    Language VARCHAR(15) NULL,
    PageCount INT,
    PopularityTier VARCHAR(15) NULL,
    CanCirculate INT
);

-- Iterations of the following query were then run for each table:

LOAD DATA LOCAL INFILE 'C:/Users/johnm/CSVimports/Branches_P3B6g.csv'
INTO TABLE branches
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(BranchID,BranchName,NeighborhoodType,CommunityProfile,OpenedYear,PatronCapacity,InventoryCapacity);

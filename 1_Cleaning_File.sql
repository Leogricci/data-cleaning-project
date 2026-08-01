-- Data Cleaning

SELECT *
FROM layoffs;

-- 1. Remove Duplicates
-- 2. Standardize the Data
-- 3. Null or Blank Values
-- 4. Remove Any Unecessary Columns

# Create a copy of the data to keep an unaltered copy
CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging;

INSERT layoffs_staging
SELECT *
FROM layoffs;

-- Remove Duplicates

# Create a CTE to get companies with same name, industry, total laid off, percentage laid off, and date
WITH duplicate_cte AS
(
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
	FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

# Check that the companies are really duplicates
SELECT *
FROM layoffs_staging
WHERE company = 'Oda';
# Theyre not so we are going to compare every single variables to make sure we get only exact duplicates

# Check again
SELECT *
FROM layoffs_staging
WHERE company = 'Casper';


# create a new table to delete duplicates
CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT *
FROM layoffs_staging_2;

# Insert data from the layoffs_statiging table plus the row_num that says if there are duplicates (1 no, >= 2 yes)
INSERT INTO layoffs_staging_2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

# Delete all the rows that have a row number > 1 (duplicates)
DELETE
FROM layoffs_staging_2
WHERE row_num > 1;

# Check that they were all deleted (it worked)
SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;


-- Standardazing Data

## Remove any white spaces in company names
SELECT company, TRIM(company)
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET company = TRIM(company);

## Check the industry
SELECT DISTINCT(industry)
FROM layoffs_staging_2
ORDER BY 1;
# We see that crypto has several names, we should change that

# Retrieve all the different industry names for crypto
SELECT *
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

# Update them
UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';


## Check location and country
SELECT DISTINCT location
FROM layoffs_staging_2
ORDER BY 1;

SELECT DISTINCT country
FROM layoffs_staging_2
ORDER BY 1;
# someone entered 'United States.' we need to remove it

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_2
ORDER BY 1;

UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States_';


## Change date to date type instead of str
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

# That changes it to a proper date format
UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

# And that changes the type to a date
ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;

SELECT *
FROM layoffs_staging_2;


-- Null and blank Values

# Check where values of interest are null
SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

# Check where industry is blank or null
SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL
OR industry = '';

# Check if industry is always null for Airbnb
SELECT *
FROM layoffs_staging_2
WHERE company = 'Airbnb'; 
# Its not so we can fix it

SELECT t1.company, t1.industry, t2.industry
FROM layoffs_staging_2 AS t1
INNER JOIN layoffs_staging_2 AS t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;
# So we foun the companies that have blank industries but where the same company also has an industry somewhere else in the table

# Make blanks into null or it won't work
UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

# Then update the null industry cells and put the actual industry there
UPDATE layoffs_staging_2 AS t1
JOIN layoffs_staging_2 AS t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE(t1.industry IS NULL or t1.industry = '')
AND t2.industry IS NOT NULL;






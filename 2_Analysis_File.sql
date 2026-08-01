-- Exploratory Data Analysis

SELECT *
FROM layoffs_staging_2;

# Look at max employees laid off and max percentage
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;

# Look at companies that went completely under (percentage_laid_off = 1)
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

# Check who laid off the most
SELECT company, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY company
ORDER BY sum_laid_off DESC;

# Checking dates
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging_2;

# Check what industry got hit the most
SELECT industry, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY industry
ORDER BY sum_laid_off DESC;

# Check what country got hit the most
SELECT country, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY country
ORDER BY sum_laid_off DESC;

# When were the lay offs hapening?
SELECT YEAR(`date`), SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY YEAR(`date`)
ORDER BY sum_laid_off DESC;
# Looks like 2022 was the worst year

# What stage is the company in?
SELECT stage, SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY stage
ORDER BY sum_laid_off DESC;
# Large companies (Post-IPO) laid off the most


## Let's look at percentages
# Average percentage laid off per company
SELECT company, AVG(percentage_laid_off) AS per_laid_off
FROM layoffs_staging_2
GROUP BY company
ORDER BY per_laid_off DESC;


# Layoffs by months
SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off)
FROM layoffs_staging_2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `Month`
ORDER BY `Month` ASC;

# Create a CTE to make it into a rolling total
WITH rolling_total_cte AS
(
	SELECT SUBSTRING(`date`, 1, 7) AS `Month`, SUM(total_laid_off) AS sum_laid_off
	FROM layoffs_staging_2
	WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
	GROUP BY `Month`
	ORDER BY `Month` ASC
)

SELECT `Month`, sum_laid_off,
SUM(sum_laid_off) OVER(ORDER BY `Month`) AS rolling_total
FROM rolling_total_cte;


## Layoffs per company per year
# look at the 5 companies with most layoffs for each year
SELECT company, YEAR(`date`), SUM(total_laid_off) AS sum_laid_off
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
ORDER BY sum_laid_off DESC;

WITH company_year_cte (company, years, sum_laid_off) AS
(
	SELECT company, YEAR(`date`), SUM(total_laid_off)
	FROM layoffs_staging_2
	GROUP BY company, YEAR(`date`)
),
company_year_rank_cte AS
(
	SELECT *,
	DENSE_RANK() OVER(PARTITION BY years ORDER BY sum_laid_off DESC) AS `rank`
	FROM company_year_cte
	WHERE years IS NOT NULL
)
SELECT *
FROM company_year_rank_cte
WHERE `rank` <= 5
ORDER BY years;

## We can do the same for industry



## And other variables



-- Now let's create a copy of layoffs_staging_2 and give it a clean name for export
CREATE TABLE layoffs_clean AS
SELECT *
FROM layoffs_staging_2;

# And export it
SELECT *
FROM layoffs_clean;

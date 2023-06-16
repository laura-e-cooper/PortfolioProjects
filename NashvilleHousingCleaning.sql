/*

Cleaning data in SQL

*/

-- Initial data preview to ensure everything imported properly

SELECT *
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
LIMIT 100;

-- What I'm seeing looks good, let's count rows to ensure everything imported.

SELECT COUNT(*) AS count
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`;

/*

Standardize date format

*/

-- The main query: 

SELECT SaleDate, PARSE_DATE('%B %d, %Y', SaleDate)
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`;

-- Check work - PARSE_DATE worked, count should be same as original count of rows

SELECT COUNT(PARSE_DATE('%B %d, %Y', SaleDate)) AS date_count
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
WHERE PARSE_DATE('%b %d, %Y', SaleDate) IS NOT NULL;

-- Update data
ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN SaleDateConverted Date;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET SaleDateConverted = PARSE_DATE('%B %d, %Y', SaleDate)
WHERE SaleDateConverted IS NULL;

/* Populate Null Property Address Data */
-- ID null property addresses

SELECT *
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
WHERE PropertyAddress IS NULL;

-- can extrapolate null Property Address from other entries with matching Parcel ID but diff unique IDs

SELECT DISTINCT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress) AS extrap_address
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`AS a
JOIN `lofty-fort-277614.nashville_housing_data.NashvilleHousing`AS b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID_ <> b.UniqueID_
WHERE a.PropertyAddress IS NULL;

-- time to update - tricky syntax given the self-join 

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing` AS a
SET PropertyAddress = (
  SELECT extrap_address
  FROM (
    SELECT DISTINCT b.ParcelID, b.PropertyAddress, c.PropertyAddress AS extrap_address
    FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing` AS b
    JOIN `lofty-fort-277614.nashville_housing_data.NashvilleHousing` AS c
    ON b.ParcelID = c.ParcelID
    AND b.UniqueID_ <> c.UniqueID_
    WHERE b.PropertyAddress IS NULL
  )
  WHERE a.ParcelID = ParcelID
)
WHERE PropertyAddress IS NULL;

/* Break out property address into individual columns */

SELECT
  SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') -1) AS StreetAddress,
  SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') +2, LENGTH(PropertyAddress)) AS City
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`;

--Create a new column for street address and add the values
ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN PropertyStreetAddress string;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET PropertyStreetAddress = SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') -1)
WHERE PropertyStreetAddress IS NULL;

-- Rinse and repeat for city
ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN PropertyCity string;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET PropertyCity = SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') +2, LENGTH(PropertyAddress))
WHERE PropertyCity IS NULL;

/* Break out owner address into individual columns and add columns to table */
-- Split into fields

SELECT
  TRIM(SPLIT(OwnerAddress, ',')[OFFSET(0)]) AS OwnerStreetAddress,
  TRIM(SPLIT(OwnerAddress, ',')[OFFSET(1)]) AS OwnerCity,
  TRIM(SPLIT(OwnerAddress, ',')[OFFSET(2)]) AS OwnerState,
FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`;

-- Add column & data for owner street address:

ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN OwnerStreetAddress string;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET OwnerStreetAddress = TRIM(SPLIT(OwnerAddress, ',')[OFFSET(0)])
WHERE OwnerStreetAddress IS NULL;

-- Repeat for owner city:

ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN OwnerCity string;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET OwnerCity = TRIM(SPLIT(OwnerAddress, ',')[OFFSET(1)])
WHERE OwnerCity IS NULL;

-- Repeat again for owner state!

ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
ADD COLUMN OwnerState string;

UPDATE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
SET OwnerState = TRIM(SPLIT(OwnerAddress, ',')[OFFSET(2)])
WHERE OwnerState IS NULL;

/* Identify potential duplicate data */

WITH t1 AS (
  SELECT *, ROW_NUMBER() OVER (
    PARTITION BY
      ParcelID,
      PropertyAddress,
      SaleDate,
      LegalReference
  ) AS row_num
  FROM `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
)

SELECT *
FROM t1
WHERE row_num > 1;

/* Delete unused columns - for demonstration purposes on a backup, of course! */

ALTER TABLE `lofty-fort-277614.nashville_housing_data.NashvilleHousing`
DROP COLUMN IF EXISTS OwnerAddress,
DROP COLUMN IF EXISTS TaxDistrict,
DROP COLUMN IF EXISTS PropertyAddress,
DROP COLUMN IF EXISTS SaleDate;

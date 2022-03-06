SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

----------------------------------------------
--Standardize Date Format
SELECT SaleDateConverted, CONVERT(Date,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

-- Does not work for unknown reason
--UPDATE NashvilleHousing
--SET SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)
----------------------------------------------

--Populate Property Adress Data
--> some Property Addresses are NULL. The identical ParcelID of another row can provide information about the address.
SELECT PropertyAddress, ParcelID
FROM PortfolioProject.dbo.NashvilleHousing
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID


SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing a
JOIN PortfolioProject.dbo.NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

----------------------------
--Fix Address: seperate string into Columns for (Address, City, State)
SELECT PropertyAddress
FROM PortfolioProject.dbo.NashvilleHousing
--CHARINDEX gives a numeric value for the position of the searched value. (-1) is needed to exclude comma form the string.
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) AS Address
, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress Nvarchar(255);
UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity Nvarchar(255);
UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

---------------------
--Fix OwnerAddress
--with PARSNAME ->looks for periods. So, first REPLACE comma with periods
SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM PortfolioProject.dbo.NashvilleHousing

SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 2)
, PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing


ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitCity Nvarchar(255);
ALTER TABLE NashvilleHousing
ADD OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress,',','.'), 3)
UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress,',','.'), 2)
UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)


---------------------------------------
--Change Y and N to Yes and No for Vacant Houses
-- Case statements
SELECT SoldAsVacant, COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 1


SELECT SoldAsVacant
, CASE WHEN SoldAsVacant = 'N' THEN 'No'
	   WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'N' THEN 'No'
	   WHEN SoldAsVacant = 'Y' THEN 'Yes'
	   ELSE SoldAsVacant
	   END

---------------------------------------------
--Remove Duplicates
--ROW_NUMBER will create a number of rows for each partition. Partitions with duplicate values have rows number >1
-- CTE needed to select WHERE row_nums = 1

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (PARTITION BY 
				 ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference ORDER BY UniqueID) row_nums
FROM PortfolioProject.dbo.NashvilleHousing
--ORDER BY ParcelID
)
DELETE
FROM RowNumCTE
WHERE row_nums > 1



---------------------------------------
--Delte unused columns
SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate
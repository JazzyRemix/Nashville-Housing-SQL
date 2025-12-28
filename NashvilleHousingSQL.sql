----- Cleaning data

select *
from PortfolioProject.dbo.NashvilleHousing;


----- Standardise SaleDate into Date format

select SaleDate, convert(date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing;

alter table PortfolioProject.dbo.NashvilleHousing
add SaleDateConverted date;

update PortfolioProject.dbo.NashvilleHousing
set SaleDateConverted = convert(date, SaleDate);

select SaleDateConverted, convert(date, SaleDate)
from PortfolioProject.dbo.NashvilleHousing; -- now we have an additional col with just the date in Date format


----- Populate the Property Address data

select *
from PortfolioProject.dbo.NashvilleHousing
-- where PropertyAddress is null; -- there are null values
order by ParcelID -- many duplicates

select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;
-- for 2 rows with the same ParcelID and diff UniqueID, and with the 2nd row having null in PropertyAddress,
-- we want to populate the 2nd row with the PropertyAddress of the 1st row
-- this is done so using ISNULL(row w PropertyAddress, row to be pop. w PropertyAddress)

-- Updating the rows

update a
set PropertyAddress = isnull(a.PropertyAddress, b.PropertyAddress)
from PortfolioProject.dbo.NashvilleHousing a
join PortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is null;


----- Breaking out Address into individual columns (Address, City, State) using 2 methods

select PropertyAddress
from PortfolioProject.dbo.NashvilleHousing;

select
substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1) as Address,
substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress)) as Address
-- substring returns positions [arg2] to [arg3] in col [arg1]
-- charindex is for finding [arg1] in col [arg2]
from PortfolioProject.dbo.NashvilleHousing;

-- Adding the 2 new columns PropertySplitAddress & PropertySplitCity
-- METHOD 1 (substring)

alter table PortfolioProject.dbo.NashvilleHousing
add PropertySplitAddress nvarchar(255);

update PortfolioProject.dbo.NashvilleHousing
set PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress) - 1);

alter table PortfolioProject.dbo.NashvilleHousing
add PropertySplitCity nvarchar(255);

update PortfolioProject.dbo.NashvilleHousing
set PropertySplitCity = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, len(PropertyAddress));

select *
from PortfolioProject.dbo.NashvilleHousing; -- check to see if new cols are added

-- METHOD 2 (parsename)

select
parsename(replace(OwnerAddress, ',', '.'), 3),
parsename(replace(OwnerAddress, ',', '.'), 2),
parsename(replace(OwnerAddress, ',', '.'), 1)
from PortfolioProject.dbo.NashvilleHousing;

alter table PortfolioProject.dbo.NashvilleHousing
add OwnerSplitAddress nvarchar(255);

update PortfolioProject.dbo.NashvilleHousing
set OwnerSplitAddress = parsename(replace(OwnerAddress, ',', '.'), 3)

alter table PortfolioProject.dbo.NashvilleHousing
add OwnerSplitCity nvarchar(255);

update PortfolioProject.dbo.NashvilleHousing
set OwnerSplitCity = parsename(replace(OwnerAddress, ',', '.'), 2);

alter table PortfolioProject.dbo.NashvilleHousing
add OwnerSplitState nvarchar(255);

update PortfolioProject.dbo.NashvilleHousing
set OwnerSplitState = parsename(replace(OwnerAddress, ',', '.'), 1);

select *
from PortfolioProject.dbo.NashvilleHousing; -- check to see if new cols are added


----- Changing Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant), count(SoldAsVacant)
from PortfolioProject.dbo.NashvilleHousing
group by SoldAsVacant
order by 2;

select SoldAsVacant,
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end
from PortfolioProject.dbo.NashvilleHousing;

update PortfolioProject.dbo.NashvilleHousing
set SoldAsVacant = case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end


----- Removing duplicates
-- CTE, window function alone doesn't work

with RowNumCTE as(
select *,
	row_number() over (
	partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 order by UniqueID) row_num
from PortfolioProject.dbo.NashvilleHousing
)
select *
from RowNumCTE -- querying off the CTE (temp table) so we can do where row_num > 1 & find duplicates
where row_num > 1;
-- we select * first -> 104 duplicates
-- then delete 
-- then select * again -> 0 duplicates


----- Delete Unused columns

alter table PortfolioProject.dbo.NashvilleHousing
drop column OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;

select *
from PortfolioProject.dbo.NashvilleHousing;

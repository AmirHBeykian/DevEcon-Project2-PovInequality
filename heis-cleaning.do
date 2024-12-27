/* -----------------------------------------------------------------------
                        Import from ODBC source
-----------------------------------------------------------------------  */

clear all
* Set the working directory
// cd "C:\Users\Amir\Codes\Dev\Project2\"

* Before this, ->[ you have to set a working ODBC source on your computer ]<-
* And name it "HEIS_1402".
* First, check if the source has been made and is ready
odbc list

* See tables in the data source, and tell STATA that 
* we want to use dsn("HEIS_1402")
odbc query "HEIS_1402"

/* -----------------------------------------------------------------------
                        Data Cleaning 
-----------------------------------------------------------------------  */

* ------------------ Weights Table (R/U1402Data)-----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "R1402Data U1402Data"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")

    * Keep the desired columns
    keep Address Weight
	recast str818 Address, force

    * Generate the urban dummy variable.
    gen urban = 0 if substr("`table'", 1, 1) == "R" // 0 if Rural
    replace urban = 1 if substr("`table'", 1, 1) == "U" // 1 if Urban

    * Save to .dta file.
	* This table contains only Address, Weights and Urbanicity.
    * So we name it the "weights table".
    save "./Data/weights-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/weights-U1402Data.dta"
merge 1:1 Address using "./Data/weights-R1402Data.dta", nogenerate

* We call Address which is a unique identifier for each family, "key".
rename(Address) (key)

* In STATA, frequency weights must be integers.
gen weight_int = round(Weight)
drop Weight

* Labeling variables.
label var weight_int "Frequency Weights"
label var key "Family Unique Identifier"
label var urban "Urbanicity"

* Saving the new unified table and removing the old ones.
save "./Data/weights.dta", replace
erase "./Data/weights-R1402Data.dta"
erase "./Data/weights-U1402Data.dta"

* ------------------ Demographic Data Table (P1)-----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "R1402P1 U1402P1"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")

    * Generate the urbanity dummy variable.
    gen urban = 0 if substr("`table'", 1, 1) == "R" // 0 if Rural
    replace urban = 1 if substr("`table'", 1, 1) == "U" // 1 if Urban

    * Save to a .dta file. This table contains social and demographic data 
    * like age, marital status, etc. So we name it the "demographic table".
    save "./Data/demographic-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/demographic-U1402P1.dta"
append using "./Data/demographic-R1402P1.dta"

* Renaming columns to meaningful names.
rename(Address DYCOL01 DYCOL03 DYCOL04 DYCOL05 DYCOL06 DYCOL07 DYCOL08 ///
DYCOL09 DYCOL10) (key fkey rel gender age lit stu educ emp marr)

* The age column (F2_D07) uses "**" to denote ages >= 100.
* We set them all to 100 years.
replace age = "100" if age == "**"

* Turn all the data to numerical format.
destring fkey rel gender age lit stu educ emp marr, replace force

recode gender (2 = 0) //1->1: Male and 2->0: Female
recode stu (2 = 0) // Is currently studying? 1->1: Yes and 2->0: No 
recode lit (2 = 0) // Can read and write? 1->1: Yes and 2->0: No

// Is employed? 1->1: Yes - 2->0: No - 3,4,5,6 -> 0 Inactive
recode emp (2 = 0) (3 = 0) (4 = 0) (5 = 0) (6 = 0)

recode marr (2 = 0) (3 = 0) (4 = 0) // 1 is married and 2, 3, 4 is single.

* We turn categories to approximate years of study.
recode educ (1 = 5) (2 = 8) (3 = 11) (4 = 12) (5 = 14) (6 = 16) ///
(7 = 20) (8 = 24) (9 = .)

* Labeling variables and values.
label var urban "Urbanity Status"
label var gender "Is the Participant Male?"
label var age "Age of the Participant"
label var stu "Is Currently a Student?"
label var lit "Is Literate?"
label var educ "Years of Study"
label var marr "Marital Status"
label var rel "Relation with Head of the Household"
label var key "Family Unique Identifier"
label var fkey "Member of the Family Unique Identifier"
label var emp "Employment Status"

label define gen_lbl 1 "Male" 0 "Female"
label define stu_lbl 1 "Student" 0 "Non-Student"
label define lit_lbl 1 "Literate" 0 "Illiterate"
label define mar_lbl 1 "Married" 0 "Single"
label define urb_lbl 1 "Urban" 0 "Rural"
label define emp_lbl 1 "Employed" 0 "Unemployed"

label values gender gen_lbl
label values stu stu_lbl
label values lit lit_lbl
label values marr mar_lbl
label values urban urb_lbl
label values emp emp_lbl

* Adding frequency weights from the weights table
merge m:1 key using "./Data/weights.dta", nogenerate

* Saving the new unified table and removing the old ones.
save "./Data/00_demographic.dta", replace
erase "./Data/demographic-R1402P1.dta"
erase "./Data/demographic-U1402P1.dta"
erase "./Data/weights.dta"

* ------------------ Living Conditions Table (P2)-----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "R1402P2 U1402P2"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")

    * Keep the desired columns
	recast str818 Address, force

    * Generate the urban dummy variable.
    gen urban = 0 if substr("`table'", 1, 1) == "R" // 0 if Rural
    replace urban = 1 if substr("`table'", 1, 1) == "U" // 1 if Urban

    * Save to .dta file.
	* This table contains only Address, Weights and Urbanicity.
    * So we name it the "weights table".
    save "./Data/living-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/living-U1402P2.dta"
merge 1:1 Address using "./Data/living-R1402P2.dta", nogenerate

* We call Address which is a unique identifier for each family, "key".
rename(Address) (key)

* Labeling variables.
label var key "Family Unique Identifier"
label var urban "Urbanicity"

* Saving the new unified table and removing the old ones.
save "./Data/01_living.dta", replace
erase "./Data/living-R1402P2.dta"
erase "./Data/living-U1402P2.dta"

* ------------- Food Expenditures (P3, S01 and S02) -----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "U1402P3S01 R1402P3S01 U1402P3S02 R1402P3S02"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
        
    * Keep the desired columns
    keep Address DYCOL01 DYCOL05 DYCOL06

    * Save to a .dta file. This table contains food expenditures,
    * So we call it the "food table"
    save "./Data/food-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/food-U1402P3S01.dta"
local tables_to_append "R1402P3S01 U1402P3S02 R1402P3S02"
foreach table in `tables_to_append' {
    append using "./Data/food-`table'.dta"
    erase "./Data/food-`table'.dta"
}

* Renaming columns.
rename (Address DYCOL01 DYCOL05 DYCOL06) (key code price expd)
label var key "Family Unique Identifier"
label var code "Commodity Code"
label var price "Commodity Unit Price"
label var expd "Total Expenditure on the Commodity"

destring expd, replace

* Summing over the commodities for each family.
// collapse(sum) expd, by(key)

* Saving the new unified table and removing the old ones.
save "./Data/02_exp_food.dta", replace
erase "./Data/food-U1402P3S01.dta" 

* ------------- Housing Expenditures (P3, S04) -----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "U1402P3S04 R1402P3S04"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
        
    * Keep the desired columns
    keep Address DYCOL04

    * Save to a .dta file. This table contains housing expenditures,
    * So we call it "housing table"
    save "./Data/housing-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/housing-U1402P3S04.dta"
append using "./Data/housing-R1402P3S04.dta"

* Renaming columns.
rename (Address DYCOL04) (key expd)
label var key "Family Unique Identifier"
label var expd "Total Expenditure on the Commodity"

destring expd, replace

* Summing over the commodities for each family.
collapse(sum) expd, by(key)

* Saving the new unified table and removing the old ones.
save "./Data/exp_housing.dta", replace
erase "./Data/housing-U1402P3S04.dta" 
erase "./Data/housing-R1402P3S04.dta" 

* ------------- Other Expenditures (P3, S03-S05-...-S12) ----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "R1402P3S03 U1402P3S03 R1402P3S05 U1402P3S05 R1402P3S06 U1402P3S06 R1402P3S07 U1402P3S07 R1402P3S08 U1402P3S08 R1402P3S09 U1402P3S09 R1402P3S10 U1402P3S10 R1402P3S11 U1402P3S11 R1402P3S12 U1402P3S12"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
        
    * Keep the desired columns
    keep Address DYCOL03

    * Save to a .dta file. This table contains other expenditures,
    * So we call it the "other table"
    save "./Data/other-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/other-U1402P3S03.dta"
local tables_to_append "R1402P3S03 R1402P3S05 U1402P3S05 R1402P3S06 U1402P3S06 R1402P3S07 U1402P3S07 R1402P3S08 U1402P3S08 R1402P3S09 U1402P3S09 R1402P3S10 U1402P3S10 R1402P3S11 U1402P3S11 R1402P3S12 U1402P3S12"
foreach table in `tables_to_append' {
    append using "./Data/other-`table'.dta"
    erase "./Data/other-`table'.dta"
}

* Renaming columns.
rename (Address DYCOL03) (key expd)
label var key "Family Unique Identifier"
label var expd "Total Expenditure on the Commodity"

destring expd, replace

* Summing over the commodities for each family.
collapse(sum) expd, by(key)

* Saving the new unified table and removing the old ones.
save "./Data/exp_other.dta", replace
erase "./Data/other-U1402P3S03.dta" 

* ------------- Salary Incomes (P4, S01) ----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "U1402P4S01 R1402P4S01"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
    * Keep only the head of the household
    drop if DYCOL01 != "01"
    * Keep the desired columns
    keep Address DYCOL15

    * Save to a .dta file. This table contains salary incomes,
    * So we call it the "salary table"
    save "./Data/salary-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/salary-U1402P4S01.dta"
append using "./Data/salary-R1402P4S01.dta"

* Renaming columns.
rename (Address DYCOL15) (key net_inc)
label var key "Family Unique Identifier"
label var net_inc "Total Net Income per Year"

destring net_inc, replace

* Saving the new unified table and removing the old ones.
save "./Data/inc_salary.dta", replace
erase "./Data/salary-U1402P4S01.dta" 
erase "./Data/salary-R1402P4S01.dta" 

* ------------- Free Incomes (P4, S02) ----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "R1402P4S02 U1402P4S02"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
    * Keep only the head of the household
    drop if DYCOL01 != "01"
    * Keep the desired columns
    keep Address DYCOL15
           
    * Save to a .dta file. This table contains freelance incomes,
    * So we call it the "free table"
    save "./Data/free-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/free-U1402P4S02.dta"
append using "./Data/free-R1402P4S02.dta"

* Renaming columns.
rename (Address DYCOL15) (key net_inc)
label var key "Family Unique Identifier"
label var net_inc "Total Net Income per Year"

destring net_inc, replace

* Saving the new unified table and removing the old ones.
save "./Data/inc_free.dta", replace
erase "./Data/free-U1402P4S02.dta" 
erase "./Data/free-R1402P4S02.dta" 

* ------------- Government Payments Incomes (P4, S04) ----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "U1402P4S04 R1402P4S04"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
    * Keep only the head of the household
    drop if Dycol01 != "01"
    * Keep the desired columns
    keep Address Dycol05

    * Save to a .dta file. This table contains government-transferred incomes,
    * So we call it the "transfers table"
    save "./Data/transfers-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/transfers-U1402P4S04.dta"
append using "./Data/transfers-R1402P4S04.dta"

* Renaming columns.
rename (Address Dycol05) (key net_inc)
label var key "Family Unique Identifier"
label var net_inc "Total Net Income per Year"

destring net_inc, replace

* Saving the new unified table and removing the old ones.
save "./Data/inc_transfers.dta", replace
erase "./Data/transfers-U1402P4S04.dta" 
erase "./Data/transfers-R1402P4S04.dta" 

* ------------- Other Incomes (P4, S03) ----------------
* We loop over tables_to_save, perform data cleaning and then save to .dta files.
local tables_to_save "U1402P4S03 R1402P4S03"
foreach table in `tables_to_save' {
    clear

    * Load the table
    odbc load, table("`table'")
    * Keep only the head of the household
    drop if DYCOL01 != "01"
    * Keep the desired columns
    drop DYCOL01

    * Save to a .dta file. This table contains other incomes,
    * So we call it the "other incomes table"
    save "./Data/other_incomes-`table'.dta", replace
}

* Merging urban and rural tables into one table.
use "./Data/other_incomes-U1402P4S03.dta"
append using "./Data/other_incomes-R1402P4S03.dta"

* Renaming columns.
rename (Address DYCOL03 DYCOL04 DYCOL05 DYCOL06 DYCOL07 DYCOL08) ///
(key reti rent inv aid sell transf)
label var key "Family Unique Identifier"
label var reti "Retirement, etc."
label var rent "Rent, etc."
label var inv "Investment, etc."
label var aid "Financial Aid, etc."
label var sell "Selling Stuff, etc."
label var transf "Transfers from Other Families"

destring reti rent inv aid sell transf, replace

* Generating column total income
gen net_inc = reti + rent + inv + aid + sell + transf
label var net_inc "Total Income"

* Remove other unwanted columns
keep key net_inc

* Saving the new unified table and removing the old ones.
save "./Data/inc_other.dta", replace
erase "./Data/other_incomes-U1402P4S03.dta" 
erase "./Data/other_incomes-R1402P4S03.dta" 

/*
* -------------- Aggregating Incomes and Expenditures --------------
* Appending all categories of expenditures together
use "./Data/food"
append using "./Data/housing.dta"
append using "./Data/other.dta"

* Summing over expenditures for each family
collapse(sum) expd, by(key)

* Saving the total expenditures data set
save "./Data/total_expenditure.dta", replace

* Appending all categories of income together
use "./Data/salary"
append using "./Data/free.dta"
append using "./Data/other_incomes.dta"

* Summing over incomes for each family
collapse(sum) net_inc, by(key)

* Saving the total income data set
save "./Data/total_income.dta", replace

* Merging income, expenditure and demographic data for head of households
* together and saving the final data set.
use "./Data/total_income"
merge 1:1 key using "./Data/total_expenditure.dta", nogenerate
merge 1:1 key using "./Data/demographic_head_only.dta", nogenerate

* fkey and rel are both equal to 1 over the whole dataset because we only
* have the head of the household data. It's useless and we drop it.
drop fkey rel


* For convenience, we divide income and expenditures by 1000000 to get
* values per 10000 Rials or a thousand Tomans.
gen inc_100 = net_inc / 10000
gen expd_100 = expd / 10000
drop expd
rename (inc_100 expd_100) (inc expd)
drop net_inc

* Labeling variables and values.
label var inc "Net Income of the Household in Last Year"
label var expd "Total Expenditure of the Household"
label values gender gen_lbl
label values stu stu_lbl
label values lit lit_lbl
label values marr mar_lbl
label values urban urb_lbl
label values emp emp_lbl

save "./Data/heis_final.dta", replace

* Erasing all unwanted data sets.
local tables_to_erase "demographic_head_only food housing other salary free transfers other_incomes total_expenditure total_income weights"
foreach table in `tables_to_erase' {
    erase "./Data/`table'.dta"
}
*/
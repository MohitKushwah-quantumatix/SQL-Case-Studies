# Introduction

Rishi’s new business, DMart, is focused on selling fresh produce online.
After managing international operations, he now needs your help to review how his sales are doing.
In June 2020, DMart made a major change by switching to fully sustainable packaging—from farm to doorstep.
Rishi wants your help to understand how this change affected DMart’s sales. Specifically, he needs answers to these questions:
What was the measurable effect on sales after switching to sustainable packaging in June 2020?
Which parts of the business (like platform, region, customer segment, and customer type) were most affected?
How can DMart prepare for future sustainability changes to reduce any negative impact on sales?

### Available Data
For this case study there is only a single table: dmart.weekly_sales

![](tbl.png)

The column names mostly explain themselves, but here are a few extra details:
DMart operates internationally using a strategy that covers multiple regions.
It has two platforms: physical Offline stores and an online store.
Customer segment and customer_type are based on personal age and demographic info shared with DMart.
Transactions show the number of unique purchases, while sales represent the total rs value of those purchases.
Each row in the dataset is a weekly summary of sales, grouped by the week_date, which marks the start of that sales week.

## Data Cleansing Steps
a single query, perform the following operations and generate a new table in the dmart schema named clean_weekly_sales:

Convert the week_date to a DATE format
Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
Add a month_number with the calendar month for each week_date value as the 3rd column
Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value

![](age_band.png)

Add a new demographic column using the following mapping for the first letter in the segment values:
|segment   | demographic   |
|----------|---------------|
|C         | Couples       |
|F         | Families      |
|----------|---------------|

Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

## Data Exploration
1. What day of the week does each week_date fall on?
→ Find out which weekday (e.g., Monday, Tuesday) each sales week starts on.

2. What range of week numbers are missing from the dataset?

3. How many purchases were made in total for each year?
→ Count the total number of transactions for every year in the dataset.

4. How much was sold in each region every month?
→ Show total sales by region, broken down by month.

5. How many transactions happened on each platform?
→ Count purchases separately for the online store and the physical store.

6. What share of total sales came from Offline vs Online each month?
→ Compare the percentage of monthly sales from the physical store vs. the online store.

7. What percentage of total sales came from each demographic group each year?
→ Break down annual sales by customer demographics (e.g., age or other groupings).

8. Which age groups and demographic categories had the highest sales in physical stores?
→ Find out which age and demographic combinations contribute most to Offline-Store sales.

9. Can we use the avg_transaction column to calculate average purchase size by year and platform? If not, how should we do it?
→ Check if the avg_transaction column gives us correct yearly average sales per transaction for Offline vs Online. If it doesn't, figure out how to calculate it manually (e.g., by dividing total sales by total transactions).

### Pre-Change vs Post-Change Analysis
This technique is usually used when we inspect an important event and want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where the DMart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of the period after the change and the previous week_date values would be before

1. What is the total sales for the 4 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

2. What is the total sales for the 12 weeks pre and post 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?

3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

### Bonus Question
Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?

1. region
2. platform
3. age_band
4. demographic
5. customer_type
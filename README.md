# SQL Data Cleaning and EDA Project

This project demonstrates comprehensive data cleaning, feature engineering, and exploratory data analysis (EDA) using SQL. The dataset, focused on laptop specifications, was transformed through SQL queries to achieve a well-structured and insightful database ready for further analysis and visualization. Additionally, vertical and horizontal histograms were implemented in SQL to gain a clearer understanding of data distributions.

## Project Overview

- **Database Creation and Backup**: Created a backup table to ensure data integrity.
- **Table Structure Optimization**: Removed unnecessary columns, added an index column, and cleaned columns to enhance database structure.
- **Data Cleaning**: Addressed missing values, standardized data types, and handled inconsistencies across various columns.
- **Feature Engineering**: 
  - Extracted meaningful features from complex columns, including GPU brand, CPU brand, screen resolution, memory types, and CPU generation.
  - Converted screen size into categorical data.
  - Added new columns to calculate screen pixel density (PPI), enhancing the dataset's analytical power.
  
## Exploratory Data Analysis (EDA)

- **Summary Statistics**: Generated descriptive statistics, including mean, median, and standard deviation, as well as calculated quartiles.
- **Outlier Detection**: Identified and flagged potential outliers in the dataset based on IQR.
- **Missing Values**: Detected and replaced missing values in price based on the average price for each company and CPU type.
- **Frequency Distributions**:
  - Frequency count of categorical variables such as `Company` to understand the data spread.

## Bivariate Analysis

- **Categorical vs. Categorical Analysis**: Created contingency tables to understand relationships, such as between `Company` and `Touchscreen` presence.
- **Categorical vs. Numerical Analysis**: Examined the relationship between `Company` and `Price`, generating minimum, maximum, average, and standard deviation of prices per company.

## Advanced Feature Engineering

- **One-Hot Encoding**: Generated one-hot encoded columns for GPU brands.
- **Feature Extraction**: Isolated components within columns for a more granular analysis, such as extracting GPU brands and CPU types from composite fields.

## SQL-Based Visualization

- **Horizontal and Vertical Histograms**: Implemented price range histograms directly in SQL, providing visual insights without relying on external tools.
- **Contingency Tables and Frequency Counts**: Built for categorical analysis, giving insights into distributions and relationships in the data.

## Key SQL Techniques and Functions Used

- **Common Table Expressions (CTEs)** for modular query building.
- **Window Functions** for statistical summaries.
- **CASE Statements** for conditional transformations.
- **String Manipulation** to extract features from text data.
- **Subqueries** to perform complex feature extraction and data transformations.

## Contributions
**I welcome all meaningful contributions!**

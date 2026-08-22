# Credit Card Customer Risk Analytics | MySQL

## Project Overview

This project demonstrates an end-to-end SQL analytics workflow for a credit card portfolio. The objective is to transform raw customer, card, transaction, payment, and monthly statement data into structured insights for customer behaviour analysis and credit risk assessment.

The project covers the complete workflow from data preparation and validation to transformation, feature creation, customer segmentation, risk analysis, and final business insights.

## Project Objectives

- Validate and prepare raw datasets for analysis.
- Identify data quality issues and inconsistent records.
- Standardize and transform key attributes.
- Create derived fields and analytical features.
- Analyze customer spending and payment behaviour.
- Evaluate credit utilization and repayment patterns.
- Segment customers based on financial behaviour.
- Identify potential high-risk customers.
- Generate insights that can support portfolio and risk management decisions.

## Data Sources

The project uses five related datasets:

| Dataset | Description |
|---|---|
| `customers.xlsx` | Customer demographic and profile information |
| `credit_cards.xlsx` | Credit card and account-level details |
| `transactions.xlsx` | Customer credit card transaction records |
| `payments.xlsx` | Customer payment and repayment history |
| `monthly_statement.xlsx` | Monthly balances, statements, and account activity |

## Project Workflow

The SQL pipeline follows the sequence below:

```text
Raw Data
   ↓
Data Validation
   ↓
Data Cleaning
   ↓
Data Transformation
   ↓
Derived Columns and Features
   ↓
Data Integration
   ↓
Exploratory Analysis
   ↓
Customer Segmentation
   ↓
Credit Risk Analysis
   ↓
Business Insights

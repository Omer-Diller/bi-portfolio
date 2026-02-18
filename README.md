# bi-portfolio
BI Developer Portfolio - BigQuery SQL & Looker Studio Dashboards


## About
SQL queries and dashboards built for Walla News (walla.co.il) as part of a BI Developer role.
Data source: Google Analytics 4 events via BigQuery.

## Queries

### 1. editorial_performance_daily.sql
Incremental daily load into a summary table.
Combines data from 3 platforms: Web, Walla App, and Sport App.
Uses CTEs, UNNEST on nested GA4 event params, HLL sketches for unique user/session estimation, and UNION ALL across platforms.
Scheduled daily via BigQuery scheduled queries.

### 2. editorial_performance_view.sql
View layer on top of the daily table.
Splits multi-author fields, joins with a mapping table, and produces both daily and monthly aggregations using UNION ALL.
Used as the data source for Looker Studio dashboards.

### 3. rolling_7day_average.sql
Calculates a 7-day rolling average of page views per author.
Uses window functions (SUM OVER with RANGE BETWEEN) on daily aggregated data.

## Dashboard
Built in Google Looker Studio.
Includes: top articles per author, daily/monthly performance tables, rolling 7-day average chart.
Automatically distributed as personalized PDFs to 22 journalists on a daily schedule.

WITH base_data AS (
SELECT 
a.platform,
a.event_date,
a.item_publication_date,
a.page_type,
a.item_id,
a.item_title,
a.vertical_name,
TRIM(author_name) AS author_name, 
a.tohash,
a.total_views,
a.users_sketch,
a.sessions_sketch
FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily` a
CROSS JOIN UNNEST(SPLIT(a.item_author_provider, ',')) AS author_name
LEFT JOIN `wallabi-169712.Manual_uploads.createdBy_mapping` b
ON TRIM(a.created_by_username) = TRIM(b.username)
),

daily_agg AS (
SELECT 
  'Daily' AS report_granularity,
  platform,
  DATE_TRUNC(event_date, day) AS report_date,
  DATE_TRUNC(item_publication_date, day) AS pub_date,
  page_type,
  item_id,
  item_title,
  vertical_name,
  author_name, 
  tohash,
  SUM(total_views) AS total_views, -- שינוי כאן
  HLL_COUNT.MERGE(users_sketch) AS unique_users,
  HLL_COUNT.MERGE(sessions_sketch) AS unique_sessions
FROM base_data
GROUP BY 1,2,3,4,5,6,7,8,9,10 -- לא כולל את ה-views
),

monthly_agg AS (
SELECT 
  'Monthly' AS report_granularity,
  platform,
  DATE_TRUNC(event_date, MONTH) AS report_date,
  DATE_TRUNC(item_publication_date, MONTH) AS pub_date,
  page_type,
  item_id,
  item_title,
  vertical_name,
  author_name, 
  tohash,
  SUM(total_views) AS total_views, -- שינוי כאן
  HLL_COUNT.MERGE(users_sketch) AS unique_users,
  HLL_COUNT.MERGE(sessions_sketch) AS unique_sessions
FROM base_data
GROUP BY 1,2,3,4,5,6,7,8,9,10 -- לא כולל את ה-views
),

union_ as (
SELECT * FROM daily_agg
UNION ALL
SELECT * FROM monthly_agg
)

select * from union_
--  where author_name like '%אמיר בוחבוט%'


WITH SplitAuthors AS (
    -- פיצול הכתבים מהטבלה המוכנה
  SELECT 
    event_date,
    TRIM(author_name) AS author_name,
    total_views
  FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily`,
  UNNEST(SPLIT(item_author_provider, ',')) AS author_name
  WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 25 DAY) -- טווח רחב לחישוב הממוצע
    AND item_author_provider IS NOT NULL
),

DailyAggregated AS (
  -- סכימת צפיות יומית לכל כתב
  SELECT 
    event_date,
    author_name,
    SUM(total_views) AS total_daily_views
  FROM SplitAuthors
  WHERE author_name != ''
  GROUP BY 1,2
)

SELECT 
  event_date,
  author_name,
  total_daily_views,
  -- חישוב ממוצע נע: סכום 7 ימים חלקי 7
  ROUND(SUM(total_daily_views) OVER (
    PARTITION BY author_name 
    ORDER BY UNIX_DATE(event_date) 
    RANGE BETWEEN 6 PRECEDING AND CURRENT ROW
  ) / 7, 2) AS rolling_7_day_average
FROM DailyAggregated
WHERE event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 21 DAY) -- הצגת הטווח המבוקש
ORDER BY author_name DESC, event_date DESC

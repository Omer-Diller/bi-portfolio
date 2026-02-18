DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 05 DAY)
AND DATE_SUB(CURRENT_DATE(), INTERVAL 00 DAY);

INSERT INTO `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily` (
  platform,
  page_type,
  event_date,
  item_id,
  vertical_name,
  item_title,
  item_author_provider,
  CategoryName,
  created_by_username,
  tohash,
  item_publication_date,
  total_views,
  users_sketch,
  sessions_sketch
)

-- CREATE OR REPLACE TABLE
-- `wallabi-169712.Walla_Daily_Reports.daily_view_sport_app` AS

WITH DateRange AS (
SELECT
FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 05 DAY)) AS start_date,
FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 0 DAY)) AS end_date
),

-- ============================================================
-- WEB: נתונים גולמיים ברמת שורה בודדת
-- ============================================================
Web_Raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.event_date) AS event_date,
    t.event_timestamp,
    t.device.web_info.hostname,
    t.user_pseudo_id,
    (SELECT p.value.int_value FROM UNNEST(t.event_params) p WHERE p.key = 'ga_session_id') AS ga_session_id,
    (SELECT COALESCE(CAST(p.value.int_value AS STRING), p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_id') AS item_id,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_title') AS item_title,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'vertical_name') AS vertical_name,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'createdByUsername') AS created_by_username,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_author') AS item_author,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'content_provider') AS content_provider,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'CategoryName') AS CategoryName, 
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'tohash') AS tohash,    
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_publication_date') AS item_publication_date,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'page_location') AS pl
  FROM `wallabi-169712.analytics_341158348.events_*` t
  WHERE _TABLE_SUFFIX BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    AND t.event_name = 'page_view'
    AND (t.device.web_info.hostname IS NULL OR (ENDS_WITH(t.device.web_info.hostname, 'walla.co.il') AND NOT REGEXP_CONTAINS(t.device.web_info.hostname, r'demo|dev')))
    AND NOT REGEXP_CONTAINS(COALESCE((SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'page_location'), ''), r"mail|Mail|friends|mobile=1|hamal|push=true")
),

-- מילון פרטי אייטמים
LatestItemDetails AS (
  SELECT
    item_id,
    ANY_VALUE(item_title HAVING MAX event_timestamp) AS item_title,
    ANY_VALUE(item_author HAVING MAX event_timestamp) AS item_author,
    ANY_VALUE(content_provider HAVING MAX event_timestamp) AS content_provider,
    ANY_VALUE(CategoryName HAVING MAX event_timestamp) AS CategoryName,
    ANY_VALUE(created_by_username HAVING MAX event_timestamp) AS created_by_username,
    ANY_VALUE(tohash HAVING MAX event_timestamp) AS tohash,
    ANY_VALUE(vertical_name HAVING MAX event_timestamp) AS vertical_name,
    ANY_VALUE(item_publication_date HAVING MIN event_timestamp) AS item_publication_date
  FROM Web_Raw
  WHERE item_id IS NOT NULL
  GROUP BY 1
),

-- סיווג page_type ברמת שורה (לפני aggregation)
Web_Classified AS (
  SELECT
    r.event_date,
    r.user_pseudo_id,
    r.ga_session_id,
    r.item_id,
    r.vertical_name,
    CASE 
      WHEN r.item_id IS NULL AND r.hostname = 'www.walla.co.il' AND (r.pl = 'https://www.walla.co.il/' OR r.pl = 'https://www.walla.co.il') AND r.vertical_name = 'וואלה' THEN 'homepage'
      WHEN r.item_id IS NULL AND (r.vertical_name IS NOT NULL OR r.CategoryName IS NOT NULL) AND NOT STARTS_WITH(r.hostname, 'www.') AND REGEXP_CONTAINS(r.pl, r'^https?://[^/]+/$') THEN 'section_page'
      WHEN REGEXP_CONTAINS(r.pl, r'/break/[0-9]+($|\?)') THEN 'newsflash'
      WHEN d.tohash IS NOT NULL AND d.tohash != '' THEN 'sponsored_content'
      WHEN REGEXP_CONTAINS(r.pl, r'/item/[0-9]+($|\?)') THEN 'item'
      ELSE 'other'
    END AS page_type
  FROM Web_Raw r
  LEFT JOIN LatestItemDetails d ON r.item_id = d.item_id
),

-- FIX: aggregation נכון - GROUP BY רק על dimensions עסקיים, בלי user/session
Web_Final_Metrics AS (
  SELECT 
    'Web' AS platform,
    page_type,
    event_date,
    item_id,
    vertical_name,
    COUNT(*) AS total_views,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch,
    HLL_COUNT.INIT(CONCAT(user_pseudo_id, CAST(ga_session_id AS STRING))) AS sessions_sketch
  FROM Web_Classified
  GROUP BY platform, page_type, event_date, item_id, vertical_name
),

-- ============================================================
-- WALLA APP: עבודה ברמת שורה בודדת (בלי GROUP BY מוקדם)
-- ============================================================
Walla_App_Raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.event_date) AS event_date,
    t.user_pseudo_id,
    (SELECT p.value.int_value FROM UNNEST(t.event_params) p WHERE p.key = 'ga_session_id') AS ga_session_id,
    (SELECT COALESCE(CAST(p.value.int_value AS STRING), p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_id') AS item_id,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_type') AS item_type,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'firebase_screen_class') AS firebase_screen_class,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'vertical_name') AS vertical_name,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'push') AS push
  FROM `wallabi-169712.analytics_341158348.events_*` t   
  WHERE _TABLE_SUFFIX BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    AND t.event_name = 'screen_view'
),

Walla_App_Classified AS (
  SELECT 
    CASE 
      WHEN push = 'true' THEN 'push'
      WHEN item_id IS NULL AND vertical_name IS NULL AND firebase_screen_class = 'homepage' THEN 'homepage'
      WHEN item_id IS NULL AND vertical_name = 'homepage' AND firebase_screen_class = 'MainActivity' THEN 'homepage'
      WHEN item_id IS NULL AND vertical_name IS NOT NULL AND firebase_screen_class IN ('category', 'MainActivity') THEN 'section_page'
      WHEN item_id IS NOT NULL AND (item_type = 'newsflash' OR firebase_screen_class = 'newsflash') THEN 'newsflash'
      WHEN item_id IS NOT NULL AND (item_type != 'newsflash' OR firebase_screen_class = 'item') THEN 'item'     
      ELSE 'other'
    END AS page_type,
    event_date,
    vertical_name,
    item_id,
    user_pseudo_id,
    ga_session_id
  FROM Walla_App_Raw
),

-- FIX: aggregation נכון עם GROUP BY מתאים
Walla_App_Final_Metrics AS (
  SELECT 
    'Walla_App' AS platform,
    page_type,
    event_date,
    CAST(NULL AS STRING) AS vertical_name, 
    item_id, 
    COUNT(*) AS total_views,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch,
    HLL_COUNT.INIT(CONCAT(user_pseudo_id, CAST(ga_session_id AS STRING))) AS sessions_sketch
  FROM Walla_App_Classified 
  WHERE page_type != 'section_page'
  GROUP BY platform, page_type, event_date, item_id

  UNION ALL

  SELECT 
    'Walla_App' AS platform,
    page_type,
    event_date,
    vertical_name,
    CAST(NULL AS STRING) AS item_id, 
    COUNT(*) AS total_views,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch,
    HLL_COUNT.INIT(CONCAT(user_pseudo_id, CAST(ga_session_id AS STRING))) AS sessions_sketch
  FROM Walla_App_Classified 
  WHERE page_type = 'section_page'
  GROUP BY platform, page_type, event_date, vertical_name
),

-- ============================================================
-- SPORT APP: עבודה ברמת שורה בודדת (בלי GROUP BY מוקדם)
-- ============================================================
Sport_App_Raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.event_date) AS event_date,
    t.user_pseudo_id,
    (SELECT p.value.int_value FROM UNNEST(t.event_params) p WHERE p.key = 'ga_session_id') AS ga_session_id,
    (SELECT COALESCE(CAST(p.value.int_value AS STRING), p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_id') AS item_id,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_type') AS item_type,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'firebase_screen_class') AS firebase_screen_class,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'vertical_name') AS vertical_name,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'push') AS push
  FROM `wallabi-169712.analytics_375212362.events_*` t   
  WHERE _TABLE_SUFFIX BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    AND t.event_name = 'screen_view'
),

Sport_App_Classified AS (
  SELECT 
    CASE 
      WHEN push = 'true' OR firebase_screen_class = 'push' THEN 'push'
      WHEN item_id IS NULL AND vertical_name IS NULL AND firebase_screen_class = 'homepage' THEN 'homepage'
      WHEN item_id IS NOT NULL AND (item_type = 'newsflash' OR firebase_screen_class = 'newsflash') THEN 'newsflash'
      WHEN item_id IS NOT NULL AND (item_type != 'newsflash' OR firebase_screen_class = 'item') THEN 'item'     
      ELSE 'other'
    END AS page_type,
    event_date,
    -- שימוש ב-MAX OVER כדי למלא vertical_name לכל שורות ה-item
    MAX(vertical_name) OVER (PARTITION BY item_id) AS vertical_name,
    item_id,
    user_pseudo_id,
    ga_session_id
  FROM Sport_App_Raw
),

-- FIX: aggregation נכון עם GROUP BY
Sport_App_Final_Metrics AS (
  SELECT 
    'Sport_App' AS platform,
    page_type, 
    event_date,
    item_id, 
    vertical_name,
    COUNT(*) AS total_views,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch,
    HLL_COUNT.INIT(CONCAT(user_pseudo_id, CAST(ga_session_id AS STRING))) AS sessions_sketch
  FROM Sport_App_Classified
  GROUP BY platform, page_type, event_date, item_id, vertical_name
),

-- ============================================================
-- איחוד כל המקורות
-- ============================================================
Metrics_Union AS (
  SELECT platform, page_type, event_date, item_id, vertical_name, total_views, users_sketch, sessions_sketch FROM Web_Final_Metrics
  UNION ALL
  SELECT platform, page_type, event_date, item_id, vertical_name, total_views, users_sketch, sessions_sketch FROM Walla_App_Final_Metrics
  UNION ALL
  SELECT platform, page_type, event_date, item_id, vertical_name, total_views, users_sketch, sessions_sketch FROM Sport_App_Final_Metrics
),

-- חיבור מטא-דאטה
Final_Consolidated_Data AS (
  SELECT 
    u.platform,
    u.page_type,
    u.event_date,
    u.item_id,
    u.users_sketch,
    u.sessions_sketch,
    COALESCE(u.vertical_name, d.vertical_name) AS vertical_name, 
    d.item_title,
    COALESCE(d.item_author, d.content_provider) AS item_author_provider,
    d.CategoryName,
    d.created_by_username,
    d.tohash,
    DATE(SAFE.PARSE_DATETIME('%H:%M %d/%m/%Y', d.item_publication_date)) AS item_publication_date,
    u.total_views
  FROM Metrics_Union u
  LEFT JOIN LatestItemDetails d ON u.item_id = d.item_id
),

-- שליפה סופית
finallll as( 
SELECT 
  platform,
  page_type,
  event_date,
  item_id,
  vertical_name,
  item_title,
  item_author_provider,
  CategoryName,
  created_by_username,
  tohash,
  item_publication_date,
  SUM(total_views) AS total_views,
  HLL_COUNT.MERGE_PARTIAL(users_sketch) AS users_sketch,
  HLL_COUNT.MERGE_PARTIAL(sessions_sketch) AS sessions_sketch
FROM Final_Consolidated_Data
GROUP BY platform, page_type, event_date, item_id, vertical_name, item_title, item_author_provider, CategoryName, created_by_username, tohash, item_publication_date
)

select * from finallll
;
DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily`
WHERE event_date < DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH), MONTH);

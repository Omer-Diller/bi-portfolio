-- ============================================================
-- editorial_video_daily – טבלת וידאו ייעודית
-- מקור: Web בלבד (analytics_341158348, event_name = 'Video')
-- rolling window: 5 ימים אחרונים, מחיקה אוטומטית > 14 חודש
-- ============================================================

-- שלב 1: מחיקת 5 הימים האחרונים
DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_video_daily`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY)
  AND CURRENT_DATE();

-- שלב 2: INSERT מחדש
INSERT INTO `wallabi-169712.Walla_Daily_Reports.editorial_video_daily` (
  event_date,
  item_id,
  vertical_name,
  CategoryName,
  tohash,
  page_location,
  device_category,
  UserPlay,
  TotalAds,
  VideoProviderID,
  AdsProvider,
  is_complete,
  total_video_plays,
  users_sketch
)

WITH DateRange AS (
  SELECT
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY)) AS start_date,
    FORMAT_DATE('%Y%m%d', CURRENT_DATE())                            AS end_date
),

-- ============================================================
-- שליפת אירועי וידאו גולמיים
-- ============================================================
Video_Raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.event_date)                                                                                                         AS event_date,
    t.user_pseudo_id,
    -- פרמטרי תוכן
    (SELECT COALESCE(CAST(p.value.int_value AS STRING), p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_id')           AS item_id,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'vertical_name')                                                  AS vertical_name,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'CategoryName')                                                   AS CategoryName,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'tohash')                                                         AS tohash,
    -- פרמטרי וידאו ייחודיים
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'UserPlay')                                                       AS UserPlay,
    (SELECT p.value.int_value    FROM UNNEST(t.event_params) p WHERE p.key = 'TotalAds')                                                       AS TotalAds,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'VideoProviderID')                                                AS VideoProviderID,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'AdsProvider')                                                    AS AdsProvider,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'is_complete')                                                    AS is_complete,
    -- מיקום ומכשיר
    REGEXP_REPLACE(
      REGEXP_REPLACE(
        (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'page_location'),
        r'\?.*$', ''
      ), r'#.*$', ''
    )                                                                                                                                           AS page_location,
    t.device.category                                                                                                                           AS device_category
  FROM `wallabi-169712.analytics_341158348.events_*` t
  WHERE _TABLE_SUFFIX BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    AND t.event_name = 'Video'
    -- סינון דומיינים זהה לשאילתת ה-page_view
    AND (t.device.web_info.hostname IS NULL
         OR (ENDS_WITH(t.device.web_info.hostname, 'walla.co.il')
             AND NOT REGEXP_CONTAINS(t.device.web_info.hostname, r'demo|dev')))
),

-- ============================================================
-- אגרגציה סופית
-- GROUP BY על כל הדימנשנים הרלוונטיים
-- HLL רק על user_pseudo_id (אין session_id רלוונטי לוידאו)
-- ============================================================
Video_Aggregated AS (
  SELECT
    event_date,
    item_id,
    vertical_name,
    CategoryName,
    tohash,
    page_location,
    device_category,
    UserPlay,
    TotalAds,
    VideoProviderID,
    AdsProvider,
    is_complete,
    COUNT(*)                       AS total_video_plays,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch
  FROM Video_Raw
  GROUP BY
    event_date,
    item_id,
    vertical_name,
    CategoryName,
    tohash,
    page_location,
    device_category,
    UserPlay,
    TotalAds,
    VideoProviderID,
    AdsProvider,
    is_complete
)

SELECT * FROM Video_Aggregated;

-- ============================================================
-- שלב 3: ניקוי נתונים ישנים מעל 14 חודש
-- ============================================================
DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_video_daily`
WHERE event_date < DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 14 MONTH), MONTH);

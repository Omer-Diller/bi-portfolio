DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_video_daily`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY) AND CURRENT_DATE();

INSERT INTO `wallabi-169712.Walla_Daily_Reports.editorial_video_daily` (
  event_date,
  item_id,
  item_title,
  item_author_provider,
  vertical_name,
  CategoryName,
  tohash,
  hostname,
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
    FORMAT_DATE('%Y%m%d', DATE_SUB(CURRENT_DATE(), INTERVAL 05 DAY)) AS start_date,
    FORMAT_DATE('%Y%m%d', CURRENT_DATE())                            AS end_date
),

Video_Raw AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.event_date)                                                                                                         AS event_date,
    t.user_pseudo_id,
    t.device.web_info.hostname                                                                                                                 AS hostname,
    (SELECT COALESCE(CAST(p.value.int_value AS STRING), p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_id')           AS item_id,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'item_title')                                                     AS item_title,
    (SELECT COALESCE(p.value.string_value, p.value.string_value) FROM UNNEST(t.event_params) p WHERE p.key = 'item_author')                    AS item_author,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'content_provider')                                              AS content_provider,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'vertical_name')                                                  AS vertical_name,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'CategoryName')                                                   AS CategoryName,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'tohash')                                                         AS tohash,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'UserPlay')                                                       AS UserPlay,
    (SELECT p.value.int_value    FROM UNNEST(t.event_params) p WHERE p.key = 'TotalAds')                                                       AS TotalAds,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'VideoProviderID')                                                AS VideoProviderID,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'AdsProvider')                                                    AS AdsProvider,
    (SELECT p.value.string_value FROM UNNEST(t.event_params) p WHERE p.key = 'is_complete')                                                    AS is_complete,
    t.device.category                                                                                                                           AS device_category
  FROM `wallabi-169712.analytics_341158348.events_*` t
  WHERE _TABLE_SUFFIX BETWEEN (SELECT start_date FROM DateRange) AND (SELECT end_date FROM DateRange)
    AND t.event_name = 'Video'
    AND (t.device.web_info.hostname IS NULL
         OR (ENDS_WITH(t.device.web_info.hostname, 'walla.co.il')
             AND NOT REGEXP_CONTAINS(t.device.web_info.hostname, r'demo|dev')))
),

LatestItemDetails AS (
  SELECT
    item_id,
    ANY_VALUE(item_title       HAVING MAX event_date) AS item_title,
    ANY_VALUE(COALESCE(item_author, content_provider) HAVING MAX event_date) AS item_author_provider
  FROM Video_Raw
  WHERE item_id IS NOT NULL
  GROUP BY item_id
),

Video_Aggregated AS (
  SELECT
    r.event_date, r.item_id,
    d.item_title, d.item_author_provider,
    r.vertical_name, r.CategoryName, r.tohash,
    r.hostname, r.device_category,
    r.UserPlay, r.TotalAds, r.VideoProviderID, r.AdsProvider, r.is_complete,
    COUNT(*)                       AS total_video_plays,
    HLL_COUNT.INIT(user_pseudo_id) AS users_sketch
  FROM Video_Raw r
  LEFT JOIN LatestItemDetails d ON r.item_id = d.item_id
  GROUP BY
    r.event_date, r.item_id, d.item_title, d.item_author_provider,
    r.vertical_name, r.CategoryName, r.tohash, r.hostname,
    r.device_category, r.UserPlay, r.TotalAds, r.VideoProviderID,
    r.AdsProvider, r.is_complete
)

SELECT * FROM Video_Aggregated;

-- ניקוי נתונים ישנים מעל 14 חודש
DELETE FROM `wallabi-169712.Walla_Daily_Reports.editorial_video_daily`
WHERE event_date < DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 14 MONTH), MONTH);

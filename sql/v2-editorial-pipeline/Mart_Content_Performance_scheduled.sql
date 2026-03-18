-- ============================================================
-- Mart_Content_Performance — עדכון יומי
-- מקור: editorial_performance_daily_v2 + staff mapping + video
-- ============================================================

-- שלב 1: מחיקת 5 ימים אחרונים
DELETE FROM `wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 5 DAY)
  AND CURRENT_DATE();

-- שלב 2: INSERT מחדש
INSERT INTO `wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`
SELECT
  p.platform,
  p.page_type,
  p.event_date,
  p.item_id,
  p.item_title,
  p.item_author_provider,
  p.created_by_username,
  p.CategoryName,
  p.vertical_name,
  p.tohash,
  p.item_publication_date,
  p.device_category,
  p.device_os,
  p.page_location,
  p.traffic_source,
  p.traffic_medium,
  p.total_views,
  p.users_sketch,
  p.sessions_sketch,
  a.Main_Section    AS author_main_section,
  a.goal            AS author_daily_goal,
  e.full_name       AS editor_full_name,
  e.Main_Section    AS editor_main_section,
  e.Destination     AS editor_daily_goal,
  v.total_video_plays,
  v.UserPlay        AS user_play,
  v.is_complete,
  v.VideoProviderID AS video_provider_id,
  v.AdsProvider     AS ads_provider,
  v.TotalAds        AS total_ads,
  v.users_sketch    AS video_users_sketch

FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2` p

LEFT JOIN `wallabi-169712.Manual_uploads.item_author_mapping` a
  ON TRIM(p.item_author_provider) = TRIM(a.username)

LEFT JOIN `wallabi-169712.Manual_uploads.createdBy_mapping` e
  ON TRIM(p.created_by_username) = TRIM(e.username)

LEFT JOIN `wallabi-169712.Walla_Daily_Reports.editorial_video_daily` v
  ON p.item_id = v.item_id
 AND p.event_date = v.event_date;

-- שלב 3: ניקוי נתונים ישנים
DELETE FROM `wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`
WHERE event_date < DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 14 MONTH), MONTH);

CREATE OR REPLACE TABLE `wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`
PARTITION BY event_date AS

SELECT
  p.platform,
  p.page_type,
  p.event_date,
  p.item_id,
  p.item_title,
  p.item_author_provider,
  p.created_by_username,
  p.CategoryName,
  CASE 
    WHEN p.item_author_provider = 'אסור לפספס' THEN 'אסור לפספס'
    ELSE p.vertical_name
  END AS vertical_name,
  p.tohash,
  p.item_publication_date,
  p.device_category,
  p.device_os,
  p.hostname,
  p.traffic_source,
  p.traffic_medium,
  SUM(p.total_views)                         AS total_views,
  HLL_COUNT.MERGE_PARTIAL(p.users_sketch)    AS users_sketch,
  HLL_COUNT.MERGE_PARTIAL(p.sessions_sketch) AS sessions_sketch,
  a.Main_Section    AS author_main_section,
  a.goal            AS author_daily_goal,
  e.full_name       AS editor_full_name,
  e.Main_Section    AS editor_main_section,
  e.Destination     AS editor_daily_goal

FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2` p

LEFT JOIN `wallabi-169712.Manual_uploads.item_author_mapping` a
  ON TRIM(p.item_author_provider) = TRIM(a.username)

LEFT JOIN `wallabi-169712.Manual_uploads.createdBy_mapping` e
  ON TRIM(p.created_by_username) = TRIM(e.username)

WHERE p.vertical_name NOT IN ('כיף') OR p.vertical_name IS NULL

GROUP BY
  p.platform, p.page_type, p.event_date, p.item_id, p.item_title,
  p.item_author_provider, p.created_by_username, p.CategoryName,
  p.vertical_name, p.tohash, p.item_publication_date,
  p.device_category, p.device_os, p.hostname,
  p.traffic_source, p.traffic_medium,
  a.Main_Section, a.goal,
  e.full_name, e.Main_Section, e.Destination;

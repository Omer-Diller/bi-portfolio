CREATE OR REPLACE TABLE `wallabi-169712.Walla_Daily_Reports.Mart_Video_Performance`
PARTITION BY event_date AS

SELECT
  item_id,
  item_title,
  item_author_provider,
  vertical_name,
  CategoryName,
  tohash,
  event_date,
  hostname,
  device_category,
  UserPlay        AS user_play,
  VideoProviderID AS video_provider_id,
  AdsProvider     AS ads_provider,
  is_complete,
  SUM(TotalAds)                              AS total_ads,
  SUM(total_video_plays)                     AS total_video_plays,
  HLL_COUNT.MERGE_PARTIAL(users_sketch)      AS users_sketch
FROM `wallabi-169712.Walla_Daily_Reports.editorial_video_daily`
GROUP BY
  item_id, item_title, item_author_provider,
  vertical_name, CategoryName, tohash,
  event_date, hostname, device_category,
  UserPlay, VideoProviderID, AdsProvider, is_complete;

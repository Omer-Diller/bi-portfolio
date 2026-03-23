CREATE OR REPLACE VIEW `wallabi-169712.Walla_Daily_Reports.editorial_staff_mapping` AS
SELECT
  p.item_author_provider,   
  p.created_by_username,    
  a.Main_Section AS author_main_section,
  a.goal AS author_daily_goal,
  e.full_name AS editor_full_name,    
  e.Main_Section AS editor_main_section,   
  e.Destination AS editor_daily_goal 
FROM (
  SELECT DISTINCT
    item_author_provider,
    created_by_username
  FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2`
  WHERE item_author_provider IS NOT NULL
     OR created_by_username  IS NOT NULL
) p
LEFT JOIN `wallabi-169712.Manual_uploads.item_author_mapping` a
  ON TRIM(p.item_author_provider) = TRIM(a.username)
LEFT JOIN `wallabi-169712.Manual_uploads.createdBy_mapping` e
  ON TRIM(p.created_by_username) = TRIM(e.username)
;

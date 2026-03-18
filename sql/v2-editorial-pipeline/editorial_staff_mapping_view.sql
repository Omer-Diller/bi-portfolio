-- ============================================================
-- editorial_staff_mapping – VIEW לחיבור נתוני כותבים ועורכים
-- מקור: Manual_uploads.item_author_mapping + createdBy_mapping
-- שימוש: הסוכן עושה LEFT JOIN על editorial_performance_daily_v2
--        לפי item_author_provider ו-created_by_username
-- ============================================================

CREATE OR REPLACE VIEW `wallabi-169712.Walla_Daily_Reports.editorial_staff_mapping` AS

SELECT
  -- ============================================================
  -- מפתחות JOIN (חזרה לטבלה הראשית)
  -- ============================================================
  p.item_author_provider,    -- מתחבר עם editorial_performance_daily_v2.item_author_provider
  p.created_by_username,     -- מתחבר עם editorial_performance_daily_v2.created_by_username

  -- ============================================================
  -- נתוני כותב (author)
  -- ============================================================
  a.Main_Section             AS author_main_section,   -- מדור ראשי של הכותב
  a.goal                     AS author_daily_goal,      -- יעד יומי של הכותב

  -- ============================================================
  -- נתוני עורך (editor / createdBy)
  -- ============================================================
  e.full_name                AS editor_full_name,       -- שם מלא של העורך
  e.Main_Section             AS editor_main_section,    -- מדור ראשי של העורך
  e.Destination              AS editor_daily_goal       -- יעד יומי של העורך

FROM (
  -- בסיס: כל הצירופים הייחודיים של כותב+עורך מהטבלה הראשית
  -- כך ה-VIEW קטן וממוקד, בלי לטעון את כל הנתונים
  SELECT DISTINCT
    item_author_provider,
    created_by_username
  FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2`
  WHERE item_author_provider IS NOT NULL
     OR created_by_username  IS NOT NULL
) p

-- JOIN לנתוני כותב
LEFT JOIN `wallabi-169712.Manual_uploads.item_author_mapping` a
  ON TRIM(p.item_author_provider) = TRIM(a.username)

-- JOIN לנתוני עורך
LEFT JOIN `wallabi-169712.Manual_uploads.createdBy_mapping` e
  ON TRIM(p.created_by_username) = TRIM(e.username);


-- ============================================================
-- דוגמת שימוש לסוכן:
-- שאלה: "כמה צפיות היו לכל כותב השבוע?"
-- ============================================================
/*
SELECT
  p.item_author_provider,
  s.author_main_section,
  s.author_daily_goal,
  SUM(p.total_views)                  AS total_views,
  HLL_COUNT.MERGE(p.users_sketch)     AS unique_users,
  HLL_COUNT.MERGE(p.sessions_sketch)  AS sessions
FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2` p
LEFT JOIN `wallabi-169712.Walla_Daily_Reports.editorial_staff_mapping` s
  ON p.item_author_provider = s.item_author_provider
 AND p.created_by_username  = s.created_by_username
WHERE p.event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) AND CURRENT_DATE()
  AND p.page_type = 'item'
GROUP BY p.item_author_provider, s.author_main_section, s.author_daily_goal
ORDER BY total_views DESC;
*/

-- ============================================================
-- דוגמת שימוש לסוכן:
-- שאלה: "כמה צפיות ביחס ליעד לכל עורך היום?"
-- ============================================================
/*
SELECT
  p.created_by_username,
  s.editor_full_name,
  s.editor_main_section,
  s.editor_daily_goal,
  SUM(p.total_views)                  AS total_views,
  HLL_COUNT.MERGE(p.users_sketch)     AS unique_users,
  SAFE_DIVIDE(SUM(p.total_views), s.editor_daily_goal) * 100 AS pct_of_goal
FROM `wallabi-169712.Walla_Daily_Reports.editorial_performance_daily_v2` p
LEFT JOIN `wallabi-169712.Walla_Daily_Reports.editorial_staff_mapping` s
  ON p.item_author_provider = s.item_author_provider
 AND p.created_by_username  = s.created_by_username
WHERE p.event_date = CURRENT_DATE()
  AND p.page_type = 'item'
GROUP BY p.created_by_username, s.editor_full_name, s.editor_main_section, s.editor_daily_goal
ORDER BY total_views DESC;
*/

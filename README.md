# 📊 Omer Diller — BI Developer Portfolio

> BigQuery SQL • Looker Studio • AI-Powered Dashboards • Google Analytics 4

---

## 🚀 Projects

### 1. 🤖 Walla News — AI Analytics Dashboard
**Natural language analytics for a major Israeli news site**

An AI-powered dashboard that lets journalists and editors ask questions in Hebrew and get instant data from BigQuery — no SQL knowledge required.

**🔴 Live demo:** [walla-dynamic-dashboard.streamlit.app](https://walla-dynamic-dashboard.streamlit.app)
**💻 Code:** [analytics-walla/dynamic-dashboard](https://github.com/analytics-walla/dynamic-dashboard)
**📖 Full story:** [dashboards/walla-ai-dashboard/PROJECT_STORY.md](./dashboards/walla-ai-dashboard/PROJECT_STORY.md)

**Tech Stack:**
- Python + Streamlit (web interface)
- Google Gemini 2.5 Flash (Hebrew → SQL translation)
- Google BigQuery (data warehouse)
- Plotly (interactive charts)
- Streamlit Cloud (deployment)

**Key Features:**
- 💬 Free-text Hebrew questions → instant SQL → results
- 🧠 Context memory across questions in the same session
- 📈 Auto-generated charts for time-series data
- 📥 Excel export
- 🐛 Error reporting system with BigQuery logging

---

### 2. ⚙️ Editorial Performance Pipeline — v2
**Production-grade daily data pipeline for Walla News editorial analytics**

Automated BigQuery pipeline aggregating data from 3 platforms (Web, Walla App, Sport App) into a single analytics-ready MART table, updated daily via Scheduled Queries.

**Highlights:**
- HLL sketches for fast & scalable unique user/session estimation
- Multi-platform UNION ALL (Web GA4 + Firebase App)
- Incremental 5-day rolling window to handle late-arriving data
- Joined with staff mapping for author/editor goals and performance tracking

**📂 See:** [`sql/v2-editorial-pipeline/`](./sql/v2-editorial-pipeline/)

---

### 3. 📐 Editorial Performance Pipeline — v1
**Original pipeline (legacy)**

The first version of the editorial pipeline, built before HLL sketches and multi-platform support were introduced.

**📂 See:** [`sql/v1-editorial-pipeline/`](./sql/v1-editorial-pipeline/)

---

## 🗂️ Repository Structure

```
bi-portfolio/
├── README.md
├── sql/
│   ├── v1-editorial-pipeline/
│   │   ├── editorial_performance_daily.sql      ← Original daily pipeline
│   │   ├── editorial_performance_view.sql        ← Original staff view
│   │   └── rolling_7day_average.sql              ← Rolling average query
│   └── v2-editorial-pipeline/
│       ├── editorial_performance_daily_v2.sql    ← Multi-platform pipeline (HLL)
│       ├── editorial_staff_mapping_view.sql       ← Author & editor mapping VIEW
│       ├── editorial_video_daily.sql              ← Video analytics pipeline
│       ├── Mart_Content_Performance_CREATE.sql    ← One-time MART table creation
│       └── Mart_Content_Performance_scheduled.sql ← Daily scheduled update
├── dashboards/
│   └── walla-ai-dashboard/
│       ├── app.py                                ← Main dashboard code
│       ├── requirements.txt                      ← Python dependencies
│       └── PROJECT_STORY.md                      ← Full project documentation
└── screenshots/
    ├── looker-studio-dashboard/                  ← Looker Studio screenshots
    └── walla-ai-dashboard/                       ← AI Dashboard screenshots
```

---

## 🛠️ Technical Skills Demonstrated

| Skill | Where |
|-------|--------|
| BigQuery SQL (CTEs, UNNEST, HLL, Window Functions) | `sql/` |
| GA4 event data processing | `editorial_performance_daily_v2.sql` |
| HLL sketches for unique user estimation | `v2-editorial-pipeline/` |
| Multi-platform data pipeline (Web + App) | `editorial_performance_daily_v2.sql` |
| Python (Streamlit, Pandas, Plotly) | `app.py` |
| Prompt Engineering (Hebrew NLP → SQL) | `app.py` |
| Cloud deployment (Streamlit Cloud) | `PROJECT_STORY.md` |
| Google Cloud (BigQuery, Service Accounts, IAM) | `PROJECT_STORY.md` |
| Git version control | This repository |

---

## 📬 Contact

**Omer Diller** — BI Developer | Walla News Analytics

---
---

# 📊 עומר דילר — תיק עבודות BI

> BigQuery SQL • Looker Studio • דשבורדים מבוססי AI • Google Analytics 4

---

## 🚀 פרויקטים

### 1. 🤖 וואלה — דשבורד AI לניתוח נתונים
**שאלות בשפה טבעית לאתר חדשות מוביל בישראל**

דשבורד מבוסס AI שמאפשר לעיתונאים ועורכים לשאול שאלות בעברית ולקבל נתונים מ-BigQuery בזמן אמת — ללא ידע ב-SQL.

**🔴 דמו חי:** [walla-dynamic-dashboard.streamlit.app](https://walla-dynamic-dashboard.streamlit.app)
**💻 קוד:** [analytics-walla/dynamic-dashboard](https://github.com/analytics-walla/dynamic-dashboard)
**📖 סיפור הפרויקט:** [dashboards/walla-ai-dashboard/PROJECT_STORY.md](./dashboards/walla-ai-dashboard/PROJECT_STORY.md)

**טכנולוגיות:**
- Python + Streamlit (ממשק משתמש)
- Google Gemini 2.5 Flash (תרגום עברית → SQL)
- Google BigQuery (מסד נתונים)
- Plotly (גרפים אינטראקטיביים)
- Streamlit Cloud (פריסה בענן)

**יכולות מרכזיות:**
- 💬 שאלות חופשיות בעברית → SQL → תוצאות מיידיות
- 🧠 זיכרון הקשר בין שאלות באותה שיחה
- 📈 גרפים אוטומטיים לנתוני זמן
- 📥 ייצוא לאקסל
- 🐛 מערכת דיווח טעויות עם לוגים ב-BigQuery

---

### 2. ⚙️ פייפליין ביצועי מערכת — v2
**פייפליין נתונים יומי לאנליטיקס עיתונאי — גרסה מתקדמת**

פייפליין אוטומטי ב-BigQuery שמאגרג נתונים מ-3 פלטפורמות (Web, אפליקציית וואלה, אפליקציית ספורט) לטבלת MART אחת, מתעדכן יומית.

**נקודות מרכזיות:**
- HLL sketches לאמידה מהירה ומדויקת של גולשים וסשנים ייחודיים
- UNION ALL רב-פלטפורמי (Web GA4 + Firebase App)
- חלון 5 ימים אינקרמנטלי לטיפול בנתונים מאוחרים
- JOIN לנתוני כותבים ועורכים עם יעדים ומדדי ביצוע

**📂 ראה:** [`sql/v2-editorial-pipeline/`](./sql/v2-editorial-pipeline/)

---

### 3. 📐 פייפליין ביצועי מערכת — v1
**הגרסה הראשונה של הפייפליין (ישן)**

הגרסה המקורית שנבנתה לפני מעבר ל-HLL ותמיכה רב-פלטפורמית.

**📂 ראה:** [`sql/v1-editorial-pipeline/`](./sql/v1-editorial-pipeline/)

---

## 🗂️ מבנה ה-Repository

```
bi-portfolio/
├── README.md
├── sql/
│   ├── v1-editorial-pipeline/
│   │   ├── editorial_performance_daily.sql      ← פייפליין יומי מקורי
│   │   ├── editorial_performance_view.sql        ← VIEW מקורי לכותבים/עורכים
│   │   └── rolling_7day_average.sql              ← ממוצע נע 7 ימים
│   └── v2-editorial-pipeline/
│       ├── editorial_performance_daily_v2.sql    ← פייפליין רב-פלטפורמי (HLL)
│       ├── editorial_staff_mapping_view.sql       ← VIEW לכותבים ועורכים
│       ├── editorial_video_daily.sql              ← פייפליין וידאו
│       ├── Mart_Content_Performance_CREATE.sql    ← יצירת טבלת MART (חד פעמי)
│       └── Mart_Content_Performance_scheduled.sql ← עדכון יומי אוטומטי
├── dashboards/
│   └── walla-ai-dashboard/
│       ├── app.py                                ← קוד הדשבורד המלא
│       ├── requirements.txt                      ← חבילות Python
│       └── PROJECT_STORY.md                      ← תיעוד מלא של הפרויקט
└── screenshots/
    ├── looker-studio-dashboard/                  ← צילומי Looker Studio
    └── walla-ai-dashboard/                       ← צילומי דשבורד ה-AI
```

---

## 🛠️ מיומנויות טכניות

| מיומנות | איפה |
|---------|------|
| BigQuery SQL (CTEs, UNNEST, HLL, Window Functions) | תיקיית `sql/` |
| עיבוד נתוני GA4 | `editorial_performance_daily_v2.sql` |
| HLL sketches לאמידת גולשים ייחודיים | `v2-editorial-pipeline/` |
| פייפליין רב-פלטפורמי (Web + App) | `editorial_performance_daily_v2.sql` |
| Python (Streamlit, Pandas, Plotly) | `app.py` |
| Prompt Engineering (עברית → SQL) | `app.py` |
| פריסה בענן (Streamlit Cloud) | `PROJECT_STORY.md` |
| Google Cloud (BigQuery, Service Accounts, IAM) | `PROJECT_STORY.md` |
| Git | ה-repository הזה |

---

## 📬 יצירת קשר

**עומר דילר** — מפתח BI | אנליטיקס וואלה

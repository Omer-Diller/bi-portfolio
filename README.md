# 📊 Omer Diller — BI Developer Portfolio

> BigQuery SQL • Looker Studio • AI-Powered Dashboards • Google Analytics 4

---

## 🚀 Projects

### 1. Walla News — AI Analytics Dashboard
**Natural language analytics for a major Israeli news site**

An AI-powered dashboard that lets journalists and editors ask questions in Hebrew and get instant data from BigQuery — no SQL knowledge required.

**Live demo:** [walla-dynamic-dashboard.streamlit.app](https://walla-dynamic-dashboard.streamlit.app)  
**Code:** [analytics-walla/dynamic-dashboard](https://github.com/analytics-walla/dynamic-dashboard)

**Tech Stack:**
- Python + Streamlit (web interface)
- Google Gemini 2.5 Flash (Hebrew → SQL translation)
- Google BigQuery (data warehouse)
- Plotly (interactive charts)
- Streamlit Cloud (deployment)

**Key Features:**
- Free-text Hebrew questions → instant SQL → results
- Context memory across questions in same session
- Auto-generated charts for time-series data
- Excel export
- Error reporting system with BigQuery logging

---

### 2. Editorial Performance Pipeline
**Daily data pipeline for Walla News editorial analytics**

Automated BigQuery pipeline aggregating data from 3 platforms (Web, Walla App, Sport App) into a single analytics-ready MART table, updated daily via Scheduled Queries.

**Highlights:**
- HLL sketches for fast unique user/session estimation at scale
- Multi-platform UNION ALL (Web GA4 + Firebase App)
- Incremental 5-day rolling window to handle late-arriving data
- Joined with staff mapping for author/editor goals and performance tracking

**See:** [`sql/`](./sql/) folder

---

### 3. Rolling 7-Day Average
**Window function query for trend analysis**

Calculates a 7-day rolling average of page views per author using BigQuery window functions.

**See:** [`sql/rolling_7day_average.sql`](./sql/rolling_7day_average.sql)

---

## 🗂️ Repository Structure

```
bi-portfolio/
├── README.md
├── sql/
│   ├── editorial_performance_daily_v2.sql     ← Daily aggregation pipeline
│   ├── editorial_staff_mapping_view.sql        ← Staff mapping VIEW
│   ├── editorial_video_daily.sql               ← Video analytics pipeline
│   ├── Mart_Content_Performance.sql            ← Final MART table
│   └── rolling_7day_average.sql                ← Rolling average query
├── dashboards/
│   └── walla-ai-dashboard/
│       ├── app.py                              ← Main dashboard code
│       ├── requirements.txt                    ← Python dependencies
│       └── PROJECT_STORY.md                    ← Full project documentation
└── screenshots/
    └── dashboard_demo.png
```

---

## 🛠️ Technical Skills Demonstrated

| Skill | Where |
|-------|--------|
| BigQuery SQL (CTEs, UNNEST, HLL, Window Functions) | `sql/` folder |
| GA4 event data processing | `editorial_performance_daily_v2.sql` |
| HLL sketches for unique user estimation | `sql/` folder |
| Multi-platform data pipeline (Web + App) | `editorial_performance_daily_v2.sql` |
| Python (Streamlit, Pandas, Plotly) | `app.py` |
| Prompt Engineering (Hebrew NLP → SQL) | `app.py` SCHEMA section |
| Cloud deployment (Streamlit Cloud) | `PROJECT_STORY.md` |
| Google Cloud (BigQuery, Service Accounts, IAM) | `PROJECT_STORY.md` |
| Git version control | This repository |

---

## 📬 Contact

**Omer Diller** — BI Developer  
Walla News Analytics

---
---

# 📊 עומר דילר — תיק עבודות BI

> BigQuery SQL • Looker Studio • דשבורדים מבוססי AI • Google Analytics 4

---

## 🚀 פרויקטים

### 1. וואלה — דשבורד AI לניתוח נתונים
**שאלות בשפה טבעית לאתר חדשות מוביל בישראל**

דשבורד מבוסס AI שמאפשר לעיתונאים ועורכים לשאול שאלות בעברית ולקבל נתונים מ-BigQuery בזמן אמת — ללא ידע ב-SQL.

**דמו:** [walla-dynamic-dashboard.streamlit.app](https://walla-dynamic-dashboard.streamlit.app)  
**קוד:** [analytics-walla/dynamic-dashboard](https://github.com/analytics-walla/dynamic-dashboard)

**טכנולוגיות:**
- Python + Streamlit (ממשק משתמש)
- Google Gemini 2.5 Flash (תרגום עברית → SQL)
- Google BigQuery (מסד נתונים)
- Plotly (גרפים אינטראקטיביים)
- Streamlit Cloud (פריסה בענן)

**יכולות מרכזיות:**
- שאלות חופשיות בעברית → SQL → תוצאות מיידיות
- זיכרון הקשר בין שאלות באותה שיחה
- גרפים אוטומטיים לנתוני זמן
- ייצוא לאקסל
- מערכת דיווח טעויות עם לוגים ב-BigQuery

---

### 2. פייפליין ביצועי מערכת
**פייפליין נתונים יומי לאנליטיקס עיתונאי**

פייפליין אוטומטי ב-BigQuery שמאגרג נתונים מ-3 פלטפורמות (Web, אפליקציית וואלה, אפליקציית ספורט) לטבלת MART אחת, מתעדכן יומית.

**נקודות מרכזיות:**
- HLL sketches לאמידה מהירה של גולשים וסשנים ייחודיים בנתונים גדולים
- UNION ALL רב-פלטפורמי (Web GA4 + Firebase App)
- חלון 5 ימים אינקרמנטלי לטיפול בנתונים מאוחרים
- JOIN לנתוני כותבים ועורכים עם יעדים ומדדי ביצוע

**ראה:** תיקיית [`sql/`](./sql/)

---

### 3. ממוצע נע 7 ימים
**שאילתת Window Function לניתוח מגמות**

חישוב ממוצע נע של 7 ימים לצפיות לפי כתב באמצעות Window Functions של BigQuery.

**ראה:** [`sql/rolling_7day_average.sql`](./sql/rolling_7day_average.sql)

---

## 🗂️ מבנה ה-Repository

```
bi-portfolio/
├── README.md
├── sql/
│   ├── editorial_performance_daily_v2.sql     ← פייפליין אגרגציה יומי
│   ├── editorial_staff_mapping_view.sql        ← VIEW לנתוני כותבים/עורכים
│   ├── editorial_video_daily.sql               ← פייפליין אנליטיקס וידאו
│   ├── Mart_Content_Performance.sql            ← טבלת MART סופית
│   └── rolling_7day_average.sql                ← שאילתת ממוצע נע
├── dashboards/
│   └── walla-ai-dashboard/
│       ├── app.py                              ← קוד הדשבורד המלא
│       ├── requirements.txt                    ← חבילות Python
│       └── PROJECT_STORY.md                    ← תיעוד מלא של הפרויקט
└── screenshots/
    └── dashboard_demo.png
```

---

## 🛠️ מיומנויות טכניות

| מיומנות | איפה |
|---------|------|
| BigQuery SQL (CTEs, UNNEST, HLL, Window Functions) | תיקיית `sql/` |
| עיבוד נתוני GA4 | `editorial_performance_daily_v2.sql` |
| HLL sketches לאמידת גולשים ייחודיים | תיקיית `sql/` |
| פייפליין רב-פלטפורמי (Web + App) | `editorial_performance_daily_v2.sql` |
| Python (Streamlit, Pandas, Plotly) | `app.py` |
| Prompt Engineering (עברית → SQL) | קטע SCHEMA ב-`app.py` |
| פריסה בענן (Streamlit Cloud) | `PROJECT_STORY.md` |
| Google Cloud (BigQuery, Service Accounts, IAM) | `PROJECT_STORY.md` |
| Git | ה-repository הזה |

---

## 📬 יצירת קשר

**עומר דילר** — מפתח BI  
אנליטיקס וואלה

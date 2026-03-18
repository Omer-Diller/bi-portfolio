# 📖 Walla AI Dashboard — מדריך מלא
## איך בניתי דשבורד AI לניתוח נתונים בשפה טבעית — מהרעיון ועד הפרסום

---

## 🎯 הבעיה שפתרתי

עיתונאים ועורכים בוואלה רצו לדעת כמה צפיות הייתה לכתבה שלהם, מי עמד ביעד, ואילו מדורים מובילים — אבל לא ידעו SQL.

**לפני:** צריך איש BI שיכתוב שאילתה → מחכים → מקבלים קובץ אקסל  
**אחרי:** כותבים שאלה בעברית → מקבלים תשובה תוך שניות

---

## 🏗️ ארכיטקטורה

```
שאלה בעברית (משתמש)
        ↓
Gemini 2.5 Flash (מתרגם לSQL)
        ↓
BigQuery — Mart_Content_Performance
        ↓
Streamlit (מציג טבלה + גרף)
        ↓
תשובה למשתמש
```

---

## 📦 שלב 1 — התקנת הסביבה

### Python
```bash
# התקן Python מ-python.org
python --version  # לוודא שעובד
```

### חבילות נדרשות
```bash
pip install streamlit google-cloud-bigquery google-generativeai plotly pandas openpyxl python-dotenv
```

### קובץ .env (מפתחות סודיים)
```
GEMINI_API_KEY=AIza...
```
⚠️ **אל תעלה קובץ זה ל-GitHub!** — מוגן ע"י `.gitignore`

### חיבור BigQuery (מחשב מקומי)
```bash
gcloud auth application-default login
```

---

## 📊 שלב 2 — בניית הנתונים ב-BigQuery

### המבנה

```
editorial_performance_daily_v2   ← טבלת בסיס (Web + Walla App + Sport App)
        +
editorial_staff_mapping          ← VIEW לכותבים ועורכים
        +
editorial_video_daily            ← נתוני וידאו
        ↓
Mart_Content_Performance         ← טבלת MART — הכל במקום אחד
```

### למה MART?
- ✅ שאילתות פשוטות — ה-AI לא צריך לעשות JOINs
- ✅ ביצועים טובים יותר
- ✅ אין בעיות הרשאות של External Tables

### יצירת הטבלאות — הסדר הנכון
```sql
-- 1. טבלת בסיס
-- הרץ: editorial_performance_daily_v2.sql

-- 2. VIEW לכותבים/עורכים
-- הרץ: editorial_staff_mapping_view.sql

-- 3. וידאו
-- הרץ: editorial_video_daily.sql

-- 4. MART
-- הרץ: Mart_Content_Performance.sql (החלק CREATE OR REPLACE)
```

### Scheduled Query — עדכון יומי
ב-BigQuery Console → Scheduled Queries → Create:
- **שם:** Mart_Content_Performance_Daily
- **זמן:** 06:00 כל יום
- **SQL:** החלק DELETE + INSERT מ-Mart_Content_Performance.sql

### HLL Sketches — חישוב גולשים ייחודיים
```sql
-- ❌ ישן — COUNT DISTINCT (איטי, לא מתאים לנתונים גדולים)
COUNT(DISTINCT user_pseudo_id)

-- ✅ חדש — HLL (מהיר, מדויק לניתוח עסקי)
HLL_COUNT.MERGE(users_sketch)
HLL_COUNT.MERGE(sessions_sketch)
```

---

## 💻 שלב 3 — בניית האפליקציה

### קובץ: app.py

**מבנה הקוד:**
```python
# 1. הגדרות — API keys, חיבור BigQuery
# 2. SCHEMA — מפת הנתונים ל-AI
# 3. פונקציות — שאילתות, גרפים, דיווח טעויות
# 4. ממשק Streamlit — צ'אט, היסטוריה, עיצוב
```

### ה-SCHEMA — הלב של הפרויקט
```python
SCHEMA = """
טבלה ראשית: `wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`

כללים קריטיים:
- צפיות = SUM(total_views)
- גולשים = HLL_COUNT.MERGE(users_sketch)
- סשנים = HLL_COUNT.MERGE(sessions_sketch)
- אל תוסיף סינונים שלא נאמרו במפורש!
...
"""
```

**למה SCHEMA חשוב?**
ה-AI לא יודע את מבנה הנתונים שלך. ה-SCHEMA הוא ה"הוראות" שמסבירות לו איך לכתוב SQL נכון.

### זרימת שאלה-תשובה
```python
def ask_data(question, history):
    # 1. בנה prompt עם SCHEMA + היסטוריה
    prompt = f"SCHEMA: {SCHEMA}\nשאלה: {question}"
    
    # 2. שלח ל-Gemini
    response = client_ai.models.generate_content(prompt)
    sql = clean_sql(response.text)
    
    # 3. הרץ ב-BigQuery
    df = client_bq.query(sql).to_dataframe()
    
    return sql, df
```

### מערכת דיווח טעויות
```python
# המשתמש לוחץ 👎 → הדיווח נשמר ב-BigQuery
def save_correction(question, sql, feedback):
    row = {
        "correction_date": datetime.utcnow().isoformat(),
        "topic": "דיווח משתמש",
        "rule": feedback[:500],
        "reason": f"SQL: {sql[:200]}",
        "example_question": question[:500]
    }
    client_bq.insert_rows_json("...AI_Corrections", [row])
```

### הרצה מקומית
```bash
python -m streamlit run app.py
# פתח דפדפן: http://localhost:8501
```

---

## 🚀 שלב 4 — פרסום ב-Streamlit Cloud

### GitHub — העלאת הקוד

```bash
# אתחול
git init
git remote add origin https://github.com/analytics-walla/dynamic-dashboard.git

# העלאה
git add app.py requirements.txt
git commit -m "first commit"
git branch -M main
git push -u origin main
```

**חשוב:** `.gitignore` מונע העלאת קבצים רגישים:
```gitignore
.env
__pycache__/
*.json
```

### Streamlit Cloud

1. לך ל-[share.streamlit.io](https://share.streamlit.io)
2. התחבר עם GitHub
3. בחר repo: `analytics-walla/dynamic-dashboard`
4. Main file: `app.py`
5. **Advanced Settings → Secrets:**
```toml
GEMINI_API_KEY = "AIza..."

[gcp_service_account]
type = "service_account"
project_id = "wallabi-169712"
private_key = "-----BEGIN PRIVATE KEY-----..."
client_email = "streamlit-dashboard@wallabi-169712.iam.gserviceaccount.com"
...
```

### Service Account — גישה ל-BigQuery מהענן

1. Google Cloud Console → IAM → Service Accounts
2. צור: `streamlit-dashboard`
3. תפקידים: `BigQuery Data Viewer` + `BigQuery Job User` + `BigQuery Data Editor`
4. צור JSON key → הכנס ל-Streamlit Secrets

### קוד לקריאת credentials
```python
if "gcp_service_account" in st.secrets:
    credentials = service_account.Credentials.from_service_account_info(
        st.secrets["gcp_service_account"]
    )
    client_bq = bigquery.Client(project=PROJECT_ID, credentials=credentials)
else:
    client_bq = bigquery.Client(project=PROJECT_ID)  # מחשב מקומי
```

### אבטחה
**Manage app → Settings → Sharing → Only specific people**
הוסף מיילים של המשתמשים המורשים — כולם נכנסים עם Google.

---

## 🔄 שלב 5 — עדכון קוד (workflow יומיומי)

```bash
# 1. ערוך קוד ב-VS Code
# 2. שמור Ctrl+S
# 3. העלה:
git add app.py
git commit -m "תיאור השינוי"
git push
# Streamlit Cloud מתעדכן אוטומטית תוך דקה
```

---

## 🐛 בעיות נפוצות ופתרונות

| בעיה | סיבה | פתרון |
|------|------|--------|
| `f0_` בשם עמודה | AI לא נתן שם לפונקציה | הוסף לSCHEMA: `SUM(total_views) AS total_views` |
| תוצאה ריקה | AI הוסיף סינון מיותר | הוסף לSCHEMA: "אל תוסיף סינונים שלא נאמרו" |
| `!=` במקום `=` | AI פירש "אתמול" כ"לא היום" | הוסף לSCHEMA: "תמיד = ולא !=" |
| `TransportError` | אין credentials בענן | הוסף Service Account ל-Secrets |
| `git push` נדחה | ענף לא מסונכרן | `git pull origin main` לאחר מכן `git push` |

---

## 📁 קבצים בפרויקט

| קובץ | תפקיד |
|------|--------|
| `app.py` | קוד הדשבורד המלא |
| `requirements.txt` | חבילות Python |
| `.env` | מפתחות API (לא ב-GitHub) |
| `.gitignore` | קבצים שלא יעלו ל-GitHub |

### יצירת requirements.txt
```bash
pip freeze > requirements.txt
```

---

## 🎓 מה למדתי

1. **MART Table** — פתר בעיות הרשאות ושיפר ביצועים
2. **SCHEMA מפורט** — ההשקעה בכתיבת כללים ברורים חסכה הרבה טעויות
3. **ברירת מחדל: אין סינונים** — AI נוטה להוסיף סינונים שמזיקים
4. **HLL Sketches** — דרך מהירה ומדויקת לספור גולשים ייחודיים בנתונים גדולים
5. **Service Account** — הדרך הנכונה לחבר אפליקציה בענן ל-BigQuery

---

## 🔁 איך לשחזר את הפרויקט

1. `pip install -r requirements.txt`
2. צור `.env` עם `GEMINI_API_KEY`
3. הגדר BigQuery credentials
4. הרץ `python -m streamlit run app.py`
5. לפריסה בענן — ראה שלב 4 למעלה

---

**Omer Diller — BI Developer, Walla News Analytics**

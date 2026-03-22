# 🛠️ איך בניתי את הדשבורד הדינאמי של וואלה — מ-A ל-Z

מסמך זה מתאר את כל הכלים, ההורדות, ההרשאות, והצעדים שנדרשו לבניית דשבורד ה-AI של וואלה.
לפי סדר הפעילות בפועל — כולל הבעיות שנתקלנו בהן ואיך פתרנו אותן.

---

## רקע — מה בנינו ולמה

עיתונאים ועורכים בוואלה רצו לדעת איך הכתבות שלהם מתפקדות — אבל הם לא יודעים SQL.

**לפני:** צריך איש BI שיכתוב שאילתה → מחכים → מקבלים קובץ אקסל
**אחרי:** כותבים שאלה בעברית → מקבלים תשובה תוך שניות

הארכיטקטורה המלאה:

```
שאלה בעברית (משתמש)
        ↓
Gemini 2.5 Flash (מתרגם לSQL)
        ↓
BigQuery — Mart_Content_Performance / Mart_Video_Performance
        ↓
Streamlit (מציג טבלה + גרף + הסבר)
        ↓
תשובה למשתמש
```

---

## שלב 1 — בדיקת יתכנות ב-Google Colab

**כלי:** [Google Colab](https://colab.research.google.com)
**מתי:** לפני שכתבנו שורת קוד אחת
**למה:** לוודא שהרעיון בכלל עובד לפני שמשקיעים זמן

### מה עשינו:
פתחנו notebook חדש ב-Colab וכתבנו קוד Python בסיסי שמתחבר ל-BigQuery. קיבלנו חזרה 3 שורות של נתונים אמיתיים — הוכחה שהחיבור עובד.

```python
from google.cloud import bigquery

client = bigquery.Client(project="wallabi-169712")

query = """
SELECT *
FROM `wallabi-169712.Walla_Daily_Reports.TempIntermediate_WallaProperties`
LIMIT 3
"""

df = client.query(query).to_dataframe()
print("החיבור עבד! הנה 3 שורות:")
print(df)
```

**להפעלה מחדש בעתיד:**
ב-Colab פשוט לפתוח notebook חדש מ-Google Drive → Runtime → Connect

---

## שלב 2 — קבלת מפתח Gemini API

**כלי:** [Google AI Studio](https://aistudio.google.com/app/api-keys)

### מה עשינו:
1. נכנסנו ל-aistudio.google.com עם חשבון Google
2. לחצנו **API Keys** בתפריט השמאלי
3. בחרנו את הפרויקט הקיים `wallabi-169712`
4. לחצנו **Create API key in existing project**
5. העתקנו את המפתח — נראה כך: `AIzaSy...`

**⚠️ חשוב מאוד:** לא לשתף את המפתח עם אף אחד ולא להעלות אותו ל-GitHub!

---

## שלב 3 — התקנת VS Code

**כלי:** [Visual Studio Code](https://code.visualstudio.com)

### מה עשינו:
1. הורדנו VS Code מהאתר הרשמי
2. יצרנו תיקייה חדשה בשם `walla-dashboard` בדסקטופ
3. פתחנו אותה ב-VS Code: **File → Open Folder**
4. התקנו את ה-extension של Python
5. יצרנו קובץ חדש: `app.py`

---

## שלב 4 — התקנת Python והחבילות

**כלי:** Python 3.14 + pip

### התקנת Python:
1. הורדנו מ-python.org
2. בהתקנה — סימנו **Add Python to PATH** (חשוב!)

### התקנת חבילות:
```bash
pip install streamlit google-cloud-bigquery google-generativeai pandas plotly
pip install openpyxl python-dotenv google-auth db-dtypes pyarrow
```

### מה כל חבילה עושה:
| חבילה | תפקיד |
|-------|--------|
| streamlit | בונה את הממשק |
| google-cloud-bigquery | מתחבר ל-BigQuery |
| google-generativeai | מתחבר ל-Gemini AI |
| pandas | עובד עם טבלאות נתונים |
| plotly | יוצר גרפים אינטראקטיביים |
| openpyxl | מייצא לאקסל |
| python-dotenv | קורא קבצי .env |
| db-dtypes | תמיכה בסוגי נתונים של BigQuery |

---

## שלב 5 — התקנת Google Cloud SDK

**כלי:** [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)

### מה עשינו:
1. הורדנו Google Cloud SDK Installer מהאתר
2. פתחנו **Command Prompt** (cmd) — לא PowerShell!
3. הרצנו:
```bash
gcloud init
```
4. נכנסנו עם Google ובחרנו פרויקט `wallabi-169712`

**⚠️ בעיה:** ב-PowerShell: `gcloud is not recognized`
**פתרון:** עברנו ל-**Command Prompt** (cmd)

---

## שלב 6 — הגדרת Application Default Credentials

```bash
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform
```

נפתח דפדפן → נכנסנו עם Google ואישרנו → credentials נשמרו אוטומטית.

---

## שלב 7 — שמירת המפתח בצורה בטוחה (.env)

**קובץ `.env`:**
```
GEMINI_API_KEY=AIzaSy...
```

**בקוד Python:**
```python
from dotenv import load_dotenv
import os

load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
```

**קובץ `.gitignore`:**
```
.env
__pycache__/
*.json
```

---

## שלב 8 — בניית הנתונים ב-BigQuery

### מבנה ה-Pipeline הסופי:

```
editorial_performance_daily_v2   ← טבלת בסיס (Web + Walla_App + Sport_App)
        +
Manual_uploads.item_author_mapping    ← מיפוי כתבים
        +
Manual_uploads.createdBy_mapping      ← מיפוי עורכים
        ↓
Mart_Content_Performance         ← MART תוכן (צפיות, גולשים, סשנים)

editorial_video_daily            ← נתוני וידאו גולמיים
        ↓
Mart_Video_Performance           ← MART וידאו (הפעלות, ספקים, מודעות)
```

### למה שתי טבלאות MART נפרדות?
בניסיון ראשון חיברנו את הוידאו ל-MART הראשי דרך JOIN — זה יצר כפילויות חמורות (כתבה שקיבלה 213,000 צפיות הראתה 23 מיליון). הסיבה: טבלת הוידאו מכילה כמה שורות ליום לכל כתבה (לפי ספק וידאו, מכשיר וכו') — כל שורה בטבלה הראשית הוכפלה.

**הפתרון:** שתי טבלאות נפרדות נקיות. ה-AI יודע לעשות JOIN ביניהן כשצריך.

### למה MART ולא VIEW?
- VIEW = מחשב מחדש בכל שאילתה → איטי
- MART = שומר נתונים בתוך BigQuery → מהיר + אין בעיות הרשאות

### HLL Sketches — חישוב גולשים ייחודיים
```sql
-- ❌ ישן — COUNT DISTINCT (איטי)
COUNT(DISTINCT user_pseudo_id)

-- ✅ חדש — HLL (מהיר, מדויק)
HLL_COUNT.MERGE(users_sketch)
HLL_COUNT.MERGE(sessions_sketch)
```

חשוב: ב-MART משתמשים ב-`MERGE_PARTIAL` כדי לשמור את ה-sketch כ-BYTES לשימוש עתידי, ואז ב-SCHEMA ב-AI משתמשים ב-`MERGE` הרגיל.

### hostname במקום page_location
בגרסה ראשונה שמרנו `page_location` (URL מלא) בטבלה — זה יצר אלפי שורות לכל כתבה כי כל URL עם query string שונה נחשב שורה נפרדת. החלפנו ל-`hostname` (תת-דומיין כמו `news.walla.co.il`) — פתר את הבעיה.

### סינון מדור כיף ב-MART
מדור "כיף" לא רלוונטי לניתוח עסקי — סיננו אותו ישירות ב-MART:
```sql
WHERE p.vertical_name NOT IN ('כיף') OR p.vertical_name IS NULL
```

### אסור לפספס — מדור נפרד
הכותב "אסור לפספס" משויך טכנית למדור חדשות אבל מייצר תוכן כיפי — הוספנו CASE ב-MART:
```sql
CASE 
  WHEN p.item_author_provider = 'אסור לפספס' THEN 'אסור לפספס'
  ELSE p.vertical_name
END AS vertical_name
```

### Scheduled Queries — סדר הרצה יומי:
1. `editorial_performance_daily_v2` — 06:00 UTC
2. `editorial_video_daily` — 06:30 UTC
3. `Mart_Content_Performance` — 07:00 UTC
4. `Mart_Video_Performance` — 07:15 UTC

---

## שלב 9 — כתיבת האפליקציה (app.py)

### מבנה הקוד:

```python
# 1. ייבוא ספריות
# 2. חיבור לשירותים (BigQuery + Gemini)
# 3. SCHEMA — מפת הנתונים ל-AI
# 4. פונקציות עזר — clean_sql, build_history_text
# 5. ask_data — שולח לGemini, מריץ SQL, מחזיר תוצאות
# 6. show_chart — מציג גרף חכם
# 7. show_result — מציג טבלה + גרף + הסבר + תובנה
# 8. ממשק צ'אט עם היסטוריה
```

### ה-SCHEMA — הלב של הפרויקט
הטקסט שמסביר ל-Gemini מה מבנה הנתונים ואיך לכתוב SQL נכון. כולל:
- שתי טבלאות (תוכן + וידאו) עם כל העמודות
- לוגיקת `page_type` מלאה — מה לסנן לפי הקשר השאלה
- כל המדורים כולל אסור לפספס
- כללי תאריכים, ספירות, מיון

### page_type — לוגיקה חכמה
```
כתבות / כותב / עורך / תפוקה → page_type = 'item'
תוכן ממומן / קמפיין → page_type = 'sponsored_content'
מבזקים / פלאשים → page_type = 'newsflash'
דף בית → page_type = 'homepage'
דף מדור → page_type = 'section_page'
צפיות כלליות → אין סינון + כלול page_type ב-SELECT
```

### Gemini מחזיר 4 שדות
במקום שGemini יחזיר רק SQL, הוא מחזיר מבנה מסודר:
```
CHART: yes/no — האם להציג גרף
DATE_COL: event_date / item_publication_date / none
EXPLAIN: הסבר קצר מה חיפשתי ומה סיננתי
INSIGHT: תובנה אחת על התוצאה
SQL: שאילתת SQL
```

### הרצה מקומית:
```bash
python -m streamlit run app.py
```

**⚠️ בעיה:** `streamlit run` לא עובד ב-PowerShell
**פתרון:** `python -m streamlit run app.py`

---

## שלב 10 — העלאה ל-GitHub

### יצירת Repository:
1. נכנסנו ל-github.com עם חשבון `analytics-walla`
2. יצרנו repo חדש: `dynamic-dashboard` (Private)

### העלאת הקוד:
```bash
git init
git remote add origin https://github.com/analytics-walla/dynamic-dashboard.git
git add app.py requirements.txt
git commit -m "first commit - walla AI dashboard"
git branch -M main
git push -u origin main
```

### עדכון קוד לאחר שינויים:
```bash
git add app.py
git commit -m "תיאור השינוי"
git push
# אם נדחה: git push --force
# Streamlit Cloud מתעדכן אוטומטית תוך דקה
```

**⚠️ בעיות נפוצות ב-Git:**
- `git not recognized` → התקן Git + סגור/פתח טרמינל
- `git push rejected` → `git push --force`
- Vim נפתח בטעות → לחץ `Escape` → `:q!` → Enter
- `nothing to commit` → הקובץ לא שונה או לא נשמר

---

## שלב 11 — יצירת Service Account לענן

1. Google Cloud Console → **IAM & Admin → Service Accounts**
2. **Create Service Account** → שם: `streamlit-dashboard`
3. הרשאות:
   - `BigQuery Data Viewer`
   - `BigQuery Job User`
4. **Keys → Add Key → Create new key → JSON**
5. הכנס את ה-JSON ל-Streamlit Secrets

---

## שלב 12 — פריסה ב-Streamlit Cloud

1. לך ל-[share.streamlit.io](https://share.streamlit.io)
2. **New App** → בחר repo + branch + `app.py`
3. **Advanced Settings → Secrets:**
```toml
GEMINI_API_KEY = "AIza..."

[gcp_service_account]
type = "service_account"
project_id = "wallabi-169712"
private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
client_email = "streamlit-dashboard@wallabi-169712.iam.gserviceaccount.com"
...
```
4. **Manage app → Settings → Sharing → Only specific people**

**URL הסופי:** `walla-dynamic-dashboard.streamlit.app`

---

## סיכום — כל הכלים לפי סדר

| # | כלי | מטרה |
|---|-----|------|
| 1 | Google Colab | בדיקת יתכנות |
| 2 | Google AI Studio | מפתח Gemini API |
| 3 | VS Code | כתיבת קוד |
| 4 | Python 3.14 | שפת תכנות |
| 5 | pip packages | חבילות Python |
| 6 | Google Cloud SDK | חיבור BigQuery מקומי |
| 7 | Git + GitHub | גרסאות + אחסון קוד |
| 8 | Service Account | הרשאות לאפליקציה בענן |
| 9 | Streamlit Cloud | פריסה אונליין |

---

## בעיות נפוצות ופתרונות

| בעיה | פתרון |
|------|--------|
| `gcloud not recognized` | סגור טרמינל ופתח מחדש |
| `git not recognized` | התקן Git, סגור/פתח טרמינל |
| `git push rejected` | `git push --force` |
| `nothing to commit` | הקובץ לא שונה — בדוק שנשמר |
| Vim נפתח בטעות | Escape → `:q!` → Enter |
| `DefaultCredentialsError` | הרץ `gcloud auth application-default login` |
| `db-dtypes not found` | `pip install db-dtypes` |
| `streamlit not recognized` | `python -m streamlit run app.py` |
| `TransportError` בענן | הוסף Service Account ל-Streamlit Secrets |
| כפילויות בנתונים | בדוק GROUP BY ב-MART + הפרד טבלת וידאו |
| HLL שגיאה BYTES/INT64 | השתמש ב-MERGE_PARTIAL ב-MART, MERGE בשאילתות |

---

## איך לשחזר את הפרויקט מאפס

1. התקן Python מ-python.org (סמן Add to PATH!)
2. התקן Git מ-git-scm.com
3. התקן VS Code מ-code.visualstudio.com
4. התקן Google Cloud SDK מ-cloud.google.com/sdk
5. הרץ `gcloud init` + `gcloud auth application-default login`
6. צור תיקיית פרויקט ופתח ב-VS Code
7. הרץ: `pip install streamlit google-cloud-bigquery google-generativeai pandas plotly openpyxl python-dotenv google-auth db-dtypes pyarrow`
8. צור קובץ `.env` עם `GEMINI_API_KEY=...`
9. צור קובץ `app.py` עם הקוד
10. הרץ: `python -m streamlit run app.py`
11. לפריסה בענן — ראה שלבים 10-12 למעלה

---

**Omer Diller — BI Developer | Walla News Analytics**

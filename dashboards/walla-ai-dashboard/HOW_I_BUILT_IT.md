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
BigQuery — Mart_Content_Performance
        ↓
Streamlit (מציג טבלה + גרף)
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

**למה Colab ולא פשוט VS Code?**
כי Colab לא דורש התקנת Python — הכל כבר שם. מושלם לבדיקה מהירה של רעיון לפני שמשקיעים בהתקנות.

**האם אפשר בלי?** אפשר — אבל Colab חסך זמן. ישר אפשר להתחיל עם VS Code.

**להפעלה מחדש בעתיד:**
ב-Colab פשוט לפתוח notebook חדש מ-Google Drive → Runtime → Connect

---

## שלב 2 — קבלת מפתח Gemini API

**כלי:** [Google AI Studio](https://aistudio.google.com/app/api-keys)
**מתי:** אחרי שוידאנו שהחיבור ל-BigQuery עובד

### מה עשינו:
1. נכנסנו ל-aistudio.google.com עם חשבון Google
2. לחצנו **API Keys** בתפריט השמאלי
3. בחרנו את הפרויקט הקיים `wallabi-169712`
4. לחצנו **Create API key in existing project**
5. העתקנו את המפתח — נראה כך: `AIzaSy...`

**מה זה API Key?** זה כמו סיסמה שמזהה אותנו מול שירות ה-AI של Google. בלי זה Gemini לא יודע מי שולח לו שאלות.

**⚠️ חשוב מאוד:** לא לשתף את המפתח עם אף אחד ולא להעלות אותו ל-GitHub!

**להפעלה מחדש בעתיד:**
נכנסים לאותו קישור → Create API key → בוחרים את הפרויקט

---

## שלב 3 — התקנת VS Code

**כלי:** [Visual Studio Code](https://code.visualstudio.com)
**מתי:** כשהחלטנו לעבור מ-Colab לפיתוח אמיתי

### מה עשינו:
1. הורדנו VS Code מהאתר הרשמי
2. יצרנו תיקייה חדשה בשם `walla-dashboard` בדסקטופ
3. פתחנו אותה ב-VS Code: **File → Open Folder**
4. התקנו את ה-extension של Python (הופיע כהצעה אוטומטית)
5. יצרנו קובץ חדש: `app.py`

**למה VS Code ולא Colab?**
Colab הוא מחברת לבדיקות. VS Code הוא סטודיו מקצועי לבניית אפליקציות. Streamlit חייב לרוץ מקובץ — לא מ-Colab.

**מה ההבדל בין VS Code ל-PyCharm?**
כמעט אותו דבר. VS Code קל יותר למתחילים וחינמי לחלוטין.

---

## שלב 4 — התקנת Python והחבילות

**כלי:** Python 3.14 + pip

### מה עשינו:
**התקנת Python:**
1. הורדנו מ-python.org
2. בהתקנה — סימנו **Add Python to PATH** (חשוב!)
3. כשנשאל — הקלדנו `y` לשאלות ההתקנה

**התקנת חבילות בטרמינל של VS Code:**
```bash
pip install streamlit google-cloud-bigquery google-generativeai pandas plotly
pip install openpyxl python-dotenv google-auth db-dtypes pyarrow
```

### מה כל חבילה עושה:
| חבילה | תפקיד |
|-------|--------|
| streamlit | בונה את האתר/ממשק המשתמש |
| google-cloud-bigquery | מתחבר ל-BigQuery ומריץ שאילתות |
| google-generativeai | מתחבר ל-Gemini AI |
| pandas | עובד עם טבלאות נתונים |
| plotly | יוצר גרפים אינטראקטיביים |
| openpyxl | מייצא לאקסל |
| python-dotenv | קורא קבצי .env (מפתחות סודיים) |
| db-dtypes | תמיכה בסוגי נתונים של BigQuery |

**בעיה שנתקלנו בה:**
קיבלנו שגיאה `Please install the 'db-dtypes' package` — פתרון: `pip install db-dtypes`

---

## שלב 5 — התקנת Google Cloud SDK

**כלי:** [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
**מתי:** כשרצינו להריץ את האפליקציה מחשב מקומי ולחבר ל-BigQuery

### מה עשינו:
1. הורדנו Google Cloud SDK Installer מהאתר
2. הרצנו את ההתקנה
3. פתחנו **Command Prompt** (cmd) — לא PowerShell!
4. הרצנו:
```bash
gcloud init
```
5. נכנסנו עם Google
6. בחרנו `wallabi-169712` כפרויקט ברירת מחדל
7. בחרנו region: `us-central1`

**⚠️ בעיה שנתקלנו בה:**
ב-PowerShell: `gcloud is not recognized` — לא עבד
פתרון: עברנו ל-**Command Prompt** (cmd)

**למה צריך את זה?**
כדי שקוד Python יוכל לגשת ל-BigQuery מהמחשב המקומי בלי להכניס סיסמאות בקוד עצמו.

---

## שלב 6 — הגדרת Application Default Credentials

כדי ש-Python יוכל לגשת ל-BigQuery מהמחשב, צריך לאמת אותו פעם אחת.

```bash
gcloud auth application-default login --scopes=https://www.googleapis.com/auth/cloud-platform
```

**מה קרה:**
- נפתח דפדפן → נכנסנו עם Google ואישרנו
- credentials נשמרו אוטומטית בנתיב:
  `C:\Users\omer.diller\AppData\Roaming\gcloud\application_default_credentials.json`

**⚠️ בעיה שנתקלנו בה:**
בפעם הראשונה קיבלנו שגיאה `DefaultCredentialsError`
סיבה: gcloud לא היה מותקן עדיין
פתרון: התקנת Cloud SDK ואז הרצת הפקודה מחדש

---

## שלב 7 — שמירת המפתח בצורה בטוחה (.env)

במקום לכתוב את מפתח Gemini ישירות בקוד — שמרנו אותו בקובץ נפרד.

**יצירת קובץ `.env`:**
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

**יצירת קובץ `.gitignore`** — כדי ש-.env לא יעלה ל-GitHub:
```
.env
__pycache__/
*.json
```

---

## שלב 8 — בניית הנתונים ב-BigQuery

### מבנה הנתונים שבנינו:

**Pipeline v2 — 3 טבלאות:**

```
editorial_performance_daily_v2   ← טבלת בסיס (Web + Walla_App + Sport_App)
        +
Manual_uploads.item_author_mapping    ← מיפוי כתבים
        +
Manual_uploads.createdBy_mapping      ← מיפוי עורכים
        +
editorial_video_daily            ← נתוני וידאו
        ↓
Mart_Content_Performance         ← טבלת MART — הכל במקום אחד
```

**למה MART ולא VIEW?**
- VIEW = מחשב מחדש בכל שאילתה → איטי
- MART = שומר נתונים בתוך BigQuery → מהיר + פותר בעיות הרשאות של Google Sheets

**שאילתת יצירת ה-MART (חד פעמי):**
```sql
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
```

**Scheduled Query — עדכון יומי ב-06:00:**
ב-BigQuery Console → Scheduled Queries → Create:
- שם: `Mart_Content_Performance_Daily`
- זמן: כל יום 07:30 UTC
- SQL: DELETE 5 ימים אחרונים + INSERT מחדש

**HLL Sketches — למה?**
```sql
-- ❌ ישן — COUNT DISTINCT (איטי)
COUNT(DISTINCT user_pseudo_id)

-- ✅ חדש — HLL (מהיר, מדויק)
HLL_COUNT.MERGE(users_sketch)
HLL_COUNT.MERGE(sessions_sketch)
```

**טבלת AI_Corrections לדיווח טעויות:**
```sql
CREATE TABLE `wallabi-169712.Walla_Daily_Reports.AI_Corrections` (
  correction_date TIMESTAMP,
  topic STRING,
  rule STRING,
  reason STRING,
  example_question STRING
)
```

---

## שלב 9 — כתיבת האפליקציה (app.py)

### מבנה הקוד:

```python
# 1. ייבוא ספריות
import streamlit as st
from google.cloud import bigquery
from google import genai

# 2. חיבור לשירותים
client_ai = genai.Client(api_key=GEMINI_API_KEY)
client_bq = bigquery.Client(project=PROJECT_ID)

# 3. SCHEMA — מפת הנתונים ל-AI (הלב של הפרויקט)
SCHEMA = """..."""

# 4. פונקציות עזר
def clean_sql(text): ...      # מנקה SQL מסימני קוד
def build_history_text(): ... # בונה היסטוריית שיחה
def ask_data(question, history): ...  # שולח לGemini, מריץ SQL
def show_chart(df, question): ...     # מציג גרף
def show_result(msg): ...             # מציג תוצאה + גרף + אקסל

# 5. עיצוב CSS
# 6. ממשק צ'אט עם זיכרון היסטוריה
```

### הלב של הפרויקט — ה-SCHEMA:
זה הטקסט שמסביר ל-Gemini מה מבנה הנתונים וכיצד לכתוב SQL נכון.

**כללים קריטיים שנלמדו מהניסיון:**
- `צפיות = SUM(total_views)` — לא COUNT(*)!
- `גולשים = HLL_COUNT.MERGE(users_sketch)`
- `כותב = item_author_provider` — לא item_title!
- `אל תוסיף סינונים שלא נאמרו במפורש`
- `תמיד = ולא != בסינון תאריכים`
- `אל תכלול את היום הנוכחי — הנתונים לא מלאים`

### הרצה מקומית:
```bash
python -m streamlit run app.py
# פתח דפדפן: http://localhost:8501
```

**⚠️ בעיה:** `streamlit run` לא עובד ב-PowerShell
**פתרון:** `python -m streamlit run app.py`

---

## שלב 10 — העלאה ל-GitHub

### יצירת Repository:
1. נכנסנו ל-github.com עם חשבון `analytics-walla`
2. יצרנו repo חדש: `dynamic-dashboard` (Private)
3. סימנו `.gitignore → Python` — כדי שה-.env לא יעלה

### העלאת הקוד:
```bash
git init
git remote add origin https://github.com/analytics-walla/dynamic-dashboard.git
git add app.py requirements.txt
git commit -m "first commit - walla AI dashboard"
git branch -M main
git push -u origin main
```

**⚠️ בעיות שנתקלנו בהן:**
- `git not recognized` → פתרון: התקנת Git + סגירה/פתיחה של טרמינל
- `git push rejected` → פתרון: `git push --force`
- Vim נפתח בטעות → פתרון: לחץ `Escape` → `:q!` → Enter

### עדכון קוד לאחר שינויים:
```bash
git add app.py
git commit -m "תיאור השינוי"
git push
# Streamlit Cloud מתעדכן אוטומטית תוך דקה
```

---

## שלב 11 — יצירת Service Account לענן

כדי שהאפליקציה בענן תוכל לגשת ל-BigQuery, צריך Service Account.

### יצירה:
1. console.cloud.google.com → **IAM & Admin → Service Accounts**
2. **Create Service Account**
3. שם: `streamlit-dashboard`
4. תיאור: `Streamlit Cloud access to BigQuery`
5. הרשאות:
   - `BigQuery Data Viewer` — לקרוא נתונים
   - `BigQuery Job User` — להריץ שאילתות
   - `BigQuery Data Editor` — לכתוב לטבלת AI_Corrections
6. **Keys → Add Key → Create new key → JSON**
7. הקובץ הורד למחשב

**⚠️ חשוב:** מחקנו את קובץ ה-JSON אחרי שסיימנו להשתמש בו!

---

## שלב 12 — פריסה ב-Streamlit Cloud

### הרשמה:
1. נכנסנו ל-[share.streamlit.io](https://share.streamlit.io)
2. התחברנו עם חשבון GitHub של analytics-walla
3. מילאנו פרטי רישום

### Deploy:
1. לחצנו **New App**
2. Repository: `analytics-walla/dynamic-dashboard`
3. Branch: `main`
4. Main file path: `app.py`
5. App URL: `walla-dynamic-dashboard`
6. לחצנו **Advanced Settings → Secrets**

### Streamlit Secrets — הגדרה בפורמט TOML:
```toml
GEMINI_API_KEY = "AIza..."

[gcp_service_account]
type = "service_account"
project_id = "wallabi-169712"
private_key_id = "..."
private_key = "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
client_email = "streamlit-dashboard@wallabi-169712.iam.gserviceaccount.com"
client_id = "..."
auth_uri = "https://accounts.google.com/o/oauth2/auth"
token_uri = "https://oauth2.googleapis.com/token"
client_x509_cert_url = "..."
```

### קוד לקריאת credentials בענן:
```python
from google.oauth2 import service_account

if "gcp_service_account" in st.secrets:
    credentials = service_account.Credentials.from_service_account_info(
        st.secrets["gcp_service_account"],
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    client_bq = bigquery.Client(project=PROJECT_ID, credentials=credentials)
else:
    client_bq = bigquery.Client(project=PROJECT_ID)  # מחשב מקומי
```

### אבטחה:
**Manage app → Settings → Sharing → Only specific people**
הוספנו מיילים של המשתמשים המורשים — כולם נכנסים עם Google.

### URL הסופי:
`walla-dynamic-dashboard.streamlit.app`

---

## סיכום — כל הכלים לפי סדר

| # | כלי | מטרה | היכן |
|---|-----|------|------|
| 1 | Google Colab | בדיקת יתכנות | colab.research.google.com |
| 2 | Google AI Studio | מפתח Gemini API | aistudio.google.com |
| 3 | VS Code | כתיבת קוד | code.visualstudio.com |
| 4 | Python 3.14 | שפת תכנות | python.org |
| 5 | pip packages | חבילות Python | דרך הטרמינל |
| 6 | Google Cloud SDK | חיבור BigQuery מקומי | cloud.google.com/sdk |
| 7 | Git + GitHub | גרסאות + אחסון קוד | github.com |
| 8 | Service Account | הרשאות לאפליקציה בענן | Google Cloud Console |
| 9 | Streamlit Cloud | פריסה אונליין | share.streamlit.io |

---

## הרשאות שנדרשו

| הרשאה | איפה | למה |
|--------|------|-----|
| BigQuery Data Viewer | Service Account | לקרוא נתונים |
| BigQuery Job User | Service Account | להריץ שאילתות |
| BigQuery Data Editor | Service Account | לכתוב לטבלת AI_Corrections |
| Application Default Credentials | מחשב מקומי | גישה ל-BigQuery במחשב |

---

## בעיות נפוצות ופתרונות

| בעיה | פתרון |
|------|--------|
| `gcloud not recognized` | סגור טרמינל ופתח מחדש |
| `git not recognized` | התקן Git, סגור/פתח טרמינל |
| `git push rejected` | `git push --force` |
| Vim נפתח בטעות | לחץ Escape → `:q!` → Enter |
| `DefaultCredentialsError` | הרץ `gcloud auth application-default login` |
| `db-dtypes not found` | `pip install db-dtypes` |
| `streamlit not recognized` | `python -m streamlit run app.py` |
| קוד הודבק בטרמינל | Ctrl+C → פתח app.py ב-VS Code |
| `TransportError` בענן | הוסף Service Account ל-Streamlit Secrets |
| `f0_` בשם עמודה | הוסף `AS שם_ברור` לכל פונקציה ב-SQL |
| AI מוסיף סינונים מיותרים | הוסף לSCHEMA: "אל תוסיף סינונים שלא נאמרו" |
| `!=` במקום `=` | הוסף לSCHEMA: "תמיד = ולא !=" |

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

# ============================================
# דשבורד וואלה — AI צ'אט
# ============================================
import streamlit as st
from google.cloud import bigquery
from google import genai
import plotly.express as px
from dotenv import load_dotenv
import os
import pandas as pd
import io

load_dotenv()

# ============================================
# הגדרות בסיסיות
# ============================================
PROJECT_ID = "wallabi-169712"
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

client_ai = genai.Client(api_key=GEMINI_API_KEY)

# חיבור BigQuery עם Service Account מ-Streamlit Secrets
from google.oauth2 import service_account

if "gcp_service_account" in st.secrets:
    credentials = service_account.Credentials.from_service_account_info(
        st.secrets["gcp_service_account"],
        scopes=["https://www.googleapis.com/auth/cloud-platform"]
    )
    client_bq = bigquery.Client(project=PROJECT_ID, credentials=credentials)
else:
    client_bq = bigquery.Client(project=PROJECT_ID)

# ============================================
# מפת הנתונים ל-AI
# ============================================
SCHEMA = """
טבלאות זמינות:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. טבלת תוכן ראשית (צפיות, גולשים, סשנים):
`wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

עמודות כלליות:
- platform (STRING) — פלטפורמה: 'Web' / 'Walla_App' / 'Sport_App'
- page_type (STRING) — סוג עמוד — ראה לוגיקה מלאה בסעיף "סוג עמוד" למטה
- event_date (DATE) — תאריך האירוע

עמודות כתבה:
- item_id (STRING) — מזהה ייחודי של כתבה (קיים רק ב-page_type = 'item' / 'newsflash' / 'sponsored_content')
- item_title (STRING) — כותרת הכתבה
- item_publication_date (DATE) — תאריך פרסום הכתבה
- vertical_name (STRING) — מדור. ערכים אפשריים:
  'חדשות', 'ספורט', 'תרבות', 'כסף', 'אופנה', 'רכב', 'סלבס', 'אוכל', 'בריאות', 'תיירות', 'אסור לפספס'
  - 'אסור לפספס' הוא תוכן כיפי המשויך טכנית לחדשות — כשמבקשים נתוני חדשות אל תכלול אותו אלא אם ביקשו במפורש
- CategoryName (STRING) — תת-מדור
- tohash (STRING) — מזהה קמפיין ממומן (קיים רק בתוכן ממומן)

עמודות כותב ועורך:
- item_author_provider (STRING) — שם הכותב או ספק התוכן
- created_by_username (STRING) — שם משתמש של העורך
- author_main_section (STRING) — מדור ראשי של הכותב
- author_daily_goal (STRING) — יעד יומי של הכותב
- editor_full_name (STRING) — שם מלא של העורך
- editor_main_section (STRING) — מדור ראשי של העורך
- editor_daily_goal (STRING) — יעד יומי של העורך

עמודות מכשיר ותנועה:
- device_category (STRING) — mobile / desktop / tablet
- device_os (STRING) — iOS / Android / Windows / וכו'
- hostname (STRING) — תת-דומיין: 'news.walla.co.il' / 'sport.walla.co.il' / 'money.walla.co.il' (Web בלבד, באפליקציה = NULL)
- traffic_source (STRING) — מקור התנועה (Web בלבד)
- traffic_medium (STRING) — מדיום התנועה (Web בלבד)

עמודות מדידה:
- total_views (INTEGER) — מספר צפיות — תמיד SUM!
- users_sketch (BYTES) — HLL sketch לגולשים ייחודיים
- sessions_sketch (BYTES) — HLL sketch לסשנים ייחודיים

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2. טבלת וידאו:
`wallabi-169712.Walla_Daily_Reports.Mart_Video_Performance`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

עמודות זיהוי:
- item_id (STRING) — מזהה כתבה
- item_title (STRING) — כותרת הכתבה
- item_author_provider (STRING) — שם הכותב
- vertical_name (STRING) — מדור
- CategoryName (STRING) — תת-מדור
- tohash (STRING) — מזהה קמפיין ממומן
- event_date (DATE) — תאריך
- hostname (STRING) — תת-דומיין
- device_category (STRING) — mobile / desktop / tablet

עמודות וידאו:
- user_play (STRING) — האם המשתמש לחץ play ידנית
- video_provider_id (STRING) — ספק הוידאו
- ads_provider (STRING) — ספק הפרסום
- is_complete (STRING) — האם הוידאו הסתיים

עמודות מדידה:
- total_video_plays (INTEGER) — מספר הפעלות — תמיד SUM!
- total_ads (INTEGER) — מספר מודעות — תמיד SUM!
- users_sketch (BYTES) — HLL sketch לגולשים שהפעילו וידאו

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ כללים קריטיים:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# ספירות
- צפיות = SUM(total_views) — לעולם אל תשתמש ב-COUNT(*) !
- גולשים ייחודיים = HLL_COUNT.MERGE(users_sketch)
- סשנים = HLL_COUNT.MERGE(sessions_sketch)
- הפעלות וידאו = SUM(total_video_plays)
- גולשי וידאו = HLL_COUNT.MERGE(users_sketch) מ-Mart_Video_Performance
- כתבות ייחודיות = COUNT(DISTINCT item_id)

# סוג עמוד — page_type — לוגיקה מלאה
השתמש בעמודה page_type לסינון לפי הקשר השאלה:

- כתבות / תכנים / כותב / עורך / תפוקה → page_type = 'item'
- תוכן ממומן / קמפיין / שיווקי → page_type = 'sponsored_content'
- מבזקים / מבזקי חדשות / פלאשים / חדשות מהירות → page_type = 'newsflash'
- דף בית / הום פייג' / עמוד ראשי → page_type = 'homepage'
- דף מדור / עמוד מדור / סקשן → page_type = 'section_page'
- כמות פרסומים / תפוקת כותב / תפוקת עורך → page_type = 'item' לפי item_publication_date
- צפיות כלליות / סך הכל / ללא ציון סוג → אין סינון על page_type + חובה לכלול page_type ב-SELECT

# ניתוב בין טבלאות
- שאלות על צפיות / גולשים / סשנים → Mart_Content_Performance
- שאלות על וידאו / הפעלות / ספקי וידאו → Mart_Video_Performance
- שאלות משולבות → JOIN לפי item_id AND event_date

# כותבים
- כותב = item_author_provider
- יעד יומי כותב = SAFE_CAST(TRIM(author_daily_goal) AS INT64)
- פער מיעד = COUNT(DISTINCT item_id) - SAFE_CAST(TRIM(author_daily_goal) AS INT64)
- מדור כותב = author_main_section
- אם המשתמש שואל על יעד כותב — הצג: שם כותב, מדור, יעד יומי, כמה פרסם, פער מהיעד

# עורכים
- עורך = editor_full_name
- יעד יומי עורך = SAFE_CAST(TRIM(editor_daily_goal) AS INT64)
- פער מיעד = COUNT(DISTINCT item_id) - SAFE_CAST(TRIM(editor_daily_goal) AS INT64)
- מדור עורך = editor_main_section
- אם המשתמש שואל על יעד עורך — הצג: שם עורך, מדור, יעד יומי, כמה כתבות ערך, פער מהיעד

# מדורים
- מדור = vertical_name
- כשמבקשים נתוני חדשות — אל תכלול vertical_name = 'אסור לפספס' אלא אם ביקשו במפורש

# פלטפורמות
- כל הפלטפורמות = אל תסנן לפי platform
- Web בלבד = platform = 'Web'
- אפליקציה בלבד = platform IN ('Walla_App', 'Sport_App')
- וואלה אפ = platform = 'Walla_App'
- ספורט אפ = platform = 'Sport_App'

# תאריכים
- אתמול = event_date = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
- תמיד השתמש ב-= ולא != בסינון תאריכים!
- השבוע = event_date >= DATE_TRUNC(CURRENT_DATE(), WEEK(MONDAY)) AND event_date < CURRENT_DATE()
- שבוע שעבר = event_date >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), WEEK(MONDAY)), INTERVAL 7 DAY) AND event_date < DATE_TRUNC(CURRENT_DATE(), WEEK(MONDAY))
- החודש = event_date >= DATE_TRUNC(CURRENT_DATE(), MONTH) AND event_date < CURRENT_DATE()
- חודש שעבר = event_date >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH) AND event_date < DATE_TRUNC(CURRENT_DATE(), MONTH)
- N ימים אחרונים = event_date >= DATE_SUB(CURRENT_DATE(), INTERVAL N DAY) AND event_date < CURRENT_DATE()
- טווח חופשי = event_date BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'
- חודש ספציפי = EXTRACT(YEAR FROM event_date) = X AND EXTRACT(MONTH FROM event_date) = Y
- מילות פרסום (שפורסמו, שפירסם, פורסם, התפרסם, פרסם) = item_publication_date
- מילות צפייה (נצפה, נצפו, צפיות, נקרא) = event_date
- אם לא ברור — השתמש ב-event_date
- אל תכלול את היום הנוכחי — הנתונים עדיין לא מלאים

# סינונים — ברירת מחדל: אין סינונים!
- אל תוסיף שום סינון שלא נאמר במפורש
- סנן לפי page_type לפי הלוגיקה בסעיף "סוג עמוד" למעלה
- סנן לפי platform רק אם המשתמש ציין פלטפורמה
- סנן לפי traffic_source/medium רק אם המשתמש ציין מקור תנועה

# מיון ברירת מחדל
- תמיד מיין לפי המדד העיקרי בסדר יורד (DESC) — אלא אם המשתמש ציין אחרת
  - שאלות על צפיות → ORDER BY total_views DESC
  - שאלות על כמות כתבות / תפוקה → ORDER BY article_count DESC (או שם העמודה הרלוונטי)
  - שאלות על גולשים → ORDER BY unique_users DESC

# שמות עמודות
- תן שמות ברורים תמיד — לא f0_, לא count
- SUM(total_views) AS total_views
- HLL_COUNT.MERGE(users_sketch) AS unique_users
- HLL_COUNT.MERGE(sessions_sketch) AS sessions
- אל תחשב ערכים מצטברים אלא אם התבקשת
"""

# ============================================
# פונקציות עזר
# ============================================
def clean_sql(text):
    text = text.strip()
    if text.startswith("```"):
        text = text.split("\n", 1)[1]
    if text.endswith("```"):
        text = text.rsplit("\n", 1)[0]
    return text.strip()

def build_history_text(history):
    lines = []
    for msg in history[-6:]:
        if msg["role"] == "user":
            lines.append(f"משתמש: {msg['content']}")
        elif "df" in msg:
            lines.append(f"תוצאה קודמת: {msg['content']}")
    return "\n".join(lines)

def ask_data(question, history):
    history_text = build_history_text(history)
    prompt = f"""
אתה מומחה SQL ל-BigQuery של וואלה.
בהינתן הסכמה הבאה:
{SCHEMA}

{"היסטוריית השיחה עד כה:" + history_text if history_text else ""}

תרגם את השאלה הבאה לשאילתת SQL תקינה ל-BigQuery.
אם השאלה מתייחסת לתוצאה קודמת — השתמש בהקשר מההיסטוריה.

⚠️ חוקים שחייבים להופיע בכל שאילתה:
- צפיות = SUM(total_views) — לעולם לא COUNT(*)
- כשמבקשים חדשות — אל תכלול vertical_name = 'אסור לפספס' אלא אם ביקשו במפורש
- סנן לפי page_type לפי הקשר השאלה (ראה SCHEMA)
- כשצפיות כלליות ללא ציון סוג תוכן — כלול page_type ב-SELECT ואל תסנן לפיו
- תמיד תן שמות ברורים לעמודות

החזר תשובה במבנה הבא בדיוק — ארבעה חלקים:

CHART: yes או no — האם להציג גרף? yes רק אם השאלה מבקשת מגמה / השוואה לפי זמן / פירוט לפי תאריכים
DATE_COL: שם עמודת התאריך לציר X (event_date / item_publication_date) — רק אם CHART: yes, אחרת none
EXPLAIN: משפט קצר בעברית פשוטה — מה חיפשת, אילו סינונים הוספת, טווח תאריכים, איזו טבלה השתמשת
INSIGHT: תובנה קצרה אחת על התוצאה (למשל: "שים לב שרוב הכתבות הן מספורט") — או none אם לא רלוונטי
SQL:
[שאילתת SQL בלבד, בלי הסברים ובלי סימני קוד]

שאלה: {question}
"""
    response = client_ai.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )

    text = response.text.strip()

    # פירוק התשובה
    show_chart = False
    date_col_override = None
    explain = None
    insight = None
    sql = text

    if "SQL:" in text:
        lines = text.split("\n")
        sql_lines = []
        in_sql = False
        for line in lines:
            if line.startswith("CHART:"):
                show_chart = "yes" in line.lower()
            elif line.startswith("DATE_COL:"):
                val = line.replace("DATE_COL:", "").strip()
                date_col_override = val if val != "none" else None
            elif line.startswith("EXPLAIN:"):
                explain = line.replace("EXPLAIN:", "").strip()
            elif line.startswith("INSIGHT:"):
                val = line.replace("INSIGHT:", "").strip()
                insight = val if val.lower() != "none" else None
            elif line.startswith("SQL:"):
                in_sql = True
            elif in_sql:
                sql_lines.append(line)
        sql = "\n".join(sql_lines).strip()

    sql = clean_sql(sql)
    df = client_bq.query(sql).to_dataframe()
    return sql, df, show_chart, date_col_override, explain, insight

def show_chart(df, question, date_col_override=None):
    date_col = date_col_override if date_col_override and date_col_override in df.columns else None
    if not date_col:
        return
    if len(df) > 1:
        df[date_col] = pd.to_datetime(df[date_col]).dt.date
        preferred = [c for c in df.select_dtypes(include='number').columns
                     if not any(x in c.lower() for x in ['goal', 'id', 'session', 'ads'])]
        num_cols = preferred if preferred else list(df.select_dtypes(include='number').columns)
        if len(num_cols) > 0:
            fig = px.line(df, x=date_col, y=num_cols[0],
                          title=question, markers=True, text=num_cols[0])
            fig.update_traces(
                textposition="top center", texttemplate='%{text:,}',
                textfont=dict(size=16), line=dict(color='#4361ee', width=2.5),
                marker=dict(size=10))
            fig.update_layout(
                title=dict(text=question, x=0.98, xanchor='right',
                           font=dict(size=18, color='#e0e0e0'), pad=dict(b=20)),
                xaxis_title="תאריך", yaxis_title=num_cols[0],
                paper_bgcolor='#2a2d3e', plot_bgcolor='#2a2d3e',
                font=dict(color='#e0e0e0', size=16),
                xaxis=dict(tickformat='%d/%m', gridcolor='#444', tickfont=dict(size=15)),
                yaxis=dict(gridcolor='#444', tickfont=dict(size=15), autorange=True),
                margin=dict(t=80, r=30, l=60, b=60))
            st.plotly_chart(fig, use_container_width=True)

def show_result(msg):
    if msg.get("explain"):
        st.markdown(f"🔍 **{msg['explain']}**")

    with st.expander("📝 SQL שנוצר"):
        st.code(msg["sql"], language="sql")

    st.dataframe(msg["df"], use_container_width=True)

    if msg.get("show_chart", False):
        show_chart(msg["df"].copy(), msg["content"], msg.get("date_col"))

    if msg.get("insight"):
        st.markdown(f"💡 **{msg['insight']}**")

    buffer = io.BytesIO()
    msg["df"].to_excel(buffer, index=False, engine='openpyxl')
    buffer.seek(0)
    st.download_button(
        label="📥 הורד לאקסל",
        data=buffer,
        file_name="walla_data.xlsx",
        mime="application/vnd.ms-excel",
        key=f"dl_{msg['id']}"
    )

# ============================================
# עיצוב
# ============================================
st.set_page_config(page_title="דשבורד וואלה AI", layout="wide")

st.markdown("""
<style>
    .stApp { background-color: #1a1a2e; }
    .block-container { max-width: 1300px; margin: auto; padding-top: 2rem; }
    .main { direction: rtl; text-align: right; }
    h1 {
        text-align: center !important;
        font-size: 2.8rem !important;
        color: #ffffff !important;
        padding-bottom: 0.8rem !important;
        border-bottom: 3px solid #4361ee !important;
        margin-bottom: 0.5rem !important;
    }
    h2, h3 { color: #e0e0e0 !important; direction: rtl !important; text-align: right !important; font-size: 1.5rem !important; }
    p, label, .stMarkdown { color: #c0c0c0 !important; direction: rtl !important; text-align: right !important; font-size: 1.2rem !important; }
    .stDataFrame { direction: rtl !important; border-radius: 12px !important; }
    .stDataFrame table { background-color: #2a2d3e !important; color: #ffffff !important; font-size: 18px !important; }
    .stDataFrame th { background-color: #4361ee !important; color: white !important; font-size: 18px !important; padding: 14px !important; }
    .stDataFrame td { color: #ffffff !important; padding: 12px !important; font-size: 17px !important; }
    .stButton button {
        background-color: #4361ee !important; color: white !important;
        font-size: 15px !important; font-weight: bold !important;
        padding: 8px 20px !important; border-radius: 10px !important; border: none !important;
    }
    .stButton button:hover { background-color: #3451d1 !important; }
    .tip-box {
        background-color: #2a2d3e;
        border-right: 3px solid #4361ee;
        padding: 8px 14px;
        border-radius: 8px;
        color: #a0a0c0 !important;
        font-size: 0.95rem !important;
        margin-top: 8px;
    }
</style>
""", unsafe_allow_html=True)

# ============================================
# ממשק משתמש — צ'אט
# ============================================
st.title("📊 דשבורד וואלה — שאל אותי הכל")

if "messages" not in st.session_state:
    st.session_state.messages = []

col1, col2 = st.columns([6, 1])
with col2:
    if st.button("🗑️ נקה שיחה"):
        st.session_state.messages = []
        st.rerun()

for msg in st.session_state.messages:
    with st.chat_message("user" if msg["role"] == "user" else "assistant"):
        st.write(msg["content"])
        if "df" in msg:
            show_result(msg)

question = st.chat_input("מה תרצה לדעת?")

# טיפ למשתמש
st.markdown(
    '<div class="tip-box">💡 טיפ: לשאלות המשך — נסח את כל הבקשה מחדש במשפט אחד מלא. '
    'לדוגמה: "תן לי צפיות לפי מדור אתמול כולל שם כותב"</div>',
    unsafe_allow_html=True
)

if question:
    st.session_state.messages.append({
        "role": "user",
        "content": question
    })

    with st.spinner("⏳ מחשב..."):
        try:
            sql, df, show_chart_flag, date_col, explain, insight = ask_data(question, st.session_state.messages)
            st.session_state.messages.append({
                "role": "assistant",
                "content": f"נמצאו {len(df)} שורות תוצאה",
                "sql": sql,
                "df": df,
                "question": question,
                "show_chart": show_chart_flag,
                "date_col": date_col,
                "explain": explain,
                "insight": insight,
                "id": len(st.session_state.messages)
            })
        except Exception as e:
            error_msg = str(e)
            # הודעת שגיאה ידידותית
            if "Syntax error" in error_msg or "invalidQuery" in error_msg or "Invalid" in error_msg:
                friendly = (
                    "❌ לא הצלחתי להבין את הבקשה ולבנות שאילתה תקינה.\n\n"
                    "💡 נסה לנסח מחדש את השאלה במשפט אחד מלא ועצמאי, "
                    "מבלי להתייחס לשאלות קודמות בשיחה."
                )
            else:
                friendly = f"❌ שגיאה: {error_msg}"

            st.session_state.messages.append({
                "role": "assistant",
                "content": friendly
            })

    st.rerun()

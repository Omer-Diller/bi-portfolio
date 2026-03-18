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
from datetime import datetime

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
טבלה ראשית (השתמש רק בה!):
`wallabi-169712.Walla_Daily_Reports.Mart_Content_Performance`

עמודות כלליות:
- platform (STRING) — פלטפורמה: 'Web' / 'Walla_App' / 'Sport_App'
- page_type (STRING) — סוג עמוד: 'item' / 'homepage' / 'section_page' / 'newsflash' / 'sponsored_content' / 'other'
- event_date (DATE) — תאריך האירוע

עמודות כתבה:
- item_id (STRING) — מזהה ייחודי של כתבה
- item_title (STRING) — כותרת הכתבה
- item_publication_date (DATE) — תאריך פרסום הכתבה
- vertical_name (STRING) — מדור: 'חדשות', 'ספורט', 'תרבות', 'כסף'
- CategoryName (STRING) — תת-מדור
- tohash (STRING) — תוכן ממומן (לא ריק = ממומן)

עמודות כותב ועורך:
- item_author_provider (STRING) — שם הכותב או ספק התוכן
- created_by_username (STRING) — שם משתמש של העורך שיצר את הכתבה
- author_main_section (STRING) — מדור ראשי של הכותב
- author_daily_goal (STRING) — יעד יומי של הכותב
- editor_full_name (STRING) — שם מלא של העורך
- editor_main_section (STRING) — מדור ראשי של העורך
- editor_daily_goal (STRING) — יעד יומי של העורך

עמודות מכשיר:
- device_category (STRING) — mobile / desktop / tablet
- device_os (STRING) — iOS / Android / Windows / וכו'

עמודות תנועה (Web בלבד):
- page_location (STRING) — URL נקי של העמוד (קיים רק ב-Web, באפליקציה = NULL)
- אם המשתמש שואל על עמוד/דף/URL ספציפי — סנן לפי page_location LIKE '%...%'
- סינון לפי page_location מחזיר אוטומטית רק נתוני Web — אין צורך לסנן גם לפי platform
- traffic_source (STRING) — מקור התנועה (Web בלבד)
- traffic_medium (STRING) — מדיום התנועה (Web בלבד)

עמודות מדידה — חשוב מאוד:
- total_views (INTEGER) — מספר צפיות (כבר מחושב — אל תשתמש ב-COUNT(*))
- users_sketch (BYTES) — HLL sketch לגולשים ייחודיים
- sessions_sketch (BYTES) — HLL sketch לסשנים ייחודיים
- video_users_sketch (BYTES) — HLL sketch לגולשים שהפעילו וידאו

עמודות וידאו:
- total_video_plays (INTEGER) — מספר הפעלות וידאו
- user_play (STRING) — האם המשתמש לחץ play ידנית
- is_complete (STRING) — האם הוידאו הסתיים
- video_provider_id (STRING) — ספק הוידאו
- ads_provider (STRING) — ספק הפרסום
- total_ads (INTEGER) — כמה מודעות הוצגו

⚠️ כללים קריטיים:

# ספירות
- צפיות = SUM(total_views) — לעולם אל תשתמש ב-COUNT(*) !
- גולשים ייחודיים = HLL_COUNT.MERGE(users_sketch)
- סשנים/ביקורים = HLL_COUNT.MERGE(sessions_sketch)
- גולשי וידאו = HLL_COUNT.MERGE(video_users_sketch)
- הפעלות וידאו = SUM(total_video_plays)
- כתבות ייחודיות = COUNT(DISTINCT item_id)

# כותבים
- כותב = item_author_provider
- יעד יומי כותב = SAFE_CAST(TRIM(author_daily_goal) AS INT64)
- פער מיעד כותב = COUNT(DISTINCT item_id) - SAFE_CAST(TRIM(author_daily_goal) AS INT64)
- מדור כותב = author_main_section
- אם המשתמש שואל על יעד כותב — הצג: שם כותב, מדור, יעד יומי, כמה פרסם, פער מהיעד

# עורכים
- עורך = editor_full_name
- יעד יומי עורך = SAFE_CAST(TRIM(editor_daily_goal) AS INT64)
- פער מיעד עורך = COUNT(DISTINCT item_id) - SAFE_CAST(TRIM(editor_daily_goal) AS INT64)
- מדור עורך = editor_main_section
- אם המשתמש שואל על יעד עורך — הצג: שם עורך, מדור, יעד יומי, כמה כתבות ערך, פער מהיעד

# מדורים
- מדור = vertical_name (ערכים: 'חדשות', 'ספורט', 'תרבות', 'כסף')
- קטגוריה = CategoryName

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
- סנן לפי page_type רק אם המשתמש ציין סוג תוכן
- סנן לפי platform רק אם המשתמש ציין פלטפורמה
- סנן לפי traffic_source/medium רק אם המשתמש ציין מקור תנועה

# שמות עמודות
- תן שמות ברורים תמיד — לא f0_, לא count
- SUM(total_views) AS total_views
- HLL_COUNT.MERGE(users_sketch) AS unique_users
- HLL_COUNT.MERGE(sessions_sketch) AS sessions
- אל תחשב ערכים מצטברים אלא אם התבקשת
"""

# ============================================
# פונקציית שמירת דיווח טעות
# ============================================
def save_correction(question, sql, feedback):
    """שומר דיווח טעות ל-BigQuery לצפייה ידנית"""
    row = {
        "correction_date": datetime.utcnow().isoformat(),
        "topic": "דיווח משתמש",
        "rule": feedback[:500],
        "reason": f"SQL: {sql[:200]}",
        "example_question": question[:500]
    }
    errors = client_bq.insert_rows_json(
        "wallabi-169712.Walla_Daily_Reports.AI_Corrections", [row]
    )
    if errors:
        raise Exception(errors)

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
החזר רק את ה-SQL בלבד — בלי הסברים ובלי סימני קוד.

שאלה: {question}
"""
    response = client_ai.models.generate_content(
        model="gemini-2.5-flash",
        contents=prompt
    )
    sql = clean_sql(response.text)
    df = client_bq.query(sql).to_dataframe()
    return sql, df

def show_chart(df, question):
    date_col = next((c for c in df.columns if 'date' in c.lower()), None)
    if date_col and len(df) > 1:
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
    with st.expander("📝 SQL שנוצר"):
        st.code(msg["sql"], language="sql")
    st.dataframe(msg["df"], use_container_width=True)
    show_chart(msg["df"].copy(), msg["content"])

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

    if st.button("👎 יש בעיה בתשובה", key=f"bad_{msg['id']}"):
        st.session_state[f"show_feedback_{msg['id']}"] = True

    if st.session_state.get(f"show_feedback_{msg['id']}"):
        feedback = st.text_input(
            "מה לא נכון? (תאר בקצרה)",
            placeholder="למשל: המספר נראה גבוה מדי",
            key=f"feedback_{msg['id']}"
        )
        if st.button("📩 שלח דיווח", key=f"submit_{msg['id']}") and feedback:
            with st.spinner("שומר דיווח..."):
                try:
                    save_correction(msg["question"], msg["sql"], feedback)
                    st.success("✅ הדיווח נשמר! הצוות הטכני יבדוק ויתקן.")
                    st.session_state[f"show_feedback_{msg['id']}"] = False
                except Exception as e:
                    st.error(f"שגיאה: {e}")

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

if question:
    st.session_state.messages.append({
        "role": "user",
        "content": question
    })

    with st.spinner("⏳ מחשב..."):
        try:
            sql, df = ask_data(question, st.session_state.messages)
            st.session_state.messages.append({
                "role": "assistant",
                "content": f"נמצאו {len(df)} שורות תוצאה",
                "sql": sql,
                "df": df,
                "question": question,
                "id": len(st.session_state.messages)
            })
        except Exception as e:
            st.session_state.messages.append({
                "role": "assistant",
                "content": f"שגיאה: {e}"
            })

    st.rerun()

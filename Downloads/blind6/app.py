import streamlit as st
import cv2
from ultralytics import YOLO
import numpy as np
import os
import tempfile
from PIL import Image
import google.generativeai as genai
from dotenv import load_dotenv
from streamlit_extras.stylable_container import stylable_container
import streamlit.components.v1 as components

# Load environment variables
load_dotenv()

# --- CONFIGURATION ---
FOCAL_LENGTH = 682 
KNOWN_WIDTHS = {"car": 1.8, "person": 0.5, "bus": 2.5, "truck": 2.6, "motorcycle": 0.7, "bicycle": 0.6}
MAX_DISTANCE_METERS = 30.0

# Initialize session state
if 'model_loaded' not in st.session_state:
    st.session_state.model_loaded = False
if 'latest_frame' not in st.session_state:
    st.session_state.latest_frame = None
if 'description_history' not in st.session_state:
    st.session_state.description_history = []

# --- BROWSER TTS FUNCTION (NO pyttsx3!) ---
def speak_text_browser(text):
    """Speak text using browser's Web Speech API"""
    escaped_text = (
        text.replace("\\", "\\\\")
            .replace("'", "\\'")
            .replace('"', '\\"')
            .replace("\n", " ")
            .replace("\r", " ")
    )
    
    js_code = f"""
    if ('speechSynthesis' in window) {{
        window.speechSynthesis.cancel();
        var utterance = new SpeechSynthesisUtterance("{escaped_text}");
        utterance.rate = 0.9;
        utterance.pitch = 1.1;
        utterance.volume = 1.0;
        window.speechSynthesis.speak(utterance);
        console.log("Speaking:", "{escaped_text}");
    }} else {{
        console.log("SpeechSynthesis not supported.");
        alert("Your browser doesn't support speech. Use Chrome/Edge/Safari.");
    }}
    """
    components.html(f"<script>{js_code}</script>", height=0)

# --- SCENE DESCRIPTION FUNCTION ---
def describe_scene(image_path):
    api_key = os.getenv("GOOGLE_API_KEY")
    if not api_key:
        msg = "API key not configured. Add GOOGLE_API_KEY in HF Secrets."
        speak_text_browser(msg)
        return msg

    try:
        genai.configure(api_key=api_key)
        model = genai.GenerativeModel('gemini-1.5-flash-latest')
        img = Image.open(image_path)
        prompt = (
            "You are assisting a visually impaired person. Describe this scene "
            "with focus on obstacles, pathways, vehicles, stairs, doors, and traffic. "
            "Mention positions (left/right/front) and distances if possible. "
            "Be concise and practical. Example: 'Bicycle approaching from right at 3 meters.'"
        )
        
        response = model.generate_content([prompt, img])
        
        if response and response.text:
            description = response.text.strip()
            timestamp = time.strftime("%H:%M:%S")
            record = f"[{timestamp}] {description}"
            st.session_state.description_history.append(record)
            speak_text_browser(description)
            return description
        else:
            msg = "No description available."
            speak_text_browser(msg)
            return msg

    except Exception as e:
        error_msg = f"Error: {str(e)}"
        speak_text_browser("Sorry, scene understanding failed.")
        return error_msg

# --- HELPER FUNCTION ---
def estimate_distance(object_pixel_width, class_name):
    if class_name in KNOWN_WIDTHS and object_pixel_width > 0:
        return (KNOWN_WIDTHS[class_name] * FOCAL_LENGTH) / object_pixel_width
    return float('inf')

# --- LOAD MODEL ---
@st.cache_resource
def load_yolo_model():
    return YOLO('yolov8n.pt')

# --- CUSTOM CSS ---
st.markdown("""
<style>
    .main { background: linear-gradient(135deg, #0f2027, #203a43, #2c5364); color: #ffffff; }
    h1, h2, h3, h4, h5, h6 { color: #ffffff !important; font-family: 'Segoe UI', sans-serif; }
    .stButton>button {
        border-radius: 12px; padding: 12px 24px; font-weight: bold; border: none;
        box-shadow: 0 4px 8px rgba(0,0,0,0.2); transition: all 0.3s ease;
    }
    .stButton>button:hover { transform: translateY(-2px); box-shadow: 0 6px 12px rgba(0,0,0,0.3); }
    .stAlert { border-radius: 12px; }
    .history-item { background: rgba(255,255,255,0.1); padding: 10px; margin: 5px 0; border-radius: 8px; }
    .made-with-love {
        text-align: center; padding: 20px; font-size: 14px; color: #aaa;
        border-top: 1px solid #333; margin-top: 40px;
    }
    .vibrate { animation: vibrate 0.3s linear infinite; }
    @keyframes vibrate { 0% { transform: translateX(0); } 25% { transform: translateX(2px); } 50% { transform: translateX(-2px); } 75% { transform: translateX(2px); } 100% { transform: translateX(0); } }
</style>
""", unsafe_allow_html=True)

# --- STREAMLIT UI ---
st.markdown("<h1 style='text-align: center;'>👁️ Smart Glasses for the Visually Impaired</h1>", unsafe_allow_html=True)
st.markdown("""
<div style='text-align: center; font-size: 1.2rem; margin-bottom: 2rem;'>
    Real-time object detection + AI scene understanding via your browser camera.
</div>
""", unsafe_allow_html=True)

# Sidebar
with st.sidebar:
    st.markdown("<h2 style='color: #4CAF50;'>🛠️ Controls</h2>", unsafe_allow_html=True)
    
    if st.button("📸 Describe Current Scene", use_container_width=True):
        if st.session_state.latest_frame is not None:
            with st.spinner("Capturing & analyzing scene..."):
                temp_path = tempfile.NamedTemporaryFile(delete=False, suffix='.jpg').name
                cv2.imwrite(temp_path, st.session_state.latest_frame)
                desc = describe_scene(temp_path)
                st.toast("✅ Description generated!", icon="🧠")
                st.image(st.session_state.latest_frame, caption="Analyzed Frame", channels="BGR", use_column_width=True)
        else:
            st.warning("⚠️ No frame captured. Take a snapshot first.")

    st.markdown("---")
    st.markdown("<h3 style='color: #4CAF50;'>⚙️ Settings</h3>", unsafe_allow_html=True)
    confidence_threshold = st.slider("🎯 Confidence Threshold", 0.0, 1.0, 0.5, 0.05)

# Tabs
tab1, tab2, tab3 = st.tabs(["📹 Live Camera", "🖼️ Upload Image", "📜 History"])

# Tab 1: Browser Camera
with tab1:
    st.markdown("### 👁️ Real-Time Detection via Browser Camera")
    st.info("Click below to allow camera access. Your browser will ask for permission.")

    img_file_buffer = st.camera_input("📷 Take Snapshot for Analysis", key="camera_input")

    if img_file_buffer is not None:
        bytes_data = img_file_buffer.getvalue()
        cv2_img = cv2.imdecode(np.frombuffer(bytes_data, np.uint8), cv2.IMREAD_COLOR)
        st.session_state.latest_frame = cv2_img.copy()

        with st.spinner("Loading YOLO model (first time only)..."):
            model = load_yolo_model()

        results = model.track(cv2_img, persist=True, tracker="botsort.yaml", verbose=False)
        annotated_frame = results[0].plot()

        st.image(annotated_frame, channels="BGR", caption="Detected Objects", use_column_width=True)

        detected_objects = []
        if results[0].boxes.id is not None:
            for box in results[0].boxes:
                class_id = int(box.cls[0])
                class_name = model.names[class_id]
                if class_name not in KNOWN_WIDTHS:
                    continue
                
                x1, y1, x2, y2 = box.xyxy[0]
                pixel_width = x2 - x1
                distance = estimate_distance(pixel_width, class_name)
                if distance > MAX_DISTANCE_METERS:
                    continue

                image_width = cv2_img.shape[1]
                box_center_x = (x1 + x2) / 2
                direction = "in front of you"
                if box_center_x < image_width / 3:
                    direction = "from your left"
                elif box_center_x > image_width * 2 / 3:
                    direction = "from your right"

                detected_objects.append({
                    "class": class_name,
                    "distance": distance,
                    "direction": direction
                })

        if detected_objects:
            nearest = min(detected_objects, key=lambda x: x['distance'])
            announcement = f"Nearest obstacle: {nearest['class']} {nearest['direction']}, {nearest['distance']:.1f} meters."
            speak_text_browser(announcement)
            st.toast(f"🔊 {announcement}", icon="📢")
        else:
            speak_text_browser("The path ahead appears clear.")
            st.toast("✅ Path is clear.", icon="🟢")

    else:
        st.markdown("""
        <div style='background: rgba(255,255,255,0.1); padding: 30px; border-radius: 16px; text-align: center;'>
            <h3>👉 Click 'Take Snapshot' above to start</h3>
            <p>Your browser will ask to access camera — please allow it.</p>
        </div>
        """, unsafe_allow_html=True)

# Tab 2: Upload Image
with tab2:
    st.markdown("### 🖼️ Describe Any Uploaded Image")
    st.info("Upload JPG/PNG. Gemini will describe the scene for safe navigation.")

    uploaded_image = st.file_uploader("Choose an image...", type=["jpg", "jpeg", "png"])

    if uploaded_image is not None:
        image = Image.open(uploaded_image)
        st.image(image, caption="Uploaded Image", use_column_width=True)

        open_cv_image = np.array(image)
        if len(open_cv_image.shape) == 3 and open_cv_image.shape[2] == 4:
            open_cv_image = cv2.cvtColor(open_cv_image, cv2.COLOR_RGBA2BGR)
        else:
            open_cv_image = cv2.cvtColor(open_cv_image, cv2.COLOR_RGB2BGR)

        st.session_state.latest_frame = open_cv_image.copy()

        if st.button("🧠 Describe This Image", use_container_width=True, type="primary"):
            with st.spinner("Analyzing with Gemini Flash..."):
                temp_path = tempfile.NamedTemporaryFile(delete=False, suffix='.jpg').name
                cv2.imwrite(temp_path, open_cv_image)
                description = describe_scene(temp_path)
                
                if any(kw in description.lower() for kw in ["caution", "danger", "warning", "careful"]):
                    st.error(f"⚠️ {description}")
                else:
                    st.success(f"✅ {description}")

# Tab 3: Description History
with tab3:
    st.markdown("### 📜 Scene Description History")
    if st.session_state.description_history:
        for i, record in enumerate(reversed(st.session_state.description_history)):
            if i >= 20: break
            if any(kw in record.lower() for kw in ["caution", "danger", "warning"]):
                st.markdown(f"<div class='history-item vibrate'>{record}</div>", unsafe_allow_html=True)
            else:
                st.markdown(f"<div class='history-item'>{record}</div>", unsafe_allow_html=True)
    else:
        st.info("No descriptions yet. Use camera or upload image.")

# Footer
st.markdown("""
<div class="made-with-love">
    Made with ❤️ and ♿ for independent, safe navigation.<br>
    <small>v2.2 • YOLOv8 + Gemini Flash • 100% Browser-Powered</small>
</div>
""", unsafe_allow_html=True)
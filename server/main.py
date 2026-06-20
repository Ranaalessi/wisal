import json
from collections import deque
from contextlib import asynccontextmanager
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np
import uvicorn
from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse


SERVER_DIR = Path(__file__).resolve().parent
PROJECT_ROOT = SERVER_DIR.parent

MODEL_NAMES = {
    "Salman.glb": ("Salman.glb",),
    "Najd.glb": ("Najd.glb",),
    "Salman_salam.glb": ("Salman_salam.glb",),
    "Najd_salam.glb": ("Najd_salam.glb",),
}
DICTIONARY_NAMES = ("sign_motion_dictionary.json",)
CAMERA_DICTIONARY_NAMES = ("camera_motion_templates.json",)

SEQUENCE_LENGTH = 24
MAX_CAPTURED_FRAMES = 64
HAND_MODEL_PATH = SERVER_DIR / "hand_landmarker.task"


def find_file(names):
    for name in names:
        candidates = (
            SERVER_DIR / name,
            SERVER_DIR / "models" / name,
            SERVER_DIR / "signs" / name,
            SERVER_DIR / "public" / name,
            SERVER_DIR / "public" / "models" / name,
            SERVER_DIR / "assets" / "signs" / name,
            SERVER_DIR / "assets" / "web_avatar" / name,
            PROJECT_ROOT / "assets" / "signs" / name,
            PROJECT_ROOT / "assets" / "web_avatar" / name,
        )
        for candidate in candidates:
            if candidate.is_file():
                return candidate
    return None


def dictionary_path():
    return find_file(DICTIONARY_NAMES)


def camera_dictionary_path():
    return find_file(CAMERA_DICTIONARY_NAMES)


def model_path(model_name):
    names = MODEL_NAMES.get(model_name)
    return find_file(names) if names else None


def load_camera_template():
    path = camera_dictionary_path()
    if path is None:
        raise RuntimeError("camera_motion_templates.json was not found")

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list) or not data:
        raise RuntimeError("camera_motion_templates.json is empty or invalid")

    template = data[0]
    sequence = np.asarray(template["sequence"], dtype=np.float32)
    if sequence.ndim != 2 or sequence.shape[1] != 66:
        raise RuntimeError("Camera template must contain frames with 66 values")

    return template["label"], sequence


CAMERA_LABEL, CAMERA_TEMPLATE = load_camera_template()

if not HAND_MODEL_PATH.is_file():
    raise RuntimeError(f"Hand landmark model was not found: {HAND_MODEL_PATH}")

# This is the MediaPipe Tasks API. Do not use mp.solutions.hands in this file.
hand_options = mp.tasks.vision.HandLandmarkerOptions(
    base_options=mp.tasks.BaseOptions(model_asset_path=str(HAND_MODEL_PATH)),
    running_mode=mp.tasks.vision.RunningMode.IMAGE,
    num_hands=1,
    min_hand_detection_confidence=0.55,
    min_hand_presence_confidence=0.55,
)
hand_detector = mp.tasks.vision.HandLandmarker.create_from_options(hand_options)


def normalize_landmarks(landmarks, handedness):
    points = np.asarray(
        [[point.x, point.y, point.z] for point in landmarks],
        dtype=np.float32,
    )
    wrist = points[0].copy()
    relative = points - wrist

    if handedness.lower() == "left":
        relative[:, 0] *= -1
        wrist[0] = 1.0 - wrist[0]

    palm_size = np.linalg.norm(relative[9])
    if palm_size < 1e-6:
        palm_size = 1.0

    wrist[:2] -= 0.5
    return np.concatenate(
        [(relative / palm_size).reshape(-1), wrist]
    ).astype(np.float32)


def resample(sequence, length=SEQUENCE_LENGTH):
    values = np.asarray(sequence, dtype=np.float32)
    if len(values) == 1:
        return np.repeat(values, length, axis=0)

    source = np.linspace(0.0, 1.0, len(values))
    target = np.linspace(0.0, 1.0, length)
    output = np.empty((length, values.shape[1]), dtype=np.float32)
    for column in range(values.shape[1]):
        output[:, column] = np.interp(target, source, values[:, column])
    return output


def velocity(sequence):
    return np.diff(sequence, axis=0, prepend=sequence[:1])


def sequence_distance(first, second):
    weights = np.ones(first.shape[1], dtype=np.float32)
    weights[63:] = 3.0
    return float(np.mean(((first - second) ** 2) * weights))


def score_sequence(sequence):
    sampled = resample(sequence)
    pose_score = sequence_distance(sampled, CAMERA_TEMPLATE)
    velocity_score = sequence_distance(velocity(sampled), velocity(CAMERA_TEMPLATE))
    return pose_score + (velocity_score * 1.6)


def movement_stats(sequence):
    values = np.asarray(sequence, dtype=np.float32)
    wrist = values[:, 63:65]
    travel = np.linalg.norm(np.diff(wrist, axis=0), axis=1).sum()
    span = max(
        float(wrist[:, 0].max() - wrist[:, 0].min()),
        float(wrist[:, 1].max() - wrist[:, 1].min()),
    )
    return float(travel), span


@asynccontextmanager
async def lifespan(_app):
    print(f"Dictionary: {dictionary_path()}")
    print(f"Camera dictionary: {camera_dictionary_path()}")
    print(f"Camera word: {CAMERA_LABEL}")
    print(f"Hand model: {HAND_MODEL_PATH}")
    for model_name in MODEL_NAMES:
        print(f"{model_name}: {model_path(model_name)}")
    yield
    hand_detector.close()


app = FastAPI(title="Wisal Server", version="5.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/")
async def root():
    return {
        "status": "Wisal Server is Online",
        "dictionary": "/api/sign-dictionary",
        "camera_dictionary": "/api/camera-sign-dictionary",
        "camera_websocket": "/ws/sign_language/",
    }


@app.get("/test")
async def test():
    return {
        "status": "connected",
        "dictionary_exists": dictionary_path() is not None,
        "camera_dictionary_exists": camera_dictionary_path() is not None,
        "camera_word": CAMERA_LABEL,
        "hand_model_exists": HAND_MODEL_PATH.is_file(),
        "salman_exists": model_path("Salman.glb") is not None,
        "najd_exists": model_path("Najd.glb") is not None,
        "salman_salam_exists": model_path("Salman_salam.glb") is not None,
        "najd_salam_exists": model_path("Najd_salam.glb") is not None,
    }


@app.get("/api/sign-dictionary")
async def get_sign_dictionary():
    path = dictionary_path()
    if path is None:
        raise HTTPException(404, "sign_motion_dictionary.json was not found")
    return json.loads(path.read_text(encoding="utf-8"))


@app.get("/api/camera-sign-dictionary")
async def get_camera_sign_dictionary():
    path = camera_dictionary_path()
    if path is None:
        raise HTTPException(404, "camera_motion_templates.json was not found")
    return json.loads(path.read_text(encoding="utf-8"))


@app.get("/signs/sign_motion_dictionary.json")
async def download_sign_dictionary():
    path = dictionary_path()
    if path is None:
        raise HTTPException(404, "Sign dictionary was not found")
    return FileResponse(path, media_type="application/json")


@app.get("/models/{model_name}")
async def download_model(model_name: str):
    path = model_path(model_name)
    if path is None:
        raise HTTPException(404, "Model was not found")
    return FileResponse(path, media_type="model/gltf-binary", filename=model_name)


@app.websocket("/ws/sign_language/")
async def sign_language_socket(websocket: WebSocket):
    await websocket.accept()
    frames = deque(maxlen=MAX_CAPTURED_FRAMES)

    try:
        while True:
            image_bytes = await websocket.receive_bytes()
            image_array = np.frombuffer(image_bytes, dtype=np.uint8)
            frame = cv2.imdecode(image_array, cv2.IMREAD_COLOR)

            if frame is None:
                await websocket.send_json({"status": "error", "message": "الصورة غير صالحة"})
                continue

            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
            result = hand_detector.detect(image)

            if not result.hand_landmarks:
                await websocket.send_json(
                    {"status": "waiting", "message": "أدخل يدك داخل الكاميرا"}
                )
                continue

            handedness = "right"
            if result.handedness and result.handedness[0]:
                handedness = result.handedness[0][0].category_name.lower()

            frames.append(normalize_landmarks(result.hand_landmarks[0], handedness))

            if len(frames) < 12:
                await websocket.send_json(
                    {
                        "status": "collecting",
                        "frames": len(frames),
                        "message": "جاري التقاط الحركة",
                    }
                )
                continue

            score = score_sequence(list(frames))
            travel, span = movement_stats(list(frames))
            is_salam = score <= 1.15 and travel >= 0.25 and span >= 0.10

            await websocket.send_json(
                {
                    "status": "matched" if is_salam else "unknown",
                    "text": CAMERA_LABEL if is_salam else "الإشارة غير موجودة",
                    "score": round(score, 4),
                    "travel": round(travel, 3),
                    "span": round(span, 3),
                }
            )
    except WebSocketDisconnect:
        print("Camera WebSocket disconnected")


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=5000)

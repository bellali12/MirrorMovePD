from flask import Flask, request, jsonify
import socket
import ipaddress
import tkinter as tk
import customtkinter as ctk
from PIL import Image, ImageTk
import cv2
import mediapipe as mp
import numpy as np
import threading
import time
import os
import simpleaudio as sa
import queue
import random
import shutil
import subprocess
import sys
import tempfile
import wave
from pathlib import Path
from typing import Optional
import sounddevice as sd

"""
ISSUES:
- merge old toast with new popup
- embed the connection popup into the main window
"""

command_queue = queue.Queue()

# Reduce OpenCV internal thread usage (prevents file decode from hogging CPU)
# Tune this if your CPU has more cores; 2 often works well on macOS without starving other threads.
OPENCV_THREADS = 2
try:
    cv2.setNumThreads(OPENCV_THREADS)
    cv2.ocl.setUseOpenCL(False)
except Exception:
    pass

# ----- CONFIG -----


def resource_path(relative_path: str) -> str:
    base_path = getattr(sys, "_MEIPASS", os.path.dirname(
        os.path.abspath(__file__)))
    return os.path.join(base_path, relative_path)


VIDEOS_DIR = resource_path("videos")
AUDIO_DIR = resource_path("audio")
IMAGES_DIR = resource_path("images")
SESSION_TITLES = [
    "Every Breath You Take",
    "Dance of the Sugar Plum Fairy",
    "All That Jazz",
    "New York, New York",
]
SESSION_FILES = [resource_path(f"videos/{title}.mp4")
                 for title in SESSION_TITLES]
REFERENCE_VIDEO_PATH = SESSION_FILES[0]
SONG_TO_INDEX = {title: index for index, title in enumerate(SESSION_TITLES)}


USER_CAMERA_INDEX = 0
FPS = 30
VIDEO_WIDTH = 480
VIDEO_HEIGHT = 640
APP_BG_COLOR = "#d9d9d9"

DEFAULT_SOUND_FILE_PATH = resource_path("audio/birds_chirping.wav")
STITCH_FACE_PATH = resource_path("images/stitch face.png")

# Allow overriding the Flask port (useful if it is taken by something else)
SERVER_PORT = int(os.environ.get("MIRRORMOTION_PORT", "5003"))

# ----- Flask Server -----
flask_app = Flask(__name__)

is_connected = False
song_metadata_registry = {}
current_song_state = {
    "title": os.path.splitext(os.path.basename(REFERENCE_VIDEO_PATH))[0],
    "artist": "",
    "duration": "",
    "level": None,
    "playing": False,
}


@flask_app.route('/status', methods=['GET'])
def status():
    return jsonify({
        "connected": is_connected,
        "ip": get_lan_ip(),
        "port": SERVER_PORT,
        "currentSong": dict(current_song_state),
    }), 200


@flask_app.route('/connect', methods=['POST'])
def connect():
    global is_connected
    is_connected = True
    return jsonify({"connected": True}), 200


@flask_app.route('/disconnect', methods=['POST'])
def disconnect():
    global is_connected
    is_connected = False
    _set_current_song_playing(False)
    return jsonify({"connected": False}), 200


@flask_app.route('/song_data', methods=['POST'])
def song_data():
    data = request.json
    print(f"Received song data: {data}")
    _register_song_metadata(data)
    target_name = data.get("title", "")
    matched_video = _find_video_path_by_title(target_name)

    if matched_video:
        title = Path(matched_video).stem
        print(f"Matched video file: {matched_video}")
        _set_current_song(title, playing=False)
        command_queue.put(f"start_new_session:{title}")
    else:
        print(f"No matching video found for: {target_name}")

    return jsonify({"status": "received"}), 200


@flask_app.route('/command', methods=['POST'])
def command():
    # assuming body: jsonEncode({'command': command}),
    data = request.json
    print("Received Raw Data:", data)
    command = data.get("command", "")
    print("Received command:", command)

    command_queue.put(command)

    # if command == "play_session":
    #     pass
    # elif command == "prev_session":
    #     pass
    # elif command == "next_session":
    #     pass
    # elif command.startswith("set_volume:"):
    #     volume = float(command.split(":")[1])
    # elif command.startswith("change_difficulty:"):
    #     level = int(command.split(":")[1])

    return jsonify({"status": "ok"}), 200


def run_flask(host: str = "0.0.0.0", port: int = SERVER_PORT):
    # threaded + no reloader to avoid spawning a second process
    flask_app.run(host=host, port=port, threaded=True, use_reloader=False)


def get_lan_ip(prefer_prefix: str = "192.168.") -> str:
    candidates = set()
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, family=socket.AF_INET):
            candidates.add(info[4][0])
    except Exception:
        pass

    s = None
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        candidates.add(s.getsockname()[0])
    except Exception:
        pass
    finally:
        try:
            if s:
                s.close()
        except Exception:
            pass

    def good(ip):
        try:
            a = ipaddress.ip_address(ip)
            return a.is_private and not a.is_loopback and not str(a).endswith(".0") and not str(a).endswith(".255")
        except Exception:
            return False

    # print("LAN IP candidates:", candidates)

    sorted_candidates = sorted(candidates)
    for ip in sorted_candidates:
        if ip.startswith(prefer_prefix) and good(ip):
            return ip
    for ip in sorted_candidates:
        # print("Checking candidate IP:", ip)
        # print("Is good?", good(ip))
        if good(ip):
            return ip
    return "127.0.0.1"


def button_callback():
    print("button clicked")


def _song_key(title: str) -> str:
    return str(title).strip().lower()


def _register_song_metadata(song_data):
    title = str(song_data.get("title", "")).strip()
    if not title:
        return

    song_metadata_registry[_song_key(title)] = {
        "title": title,
        "artist": str(song_data.get("artist", "")).strip(),
        "duration": str(song_data.get("duration", "")).strip(),
        "level": song_data.get("level"),
    }


def _normalize_media_name(value: str) -> str:
    return " ".join(str(value).strip().lower().split())


def _find_video_path_by_title(title: str):
    target = _normalize_media_name(title)

    for path in SESSION_FILES:
        if _normalize_media_name(Path(path).stem) == target:
            return path

    videos_dir = Path(VIDEOS_DIR)
    if not videos_dir.exists():
        return None

    for path in videos_dir.iterdir():
        if path.is_file() and path.suffix.lower() == ".mp4":
            if _normalize_media_name(path.stem) == target:
                return str(path)
    return None


def _find_audio_path_by_title(title: str):
    target = _normalize_media_name(title)
    audio_dir = Path(AUDIO_DIR)
    if not audio_dir.exists():
        return None

    for path in sorted(audio_dir.iterdir()):
        if not path.is_file():
            continue
        if path.suffix.lower() not in {".mp3", ".wav"}:
            continue
        if target in _normalize_media_name(path.stem):
            return str(path)
    return None


def _load_overlay_image(path: str):
    if not path:
        return None

    overlay = cv2.imread(path, cv2.IMREAD_UNCHANGED)
    if overlay is None or overlay.ndim != 3 or overlay.shape[2] != 4:
        return None
    return overlay


def _blend_overlay(frame, overlay, x: int, y: int, width: int, height: int):
    if overlay is None or width <= 0 or height <= 0:
        return frame

    frame_h, frame_w = frame.shape[:2]
    x1 = max(0, x)
    y1 = max(0, y)
    x2 = min(frame_w, x + width)
    y2 = min(frame_h, y + height)
    if x1 >= x2 or y1 >= y2:
        return frame

    overlay_resized = cv2.resize(
        overlay, (width, height), interpolation=cv2.INTER_LINEAR)
    crop_x1 = x1 - x
    crop_y1 = y1 - y
    crop_x2 = crop_x1 + (x2 - x1)
    crop_y2 = crop_y1 + (y2 - y1)
    overlay_crop = overlay_resized[crop_y1:crop_y2, crop_x1:crop_x2]

    alpha = overlay_crop[:, :, 3:4].astype(float) / 255.0
    if alpha.size == 0:
        return frame

    background = frame[y1:y2, x1:x2].astype(float)
    foreground = overlay_crop[:, :, :3].astype(float)
    blended = foreground * alpha + background * (1.0 - alpha)
    frame[y1:y2, x1:x2] = blended.astype(frame.dtype)
    return frame


def _set_current_song(title: str, playing=None):
    global current_song_state
    normalized_title = str(title).strip()
    if not normalized_title:
        return

    metadata = song_metadata_registry.get(_song_key(normalized_title), {})
    current_song_state = {
        "title": normalized_title,
        "artist": str(metadata.get("artist", "")).strip(),
        "duration": str(metadata.get("duration", "")).strip(),
        "level": metadata.get("level"),
        "playing": current_song_state.get("playing", False)
        if playing is None
        else bool(playing),
    }


def _set_current_song_playing(playing: bool):
    global current_song_state
    current_song_state = {
        **current_song_state,
        "playing": bool(playing),
    }


class SoundPlayer:
    def __init__(self, path: str):
        self.path = path
        self._volume = 0.4
        self._audio_data = None
        self._sample_rate = None
        self._channels = 0
        self._frame_index = 0
        self._stream = None
        self._should_play = False
        self._cache_dir = Path(tempfile.gettempdir()) / \
            "mirrormotion_audio_cache"
        self._cache_dir.mkdir(parents=True, exist_ok=True)
        self._lock = threading.Lock()
        self._mpg123_path = shutil.which("mpg123")
        self._lame_path = shutil.which("lame")

        self._load_source(path)

    def _decoded_audio_path(self, path: str) -> str:
        source = Path(path)
        if source.suffix.lower() == ".wav":
            return str(source)

        target = self._cache_dir / \
            f"{source.stem}-{int(source.stat().st_mtime)}.wav"
        source_stat = source.stat()
        if target.exists():
            target_stat = target.stat()
            if target_stat.st_mtime >= source_stat.st_mtime and target_stat.st_size > 0:
                return str(target)

        if target.exists():
            target.unlink()

        if self._mpg123_path:
            subprocess.run(
                [self._mpg123_path, "-q", "-w", str(target), str(source)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        elif self._lame_path:
            subprocess.run(
                [self._lame_path, "--quiet", "--decode",
                    str(source), str(target)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        else:
            raise RuntimeError(
                "No MP3 decoder available for desktop audio playback.")
        return str(target)

    def _load_source(self, path: str):
        decoded_path = self._decoded_audio_path(path)
        sample_rate, data = self._read_wav_file(decoded_path)
        audio = self._normalize_audio_data(data)

        with self._lock:
            self.path = path
            self._sample_rate = int(sample_rate)
            self._audio_data = audio
            self._channels = int(audio.shape[1])
            self._frame_index = 0

        self._close_stream()

    def _read_wav_file(self, path: str):
        with wave.open(path, "rb") as wav_file:
            channels = wav_file.getnchannels()
            sample_rate = wav_file.getframerate()
            sample_width = wav_file.getsampwidth()
            frame_count = wav_file.getnframes()
            raw_frames = wav_file.readframes(frame_count)

        dtype_by_width = {
            1: np.uint8,
            2: np.int16,
            4: np.int32,
        }
        dtype = dtype_by_width.get(sample_width)
        if dtype is None:
            raise ValueError(f"Unsupported WAV sample width: {sample_width}")

        data = np.frombuffer(raw_frames, dtype=dtype)
        if channels > 1:
            data = data.reshape(-1, channels)
        return sample_rate, data

    def _normalize_audio_data(self, data):
        audio = np.asarray(data)
        if audio.ndim == 1:
            audio = audio[:, np.newaxis]

        if audio.dtype == np.uint8:
            audio = (audio.astype(np.float32) - 128.0) / 128.0
        elif np.issubdtype(audio.dtype, np.integer):
            scale = float(np.iinfo(audio.dtype).max)
            audio = audio.astype(np.float32) / scale
        else:
            audio = audio.astype(np.float32)

        return np.clip(audio, -1.0, 1.0)

    def _rebuild_stream(self):
        was_playing = self._should_play and self._stream is not None and self._stream.active
        self._close_stream()

        if self._audio_data is None or self._sample_rate is None or self._channels <= 0:
            return

        self._stream = sd.OutputStream(
            samplerate=self._sample_rate,
            channels=self._channels,
            dtype="float32",
            callback=self._audio_callback,
        )
        if was_playing:
            self._stream.start()

    def _audio_callback(self, outdata, frames, time_info, status):
        del time_info
        if status:
            print(f"Audio callback status: {status}")

        outdata.fill(0)
        with self._lock:
            if self._audio_data is None:
                return

            start = self._frame_index
            end = min(start + frames, len(self._audio_data))
            chunk = self._audio_data[start:end]
            if len(chunk) == 0:
                return

            volume = self._volume
            outdata[:len(chunk)] = chunk * volume
            self._frame_index = end

            if self._frame_index >= len(self._audio_data):
                self._should_play = False
                self._frame_index = len(self._audio_data)
                raise sd.CallbackStop()

    def _close_stream(self):
        if self._stream is None:
            return
        try:
            if self._stream.active:
                self._stream.stop()
        except Exception:
            pass
        try:
            self._stream.close()
        except Exception:
            pass
        self._stream = None

    def start(self):
        self._should_play = True
        with self._lock:
            if self._audio_data is None:
                return
            if self._frame_index >= len(self._audio_data):
                self._frame_index = 0

        if self._stream is None:
            self._rebuild_stream()
        if self._stream is not None and not self._stream.active:
            self._stream.start()

    def stop(self):
        self._should_play = False
        if self._stream is not None and self._stream.active:
            self._stream.stop()

    def set_source(self, path: str):
        path = str(path)
        if not path or path == self.path:
            return

        was_playing = self._should_play
        self._should_play = False
        self._load_source(path)
        if was_playing:
            self.start()

    def set_volume(self, volume_percent: float):
        volume_percent = max(0.0, min(100.0, float(volume_percent)))
        new_volume = volume_percent / 100.0
        if abs(new_volume - self._volume) < 0.001:
            return

        self._volume = new_volume

    def close(self):
        self._should_play = False
        self._close_stream()


class VideoPanel(ctk.CTkFrame):
    def __init__(self, parent, source, display_width=VIDEO_WIDTH, display_height=VIDEO_HEIGHT, face_overlay_path: Optional[str] = None):
        super().__init__(parent)
        self.cap = cv2.VideoCapture(source)
        if not self.cap.isOpened():
            raise ValueError("Unable to open video source", source)
        self._rotation_degrees = int(self.cap.get(
            cv2.CAP_PROP_ORIENTATION_META) or 0) % 360
        self._face_overlay_enabled = bool(face_overlay_path)
        self._face_overlay = _load_overlay_image(
            face_overlay_path) if face_overlay_path else None
        self._face_detection = None
        self._face_detection_counter = 0
        self._last_face_bbox = None

        self._display_width = 0
        self._display_height = 0
        self.pack_propagate(False)

        # Ask backend for smaller frames to reduce work
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, VIDEO_WIDTH)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, VIDEO_HEIGHT)
        # Reduce camera buffering/latency if supported
        try:
            if isinstance(source, int):
                self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)
        except Exception:
            pass

        self.label = ctk.CTkLabel(
            self, text="", width=VIDEO_WIDTH, height=VIDEO_HEIGHT)
        self.label.pack(expand=True, padx=10, pady=10)

        # Worker thread state
        self._running = True
        self._paused = True
        # store RGB frame (UI only creates PhotoImage)
        self._latest_rgb = None
        self._latest_ver = 0         # increment when a new frame arrives
        self._drawn_ver = -1         # last drawn version
        self._lock = threading.Lock()
        self._frame = None
        self._ctkimg = None  # keep a reference to CTkImage

        # Pace the reader to the source FPS (fallback to UI FPS, clamp to sane range)
        src_fps = self.cap.get(cv2.CAP_PROP_FPS) or 0
        if src_fps <= 0 or src_fps > 120:
            src_fps = FPS
        self._period = 1.0 / float(src_fps)

        if self._face_overlay_enabled:
            self._face_detection = mp.solutions.face_detection.FaceDetection(
                model_selection=0,
                min_detection_confidence=0.5,
            )

        # Start background reader
        self._reader_thread = threading.Thread(
            target=self._reader_loop, daemon=True)
        self._reader_thread.start()

        self.set_display_size(display_width, display_height)

    def get_display_size(self):
        return self._display_width, self._display_height

    def set_display_size(self, width: int, height: int):
        width = max(1, int(round(width)))
        height = max(1, int(round(height)))
        if width == self._display_width and height == self._display_height:
            return

        self._display_width = width
        self._display_height = height
        self.configure(width=width + 20, height=height + 20)
        self.label.configure(width=width, height=height)
        # Force a redraw even when the video is paused.
        self._drawn_ver = -1

    def set_paused(self, paused: bool):
        self._paused = paused

    def _reader_loop(self):
        next_t = time.monotonic()
        while self._running:

            if self._paused:
                time.sleep(0.05)
                continue

            ret, frame = self.cap.read()
            if not ret:
                # If file ended or temporary hiccup, don't spin
                time.sleep(0.02)
                continue

            if self._rotation_degrees == 90:
                frame = cv2.rotate(frame, cv2.ROTATE_90_CLOCKWISE)
            elif self._rotation_degrees == 180:
                frame = cv2.rotate(frame, cv2.ROTATE_180)
            elif self._rotation_degrees == 270:
                frame = cv2.rotate(frame, cv2.ROTATE_90_COUNTERCLOCKWISE)

            if self._face_overlay_enabled and self._face_overlay is not None:
                frame = self._apply_face_overlay(frame)

            # Scale down (if needed) and center-crop in the worker thread
            h, w, _ = frame.shape
            if h > VIDEO_HEIGHT:
                scale = VIDEO_HEIGHT / h
                frame = cv2.resize(frame, (int(w * scale), VIDEO_HEIGHT))
                h, w, _ = frame.shape

            start_x = max(0, w // 2 - VIDEO_WIDTH // 2)
            start_y = max(0, h // 2 - VIDEO_HEIGHT // 2)
            end_x = min(w, start_x + VIDEO_WIDTH)
            end_y = min(h, start_y + VIDEO_HEIGHT)
            frame = frame[start_y:end_y, start_x:end_x]

            # Convert to RGB off the UI thread
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)

            with self._lock:
                self._latest_rgb = rgb
                self._latest_ver += 1

            # Throttle to source FPS so we don't starve other threads
            next_t += self._period
            sleep_dt = next_t - time.monotonic()
            if sleep_dt > 0:
                time.sleep(min(sleep_dt, 0.02))
            else:
                next_t = time.monotonic()

    def _apply_face_overlay(self, frame):
        if self._face_detection is None:
            return frame

        self._face_detection_counter = (self._face_detection_counter + 1) % 3
        frame_h, frame_w = frame.shape[:2]

        if self._face_detection_counter == 0 or self._last_face_bbox is None:
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            results = self._face_detection.process(rgb)
            detection = results.detections[0] if results and results.detections else None
            if detection is None:
                self._last_face_bbox = None
                return frame

            rel_box = detection.location_data.relative_bounding_box
            x = int(rel_box.xmin * frame_w)
            y = int(rel_box.ymin * frame_h)
            width = int(rel_box.width * frame_w)
            height = int(rel_box.height * frame_h)
            self._last_face_bbox = (x, y, width, height)

        if self._last_face_bbox is None:
            return frame

        x, y, width, height = self._last_face_bbox
        overlay_width = max(1, int(width * 1.7))
        overlay_height = max(1, int(height * 1.95))
        overlay_x = x - (overlay_width - width) // 2
        overlay_y = y - int(height * 0.9)
        return _blend_overlay(
            frame,
            self._face_overlay,
            overlay_x,
            overlay_y,
            overlay_width,
            overlay_height,
        )

    def draw_latest(self):
        # Very light work on the UI thread: only create image if a new frame arrived
        with self._lock:
            if self._latest_rgb is None or self._latest_ver == self._drawn_ver:
                return
            rgb = self._latest_rgb
            ver = self._latest_ver

        pil_img = self._resize_to_fill(Image.fromarray(rgb))
        # Use CTkImage to avoid HiDPI warning
        self._ctkimg = ctk.CTkImage(
            light_image=pil_img,
            dark_image=pil_img,
            size=(self._display_width, self._display_height),
        )
        self.label.configure(image=self._ctkimg, text="")
        self._drawn_ver = ver

    def _resize_to_fill(self, image: Image.Image) -> Image.Image:
        if image.width <= 0 or image.height <= 0:
            return image

        scale = max(
            self._display_width / image.width,
            self._display_height / image.height,
        )
        resized_width = max(1, int(round(image.width * scale)))
        resized_height = max(1, int(round(image.height * scale)))
        resampling = (
            Image.Resampling.LANCZOS
            if hasattr(Image, "Resampling")
            else Image.LANCZOS
        )
        resized = image.resize((resized_width, resized_height), resampling)

        left = max(0, (resized_width - self._display_width) // 2)
        top = max(0, (resized_height - self._display_height) // 2)
        right = left + self._display_width
        bottom = top + self._display_height
        return resized.crop((left, top, right, bottom))

    def release(self):
        self._running = False
        try:
            if self._reader_thread.is_alive():
                self._reader_thread.join(timeout=0.5)
        except Exception:
            pass
        if self._face_detection is not None:
            self._face_detection.close()
        if self.cap.isOpened():
            self.cap.release()


class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        ctk.set_appearance_mode("light")
        ctk.set_default_color_theme("blue")
        self.title("MirrorMotion")
        self.configure(bg=APP_BG_COLOR)
        # self.app_connected = False
        self._popup_shown_this_session = False

        # Session Variables
        self._difficulty = 1
        self._volume = 40
        self.after(250, self._poll_commands)

        self._sessions = list(SESSION_FILES)
        self._session_index = 0
        self._master_sessions = list(SESSION_FILES)

        # Toast state
        self._toast_window = None
        self._toast_bind_id = None
        self._left_panel_ratio = 1.0
        self._right_panel_ratio = 1.0
        self._panel_animation_job = None
        self._last_connection_state = False

        self.sound_player = SoundPlayer(
            _find_audio_path_by_title(Path(REFERENCE_VIDEO_PATH).stem)
            or DEFAULT_SOUND_FILE_PATH
        )

        self.content = ctk.CTkFrame(self, fg_color=APP_BG_COLOR)
        self.content.pack(padx=20, pady=20, fill="both", expand=True)

        self.content.grid_columnconfigure(0, weight=1)
        self.content.grid_columnconfigure(
            1, weight=0, minsize=VIDEO_WIDTH + 20)
        self.content.grid_columnconfigure(
            2, weight=0, minsize=VIDEO_WIDTH + 20)
        self.content.grid_columnconfigure(3, weight=1)
        self.content.grid_rowconfigure(0, weight=1)

        self.left_panel = VideoPanel(self.content, REFERENCE_VIDEO_PATH)
        self.right_panel = VideoPanel(
            self.content,
            USER_CAMERA_INDEX,
            face_overlay_path=STITCH_FACE_PATH,
        )
        # Webcam view is never paused
        self.right_panel.set_paused(False)

        self.left_panel.grid(
            row=0, column=1, padx=(8, 4), pady=8)
        self.right_panel.grid(
            row=0, column=2, padx=(4, 8), pady=8)

        self.protocol("WM_DELETE_WINDOW", self.on_closing)

        self.left_panel.set_paused(True)
        self._apply_panel_proportion(
            self._left_panel_ratio,
            self._right_panel_ratio,
            redraw=False,
        )

        # Embedded Connection Bar at Bottom Center
        self.connection_bar = ctk.CTkFrame(
            self, fg_color="#4F4451", corner_radius=12)
        self.connection_bar.grid_columnconfigure(0, weight=1)

        self.connection_label = ctk.CTkLabel(
            self.connection_bar,
            text="Not Connected",
            text_color="white",
            font=ctk.CTkFont(size=14, weight="bold"),
        )
        self.connection_label.grid(row=0, column=0, padx=(14, 10), pady=10)
        self.connection_close_btn = ctk.CTkButton(
            self.connection_bar, text="✕", width=28, height=28, corner_radius=14,
            fg_color="#444444", hover_color="#555555",
            command=self._hide_ip_toast
        )
        self.connection_close_btn.grid(row=0, column=1, padx=10, pady=8)

        self.connection_bar.pack(side="bottom", fill="x")

        # UI Loop
        self._delay = int(1000 / FPS)
        self._updating = True
        self.after(self._delay, self._update_frames)

        # Start checking connection to control the toast
        self.after(200, self._update_connection_toast)
        self.after(100, self._bring_to_front)

    def _bring_to_front(self):
        try:
            self.update_idletasks()
            self.lift()
            self.focus_force()

            self.attributes('-topmost', True)
            self.after(200, lambda: self.attributes('-topmost', False))
        except Exception as e:
            print("Error bringing window to front:", e)

    def _poll_commands(self):
        while True:
            try:
                command = command_queue.get_nowait()
            except queue.Empty:
                break

            self._handle_command(command)

        self.after(250, self._poll_commands)

    def _parse_panel_proportion(self, proportion: str):
        parts = [part.strip() for part in proportion.split("/", 1)]
        if len(parts) != 2:
            return None

        try:
            left = float(parts[0])
            right = float(parts[1])
        except ValueError:
            return None

        if left <= 0 or right <= 0:
            return None

        return left, right

    def _proportion_to_panel_sizes(self, left_ratio: float, right_ratio: float):
        total_ratio = max(0.1, float(left_ratio) + float(right_ratio))
        total_width = VIDEO_WIDTH * 2
        left_width = int(round(total_width * (left_ratio / total_ratio)))
        left_width = min(total_width - 1, max(1, left_width))
        right_width = max(1, total_width - left_width)
        return (
            (left_width, VIDEO_HEIGHT),
            (right_width, VIDEO_HEIGHT),
        )

    def _apply_panel_proportion(self, left_ratio: float, right_ratio: float, redraw: bool = True):
        self._left_panel_ratio = left_ratio
        self._right_panel_ratio = right_ratio

        (left_width, left_height), (right_width, right_height) = (
            self._proportion_to_panel_sizes(left_ratio, right_ratio)
        )

        self.left_panel.set_display_size(left_width, left_height)
        self.right_panel.set_display_size(right_width, right_height)
        self.content.grid_columnconfigure(1, minsize=left_width + 20)
        self.content.grid_columnconfigure(2, minsize=right_width + 20)

        if redraw:
            self.left_panel.draw_latest()
            self.right_panel.draw_latest()

    def _animate_panel_proportion(self, left_ratio: float, right_ratio: float, duration_ms: int = 260, steps: int = 12):
        if self._panel_animation_job is not None:
            try:
                self.after_cancel(self._panel_animation_job)
            except Exception:
                pass
            self._panel_animation_job = None

        start_left = self._left_panel_ratio
        start_right = self._right_panel_ratio

        def ease_in_out(t: float) -> float:
            return 3 * t * t - 2 * t * t * t

        def animate_step(step: int = 0):
            progress = step / steps
            eased = ease_in_out(progress)
            current_left = start_left + (left_ratio - start_left) * eased
            current_right = start_right + (right_ratio - start_right) * eased
            self._apply_panel_proportion(current_left, current_right)

            if step >= steps:
                self._panel_animation_job = None
                return

            delay = max(1, duration_ms // steps)
            self._panel_animation_job = self.after(
                delay, lambda: animate_step(step + 1)
            )

        animate_step()

    def _handle_command(self, command: str):
        print("Handling command:", command)

        if command == "play_session":
            if self.left_panel._paused:
                self.left_panel.set_paused(False)
                _set_current_song_playing(True)
                self.sound_player.start()
            else:
                self.left_panel.set_paused(True)
                _set_current_song_playing(False)
                self.sound_player.stop()
        elif command == "prev_session":
            self._session_index -= 1
            self._switch_session(self._session_index)
        elif command == "next_session":
            self._session_index += 1
            self._switch_session(self._session_index)
        elif command.startswith("set_volume:"):
            volume = float(command.split(":")[1])
            self._volume = volume
            self.sound_player.set_volume(volume)
            print("Set volume to:", volume)
        # for now assum difficulty determines pose tolerance
        elif command.startswith("change_difficulty:"):
            level = int(command.split(":")[1])
            self._difficulty = level
            print("Set difficulty to:", level)

        elif command.startswith("start_new_session"):
            song_name = command.split(":", 1)[1]
            song_idx = SONG_TO_INDEX.get(song_name)
            if song_idx is None:
                print(f"Unknown session requested: {song_name}")
                return
            self._switch_session(song_idx)

        elif command.startswith("change_proportion:"):
            proportion = command.split(":", 1)[1].strip()
            print("Received proportion:", proportion)
            scales = self._parse_panel_proportion(proportion)
            if scales is None:
                print("Invalid proportion:", proportion)
                return

            self._animate_panel_proportion(*scales)

    def _switch_session(self, index: int):
        pass  # TODO: assume countdown upon new session

        if not self._sessions:
            return

        # If overflow to higher levels, regenerate new sequence
        # If overflow to previous levels, stops working
        if index < 0:
            return
        if index == len(self._sessions):
            chosen_session = random.choice(self._master_sessions)
            self._sessions.append(chosen_session)

        new_path = self._sessions[index]
        self._session_index = index
        print('Switching to session')
        song_title = os.path.splitext(os.path.basename(new_path))[0]
        _set_current_song(song_title, playing=False)

        session_parent = self.left_panel.master
        current_width, current_height = self.left_panel.get_display_size()
        self.left_panel.release()
        self.left_panel.destroy()

        self.left_panel = VideoPanel(
            session_parent,
            new_path,
            display_width=current_width,
            display_height=current_height,
        )
        self.left_panel.grid(
            row=0, column=1, padx=(8, 4), pady=8)
        self.left_panel.set_paused(True)
        self._apply_panel_proportion(
            self._left_panel_ratio,
            self._right_panel_ratio,
            redraw=False,
        )
        self.sound_player.set_source(
            _find_audio_path_by_title(song_title) or DEFAULT_SOUND_FILE_PATH
        )
        self.sound_player.stop()

    def _show_ip_popup(self):
        """Show a one-time, clearer message in the embedded connection bar."""
        lan_ip = get_lan_ip()
        code = self.ip_to_connection_code(lan_ip)

        self.connection_label.configure(
            text=f"Connect your mobile app using code: {code}"
        )

        if not self.connection_bar.winfo_manager():
            self.connection_bar.pack(side="bottom", fill="x")

        self._popup_shown_this_session = True

    # ----- Persistent bottom-center IP toast while not connected -----
    def ip_to_connection_code(self, ip: str) -> str:
        try:
            parts = ip.split(".")  # 192.168.12.5 --> ['192', '168', '12', '5']
            if len(parts) == 4:
                return ".".join(parts[2:])  # '12.5'
            return ip
        except Exception:
            return ip

    def _ensure_ip_toast(self):

        ip = get_lan_ip()
        connection_code = self.ip_to_connection_code(ip)

        self.connection_label.configure(
            text=f"Connection Code: {connection_code}"
        )

        if not self.connection_bar.winfo_ismapped():
            self.connection_bar.pack(side="bottom", fill="x")
            self.update_idletasks()

    def _hide_ip_toast(self):
        if self.connection_bar and self.connection_bar.winfo_manager():
            self.connection_bar.pack_forget()

    def _update_connection_toast(self):
        currently_connected = is_connected

        if not currently_connected:
            self._ensure_ip_toast()
            if self._last_connection_state:
                self.left_panel.set_paused(True)
                _set_current_song_playing(False)
                self.sound_player.stop()
            if not self._popup_shown_this_session:
                self._show_ip_popup()

        else:
            self._hide_ip_toast()
            if not self._last_connection_state:
                self.left_panel.set_paused(False)
                _set_current_song_playing(True)
                self.sound_player.start()
            self._popup_shown_this_session = True
        self._last_connection_state = currently_connected
        self.after(500, self._update_connection_toast)
    # ----- end toast -----

    def _update_frames(self):
        if self._updating:
            # Draw whichever panel has a new frame; UI work stays minimal
            self.left_panel.draw_latest()
            self.right_panel.draw_latest()
            self.after(self._delay, self._update_frames)

            # self._show_ip_popup()

    def on_closing(self):
        self._updating = False
        self.left_panel.release()
        self.right_panel.release()
        self.sound_player.close()
        self._hide_ip_toast()
        self.destroy()


if __name__ == "__main__":
    # Start Flask server in the background so mobile app can connect
    server_thread = threading.Thread(
        target=run_flask, kwargs={"host": "0.0.0.0", "port": SERVER_PORT}, daemon=True
    )
    server_thread.start()

    app = App()
    app.geometry(f"{2*VIDEO_WIDTH + 80}x{VIDEO_HEIGHT + 80}")
    app.minsize(VIDEO_WIDTH*2 + 80, VIDEO_HEIGHT + 80 + 40)
    app.mainloop()

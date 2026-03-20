from flask import Flask, request, jsonify
import socket
import ipaddress
import tkinter as tk
import customtkinter as ctk
from PIL import Image, ImageTk
import cv2
import threading
import time
import os
import simpleaudio as sa
import queue
import random

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
REFERENCE_VIDEO_PATH = "videos/Every Breath You Take.mp4"
SONG_TO_INDEX = {
    "Every Breath You Take": 0,
    "All That Jazz": 1,
    "Dance of the Sugar Plum Fairy": 2,
    "New York, New York": 3
}


USER_CAMERA_INDEX = 0
FPS = 30
VIDEO_WIDTH = 480
VIDEO_HEIGHT = 640
APP_BG_COLOR = "#d9d9d9"

SOUND_FILE_PATH = "audio/birds_chirping.wav"

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

    # Get all the filenames in the 'videos' directory
    video_filenames = os.listdir('videos')
    print(f"Available video files: {video_filenames}")

    target_name = data.get("title", "")

    for filename in video_filenames:
        # Strip off the extension
        name_without_ext = os.path.splitext(filename)[0]
        if name_without_ext.lower() == target_name.lower():
            print(f"Matched video file: {filename}")
            _set_current_song(name_without_ext, playing=False)
            command_queue.put(f"start_new_session:{filename[:-4]}")

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
        self._wave_obj = None
        self._play_obj = None
        self._should_play = False
        self._running = True

        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def _loop(self):
        while self._running:
            if self._should_play:
                if (self._play_obj is None) or (not self._play_obj.is_playing()):
                    try:
                        if self._wave_obj is None:
                            self._wave_obj = sa.WaveObject.from_wave_file(
                                self.path)

                        self._play_obj = self._wave_obj.play()
                    except Exception:
                        print("Error playing sound")
                        time.sleep(0.1)
                time.sleep(0.1)
            else:
                if self._play_obj is not None and self._play_obj.is_playing():
                    self._play_obj.stop()
                    self._play_obj = None
                time.sleep(0.1)

    def start(self):
        self._should_play = True

    def stop(self):
        self._should_play = False
        if self._play_obj is not None and self._play_obj.is_playing():
            self._play_obj.stop()
            self._play_obj = None

    def close(self):
        self._running - False
        self.stop()


class VideoPanel(ctk.CTkFrame):
    def __init__(self, parent, source, display_width=VIDEO_WIDTH, display_height=VIDEO_HEIGHT):
        super().__init__(parent)
        self.cap = cv2.VideoCapture(source)
        if not self.cap.isOpened():
            raise ValueError("Unable to open video source", source)

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

        self._sessions = ['videos/Every Breath You Take.mp4',
                          'videos/Dance of the Sugar Plum Fairy.mp4',
                          'videos/All That Jazz.mp4',
                          'videos/New York, New York.mp4',
                          ]
        self._session_index = 0
        self._master_sessions = ['videos/Every Breath You Take.mp4',
                                 'videos/Dance of the Sugar Plum Fairy.mp4',
                                 'videos/All That Jazz.mp4',
                                 'videos/New York, New York.mp4',
                                 ]

        # Toast state
        self._toast_window = None
        self._toast_bind_id = None
        self._left_panel_ratio = 1.0
        self._right_panel_ratio = 1.0
        self._panel_animation_job = None
        self._last_connection_state = False

        self.sound_player = SoundPlayer(SOUND_FILE_PATH)

        self.content = ctk.CTkFrame(self, fg_color=APP_BG_COLOR)
        self.content.pack(padx=20, pady=20, fill="both", expand=True)

        self.content.grid_columnconfigure(0, weight=1)
        self.content.grid_columnconfigure(1, weight=0, minsize=VIDEO_WIDTH + 20)
        self.content.grid_columnconfigure(2, weight=0, minsize=VIDEO_WIDTH + 20)
        self.content.grid_columnconfigure(3, weight=1)
        self.content.grid_rowconfigure(0, weight=1)

        self.left_panel = VideoPanel(self.content, REFERENCE_VIDEO_PATH)
        self.right_panel = VideoPanel(self.content, USER_CAMERA_INDEX)
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
                # self.sound_player.start()
            else:
                self.left_panel.set_paused(True)
                _set_current_song_playing(False)
                # self.sound_player.stop()
        elif command == "prev_session":
            self._session_index -= 1
            self._switch_session(self._session_index)
        elif command == "next_session":
            self._session_index += 1
            self._switch_session(self._session_index)
        elif command.startswith("set_volume:"):
            volume = float(command.split(":")[1])
            self._volume = volume
            print("Set volume to:", volume)
        # for now assum difficulty determines pose tolerance
        elif command.startswith("change_difficulty:"):
            level = int(command.split(":")[1])
            self._difficulty = level
            print("Set difficulty to:", level)

        elif command.startswith("start_new_session"):
            song_name = command.split(":")[1]
            song_idx = SONG_TO_INDEX[song_name]
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
            # self.sound_player.stop()
            if not self._popup_shown_this_session:
                self._show_ip_popup()

        else:
            self._hide_ip_toast()
            if not self._last_connection_state:
                self.left_panel.set_paused(False)
                _set_current_song_playing(True)
            # self.sound_player.start()
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

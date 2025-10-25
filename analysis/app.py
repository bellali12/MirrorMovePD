from flask import Flask, request, jsonify
import tkinter as tk
import customtkinter as ctk
from PIL import Image, ImageTk
import cv2
import threading
import socket

# ----- CONFIG -----
REFERENCE_VIDEO_PATH = "videos/IMG_8404.mp4"
USER_CAMERA_INDEX = 0
FPS = 30
VIDEO_WIDTH = 480
VIDEO_HEIGHT = 640
APP_BG_COLOR = "#d9d9d9"

# ----- Flask Server -----
app = Flask(__name__)


@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "ok"}), 200


def run_flask(host: str = "0.0.0.0", port: int = 5000):
    app.run(host=host, port=port)


def get_lan_ip(prefer_prefix: str = "192.168.") -> str:
    candidates = set()

    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, family=socket.AF_INET):
            candidates.add(info[4][0])
    except Exception:
        pass

    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        candidates.add(s.getsockname()[0])
    except Exception:
        pass
    finally:
        s.close()

    for ip in candidates:
        if ip.startswith(prefer_prefix):
            return ip

    # TODO: there might be other addresses, handle later
    return "127.0.0.1"


def button_callback():
    print("button clicked")


class VideoPanel(ctk.CTkFrame):
    def __init__(self, parent, source):
        super().__init__(parent)
        self.cap = cv2.VideoCapture(source)
        if not self.cap.isOpened():
            raise ValueError("Unable to open video source", source)

        self.label = ctk.CTkLabel(
            self, text="", width=VIDEO_WIDTH, height=VIDEO_HEIGHT)
        self.label.pack(fill="both", expand=True, padx=10, pady=10)
        self._frame = None

    def read_and_draw(self):
        ret, frame = self.cap.read()
        if not ret:
            # TODO: Go to next video if available, for now just halt
            return
        # frame = cv2.resize(frame, (VIDEO_WIDTH, VIDEO_HEIGHT))
        # Instead of resize, crop to center
        h, w, _ = frame.shape

        # Scale down if frame height is larger than the image height
        if h > VIDEO_HEIGHT:
            scale = VIDEO_HEIGHT / h
            frame = cv2.resize(frame, (int(w*scale), VIDEO_HEIGHT))
            h, w, _ = frame.shape

        start_x = w//2 - VIDEO_WIDTH//2
        start_y = h//2 - VIDEO_HEIGHT//2
        frame = frame[start_y:start_y+VIDEO_HEIGHT,
                      start_x:start_x+VIDEO_WIDTH]

        frame = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        img = Image.fromarray(frame)
        self._frame = ImageTk.PhotoImage(image=img)
        self.label.configure(image=self._frame)

    def release(self):
        if self.cap.isOpened():
            self.cap.release()


class App(ctk.CTk):
    def __init__(self):
        super().__init__()
        ctk.set_appearance_mode("light")
        ctk.set_default_color_theme("blue")
        self.title("MirrorMotion")
        self.configure(bg=APP_BG_COLOR)
        self.app_connected = False

        content = ctk.CTkFrame(self, fg_color=APP_BG_COLOR)
        content.pack(padx=20, pady=20, fill="both", expand=True)

        content.grid_columnconfigure(0, weight=1)
        content.grid_columnconfigure(1, weight=1)
        content.grid_rowconfigure(0, weight=1)

        self.left_panel = VideoPanel(content, REFERENCE_VIDEO_PATH)
        self.right_panel = VideoPanel(content, USER_CAMERA_INDEX)

        self.left_panel.grid(
            row=0, column=0, sticky="nsew", padx=(8, 4), pady=8)
        self.right_panel.grid(
            row=0, column=1, sticky="nsew", padx=(4, 8), pady=8)

        self.protocol("WM_DELETE_WINDOW", self.on_closing)

        # UI Loop
        self._delay = int(1000 / FPS)
        self._updating = True
        self.after(self._delay, self._update_frames)

    def _show_ip_popup(self):
        if not self.app_connected:
            lan_ip = get_lan_ip()
            popup = ctk.CTkToplevel(self)
            popup.title("Connection Info")
            popup.geometry("300x150")
            popup.configure(bg=APP_BG_COLOR)

            label = ctk.CTkLabel(
                popup, text=f"Connect your mobile app to:\nIP Address: {lan_ip}\nPort: 5000", bg=APP_BG_COLOR)
            label.pack(pady=20, padx=20)

            button = ctk.CTkButton(
                popup, text="OK", command=popup.destroy)
            button.pack(pady=10)

            self.app_connected = True

    def _update_frames(self):
        if self._updating:
            self.left_panel.read_and_draw()
            self.right_panel.read_and_draw()
            self.after(self._delay, self._update_frames)

            # self._show_ip_popup()

    def on_closing(self):
        self._updating = False
        self.left_panel.release()
        self.right_panel.release()
        self.destroy()


if __name__ == "__main__":
    # app = ctk.CTk()
    # app.geometry("400x150")

    # button = ctk.CTkButton(
    #     app, text="my button", command=button_callback)
    # button.pack(padx=20, pady=20)

    app = App()

    app.geometry(f"{2*VIDEO_WIDTH + 80}x{VIDEO_HEIGHT + 80}")
    app.minsize(VIDEO_WIDTH*2 + 80, VIDEO_HEIGHT + 80)

    app.mainloop()

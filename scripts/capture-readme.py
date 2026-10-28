#!/usr/bin/env python3
"""Capture the README images in docs/ from the running Connect IQ simulator.

Starts the demo build (scripts/run-screenshots.sh, fixed events) twice: once in the
simulator's glance launch mode for the glance shot, once in normal mode for the rest.
Opens the simulator if needed. The app running this script needs Screen
Recording and Accessibility ("Device Control and Data Access") in macOS privacy settings.

Drives the simulator with keys: Down = DOWN, Return = START, Escape = BACK.
Needs Pillow. Run from anywhere: python3 -I scripts/capture-readme.py
"""
import json
import pathlib
import subprocess
import sys
import tempfile
import time

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"
SIZE = 360
# Watch head inside the 2x window capture of the fenix 9 Pro Solar 47mm simulator
WATCH_BOX = (40, 235, 810, 1005)
KEY_DOWN, KEY_START, KEY_BACK = 125, 36, 53

FIND_WINDOW = """
ObjC.import("CoreGraphics");
var l = ObjC.castRefToObject($.CGWindowListCopyWindowInfo($.kCGWindowListOptionAll, 0));
var r = "";
for (var i = 0; i < l.count; i++) {
  var w = l.objectAtIndex(i);
  var n = ObjC.unwrap(w.objectForKey("kCGWindowName"));
  if (n && n.indexOf("CIQ Simulator") == 0) r = ObjC.unwrap(w.objectForKey("kCGWindowNumber"));
}
JSON.stringify(r);
"""


def find_window():
    out = subprocess.run(["osascript", "-l", "JavaScript", "-e", FIND_WINDOW],
                         check=True, capture_output=True, text=True).stdout
    return json.loads(out)


def osascript(*lines):
    args = ["osascript"]
    for line in lines:
        args += ["-e", line]
    subprocess.run(args, check=True, capture_output=True)


def press(key_code, wait=1.2):
    osascript('tell application "System Events" to tell process "simulator" to set frontmost to true',
              "delay 0.3",
              f'tell application "System Events" to key code {key_code}')
    time.sleep(wait)


def launch(mode):
    """Set Glance Launch Mode ("Glance" or "Normal") and (re)start the demo build"""
    item = (f'menu item "Launch in {mode} Mode" of menu 1 of menu item "Glance Launch Mode" '
            'of menu 1 of menu bar item "Settings" of menu bar 1')
    osascript('tell application "System Events" to tell process "simulator" to set frontmost to true',
              "delay 0.5",
              f'tell application "System Events" to tell process "simulator" to click {item}')
    mark = subprocess.run(["osascript", "-e", 'tell application "System Events" to tell process '
                           f'"simulator" to get value of attribute "AXMenuItemMarkChar" of {item}'],
                          capture_output=True, text=True).stdout.strip()
    if mark != "✓":
        sys.exit(f"Could not switch the simulator to {mode} launch mode")
    subprocess.run(["pkill", "-f", "monkeydo"])
    time.sleep(1)
    subprocess.Popen([str(ROOT / "scripts" / "run-screenshots.sh")],
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(20)


def shot(window_id, path):
    subprocess.run(["screencapture", "-x", "-o", "-l", str(window_id), str(path)], check=True)


def watch(path):
    """Crop to the watch head and make the white window background transparent"""
    im = Image.open(path).convert("RGBA").crop(WATCH_BOX)
    for corner in [(0, 0), (im.width - 1, 0), (0, im.height - 1), (im.width - 1, im.height - 1)]:
        ImageDraw.floodfill(im, corner, (255, 255, 255, 0), thresh=40)
    return im.resize((SIZE, SIZE), Image.LANCZOS)


def main():
    window_id = find_window()
    if not window_id:
        # run-screenshots.sh opens the simulator when it is not running
        subprocess.Popen([str(ROOT / "scripts" / "run-screenshots.sh")],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        time.sleep(30)
        window_id = find_window()
    if not window_id:
        sys.exit("Simulator window not found")

    DOCS.mkdir(exist_ok=True)
    tmp = pathlib.Path(tempfile.mkdtemp())

    def capture(name, key=None, wait=1.2):
        path = tmp / f"{name}.png"
        if key is not None:
            # The simulator sometimes swallows a key (e.g. the first after focusing it):
            # press again if the screen did not change
            shot(window_id, tmp / "before.png")
            before = Image.open(tmp / "before.png").tobytes()
            for _ in range(3):
                press(key, wait)
                shot(window_id, path)
                if Image.open(path).tobytes() != before:
                    break
        else:
            shot(window_id, path)
        return watch(path)

    launch("Glance")
    capture("glance").save(DOCS / "glance.png", optimize=True)
    launch("Normal")

    # Opens on the glance event (Sober, third of four); DOWN wraps around the list
    capture("event-sober").save(DOCS / "event-sober.png", optimize=True)
    pages = {"moved": capture("moved", KEY_DOWN)}
    for name in ["running", "married", "sober"]:
        pages[name] = capture(name, KEY_DOWN)
    frames = [pages[n] for n in ["running", "married", "sober", "moved"]]
    frames[0].save(DOCS / "browse.gif", save_all=True, append_images=frames[1:],
                   duration=1600, loop=0, disposal=2, optimize=True)

    capture("menu", KEY_START, 1.5).save(DOCS / "menu.png", optimize=True)
    press(KEY_DOWN)
    capture("edit", KEY_START, 1.5).save(DOCS / "edit.png", optimize=True)
    for _ in range(3):
        press(KEY_BACK, 1.0)
    subprocess.run(["pkill", "-f", "monkeydo"])
    print("Saved:", ", ".join(sorted(p.name for p in DOCS.iterdir())))


if __name__ == "__main__":
    main()

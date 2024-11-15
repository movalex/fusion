import pyautogui
import time


from resolve_utils import ResolveUtility
utils = ResolveUtility()


clips = utils.get_clips_in_timeline(track_number=1)


short_clips = utils.get_clips_in_timeline(track_type="audio", track_number=3)
timeline = utils.get_current_timeline()
ends = []
for clip in short_clips:
    clip_end = clip.GetEnd()
    ends.append(clip_end)


timeline.SetCurrentTimecode("0")

# Get the DaVinci Resolve window
window = pyautogui.getWindowsWithTitle("DaVinci Resolve Studio")[0]

for n, clip in enumerate(clips):
    try:
        timeline.SetCurrentTimecode(str(ends[n]))
        # Activate the window
        window.activate()

        # Give it a moment to activate
        time.sleep(0.3)

        # Emulate pressing the 'c' key
        pyautogui.press("c")
        pyautogui.press("down")
        pyautogui.press("up")

        # Emulate pressing the 'backspace' key
        pyautogui.press("backspace")
    except IndexError:
        pass

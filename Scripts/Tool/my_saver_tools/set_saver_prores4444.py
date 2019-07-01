if tool.ID != 'Saver':
    print("this tool works with saver only")
else:
    tool.QuickTimeMovies.Compression = "Apple ProRes 4444_ap4h"
    tool.QuickTimeMovies.FrameRateFps = 25

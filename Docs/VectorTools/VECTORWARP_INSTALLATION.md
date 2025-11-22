# VectorWarp Installation & Usage Guide

Version 2.0

## Overview

**VectorWarp** is an advanced Fusion macro for motion tracking, stabilization, and warping effects. It creates STMaps (spatial transformation maps) using optical flow analysis for reusable distortion maps that can stabilize footage, track motion, or create warping effects.

---

## Installation

### Required Files

The following files must be installed in your Fusion user paths:

#### Macro File
Copy to `Macros:\` folder:
```
Macros/
└── VectorWarp.setting
```

#### Lua Module Dependencies
Copy these to `Modules:\Lua\` folder:
```
Modules/Lua/
├── fusionlib.lua                 (Required - Core utilities)
└── vectorwarp_utilities.lua      (Required for VectorWarp)
```

#### Optional UTF-8 Support
For paths containing non-Latin characters (Cyrillic, Chinese, etc.):
```
Modules/Lua/
└── win-125x.lua                  (Optional - UTF-8 path support)
```

### Installation Steps

1. **Locate your Fusion user paths**
   - Windows: `%APPDATA%\Blackmagic Design\Fusion\`
   - macOS: `~/Library/Application Support/Blackmagic Design/Fusion/`
   - Linux: `~/.fusion/BlackmagicDesign/Fusion/`

2. **Copy macro file**
   ```
   Copy VectorWarp.setting → Fusion/Macros/
   ```

3. **Copy Lua modules**
   ```
   Copy fusionlib.lua → Fusion/Modules/Lua/
   Copy vectorwarp_utilities.lua → Fusion/Modules/Lua/
   ```

4. **Optional: Copy UTF-8 module** (for non-Latin path support)
   ```
   Copy win-125x.lua → Fusion/Modules/Lua/
   ```

5. **Restart Fusion** to load the new macro

6. **Verify installation**
   - Open Fusion
   - Press Shift+Space and type "VectorWarp"
   - Macro should appear in the search results

---

## Key Features

- Optical flow-based motion analysis
- STMap generation for reusable tracking data
- Multiple analysis directions (forward, backward, bidirectional)
- Professional stabilization workflows
- Compatible with STMapper and Texture nodes

---

## Workflows

### Auto Process (One-Click Workflow)
Complete workflow in one click - generates CleanPass, sets reference frame, and analyzes motion.
- Uses current frame as reference
- Ideal for general processing

### Quick Stabilize
Auto-stabilizes footage to remove camera shake.
- Automatically uses MIDDLE frame as reference
- Minimizes maximum warp distance (half compared to first/last frame)
- Reduces distortion artifacts
- Industry standard approach

### Track Forward
Tracks forward motion from current frame.
- Uses current frame as reference
- Ideal for following an object

### Manual Workflow
1. Connect footage input
2. Generate CleanPass (fast method recommended)
3. Set reference frame
4. Analyze motion vectors (forward/backward/both)
5. Connect output to STMapper or Texture node

---

## Dependencies

### fusionlib.lua (Core Library)

Provides core functionality:
- File operations and path handling
- UTF-8 support for non-Latin paths
- Composition validation and dialogs
- Loader/Saver frame management
- File copying and existence checking

### vectorwarp_utilities.lua

VectorWarp-specific automation functions:
- CleanPass generation (fast and safe methods)
- Reference frame management
- Motion analysis workflows
- Stabilization presets

---

## Technical Notes

### File Paths

- Default output to `comp:VectorWarp\render001.####.exr`
- Paths can be customized in the File tab

### Non-Latin Path Support

If your project paths contain non-Latin characters (Cyrillic, Chinese, Japanese, etc.):
1. Install `win-125x.lua` module to `Modules:\Lua\`
2. Use "Render CleanPass (safe)" method instead of fast method
3. The macro will attempt to load UTF-8 module automatically

### Frame Range Considerations

- Respects composition render range
- Start frames are automatically aligned to render start
- Created loaders properly inherit composition timing
- Sequential processing required for accurate results

---

## Requirements

- Blackmagic Fusion 9.0 or later (Fusion Studio)
- Sufficient disk space for cached EXR sequences
- For stabilization: STMapper node (available via Reactor)

---

## Troubleshooting

### Macro not appearing in Fusion
- Verify files are in correct `Macros:\` folder
- Restart Fusion
- Check console for Lua errors

### Lua module errors
- Ensure both .lua files are in `Modules:\Lua\` folder
- Check file permissions (must be readable)
- Verify no syntax errors by checking console output

### Non-Latin path issues
- Install `win-125x.lua` module
- Use safe rendering method instead of fast method
- Consider using Latin-only path names for temp files

### Frame range issues
- Use "Create Loader" button to create properly aligned loaders
- Check GlobalIn/GlobalOut values match composition render range
- Verify render start/end are set correctly

### Cache or rendering issues
- Purge Fusion cache (Shift+R)
- Verify disk space available
- Check saver output paths exist and are writable

---

## Support & Credits

### Authors
- Emilio Sapia
- Alexey Bogomolov
- Utilities: Module refactoring and automation (2024-2025)

### License
MIT License - Free to use and modify

### Resources
- GitHub: https://github.com/movalex/fusion
- Emilio Sapia Portfolio: https://emiliosapia.myportfolio.com

---

## Changelog

### Version 2.0 (October 2025)

**Critical Fixes:**
- Fixed create_loader frame range bug causing incorrect start frames
- Added missing move_clip function to fusionlib
- Improved error handling

**VectorWarp Improvements:**
- Renamed "Quick Track" to "Quick Track Forward"
- Enhanced workflow documentation
- Improved module structure

**Code Quality:**
- Refactored module dependencies
- Standardized naming conventions
- Enhanced inline documentation

---

**Last Updated**: November 07, 2025

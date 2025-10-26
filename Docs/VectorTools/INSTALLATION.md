# VectorWarp & VectorFill Installation Guide

Version 2.0 - Updated January 2025

## Overview

**VectorWarp** and **VectorFill** are advanced Fusion macros for motion tracking, stabilization, and organic growth effects. These tools require supporting Lua utility modules to function properly.

---

## Installation

### Required Files

The following files must be installed in your Fusion user paths:

#### Macro Files
Copy these to `Macros:\` folder:
```
Macros/
├── VectorWarp.setting
└── VectorFill.setting
```

#### Lua Module Dependencies
Copy these to `Modules:\Lua\` folder:
```
Modules/Lua/
├── fusionlib.lua                 (Required - Core utilities)
├── vectorwarp_utilities.lua      (Required for VectorWarp)
└── vectorfill_utilities.lua      (Required for VectorFill)
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

2. **Copy macro files**
   ```
   Copy VectorWarp.setting → Fusion/Macros/
   Copy VectorFill.setting → Fusion/Macros/
   ```

3. **Copy Lua modules**
   ```
   Copy fusionlib.lua → Fusion/Modules/Lua/
   Copy vectorwarp_utilities.lua → Fusion/Modules/Lua/
   Copy vectorfill_utilities.lua → Fusion/Modules/Lua/
   ```

4. **Optional: Copy UTF-8 module** (for non-Latin path support)
   ```
   Copy win-125x.lua → Fusion/Modules/Lua/
   ```

5. **Restart Fusion** to load the new macros

6. **Verify installation**
   - Open Fusion
   - Press Shift+Space and type "VectorWarp" or "VectorFill"
   - Macros should appear in the search results

---

## VectorWarp

### Description

Motion tracking and stabilization tool that creates STMaps (spatial transformation maps) using optical flow analysis. These reusable distortion maps can stabilize footage, track motion, or create warping effects.

### Key Features

- Optical flow-based motion analysis
- STMap generation for reusable tracking data
- Multiple analysis directions (forward, backward, bidirectional)
- Professional stabilization workflows
- Compatible with STMapper and Texture nodes

### Workflows

#### Auto Process (One-Click Workflow)
Complete workflow in one click - generates CleanPass, sets reference frame, and analyzes motion.
- Uses current frame as reference
- Ideal for general processing

#### Quick Stabilize
Auto-stabilizes footage to remove camera shake.
- Automatically uses MIDDLE frame as reference
- Minimizes maximum warp distance (half compared to first/last frame)
- Reduces distortion artifacts
- Industry standard approach

#### Track Forward
Tracks forward motion from current frame.
- Uses current frame as reference
- Ideal for following an object

#### Manual Workflow
1. Connect footage input
2. Generate CleanPass (fast method recommended)
3. Set reference frame
4. Analyze motion vectors (forward/backward/both)
5. Connect output to STMapper or Texture node

### Recent Changes (January 2025)

- Fixed create_loader bug causing incorrect frame ranges (2002 instead of 1001)
- Added move_loader function to properly align frame values
- Refactored module dependencies for better code organization
- Renamed "Quick Track" to "Quick Track Forward" for clarity
- Improved error handling and validation
- Enhanced documentation in controls

---

## VectorFill

### Description

Creates organic growth and propagation effects where a source image expands from defined starting points, with growth speed controlled by various map sources. Perfect for ink spreading, organic reveals, and growth animations.

### Key Features

- Iterative frame-by-frame growth propagation
- Multiple speed source options (Texture, Shape, Interior, Combined, Custom)
- Real-time output mode switching
- Canvas-based workflow with EXR caching
- Trail and gradient visualization modes

### Output Modes

- **Render**: Live calculation with full quality (slower playback)
- **Age**: Baked cached instance (faster playback, fixed result)
- **Trail**: Dynamic gradient-based coloring effect
- **Growth Speed**: Visualization of the active speed map

### Speed Source Options

- **Texture**: Uses input image texture patterns for growth speed variation
- **Shape**: Uses alpha shape with adjustable edge repetitions and width
- **Interior**: Uses alpha channel interior only
- **Combined**: Weighted mix of texture, shape, and interior sources
- **Custom**: External speed map image input via Speed Map input

### Workflow

#### Auto Process (Recommended)
1. Connect Image and Growth Source inputs
2. Click "Auto Process" button in Controls tab
3. Wait for canvas generation and processing (progress displayed in console)
4. Playback starts automatically showing growth effect
5. Switch output modes as needed

#### Manual Workflow
1. Connect inputs (Image, Growth Source, optional Speed Map)
2. Click "1. Render Canvas" to generate blank canvas sequence
3. Click "2. Go to Start" to move to render start frame
4. Click "3. Process Growth" to analyze and cache growth
5. Switch output modes for different visualization styles

### Recent Changes (January 2025)

#### Bug Fixes
- Fixed create_loader frame range bug (new loaders now correctly use composition render range)
- Fixed type checking errors in generate_canvas function
- Improved error handling and validation

#### New Features
- Split canvas generation into fast and safe methods
- Added generate_canvas_fast for quick single-frame copy workflow
- Added process_forward function for forward-only tracking
- New "File" control page for easier loader/saver access
- Added GlobalIn/GlobalOut controls for frame management

#### UI Improvements
- Reorganized control layout with clearer button labels
- Renamed controls with CT5_ prefix for consistency
- Improved button spacing and grouping
- Added render method selection (fast vs. safe)

#### Code Quality
- Refactored auto_process to remove unnecessary options parameter
- Extracted common patterns into helper functions
- Improved documentation and comments
- Standardized variable naming conventions

---

## Dependencies

### fusionlib.lua (Core Library)

Provides core functionality used by both macros:
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

### vectorfill_utilities.lua

VectorFill-specific automation functions:
- Canvas generation workflows
- Growth processing automation
- Output mode switching
- Cache management

---

## Technical Notes

### File Paths

- **VectorWarp**: Default output to `comp:VectorWarp\render001.####.exr`
- **VectorFill**: Default output to `comp:DistanceMap\DistMap1.####.exr`
- Paths can be customized in the File tab of each macro

### Non-Latin Path Support

If your project paths contain non-Latin characters (Cyrillic, Chinese, Japanese, etc.):
1. Install `win-125x.lua` module to `Modules:\Lua\`
2. Use "Render CleanPass (safe)" method in VectorWarp instead of fast method
3. Both macros will attempt to load UTF-8 module automatically

### Cache Management

- VectorFill saves intermediate frames as EXR sequences
- Use "Clear Cache" button to purge cached data
- Re-run Auto Process after parameter changes
- Cache purge recommended when changing growth parameters

### Frame Range Considerations

- Both macros respect composition render range
- Start frames are automatically aligned to render start
- Created loaders properly inherit composition timing
- Sequential processing required for accurate results

---

## Requirements

- Blackmagic Fusion 9.0 or later (Fusion Studio or Resolve Fusion page)
- Sufficient disk space for cached EXR sequences
- For VectorWarp stabilization: STMapper node (available via Reactor)

---

## Troubleshooting

### Macros not appearing in Fusion
- Verify files are in correct `Macros:\` folder
- Restart Fusion
- Check console for Lua errors

### Lua module errors
- Ensure all three .lua files are in `Modules:\Lua\` folder
- Check file permissions (must be readable)
- Verify no syntax errors by checking console output

### Non-Latin path issues
- Install `win-125x.lua` module
- Use safe rendering methods instead of fast methods
- Consider using Latin-only path names for temp files

### Frame range issues
- Use "Create Loader" button to create properly aligned loaders
- Check GlobalIn/GlobalOut values match composition render range
- Verify render start/end are set correctly

### Cache or rendering issues
- Click "Clear Cache" button
- Purge Fusion cache (Shift+R)
- Verify disk space available
- Check saver output paths exist and are writable

---

## Support & Credits

### Authors
- **VectorWarp**: Emilio Sapia, Alexey Bogomolov
- **VectorFill**: Zeke Faust, Emilio Sapia, Alexey Bogomolov
- **Utilities**: Module refactoring and automation (2024-2025)

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
- Fixed type checking in canvas generation

**VectorFill Improvements:**
- Separated canvas generation into fast and safe methods
- Added process_forward for forward-only tracking
- New File control page for better organization
- Improved UI layout and button labels

**VectorWarp Improvements:**
- Renamed "Quick Track" to "Quick Track Forward"
- Enhanced workflow documentation
- Improved module structure

**Code Quality:**
- Refactored module dependencies
- Improved error handling
- Standardized naming conventions
- Enhanced inline documentation

---

**Last Updated**: October 26, 2025

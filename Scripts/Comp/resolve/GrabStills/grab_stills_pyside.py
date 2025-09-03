#!/usr/bin/env python3
"""
Grab Stills from Timeline - PySide6 Version

A DaVinci Resolve script to capture and export timeline stills with a modern PySide6 interface.

License: MIT
Copyright © 2024 Alexey Bogomolov
Email: mail@abogomolov.com
"""

import sys
import time
from pathlib import Path
from typing import Dict, Any, List, Optional


# Ensure shared Modules/Python is on sys.path so we don't need local copies
def _bootstrap_modules_path():
    candidates = []
    # Walk up several levels to find a Modules/Python folder
    try:
        here = Path(__file__).resolve()
    except NameError:
        # __file__ may be missing when run inside Resolve; fallback to argv or cwd
        if sys.argv and sys.argv[0]:
            try:
                here = Path(sys.argv[0]).resolve()
            except Exception:
                here = Path.cwd()
        else:
            here = Path.cwd()
    for parent in [here.parent] + list(here.parents):
        mod_path = parent / "Modules" / "Python"
        if mod_path.exists():
            candidates.append(mod_path)
            break
    # Fallback to user-provided absolute path
    candidates.append(Path(r"C:\Users\alexey.bogomolov\Documents\git\fusion\Modules\Python"))

    for p in candidates:
        try:
            if p and p.exists():
                sp = str(p)
                if sp not in sys.path:
                    sys.path.insert(0, sp)
                break
        except Exception:
            continue


try:
    from PySide6.QtWidgets import (
        QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
        QLabel, QComboBox, QCheckBox, QLineEdit, QPushButton, QGroupBox,
        QFileDialog, QMessageBox, QFrame, QSpacerItem, QSizePolicy
    )
    from PySide6.QtCore import Qt, QThread, QObject, Signal
    from PySide6.QtGui import QFont, QIcon
except ImportError:
    print("PySide6 not found. Please install with: pip install PySide6")
    sys.exit(1)

# DaVinci Resolve imports
try:
    import DaVinciResolveScript as dvr_script
    resolve = dvr_script.scriptapp("Resolve")
    fusion = resolve.Fusion()
except ImportError:
    _bootstrap_modules_path()
    from resolve_utils import ResolveUtility
    print("DaVinci Resolve scripting API not available")
    utils = ResolveUtility()
    resolve = utils.resolve
    fusion = resolve.Fusion()

# Constants
STILL_FRAME_REF = 2  # 1 - First frame, 2 - Middle frame
DEFAULT_STILL_ALBUM = "STILLS"
DEFAULT_STILL_FORMAT = "jpg"

# Marker colors as in Resolve
MARKER_COLORS = [
    "Any", "Blue", "Cyan", "Green", "Yellow", "Red", "Pink", "Purple",
    "Fuchsia", "Rose", "Lavender", "Sky", "Mint", "Lemon", "Sand", "Cocoa", "Cream"
]

# Export formats supported by ExportStills
STILL_FORMATS = {
    "dpx": "DPX Files (*.dpx)",
    "cin": "Cineon Files (*.cin)", 
    "tif": "TIFF Files (*.tif)",
    "jpg": "JPEG Files (*.jpg)",
    "png": "PNG Files (*.png)",
    "ppm": "PPM Files (*.ppm)",
    "bmp": "BMP Files (*.bmp)",
    "xpm": "XPM Files (*.xpm)",
}
STILL_FORMATS_ORDER = ["dpx", "cin", "tif", "jpg", "png", "ppm", "bmp", "xpm"]


class ResolveUtils:
    """Utility functions for DaVinci Resolve operations."""
    
    def __init__(self):
        self.resolve = resolve
        self.fusion = fusion
    
    def get_current_timeline(self):
        """Get the currently active timeline."""
        if not self.resolve:
            return None
        project = self.resolve.GetProjectManager().GetCurrentProject()
        return project.GetCurrentTimeline()
    
    def get_gallery(self):
        """Get the gallery object."""
        if not self.resolve:
            return None
        project = self.resolve.GetProjectManager().GetCurrentProject()
        return project.GetGallery()
    
    def get_still_album(self, gallery, album_name):
        """Get or create a still album."""
        if not gallery:
            return None
        
        albums = gallery.GetGalleryStillAlbums()
        for album in albums:
            if gallery.GetAlbumName(album) == album_name:
                return album
        
        # Create new album if not found
        return gallery.CreateStillAlbum(album_name)
    
    def frame_to_timecode(self, frame_number):
        """Convert frame number to timecode."""
        timeline = self.get_current_timeline()
        if not timeline:
            return "00:00:00:00"
        
        # Simple frame to timecode conversion (assuming 24fps)
        fps = 24
        hours = frame_number // (fps * 3600)
        minutes = (frame_number % (fps * 3600)) // (fps * 60)
        seconds = (frame_number % (fps * 60)) // fps
        frames = frame_number % fps
        
        return f"{hours:02d}:{minutes:02d}:{seconds:02d}:{frames:02d}"


class StillsWorker(QObject):
    """Worker thread for processing stills to avoid UI freezing."""
    
    progress = Signal(str)
    finished = Signal(bool, str)
    
    def __init__(self, options, utils):
        super().__init__()
        self.options = options
        self.utils = utils
    
    def run(self):
        """Execute the stills processing."""
        try:
            success = self.process_stills()
            if success:
                self.finished.emit(True, "Stills processing completed successfully!")
            else:
                self.finished.emit(False, "No stills were processed.")
        except Exception as e:
            self.finished.emit(False, f"Error: {str(e)}")
    
    def process_stills(self):
        """Main stills processing logic."""
        if not self.utils.resolve:
            self.progress.emit("Error: DaVinci Resolve not available")
            return False
        
        gallery = self.utils.get_gallery()
        if not gallery:
            self.progress.emit("Error: Could not access gallery")
            return False
        
        album_name = self.options.get("album", DEFAULT_STILL_ALBUM)
        still_album = self.utils.get_still_album(gallery, album_name)
        save_mode = self.options.get("save_mode", "per_marker")
        
        # Process based on save mode
        if save_mode == "export_existing":
            self.progress.emit("Getting existing stills from album...")
            stills = still_album.GetStills()
            if not stills:
                self.progress.emit(f"No existing stills found in album '{album_name}'")
                return False
            self.progress.emit(f"Found {len(stills)} existing stills")
        else:
            # Get timeline for grabbing new stills
            timeline = self.utils.get_current_timeline()
            if not timeline:
                self.progress.emit("Error: No active timeline")
                return False
            
            if save_mode == "per_marker":
                self.progress.emit("Grabbing stills from markers...")
                stills = self.grab_stills_from_markers(timeline, still_album)
            else:  # per_clip
                self.progress.emit("Grabbing stills from clips...")
                stills = timeline.GrabAllStills(STILL_FRAME_REF)
        
        if not stills:
            self.progress.emit("No stills to process")
            return False
        
        # Export if enabled
        if self.options.get("export", True):
            export_path = self.options.get("export_to")
            if not export_path:
                self.progress.emit("Error: No export path specified")
                return False
            
            self.export_stills(stills, still_album, gallery)
        
        return True
    
    def grab_stills_from_markers(self, timeline, still_album):
        """Grab stills from timeline markers."""
        markers = timeline.GetMarkers()
        if not markers:
            self.progress.emit("No markers found in timeline")
            return []
        
        color_filter = self.options.get("marker_color", "Any")
        stills = []
        
        for frame_id in sorted(markers.keys()):
            marker_data = markers[frame_id]
            if color_filter != "Any" and marker_data.get("color") != color_filter:
                continue
            
            # Navigate and grab
            timeline.SetCurrentTimecode(self.utils.frame_to_timecode(frame_id))
            self.progress.emit(f"Processing marker at frame {frame_id}")
            time.sleep(0.2)  # Small delay for stability
            
            still = timeline.GrabStill()
            marker_name = marker_data.get("name", "Unnamed")
            try:
                still_album.SetLabel(still, marker_name)
            except Exception:
                pass
            
            stills.append(still)
        
        return still_album.GetStills() if stills else []
    
    def export_stills(self, stills, still_album, gallery):
        """Export stills to files."""
        export_path = Path(self.options["export_to"])
        album_name = gallery.GetAlbumName(still_album)
        target_folder = export_path / album_name
        
        try:
            target_folder.mkdir(parents=True, exist_ok=True)
        except Exception as e:
            self.progress.emit(f"Error creating folder: {e}")
            return
        
        self.progress.emit(f"Exporting {len(stills)} stills to {target_folder}")
        
        # Reselect album before export (workaround)
        albums = gallery.GetGalleryStillAlbums()
        for album in albums:
            if album != still_album:
                gallery.SetCurrentStillAlbum(album)
                break
        gallery.SetCurrentStillAlbum(still_album)
        
        # Export stills
        export_format = self.options.get("format", DEFAULT_STILL_FORMAT)
        still_album.ExportStills(stills, str(target_folder), "", export_format)
        
        # Post-processing
        if self.options.get("delete_stills", False):
            still_album.DeleteStills(stills)
            self.progress.emit("Deleted stills from album")
        
        if self.options.get("cleanup_drx", False):
            self.cleanup_drx_files(target_folder)
        
        if self.options.get("open_edit", False):
            self.utils.resolve.OpenPage("edit")
    
    def cleanup_drx_files(self, folder):
        """Remove .drx files from export folder."""
        try:
            for file in folder.glob("*.drx"):
                file.unlink()
            self.progress.emit("Cleaned up .drx files")
        except Exception as e:
            self.progress.emit(f"Error cleaning up .drx files: {e}")


class GrabStillsDialog(QMainWindow):
    """Main dialog for grabbing stills."""
    
    def __init__(self):
        super().__init__()
        self.utils = ResolveUtils()
        self.worker_thread = None
        self.worker = None
        self.settings = self.load_settings()
        
        self.setWindowTitle("Grab Stills at Markers")
        self.setFixedSize(600, 500)
        self.setWindowFlags(Qt.Window | Qt.WindowCloseButtonHint)
        
        self.setup_ui()
        self.load_values()
        self.connect_signals()
    
    def setup_ui(self):
        """Set up the user interface."""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        layout = QVBoxLayout(central_widget)
        layout.setSpacing(12)
        
        # Title
        title = QLabel("Grab Stills at Markers")
        title.setAlignment(Qt.AlignCenter)
        font = QFont()
        font.setPointSize(14)
        font.setBold(True)
        title.setFont(font)
        layout.addWidget(title)
        
        # Capture Settings Group
        capture_group = QGroupBox("Capture Settings")
        capture_layout = QVBoxLayout(capture_group)
        
        # Save mode row
        mode_layout = QHBoxLayout()
        mode_layout.addWidget(QLabel("Save mode:"))
        self.save_mode_combo = QComboBox()
        self.save_mode_combo.addItems(["Per marker", "Per clip", "Export existing stills"])
        mode_layout.addWidget(self.save_mode_combo)
        capture_layout.addLayout(mode_layout)
        
        # Markers row
        markers_layout = QHBoxLayout()
        markers_layout.addWidget(QLabel("Timeline markers:"))
        self.markers_combo = QComboBox()
        self.markers_combo.addItems(MARKER_COLORS)
        markers_layout.addWidget(self.markers_combo)
        capture_layout.addLayout(markers_layout)
        
        # Info label
        self.info_label = QLabel()
        self.info_label.setStyleSheet("""
            QLabel {
                background-color: #f0f0f0;
                border: 1px solid #ccc;
                border-radius: 3px;
                padding: 6px;
                font-style: italic;
                color: #666;
            }
        """)
        capture_layout.addWidget(self.info_label)
        
        layout.addWidget(capture_group)
        
        # Export Settings Group
        export_group = QGroupBox("Export Settings")
        export_layout = QVBoxLayout(export_group)
        
        # Export checkbox
        self.export_check = QCheckBox("Export grabbed stills")
        self.export_check.setChecked(True)
        export_layout.addWidget(self.export_check)
        
        # Export path row
        path_layout = QHBoxLayout()
        path_layout.addWidget(QLabel("Export to:"))
        self.export_path_edit = QLineEdit()
        self.browse_btn = QPushButton("Browse...")
        self.browse_btn.setMaximumWidth(80)
        path_layout.addWidget(self.export_path_edit)
        path_layout.addWidget(self.browse_btn)
        export_layout.addLayout(path_layout)
        
        # Format and Album row
        format_layout = QHBoxLayout()
        format_layout.addWidget(QLabel("Format:"))
        self.format_combo = QComboBox()
        self.format_combo.addItems([STILL_FORMATS[k] for k in STILL_FORMATS_ORDER])
        format_layout.addWidget(self.format_combo)
        
        format_layout.addWidget(QLabel("Album:"))
        self.album_edit = QLineEdit(DEFAULT_STILL_ALBUM)
        format_layout.addWidget(self.album_edit)
        export_layout.addLayout(format_layout)
        
        layout.addWidget(export_group)
        
        # Post-processing Group
        post_group = QGroupBox("Post-Processing Options")
        post_layout = QVBoxLayout(post_group)
        
        self.delete_stills_check = QCheckBox("Delete grabbed stills from album after export")
        self.delete_stills_check.setChecked(True)
        post_layout.addWidget(self.delete_stills_check)
        
        self.cleanup_drx_check = QCheckBox("Cleanup .drx files in export folder")
        self.cleanup_drx_check.setChecked(True)
        post_layout.addWidget(self.cleanup_drx_check)
        
        self.open_edit_check = QCheckBox("Open Edit page after export")
        self.open_edit_check.setChecked(True)
        post_layout.addWidget(self.open_edit_check)
        
        layout.addWidget(post_group)
        
        # Progress label
        self.progress_label = QLabel()
        self.progress_label.setStyleSheet("color: #0078d4; font-weight: bold;")
        layout.addWidget(self.progress_label)
        
        # Spacer
        layout.addItem(QSpacerItem(20, 40, QSizePolicy.Minimum, QSizePolicy.Expanding))
        
        # Buttons
        buttons_layout = QHBoxLayout()
        buttons_layout.addItem(QSpacerItem(40, 20, QSizePolicy.Expanding, QSizePolicy.Minimum))
        
        self.cancel_btn = QPushButton("Cancel")
        self.start_btn = QPushButton("Start")
        self.start_btn.setDefault(True)
        
        # Style buttons
        button_style = """
            QPushButton {
                min-height: 28px;
                min-width: 80px;
                padding: 6px 16px;
                font-weight: bold;
                border-radius: 4px;
            }
        """
        self.cancel_btn.setStyleSheet(button_style + """
            QPushButton {
                background-color: #f3f2f1;
                border: 1px solid #8a8886;
                color: #323130;
            }
            QPushButton:hover {
                background-color: #edebe9;
            }
        """)
        self.start_btn.setStyleSheet(button_style + """
            QPushButton {
                background-color: #0078d4;
                border: 1px solid #005a9e;
                color: white;
            }
            QPushButton:hover {
                background-color: #106ebe;
            }
        """)
        
        buttons_layout.addWidget(self.cancel_btn)
        buttons_layout.addWidget(self.start_btn)
        layout.addLayout(buttons_layout)
    
    def connect_signals(self):
        """Connect UI signals to slots."""
        self.save_mode_combo.currentTextChanged.connect(self.update_info)
        self.markers_combo.currentTextChanged.connect(self.update_info)
        self.export_check.toggled.connect(self.toggle_export)
        self.browse_btn.clicked.connect(self.browse_folder)
        self.cancel_btn.clicked.connect(self.close)
        self.start_btn.clicked.connect(self.start_processing)
        
        # Initial update
        self.update_info()
        self.toggle_export(self.export_check.isChecked())
    
    def update_info(self):
        """Update the info label based on current settings."""
        mode = self.save_mode_combo.currentText()
        color = self.markers_combo.currentText()
        
        # Enable/disable marker combo based on mode
        is_export_existing = mode.startswith("Export existing")
        self.markers_combo.setEnabled(not is_export_existing)
        
        if mode.startswith("Per marker"):
            text = f"Saving per marker; filter: {color}"
        elif mode.startswith("Per clip"):
            text = "Saving per clip"
        elif mode.startswith("Export existing"):
            text = "Exporting existing stills from album (no grabbing)"
        else:
            text = "Saving per marker"
        
        self.info_label.setText(text)
    
    def toggle_export(self, enabled):
        """Enable/disable export options."""
        self.export_path_edit.setEnabled(enabled)
        self.browse_btn.setEnabled(enabled)
        self.format_combo.setEnabled(enabled)
        
        # Update start button state
        can_start = True
        if enabled:
            can_start = bool(self.export_path_edit.text().strip())
        self.start_btn.setEnabled(can_start)
    
    def browse_folder(self):
        """Browse for export folder."""
        folder = QFileDialog.getExistingDirectory(
            self, 
            "Select Export Folder",
            self.export_path_edit.text()
        )
        if folder:
            self.export_path_edit.setText(folder)
            self.save_setting("export_path", folder)
            self.toggle_export(self.export_check.isChecked())
    
    def start_processing(self):
        """Start the stills processing."""
        if not self.utils.resolve:
            QMessageBox.critical(self, "Error", "DaVinci Resolve not available!")
            return
        
        options = self.collect_options()
        
        # Validate options
        if options["export"] and not options["export_to"]:
            QMessageBox.warning(self, "Warning", "Please specify an export folder!")
            return
        
        # Disable UI during processing
        self.start_btn.setEnabled(False)
        self.progress_label.setText("Starting...")
        
        # Start worker thread
        self.worker_thread = QThread()
        self.worker = StillsWorker(options, self.utils)
        self.worker.moveToThread(self.worker_thread)
        
        # Connect signals
        self.worker_thread.started.connect(self.worker.run)
        self.worker.progress.connect(self.update_progress)
        self.worker.finished.connect(self.processing_finished)
        
        self.worker_thread.start()
    
    def update_progress(self, message):
        """Update progress display."""
        self.progress_label.setText(message)
        QApplication.processEvents()
    
    def processing_finished(self, success, message):
        """Handle processing completion."""
        self.worker_thread.quit()
        self.worker_thread.wait()
        
        self.progress_label.setText("")
        self.start_btn.setEnabled(True)
        
        if success:
            QMessageBox.information(self, "Success", message)
            self.close()
        else:
            QMessageBox.warning(self, "Warning", message)
    
    def collect_options(self):
        """Collect all options from the UI."""
        mode_index = self.save_mode_combo.currentIndex()
        if mode_index == 0:
            save_mode = "per_marker"
        elif mode_index == 1:
            save_mode = "per_clip"
        else:
            save_mode = "export_existing"
        
        format_index = self.format_combo.currentIndex()
        export_format = STILL_FORMATS_ORDER[format_index]
        
        return {
            "save_mode": save_mode,
            "marker_color": self.markers_combo.currentText(),
            "export": self.export_check.isChecked(),
            "export_to": self.export_path_edit.text().strip(),
            "format": export_format,
            "album": self.album_edit.text().strip() or DEFAULT_STILL_ALBUM,
            "delete_stills": self.delete_stills_check.isChecked(),
            "cleanup_drx": self.cleanup_drx_check.isChecked(),
            "open_edit": self.open_edit_check.isChecked(),
        }
    
    def load_settings(self):
        """Load settings from Resolve storage."""
        settings = {}
        if fusion:
            settings["export_path"] = fusion.GetData("BatchResolveSaveStills.Folder") or ""
        return settings
    
    def save_setting(self, key, value):
        """Save a setting to Resolve storage."""
        if fusion:
            if key == "export_path":
                fusion.SetData("BatchResolveSaveStills.Folder", value)
    
    def load_values(self):
        """Load saved values into the UI."""
        export_path = self.settings.get("export_path", "")
        self.export_path_edit.setText(export_path)


def main():
    """Main entry point."""
    app = QApplication.instance()
    if app is None:
        app = QApplication(sys.argv)
    
    # Check if Resolve is available
    if not resolve:
        QMessageBox.critical(None, "Error", 
                           "DaVinci Resolve not available!\n"
                           "Please run this script from within DaVinci Resolve.")
        return
    
    dialog = GrabStillsDialog()
    dialog.show()
    
    # If we're running standalone, start the event loop
    if __name__ == "__main__":
        sys.exit(app.exec())


if __name__ == "__main__":
    main()

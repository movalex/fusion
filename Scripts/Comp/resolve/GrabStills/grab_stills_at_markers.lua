--[[

MIT License

Copyright (c) 2023 Roger Magnusson

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-----------------------------------------------------------------------------


	A script that allows you to grab stills from timeline markers and optionally export them to a folder.

	This script also highlights an issue with scripting in Resolve. There's no way to lock the user
	interface while the script is running and if the user opens a modal window, like Project Settings,
	most of the scriptable operations will fail. What's even worse, if the automatic backup kicks in when
	a script is running, the script will also fail.

	Many functions in the Resolve API can return a status so you can check if it succeeded or not, but I
	think what we really need is a way to lock the GUI and for backups to be postponed while running. Just
	like what happens when you're rendering a file.

	roger.magnusson@gmail.com


]]

local script, luaresolve, libavutil

script = 
{
	filename = debug.getinfo(1,"S").source:match("^.*%@(.*)"),
	version = "1.0",
	name = "Grab Stills at Markers",
	window_id = "GrabStills",

	settings =
	{
		markers = "Any",
		export = false,
		export_to = "",
		format = "jpg",
	},

	load_settings = function(self)
		local settings_filename = self.filename:gsub(".lua", ".settings")

		if (bmd.fileexists(settings_filename)) then
			self.settings = bmd.readfile(settings_filename)
		end
	end,

	save_settings = function(self)
		bmd.writefile(self.filename:gsub(".lua", ".settings"), self.settings)
	end,

	set_declarations = function()
		libavutil.set_declarations()
	end,

	ui = app.UIManager,
	dispatcher = bmd.UIDispatcher(app.UIManager)
}

luaresolve = 
{
	frame_rates =
	{
		get_fraction = function(self, frame_rate_string_or_number)
			local frame_rate = tonumber(tostring(frame_rate_string_or_number))
			-- These are the frame rates that DaVinci Resolve Studio supports as of version 18
			local frame_rates = { 16, 18, 23.976, 24, 25, 29.97, 30, 47.952, 48, 50, 59.94, 60, 72, 95.904, 96, 100, 119.88, 120 }

			for _, current_frame_rate in ipairs (frame_rates) do
				if current_frame_rate == frame_rate or math.floor(current_frame_rate) == frame_rate then
					local is_decimal = current_frame_rate % 1 > 0
					local denominator = iif(is_decimal, 1001, 100)
					local numerator = math.ceil(current_frame_rate) * iif(is_decimal, 1000, denominator)
					return { num = numerator, den = denominator }
				end
			end

			return nil, string.format("Invalid frame rate: %s", frame_rate_string_or_number)
		end,

		get_decimal = function(self, frame_rate_string_or_number)
			local fractional_frame_rate, error_message = self:get_fraction(frame_rate_string_or_number)
			
			if fractional_frame_rate ~= nil then
				return tonumber(string.format("%.3f", fractional_frame_rate.num / fractional_frame_rate.den))
			else
				return nil, error_message
			end
		end,
	},

	load_library = function(name_pattern)
		local files = bmd.readdir(fu:MapPath("FusionLibs:"..iif(ffi.os == "Windows", "", "../"))..name_pattern)
		assert(#files == 1 and files[1].IsDir == false, string.format("Couldn't find exact match for pattern \"%s.\"", name_pattern))
		return ffi.load(files.Parent..files[1].Name)
	end,

	frame_from_timecode = function(self, timecode, frame_rate)
		return libavutil:av_timecode_init_from_string(timecode, self.frame_rates:get_fraction(frame_rate)).start
	end,

	timecode_from_frame = function(self, frame, frame_rate, drop_frame)
		return libavutil:av_timecode_make_string(0, frame, self.frame_rates:get_decimal(frame_rate),
		{
			AV_TIMECODE_FLAG_DROPFRAME = drop_frame == true or drop_frame == 1 or drop_frame == "1",
			AV_TIMECODE_FLAG_24HOURSMAX = true,
			AV_TIMECODE_FLAG_ALLOWNEGATIVE = false
		})
	end,

	change_page = function(page)
		local current_page, state

		current_page = resolve:GetCurrentPage()
		
		local function get_state()
			local current_state =
			{
				page = current_page,
				project = resolve:GetProjectManager():GetCurrentProject()
			}

			if current_state.project then
				current_state.timeline = current_state.project:GetCurrentTimeline()

				if current_state.timeline then
					current_state.timecode = current_state.timeline:GetCurrentTimecode()
				end
			end

			return current_state
		end

		if current_page == "media" or current_page == "fusion" then
			-- We can't get current timecode from the Media or Fusion pages, so try switching to the requested page first
			assert(resolve:OpenPage(page), "Couldn't open page: "..page)
			state = get_state()
		else
			-- Otherwise get the state first, in case we're switching to Media or Fusion
			state = get_state()
			assert(resolve:OpenPage(page), "Couldn't open page: "..page)
		end

		return state
	end,

	restore_page = function(state)
		local function set_state(initial_state)
			local current_project, current_timeline
			current_project = resolve:GetProjectManager():GetCurrentProject()

			if current_project then
				current_timeline = current_project:GetCurrentTimeline()

				if current_timeline ~= nil and current_timeline == initial_state.timeline and initial_state.timecode ~= nil then
					initial_state.timeline:SetCurrentTimecode(initial_state.timecode)
				end
			end
		end

		local current_page = resolve:GetCurrentPage()

		if current_page == "media" or current_page == "fusion" then
			-- We can't get set current timecode on the Media or Fusion pages, so try switching to the original page first
			resolve:OpenPage(state.page)
			set_state(state)
		else
			-- Otherwise set the state first, in case we're going back to Media or Fusion
			set_state(state)
			resolve:OpenPage(state.page)
		end
	end,

	stills = 
	{
		formats = 
		{
			dpx = "DPX Files (*.dpx)",
			cin = "Cineon Files (*.cin)",
			tif = "TIFF Files (*.tif)",
			jpg = "JPEG Files (*.jpg)",
			png = "PNG Files (*.png)",
			ppm = "PPM Files (*.ppm)",
			bmp = "BMP Files (*.bmp)",
			xpm = "XPM Files (*.xpm)",

			sort_order = table.pack("dpx", "cin", "tif", "jpg", "png", "ppm", "bmp", "xpm")
		},

		-- Workaround for an error that occurs during ExportStills() if the "Timelines" album is selected by the user (verified in v18.1)
		reselect_album = function(album, gallery)
			for _, gallery_album in ipairs(gallery:GetGalleryStillAlbums()) do
				if gallery_album ~= album then
					gallery:SetCurrentStillAlbum(gallery_album)
					break
				end
			end

			gallery:SetCurrentStillAlbum(album)
			return album
		end,
	},

	markers =
	{
		get_marker_count_by_color = function(markers)
			local marker_count_by_color = { Any = 0 }

			for marker_frame, marker in pairs(markers) do
				if marker_count_by_color[marker.color] == nil then
					marker_count_by_color[marker.color] = 0
				end

				marker_count_by_color[marker.color] = marker_count_by_color[marker.color] + 1
				marker_count_by_color.Any = marker_count_by_color.Any + 1
			end

			return marker_count_by_color
		end,

		colors = 
		{
			"Blue",
			"Cyan",
			"Green",
			"Yellow",
			"Red",
			"Pink",
			"Purple",
			"Fuchsia",
			"Rose",
			"Lavender",
			"Sky",
			"Mint",
			"Lemon",
			"Sand",
			"Cocoa",
			"Cream"
		}
	},
}

libavutil = 
{
	library = luaresolve.load_library(iif(ffi.os == "Windows", "avutil*.dll", iif(ffi.os == "OSX", "libavutil*.dylib", "libavutil.so"))),

	demand_version = function(self, version)
		local library_version = self:av_version_info()

		return (library_version.major > version.major)
			or (library_version.major == version.major and library_version.minor > version.minor)
			or (library_version.major == version.major and library_version.minor == version.minor and library_version.patch > version.patch)
			or (library_version.major == version.major and library_version.minor == version.minor and library_version.patch == version.patch)
	end,

	set_declarations = function()
		ffi.cdef[[
			enum AVTimecodeFlag {
				AV_TIMECODE_FLAG_DROPFRAME      = 1<<0, // timecode is drop frame
				AV_TIMECODE_FLAG_24HOURSMAX     = 1<<1, // timecode wraps after 24 hours
				AV_TIMECODE_FLAG_ALLOWNEGATIVE  = 1<<2, // negative time values are allowed
			};

			struct AVRational { int32_t num; int32_t den; };
			struct AVTimecode { int32_t start; enum AVTimecodeFlag flags; struct AVRational rate; uint32_t fps; };

			char* av_timecode_make_string(const struct AVTimecode* tc, const char* buf, int32_t framenum);
			int32_t av_timecode_init_from_string(struct AVTimecode* tc, struct AVRational rate, const char* str, void* log_ctx);

			char* av_version_info (void);
		]]
	end,

	av_timecode_make_string = function(self, start, frame, fps, flags)
		local function bor_number_flags(enum_name, flags)
			local enum_value = 0    
	
			if (flags) then
				for key, value in pairs(flags) do
					if (value == true) then
						enum_value = bit.bor(enum_value, tonumber(ffi.new(enum_name, key)))
					end
				end
			end

			return enum_value;
		end

		local tc = ffi.new("struct AVTimecode",
		{
			start = start,
			flags = bor_number_flags("enum AVTimecodeFlag", flags),
			fps = math.ceil(luaresolve.frame_rates:get_decimal(fps))
		})

		if (flags.AV_TIMECODE_FLAG_DROPFRAME and fps > 60 and (fps % (30000 / 1001) == 0 or fps % 29.97 == 0))
			and (not self:demand_version( { major = 4, minor = 4, patch = 0 } ))
		then
			-- Adjust for drop frame above 60 fps (not necessary if BMD upgrades to libavutil-57 or later)
			frame = frame + 9 * tc.fps / 15 * (math.floor(frame / (tc.fps * 599.4))) + (math.floor((frame % (tc.fps * 599.4)) / (tc.fps * 59.94))) * tc.fps / 15
		end

		local timecodestring = ffi.string(self.library.av_timecode_make_string(tc, ffi.string(string.rep(" ", 16)), frame))
	
		if (#timecodestring > 0) then
			local frame_digits = #tostring(math.ceil(fps) - 1)

			-- Fix for libavutil where it doesn't use leading zeros for timecode at frame rates above 100
			if frame_digits > 2 then
				timecodestring = string.format("%s%0"..frame_digits.."d", timecodestring:sub(1, timecodestring:find("[:;]%d+$")), tonumber(timecodestring:match("%d+$")))
			end

			return timecodestring
		else
			return nil
		end
	end,

	av_timecode_init_from_string = function(self, timecode, frame_rate_fraction)
		local tc = ffi.new("struct AVTimecode")
		local result = self.library.av_timecode_init_from_string(tc, ffi.new("struct AVRational", frame_rate_fraction), timecode, ffi.new("void*", nil))
	
		if (result == 0) then
			return
			{
				start = tc.start,
				flags =
				{
					AV_TIMECODE_FLAG_DROPFRAME = bit.band(tc.flags, ffi.C.AV_TIMECODE_FLAG_DROPFRAME) == ffi.C.AV_TIMECODE_FLAG_DROPFRAME,
					AV_TIMECODE_FLAG_24HOURSMAX = bit.band(tc.flags, ffi.C.AV_TIMECODE_FLAG_24HOURSMAX) == ffi.C.AV_TIMECODE_FLAG_24HOURSMAX,
					AV_TIMECODE_FLAG_ALLOWNEGATIVE = bit.band(tc.flags, ffi.C.AV_TIMECODE_FLAG_ALLOWNEGATIVE) == ffi.C.AV_TIMECODE_FLAG_ALLOWNEGATIVE,
				},
				rate =
				{
					num = tc.rate.num,
					den = tc.rate.den
				},
				fps = tc.fps
			}
		else
			error("avutil error code: "..result)
		end
	end,

	av_version_info = function(self)
		local version = ffi.string(self.library.av_version_info())

		return 
		{
			major = tonumber(version:match("^%d+")),
			minor = tonumber(version:match("%.%d+"):sub(2)),
			patch = tonumber(version:match("%d+$"))
		}
	end,
}

script.set_declarations()
script:load_settings()

local function create_window(marker_count_by_color, still_album_name)
	local ui = script.ui
	local dispatcher = script.dispatcher

	local left_column_minimum_size = { 100, 0 }
	local left_column_maximum_size = { 100, 16777215 }

	local window_flags = nil

	if ffi.os == "Windows" then
		window_flags = 	
		{
			Window = true,
			CustomizeWindowHint = true,
			WindowCloseButtonHint = true,
		}
	elseif ffi.os == "Linux" then
		window_flags = 
		{
			Window = true,
		}
	elseif ffi.os == "OSX" then
		window_flags = 
		{
			Dialog = true,
		}
	end

	local window = dispatcher:AddDialog(
	{
		ID = script.window_id,
		WindowTitle = script.name,
		WindowFlags = window_flags,

		WindowModality = "ApplicationModal",

		Events = 
		{
			Close = true,
			KeyPress = true,
		},

		FixedSize = { 600, 250 },

		ui:VGroup
		{
			MinimumSize = { 450, 230 },
			MaximumSize = { 16777215, 230 },

			Weight = 1,

			ui:HGroup
			{
				Weight = 0,
				Spacing = 10,

				ui:Label
				{
					Weight = 0,
					Alignment = { AlignRight = true, AlignVCenter = true },
					MinimumSize = left_column_minimum_size,
					MaximumSize = left_column_maximum_size,
					Text = "Timeline markers"
				},

				ui:ComboBox
				{
					Weight = 1,
					ID = "MarkersComboBox",
				},
			},
			
			ui:HGroup
			{
				Weight = 0,
				Spacing = 10,

				ui:Label
				{
					Weight = 0,
					MinimumSize = left_column_minimum_size,
					MaximumSize = left_column_maximum_size,
				},

				ui:Label
				{
					Weight = 1,
					ID = "InfoLabel",
				},
			},

			ui:VGap(10),

			ui:HGroup
			{
				Weight = 0,
				Spacing = 10,

				ui:Label
				{
					Weight = 0,
					MinimumSize = left_column_minimum_size,
					MaximumSize = left_column_maximum_size,
				},

				ui:CheckBox
				{
					Weight = 1,
					ID = "ExportCheckBox",
					Text = "Export grabbed stills",
					Checked = script.settings.export,
					Events = { Toggled = true },
				},
			},

			ui:VGroup
			{
				ID = "ExportSettings",
				Weight = 0,
				Enabled = script.settings.export,

				ui:HGroup
				{
					Weight = 0,
					Spacing = 10,
					
					ui:Label
					{
						Weight = 0,
						Alignment = { AlignRight = true, AlignVCenter = true },
						MinimumSize = left_column_minimum_size,
						MaximumSize = left_column_maximum_size,
						Text = "Export to",
					},

					ui:LineEdit
					{
						Weight = 1,
						ID = "ExportToLineEdit",
						Text = script.settings.export_to,
					},
					
					ui:Button
					{
						Weight = 0,
						ID = "BrowseButton",
						Text = "Browse",
						AutoDefault = false,
					},
				},

				ui:HGroup
				{
					Weight = 0,
					Spacing = 10,

					ui:Label
					{
						Weight = 0,
						Alignment = { AlignRight = true, AlignVCenter = true },
						MinimumSize = left_column_minimum_size,
						MaximumSize = left_column_maximum_size,
						Text = "Format",
					},

					ui:ComboBox
					{
						Weight = 1,
						ID = "FormatComboBox",
					},
				},
			},

			ui:VGap(0, 1),

			ui:HGroup
			{
				Weight = 0,
				Spacing = 10,
				StyleSheet = [[
					QPushButton
					{
						min-height: 22px;
						max-height: 22px;
						min-width: 108px;
						max-width: 108px;
					}
				]],

				ui:HGap(0, 1),

				ui:Button
				{
					Weight = 0,
					ID = "CancelButton",
					Text = "Cancel",
					AutoDefault = false,
				},

				ui:Button
				{
					Weight = 0,
					ID = "StartButton",
					Text = "Start",
					AutoDefault = false,
					Default = true,
				},
			},
		},
	})

	window_items = window:GetItems()

	local function update_controls()
		local start_button_enabled = not window_items.ExportCheckBox.Checked or (window_items.ExportCheckBox.Checked and #window_items.ExportToLineEdit.Text > 0)
		window_items.ExportSettings.Enabled = window_items.ExportCheckBox.Checked

		local marker_count = marker_count_by_color[window_items.MarkersComboBox.CurrentText]

		if marker_count ~= nil and marker_count > 0 then
			window_items.InfoLabel.Text = string.format("%s still%s will be grabbed to the \"%s\" album", marker_count, iif(marker_count == 1, "", "s"), still_album_name)
		else
			local marker_color = iif(window_items.MarkersComboBox.CurrentText == "Any", "", window_items.MarkersComboBox.CurrentText:lower().." ")
			window_items.InfoLabel.Text = string.format("No %smarkers found, no stills will be grabbed", marker_color)
			start_button_enabled = false
		end

		window_items.StartButton.Enabled = start_button_enabled
		window_items.ExportToLineEdit.ToolTip = window_items.ExportToLineEdit.Text
	end

	local function initialize_controls()
		local right_column_button_width = 70 -- excluding border

		window.StyleSheet = [[
			QComboBox
			{
				margin-right: ]]..(right_column_button_width + 2 + 10)..[[px;
				padding-right: 6px;
				padding-left: 6px;
				min-height: 18px;
				max-height: 18px;
			}

			QLineEdit
			{
				padding-top: 0px;
				margin-top: 1px;
				min-height: 18px;
				max-height: 18px;
			}

			QPushButton
			{
				min-height: 20px;
				max-height: 20px;
				min-width: ]]..right_column_button_width..[[px;
				max-width: ]]..right_column_button_width..[[px;
			}
		]]

		window_items.MarkersComboBox:AddItem("Any")
		window_items.MarkersComboBox:AddItems(luaresolve.markers.colors)
		window_items.MarkersComboBox:InsertSeparator(1)
		window_items.MarkersComboBox.CurrentText = script.settings.markers

		for _, format in ipairs(luaresolve.stills.formats.sort_order) do
			window_items.FormatComboBox:AddItem(luaresolve.stills.formats[format])
		end

		window_items.FormatComboBox.CurrentText = luaresolve.stills.formats[script.settings.format]
		
		update_controls()
	end

	initialize_controls()

	window.On.MarkersComboBox.CurrentIndexChanged = function(ev)
		update_controls()
	end

	window.On.ExportCheckBox.Toggled = function(ev)
		update_controls()
	end

	window.On.BrowseButton.Clicked = function(ev)
		local selected_dir = fusion:RequestDir(window_items.ExportToLineEdit.Text, { FReqS_Title = "Export to", })

		if selected_dir then
			window_items.ExportToLineEdit.Text = selected_dir
		end
	end

	window.On.ExportToLineEdit.TextChanged = function(ev)
		update_controls()
	end

	window.On.CancelButton.Clicked = function(ev)
		dispatcher:ExitLoop(false)
	end

	window.On.StartButton.Clicked = function(ev)
		script.settings.markers = window_items.MarkersComboBox.CurrentText
		script.settings.export = window_items.ExportCheckBox.Checked
		script.settings.export_to = window_items.ExportToLineEdit.Text
		script.settings.format = luaresolve.stills.formats.sort_order[window_items.FormatComboBox.CurrentIndex + 1]
		script:save_settings()

		dispatcher:ExitLoop(true)
	end
	
	window.On[script.window_id].KeyPress = function(ev)
		if (ev.Key == 16777216) then -- Escape
			window_items.CancelButton:Click()
		end
	end

	window.On[script.window_id].Close = function(ev)
		window_items.CancelButton:Click()
	end

	return window
end

local function main()
	local project = assert(resolve:GetProjectManager():GetCurrentProject(), "Couldn't get current project")
	local gallery = assert(project:GetGallery(), "Couldn't get the Resolve stills gallery")
	local still_album = assert(gallery:GetCurrentStillAlbum(), "Couldn't get the current gallery still album") 
	local still_album_name = gallery:GetAlbumName(still_album)
	local timeline = assert(project:GetCurrentTimeline(), "Couldn't get current timeline")
	local timeline_start = timeline:GetStartFrame()
	local frame_rate = timeline:GetSetting("timelineFrameRate")
	local drop_frame = timeline:GetSetting("timelineDropFrameTimecode")
	local markers = timeline:GetMarkers()

	if next(markers) ~= nil then
		local marker_count_by_color = luaresolve.markers.get_marker_count_by_color(markers)
		local window = create_window(marker_count_by_color, still_album_name)

		window:Show()
		local grab_stills = script.dispatcher:RunLoop()
		window:Hide()

		if grab_stills then
			local initial_state = luaresolve.change_page("color")
			local stills_to_export = {}

			-- Note: The script will stop if an automated backup starts, or if the user does something in Resolve like opening Preferences or Project Settings.
			--       Resolve currently has no way of locking the user interface while running a script and we can't move the playhead if we have a modal window showing.

			-- Create a new table that will contain ordered marker frames
			local marker_frames = {}
			
			-- Add the marker frames to the table
			for marker_frame, _ in pairs(markers) do
				marker_frames[#marker_frames+1] = marker_frame
			end
			
			-- Sort the table
			table.sort(marker_frames)

			-- Now we can process the markers in order
			for _, marker_frame in ipairs(marker_frames) do
				local marker = markers[marker_frame]

				if script.settings.markers == "Any" or script.settings.markers == marker.color then
					local frame = timeline_start + marker_frame
					local timecode = luaresolve:timecode_from_frame(frame, frame_rate, drop_frame)
					
					assert(timeline:SetCurrentTimecode(timecode), "Couldn't navigate to marker at "..timecode)
					stills_to_export[#stills_to_export+1] = assert(timeline:GrabStill(), "Couldn't grab still at "..timecode)
				end
			end
			
			if script.settings.export then
				local prefix = "" -- An empty prefix lets it export using the labels configured in Resolve
				
				luaresolve.stills.reselect_album(still_album, gallery)
				assert(still_album:ExportStills(stills_to_export, script.settings.export_to, prefix, script.settings.format), "An error occurred while exporting stills")
			end

			luaresolve.restore_page(initial_state)
		end
	end
end

main()

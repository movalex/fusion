import sys
import os

if sys.version_info[0] >= 3 and sys.version_info[1] >= 5:
	import importlib.machinery
	import importlib.util

	def load_dynamic(module_name, file_path):
		module = None
		spec = None
		loader = importlib.machinery.ExtensionFileLoader(module_name, file_path)
		if loader:
			spec = importlib.util.spec_from_loader(module_name, loader)
		if spec:
			module = importlib.util.module_from_spec(spec)
		if module:
			loader.exec_module(module)
		return module

else:
	import imp

	def load_dynamic(module, path):
		return imp.load_dynamic(module, path)


fu_mod = None

try:
	import fusionscript as fu_mod

except ImportError:
	ext = ""

	if sys.platform.startswith("darwin"):
		ext = ".so"
		paths = [
			"./",
			"/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/",
			"/Applications/Blackmagic Fusion 18/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 18 Render Node/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 17/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 17 Render Node/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 16/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 16 Render Node/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 9/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 9 Render Node/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 8/Fusion.app/Contents/MacOS/",
			"/Applications/Blackmagic Fusion 8 Render Node/Fusion.app/Contents/MacOS/",
		]
	elif sys.platform.startswith("win") or sys.platform.startswith("cygwin"):
		ext = ".dll"
		paths = [
			".\\",
			"C:\\Program Files\\Blackmagic Design\\DaVinci Resolve\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion 18\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion Render Node 18\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion 17\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion Render Node 17\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion 16\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion Render Node 16\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion 9\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion Render Node 9\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion 8\\",
			"C:\\Program Files\\Blackmagic Design\\Fusion Render Node 8\\",
		]
	elif sys.platform.startswith("linux"):
		ext = ".so"
		paths = [
			"./",
			"/opt/resolve/libs/Fusion/",
			"/opt/BlackmagicDesign/Fusion18/",
			"/opt/BlackmagicDesign/FusionRenderNode18/",
			"/opt/BlackmagicDesign/Fusion17/",
			"/opt/BlackmagicDesign/FusionRenderNode17/",
			"/opt/BlackmagicDesign/Fusion16/",
			"/opt/BlackmagicDesign/FusionRenderNode16/",
			"/opt/BlackmagicDesign/Fusion9/",
			"/opt/BlackmagicDesign/FusionRenderNode9/",
			"/opt/BlackmagicDesign/Fusion8/",
			"/opt/BlackmagicDesign/FusionRenderNode8/",
		]

	modpath = os.getenv("FUSION_MODULE_PATH")
	if modpath:
		paths.insert(0, modpath)

	for path in paths:
		try:
			fu_mod = load_dynamic("fusionscript", path + "fusionscript" + ext)
			if fu_mod:
				break
		except ImportError:
			continue

if fu_mod:
	sys.modules[__name__] = fu_mod
else:
	raise ImportError("could not locate module dependencies")

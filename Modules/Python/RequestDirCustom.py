import BlackmagicFusion as bmd

class RequestDirCustom:
    def __init__(self, fusion):
        self.fusion = fusion
        self.ui = fusion.UIManager
        self.disp = bmd.UIDispatcher(self.ui)
        
    def create_dialog(self):
        # Create the main window
        self.win = self.disp.AddWindow({
            'WindowTitle': 'Custom Directory Request',
            'ID': 'RequestDirCustomWin',
            'Geometry': [100, 100, 400, 200],
        }, [
            self.ui.VGroup([
                self.ui.Label({'Text': 'Select directories for your automation script:'}),
                
                # Original directory input
                self.ui.HGroup([
                    self.ui.Label({'Text': 'Input Directory:', 'Weight': 0.3}),
                    self.ui.LineEdit({'ID': 'CompDir', 'PlaceholderText': 'Select input directory...'}),
                    self.ui.Button({'ID': 'BrowseComp', 'Text': 'Browse', 'Weight': 0.2}),
                ]),
                
                # New saver output location input
                self.ui.HGroup([
                    self.ui.Label({'Text': 'Output Directory:', 'Weight': 0.3}),
                    self.ui.LineEdit({'ID': 'OutputDir', 'PlaceholderText': 'Select output directory...'}),
                    self.ui.Button({'ID': 'BrowseOutput', 'Text': 'Browse', 'Weight': 0.2}),
                ]),
                
                # Buttons
                self.ui.HGroup([
                    self.ui.Button({'ID': 'OK', 'Text': 'OK'}),
                    self.ui.Button({'ID': 'Cancel', 'Text': 'Cancel'}),
                ]),
            ])
        ])
        
        # Set up event handlers
        self.win.On.OK.Clicked = self.on_ok
        self.win.On.Cancel.Clicked = self.on_cancel
        self.win.On.BrowseComp.Clicked = self.on_browse_input
        self.win.On.BrowseOutput.Clicked = self.on_browse_output
        
    def on_browse_input(self, ev):
        path = self.fusion.RequestDir()
        if path:
            self.win.Find('CompDir').Text = path
            
    def on_browse_output(self, ev):
        path = self.fusion.RequestDir()
        if path:
            self.win.Find('OutputDir').Text = path
    
    def on_ok(self, ev):
        self.input_dir = self.win.Find('CompDir').Text
        self.output_dir = self.win.Find('OutputDir').Text
        self.result = True
        self.disp.ExitLoop()
        
    def on_cancel(self, ev):
        self.result = False
        self.disp.ExitLoop()
        
    def show(self):
        self.create_dialog()
        self.win.Show()
        self.disp.RunLoop()
        self.win.Hide()
        
        if hasattr(self, 'result') and self.result:
            return {
                'input_dir': getattr(self, 'input_dir', ''),
                'output_dir': getattr(self, 'output_dir', '')
            }
        return None

# Usage example
def request_custom_dirs():
    fusion = bmd.scriptapp("Fusion")
    dialog = RequestDirCustom(fusion)
    result = dialog.show()
    
    if result:
        print(f"Input Directory: {result['input_dir']}")
        print(f"Output Directory: {result['output_dir']}")
        return result
    else:
        print("Dialog cancelled")
        return None

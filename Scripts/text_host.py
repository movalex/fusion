import socket
try:
    tool = comp.ActiveTool()
    host = socket.gethostname()
    text_host = comp.AddTool('TextPlus', -32768, -32768)
    text_host.SetAttrs({'TOOLS_Name': 'computer_host'})
    text_host.StyledText = host
    text_host.Size = .03
    text_host.Center = {1: .1, 2: .1, 3: 0}
except TypeError:
    print('Select tool')

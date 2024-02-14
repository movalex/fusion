function UpdateProbe()
    settings = comp:GetData("ColorAnalyzer.settings")
    tools = tool:GetChildrenList(false)
    s = comp:GetData("ColorAnalyzer")
    for i, t in ipairs(tools) do
        print(t.Name)
        t:LoadSettings(s[t.Name])
    end
    tool:LoadSettings(settings)

end

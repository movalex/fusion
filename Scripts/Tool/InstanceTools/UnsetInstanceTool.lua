tool:SetData("Instanced")
resetName = tool.Name:gsub("_Instanced", "")
tool:SetAttrs({TOOLB_Nameset = true, TOOLS_Name = resetName})
tool.TileColor = nil

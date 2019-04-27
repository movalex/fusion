local width = tool:GetAttrs('TOOLI_ImageWidth')
local height = tool:GetAttrs('TOOLI_ImageHeight')

comp:SetPrefs({['Comp.FrameFormat.Width'] = width,  ['Comp.FrameFormat.Height'] = height})

print('Comp size is adjusted to '.. width ..'x'.. height)

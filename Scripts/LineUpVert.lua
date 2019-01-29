fl = comp.CurrentFrame.FlowView

comp:StartUndo("Stack Tools Vertically")
comp:Lock()
_SEL = comp:GetToolList(true)
_A = comp.ActiveTool
if (_A == nil) then
	_A = _SEL[1]
end
_AX,_AY = fl:GetPos(_A)

for k,v in pairs(_SEL) do
	if (v ~= _A) then
		_TEMP_X, _TEMP_Y = fl:GetPos(v)
		-- check if nodes have the same X value
		if _TEMP_Y == _AY then
			newpos = _TEMP_Y + (k-1)
		else
			newpos = _TEMP_Y
		end
		fl:SetPos(v, _AX, newpos)
	end
end
comp:Unlock()
comp:EndUndo()
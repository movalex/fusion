---------------------------------------
-- Graceful clip failure tool
-- Sets up a BG and DX to catch out of range LDs
-- March 26 2008
-- Chad Capeland
--
-- To do:
-- 1) Check LD's flow position, so new tools are placed in a logical coordinate in the flow.
-- 2) Figure out a way to force the LD to render without using a viewer.
---------------------------------------
--
-- declare the function
function BGDX(t)
	-- get the attributes of the tool
		 local ta = t:GetAttrs()
		 local tx,ty = comp.CurrentFrame.FlowView:GetPos(t)
		 if ta.TOOLI_ImageDepth == nil then
			print (t, "has not rendered yet, new BG parameters will be set to defaults and may not be incorrect")
			
			local bg = comp:AddTool("Background")
			local dx = comp:AddTool("Dissolve")
			-- connect the tools together
			dx.Background = bg.Output
			dx.Foreground = t.Output
			-- set their positions
			comp.CurrentFrame.FlowView:SetPos(bg, tx + 0.5, ty)
			comp.CurrentFrame.FlowView:SetPos(dx, tx, ty + 0.5)
		 else
			-- assign some variables
			local w = ta.TOOLI_ImageWidth
			local h = ta.TOOLI_ImageHeight
			local d = (ta.TOOLI_ImageDepth) - 4
			local xa = ta.TOOLN_ImageAspectX
			local ya = ta.TOOLN_ImageAspectY
		
			-- add some tools
			local bg = comp:AddTool("Background")
			local dx = comp:AddTool("Dissolve")
				-- set some properties
			bg.Width = w
			bg.Height = h
			bg.Depth = d
			bg.PixelAspect = {xa,ya}
				-- connect the tools together
			dx.Background = bg.Output
			dx.Foreground = t.Output
				-- set their positions
			comp.CurrentFrame.FlowView:SetPos(bg, tx + 0.5, ty)
			comp.CurrentFrame.FlowView:SetPos(dx, tx, ty + 0.5)
		end
	end
	
-- run the function
	if tool.Clip then -- test to see if it is a functional LD
	BGDX(tool)
		-- output an error if tool is not a loader
	else print( toolname, "is not a Loader.  This script is designed to allow for graceful failure of LDs whose ranges do not match that of the requesting tool.  Look at you, fancy Time Lord.")
	end
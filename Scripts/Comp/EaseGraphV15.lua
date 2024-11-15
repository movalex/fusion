--[[--
EaseGraph


V15: Added "Connect_to"-Functionality
Show Easevalue in Label
--]]--

FuRegisterClass("EaseGraph", CT_SourceTool, {
	REGS_Category = "Fuses",
	REGS_OpIconString = "fEg",
	REGS_OpDescription = "EaseGraph Fuse",
	
	REG_Source_GlobalCtrls = true,
	REG_Source_SizeCtrls = true,
	REG_Source_AspectCtrls = true,
	REG_Source_DepthCtrls = true,	
	
	REG_Version              = 000015,
	})
 

-- define global variables 	
	boolShowCurve = 0
	boolRelativeCurve = 0
	p1 = 0
	p2 = 0
	p3 = 0
	p4 = 0
	p5 = 0
	
	s1 = 0
	s2 = 0
	s3 = 0
	s4 = 0
	s5 = 0
		
	a1 = 0
	a23 = 0
	a4 = 0
	a5 = 0
	b5 = 0
	c5 = 0

	te = 0
	time1 = 0
	time2 = 0
	boolSetup = 0

 
function Create()
	btn01 = self:AddInput("1", "btn1", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})	
	btn02 = self:AddInput("2", "btn2", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})	
	btn03 = self:AddInput("3", "btn3", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})
	btnLink = self:AddInput("link", "lnk", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,		
		ICD_Width = 0.2,
	})			
	btn04 = self:AddInput("4", "btn4", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})	
	btn05 = self:AddInput("AR", "btn5", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})		
	btn06 = self:AddInput("RA", "btn6", {
		LINKID_DataType = "Text",
		INPID_InputControl = "ButtonControl",
		INP_DoNotifyChanged = true,
		INP_External = false,
		ICD_Width = 0.12,
	})		

	boolShow = self:AddInput("Show", "boolShow", {
		LINKID_DataType = "Number",
		INPID_InputControl = "CheckboxControl",
		INP_Integer = true,
		INP_Default = 1,
		ICD_Width = 0.55,
	})
	boolRel = self:AddInput("Relative", "boolRelative", {
		LINKID_DataType = "Number",
			INPID_InputControl = "CheckboxControl",
			INP_Integer = true,
			INP_Default = 1,
			ICD_Width = 0.45,
	})		
		
	varX = self:AddInput("time", "x", {
		LINKID_DataType = "Number",
		INPID_InputControl = "SliderControl",
		INP_Integer = false,
		INP_Default = 0,
		INP_MinScale = -1,
		INP_MaxScale = 1,	
	}) 
	varTRate = self:AddInput("time end", "te", {
		LINKID_DataType = "Number",
		INPID_InputControl = "SliderControl",
		INP_Default = 0,
		INP_Integer = false,			
		INP_MinScale = 0,
		INP_MaxScale = 1,
		})		
	varF = self:AddInput("FUNCTION", "f", {
		LINKID_DataType = "Number",
		INPID_InputControl = "SliderControl",
		INP_Integer = false,
		INP_Default = 0,
		INP_MinScale = -1,
		INP_MaxScale = 1,
	}) 	
		
		
		
	self:BeginControlNest("Ease", "Ease", true, {})
	
	InP1 = self:AddInput("Ease In", "p1", {
		LINKID_DataType = "Number",
		INPID_InputControl = "RangeControl",
		INP_Default = 10.0,
		IC_ControlGroup = 1,
		IC_ControlID = 0,
		INP_MinScale = 0,
		INP_MaxScale = 100,		
	})			
	InP4 = self:AddInput("Ease Out", "p4", {
		LINKID_DataType = "Number",
		INPID_InputControl = "RangeControl",
		INP_Default = 90.0,
		IC_ControlGroup = 1,
		IC_ControlID = 1,
		INP_MinScale = 0,
		INP_MaxScale = 100,				
	})
	InS1 = self:AddInput("Slope In", "s1", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 1,
	   INP_MinScale = 0,
	   INP_MaxScale = 2,	   
	}) 
	  InS4 = self:AddInput("Slope Out", "s4", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = -1,
	   INP_MinScale = -2,
	   INP_MaxScale = 0,
	}) 
	  InA1 = self:AddInput("Hight In", "a1", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 0.5,
	   INP_MinScale = -5,
	   INP_MaxScale = 5,
	}) 
	  
	InA4 = self:AddInput("Hight Out", "a4", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = -0.5,
	   INP_MinScale = -5,
	   INP_MaxScale = 5,
	}) 	  
	
  	self:EndControlNest()
	
	self:BeginControlNest("Wave", "Wave", true, {})
		
	InP2 = self:AddInput("Wave In", "p2", {
		LINKID_DataType = "Number",
		INPID_InputControl = "RangeControl",
		INP_Default = 10.0,
		IC_ControlGroup = 6,
		IC_ControlID = 0,
		INP_MinScale = 0,
		INP_MaxScale = 100,		
	})			
	
	InP3 = self:AddInput("Wave Out", "p3", {
		LINKID_DataType = "Number",
		INPID_InputControl = "RangeControl",
		INP_Default = 50.0,
		IC_ControlGroup = 6,
		IC_ControlID = 1,
		INP_MinScale = 0,
		INP_MaxScale = 100,				
	})		
	
	InS2 = self:AddInput("Slope In", "s2", {
		LINKID_DataType = "Number",
		INPID_InputControl = "SliderControl",
		INP_Integer = false,
		INP_Default = 1,
		INP_MinScale = 0,
		INP_MaxScale = 5,
	}) 
	InS3 = self:AddInput("Slope Out", "s3", {
		LINKID_DataType = "Number",
		INPID_InputControl = "SliderControl",
		INP_Integer = false,
		INP_Default =  0.2,
		INP_MinScale = 0,
		INP_MaxScale = 5,
	}) 
	
	InA23 = self:AddInput("Amplitude", "a23", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 1.0,
	   INP_MinScale = -5,
	   INP_MaxScale = 5,
	}) 
	  
	  
	InP5 = self:AddInput("Pos Damp", "p5", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 0,
	   INP_MinScale = -100,
	   INP_MaxScale = 200,
	}) 	  	  
	  
	InS5 = self:AddInput("Freq Damp1", "s5", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 2.0,
	   INP_MinScale = 1,
	   INP_MaxScale = 6,
	}) 	  	  	  
	  
	InA5 = self:AddInput("Freq Damp2", "a5", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 2.5,
	   INP_MinScale = 0,
	   INP_MaxScale = 5,
	}) 	  
	  
	InB5 = self:AddInput("Pow Damp2", "b5", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 1.0,
	   INP_MinScale = 0.0,
	   INP_MaxScale = 5,
	}) 	  	  
	  
	InC5 = self:AddInput("Phase Shift", "c5", {
	   LINKID_DataType = "Number",
	   INPID_InputControl = "SliderControl",
	   INP_Integer = false,
	   INP_Default = 3.15,
	   INP_MinScale = 0,
	   INP_MaxScale = 6.3,
	}) 	 
		 
	self:EndControlNest()		

	self:BeginControlNest("Color", "Color", true, {})
	InR = self:AddInput("Red", "Red", {
		LINKID_DataType = "Number",
		INPID_InputControl = "ColorControl",
		INP_MinScale = 0.0,
		INP_MaxScale = 1.0,
		INP_Default  = 1.0,
		ICS_Name = "Color",
		IC_ControlGroup = 1,
		IC_ControlID = 0,
	})
	InG = self:AddInput("Green", "Green", {
		LINKID_DataType = "Number",
		INPID_InputControl = "ColorControl",
		INP_MinScale = 0.0,
		INP_MaxScale = 1.0,
		INP_Default  = 0.6,
		IC_ControlGroup = 1,
		IC_ControlID = 1,
	})
		
	InB = self:AddInput("Blue", "Blue", {
		LINKID_DataType = "Number",
		INPID_InputControl = "ColorControl",
		INP_MinScale = 0.0,
		INP_MaxScale = 1.0,
		INP_Default  = 0.3,
		IC_ControlGroup = 1,
		IC_ControlID = 2,
	})
		
	self:EndControlNest()	

  InLabelEase = self:AddInput("Ease", "LabelEase", {
    LINKID_DataType = "Text",
    INPID_InputControl = "LabelControl",
    INP_External = false,
    INP_Passive = true,
  })

OutEase = self:AddOutput("Ease", "EaseCourse", {
    LINKID_DataType = "Number",
  })

end
 
 
function fkt(x,req)
	 -- Control Expressions: (implemented in function Process)
	 -- time    : iif(boolRelative==1,time/comp.RenderEnd*100,time)     
	 -- FUNCTION: (a1/(1+2^(s1*(p1-x)))+((a23/(1+2^(s2*(p2-x))))-(a23/(1+2^(s3*(p3-x)))))*(sin((10^(-a5)*(p5-x)^s5)+c5))^b5-(a4/(1+2^(s4*(p4-x)))))+a4
      
	  y=(a1/(1+2^(s1*(p1-x)))+((a23/(1+2^(s2*(p2-x))))-(a23/(1+2^(s3*(p3-x)))))*(math.sin((10^(-a5)*(p5-x)^s5)+c5))^b5-(a4/(1+2^(s4*(p4-x)))))+a4 
	return y 	
end
 
function NotifyChanged(inp, param, time)
	if (param ~= nil) then	
		if (param.Value == 1) then
			if (inp == btnLink) then
				os.execute('open "" "https://www.desmos.com/calculator/9kktufyeba"')
				os.execute('start "" "https://www.desmos.com/calculator/9kktufyeba"')
			end	
			
			if (inp == btn01) then					
				InP1:SetSource(Number(10),0)  
				InP2:SetSource(Number(40),0)  
				InP3:SetSource(Number(80),0)  
				InP4:SetSource(Number(90),0)  
				InP5:SetSource(Number(100),0)  
				
				InS1:SetSource(Number(1),0)  
				InS2:SetSource(Number(0.17),0)  
				InS3:SetSource(Number(1),0)  
				InS4:SetSource(Number(-1),0)  
				InS5:SetSource(Number(2.4),0)  
				
				InA1:SetSource(Number(0),0)  
				InA23:SetSource(Number(0.5),0)  
				InA4:SetSource(Number(1),0)  
				InA5:SetSource(Number(3.5),0)  
				InB5:SetSource(Number(2),0)  
				InC5:SetSource(Number(3.5),0)  			
				boolRelativeCurve:SetSource(Number(1),0)						
			end
			
			if (inp == btn02) then
				InP1:SetSource(Number(20),0)  
				InP2:SetSource(Number(40),0)  
				InP3:SetSource(Number(15),0)  
				InP4:SetSource(Number(50),0)  
				InP5:SetSource(Number(100),0)  
				
				InS1:SetSource(Number(0.5),0)  
				InS2:SetSource(Number(1),0)  
				InS3:SetSource(Number(1),0)  
				InS4:SetSource(Number(-0.2),0)  
				InS5:SetSource(Number(2.4),0)  
				
				InA1:SetSource(Number(-0.5),0)  
				InA23:SetSource(Number(0.7),0)  
				InA4:SetSource(Number(1.5),0)  
				InA5:SetSource(Number(4),0)  
				InB5:SetSource(Number(1),0)  
				InC5:SetSource(Number(2.6),0)  			
				boolRelativeCurve:SetSource(Number(1),0)									
			end
			
			if (inp == btn03) then
			end
			
			if (inp == btn04) then					
			end
			
			if (inp == btn05) then
			end

			if (inp == btn06) then
			end			
			
		end	
	end
end 
 
 
function PreCalcProcess(req)
  -- Attributes for new images
  local imgattrs = {
    IMG_Document = self.Comp,
    { IMG_Channel = "Red", },
    { IMG_Channel = "Green", },
    { IMG_Channel = "Blue", },
    { IMG_Channel = "Alpha", },
    IMG_Width = Width,
    IMG_Height = Height,
    IMG_XScale = XAspect,
    IMG_YScale = YAspect,
    IMAT_OriginalWidth = realwidth,
    IMAT_OriginalHeight = realheight,
    IMG_Quality = not req:IsQuick(),
    IMG_MotionBlurQuality = not req:IsNoMotionBlur(),
  }

  -- Initialize the images
  local img = Image(imgattrs)

  local tRate= req.Time/self.Comp.GlobalEnd
        
  local f1 = fkt(tRate*100,req)  
      
  OutEase:Set(req, f1)

  -- output image with no data
  local out = Image({IMG_Like = img, IMG_NoData = true})
  OutImage:Set(req, out)

end
 
 

function Process(req) 

-- ### install Simple Expressions ###
	if (boolSetup == 0) then                     -- only used one time, when needs to be renewed push reload button
		local fusion = Fusion() 				
		local comp = fusion.CurrentComp 		
		local tool = comp:FindTool(self.Name) 
		local expr1 = tool.x:GetExpression()
		local expr2 = tool.f:GetExpression()
		if (expr1 == nil) or (expr2 == nil) then   -- safety that cache will not be destroyed
			tool.x:SetExpression("iif(boolRelative==1,time/comp.RenderEnd*100,time)")
			tool.f:SetExpression("(a1/(1+2^(s1*(p1-x)))+((a23/(1+2^(s2*(p2-x))))-(a23/(1+2^(s3*(p3-x)))))*(sin((10^(-a5)*(p5-x)^s5)+c5))^b5-(a4/(1+2^(s4*(p4-x)))))+a4")
		end
		boolSetup = 1
	end
				
-- ### update global variables ###
	boolShowCurve = boolShow: GetValue(req).Value
		
	if (boolShowCurve == 1) then 
		boolRelativeCurve = boolRel:GetValue(req).Value	

		p1 = InP1:GetValue(req).Value  
		p2 = InP2:GetValue(req).Value  
		p3 = InP3:GetValue(req).Value  
		p4 = InP4:GetValue(req).Value  
		p5 = InP5:GetValue(req).Value  
			
		s1 = InS1:GetValue(req).Value  
		s2 = InS2:GetValue(req).Value  
		s3 = InS3:GetValue(req).Value  
		s4 = InS4:GetValue(req).Value  
		s5 = InS5:GetValue(req).Value  
			
		a1 = InA1:GetValue(req).Value  
		a23 = InA23:GetValue(req).Value  
		a4 = InA4:GetValue(req).Value  
		a5 = InA5:GetValue(req).Value  
		b5 = InB5:GetValue(req).Value  
		c5 = InC5:GetValue(req).Value  

		te = self.Comp.GlobalEnd
	end

	local R1 = InR:GetValue(req).Value   
	local G1 = InG:GetValue(req).Value   
	local B1 = InB:GetValue(req).Value   	
	
	local p1 = Pixel({A=0.5})
	p1.R = R1
	p1.G = G1
	p1.B = B1
	
	local realwidth = Width;
	local realheight = Height;
	local x = 0
	local y = 0
	
	Width = Width / Scale
	Height = Height / Scale
	Scale = 1
	
	local imgattrs = {
		IMG_Document = self.Comp,
		{ IMG_Channel = "Red", },
		{ IMG_Channel = "Green", },
		{ IMG_Channel = "Blue", },
		{ IMG_Channel = "Alpha", },
		IMG_Width = Width,
		IMG_Height = Height,
		IMG_XScale = XAspect,
		IMG_YScale = YAspect,
		IMAT_OriginalWidth = realwidth,
		IMAT_OriginalHeight = realheight,
		IMG_Quality = not req:IsQuick(),
		IMG_MotionBlurQuality = not req:IsNoMotionBlur(),
	}
	
	if not req:IsStampOnly() then
		imgattrs.IMG_ProxyScale = 1
	end
	
	if SourceDepth ~= 0 then
		imgattrs.IMG_Depth = SourceDepth
	end
	

-- ### Start to build up Graph ###
	local img = Image(imgattrs)
	local p = Pixel({A=1})	
	
	

	-- Will try to be changed by using DoMultiProcess
	-- Use of Simple Expressions should be bottlenck for speed
	img:Clear()
	
	-- ##########################################################
	-- varTRate:SetSource(Number(req.Time/self.Comp.GlobalEnd),0)
	
	local tRate= req.Time/self.Comp.GlobalEnd
	if (boolRelativeCurve == 1) then te = 100 end					
	local f1 = fkt(tRate*te,req)			
	
	-- #########################################################
	-- varF:SetSource(Number(f1),0)
		
	if (boolShowCurve ==1) then	
		p.R = 255
		p.G = 255
		p.B = 255	
		
		for y = (Height/2-20), (Height/2+20) do	
			for x = 0, 11 do
				img:SetPixel(x*Width/10-3,y, p)					
				img:SetPixel(x*Width/10-2,y, p)		
				img:SetPixel(x*Width/10-1,y, p)
				img:SetPixel(x*Width/10,y, p)
				img:SetPixel(x*Width/10+1,y, p)
				img:SetPixel(x*Width/10+2,y, p)			
				img:SetPixel(x*Width/10+3,y, p)			
			end
		end

		y = Height/2
		for x=0,(Width-3)/2 do		
				img:SetPixel(x*2,y, p)
				img:SetPixel(x*2,y-1, p)
				img:SetPixel(x*2,y+1, p)
				img:SetPixel(x*2,y-2, p)
				img:SetPixel(x*2,y+2, p)			
		end	

		x = tRate*Width
		for y = (Height/2-30), (Height/2+30) do	
			img:SetPixel(x,y, p)		
			img:SetPixel(x+3,y, p)
			img:SetPixel(x-3,y, p)			
			img:SetPixel(x+2,y, p)
			img:SetPixel(x-2,y, p)
			img:SetPixel(x+1,y, p)
			img:SetPixel(x-1,y, p)			
		end
		
		for y = (Height/2-30), (Height/2+30) do	
			if (f1*200+y < Height-5) then
				if (f1*200+y > 5) then				
					img:SetPixel(x,f1*200+y, p)		
					img:SetPixel(x+1,f1*200+y, p)
					img:SetPixel(x-1,f1*200+y, p)
					img:SetPixel(x+2,f1*200+y, p)
					img:SetPixel(x-2,f1*200+y, p)			
					img:SetPixel(x+3,f1*200+y, p)
					img:SetPixel(x-3,f1*200+y, p)						
				end
			end
		end

		local f2=0			
		for x= 0, Width-3 do
			f2 = fkt(x/Width*te,req)
			for y = (Height/2-5), (Height/2+5) do	
				if (f2*200+y < Height-5) then
					if (f2*200+y > 5) then
						img:SetPixel(x,f2*200+y, p1)		
					end
				end
			end
		end
	end
	
	
	lb_str = (string.format("Ease   %g",f1))
  InLabelEase:SetAttrs({LINKS_Name = lb_str,LBLC_LabelColor = 2,})
	
	local f1 = fkt(tRate*100,req)  
  OutEase:Set(req, f1)
	
	OutImage:Set(req, img)	
end
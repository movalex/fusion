--
--
--  Dual Monitor Setup Hackaroo for Fusion 16
--
--  Written by Kel Sheeran of ISDK Films
--
--  Copyright 2019
--
--  v1.0	19 Nov 2019		Prototype created
--


s = comp.CurrentFrame:GetViewLayout()

--print('\n\nBEFORE\n')
--dump(s)


_Viewers =  {{ __flags = 256, RatioX = 0.5, RatioY = 1, ID = 'Viewer1' }, { ID = 'Viewer2',  __flags = 256, RatioX = 0.5 }, RatioX = 1, RatioY = 0.72, Columns = 2 }
_Time = {__flags = 256, FixedY =83, Flat = true, ID = 'Time'}
_Left =  { _Viewers , _Time, RatioX = 1, RatioY = 1, Rows = 2 }

_Effects = { __flags = 256, PixelX = 320, RatioY = 1, ID = 'Effects' }
_Nodes = { __flags = 256, RatioY = 1, ID = 'Nodes' }
_Inspector = { __flags = 256, PixelX = 440, RatioY = 1, ID = 'Inspector' }
_Right =  { _Effects, _Nodes, _Inspector, RatioX = 1, RatioY = 1, Columns = 3 }

nl = { _Left , _Right, Columns = 2, RatioX = 1, RatioY = 1 }

s.ViewInfo.LayoutStrip.Show = false
s.ViewInfo.ActionStrip.Show = false
s.ViewInfo.Spline.Show = false
s.ViewInfo.Keyframes.Show = false

-- Add Tabs to Nodes View
s.Views.Nodes.ViewList.TimelineView='TimelineView'
s.Views.Nodes.ViewList.SplineView='SplineView'

s.Layout = nl

--print('\n\nAFTER\n')
--dump(nl)

comp.CurrentFrame:SetViewLayout(s)

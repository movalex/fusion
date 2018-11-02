sv = comp.CurrentFrame.SplineView
if sv == nil then
    print('Spline view has to be selected')
else
    sv:GoPrevKeyTime()
end
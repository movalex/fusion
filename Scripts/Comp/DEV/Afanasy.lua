-- eyeon script for submission to render with Afanasy render manager
-- written by Mikhail Korovyansky
-- mclawest@mail.ru
-- updated to work with Afanasy 3 and Fusion 16/17 by Alexey Bogomolov 1.15.2021
-- mail@abogomolov.com

-- SUBMIT TO AFANASY

	-- create dialog on unsaved composition
function MessageBox(msg, title)
	local d = {}
	d[1] = {"Msg", Name = "Message", "Text", ReadOnly = true, Default = msg ,Lines = 2 ,Wrap = true}
	comp:AskUser( title, d )
end

	-- get global parameters
gcp = composition:GetAttrs()

	-- check if the composition is saved and have been named
if gcp.COMPS_FileName == "" then
	MessageBox( "You must save the comp before you can submit it.", "Submit to Afanasy" )
	return
end

	-- autosave the comp if it was modified but not saved before submission
if gcp.COMPB_Modified then
    comp:Save(gcp.COMPS_FileName)
end 

	-- define global path to Afanasy
	tenv = os.getenv("AF_ROOT")
if tenv == nil then
	MessageBox( "Launch Fusion from CGRU Keeper.", "Submit to Afanasy" )
	return
else
    -- sysPath = os.getenv("CGRU_LOCATION")
	-- afpy = sysPath .."/python/python.exe ".. tenv .. "/python/afjob.py"
    afpy = "python" .." ".. tenv .. "/python/afjob.py"
end

	-- get full path to comp file
fcn = gcp.COMPS_FileName

	-- get first render frame
frf = gcp.COMPN_RenderStartTime

	-- get last render frame
lrf = gcp.COMPN_RenderEndTime

	-- show message at launch
msg = " Comp is ready for submission"

	-- GUI
dialog = composition:AskUser(
  "Submit to Afanasy",
  {
    { "Start Frame", Name = "Start Frame", "Text", Lines = 1, Wrap = false, Default = frf },
    { "Last Frame" , Name = "Last Frame" , "Text", Lines = 1, Wrap = false, Default = lrf },
    { "By", Name = "Step", "Text", Lines = 1, Wrap = false, Default = 1},
    { "Frames Per Task" , Name = "Frames Per Task" , "Text", Lines = 1, Wrap = false, Default = lrf-frf+1 },
    { "Hosts Mask" , Name = "Hosts Mask" , "Text", Lines = 1, Wrap = false, Default = "" },
    { "Status"  , Name = "Status"  , "Text", Lines = 1, Wrap = false, Default = msg, ReadOnly = true },
  }
)

	-- get rid from attention in console if dialog was denied by Cancel button
if dialog == nil then
	return
end

	-- get first render frame specified in GUI
mfrf = dialog["Start Frame"]

	-- get last render frame specified in GUI
mlrf = dialog["Last Frame"]

by = "-by "..dialog["By"]

	-- get frames per task
fpt = "-fpt" .." ".. dialog["Frames Per Task"]

parseCompName = bmd.parseFilename(fcn)
pwd = " -pwd " .. parseCompName.Path
cmp = " -name " .. parseCompName.Name

	-- get host mask
hosts_mask = dialog["Hosts Mask"]

if hosts_mask ~= "" then
    hosts_mask = " -hostsmask " .. hosts_mask
end

	-- collect main command for cmd
rcom = afpy .." ".. fcn .." ".. mfrf .." ".. mlrf .." ".. by .." ".. fpt .. " -seq 1" .. pwd .. hosts_mask ..  cmp --.. " -tempscene -deletescene"


	-- print the main command in console
print("Command Line Command:  " .. rcom)

	-- run cmd render
os.execute(rcom)

	-- exit message
MessageBox( "Successfully Submitted.", "Submit to Afanasy" )


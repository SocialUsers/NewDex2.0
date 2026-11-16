"""Exercise the real splash choreography with an owned GUI and frame clock."""
import argparse
import json
from pathlib import Path
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--luau', default='luau')
parser.add_argument('--snapshots', type=Path, help='Write sampled motion values as JSON for a local preview')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
mock = (root / 'tests/roblox_mock.luau').read_text(encoding='utf-8')
source = (root / 'src/Shared/LoadingSplash.lua').read_text(encoding='utf-8')
program = mock + r'''
do
local ColorSequence = {new=function(value) return {Keypoints=value} end}
local ColorSequenceKeypoint = {new=function(time,value) return {Time=time,Value=value} end}
local NumberSequence = {new=function(value) return {Keypoints=value} end}
local NumberSequenceKeypoint = {new=function(time,value) return {Time=time,Value=value} end}
-- Any hidden wait in Create/SetProgress/Close would fail rather than stall tests.
local task = {wait=function() error("splash must not wait") end,delay=function() error("splash must not schedule a detached timer") end}
local control = (function()
''' + source + r'''
end)()
local function fixture(options)
 options=options or {}
 local callbacks,active,disconnects={},0,0
 local frame={Connect=function(_,fn)
  active+=1
  local item={fn=fn,connected=true}
  callbacks[#callbacks+1]=item
  return {Disconnect=function()
   if item.connected then item.connected=false active-=1 disconnects+=1 end
  end}
 end}
 local owned,cleanup
 local main={Alive=true,DisplayOrders={Menu=10},
  GetStudioAsset=function(key)
   assert(key=="branding/dex/toolbar-white-v1")
   if not options.noAsset then return "owned://dex-logo" end
  end,
  SecureGui=function(gui) owned=gui end,
  AddCleanup=function(fn) assert(not cleanup,"one cleanup owner") cleanup=fn end}
 local settings={Theme={
  Brand=Color3.fromRGB(60,100,250),Focus=Color3.fromRGB(51,95,255),
  SelectedText=Color3.fromRGB(238,239,241),Text=Color3.fromRGB(213,215,221),
  Menu=Color3.fromRGB(25,27,31),Outline2=Color3.fromRGB(55,55,55),
  PlaceholderText=Color3.fromRGB(187,188,190)}}
 control.InitDeps({Main=main,Settings=settings,service=options.noFrames and {} or {RunService={RenderStepped=frame}},createSimple=createSimple})
 local api=control.Main()
 local splash=api.Create("Loading library")
 local function step(dt)
  for _,item in ipairs(table.clone(callbacks)) do if item.connected then item.fn(dt) end end
 end
 local function advance(seconds)
  local remaining=seconds
  while remaining>1e-8 do local dt=math.min(.05,remaining) step(dt) remaining-=dt end
 end
 return {splash=splash,main=main,gui=owned,card=owned.Status,step=step,advance=advance,
  cleanup=function() cleanup() end,active=function() return active end,disconnects=function() return disconnects end}
end

-- Preview sampling reads production-calculated values; no extra production API.
local function jsonValue(value)
 if type(value)=="string" then return string.format("%q",value) end
 if type(value)=="boolean" or type(value)=="number" then return tostring(value) end
 local entries={}
 for key,item in pairs(value) do entries[#entries+1]=string.format("%q",key)..":"..jsonValue(item) end
 table.sort(entries)
 return "{"..table.concat(entries,",").."}"
end
local sample=fixture()
local function snapshot(time,closing)
 local card=sample.card
 local title=card.TitleMask.Title
 local subtitle=card.SubtitleMask.Subtitle
 local mark=card.Brand
 local image=mark.Reveal.Logo
 local bg=card:FindFirstChildOfClass("UIGradient")
 local stroke=card:FindFirstChildOfClass("UIStroke")
 local data={time=time,closing=closing,closed=sample.gui.Destroyed==true,
  panelY=card.Position.Y.Offset,titleX=title.Position.X.Offset,titleAlpha=title.TextTransparency,
  subtitleX=subtitle.Position.X.Offset,subtitleAlpha=subtitle.TextTransparency,
  markX=mark.Position.X.Offset,markY=mark.Position.Y.Offset,markRotation=mark.Rotation or 0,
  reveal=mark.Reveal.Size.X.Scale,logoAlpha=image.ImageTransparency,
  slabAlpha=card.Slab.BackgroundTransparency,
  strokeAlpha=stroke.Transparency,bgOffset=bg.Offset.X,markScale=mark.EntranceScale.Scale,activityAlpha=card.Activity.BackgroundTransparency,
  statusAlpha=card.Message.TextTransparency,statusY=card.Message.Position.Y.Offset,
  percentAlpha=card.Percent.TextTransparency,progressScale=card.Progress.Size.X.Scale,
  progressOffset=card.Progress.Size.X.Offset,progressAlpha=card.Progress.BackgroundTransparency,
  fillAlpha=card.Progress.Fill.BackgroundTransparency,shown=card.Progress.Fill.Size.X.Scale,
  message=card.Message.Text,percent=card.Percent.Text}
 print("SNAPSHOT\t"..jsonValue(data))
end
local previous=0
for _,time in ipairs({0,.15,.3,.5,.8,1.2}) do
 sample.advance(time-previous) previous=time
 if time==.3 then sample.splash.SetProgress("Loading class details",.35) end
 if time==.8 then sample.splash.SetProgress("Loading tools",.75) end
 snapshot(time,false)
end
sample.splash.SetProgress("Ready",1) sample.splash.Close()
sample.advance(.1) snapshot(.1,true)
sample.advance(.13) snapshot(.23,true)

-- Validate curve bounds at small frame steps and equivalent timing at different FPS.
for _,fps in ipairs({30,60,144}) do
 local motion=fixture()
 for _=1,fps do
  motion.step(1/fps)
  for _,alpha in ipairs({motion.card.TitleMask.Title.TextTransparency,motion.card.Brand.Reveal.Logo.ImageTransparency,motion.card.Activity.BackgroundTransparency}) do
   assert(alpha==alpha and alpha>=0 and alpha<=1,"motion opacity remains finite and bounded")
  end
 end
 local position=motion.card.Brand.Position
 assert(position.X.Offset==0 and position.Y.Offset==126 and motion.card.Brand.EntranceScale.Scale==1,"entrance settles identically at different frame rates")
 motion.cleanup()
end

local a=fixture()
local card=a.card
assert(a.active()==1 and not a.gui.Destroyed,"Create returns before its entrance finishes and owns one frame connection")
assert(card.AnchorPoint.X==.5 and card.AnchorPoint.Y==.5 and card.Position==UDim2.fromScale(.5,.5),"splash starts centered")
local constraint=card:FindFirstChildOfClass("UISizeConstraint")
assert(constraint.MaxSize.X==488 and constraint.MaxSize.Y==280,"compact original-sized splash")
local background=card:FindFirstChildOfClass("UIGradient")
assert(card.TitleMask.Title.TextTransparency==1 and card.Brand.Reveal.Logo.ImageTransparency==1,"initial state is hidden until the entrance runs")
assert(not card.Brand:FindFirstChild("Corner1"),"logo has no corner brackets")
assert(not card.Brand.Reveal.Logo:FindFirstChildOfClass("UIGradient") and not card.Progress.Fill:FindFirstChild("Sheen"),"logo and progress have no shimmer effects")
local startWipe=background.Offset.X
a.step(.05)
local startTitle=card.TitleMask.Title.Position.X.Offset
assert(startTitle<0 and background.Offset.X>startWipe,"first frame slides masked title and wipes the background")
a.advance(.2)
assert(card.TitleMask.Title.Position.X.Offset>startTitle and card.TitleMask.Title.TextTransparency<1,"title progressively enters")
assert(card.Brand.EntranceScale.Scale>.9 and card.Brand.EntranceScale.Scale<1,"mark settles into place with a short scale transition")
for _,object in ipairs(card:GetDescendants()) do
 if object.ClassName=="Frame" then assert((object.Rotation or 0)==0,"native masks cannot depend on rotated clipping being enabled") end
end
a.advance(.55)
assert(card.TitleMask.Title.Position.X.Offset==0 and card.TitleMask.Title.TextTransparency==0,"entrance settles the title")
assert(card.Brand.Reveal.Size.X.Scale==1 and card.Brand.Reveal.Logo.ImageTransparency==0,"existing Dex mark finishes revealing")
assert(card.Progress.Size.X.Scale==1 and card.Message.TextTransparency==0,"status and track are fully visible")
local beforeMotion=card.Brand.Position.Y.Offset
local activity=card.Activity.BackgroundTransparency
a.advance(.4)
assert(card.Brand.Position.Y.Offset==beforeMotion and card.Brand.EntranceScale.Scale==1,"logo stays still after its entrance")
assert(card.Activity.BackgroundTransparency~=activity,"only the small loading cue keeps moving")

a.splash.SetProgress("Loading tools",.75)
assert(card.Message.Text=="Loading tools" and card.Percent.Text=="75%","actual stage and percentage update immediately")
assert(card.Progress.Fill.Size.X.Scale<.75,"bar does not jump to its target")
a.step(.05)
local partial=card.Progress.Fill.Size.X.Scale
assert(partial>0 and partial<.75,"bar smoothly approaches progress")
a.splash.SetProgress(nil,.2)
a.splash.SetProgress(nil,0/0)
a.splash.SetProgress(nil,math.huge)
a.splash.SetProgress(nil,-math.huge)
assert(card.Percent.Text=="75%","older and non-finite values do not replace progress")
a.advance(1)
assert(card.Progress.Fill.Size.X.Scale==.75,"bar settles at the actual target")
a.splash.SetProgress("Ready",2)
assert(card.Percent.Text=="100%","progress is clamped")
a.splash.Close() a.splash.Close()
a.splash.SetProgress("Late message",0)
assert(card.Message.Text=="Ready","late updates are ignored while closing")
a.step(.1)
assert(not a.gui.Destroyed and a.active()==1,"exit runs asynchronously")
assert(card.TitleMask.Title.TextTransparency>0 and card.Progress.BackgroundTransparency>0 and card.Position.Y.Offset<0,"exit moves and fades the composition together")
a.step(.1)
assert(not a.gui.Destroyed,"exit remains until its 0.22-second duration")
a.step(.03)
assert(a.gui.Destroyed and a.active()==0 and a.disconnects()==1,"exit destroys GUI and disconnects its frame listener")
a.splash.Close() a.cleanup() a.splash.SetProgress("Too late",0)
assert(a.disconnects()==1 and card.Message.Text=="Ready","repeated close/cleanup is safe")

for _,duringExit in ipairs({false,true}) do
 local b=fixture()
 b.step(.05)
 if duringExit then b.splash.Close() b.step(.05) end
 b.main.Alive=false b.cleanup()
 assert(b.gui.Destroyed and b.active()==0 and b.disconnects()==1,"shutdown immediately stops entrance or exit")
 b.step(.1) b.cleanup() b.splash.Close()
 assert(b.disconnects()==1,"shutdown leaves no live callbacks")
end
local c=fixture()
c.main.Alive=false c.step(.016)
assert(c.gui.Destroyed and c.active()==0,"frame guard stops work if the owner dies")

local d=fixture({noAsset=true,noFrames=true})
assert(d.active()==0 and d.card.Brand.Reveal.LogoFallback and not d.card.Brand.Reveal:FindFirstChild("Logo"),"missing assets use the text mark")
assert(d.card.TitleMask.Title.TextTransparency==0 and d.card.Brand.Reveal.Size.X.Scale==1,"missing RunService falls back to a visible static splash")
d.splash.SetProgress("Ready",1)
assert(d.card.Progress.Fill.Size.X.Scale==1 and d.card.Percent.Text=="100%","static fallback still reports real progress")
d.splash.Close() d.splash.Close() d.cleanup()
assert(d.gui.Destroyed,"static fallback closes immediately")
print("PASS: coordinated splash entrance, solid settled logo, isolated activity cue, frame-rate/opacity bounds, smooth progress, exit and teardown")
end
'''
with tempfile.TemporaryDirectory(prefix='dex-loading-splash-') as directory:
    path = Path(directory) / 'test.luau'
    path.write_text(program, encoding='utf-8')
    try:
        result = subprocess.run([args.luau, str(path)], check=True, capture_output=True, text=True)
        snapshots = []
        for line in result.stdout.splitlines():
            if line.startswith('SNAPSHOT\t'):
                snapshots.append(json.loads(line.split('\t', 1)[1]))
            else:
                print(line)
        if args.snapshots:
            args.snapshots.parent.mkdir(parents=True, exist_ok=True)
            args.snapshots.write_text(json.dumps(snapshots, indent=2), encoding='utf-8')
            print(f'Motion samples written to {args.snapshots}')
    except subprocess.CalledProcessError as error:
        if error.stdout:
            print(error.stdout, end='')
        if error.stderr:
            print(error.stderr, end='')
        saved = root / '.build/loading_splash_failed.luau'
        saved.parent.mkdir(parents=True, exist_ok=True)
        saved.write_text(program, encoding='utf-8')
        print(f'Failed fixture saved to {saved}', flush=True)
        raise

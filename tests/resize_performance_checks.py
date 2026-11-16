"""Exercise actual floating/dock drag handlers with high-frequency input."""
import argparse
from pathlib import Path
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]
cli=argparse.ArgumentParser()
cli.add_argument('--luau',default=str(ROOT/'.tools/bin/luau.exe'))
args=cli.parse_args()
lib=(ROOT/'src/Shared/Lib.lua').read_text()
frame=lib[lib.index('\tlocal frameTasks, frameConnection ='):lib.index('\n\tLib.StudioText = function')]
floating=lib[lib.index('\t\tlocal function resizeHook('):lib.index('\n\t\tlocal updateWindows')]
dock=lib[lib.index('\t\tlocal function sideResizerHook('):lib.index('\n\t\tlocal function renderSide(')]
program=(ROOT/'tests/roblox_mock.luau').read_text()+r'''
service.RunService={RenderStepped=signal()}
local activeFrameJobs=0
local connectFrame=service.RunService.RenderStepped.Connect
service.RunService.RenderStepped.Connect=function(self,fn)
 activeFrameJobs+=1 local con=connectFrame(self,fn) local stopped=false
 return {Disconnect=function() if not stopped then stopped=true activeFrameJobs-=1 con:Disconnect() end end}
end
dimMT.__add=function(a,b) return UDim2.new(a.X.Scale+b.X.Scale,a.X.Offset+b.X.Offset,a.Y.Scale+b.Y.Scale,a.Y.Offset+b.Y.Offset) end
local warnings={} warn=function(message) warnings[#warnings+1]=message end
'''+frame+r'''
local cursors=0 local hover
local function registerResizeTarget() end
local function clearResizeCursor() end
local function refreshResizeCursor() end
local function showResizeCursor() cursors+=1 end
local mouseInset=0
local function currentMousePosition(fallback) return Vector2.new(fallback.X,fallback.Y+mouseInset) end
local function setResizeHover(_,_,value) hover=value end
local resizeDragOwner,resizeDragDirection
'''+floating+r'''
local sizeWrites=0 local oldNewIndex=instMT.__newindex
local observed
instMT.__newindex=function(object,key,value) if object==observed and key=="Size" then sizeWrites+=1 end return oldNewIndex(object,key,value) end
local function floatingCase(dir,touch)
 local main=Instance.new("Frame") main.Position=UDim2.fromOffset(100,100) main.Size=UDim2.fromOffset(400,300)
 local resizer=Instance.new("Frame",main)
 local west=dir:find("W",1,true)~=nil local north=dir:find("N",1,true)~=nil
 local horizontal=dir:find("[WE]")~=nil local vertical=dir:find("[NS]")~=nil
 resizer.Position=UDim2.new(west and 0 or 1,-5,north and 0 or 1,-5) resizer.Size=UDim2.fromOffset(10,10)
 local window={Resizable=true,ResizableInternal=true,MinX=160,MinY=100,SizeX=400,SizeY=300,GuiElems={Main=main},Stops=0}
 function window:StopTweens() self.Stops+=1 end
 resizeHook(window,resizer,dir)
 local at=resizer.AbsolutePosition local start=Vector2.new(at.X+2,at.Y+2)
 local gesture={UserInputType=touch and Enum.UserInputType.Touch or Enum.UserInputType.MouseButton1,Position=start}
 local function move(position)
  local event=touch and gesture or {UserInputType=Enum.UserInputType.MouseMovement}
  event.Position=position
  service.UserInputService.InputChanged:Fire(event)
 end
 resizer.InputBegan:Fire(gesture)
 local priorIndex=instMT.__index
 instMT.__index=function(object,key) if object==resizer and key=="AbsolutePosition" then return at end return priorIndex(object,key) end
 observed=main sizeWrites=0
 for i=1,1000 do move(Vector2.new(start.X+i*.1,start.Y+i*.05)) end
 assert(sizeWrites==0,"resize input bursts queue only the latest geometry")
 service.RunService.RenderStepped:Fire()
 assert(sizeWrites==1 and window.Stops==1,"one geometry write per frame and one tween cancellation per gesture")
 assert(window.SizeX==400+(horizontal and (west and -100 or 100) or 0))
 assert(window.SizeY==300+(vertical and (north and -50 or 50) or 0))
 move(Vector2.new(start.X+100,start.Y+50))
 service.RunService.RenderStepped:Fire()
 assert(sizeWrites==1,"stationary pointer with delayed absolute geometry must not drift or rewrite the window")
 move(Vector2.new(start.X+120,start.Y+60))
 service.UserInputService.InputEnded:Fire(gesture)
 assert(sizeWrites==2 and not window.Resizing,"release applies the final queued movement without waiting for another frame")
 assert(window.SizeX==400+(horizontal and (west and -120 or 120) or 0))
 assert(window.SizeY==300+(vertical and (north and -60 or 60) or 0))
 service.RunService.RenderStepped:Fire() assert(sizeWrites==2,"released gestures cannot write geometry again")
 assert(main.Position.X.Offset==(west and 220 or 100) and main.Position.Y.Offset==(north and 160 or 100),"top/left anchors remain correct")
 observed=nil
 instMT.__index=priorIndex
end
for _,dir in ipairs({"N","S","E","W","NE","NW","SE","SW"}) do floatingCase(dir,false) end
floatingCase("SE",true)
mouseInset=58
floatingCase("SE",false)
mouseInset=0
local function limitsCase(dir,dx,dy,width,height,x,y)
 local main=Instance.new("Frame") main.Position=UDim2.fromOffset(100,100) main.Size=UDim2.fromOffset(400,300)
 local resizer=Instance.new("Frame",main)
 resizer.Position=UDim2.new(dir:find("W",1,true) and 0 or 1,-5,dir:find("N",1,true) and 0 or 1,-5)
 local window={Resizable=true,ResizableInternal=true,MinX=160,MinY=100,SizeX=400,SizeY=300,GuiElems={Main=main},StopTweens=function() end}
 resizeHook(window,resizer,dir)
 local at=resizer.AbsolutePosition local start=Vector2.new(at.X+2,at.Y+2)
 resizer.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=start})
 service.UserInputService.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=Vector2.new(start.X+dx,start.Y+dy)})
 service.UserInputService.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=start})
 assert(window.SizeX==width and window.SizeY==height and main.Position.X.Offset==x and main.Position.Y.Offset==y,"minimum sizes and top boundary preserve the opposite anchor")
end
limitsCase("NW",1000,1000,160,100,340,300)
limitsCase("SE",-1000,-1000,160,100,100,100)
limitsCase("N",0,-1000,400,400,100,0)
local calls,latest=0,nil local job=Lib.FrameTask(function(value) calls+=1 latest=value end)
for i=1,1000 do job:Push(i) end service.RunService.RenderStepped:Fire()
assert(calls==1 and latest==1000,"shared jobs coalesce high-frequency work")
assert(activeFrameJobs==0,"idle frame work disconnects immediately")
job:Push(1001) job:Flush() service.RunService.RenderStepped:Fire() assert(calls==2 and latest==1001)
job:Push(1002) job:Cancel() service.RunService.RenderStepped:Fire() assert(calls==2) assert(activeFrameJobs==0,"cancel releases frame subscription")
local reentrant
reentrant=Lib.FrameTask(function(value) if value==1 then reentrant:Push(2) else latest=value end end)
reentrant:Push(1) service.RunService.RenderStepped:Fire() service.RunService.RenderStepped:Fire() assert(latest==2,"reentrant scheduling preserves next-frame work") assert(activeFrameJobs==0)
local side={Width=300,Windows={}} local other={Width=300,Windows={}}
local leftSide,rightSide=side,other local static={FreeWidth=100,MinWidth=200}
local sidesGui=Instance.new("Frame") sidesGui.Size=UDim2.fromOffset(1200,800)
local theme={MainColor2=Color3.new(1,1,1),Button=Color3.new()}
local sideUpdates=0 local frameUpdates=0
local function updateSideFrames(noTween) assert(noTween,"dragging must not restart side tweens") frameUpdates+=1 end
local function sideResized(current)
 sideUpdates+=1
 local y=0 for _,window in ipairs(current.Windows) do window.GuiElems.Main.Size=UDim2.fromOffset(current.Width,window.SizeY) window.GuiElems.Main.Position=UDim2.fromOffset(0,y) y+=window.SizeY+4 end
end
'''+dock+r'''
local resizer=Instance.new("Frame",sidesGui) resizer.Position=UDim2.fromOffset(300,0)
Main.Mouse.X=302 Main.Mouse.Y=2
sideResizerHook(resizer,"H",side)
resizer.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=Vector2.new(302,2)})
resizer.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseMovement})
assert(resizer.BackgroundColor3==theme.MainColor2,"leaving the moving divider keeps its active drag highlight")
for i=1,500 do service.UserInputService.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=Vector2.new(302+i*.1,2)}) end
assert(frameUpdates==0 and sideUpdates==0)
service.UserInputService.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=Vector2.new(352,2)})
assert(frameUpdates==1 and sideUpdates==2 and side.Width==350,"docked width release is exact and updates both sides once")
local divider=Instance.new("Frame",sidesGui) divider.Position=UDim2.fromOffset(0,300)
side.Windows={{SizeY=300,MinY=100,GuiElems={Main=Instance.new("Frame")}},{SizeY=300,MinY=100,GuiElems={Main=Instance.new("Frame")}}}
Main.Mouse.X=2 Main.Mouse.Y=302
sideResizerHook(divider,"V",side,1)
divider.InputBegan:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=Vector2.new(2,302)})
service.UserInputService.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseMovement,Position=Vector2.new(2,352)})
service.RunService.RenderStepped:Fire()
assert(side.Windows[1].SizeY==350 and side.Windows[2].SizeY==250,"docked divider preserves redistribution")
service.UserInputService.InputEnded:Fire({UserInputType=Enum.UserInputType.MouseButton1,Position=Vector2.new(2,352)})
job:Push(1003) Main.Shutdown() service.RunService.RenderStepped:Fire() assert(calls==2,"shutdown clears pending frame work")
assert(#warnings==0,table.concat(warnings,"\n"))
print("PASS: eight floating resize directions, touch, 1000-to-one frame updates, final release, dock width/divider, no drag tweens and cleanup")
'''
program+=lib[lib.index('\t\tlocal function updateSideSeams('):lib.index('\n\t\tlocal function renderSide(')]+r'''
do
 local rail=Instance.new("Frame") rail.Size=UDim2.fromOffset(5,600)
 local line=Instance.new("Frame",rail) line.Name="Line" line.Position=UDim2.fromOffset(4,0) line.BackgroundColor3=Color3.fromRGB(36,36,36)
 local upper=Instance.new("Frame") upper.Position=UDim2.fromOffset(0,0) upper.Size=UDim2.fromOffset(340,250)
 local lower=Instance.new("Frame") lower.Position=UDim2.fromOffset(0,254) lower.Size=UDim2.fromOffset(340,346)
 local side={Frame={Resizer=rail},Windows={{GuiElems={Main=upper}},{GuiElems={Main=lower}}}}
 updateSideSeams(side)
 assert(not line.Visible and #side.SeamSegments==2,"shared rail replaces continuous edge with retained segments")
 local first,last=side.SeamSegments[1],side.SeamSegments[2]
 assert(first.Position.Y.Offset==0 and first.Size.Y.Offset==250 and last.Position.Y.Offset==254 and last.Size.Y.Offset==346,"no interior border across the four-pixel divider junction")
 assert(first.Position.X.Offset==4 and last.Position.X.Offset==4,"right sidebar keeps its outside edge")
 upper.Size=UDim2.fromOffset(340,300) lower.Position=UDim2.fromOffset(0,304) updateSideSeams(side)
 assert(side.SeamSegments[1]==first and first.Size.Y.Offset==300 and last.Position.Y.Offset==304,"drag updates geometry without reallocating seam frames")
 side.Windows[1].SizeY=330 side.Windows[2].SizeY=266
 updateSideSeams(side,true)
 assert(first.Size.Y.Offset==330 and last.Position.Y.Offset==334,"T-junctions use the current drag geometry even when GUI layout notifications lag")
 line.Position=UDim2.fromOffset(0,0) updateSideSeams(side) assert(first.Position.X.Offset==0,"left sidebar uses the same seam logic")
 side.Windows={side.Windows[1]} updateSideSeams(side)
 assert(line.Visible and not first.Visible and not last.Visible,"removing the split restores the complete rail")
 side.Windows={} updateSideSeams(side) assert(line.Visible,"empty sidebar retains its normal rail")
end
print("PASS: open sidebar T-junctions, left/right edge ownership, resize reuse and split removal")
'''
program+='\ndo\nlocal function getSideFramePos() return UDim2.new(1,-420,0,0) end\n'+lib[lib.index('\t\tlocal function sideResized('):lib.index('\n\t\tlocal function sideResizerHook(')]+r'''
local divider=Instance.new("Frame") divider.Position=UDim2.fromOffset(-300,200)
local side={Width=420,Dividers={divider},Windows={{SizeY=310,GuiElems={Main=Instance.new("Frame")}},{SizeY=286,GuiElems={Main=Instance.new("Frame")}}}}
local applied=0
side.Windows[2].OnResizeApplied=function(window)
 assert(window.GuiElems.Main.Size==UDim2.fromOffset(420,286),"resize callback sees current geometry")
 applied+=1
end
local synced=false
side.UpdateSeams=function(logical) synced=logical and side.LayoutApplying and divider.Position.X.Offset==-420 and divider.Position.Y.Offset==310 end
sideResized(side)
assert(synced and not side.LayoutApplying,"horizontal divider and vertical seam synchronize without waiting for property-change callbacks")
assert(side.Windows[2].GuiElems.Main.Position.Y.Offset==314,"panels share the same divider boundary")
sideResized(side)
assert(applied==1,"unchanged side geometry does not repeat panel resize callbacks")
end
'''
with tempfile.TemporaryDirectory(prefix='dex-resize-') as directory:
 path=Path(directory)/'resize.luau'
 path.write_text(program,encoding='utf-8')
 subprocess.run([args.luau,str(path)],check=True)

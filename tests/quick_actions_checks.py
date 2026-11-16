"""Exercise the production quick-action controller with deterministic Roblox adapters."""
from pathlib import Path
import subprocess, tempfile, argparse
root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--luau',default=str(root/'.tools/bin/luau.exe'));args=parser.parse_args()
source=(root/'src/Apps/Explorer/ExplorerQuickActions.lua').read_text(encoding='utf-8')
prefix=r"""
local function signal()
 local s={callbacks={}}
 function s:Connect(fn) local c={Connected=true} function c:Disconnect() self.Connected=false end self.callbacks[#self.callbacks+1]={c,fn} return c end
 function s:Fire(...) for _,v in ipairs(self.callbacks) do if v[1].Connected then v[2](...) end end end
 return s
end
local function object(class,parent)
 local o={ClassName=class,Parent=parent,Children={},Destroying=signal(),AncestryChanged=signal()}
 function o:IsA(c) return c==self.ClassName or c=="BasePart" and (class=="Seat" or class=="VehicleSeat" or class=="Part") or c=="GuiObject" and class=="Frame" or c=="LayerCollector" and class=="ScreenGui" or c=="BaseScript" and class=="LocalScript" end
 function o:IsDescendantOf(ancestor)
  local p=self.Parent
  while p do if p==ancestor then return true end p=p.Parent end
  return false
 end
 function o:Destroy() self.Destroying:Fire() self.Parent=nil self.Destroyed=true end
 function o:FindFirstChild(name) return self.Children[name] end
 function o:FindFirstChildOfClass(name) return self.Children[name] end
 return o
end
local Enum={ListenerType={Camera="Camera",ObjectPosition="ObjectPosition"},HighlightDepthMode={Occluded="Occluded"}}
local Color3={fromRGB=function(...) return {...} end}
local effects={}
local Instance={new=function(class)
 local item=object(class)
 if class=="Highlight" then effects[#effects+1]=item end
 return item
end}
local deferred={} local task={defer=function(fn) deferred[#deferred+1]=fn end}
local workspace={}
local clicks,touches,prompts={},{},{}
local function fireclickdetector(...) clicks[#clicks+1]=table.pack(...) end
local function firetouchinterest(...) touches[#touches+1]=table.pack(...) end
local function fireproximityprompt(o) prompts[#prompts+1]=o end
local controller=(function()
"""
suffix=r"""
end)()
local cleanup={} local Main={AddCleanup=function(fn) cleanup[#cleanup+1]=fn end}
local c=object("Model",workspace) local h=object("Humanoid") c.Children.Humanoid=h
local root=object("Part",c) c.Children.HumanoidRootPart=root
local backpack=object("Backpack")
local players={}
local plr=object("Player",players) plr.Character=c plr.Children.Backpack=backpack plr.CharacterRemoving=signal()
function h:EquipTool(tool) tool.Parent=c end
function h:MoveTo(p) self.Walked=p end
local animator=object("Animator") h.Children.Animator=animator
function animator:LoadAnimation(a)
 local t={IsPlaying=false,Stopped=signal()}
 function t:Play() self.IsPlaying=true end
 function t:Stop() self.IsPlaying=false self.Stopped:Fire() end
 function t:Destroy() self.Destroyed=true end
 self.Last=t return t
end
local sound={kind="Camera"}
plr.CharacterAdded=signal()
function players:GetPlayerFromCharacter(model) if plr.Character==model then return plr end end
function sound:GetListener() return self.kind,self.target end
function sound:SetListener(k,t) self.kind=k self.target=t end
local history={Run=function(_,fn) fn() end,Set=function(o,k,v) o[k]=v end}
local Apps={History=history,Explorer={HasInferredSelection=function() return false end,HasReconstructedSelection=function() return false end}}
controller.InitDeps({Main=Main,Apps=Apps,env={},service={SoundService=sound,Players=players,Workspace=workspace},plr=plr})
local actions=controller.Main()
local selection={List={}}
local context={Registered={},Added={}}
function context:Register(id,data) self.Registered[id]=data end
function context:AddRegistered(id,disabled) self.Added[id]={Name=self.Registered[id].Name,Disabled=disabled} end
actions.Register(context,selection)
local function select(...) selection.List={} context.Added={} for _,o in ipairs({...}) do selection.List[#selection.List+1]={Obj=o} end actions.Add(context,selection) end
local function click(id) context.Registered[id].OnClick() end
local seat=object("Seat") function seat:Sit(who) self.Occupant=who end seat.Position=42
select(seat) click("SIT_HERE") assert(seat.Occupant==h) click("WALK_TO") assert(h.Walked==42)
local tool=object("Tool",backpack) tool.CanBeDropped=true function tool:Activate() self.Activated=true end
select(tool) assert(context.Added.EQUIP_TOOL.Name=="Equip") click("EQUIP_TOOL") select(tool) assert(context.Added.EQUIP_TOOL.Name=="Unequip") click("ACTIVATE_TOOL") assert(tool.Activated) click("EQUIP_TOOL") assert(tool.Parent==backpack) click("DROP_TOOL") assert(tool.Parent==workspace)
local gui=object("Frame") gui.Visible=true select(gui) assert(context.Added.TOGGLE_VISIBILITY.Name=="Hide") click("TOGGLE_VISIBILITY") select(gui) assert(not gui.Visible and context.Added.TOGGLE_VISIBILITY.Name=="Show") click("TOGGLE_VISIBILITY") assert(gui.Visible)
local script=object("LocalScript") script.Disabled=false select(script) assert(context.Added.TOGGLE_ENABLED.Name=="Disable") click("TOGGLE_ENABLED") assert(script.Disabled) select(script) click("TOGGLE_ENABLED") assert(not script.Disabled)
local anim=object("Animation") select(anim) click("LOAD_ANIMATION") local track=animator.Last select(anim) assert(context.Added.LOAD_ANIMATION.Name=="Stop Playing on My Character") click("LOAD_ANIMATION") assert(track.Destroyed and not track.IsPlaying)
local other=object("Player") other.Character=c other.CharacterRemoving=signal() other.AncestryChanged=signal()
select(other) click("LISTEN_PLAYER") assert(sound.target==root) select(other) assert(context.Added.LISTEN_PLAYER.Name=="Stop Listening To") other.CharacterRemoving:Fire() assert(sound.kind=="Camera")
local detector=object("ClickDetector") select(detector) click("FIRE_CLICKDETECTOR") click("RIGHT_CLICKDETECTOR") assert(clicks[1][3]=="MouseClick" and clicks[2][3]=="RightMouseClick")
local prompt=object("ProximityPrompt") select(prompt) click("FIRE_PROXIMITYPROMPT") assert(prompts[1]==prompt)
local touch=object("TouchTransmitter",root) select(touch) click("FIRE_TOUCHTRANSMITTER") assert(touches[1][3]==0 and #touches==1) deferred[1]() assert(touches[2][3]==1)
local prop=object("Part",workspace)
select(prop) assert(context.Added.TOGGLE_HIGHLIGHT.Name=="Highlight") click("TOGGLE_HIGHLIGHT")
local effect=effects[#effects] local ownedRoot=effect.Parent
assert(effect.Adornee==prop and effect.DepthMode=="Occluded" and not effect.Archivable)
assert(ownedRoot.Parent==workspace and Main.SelectionGeometryRoots[ownedRoot])
select(prop) assert(context.Added.TOGGLE_HIGHLIGHT.Name=="Remove Highlight") click("TOGGLE_HIGHLIGHT")
assert(effect.Destroyed and ownedRoot.Destroyed and not Main.SelectionGeometryRoots[ownedRoot])
select(plr,c) local before=#effects click("TOGGLE_HIGHLIGHT")
assert(#effects==before+1 and effects[#effects].Adornee==c,"player and character must share one highlight")
local previous=effects[#effects]
plr.CharacterRemoving:Fire(c)
assert(previous.Destroyed)
plr.Character=nil
select(plr) assert(context.Added.TOGGLE_HIGHLIGHT.Name=="Remove Highlight","toggle disappears while awaiting respawn")
local replacement=object("Model",workspace)
plr.Character=replacement plr.CharacterAdded:Fire(replacement)
local respawned=effects[#effects]
assert(respawned.Adornee==replacement and not respawned.Destroyed)
plr.CharacterRemoving:Fire(c) plr.CharacterAdded:Fire(c)
assert(effects[#effects]==respawned and not respawned.Destroyed,"late character events changed the replacement highlight")
select(replacement) click("TOGGLE_HIGHLIGHT") assert(respawned.Destroyed)
plr.CharacterAdded:Fire(c) assert(effects[#effects]==respawned,"removed action kept its respawn listener")
plr.Character=c
select(prop,plr) click("TOGGLE_HIGHLIGHT")
local playerVisual=effects[#effects] local propVisual=effects[#effects-1]
prop.Parent=nil prop.AncestryChanged:Fire(prop,nil)
assert(propVisual.Destroyed and not playerVisual.Destroyed)
plr.Parent=nil plr.AncestryChanged:Fire(plr,nil)
assert(playerVisual.Destroyed,"leaving the game left a character highlight")
prop.Parent=workspace
select(prop) click("TOGGLE_HIGHLIGHT") local teardown=effects[#effects]
select(anim) click("LOAD_ANIMATION") track=animator.Last
select(other) click("LISTEN_PLAYER") for _,fn in ipairs(cleanup) do fn() end assert(track.Destroyed and sound.kind=="Camera" and teardown.Destroyed)
print("PASS: quick-action eligibility, equip/unequip/drop, visibility and enabled toggles, animation ownership, listener restoration, highlight toggling/respawn/cleanup, click buttons, prompt and touch release")
"""
with tempfile.TemporaryDirectory(prefix='dex-quick-actions-') as temp:
 harness=Path(temp)/'check.luau';harness.write_text(prefix+source+suffix,encoding='utf-8');subprocess.run([args.luau,str(harness)],check=True)

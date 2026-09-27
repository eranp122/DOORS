-- ==========================================
-- DOORS · zmV5悬浮窗版
-- 已去除所有作者信息
-- ==========================================
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local RS=game:GetService("ReplicatedStorage")
local CoreGui=game:GetService("CoreGui")
local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")
local LP=Players.LocalPlayer
local PG=LP:WaitForChild("PlayerGui")

if PG:FindFirstChild("DoorsGui")then PG.DoorsGui:Destroy()end

-- 状态
local desiredWalkSpeed=16
local interactRange=15
local flySpeed=50
local ladderSpeedValue=20
local healthValue=100
local loops={}
local espConnections={}
local uiCreated=false

-- ============ 工具函数 ============
local function Notify(msg,dur)
dur=dur or 3
game:GetService("StarterGui"):SetCore("SendNotification",{Title="DOORS",Text=msg,Duration=dur})
end

local function toggleLoop(name,active,func)
if loops[name]then loops[name]:Disconnect()loops[name]=nil end
if active then loops[name]=RunService.Heartbeat:Connect(func)end
end

local function clearESPGroup(name)
if espConnections[name]then
for _,v in ipairs(espConnections[name])do
pcall(function()
if typeof(v)=="RBXScriptConnection"then v:Disconnect()
elseif v:IsA("Highlight")then v:Destroy()end
end)
end
espConnections[name]=nil
end
end

local function enableESP(name,filterFunc,fillColor,outlineColor)
clearESPGroup(name)
local group={}
local HighlightColor=fillColor or Color3.fromRGB(255,255,255)
local OutlineColor=outlineColor or HighlightColor
local function add(obj)
if not filterFunc(obj)then return end
local h=Instance.new("Highlight")
h.Adornee=obj
h.FillColor=HighlightColor
h.OutlineColor=OutlineColor
h.FillTransparency=0.5
h.Parent=obj
table.insert(group,h)
end
for _,o in ipairs(Workspace:GetDescendants())do add(o)end
local conn=Workspace.DescendantAdded:Connect(add)
table.insert(group,conn)
espConnections[name]=group
end

local function disableESP(name)
clearESPGroup(name)
end

local function safeFireProximityPrompt(prompt)
pcall(function()if fireproximityprompt then fireproximityprompt(prompt)end end)
end

local function tp(pos)
local char=LP.Character
if not char then return end
if typeof(pos)=="CFrame"then char:SetPrimaryPartCFrame(pos)
elseif typeof(pos)=="Vector3"then char:MoveTo(pos)end
end

-- ============ 物品名单 ============
local doorNames={["Door"]=true}
local objectiveItems={["KeyObtain"]=true,["FuseObtain"]=true,["LiveBreakerPolePickup"]=true}
local coinNames={["GoldPile"]=true}
local genNames={["MinesGenerator"]=true}
local leverNames={["LeverForGate"]=true}
local itemNames={
AlarmClock=true,Aloe=true,BandagePack=true,Battery=true,BatteryPack=true,
Candle=true,Compass=true,Crucifix=true,Flashlight=true,Glowstick=true,
HolyHandGrenade=true,Lantern=true,LaserPointer=true,Lighter=true,
Lockpick=true,LotusFlower=true,Multitool=true,NVCS3000=true,
Shears=true,SkeletonKey=true,Smoothie=true,Vitamins=true
}
local closetNames={Wardrobe=true,Toolshed=true,Locker_Large=true,Backdoor_Wardrobe=true}
local anchorNames={MinesAnchor=true}
local bookNames={LiveHintBook=true}
local chestNames={ChestBox=true,ChestBoxLocked=true}

-- ============ 规避函数 ============
local function avoidScreech(enabled)
if enabled then
Workspace.DescendantAdded:Connect(function(x)if x.Name=="Screech"then x:Destroy()end end)
end
end

local function avoidGloom(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="GloomEgg"then
local egg=v:FindFirstChild("Egg")
if egg then egg.CanTouch=not enabled end
end
end
end

local function avoidDread(enabled)
local mod=LP.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules:FindFirstChild("Dread")or LP.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules:FindFirstChild("_Dread")
if mod then mod.Name=enabled and "_Dread"or "Dread"end
end

local function avoidGiggle(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="GiggleCeiling"then
local hit=v:FindFirstChild("Hitbox")
if hit then hit.CanTouch=not enabled end
end
end
end

local function avoidFigureHearing(enabled)
if enabled then
RunService.Heartbeat:Connect(function()
pcall(function()
RS.RemotesFolder.Crouch:FireServer(true)
end)
end)
else
pcall(function()
RS.RemotesFolder.Crouch:FireServer(false)
end)
end
end

local function avoidSurge(enabled)
if enabled then
local surge=RS.FloorReplicated.ClientRemote:FindFirstChild("SurgeClient")
if surge then surge:Destroy()end
end
end

local function avoidHalt(enabled)
local mod=RS.ModulesClient.EntityModules:FindFirstChild("Shade")or RS.ModulesClient.EntityModules:FindFirstChild("_Shade")
if mod then mod.Name=enabled and "_Shade"or "Shade"end
end

local function avoidLookman(enabled)
if enabled then
pcall(function()
RS.RemotesFolder.MotorReplication:FireServer(-890)
end)
end
end

local function avoidSnare(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="Snare"then
local hit=v:FindFirstChild("Hitbox")
if hit then hit.CanTouch=not enabled end
end
end
end

local function avoidSeekObstacles(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="Seek_Arm"then
if v:FindFirstChild("AnimatorPart")then
v.AnimatorPart.CanTouch=not enabled
end
elseif v.Name=="ChandelierObstruction"then
if v:FindFirstChild("HurtPart")then
v.HurtPart.CanTouch=not enabled
end
end
end
end

local function avoidDupeDoors(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="DoorFake"then
if v:FindFirstChild("Hidden")then
v.Hidden.CanTouch=not enabled
end
end
end
end

local function avoidVoidArea(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="SideroomSpace"then
for _,p in ipairs(v:GetChildren())do
if p:IsA("BasePart")then
p.CanTouch=not enabled
p.CanCollide=enabled
end
end
end
end
end

local function avoidEyes(enabled)
if enabled then
RunService.RenderStepped:Connect(function()
if not LP.Character:GetAttribute("Hiding")then
for _,e in ipairs(Workspace:GetChildren())do
if e.Name=="Eyes"and e.Core.Ambience.Playing then
pcall(function()
RS.RemotesFolder.MotorReplication:FireServer(-650)
end)
end
end
end
end)
end
end

local function avoidA90(enabled)
local mod=LP.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules:FindFirstChild("A90")or LP.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener.Modules:FindFirstChild("_A90")
if mod then mod.Name=enabled and "_A90"or "A90"end
end

local function avoidVoidEffect(enabled)
local mod=RS.ModulesClient.EntityModules:FindFirstChild("Void")or RS.ModulesClient.EntityModules:FindFirstChild("_Void")
if mod then mod.Name=enabled and "_Void"or "Void"end
end

local function avoidHaste(enabled)
if enabled then
local haste=RS.FloorReplicated.ClientRemote.Haste
if haste then
haste.Ambience:GetPropertyChangedSignal("Playing"):Connect(function()
if enabled then haste.Ambience.Playing=false end
end)
end
end
end

local function avoidFiredamp(enabled)
if enabled then
Workspace.Camera.ChildAdded:Connect(function(x)
if x.Name=="LiveSantity"or x.Name=="LiveFiredamp"then x:Destroy()end
end)
end
end

local function avoidMineAtmosphere(enabled)
if enabled then
local cave=Lighting:FindFirstChild("CaveAtmosphere")
if cave then cave:Destroy()end
local caves=Lighting:FindFirstChild("Caves")
if caves then caves:Destroy()end
end
end

local function avoidOxygenSanity(enabled)
if enabled then
local sanity=Lighting:FindFirstChild("Sanity")
if sanity then sanity:Destroy()end
local oxyCC=Lighting:FindFirstChild("OxygenCC")
if oxyCC then oxyCC:Destroy()end
local oxyBlur=Lighting:FindFirstChild("OxygenBlur")
if oxyBlur then oxyBlur:Destroy()end
end
end

local function setNoFog(enabled)
if enabled then
Lighting.FogStart=1000000
Lighting.FogEnd=1000000
else
Lighting.FogStart=150
Lighting.FogEnd=150
end
end

local function setNoShake(enabled)
local req=require(LP.PlayerGui.MainUI.Initiator.Main_Game)
if enabled then
task.spawn(function()
while enabled do
task.wait()
req.csgo=CFrame.new()
end
end)
end
end

local function setNoHeadBob(enabled)
local req=require(LP.PlayerGui.MainUI.Initiator.Main_Game)
if enabled then
_G.HeadBobConn=RunService.RenderStepped:Connect(function()
if req and req.spring then
req.spring.Target=Vector3.zero
req.spring.Position=Vector3.zero
end
end)
else
if _G.HeadBobConn then _G.HeadBobConn:Disconnect()_G.HeadBobConn=nil end
end
end

local function setNoCutscenes(enabled)
local rl=LP.PlayerGui.MainUI.Initiator.Main_Game.RemoteListener
local cs=rl:FindFirstChild("Cutscenes")or rl:FindFirstChild("_Cutscenes")
if cs then cs.Name=enabled and "_Cutscenes"or "Cutscenes"end
end

local function removeHideVignette(enabled)
LP.PlayerGui.MainUI.MainFrame.HideVignette.Image=enabled and "rbxassetid://0"or "rbxassetid://6100076320"
end

local function antiJam(enabled)
local st=game.SoundService:FindFirstChild("Main")
if st then
local jam=st:FindFirstChild("Jamming")
if jam then jam.Enabled=not enabled end
end
end

local function antiBanana(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="BananaPeel"then v.CanTouch=not enabled end
end
end

local function antiJeff(enabled)
for _,v in ipairs(Workspace.CurrentRooms:GetDescendants())do
if v.Name=="JeffTheKiller"then
for _,p in ipairs(v:GetChildren())do
if p:IsA("BasePart")then p.CanTouch=not enabled end
end
end
end
end

-- ============ 飞行脚本 ============
local function loadFlightScript()
pcall(function()
local main=Instance.new("ScreenGui",CoreGui)
main.Name="FlightGui_"..tostring(math.random())
main.ResetOnSpawn=false
local Frame=Instance.new("Frame",main)
Frame.BackgroundColor3=Color3.fromRGB(163,255,137)
Frame.BorderColor3=Color3.fromRGB(103,221,213)
Frame.Position=UDim2.new(0.1,0,0.38,0)
Frame.Size=UDim2.new(0,190,0,57)
local function makeBtn(text,size,pos,bg)
local btn=Instance.new("TextButton",Frame)
btn.BackgroundColor3=bg
btn.Size=size
btn.Position=pos
btn.Font=Enum.Font.SourceSans
btn.Text=text
btn.TextColor3=Color3.new(0,0,0)
btn.TextSize=14
return btn
end
local up=makeBtn("上升",UDim2.new(0,44,0,28),UDim2.new(0,0,0,0),Color3.fromRGB(79,255,152))
local down=makeBtn("下落",UDim2.new(0,44,0,28),UDim2.new(0,0,0.5,0),Color3.fromRGB(215,255,121))
local onof=makeBtn("飞",UDim2.new(0,56,0,28),UDim2.new(0.7,0,0.5,0),Color3.fromRGB(255,249,74))
local TextLabel=Instance.new("TextLabel",Frame)
TextLabel.BackgroundColor3=Color3.fromRGB(242,60,255)
TextLabel.Position=UDim2.new(0.5,0,0,0)
TextLabel.Size=UDim2.new(0,100,0,28)
TextLabel.Font=Enum.Font.SourceSans
TextLabel.Text="飞行控制"
TextLabel.TextColor3=Color3.new(0,0,0)
TextLabel.TextScaled=true
TextLabel.TextSize=14
local plus=makeBtn("+",UDim2.new(0,45,0,28),UDim2.new(0.23,0,0,0),Color3.fromRGB(133,145,255))
local speed=Instance.new("TextLabel",Frame)
speed.BackgroundColor3=Color3.fromRGB(255,85,0)
speed.Position=UDim2.new(0.47,0,0.5,0)
speed.Size=UDim2.new(0,44,0,28)
speed.Font=Enum.Font.SourceSans
speed.Text="1"
speed.TextColor3=Color3.new(0,0,0)
speed.TextScaled=true
speed.TextSize=14
local mine=makeBtn("-",UDim2.new(0,45,0,29),UDim2.new(0.23,0,0.5,0),Color3.fromRGB(123,255,247))
local closeBtn=makeBtn("X",UDim2.new(0,45,0,28),UDim2.new(0,0,-1,27),Color3.fromRGB(225,25,0))
closeBtn.TextSize=30
closeBtn.Font=Enum.Font.ArialBold
local mini=makeBtn("-",UDim2.new(0,45,0,28),UDim2.new(0,44,-1,27),Color3.fromRGB(192,150,230))
mini.TextSize=40
local mini2=makeBtn("+",UDim2.new(0,45,0,28),UDim2.new(0,44,0,30),Color3.fromRGB(192,150,230))
mini2.TextSize=40
mini2.Visible=false
local speeds=1
local nowe=false
local chr=LP.Character
local hum=chr and chr:FindFirstChildOfClass("Humanoid")
Frame.Active=true
Frame.Draggable=true
closeBtn.MouseButton1Click:Connect(function()main:Destroy()end)
up.MouseButton1Click:Connect(function()
if chr and chr:FindFirstChild("HumanoidRootPart")then
chr.HumanoidRootPart.CFrame=chr.HumanoidRootPart.CFrame+Vector3.new(0,3,0)
end
end)
down.MouseButton1Click:Connect(function()
if chr and chr:FindFirstChild("HumanoidRootPart")then
chr.HumanoidRootPart.CFrame=chr.HumanoidRootPart.CFrame+Vector3.new(0,-3,0)
end
end)
mini.MouseButton1Click:Connect(function()
up.Visible=false
down.Visible=false
onof.Visible=false
plus.Visible=false
speed.Visible=false
mine.Visible=false
closeBtn.Visible=false
mini.Visible=false
mini2.Visible=true
Frame.Size=UDim2.new(0,100,0,28)
TextLabel.Position=UDim2.new(0,0,0,0)
end)
mini2.MouseButton1Click:Connect(function()
up.Visible=true
down.Visible=true
onof.Visible=true
plus.Visible=true
speed.Visible=true
mine.Visible=true
closeBtn.Visible=true
mini.Visible=true
mini2.Visible=false
Frame.Size=UDim2.new(0,190,0,57)
TextLabel.Position=UDim2.new(0.47,0,0,0)
end)
plus.MouseButton1Click:Connect(function()
speeds=speeds+1
speed.Text=tostring(speeds)
end)
mine.MouseButton1Click:Connect(function()
if speeds>1 then
speeds=speeds-1
speed.Text=tostring(speeds)
else
speed.Text="错误"
task.wait(0.2)
speed.Text="1"
end
end)
LP.CharacterAdded:Connect(function(c)
chr=c
hum=c:FindFirstChildOfClass("Humanoid")
end)
onof.MouseButton1Click:Connect(function()
nowe=not nowe
if nowe then
if hum then
for _,s in pairs(Enum.HumanoidStateType:GetEnumItems())do
hum:SetStateEnabled(s,false)
end
hum:ChangeState(Enum.HumanoidStateType.Swimming)
end
if chr.Animate then chr.Animate.Disabled=true end
if hum then
for _,t in pairs(hum:GetPlayingAnimationTracks())do
t:AdjustSpeed(0)
end
end
task.spawn(function()
while nowe and chr and hum do
RunService.Heartbeat:Wait()
if hum.MoveDirection.Magnitude>0 then
chr:TranslateBy(hum.MoveDirection*speeds)
end
end
end)
local root=hum.RigType==Enum.HumanoidRigType.R6 and chr.Torso or chr.UpperTorso
local bg=Instance.new("BodyGyro",root)
bg.P=9e4
bg.MaxTorque=Vector3.new(9e9,9e9,9e9)
bg.CFrame=root.CFrame
local bv=Instance.new("BodyVelocity",root)
bv.Velocity=Vector3.new(0,0,0)
bv.MaxForce=Vector3.new(9e9,9e9,9e9)
if nowe then chr.Humanoid.PlatformStand=true end
while nowe and chr.Humanoid.Health>0 do
RunService.RenderStepped:Wait()
bg.CFrame=workspace.CurrentCamera.CoordinateFrame
end
bg:Destroy()
bv:Destroy()
chr.Humanoid.PlatformStand=false
chr.Animate.Disabled=false
else
if hum then
for _,s in pairs(Enum.HumanoidStateType:GetEnumItems())do
hum:SetStateEnabled(s,true)
end
hum:ChangeState(Enum.HumanoidStateType.Running)
end
if chr.Animate then chr.Animate.Disabled=false end
end
end)
Notify("飞行脚本已加载")
end)
end

-- ============ 其他工具 ============
local noclipConn
local function toggleNoclip(enabled)
if enabled then
noclipConn=RunService.Stepped:Connect(function()
local char=LP.Character
if char then
for _,p in ipairs(char:GetDescendants())do
if p:IsA("BasePart")then p.CanCollide=false end
end
end
end)
else
if noclipConn then noclipConn:Disconnect()noclipConn=nil end
end
end

local ladderConn
local function toggleFastLadder(enabled)
if enabled then
ladderConn=RunService.Heartbeat:Connect(function()
local char=LP.Character
local hum=char and char:FindFirstChildOfClass("Humanoid")
local hrp=char and char:FindFirstChild("HumanoidRootPart")
if hum and hrp and hum:GetState()==Enum.HumanoidStateType.Climbing then
hrp.Velocity=Vector3.new(hrp.Velocity.X,ladderSpeedValue,hrp.Velocity.Z)
end
end)
else
if ladderConn then ladderConn:Disconnect()ladderConn=nil end
end
end

local function toggleAlwaysJump(enabled)
local function apply(c)
if c then c:SetAttribute("CanJump",enabled)end
end
apply(LP.Character)
LP.CharacterAdded:Connect(function(c)task.wait(1.5)apply(c)end)
end

local function toggleHeadLight(enabled)
local head=LP.Character and LP.Character:FindFirstChild("Head")
if enabled then
if head and not head:FindFirstChild("bai")then
local light=Instance.new("PointLight")
light.Name="bai"
light.Range=150
light.Brightness=1.7
light.Parent=head
end
else
if head then
local light=head:FindFirstChild("bai")
if light then light:Destroy()end
end
end
end

local function getCrucifix()
pcall(function()
local tool=game:GetObjects("rbxassetid://11498423088")[1]
tool.Parent=LP.Backpack
Notify("十字架已添加")
end)
end

local healthConn
local function toggleHealthLock(enabled)
if enabled then
healthConn=RunService.Heartbeat:Connect(function()
local char=LP.Character
if char and char:FindFirstChildOfClass("Humanoid")then
char:FindFirstChildOfClass("Humanoid").Health=healthValue
end
end)
else
if healthConn then healthConn:Disconnect()healthConn=nil end
end
end

local function disableAntiCheat()
local lp=LP
if lp:GetAttribute("CurrentRoom")==0 then
if replicatesignal then pcall(function()replicatesignal(lp.Kill)end)end
Notify("反作弊已尝试禁用")
else
Notify("请在电梯中使用")
end
end

local function autoInteractLoop()
local char=LP.Character
if not char then return end
local root=char:FindFirstChild("HumanoidRootPart")
if not root then return end
for _,prompt in ipairs(Workspace:GetDescendants())do
if prompt:IsA("ProximityPrompt")and prompt.Enabled then
local part=prompt.Parent
if part and part:IsA("BasePart")and(root.Position-part.Position).Magnitude<10 then
safeFireProximityPrompt(prompt)
end
end
end
end

local function autoOpenDoorsLoop()
local char=LP.Character
if not char then return end
local root=char:FindFirstChild("HumanoidRootPart")
if not root then return end
for _,door in ipairs(Workspace.CurrentRooms:GetChildren())do
local doorModel=door:FindFirstChild("Door")
if doorModel and door:FindFirstChild("ClientOpen")then
pcall(function()door.ClientOpen:FireServer()end)
end
end
end

local function autoBreakDoorLoop()
for _,part in ipairs(Workspace.CurrentRooms:GetDescendants())do
if part.Name=="DoorPieceBottom"or part.Name=="DoorPieceTop"then
for _,prompt in ipairs(part:GetDescendants())do
if prompt:IsA("ProximityPrompt")and prompt.Enabled then
safeFireProximityPrompt(prompt)
end
end
end
end
end

local function autoPickupDropsLoop()
local drops=Workspace:FindFirstChild("Drops")
if drops then
for _,model in ipairs(drops:GetChildren())do
for _,prompt in ipairs(model:GetDescendants())do
if prompt:IsA("ProximityPrompt")and prompt.Enabled then
safeFireProximityPrompt(prompt)
end
end
end
end
end

local function autoMinecartLoop()
for _,obj in ipairs(Workspace.CurrentRooms:GetDescendants())do
if obj.Name=="MinecartMoving"then
local prompt=obj:FindFirstChild("PushPrompt",true)
if prompt then safeFireProximityPrompt(prompt)end
end
end
end

local function autoThrowablesLoop()
local targets={"WoodenCrate","OilBarrel","GarbageBag","Trashcan","CardboardBox_Normal","Hat_Stand","CardboardBox_Wide","Office_Chair"}
local bigProps=Workspace:FindFirstChild("BigProps")
if bigProps then
for _,name in ipairs(targets)do
local prop=bigProps:FindFirstChild(name)
if prop then
for _,prompt in ipairs(prop:GetDescendants())do
if prompt:IsA("ProximityPrompt")and prompt.Enabled then
safeFireProximityPrompt(prompt)
end
end
end
end
end
end

local autoFireConn
local function toggleAutoFire(enabled)
if enabled then
autoFireConn=RunService.RenderStepped:Connect(function()
local cam=workspace.CurrentCamera
local char=LP.Character
if not char then return end
local look=cam.CFrame.LookVector
local origin=cam.CFrame.Position
local closest,bestDot=nil,0.995
for _,plr in ipairs(Players:GetPlayers())do
if plr~=LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")then
local pos=plr.Character.HumanoidRootPart.Position
local dir=(pos-origin).Unit
local dot=look:Dot(dir)
if dot>bestDot and(pos-origin).Magnitude<50 then
bestDot=dot
closest=plr
end
end
end
if closest then
pcall(function()mouse1press()end)
else
pcall(function()mouse1release()end)
end
end)
else
if autoFireConn then autoFireConn:Disconnect()autoFireConn=nil end
pcall(function()mouse1release()end)
end
end

local function autoRoomsLoop()
local gameData=RS:WaitForChild("GameData")
if gameData.Floor.Value~="Rooms"or gameData.LatestRoom.Value>=1000 then return end
local char=LP.Character
if not char then return end
local hrp=char:FindFirstChild("HumanoidRootPart")
if not hrp then return end
local entity=Workspace:FindFirstChild("A60")or Workspace:FindFirstChild("A120")
if entity and entity.PrimaryPart then
local best,bestDist=nil,math.huge
for _,obj in ipairs(Workspace.CurrentRooms:GetDescendants())do
if obj.Name=="Rooms_Locker"or obj.Name=="Rooms_Locker_Fridge"then
if obj.PrimaryPart then
local d=(hrp.Position-obj.PrimaryPart.Position).Magnitude
if d<bestDist then best,bestDist=obj,d end
end
end
end
if best then
local hum=char:FindFirstChildOfClass("Humanoid")
if hum then hum:MoveTo(best.PrimaryPart.Position)end
task.wait(0.5)
local prompt=best:FindFirstChildOfClass("ProximityPrompt")
if prompt then safeFireProximityPrompt(prompt)end
end
else
local currentRoom=Workspace.CurrentRooms[gameData.LatestRoom.Value]
if currentRoom then
local door=currentRoom:FindFirstChild("Door",true)
if door then
local hum=char:FindFirstChildOfClass("Humanoid")
if hum then hum:MoveTo(door.Position)end
end
end
end
end

local function autoHideSetup()
Workspace.ChildAdded:Connect(function(inst)
if inst.Name=="RushMoving"or inst.Name=="AmbushMoving"then
task.wait(0.5)
local char=LP.Character
local hrp=char and char:FindFirstChild("HumanoidRootPart")
if not hrp then return end
local closest,minDist=nil,math.huge
for _,obj in ipairs(Workspace.CurrentRooms:GetDescendants())do
if obj:IsA("Model")and(obj.Name=="Wardrobe"or obj.Name=="Locker_Large")and obj:FindFirstChild("HidePrompt")then
local hiddenPlr=obj:FindFirstChild("HiddenPlayer")
if hiddenPlr and not hiddenPlr.Value then
local part=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
if part then
local dist=(hrp.Position-part.Position).Magnitude
if dist<minDist then
minDist=dist
closest=obj
end
end
end
end
end
if closest then
local hum=char:FindFirstChildOfClass("Humanoid")
if hum then hum:MoveTo(closest.PrimaryPart.Position)end
task.wait(0.3)
safeFireProximityPrompt(closest.HidePrompt)
end
end
end)
end

-- ============ 实体提示名单 ============
local entityNotifyList={
Screech="尖啸者",Halt="暂停实体",FigureRig="雕像",Eyes="眼睛",
SeekMoving="追逐者",RushMoving="冲刺",AmbushMoving="伏击",
A60="A-60",A120="A-120",GiggleCeiling="傻笑",
GrumbleRig="咕噜",GloombatSwarm="暗影蝙蝠",Dread="恐惧",
BackdoorLookman="观察者",Snare="陷阱",WorldLotus="世界莲花",
Bramble="荆棘",Caws="乌鸦",Eyestalk="眼球",
Grampy="爷爷",Groundskeeper="园丁",Mandrake="曼德拉草",
Monument="纪念碑",Surge="浪涌",BackdoorRush="闪电"
}

-- ============ 主 GUI ============
local Gui=Instance.new("ScreenGui")
Gui.Name="DoorsGui"
Gui.ResetOnSpawn=false
Gui.DisplayOrder=999999
Gui.IgnoreGuiInset=true
Gui.Parent=PG

-- 悬浮球
local Orb=Instance.new("TextButton")
Orb.Size=UDim2.new(0,50,0,50)
Orb.Position=UDim2.new(0.5,-25,0,50)
Orb.BackgroundColor3=Color3.fromRGB(255,255,255)
Orb.BackgroundTransparency=0.72
Orb.Text="🚪"
Orb.TextColor3=Color3.fromRGB(255,255,255)
Orb.TextSize=22
Orb.Font=Enum.Font.GothamBold
Orb.BorderSizePixel=0
Orb.AutoButtonColor=false
Orb.Active=true
Orb.ZIndex=999999
Orb.Parent=Gui
Instance.new("UICorner",Orb).CornerRadius=UDim.new(1,0)

local OrbStroke=Instance.new("UIStroke",Orb)
OrbStroke.Thickness=2.5
OrbStroke.Color=Color3.fromRGB(255,180,210)
OrbStroke.Transparency=.15
local OrbSG=Instance.new("UIGradient",OrbStroke)
OrbSG.Color=ColorSequence.new({
ColorSequenceKeypoint.new(0,Color3.fromRGB(255,120,180)),
ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,190,120)),
ColorSequenceKeypoint.new(.5,Color3.fromRGB(120,220,180)),
ColorSequenceKeypoint.new(.75,Color3.fromRGB(120,180,255)),
ColorSequenceKeypoint.new(1,Color3.fromRGB(255,120,180))})
task.spawn(function()
while Orb.Parent do
OrbSG.Offset=Vector2.new(math.sin(tick()*1.5)*0.5,tick()*0.3%1)
task.wait(.03)
end end)

local OG=Instance.new("UIGradient",Orb)
OG.Color=ColorSequence.new({
ColorSequenceKeypoint.new(0,Color3.fromRGB(255,140,190)),
ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,200,140)),
ColorSequenceKeypoint.new(.5,Color3.fromRGB(140,230,190)),
ColorSequenceKeypoint.new(.75,Color3.fromRGB(140,190,255)),
ColorSequenceKeypoint.new(1,Color3.fromRGB(255,140,190))})
OG.Transparency=NumberSequence.new({
NumberSequenceKeypoint.new(0,0.75),
NumberSequenceKeypoint.new(.5,0.55),
NumberSequenceKeypoint.new(1,0.75)})
task.spawn(function()
while Orb.Parent do
OG.Offset=Vector2.new(math.sin(tick()*1.2)*0.4,tick()*0.18%1)
task.wait(.03)
end end)

local OrbHi=Instance.new("Frame")
OrbHi.Size=UDim2.new(0.7,0,0.35,0)
OrbHi.Position=UDim2.new(0.15,0,0.08,0)
OrbHi.BackgroundColor3=Color3.fromRGB(255,255,255)
OrbHi.BackgroundTransparency=0.6
OrbHi.BorderSizePixel=0
OrbHi.ZIndex=3
OrbHi.Parent=Orb
Instance.new("UICorner",OrbHi).CornerRadius=UDim.new(1,0)

local OrbShade=Instance.new("Frame")
OrbShade.Size=UDim2.new(0.85,0,0.5,0)
OrbShade.Position=UDim2.new(0.075,0,0.48,0)
OrbShade.BackgroundColor3=Color3.fromRGB(0,0,0)
OrbShade.BackgroundTransparency=0.88
OrbShade.BorderSizePixel=0
OrbShade.ZIndex=2
OrbShade.Parent=Orb
Instance.new("UICorner",OrbShade).CornerRadius=UDim.new(1,0)

-- 面板
local P=Instance.new("Frame")
P.Size=UDim2.new(0,340,0,260)
P.Position=UDim2.new(.5,0,.5,0)
P.AnchorPoint=Vector2.new(.5,.5)
P.BackgroundColor3=Color3.fromRGB(255,255,255)
P.BackgroundTransparency=0.82
P.BorderSizePixel=0
P.Visible=false
P.ZIndex=999998
P.ClipsDescendants=true
P.Parent=Gui
Instance.new("UICorner",P).CornerRadius=UDim.new(0,20)

local PStroke=Instance.new("UIStroke",P)
PStroke.Thickness=2.2
PStroke.Color=Color3.fromRGB(255,180,210)
PStroke.Transparency=.15
local PSG=Instance.new("UIGradient",PStroke)
PSG.Color=OrbSG.Color
task.spawn(function()
while P.Parent do
PSG.Offset=Vector2.new(math.sin(tick()*1.2)*0.5,tick()*0.25%1)
task.wait(.03)
end end)

local PGrad=Instance.new("UIGradient",P)
PGrad.Color=ColorSequence.new({
ColorSequenceKeypoint.new(0,Color3.fromRGB(255,150,200)),
ColorSequenceKeypoint.new(.25,Color3.fromRGB(255,200,150)),
ColorSequenceKeypoint.new(.5,Color3.fromRGB(150,230,200)),
ColorSequenceKeypoint.new(.75,Color3.fromRGB(150,190,255)),
ColorSequenceKeypoint.new(1,Color3.fromRGB(255,150,200))})
PGrad.Transparency=NumberSequence.new({
NumberSequenceKeypoint.new(0,.9),
NumberSequenceKeypoint.new(.5,.84),
NumberSequenceKeypoint.new(1,.9)})
task.spawn(function()
while P.Parent do
PGrad.Offset=Vector2.new(math.sin(tick()*0.8)*0.4,tick()*0.12%1)
task.wait(.03)
end end)

local TopHi=Instance.new("Frame")
TopHi.Size=UDim2.new(1,-30,0,1)
TopHi.Position=UDim2.new(0,15,0,1)
TopHi.BackgroundColor3=Color3.fromRGB(255,255,255)
TopHi.BackgroundTransparency=0.3
TopHi.BorderSizePixel=0
TopHi.ZIndex=3
TopHi.Parent=P

local BotShade=Instance.new("Frame")
BotShade.Size=UDim2.new(1,-30,0,1)
BotShade.Position=UDim2.new(0,15,1,-2)
BotShade.BackgroundColor3=Color3.fromRGB(0,0,0)
BotShade.BackgroundTransparency=0.75
BotShade.BorderSizePixel=0
BotShade.ZIndex=3
BotShade.Parent=P

local Title=Instance.new("TextLabel")
Title.Size=UDim2.new(1,-16,0,20)
Title.Position=UDim2.new(0,8,0,4)
Title.BackgroundTransparency=1
Title.Text="🚪 DOORS"
Title.TextColor3=Color3.fromRGB(255,255,255)
Title.TextStrokeTransparency=0
Title.TextStrokeColor3=Color3.fromRGB(0,0,0)
Title.TextSize=12
Title.Font=Enum.Font.GothamBold
Title.TextXAlignment=Enum.TextXAlignment.Left
Title.ZIndex=5
Title.Parent=P

-- 左右分栏
local Container=Instance.new("Frame")
Container.Size=UDim2.new(1,-12,1,-30)
Container.Position=UDim2.new(0,6,0,26)
Container.BackgroundTransparency=1
Container.ZIndex=2
Container.Parent=P

local Sidebar=Instance.new("ScrollingFrame")
Sidebar.Size=UDim2.new(0,54,1,0)
Sidebar.BackgroundColor3=Color3.fromRGB(20,20,35)
Sidebar.BackgroundTransparency=0.3
Sidebar.BorderSizePixel=0
Sidebar.ScrollBarThickness=2
Sidebar.ScrollBarImageColor3=Color3.fromRGB(255,255,255)
Sidebar.ScrollBarImageTransparency=.4
Sidebar.AutomaticCanvasSize=Enum.AutomaticSize.Y
Sidebar.CanvasSize=UDim2.new(0,0,0,0)
Sidebar.ZIndex=3
Sidebar.Parent=Container
Instance.new("UICorner",Sidebar).CornerRadius=UDim.new(0,12)

local SideStroke=Instance.new("UIStroke",Sidebar)
SideStroke.Thickness=1.5
SideStroke.Color=Color3.fromRGB(255,180,210)
SideStroke.Transparency=.3

local SideLayout=Instance.new("UIListLayout",Sidebar)
SideLayout.Padding=UDim.new(0,3)
SideLayout.SortOrder=Enum.SortOrder.LayoutOrder
SideLayout.HorizontalAlignment=Enum.HorizontalAlignment.Center

local SidePad=Instance.new("UIPadding",Sidebar)
SidePad.PaddingTop=UDim.new(0,5)
SidePad.PaddingBottom=UDim.new(0,5)

local Content=Instance.new("Frame")
Content.Size=UDim2.new(1,-60,1,0)
Content.Position=UDim2.new(0,60,0,0)
Content.BackgroundTransparency=1
Content.ZIndex=3
Content.Parent=Container

-- 页面系统
local pages={}
local sideButtons={}

local function createPage(key)
local page=Instance.new("ScrollingFrame")
page.Size=UDim2.new(1,0,1,0)
page.BackgroundTransparency=1
page.BorderSizePixel=0
page.ScrollBarThickness=2
page.ScrollBarImageColor3=Color3.fromRGB(255,255,255)
page.ScrollBarImageTransparency=.3
page.AutomaticCanvasSize=Enum.AutomaticSize.Y
page.Visible=false
page.ZIndex=3
page.Parent=Content
local l=Instance.new("UIListLayout",page)
l.Padding=UDim.new(0,4)
l.SortOrder=Enum.SortOrder.LayoutOrder
local p=Instance.new("UIPadding",page)
p.PaddingLeft=UDim.new(0,3)
p.PaddingRight=UDim.new(0,3)
p.PaddingTop=UDim.new(0,3)
p.PaddingBottom=UDim.new(0,6)
pages[key]={page=page,order=0}
end

local function nextOrder(key)
pages[key].order=pages[key].order+1
return pages[key].order
end

local function addCategory(key,label)
local btn=Instance.new("TextButton")
btn.Size=UDim2.new(1,-8,0,24)
btn.BackgroundColor3=Color3.fromRGB(40,40,60)
btn.Text=label
btn.TextColor3=Color3.fromRGB(255,255,255)
btn.TextStrokeTransparency=0.2
btn.TextStrokeColor3=Color3.fromRGB(0,0,0)
btn.TextSize=10
btn.Font=Enum.Font.GothamBold
btn.BorderSizePixel=0
btn.ZIndex=4
btn.Parent=Sidebar
Instance.new("UICorner",btn).CornerRadius=UDim.new(0,9)
local bs=Instance.new("UIStroke",btn)
bs.Thickness=1.2
bs.Color=Color3.fromRGB(255,180,210)
bs.Transparency=.35
btn.MouseButton1Click:Connect(function()
for _,v in pairs(pages)do v.page.Visible=false end
for _,v in pairs(sideButtons)do
v.BackgroundColor3=Color3.fromRGB(40,40,60)
v.TextColor3=Color3.fromRGB(255,255,255)
end
pages[key].page.Visible=true
btn.BackgroundColor3=Color3.fromRGB(255,80,160)
btn.TextColor3=Color3.fromRGB(255,255,255)
end)
sideButtons[key]=btn
end

local function addLabel(key,text)
local l=Instance.new("TextLabel")
l.Size=UDim2.new(1,0,0,18)
l.BackgroundColor3=Color3.fromRGB(40,40,60)
l.Text="  "..text
l.TextColor3=Color3.fromRGB(255,240,120)
l.TextStrokeTransparency=0.3
l.TextStrokeColor3=Color3.fromRGB(0,0,0)
l.TextSize=10
l.Font=Enum.Font.GothamBold
l.TextXAlignment=Enum.TextXAlignment.Left
l.LayoutOrder=nextOrder(key)
l.ZIndex=4
l.Parent=pages[key].page
Instance.new("UICorner",l).CornerRadius=UDim.new(0,5)
end

local function makeButton(key,text,callback)
local b=Instance.new("TextButton")
b.Size=UDim2.new(1,0,0,28)
b.BackgroundColor3=Color3.fromRGB(50,50,75)
b.Text=text
b.TextColor3=Color3.fromRGB(255,255,255)
b.TextStrokeTransparency=0.2
b.TextStrokeColor3=Color3.fromRGB(0,0,0)
b.TextSize=11
b.Font=Enum.Font.GothamBold
b.BorderSizePixel=0
b.LayoutOrder=nextOrder(key)
b.ZIndex=4
b.Parent=pages[key].page
Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
local bs=Instance.new("UIStroke",b)
bs.Thickness=1.2
bs.Color=Color3.fromRGB(255,180,210)
bs.Transparency=.25
b.MouseButton1Click:Connect(callback)
return b
end

local function makeToggle(key,text,onFunc,offFunc)
local b=Instance.new("TextButton")
b.Size=UDim2.new(1,0,0,30)
b.BackgroundColor3=Color3.fromRGB(50,50,75)
b.Text=text.."  ○"
b.TextColor3=Color3.fromRGB(255,255,255)
b.TextStrokeTransparency=0.2
b.TextStrokeColor3=Color3.fromRGB(0,0,0)
b.TextSize=11
b.Font=Enum.Font.GothamBold
b.BorderSizePixel=0
b.LayoutOrder=nextOrder(key)
b.ZIndex=4
b.Parent=pages[key].page
Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
local stroke=Instance.new("UIStroke",b)
stroke.Thickness=1.2
stroke.Color=Color3.fromRGB(255,180,210)
stroke.Transparency=.35
local state=false
local function update()
if state then
b.Text=text.."  ●"
b.BackgroundColor3=Color3.fromRGB(90,200,140)
stroke.Color=Color3.fromRGB(180,255,200)
stroke.Transparency=.15
else
b.Text=text.."  ○"
b.BackgroundColor3=Color3.fromRGB(50,50,75)
stroke.Color=Color3.fromRGB(255,180,210)
stroke.Transparency=.35
end
end
update()
b.MouseButton1Click:Connect(function()
state=not state
update()
if state then if onFunc then pcall(onFunc)end
else if offFunc then pcall(offFunc)end end
end)
return b
end

local function makeSliderToggle(key,text,minV,maxV,defV,onFunc,offFunc)
local b=Instance.new("TextButton")
b.Size=UDim2.new(1,0,0,30)
b.BackgroundColor3=Color3.fromRGB(50,50,75)
b.Text=text.."  ○"
b.TextColor3=Color3.fromRGB(255,255,255)
b.TextStrokeTransparency=0.2
b.TextStrokeColor3=Color3.fromRGB(0,0,0)
b.TextSize=11
b.Font=Enum.Font.GothamBold
b.BorderSizePixel=0
b.LayoutOrder=nextOrder(key)
b.ZIndex=4
b.Parent=pages[key].page
Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
local stroke=Instance.new("UIStroke",b)
stroke.Thickness=1.2
stroke.Color=Color3.fromRGB(255,180,210)
stroke.Transparency=.35

local panel=Instance.new("Frame")
panel.Size=UDim2.new(1,0,0,46)
panel.BackgroundColor3=Color3.fromRGB(30,30,50)
panel.BorderSizePixel=0
panel.LayoutOrder=nextOrder(key)
panel.Visible=false
panel.ZIndex=4
panel.Parent=pages[key].page
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,9)

local vl=Instance.new("TextLabel")
vl.Size=UDim2.new(1,-14,0,14)
vl.Position=UDim2.new(0,7,0,3)
vl.BackgroundTransparency=1
vl.Text=text..": "..defV
vl.TextColor3=Color3.fromRGB(255,255,255)
vl.TextSize=10
vl.Font=Enum.Font.GothamBold
vl.TextXAlignment=Enum.TextXAlignment.Left
vl.ZIndex=5
vl.Parent=panel

local bar=Instance.new("Frame")
bar.Size=UDim2.new(1,-30,0,8)
bar.Position=UDim2.new(0,15,0,28)
bar.BackgroundColor3=Color3.fromRGB(255,255,255)
bar.BackgroundTransparency=.5
bar.BorderSizePixel=0
bar.ZIndex=5
bar.Parent=panel
Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)

local fill=Instance.new("Frame")
fill.Size=UDim2.new(0,0,1,0)
fill.BackgroundColor3=Color3.fromRGB(255,80,160)
fill.BorderSizePixel=0
fill.ZIndex=6
fill.Parent=bar
Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

local knob=Instance.new("TextButton")
knob.Size=UDim2.new(0,14,0,14)
knob.AnchorPoint=Vector2.new(.5,.5)
knob.Position=UDim2.new(0,0,.5,0)
knob.BackgroundColor3=Color3.new(1,1,1)
knob.Text=""
knob.BorderSizePixel=0
knob.ZIndex=7
knob.Parent=bar
Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

local state=false
local cv=defV
local function updateSlider(alpha)
alpha=math.clamp(alpha,0,1)
local v=math.floor(minV+(maxV-minV)*alpha)
cv=v
fill.Size=UDim2.new(alpha,0,1,0)
knob.Position=UDim2.new(alpha,0,.5,0)
vl.Text=text..": "..v
return v
end
updateSlider((defV-minV)/(maxV-minV))

local sd=false
bar.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
sd=true
local sx=bar.AbsolutePosition.X
local sw=bar.AbsoluteSize.X
updateSlider((i.Position.X-sx)/sw)
if state and onFunc then pcall(onFunc,cv)end
end
end)
UIS.InputChanged:Connect(function(i)
if not sd then return end
if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then
local sx=bar.AbsolutePosition.X
local sw=bar.AbsoluteSize.X
updateSlider((i.Position.X-sx)/sw)
if state and onFunc then pcall(onFunc,cv)end
end
end)
UIS.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
sd=false
end
end)

b.MouseButton1Click:Connect(function()
state=not state
if state then
b.Text=text.."  ●"
b.BackgroundColor3=Color3.fromRGB(90,200,140)
stroke.Color=Color3.fromRGB(180,255,200)
stroke.Transparency=.15
panel.Visible=true
if onFunc then pcall(onFunc,cv)end
else
b.Text=text.."  ○"
b.BackgroundColor3=Color3.fromRGB(50,50,75)
stroke.Color=Color3.fromRGB(255,180,210)
stroke.Transparency=.35
panel.Visible=false
if offFunc then pcall(offFunc)end
end
end)
return b
end

local StatusLabel=Instance.new("TextLabel")
StatusLabel.Size=UDim2.new(1,-16,0,16)
StatusLabel.Position=UDim2.new(0,8,1,-20)
StatusLabel.BackgroundColor3=Color3.fromRGB(0,0,0)
StatusLabel.BackgroundTransparency=.3
StatusLabel.Text="就绪"
StatusLabel.TextColor3=Color3.fromRGB(120,255,180)
StatusLabel.TextStrokeTransparency=0.2
StatusLabel.TextStrokeColor3=Color3.fromRGB(0,0,0)
StatusLabel.TextSize=10
StatusLabel.Font=Enum.Font.GothamBold
StatusLabel.TextXAlignment=Enum.TextXAlignment.Center
StatusLabel.ZIndex=6
StatusLabel.Parent=P
Instance.new("UICorner",StatusLabel).CornerRadius=UDim.new(0,6)

local function setStatus(txt,ok)
StatusLabel.Text=txt
StatusLabel.TextColor3=ok and Color3.fromRGB(120,255,180)or Color3.fromRGB(255,120,120)
end

-- 分类
createPage("player")
createPage("auto")
createPage("avoid")
createPage("esp")
createPage("notify")
createPage("settings")

addCategory("player","玩家")
addCategory("auto","自动")
addCategory("avoid","规避")
addCategory("esp","透视")
addCategory("notify","提示")
addCategory("settings","设置")

pages.player.page.Visible=true
sideButtons.player.BackgroundColor3=Color3.fromRGB(255,80,160)
sideButtons.player.TextColor3=Color3.new(1,1,1)

-- ============ 一、玩家区 ============
addLabel("player","· 移动与物理")

makeToggle("player","自定义速度",function()
toggleLoop("speed",true,function()
local hum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
if hum then hum.WalkSpeed=desiredWalkSpeed end
end)
setStatus("✓ 速度锁定开启",true)
end,function()
toggleLoop("speed",false)
setStatus("速度锁定关闭",true)
end)

makeSliderToggle("player","速度值",16,100,16,function(v)
desiredWalkSpeed=v
setStatus("✓ 速度 "..v,true)
end,function()
desiredWalkSpeed=16
end)

makeToggle("player","即时加速度",function()
local prop=PhysicalProperties.new(100,0,0,0,0)
local function apply(c)
if c and c:FindFirstChild("HumanoidRootPart")then
c.HumanoidRootPart.CustomPhysicalProperties=prop
end
end
apply(LP.Character)
LP.CharacterAdded:Connect(function(c)task.wait(1.5)apply(c)end)
setStatus("✓ 即时加速度开启",true)
end,function()
local prop=PhysicalProperties.new(0.01,0.7,0,1,1)
local function apply(c)
if c and c:FindFirstChild("HumanoidRootPart")then
c.HumanoidRootPart.CustomPhysicalProperties=prop
end
end
apply(LP.Character)
setStatus("即时加速度关闭",true)
end)

makeToggle("player","飞行模式",function()
loadFlightScript()
setStatus("✓ 飞行模式开启",true)
end,function()
setStatus("飞行模式关闭",true)
end)

makeToggle("player","穿墙模式",function()
toggleNoclip(true)
setStatus("✓ 穿墙开启",true)
end,function()
toggleNoclip(false)
setStatus("穿墙关闭",true)
end)

makeToggle("player","更快爬梯",function()
toggleFastLadder(true)
setStatus("✓ 更快爬梯开启",true)
end,function()
toggleFastLadder(false)
setStatus("更快爬梯关闭",true)
end)

makeSliderToggle("player","爬梯速度",0,100,20,function(v)
ladderSpeedValue=v
setStatus("✓ 爬梯速度 "..v,true)
end,function()
ladderSpeedValue=20
end)

makeToggle("player","始终可跳跃",function()
toggleAlwaysJump(true)
setStatus("✓ 始终可跳跃开启",true)
end,function()
toggleAlwaysJump(false)
setStatus("始终可跳跃关闭",true)
end)

addLabel("player","· 辅助")

makeToggle("player","头部发光",function()
toggleHeadLight(true)
setStatus("✓ 头部发光开启",true)
end,function()
toggleHeadLight(false)
setStatus("头部发光关闭",true)
end)

makeButton("player","获得十字架",function()
getCrucifix()
setStatus("✓ 十字架已添加",true)
end)

makeToggle("player","血量锁定",function()
toggleHealthLock(true)
setStatus("✓ 血量锁定开启",true)
end,function()
toggleHealthLock(false)
setStatus("血量锁定关闭",true)
end)

makeSliderToggle("player","血量数值",1,1000,100,function(v)
healthValue=v
setStatus("✓ 血量 "..v,true)
end,function()
healthValue=100
end)

makeButton("player","禁用反作弊(电梯)",function()
disableAntiCheat()
end)

-- ============ 二、自动区 ============
addLabel("auto","· 互动自动化")

makeToggle("auto","即时互动",function()
game:GetService("ProximityPromptService").PromptButtonHoldBegan:Connect(safeFireProximityPrompt)
setStatus("✓ 即时互动开启",true)
end,function()
setStatus("即时互动关闭",true)
end)

makeSliderToggle("auto","互动范围倍数",1,5,1,function(v)
for _,o in ipairs(Workspace:GetDescendants())do
if o:IsA("ProximityPrompt")then
local orig=o:GetAttribute("OriginalMaxDist")or o.MaxActivationDistance
o.MaxActivationDistance=orig*v
if not o:GetAttribute("OriginalMaxDist")then
o:SetAttribute("OriginalMaxDist",orig)
end
end
end
setStatus("✓ 范围倍数 "..v,true)
end,function()
setStatus("范围恢复",true)
end)

makeToggle("auto","自动互动(捡物)",function()
toggleLoop("autoInteract",true,autoInteractLoop)
setStatus("✓ 自动互动开启",true)
end,function()
toggleLoop("autoInteract",false)
setStatus("自动互动关闭",true)
end)

makeToggle("auto","自动门范围",function()
toggleLoop("autoDoorReach",true,autoOpenDoorsLoop)
setStatus("✓ 自动门开启",true)
end,function()
toggleLoop("autoDoorReach",false)
setStatus("自动门关闭",true)
end)

addLabel("auto","· 任务自动化")

makeToggle("auto","自动破门",function()
toggleLoop("breakDoor",true,autoBreakDoorLoop)
setStatus("✓ 自动破门开启",true)
end,function()
toggleLoop("breakDoor",false)
setStatus("自动破门关闭",true)
end)

makeToggle("auto","自动拾取掉落物",function()
toggleLoop("pickupDrops",true,autoPickupDropsLoop)
setStatus("✓ 自动拾取开启",true)
end,function()
toggleLoop("pickupDrops",false)
setStatus("自动拾取关闭",true)
end)

makeToggle("auto","自动矿车推动",function()
toggleLoop("minecart",true,autoMinecartLoop)
setStatus("✓ 自动矿车开启",true)
end,function()
toggleLoop("minecart",false)
setStatus("自动矿车关闭",true)
end)

makeToggle("auto","自动拾取投掷物",function()
toggleLoop("throwables",true,autoThrowablesLoop)
setStatus("✓ 自动投掷物开启",true)
end,function()
toggleLoop("throwables",false)
setStatus("自动投掷物关闭",true)
end)

makeToggle("auto","自动开火",function()
toggleAutoFire(true)
setStatus("✓ 自动开火开启",true)
end,function()
toggleAutoFire(false)
setStatus("自动开火关闭",true)
end)

makeToggle("auto","自动房间(Rooms)",function()
toggleLoop("autoRooms",true,autoRoomsLoop)
setStatus("✓ 自动房间开启",true)
end,function()
toggleLoop("autoRooms",false)
setStatus("自动房间关闭",true)
end)

makeToggle("auto","自动隐藏(防怪物)",function()
autoHideSetup()
setStatus("✓ 自动隐藏开启",true)
end,function()
setStatus("自动隐藏关闭",true)
end)

makeToggle("auto","反AFK",function()
_G.AFKConn=LP.Idled:Connect(function()
game:GetService("VirtualUser"):CaptureController()
game:GetService("VirtualUser"):ClickButton2(Vector2.new())
end)
setStatus("✓ 反AFK开启",true)
end,function()
if _G.AFKConn then _G.AFKConn:Disconnect()_G.AFKConn=nil end
setStatus("反AFK关闭",true)
end)

-- ============ 三、规避区 ============
addLabel("avoid","· 实体规避")

makeToggle("avoid","规避Screech",function()avoidScreech(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避Gloom蛋",function()avoidGloom(true)setStatus("✓",true)end,function()avoidGloom(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Dread",function()avoidDread(true)setStatus("✓",true)end,function()avoidDread(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Giggle",function()avoidGiggle(true)setStatus("✓",true)end,function()avoidGiggle(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Figure听觉",function()avoidFigureHearing(true)setStatus("✓",true)end,function()avoidFigureHearing(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Surge",function()avoidSurge(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避Halt",function()avoidHalt(true)setStatus("✓",true)end,function()avoidHalt(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Lookman",function()avoidLookman(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避Snare",function()avoidSnare(true)setStatus("✓",true)end,function()avoidSnare(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Seek障碍物",function()avoidSeekObstacles(true)setStatus("✓",true)end,function()avoidSeekObstacles(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Dupe门",function()avoidDupeDoors(true)setStatus("✓",true)end,function()avoidDupeDoors(false)setStatus("关闭",true)end)
makeToggle("avoid","规避真空区域",function()avoidVoidArea(true)setStatus("✓",true)end,function()avoidVoidArea(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Eyes",function()avoidEyes(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避A-90",function()avoidA90(true)setStatus("✓",true)end,function()avoidA90(false)setStatus("关闭",true)end)
makeToggle("avoid","规避虚空效果",function()avoidVoidEffect(true)setStatus("✓",true)end,function()avoidVoidEffect(false)setStatus("关闭",true)end)
makeToggle("avoid","规避Haste效果",function()avoidHaste(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避Firedamp",function()avoidFiredamp(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避矿井氛围",function()avoidMineAtmosphere(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)
makeToggle("avoid","规避氧气/理智效果",function()avoidOxygenSanity(true)setStatus("✓",true)end,function()setStatus("关闭",true)end)

addLabel("avoid","· 视觉效果")

makeToggle("avoid","无雾效果",function()setNoFog(true)setStatus("✓",true)end,function()setNoFog(false)setStatus("关闭",true)end)
makeToggle("avoid","无相机抖动",function()setNoShake(true)setStatus("✓",true)end,function()setNoShake(false)setStatus("关闭",true)end)
makeToggle("avoid","无头部晃动",function()setNoHeadBob(true)setStatus("✓",true)end,function()setNoHeadBob(false)setStatus("关闭",true)end)
makeToggle("avoid","跳过过场动画",function()setNoCutscenes(true)setStatus("✓",true)end,function()setNoCutscenes(false)setStatus("关闭",true)end)
makeToggle("avoid","移除隐藏暗角",function()removeHideVignette(true)setStatus("✓",true)end,function()removeHideVignette(false)setStatus("关闭",true)end)
makeToggle("avoid","防卡顿",function()antiJam(true)setStatus("✓",true)end,function()antiJam(false)setStatus("关闭",true)end)
makeToggle("avoid","防香蕉皮",function()antiBanana(true)setStatus("✓",true)end,function()antiBanana(false)setStatus("关闭",true)end)
makeToggle("avoid","防Jeff杀手",function()antiJeff(true)setStatus("✓",true)end,function()antiJeff(false)setStatus("关闭",true)end)

-- ============ 四、透视区 ============
addLabel("esp","· 物体透视")

makeToggle("esp","门透视",function()
enableESP("door",function(o)return doorNames[o.Name]end,Color3.fromRGB(0,255,0))
setStatus("✓ 门透视开启",true)
end,function()disableESP("door")setStatus("门透视关闭",true)end)

makeToggle("esp","目标物品",function()
enableESP("obj",function(o)return objectiveItems[o.Name]end,Color3.fromRGB(255,255,0))
setStatus("✓ 目标物品开启",true)
end,function()disableESP("obj")setStatus("关闭",true)end)

makeToggle("esp","金币",function()
enableESP("coin",function(o)return coinNames[o.Name]end,Color3.fromRGB(255,255,0))
setStatus("✓ 金币透视开启",true)
end,function()disableESP("coin")setStatus("关闭",true)end)

makeToggle("esp","发电机",function()
enableESP("gen",function(o)return genNames[o.Name]end,Color3.fromRGB(0,255,255))
setStatus("✓ 发电机透视开启",true)
end,function()disableESP("gen")setStatus("关闭",true)end)

makeToggle("esp","杠杆",function()
enableESP("lever",function(o)return leverNames[o.Name]end,Color3.fromRGB(255,165,0))
setStatus("✓ 杠杆透视开启",true)
end,function()disableESP("lever")setStatus("关闭",true)end)

makeToggle("esp","物品",function()
enableESP("item",function(o)return itemNames[o.Name]end,Color3.fromRGB(0,0,255))
setStatus("✓ 物品透视开启",true)
end,function()disableESP("item")setStatus("关闭",true)end)

makeToggle("esp","柜子",function()
enableESP("closet",function(o)return closetNames[o.Name]end,Color3.fromRGB(255,192,203))
setStatus("✓ 柜子透视开启",true)
end,function()disableESP("closet")setStatus("关闭",true)end)

makeToggle("esp","锚点",function()
enableESP("anchor",function(o)return anchorNames[o.Name]end,Color3.fromRGB(255,192,203))
setStatus("✓ 锚点透视开启",true)
end,function()disableESP("anchor")setStatus("关闭",true)end)

makeToggle("esp","书籍",function()
enableESP("book",function(o)return bookNames[o.Name]end,Color3.fromRGB(0,255,255))
setStatus("✓ 书籍透视开启",true)
end,function()disableESP("book")setStatus("关闭",true)end)

makeToggle("esp","宝箱",function()
enableESP("chest",function(o)return chestNames[o.Name]end,Color3.fromRGB(0,255,0))
setStatus("✓ 宝箱透视开启",true)
end,function()disableESP("chest")setStatus("关闭",true)end)

addLabel("esp","· 实体透视")

local entities={
{Name="Seek",Text="追逐者",Model="SeekMoving"},
{Name="Figure",Text="雕像",Model="FigureRig"},
{Name="Ambush",Text="伏击",Model="AmbushMoving"},
{Name="Rush",Text="冲刺",Model="RushMoving"},
{Name="Snare",Text="陷阱",Model="Snare"},
{Name="Giggle",Text="傻笑",Model="GiggleCeiling"},
{Name="Eyestalk",Text="眼球",Model="EyestalkMoving"},
{Name="Mandrake",Text="曼德拉草",Model="Mandrake"},
{Name="Groundskeeper",Text="园丁",Model="Groundskeeper"},
{Name="Blitz",Text="闪电",Model="BackdoorRush"},
}
for _,v in ipairs(entities)do
makeToggle("esp",v.Text,function()
enableESP(v.Name.."Entity",function(o)return o.Name==v.Model end,Color3.fromRGB(255,0,0))
setStatus("✓ "..v.Text.."透视开启",true)
end,function()
disableESP(v.Name.."Entity")
setStatus("关闭",true)
end)
end

-- ============ 五、提示区 ============
addLabel("notify","· 实体刷新提示")

for name,desc in pairs(entityNotifyList)do
makeToggle("notify",desc.."提示",function()
Workspace.ChildAdded:Connect(function(obj)
if obj.Name==name then
Notify(desc.." 已出现",5)
end
end)
setStatus("✓ "..desc.."提示开启",true)
end,function()
setStatus("关闭",true)
end)
end

-- ============ 六、设置区 ============
addLabel("settings","· 脚本控制")

makeButton("settings","卸载脚本",function()
for _,conn in pairs(loops)do
if conn then conn:Disconnect()end
end
loops={}
for name,_ in pairs(espConnections)do
disableESP(name)
end
_G.autowinfarm=false
Gui:Destroy()
end)

-- ============ 悬浮球拖动 ============
local dragging=false
local dragStart=nil
local startPos=nil
local moved=false

Orb.InputBegan:Connect(function(input)
if input.UserInputType==Enum.UserInputType.MouseButton1
or input.UserInputType==Enum.UserInputType.Touch then
dragging=true
moved=false
dragStart=input.Position
startPos=Orb.Position
input.Changed:Connect(function()
if input.UserInputState==Enum.UserInputState.End then dragging=false end
end)
end
end)

Orb.InputChanged:Connect(function(input)
if not dragging then return end
if input.UserInputType~=Enum.UserInputType.MouseMovement
and input.UserInputType~=Enum.UserInputType.Touch then return end
local d=input.Position-dragStart
moved=true
Orb.Position=UDim2.new(
startPos.X.Scale,startPos.X.Offset+d.X,
startPos.Y.Scale,startPos.Y.Offset+d.Y)
end)

Orb.MouseButton1Click:Connect(function()
if moved then moved=false return end
if P.Visible then
P.Visible=false
Orb.Text="🚪"
else
P.Visible=true
Orb.Text="×"
end
end)

-- 加载提示
game:GetService("StarterGui"):SetCore("SendNotification",{
Title="DOORS",
Text="已加载 · 点击🚪打开",
Duration=3})
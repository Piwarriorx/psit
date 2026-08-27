--[[
	PI HUB  |  Grow a Chicken Fighter  (v8.7)  [FIXED REBIRTH]
	- Right Shift / tap P icon : menu toggle
	- UNLOAD button sa menu o _G.PiHubDestroy()
	- HP threshold slider (1–100%) bago mag-tower run
	- Draggable floating icon (mobile-friendly)
	- Compact at centered menu para sa mobile
	- FIX: Awtomatikong nagre-retreat sa tower kapag ready na mag-rebirth
]]

if type(_G.PiHubDestroy) == "function" then pcall(_G.PiHubDestroy) end
_G.HubGen = (_G.HubGen or 0) + 1
local GEN = _G.HubGen
_G.FeederAutoUpgrade = false
_G.HubConns = _G.HubConns or {}

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local okMods, Mods = pcall(function()
	local PS = LP.PlayerScripts
	return {
		Client = require(RS.Packages.DataService).client,
		CoopView = require(RS.Features.Coop.CoopView),
		Data = require(PS.Core.Data.DataController),
		RebirthBonus = require(RS.Core.Progression.RebirthBonus),
		MissionView = require(RS.Features.Missions.MissionView),
		MissionDefs = require(RS.Content.Missions),
		BodyProxy = require(RS.Features.Chicken.ChickenBodyProxy),
		ChickenMode = require(PS.Features.Chicken.ChickenMode),
		ChickenCtrl = require(PS.Features.Chicken.controllers.ChickenController),
	}
end)

if not okMods then
	warn("[PiHub] Failed to load required modules. Make sure you're in 'Grow a Chicken Fighter'.")
	return
end

local ACCENT = Color3.fromRGB(0, 195, 140)
local WARN = Color3.fromRGB(240, 160, 60)
local BG = Color3.fromRGB(17, 17, 23)
local CARD = Color3.fromRGB(26, 26, 34)
local TEXT = Color3.fromRGB(235, 235, 240)
local DIM = Color3.fromRGB(150, 150, 165)
local OFF = Color3.fromRGB(55, 55, 68)

local state = {
	autoFeeders = true,
	claimAll = false,
	autoTower = true,
	autoRebirth = true,
	autoChaos = false,
	maxFeederLevel = 35,
	hpThreshold = 100,
}
if type(_G.HubSavedState) == "table" then
	for k, v in pairs(_G.HubSavedState) do
		if type(v) == "boolean" then state[k] = v end
	end
	if _G.HubSavedState.maxFeederLevel then state.maxFeederLevel = _G.HubSavedState.maxFeederLevel end
	if _G.HubSavedState.hpThreshold then state.hpThreshold = _G.HubSavedState.hpThreshold end
end
_G.HubState = state

local gui = Instance.new("ScreenGui")
gui.Name = "PiHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.Parent = PG

local function make(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	o.Parent = parent
	return o
end

local function round(o, r)
	make("UICorner", { CornerRadius = UDim.new(0, r or 8) }, o)
end

-- ===== COMPACT & CENTERED MAIN WINDOW =====
local main = make("Frame", {
	Size = UDim2.fromScale(0.8, 0.65),
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	BackgroundColor3 = BG, Active = true, Visible = false,
}, gui)
round(main, 12)
make("UIStroke", { Color = Color3.fromRGB(65, 65, 90), Thickness = 1 }, main)

local header = make("Frame", {
	Size = UDim2.new(1, 0, 0, 40), 
	BackgroundColor3 = Color3.fromRGB(13, 13, 18),
}, main)
round(header, 12)
make("Frame", {
	AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
	Size = UDim2.new(1, 0, 0, 8), BackgroundColor3 = header.BackgroundColor3,
	BorderSizePixel = 0,
}, header)

make("TextLabel", {
	Position = UDim2.fromOffset(10, 6), Size = UDim2.new(1, -50, 0, 18),
	BackgroundTransparency = 1, Text = "PI HUB", TextColor3 = TEXT,
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.GothamBold, TextSize = 16,
}, header)
make("TextLabel", {
	Position = UDim2.fromOffset(10, 22), Size = UDim2.new(1, -50, 0, 14),
	BackgroundTransparency = 1, Text = "Grow a Chicken Fighter", TextColor3 = DIM,
	TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Gotham, TextSize = 11,
}, header)

local closeBtn = make("TextButton", {
	AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
	Size = UDim2.fromOffset(26, 26), BackgroundColor3 = Color3.fromRGB(40, 40, 52),
	Text = "X", TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 14,
}, header)
round(closeBtn, 8)

local body = make("ScrollingFrame", {
	Position = UDim2.fromOffset(8, 46), Size = UDim2.new(1, -16, 1, -54),
	BackgroundTransparency = 1, BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(), ScrollBarThickness = 3, ScrollBarImageColor3 = OFF,
}, main)
make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, body)
make("UIPadding", { PaddingBottom = UDim.new(0, 5) }, body)

local function sectionLabel(text, order)
	make("TextLabel", {
		Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, LayoutOrder = order,
		Text = text, TextColor3 = DIM, Font = Enum.Font.GothamBold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, body)
end

local toggles = {}
local function addToggle(key, label, order, accent)
	local row = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = CARD, LayoutOrder = order,
		Text = "", AutoButtonColor = false,
	}, body)
	round(row, 8)
	make("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -80, 1, 0),
		BackgroundTransparency = 1, Text = label, TextColor3 = TEXT,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local pill = make("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(44, 22), BackgroundColor3 = OFF,
	}, row)
	round(pill, 11)
	local knob = make("Frame", {
		Position = UDim2.fromOffset(3, 3), Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(200, 200, 210),
	}, pill)
	round(knob, 8)
	toggles[key] = { pill = pill, knob = knob, accent = accent or ACCENT }
	row.MouseButton1Click:Connect(function()
		state[key] = not state[key]
		print("[PiHub] " .. key .. " = " .. tostring(state[key]))
	end)
end

local function addNumberInput(key, label, order, default, minVal, maxVal)
	local row = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = CARD, LayoutOrder = order,
		Text = "", AutoButtonColor = false,
	}, body)
	round(row, 8)
	make("TextLabel", {
		Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -100, 1, 0),
		BackgroundTransparency = 1, Text = label, TextColor3 = TEXT,
		Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local box = make("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(70, 24), BackgroundColor3 = OFF,
		Text = tostring(state[key] or default), TextColor3 = TEXT,
		Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
		ClearTextOnFocus = false,
	}, row)
	round(box, 6)
	make("UIStroke", { Color = Color3.fromRGB(80, 80, 100), Thickness = 1 }, box)
	box.FocusLost:Connect(function()
		local num = tonumber(box.Text)
		if num then
			num = math.floor(num)
			if minVal and num < minVal then num = minVal end
			if maxVal and num > maxVal then num = maxVal end
			state[key] = num
			box.Text = tostring(num)
			print("[PiHub] " .. key .. " = " .. num)
		else
			box.Text = tostring(state[key] or default)
		end
	end)
	return box
end

local sliderObjects = {}
local function addSlider(key, label, order, default, minVal, maxVal)
	local row = make("Frame", {
		Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = CARD, LayoutOrder = order,
	}, body)
	round(row, 8)
	local labelObj = make("TextLabel", {
		Position = UDim2.fromOffset(10, 4), Size = UDim2.new(1, -20, 0, 16),
		BackgroundTransparency = 1, Text = label .. ": " .. tostring(state[key] or default) .. "%",
		TextColor3 = TEXT, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, row)
	local slider = make("Frame", {
		Position = UDim2.fromOffset(10, 24), Size = UDim2.new(1, -70, 0, 14),
		BackgroundColor3 = OFF,
	}, row)
	round(slider, 7)
	local fill = make("Frame", {
		Size = UDim2.new((state[key] or default) / 100, 0, 1, 0),
		BackgroundColor3 = ACCENT,
	}, slider)
	round(fill, 7)
	local drag = make("TextButton", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((state[key] or default) / 100, 0, 0.5, 0),
		Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromRGB(255,255,255),
		Text = "", AutoButtonColor = false,
	}, slider)
	round(drag, 9)

	sliderObjects[key] = { slider = slider, fill = fill, drag = drag, label = labelObj, row = row }

	local function updateSlider(val)
		val = math.clamp(val, minVal or 0, maxVal or 100)
		state[key] = val
		fill.Size = UDim2.new(val / 100, 0, 1, 0)
		drag.Position = UDim2.new(val / 100, 0, 0.5, 0)
		labelObj.Text = label .. ": " .. tostring(val) .. "%"
		print("[PiHub] " .. key .. " = " .. val)
	end

	drag.MouseButton1Down:Connect(function()
		local con, con2
		con = UIS.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local relX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
				updateSlider(math.round(relX * 100))
			end
		end)
		con2 = UIS.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				con:Disconnect()
				con2:Disconnect()
			end
		end)
	end)
	slider.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local relX = math.clamp((input.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
			updateSlider(math.round(relX * 100))
		end
	end)
	return slider
end

local function paintToggles()
	for key, t in pairs(toggles) do
		local on = state[key] == true
		TS:Create(t.pill, TweenInfo.new(0.18), { BackgroundColor3 = on and t.accent or OFF }):Play()
		TS:Create(t.knob, TweenInfo.new(0.18), {
			Position = on and UDim2.fromOffset(25, 3) or UDim2.fromOffset(3, 3),
			BackgroundColor3 = on and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(200, 200, 210),
		}):Play()
	end
end

-- ===== UI LAYOUT (compact) =====
sectionLabel("FARMING", 1)
addToggle("autoFeeders", "Auto Feeders", 2)
addNumberInput("maxFeederLevel", "Max Upgrade Level", 3, 999, 1, 9999)
addToggle("autoTower", "Auto Tower Run", 4)
addToggle("autoChaos", "Auto Chaos", 5)
sectionLabel("REWARDS", 6)
addToggle("claimAll", "Auto Claim All", 7)
addToggle("autoRebirth", "Auto Rebirth", 8, WARN)
sectionLabel("TOWER HP", 9)
addSlider("hpThreshold", "HP threshold to start", 10, 100, 1, 100)

local function addButton(label, order, fn, color, textColor)
	local b = make("TextButton", {
		Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = color or CARD, LayoutOrder = order,
		Text = label, TextColor3 = textColor or TEXT, Font = Enum.Font.GothamBold,
		TextSize = 13, AutoButtonColor = false,
	}, body)
	round(b, 8)
	b.MouseButton1Click:Connect(fn)
	return b
end

local unloadBtn = addButton("UNLOAD SCRIPT", 11, function()
	print("[PiHub] unload requested from menu")
	if type(_G.PiHubDestroy) == "function" then _G.PiHubDestroy() end
end, Color3.fromRGB(60, 24, 28), Color3.fromRGB(255, 130, 130))

sectionLabel("INFO", 12)
local info = make("TextLabel", {
	Size = UDim2.new(1, 0, 0, 80), BackgroundColor3 = CARD, LayoutOrder = 13,
	Text = "...", RichText = true, TextColor3 = DIM, Font = Enum.Font.Code, TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, body)
round(info, 8)
make("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 6) }, info)

-- ===== FLOATING ICON =====
local fab = make("ImageButton", {
	Size = UDim2.fromOffset(50, 50), 
	Position = UDim2.new(0, 10, 0, 80),
	BackgroundColor3 = ACCENT, Image = "", ZIndex = 5,
}, gui)
round(fab, 25)
make("TextLabel", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "P",
	TextColor3 = Color3.fromRGB(10, 30, 24), Font = Enum.Font.GothamBlack, TextSize = 24, ZIndex = 6,
}, fab)

local function makeDraggable(obj)
	local dragging, dragStart, startPos
	obj.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = obj.Position
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end
makeDraggable(fab)

local function setVisible(v)
	if not main or not fab then return end
	main.Visible = v
	fab.Visible = not v
end

fab.MouseButton1Click:Connect(function()
	if main then setVisible(not main.Visible) end
end)
closeBtn.MouseButton1Click:Connect(function()
	setVisible(false)
end)

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.G or input.KeyCode == Enum.KeyCode.RightShift then
		setVisible(not main.Visible)
	end
end)

-- ===== HELPERS =====
local function money()
	if not okMods then return 0 end
	local ok, n = pcall(function() return Mods.Data.money():toNumber() end)
	return (ok and n) or 0
end

local function towerActive()
	local ar = workspace:FindFirstChild("Arenas")
	local idx = tonumber(LP:GetAttribute("Plot"))
	local a = ar and idx and ar:FindFirstChild("Arena" .. idx)
	return (a and a:GetAttribute("TowerActive")) == true, a and tonumber(a:GetAttribute("TowerFloor")) or 0
end

local BOSS_PAT = { "goose", "boss", "ufo", "kraken", "hotegg", "hot-egg", "event" }
local function findBoss()
	if not okMods then return nil end
	for _, part in ipairs(CS:GetTagged(Mods.BodyProxy.Tag)) do
		if part:IsA("BasePart") then
			local id = string.lower(tostring(part:GetAttribute(Mods.BodyProxy.Attr.EntityId) or ""))
			for _, p in ipairs(BOSS_PAT) do
				if #id > 0 and string.find(id, p, 1, true) then
					return part
				end
			end
		end
	end
	return nil
end

local function myChickenBody()
	if not okMods then return nil end
	for _, b in ipairs(CS:GetTagged(Mods.BodyProxy.Tag)) do
		if b:IsA("BasePart") and tostring(b:GetAttribute(Mods.BodyProxy.Attr.Owner)) == tostring(LP.UserId) then
			return b
		end
	end
	return nil
end

-- ===== INFO UPDATE =====
task.spawn(function()
	while GEN == _G.HubGen do
		paintToggles()
		local saved = {}
		for k, v in pairs(state) do saved[k] = v end
		_G.HubSavedState = saved
		if okMods then
			local okR, txt = pcall(function()
				local coop = Mods.Client:get({ "coop" })
				local parts = {}
				if coop then
					for _, g in ipairs(coop.generators) do
						parts[#parts + 1] = ("#%d Lv%s"):format(tonumber(g.slot) or 0, tostring(g.level))
					end
				end
				local rb = Mods.Data.rebirth()
				local cnt = rb and rb.count or 0
				local best = tonumber(Mods.Data.towerBest()) or 0
				local okQ, req = pcall(Mods.RebirthBonus.requirementFloorFor, cnt)
				req = okQ and req or "?"
				local act, fl = towerActive()
				local mine = myChickenBody()
				local hpTxt = "?"
				if mine then
					local hp = tonumber(mine:GetAttribute(Mods.BodyProxy.Attr.HpFrac))
					hpTxt = hp and math.floor(hp * 100 + 0.5) .. "%" or "?"
				end
				local rbReady = (type(req) == "number") and best >= req
				return table.concat(parts, "  ")
					.. "\nMoney: " .. tostring(math.floor((money() or 0) + 0.5))
					.. " | Best: " .. tostring(best)
					.. (act and (" | TOWER f" .. tostring(fl)) or "")
					.. " | HP: " .. hpTxt
					.. "\nRebirth #" .. tostring(cnt)
					.. " -> needs floor " .. tostring(req)
					.. (rbReady and " [READY]" or " [locked]")
					.. "\nMax Feeder: " .. tostring(state.maxFeederLevel)
					.. " | HP threshold: " .. tostring(state.hpThreshold) .. "%"
			end)
			info.Text = (okR and txt) or "-"
		else
			info.Text = "modules unavailable"
		end
		task.wait(0.8)
	end
end)

-- ===== AUTO FEEDERS =====
task.spawn(function()
	while GEN == _G.HubGen do
		if state.autoFeeders and okMods then
			pcall(function()
				local coop = Mods.Client:get({ "coop" })
				if not coop then return end
				if Mods.CoopView.canBuyGenerator(coop.slots, #coop.generators) then
					local cost = Mods.CoopView.buyGeneratorCost(#coop.generators)
					if money() >= cost then
						RS.Remotes.BuyGenerator:InvokeServer(#coop.generators + 1)
						task.wait(1)
						coop = Mods.Client:get({ "coop" }) or coop
					end
				end
				local maxLvl = state.maxFeederLevel or 999
				for _, g in ipairs(coop.generators) do
					local slot, lvl = tonumber(g.slot), tonumber(g.level)
					if slot and lvl and Mods.CoopView.canUpgrade(lvl) then
						if lvl < maxLvl then
							local cost = Mods.CoopView.upgradeCost(lvl)
							if money() >= cost then
								RS.Remotes.UpgradeGenerator:InvokeServer(slot)
								task.wait(0.6)
							end
						end
					end
				end
			end)
		end
		task.wait(1)
	end
end)

-- ===== AUTO CLAIM =====
task.spawn(function()
	while GEN == _G.HubGen do
		if state.claimAll and okMods then
			pcall(function()
				local r = RS.Remotes.DailyClaim:InvokeServer()
				if r and r.ok then print("[PiHub] Claimed: daily") end
			end)
			pcall(function()
				local r = RS.Remotes.SocialClaim:InvokeServer()
				if r and r.ok then print("[PiHub] Claimed: community") end
			end)
			pcall(function()
				local r = RS.Remotes.PassClaim:InvokeServer()
				if r and r.ok then print("[PiHub] Claimed: pass") end
			end)
			pcall(function()
				local r = RS.Remotes.ClaimRebirthMilestones:InvokeServer()
				if r and r.ok then print("[PiHub] Claimed: rebirth milestones") end
			end)
			pcall(function()
				local snap = { missions = Mods.Data.missions(), towerBest = Mods.Data.towerBest() }
				local rb = Mods.Data.rebirth()
				snap.rebirthCount = rb and rb.count or 0
				for _, def in ipairs(Mods.MissionDefs) do
					local prog = Mods.MissionView.progress(def, snap)
					local goal = def.goal or def.amount or def.target or def.count
					local claimed = Mods.MissionView.track(snap, def.scope).claimed or {}
					if goal and prog >= goal and not claimed[tostring(def.id)] and not claimed[def.id] then
						local r = RS.Remotes.MissionClaim:InvokeServer(def.id)
						if r and r.ok then print("[PiHub] Claimed mission:", tostring(def.id)) end
						task.wait(0.5)
					end
				end
			end)
		end
		task.wait(45)
	end
end)

-- ===== AUTO TOWER (with HP threshold + rebirth readiness check) =====
local lastContinueAttempt = 0
table.insert(_G.HubConns, RS.Remotes.TowerContinueOffer.OnClientEvent:Connect(function(payload)
	if GEN ~= _G.HubGen or not state.autoTower then return end
	local now = os.clock()
	if now - lastContinueAttempt < 2 then return end
	lastContinueAttempt = now
	task.spawn(function()
		task.wait(0.6)
		pcall(function() RS.Remotes.TowerContinueDecline:FireServer() end)
		print("[PiHub] Continue offer DECLINED")
	end)
end))

task.spawn(function()
	while GEN == _G.HubGen do
		if state.autoTower and okMods then
			local active = false
			pcall(function() active = towerActive() end)
			if active then
				local ko = false
				pcall(function()
					local mine = myChickenBody()
					if mine then
						local st = string.lower(tostring(mine:GetAttribute(Mods.BodyProxy.Attr.State) or ""))
						local hp = tonumber(mine:GetAttribute(Mods.BodyProxy.Attr.HpFrac))
						if st == "ko" or st == "dead" or (hp ~= nil and hp <= 0) then
							ko = true
						end
					end
				end)
				if ko then
					print("[PiHub] Chicken KO - surrendering run...")
					pcall(function()
						Mods.ChickenMode.order("coop")
						RS.Remotes.TowerSurrender:InvokeServer()
					end)
					task.delay(1, function()
						pcall(function() RS.Remotes.TowerContinueDecline:FireServer() end)
					end)
					task.wait(12)
				else
					task.wait(2)
				end
			else
				local busyWithBoss = state.autoChaos and findBoss() ~= nil
				if not busyWithBoss then
					-- 【BAGONG CHECK】Huwag magsimula ng tower kung ready na mag-rebirth
					local rebirthReady = false
					if state.autoRebirth and okMods then
						pcall(function()
							local rb = Mods.Data.rebirth()
							local cnt = rb and rb.count or 0
							local best = tonumber(Mods.Data.towerBest()) or 0
							local okQ, req = pcall(Mods.RebirthBonus.requirementFloorFor, cnt)
							if okQ and best >= req then
								rebirthReady = true
							end
						end)
					end

					if not rebirthReady then
						local hp = 0
						pcall(function()
							local mine = myChickenBody()
							if mine then
								hp = tonumber(mine:GetAttribute(Mods.BodyProxy.Attr.HpFrac)) or 0
							end
						end)
						local threshold = (state.hpThreshold or 100) / 100
						if hp >= threshold then
							pcall(function()
								Mods.ChickenMode.order("tower")
								task.wait(0.35)
								local res = RS.Remotes.TowerStart:InvokeServer()
								if res and res.ok then
									print("[PiHub] TowerStart OK (floor 1)! HP: " .. math.floor(hp*100) .. "%")
								else
									print("[PiHub] TowerStart fail:", tostring(res and res.error))
								end
							end)
							task.wait(8)
						else
							print("[PiHub] HP " .. math.floor(hp*100) .. "% < threshold " .. state.hpThreshold .. "%. Waiting...")
							task.wait(2)
						end
					else
						print("[PiHub] Ready for rebirth, skipping tower start.")
						task.wait(2)
					end
				end
			end
		end
		task.wait(1)
	end
end)

-- ===== REBIRTH (with auto-retreat) =====
local lastRebirthTry = 0
local function tryRebirth(force)
	if GEN ~= _G.HubGen then return end
	if not (state.autoRebirth and okMods) then return end

	local now = os.clock()
	if not force and now - lastRebirthTry < 4 then return end
	lastRebirthTry = now

	pcall(function()
		local rb = Mods.Data.rebirth()
		local cnt = rb and rb.count or 0
		local best = tonumber(Mods.Data.towerBest()) or 0
		local okQ, req = pcall(Mods.RebirthBonus.requirementFloorFor, cnt)
		if not (okQ and best >= req) then return end

		-- 【BAGONG LOGIC】Kung nasa tower, sumuko muna
		local active, _ = towerActive()
		if active then
			print("[PiHub] Ready to rebirth but tower is active. Retreating...")
			RS.Remotes.TowerSurrender:InvokeServer()
			RS.Remotes.TowerContinueDecline:FireServer()
			task.wait(2.5)
		end

		-- Double‑check kung wala na sa tower
		local stillActive, _ = towerActive()
		if not stillActive then
			local res = RS.Remotes.Rebirth:InvokeServer()
			print("[PiHub] REBIRTH FIRED:", tostring(res and res.ok))
		else
			print("[PiHub] Tower still active after retreat, cannot rebirth yet.")
		end
	end)
end

table.insert(_G.HubConns, RS.Remotes.TowerRunEnded.OnClientEvent:Connect(function()
	if GEN == _G.HubGen then
		task.delay(1, function()
			pcall(function() RS.Remotes.TowerContinueDecline:FireServer() end)
		end)
		task.delay(2, tryRebirth, true)
	end
end))
table.insert(_G.HubConns, RS.Remotes.TowerDefeat.OnClientEvent:Connect(function()
	if GEN == _G.HubGen then
		task.delay(1, function()
			pcall(function() RS.Remotes.TowerContinueDecline:FireServer() end)
		end)
		task.delay(2, tryRebirth, true)
	end
end))

task.spawn(function()
	while GEN == _G.HubGen do
		tryRebirth(false)
		task.wait(5)
	end
end)

-- ===== CHAOS =====
task.spawn(function()
	while GEN == _G.HubGen do
		if state.autoChaos and okMods then
			pcall(function()
				local boss = findBoss()
				if boss then
					local char = LP.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart")
					if hrp then
						local bp = boss.Position
						local dir = (hrp.Position - bp)
						dir = Vector3.new(dir.X, 0, dir.Z)
						if dir.Magnitude < 1 then dir = Vector3.new(1, 0, 0) end
						dir = dir.Unit * 14
						hrp.AssemblyLinearVelocity = Vector3.zero
						char:PivotTo(CFrame.new(bp + dir + Vector3.new(0, 3, 0)) * (hrp.CFrame - hrp.Position))
					end
					state._lastChaosOrder = state._lastChaosOrder or 0
					if os.clock() - state._lastChaosOrder > 3 then
						state._lastChaosOrder = os.clock()
						Mods.ChickenCtrl:setOrder("chaos")
					end
				else
					state._lastChaosOrder = 0
				end
			end)
		end
		task.wait(2)
	end
end)

-- ===== UNLOAD =====
_G.PiHubDestroy = function()
	_G.HubGen = _G.HubGen + 1
	for _, c in ipairs(_G.HubConns or {}) do 
		pcall(function() c:Disconnect() end) 
	end
	table.clear(_G.HubConns or {})
	if gui then pcall(function() gui:Destroy() end) end
	_G.PiHubDestroy = nil
	print("[PiHub] unloaded")
end

print("[PiHub] loaded (gen " .. GEN .. ") - tap P icon or RightShift")
task.wait(0.5)
setVisible(true)
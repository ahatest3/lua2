local plotsFolder = game.Workspace:WaitForChild("Plots")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")

local ReplicatedService = game:GetService("ReplicatedStorage")
local events = ReplicatedService:WaitForChild("Events")
local soundEvent = events:WaitForChild("PlaySound")

local SS = game:GetService("SoundService")
local sounds = SS:WaitForChild("Sounds")

local settingsModule = require(ReplicatedService:WaitForChild("Modules"):WaitForChild("Settings"))
local formatModule = require(ReplicatedService:WaitForChild("Modules"):WaitForChild("FormatNumber"))
local notificationModule = require(ReplicatedService:WaitForChild("Modules"):WaitForChild("Notifications"))


local isStudio
isStudio = RS:IsStudio()

local PlotHandler = {}

--show money affect when they purchase a business
PlotHandler.DoMoneyEffect = function(player:Player, rate)
	local char = player.Character
	local hrp = char:WaitForChild("HumanoidRootPart")
	local head = char:WaitForChild("Head")
	local moneyParticleClone = ReplicatedService:WaitForChild("CashParticle"):Clone()
	moneyParticleClone.Parent = workspace
	moneyParticleClone.CFrame = hrp.CFrame
	
	if rate then moneyParticleClone.CashParticle.Rate = rate end

	task.spawn(function()
		repeat wait(0.1) moneyParticleClone.CFrame = hrp.CFrame until not moneyParticleClone
	end)

	task.delay(.5, function()
		moneyParticleClone.CashParticle.Enabled = false
		task.wait(.5)
		moneyParticleClone:Destroy()
	end)
end

--assign the plot to the user once they join the game
PlotHandler.AssignPlot = function(player:Player)
	for _, plot in pairs(plotsFolder:GetChildren()) do
		local character = player.Character or player.CharacterAdded:Wait()
		local HRP:Part = character:WaitForChild("HumanoidRootPart")
		if plot:GetAttribute("Owner") == 0 then
			plot:SetAttribute("Owner", tonumber(player.UserId))
			plot:WaitForChild("Sign"):WaitForChild("Sign"):WaitForChild("Ui"):WaitForChild("Text").Text = player.DisplayName.."'s Plot"
			
			local spawnPoint = plot:FindFirstChild("Spawn")
			if not spawnPoint then return plot
				else HRP.CFrame = spawnPoint.CFrame + Vector3.new(0,5,0)
				end
	
			return plot
		end
	end
	if not isStudio then
	player:Kick("No avaliable plots were found, please rejoin!")
	end
	warn("No avaliable plots were found, please rejoin!")
end

--find a plot to assign the new user
PlotHandler.GetPlot = function(player:Player)
	for _, plot in pairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("Owner") == tonumber(player.UserId) then
			return plot
		end
	end
end

--remove all the users businesses
PlotHandler.DestroyBusinesses = function(player:Player)
	local plot = PlotHandler.GetPlot(player)
	if not plot then return end
	for _, business in pairs(plot:FindFirstChild("Businesses"):GetChildren()) do
		for _, part:Part in pairs(business:GetDescendants()) do
			
               coroutine.wrap(function()
	            if part.Name == "Origin" then
					local vfx = ReplicatedService:WaitForChild("CrackVFX"):Clone()
					vfx.Parent = part
					vfx.Position = part.Position
				end
			if part:IsA("Part") or part:IsA("BasePart") and part.Name ~= "Origin" then
				local tween = TS:Create(part, TweenInfo.new(1), {Position = part.Position - Vector3.new(0, 20, 0)})
				tween:Play()
				soundEvent:FireClient(player, sounds:WaitForChild("Demolish"))
				tween.Completed:Connect(function()
					part:Destroy()
					business:Destroy()
				end)
			end
			   end)() -- end of coroutine
		end	
end
	
	for _, purchaseSign in pairs(plot:WaitForChild("PurchaseBusinesses"):GetChildren()) do
		for _, part in pairs(purchaseSign:GetDescendants()) do
			if part:IsA("BasePart") or part:IsA("Part") then
				part.Transparency = 0
				part.CanCollide = true
				part.CanTouch = true
				part.CanQuery = true
			elseif part:IsA("SurfaceGui") then
				part.Enabled = true
			end
		end
	end
	return
end

--Remove a plot, if the user leaves the game
PlotHandler.UnassignPlot = function(UserId:number)
	for _, plot in pairs(plotsFolder:GetChildren()) do
		if plot:GetAttribute("Owner") == UserId then
			plot:SetAttribute("Owner", 0)
			plot:WaitForChild("Sign"):WaitForChild("Sign"):WaitForChild("Ui"):WaitForChild("Text").Text = "Nobody's Plot"
			
			for _, business in pairs(plot:FindFirstChild("Businesses"):GetChildren()) do
				business:Destroy()
			end

			for _, purchaseSign in pairs(plot:WaitForChild("PurchaseBusinesses"):GetChildren()) do
				for _, part in pairs(purchaseSign:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("Part") then
						part.Transparency = 0
						part.CanCollide = true
						part.CanTouch = true
						part.CanQuery = true
					elseif part:IsA("SurfaceGui") then
						part.Enabled = true
					end
				end
			end
			return
			else continue
		end
	end
end

PlotHandler.hasGui = function(part)
	return part:FindFirstChildOfClass("SurfaceGui")
		or part:FindFirstChildOfClass("BillboardGui")
end

--tweens the build into the correct place, rotates around the origin part
PlotHandler.TweenBuild = function(build:Part, player)
	local PartPositions = {}
	local origin = build:FindFirstChild("Origin")
	
	if not origin then
		for _, part in pairs(build:GetDescendants()) do
			if (part:IsA("BasePart") or part:IsA("Part")) and not part:FindFirstChild("BillboardGui") and part.Name ~= "Origin" then
				part.Transparency = 0
				part.CanCollide = true
				part.CanTouch = true
				elseif part:IsA("SurfaceGui") or part:IsA("BillboardGui") then
				part.Enabled = true
				end
		end
		return
	end
	
	for _, Part:Part in pairs(build:GetDescendants()) do
		if (Part:IsA("BasePart") or Part:IsA("Part")) and not Part:FindFirstChild("BillboardGui") and Part.Name ~= "Origin" then
   		coroutine.wrap(function()
			Part.CanCollide = true
			Part.Transparency = 0
			Part.CanTouch = true

	
			--[[local particleEmitter = ReplicatedService:WaitForChild("Smoke"):Clone()
				particleEmitter.Parent = Part--]]
				
			local highlight = Instance.new("Highlight", Part)
			highlight.FillColor = Color3.fromRGB(255,255,255)
			highlight.FillTransparency = 0.75
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			
		
			
			
			local cframeToReach = Part.Position
			local tween = TS:Create(Part, TweenInfo.new(0.4, Enum.EasingStyle.Back), {Position = cframeToReach})
			Part.Position = Vector3.new(Part.Position.X, origin.Position.Y + 5, Part.Position.Z)
			tween:Play()
			soundEvent:FireClient(player, sounds:WaitForChild("Build"))
			wait(1)
			local highlightTween = TS:Create(highlight, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {FillTransparency = 1, OutlineTransparency = 1})

			--[[task.delay(0.2,function()
			particleEmitter:Destroy()
			end)--]]
			
			highlightTween:Play()
			highlightTween.Completed:Connect(function()
			highlight:Destroy()
				end)
			end)()
		elseif Part:IsA("SurfaceGui") or Part:IsA("BillboardGui") then
			Part.Enabled = true 
		end
	end
	
end

--build system to handle the tweening of the builds
PlotHandler.AwardBuild = function(player:Player, Build:string, plot)
	if not plot then return end
	
	local avaliableBusinesses = plot:FindFirstChild("AvaliableBusinesses")
	local newBusiness = avaliableBusinesses:FindFirstChild(Build)
	if not newBusiness then return end
	newBusiness = newBusiness:Clone()
	
	newBusiness.Parent = plot:WaitForChild("Businesses")
	local businessSign = plot:WaitForChild("PurchaseBusinesses"):WaitForChild(Build)
	
	local UpgradeSign = newBusiness:WaitForChild("Buttons"):WaitForChild("Upgrader"):WaitForChild("Sign"):WaitForChild("Ui")
	local Level = UpgradeSign:WaitForChild("Level")
	local Title = UpgradeSign:WaitForChild("Title")
	local Purchase = UpgradeSign:WaitForChild("PurchaseUpgrade")
	local Cost = Purchase:WaitForChild("Cost")
	Level.Text = "1 > 2"
	Title.Text = "LEVEL 1"
	Cost.Text = formatModule.Finalize("¢"..formatModule.Finalize(settingsModule.BusinessUpgrades[Build]))
	newBusiness:WaitForChild("Values"):WaitForChild("Upgrade").Value = 1

	
	for _, part in pairs(businessSign:GetDescendants()) do
		if part:IsA("BasePart") or part:IsA("Part") then
			part.Transparency = 1
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
		elseif part:IsA("SurfaceGui") then
			part.Enabled = false
		end
	end

	PlotHandler.TweenBuild(newBusiness, player)
	return newBusiness
end

PlotHandler.DetectRebirthCost = function(player:Player)
	local playerValues = player:WaitForChild("Values")
	local Locations = playerValues:WaitForChild("Locations")

repeat wait() until Locations.Value >= 1
	local baseCost = settingsModule.RebirthCost

	--local cost = baseCost * (2 ^ (Locations.Value -1))--2 = rebirth boost
	--cost = math.round(cost * (1.4 ^ (Locations.Value - 1)))

local cost 
	cost = (baseCost * Locations.Value) + ((Locations.Value - 1) * 500000)
if Locations.Value == 1 then
	cost = baseCost
end
	cost = math.round(cost)

		return cost
end

PlotHandler.DetectRebirthMultiplier = function(player:Player)
	local playerValues = player:WaitForChild("Values")
	local Locations = playerValues:WaitForChild("Locations")

	local multiplier 
		multiplier = (Locations.Value) + 1
	if Locations.Value == 1 then
		multiplier = 1
	end
	
	return multiplier
end

--check if they own every single mini business
PlotHandler.CheckIfUserOwnsAll = function(player:Player)
	local plot = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local avaliableBusinesses = plot:FindFirstChild("AvaliableBusinesses")
	local playerBusinesses = plot:WaitForChild("Businesses")
	local numBuildings = 0
	
	for _,Building:Part in pairs(avaliableBusinesses:GetChildren()) do
		numBuildings += 1
	end
	
	for _,Building:Part in pairs(playerBusinesses:GetChildren()) do
		numBuildings -= 1
	end
	if numBuildings == 0 then
		return true
	else
		return false
	end
end

--rebirth function to multiply the users income
PlotHandler.Rebirth = function(player:Player)
	local plot = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local businessFolder = plot:WaitForChild("Businesses")
	
	local playerValues = player:WaitForChild("Values")
	local Locations = playerValues:WaitForChild("Locations")
	local Cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	
	local baseCost = settingsModule.RebirthCost
	
	local cost = PlotHandler.DetectRebirthCost(player)

if not PlotHandler.CheckIfUserOwnsAll(player) then return end
		
		if Cash.Value >= cost then
		PlotHandler.DestroyBusinesses(player)
		Cash.Value = 0
		Locations.Value += 1
		
		cost = baseCost * (2 ^ (Locations.Value))
		return cost
		end
end


--detects how much money each upgrade will cost, checking the other upgrades to calculate the new sum
PlotHandler.DetectUpgradeCost = function(player: Player, business: string)
	local plot: Part = PlotHandler.GetPlot(player)
	if not plot then return end

	local businessFolder = plot:FindFirstChild("Businesses")
	if not businessFolder then return end

	local businessModel = businessFolder:FindFirstChild(business)
	if not businessModel then return end

	local values = businessModel:WaitForChild("Values")
	local upgrade = values:WaitForChild("Upgrade")

	local startingUpgrade = settingsModule.BusinessUpgrades[business]
	
	local cost 
		cost = math.round(startingUpgrade * (settingsModule.PriceIncrease ^ (upgrade.Value - 1))*100)/100
		

	if upgrade.Value <= 1 then
		upgrade.Value = 1
		cost = startingUpgrade
	end

	if cost > 999 then
		cost = math.floor(cost)
	else
		cost = math.round(cost * 100) / 100
	end

	return cost
end

--check how much the business earns with the correct upgrade amount
PlotHandler.DetectEarnings = function(player: Player, business: string)
	local plot: Part = PlotHandler.GetPlot(player)
	if not plot then return end

	local businessesFolder = plot:FindFirstChild("Businesses")
	if not businessesFolder then return end

	local businessModel = businessesFolder:FindFirstChild(business)
	if not businessModel then return end

	local values = businessModel:WaitForChild("Values")
	local upgrade = values:WaitForChild("Upgrade")

	local startingEarnings = settingsModule.BusinessEarnings[business]

	local earningsGrowth = settingsModule.EarningsIncrease

	local earnings
	

local rebirthMulti = PlotHandler.DetectRebirthMultiplier(player)

local owns2X = player:WaitForChild("Values"):WaitForChild("Owns2x")

	if upgrade.Value <= 1 then
		upgrade.Value = 1
		earnings = startingEarnings
	else
		earnings = startingEarnings * upgrade.Value * (earningsGrowth ^ (upgrade.Value - 1))
	end

	if earnings * rebirthMulti > 999 then
		earnings = math.floor(earnings) * rebirthMulti
	else
		earnings = (math.round(earnings * 100) / 100) * rebirthMulti
	end
	
	if owns2X.Value == true then
		if earnings * 2 > 999 then
			earnings = math.floor(earnings * 2)
		else
			earnings = (math.round(earnings * 2 * 100) / 100)
		end
	end

	return earnings
end


--detects the time needed to work the business, with the correct upgrade amount
PlotHandler.DetectTime = function(player: Player, business: string)
	local plot: Part = PlotHandler.GetPlot(player)
	if not plot then return end

	local businessesFolder = plot:FindFirstChild("Businesses")
	if not businessesFolder then return end

	local businessModel = businessesFolder:FindFirstChild(business)
	if not businessModel then return end

	local values = businessModel:WaitForChild("Values")
	local upgrade = values:WaitForChild("Upgrade")

	local startingTime = settingsModule.BusinessTimes[tostring(business)]
	local businessInterval = settingsModule.BuildingInvertals[tostring(business)]

	local newTime =	math.round((startingTime - (upgrade.Value * businessInterval)) * 10) / 10
	
	if upgrade.Value == 1  then
		newTime = startingTime
	end

	if newTime < 0.1 then
		newTime = math.round(businessInterval * 10) / 10
	end

	return newTime
end

--runs the auto work function with the workers
PlotHandler.SetupWorker = function(player:Player, business:string)
	local plot:Part = PlotHandler.GetPlot(player)
	if not plot then return end

	local buinessFolder = plot:WaitForChild("Businesses")
	local businessModel = buinessFolder:WaitForChild(business)
	local values = businessModel:WaitForChild("Values")
	local buttons = businessModel:WaitForChild("Buttons")
	local collectPad = buttons:WaitForChild("Earn"):WaitForChild("CollectPad")
	local WorkerButton = buttons:WaitForChild("Upgrader"):WaitForChild("Worker")

	values:WaitForChild("HasWorker").Value = true	
	collectPad:SetAttribute("Touched", true) --Can't step on it
	
	local tween = TS:Create(WorkerButton, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = Vector3.new(0,0,0)})
	WorkerButton:WaitForChild("Ui").Enabled = false
	tween:Play()
	tween.Completed:Connect(function()
		WorkerButton:Destroy()
		end)

	local tries = 0
	repeat tries += 1 wait() until businessModel:GetAttribute("IsWorking") == false

	while business and player do
		if tries > 1 then
			task.wait(0.35)
		end
		PlotHandler.WorkBusiness(player, business, true)
		task.wait(0.35)
		tries = 0
	end
end

--purchase a worker for the business
PlotHandler.PurchaseWorker = function(player:Player, business:string)
	local plot:Part = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local buinessFolder = plot:WaitForChild("Businesses")
	local businessModel = buinessFolder:WaitForChild(business)
	
	
	local playerCash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	local workerCost = settingsModule.WorkerCosts[tostring(business)]
	
	if playerCash.Value < workerCost then
		return
	end
	
	playerCash.Value -= workerCost
	
	notificationModule.PlayerNotification(player, "You have received a worker for your "..tostring(business).."!", 5, settingsModule.GreenNotification)
	PlotHandler.SetupWorker(player, business)
end	

--run the business and then award the user the correct money sum, adds a debounce to not allow the user to run multiple tasks
PlotHandler.WorkBusiness = function(player:Player, business:string, isWorker:BoolValue)
	local plot:Part = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local Cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	
	local buinessFolder = plot:FindFirstChild("Businesses")
	local businessModel = buinessFolder:FindFirstChild(business)
	if not businessModel then return end
	local values = businessModel:WaitForChild("Values")
	local upgrade = values:WaitForChild("Upgrade")
	local buttons = businessModel:WaitForChild("Buttons")
	local collectPad = buttons:FindFirstChild("Earn"):FindFirstChild("CollectPad")
	if not collectPad then return end
	
	local cancelled = false
	
	if isWorker then collectPad.CanTouch = false end
	
	collectPad:SetAttribute("Touched", true)
	collectPad:SetAttribute("PauseWork", false)
	
	
	local earningsText = collectPad:WaitForChild("Ui"):WaitForChild("Earnings"):WaitForChild("Earnings")
	local Tweener:Frame = earningsText.Parent:WaitForChild("Tween")
	
	local startingTime = settingsModule.BusinessTimes[tostring(business)]
	local businessInvertal = settingsModule.BuildingInvertals[tostring(business)]
	
	local businessEarnings = PlotHandler.DetectEarnings(player, business)
	local newTime = PlotHandler.DetectTime(player, business)

--do countdown

	
	local tweenIn = TS:Create(Tweener, TweenInfo.new(newTime,Enum.EasingStyle.Sine), {Size = UDim2.new(1,0,1,0)})
	local tweenOut = TS:Create(Tweener, TweenInfo.new(0.35,Enum.EasingStyle.Sine), {Size = UDim2.new(0,0,1,0)})
	
	task.spawn(function()
		tweenIn:Play()
	end)
	
	local proximityPrompt 
	proximityPrompt = Instance.new("ProximityPrompt", collectPad)
	proximityPrompt.ObjectText = "Stop Working"
	proximityPrompt.HoldDuration = 1
	
	if newTime >= 5 then
	proximityPrompt.MaxActivationDistance = 7
	else 
		proximityPrompt.MaxActivationDistance = 0
	end
	
	proximityPrompt.Triggered:Connect(function(player)
		if plot:GetAttribute("Owner") == player.UserId then
			collectPad:SetAttribute("PauseWork", true)
			end
	end)
	
	businessModel:SetAttribute("IsWorking", true)
	
for i = newTime, 0, -0.1 do
	task.wait(0.1)
	if not businessModel or not businessModel.Parent then cancelled = true 
		break
	end		
	
	if not player or not player.Parent then cancelled = true
		break
	end
	
		--detect if paused
	if collectPad:GetAttribute("PauseWork") then
			proximityPrompt:Destroy()
		   tweenOut:Play()
			newTime = PlotHandler.DetectTime(player, business)
			businessEarnings = PlotHandler.DetectEarnings(player, business)
			earningsText.Text = "¢" .. formatModule.Finalize(businessEarnings) .. "/" ..newTime.."s"
				collectPad:SetAttribute("Touched", false)
			collectPad:SetAttribute("PauseWork", false) 
			businessModel:SetAttribute("IsWorking", false)
		return end
	
	earningsText.Text = "¢" .. formatModule.Finalize(businessEarnings) .. "/" ..(math.round(i*10)/10).."s"
end

	if cancelled then
		proximityPrompt:Destroy()
		collectPad:SetAttribute("Touched", false) 	
		businessModel:SetAttribute("IsWorking", false)
		return
	end

if newTime >= 5 and not isWorker then
		notificationModule.PlayerNotification(player, "You have received ¢"..formatModule.Finalize(businessEarnings).."!", 5, settingsModule.GreenNotification)
end

proximityPrompt:Destroy()

	Cash.Value += businessEarnings
	
	if not isWorker then
	soundEvent:FireClient(player, sounds:WaitForChild("money"))
	end
	
	newTime = PlotHandler.DetectTime(player, business)
	businessEarnings = PlotHandler.DetectEarnings(player, business)
	
	earningsText.Text = "¢" .. formatModule.Finalize(businessEarnings) .. "/" ..newTime.."s"
	if not isWorker then
	PlotHandler.DoMoneyEffect(player,7)
	end
	   
		collectPad:SetAttribute("Touched", false) 	
	businessModel:SetAttribute("IsWorking", false)


	
	tweenOut:Play()
end

--collect the earnings from the business, not currently in use
PlotHandler.CollectEarnings = function(player, business:string)
	local plot = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local business = plot:FindFirstChild("Businesses"):FindFirstChild(business)
	if not business then return end
	
	local values = business:WaitForChild("Values")
	local earnings = values:WaitForChild("Earnings")
	
	if earnings.Value >= 0 then
		local playerCash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
		
		playerCash.Value += earnings.Value
		earnings.Value = 0
	end
end


--Awards the user the business once they purchase it, plays a sound and money animation, if they cant it will notify them saying they can't
PlotHandler.PurchaseBusiness = function(player, business:string)
	local plot = PlotHandler.GetPlot(player)
	if not plot then return end
	
	local plotBusinesses = plot:FindFirstChild("Businesses")
	local existingBusiness = plotBusinesses:FindFirstChild(business)
	if existingBusiness then return end --already own
	
	local playerCash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	local cost = settingsModule.BusinessCosts[business]
	if not cost then return end
	
	if playerCash.Value < cost then
		soundEvent:FireClient(player, sounds:WaitForChild("Error")) 
		notificationModule.PlayerNotification(player, "You can't afford this!", 4, Color3.fromRGB(255, 11, 11), true) 
		return end
	
	playerCash.Value -= cost
	soundEvent:FireClient(player, sounds:WaitForChild("money"))
	PlotHandler.AwardBuild(player, business, plot)
	
	local businessEarnings = PlotHandler.DetectEarnings(player, business)
	local timePerEarn = PlotHandler.DetectTime(player, business)
	
	local collectPad = plotBusinesses:WaitForChild(business):WaitForChild("Buttons"):WaitForChild("Earn"):WaitForChild("CollectPad"):WaitForChild("Ui"):WaitForChild("Earnings")
	collectPad:WaitForChild("Earnings").Text = "¢"..formatModule.Finalize(businessEarnings).."/"..timePerEarn.."s"
	
	
PlotHandler.DoMoneyEffect(player)
end

--Function that upgrades the player's mini business
PlotHandler.UpgradeBusiness = function(player:Player, business:Model)
	local playerPlot = PlotHandler.GetPlot(player)
	local values = playerPlot:WaitForChild("Businesses"):FindFirstChild(business.Name):WaitForChild("Values")
	local Cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")
	local startingUpgrade = tonumber(settingsModule.BusinessUpgrades[business.Name])
	local UpgradeSign = business:WaitForChild("Buttons"):WaitForChild("Upgrader"):WaitForChild("Sign"):WaitForChild("Ui")
	local LevelText = UpgradeSign:WaitForChild("Level")
	local Purchase = UpgradeSign:WaitForChild("PurchaseUpgrade")
	local CostText = Purchase:WaitForChild("Cost")
	local titleText = UpgradeSign:WaitForChild("Title")
	if not startingUpgrade then return end
	
   local collectPad = values.Parent.Buttons:FindFirstChild("Earn"):FindFirstChild("CollectPad")
	local earningsText = collectPad:WaitForChild("Ui"):WaitForChild("Earnings"):WaitForChild("Earnings")

	local startingEarnings = settingsModule.BusinessEarnings[tostring(business)]


	
	

local cost = PlotHandler.DetectUpgradeCost(player, business.Name)
	
	if Cash.Value >= cost and values.Upgrade.Value < 100 then
		local newUpgrade = values.Upgrade.Value + 1
		Cash.Value -= cost
		soundEvent:FireClient(player, sounds:WaitForChild("money"))
		PlotHandler.DoMoneyEffect(player, 8)
		
		values.Upgrade.Value = newUpgrade	
		cost = PlotHandler.DetectUpgradeCost(player, business.Name)
	
		
		if not business:GetAttribute("IsWorking") then
			local timePerEarn = PlotHandler.DetectTime(player, tostring(business.Name))
			local businessEarnings = PlotHandler.DetectEarnings(player, tostring(business.Name))
			earningsText.Text = "¢"..formatModule.Finalize(businessEarnings).."/"..timePerEarn.."s"
		end


		if newUpgrade < 100 then
		CostText.Text = "¢"..formatModule.Finalize(cost)
		LevelText.Text = values.Upgrade.Value.." > "..(newUpgrade + 1)
		titleText.Text = "LEVEL "..newUpgrade
		else
			CostText.Text = "Max"
			LevelText.Text = "100 < 100"
			titleText.Text = "LEVEL 100"
		end
	else
		soundEvent:FireClient(player, sounds:WaitForChild("Error"))
	end
end

return PlotHandler

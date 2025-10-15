if not game:IsLoaded() then game.Loaded:Wait() end
local Notifier = {}
Notifier.__index = Notifier

function Notifier.new(title, text, duration)
	local self = setmetatable({}, Notifier)
	self.title = title or "Notification"
	self.text = text or ""
	self.duration = duration or 3
	return self
end

function Notifier:Show()
	if game:GetService("StarterGui") then
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = self.title;
			Text = self.text;
			Duration = self.duration;
		})
	end
end

local notification = Notifier.new("Velo V1", "Script carregado com sucesso \n luni, qualquer bug fala pra mim", 5)
notification:Show()


local success, Players = pcall(function() return game:GetService("Players") end)
if not success or not Players then
	game:Kick("Falha ao obter Players")
end

local success2, RunService = pcall(function() return game:GetService("RunService") end)
if not success2 or not RunService then
	game:Kick("Falha ao obter RunService")
end

local success3, player = pcall(function() return Players.LocalPlayer end)
if not success3 or not player then
	game:Kick("Falha ao obter LocalPlayer")
end

local success4, _character = pcall(function()
	return player.Character or player.CharacterAdded:Wait()
end)
if not success4 or not _character then
	game:Kick("Falha ao obter Character")
end

local Vehicles = workspace:FindFirstChild("Vehicles")
local maxSpeeds = {}
local playerBillboards = {}
local lastUpdate = 0


local function getPlayerCharacter(targetPlayer)
	return targetPlayer.Character or targetPlayer.CharacterAdded:Wait()
end


local function createPlayerBillboard(targetPlayer)
	if playerBillboards[targetPlayer.Name] then
		return playerBillboards[targetPlayer.Name]
	end

	local character = getPlayerCharacter(targetPlayer)
	local head = character:WaitForChild("Head")

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Size = UDim2.new(0, 100, 0, 50)
	billboardGui.StudsOffset = Vector3.new(0, 3, 0)
	billboardGui.Adornee = head
	billboardGui.AlwaysOnTop = true
	billboardGui.Name = "MaxSpeedDisplay"
	billboardGui.Parent = head

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Text = "MaxSpeed: 0"
	label.BorderSizePixel = 0
	label.Parent = billboardGui

	playerBillboards[targetPlayer.Name] = label
	return label
end

local function removePlayerBillboard(targetPlayer)
	local playerName = targetPlayer and targetPlayer.Name
	if not playerName then return end

	local label = playerBillboards[playerName]
	if label then
		local parent = label.Parent
		if parent and parent:IsA("GuiBase2d") or parent:IsA("BillboardGui") then
			parent:Destroy()
		end
		playerBillboards[playerName] = nil
	end
end


local function getSeatedPlayerFromHumanoid(humanoid)
	if not humanoid then return nil end
	local character = humanoid.Parent
	if not character then return nil end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character == character then
			return player
		end
	end
	return nil
end

local function clearPlayerMaxSpeeds(playerName)
	for key, _ in pairs(maxSpeeds) do
		local nameFromKey = key:match("Car:.+:(.+)")
		if nameFromKey == playerName then
			maxSpeeds[key] = nil
		end
	end
end

local function updateAllPlayersMaxSpeeds()
	if not Vehicles then return end

	local now = os.clock()
	if now - lastUpdate < 1 then return end
	lastUpdate = now


	for playerName, _ in pairs(playerBillboards) do
		local playerObj = Players:FindFirstChild(playerName)
		if playerObj and playerObj.Character then
			local humanoid = playerObj.Character:FindFirstChildOfClass("Humanoid")
			if not humanoid or not humanoid.SeatPart then
				removePlayerBillboard(playerObj)
				clearPlayerMaxSpeeds(playerName)
			end
		end
	end


	for _, car in ipairs(Vehicles:GetChildren()) do
		if not car.Name:match("Car$") then
			continue
		end

		local seatsFolder = car:FindFirstChild("Seats")
		if not seatsFolder then
			continue
		end

		local vehicleSeat = seatsFolder:FindFirstChildWhichIsA("VehicleSeat")
		if not vehicleSeat then
			continue
		end

		local occupant = vehicleSeat.Occupant
		if not occupant then
			continue
		end

		local seatedPlayer = getSeatedPlayerFromHumanoid(occupant)
		if not seatedPlayer or occupant.SeatPart ~= vehicleSeat then
			if seatedPlayer then
				local key = ("Car:%s:%s"):format(car.Name, seatedPlayer.Name)
				maxSpeeds[key] = nil
				removePlayerBillboard(seatedPlayer)
			end
			continue
		end

		local maxSpeedObj = vehicleSeat:FindFirstChild("MaxSpeed")
		if not (maxSpeedObj and maxSpeedObj:IsA("NumberValue")) then
			continue
		end

		local maxSpeed = maxSpeedObj.Value
		if not maxSpeed then
			continue
		end

		local key = ("Car:%s:%s"):format(car.Name, seatedPlayer.Name)
		maxSpeeds[key] = maxSpeed

		local label = createPlayerBillboard(seatedPlayer)
		if label then
			label.Text = string.format("MaxSpeed: %d", maxSpeed)
		end
	end
end


local function cleanupOfflinePlayers()

	local keysToRemove = {}

	for key in pairs(maxSpeeds) do
		local playerName = key:match("^Car:.-:(.+)$")
		if playerName and not Players:FindFirstChild(playerName) then
			table.insert(keysToRemove, { key = key, playerName = playerName })
		end
	end

	for _, entry in ipairs(keysToRemove) do
		maxSpeeds[entry.key] = nil

		removePlayerBillboard({ Name = entry.playerName })
	end
end



local function GetOtherPlayersCarMaxSpeeds()
	local speedsSnapshot = {}
	for key, speed in pairs(maxSpeeds) do
		speedsSnapshot[key] = speed
	end
	return speedsSnapshot
end


_GetOtherPlayersCarMaxSpeeds = GetOtherPlayersCarMaxSpeeds


function _DebugMaxSpeeds()
	print("=== DEBUG MAXSPEEDS ===")
	for key, maxSpeed in pairs(maxSpeeds) do
		print(string.format("Key: %s | MaxSpeed: %d", key, maxSpeed))
	end
	print("=== DEBUG PLAYER BILLBOARDS ===")
	for playerName, _ in pairs(playerBillboards) do
		print(string.format("Player: %s tem billboard", playerName))
	end
	print("========================")
end


RunService.Heartbeat:Connect(function()
	updateAllPlayersMaxSpeeds()
	cleanupOfflinePlayers()
end)

Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(2)
	updateAllPlayersMaxSpeeds()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)

	removePlayerBillboard(leavingPlayer)


	local keysToRemove = {}


	for key in pairs(maxSpeeds) do
		local playerName = key:match("^Car:.-:(.+)$")
		if playerName == leavingPlayer.Name then
			table.insert(keysToRemove, key)
		end
	end


	for _, key in ipairs(keysToRemove) do
		maxSpeeds[key] = nil
	end
end)

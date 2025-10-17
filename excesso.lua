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

local notificationsToShow = {
	{title = "Velo V1", text = "Script carregado com sucesso. \n Luni, qualquer bug fala pra mim", duration = 2},
	{title = "Controles", text = "Pressione 'L' para alternar visibilidade do rastreio\nPressione 'K' para mostrar log de velocidades", duration = 3}
}

for _, notif in ipairs(notificationsToShow) do
	local notificationInstance = Notifier.new(notif.title, notif.text, notif.duration)
	notificationInstance:Show()
end


local success, Players = pcall(function() return game:GetService("Players") end)
if not success or not Players then
	error("Falha ao obter Players")
end

local success2, RunService = pcall(function() return game:GetService("RunService") end)
if not success2 or not RunService then
	error("Falha ao obter RunService")
end

local success5, UserInputService = pcall(function() return game:GetService("UserInputService") end)
if not success5 or not UserInputService then
	error("Falha ao obter UserInputService")
end

local success3, player = pcall(function() return Players.LocalPlayer end)
if not success3 or not player then
	error("Falha ao obter LocalPlayer")
end

local success4, _character = pcall(function()
	return player.Character or player.CharacterAdded:Wait()
end)
if not success4 or not _character then
	error("Falha ao obter Character")
end

local function makeFrameDraggable(frame)
    local dragging = false
    local dragInput, mousePos, framePos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            frame.Position = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
        end
    end)
end

local Vehicles = workspace:FindFirstChild("Vehicles")
local maxSpeeds = {}
local playerBillboards = {}
local lastUpdate = 0
local billboardsVisible = true
local TOGGLE_BILLBOARD_KEY = Enum.KeyCode.L
local LOG_KEY = Enum.KeyCode.K
local lastSpeedAlert = {}
local speedHistory = {} 

local function createSessionVeloGui()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SessionVeloGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "MainFrame"
	frame.Parent = screenGui
	frame.BackgroundColor3 = Color3.fromRGB(18, 32, 39)
	frame.BorderColor3 = Color3.fromRGB(42, 99, 132)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.new(0.7, 0, 0.35, 0)
	frame.Size = UDim2.new(0, 340, 0, 196)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.ClipsDescendants = true
	frame.BackgroundTransparency = 0.05
	frame.Active = true

	
	local topbar = Instance.new("Frame")
	topbar.Name = "TopBar"
	topbar.Parent = frame
	topbar.BackgroundColor3 = Color3.fromRGB(28, 55, 70)
	topbar.Size = UDim2.new(1, 0, 0, 38)
	topbar.BorderSizePixel = 0



	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Header"
	textLabel.Parent = topbar
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.new(0, 45, 0, 0)
	textLabel.Size = UDim2.new(1, -45, 1, 0)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.Text = "VELOCIDADE DA SESSÃO"
	textLabel.TextColor3 = Color3.fromRGB(199, 235, 255)
	textLabel.TextScaled = true
	textLabel.TextStrokeTransparency = 0.7

	
	local inputBg = Instance.new("Frame")
	inputBg.Parent = frame
	inputBg.Name = "InputBackground"
	inputBg.BackgroundColor3 = Color3.fromRGB(42, 99, 132)
	inputBg.Position = UDim2.new(0.08, 0, 0.31, 0)
	inputBg.Size = UDim2.new(0.84, 0, 0.52, 0)
	inputBg.BackgroundTransparency = 0.2
	inputBg.BorderSizePixel = 0
	inputBg.ClipsDescendants = true
	inputBg.AnchorPoint = Vector2.new(0, 0)
	inputBg.ZIndex = 2

	local textBox = Instance.new("TextBox")
	textBox.Name = "SpeedInput"
	textBox.Parent = inputBg
	textBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextTransparency = 0
	textBox.BorderSizePixel = 0
	textBox.Position = UDim2.new(0.03, 0, 0.2, 0)
	textBox.Size = UDim2.new(0.94, 0, 0.6, 0)
	textBox.Font = Enum.Font.Gotham
	textBox.Text = ""
	textBox.TextColor3 = Color3.fromRGB(13, 36, 53)
	textBox.PlaceholderText = ""
	textBox.PlaceholderColor3 = Color3.fromRGB(170, 210, 227)
	textBox.TextSize = 26
	textBox.ClearTextOnFocus = false
	textBox.ZIndex = 3

	
	local underline = Instance.new("Frame")
	underline.Parent = textBox
	underline.BackgroundColor3 = Color3.fromRGB(42, 99, 132)
	underline.BorderSizePixel = 0
	underline.Position = UDim2.new(0, 0, 1, -4)
	underline.Size = UDim2.new(1, 0, 0, 4)
	underline.ZIndex = 3

	
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Parent = frame
	shadow.BackgroundTransparency = 1
	shadow.Position = UDim2.new(0, -8, 0, -8)
	shadow.Size = UDim2.new(1, 16, 1, 16)
	shadow.ZIndex = 0
	shadow.Image = "rbxassetid://1316045217"
	shadow.ImageTransparency = 0.85

	return {
		ScreenGui = screenGui,
		Frame = frame,
		TextBox = textBox,
		TextLabel = textLabel
	}
end

local guiElements = createSessionVeloGui()
makeFrameDraggable(guiElements.Frame)


local historyGui = nil

local function createHistoryGui()
	if historyGui then
		historyGui:Destroy()
	end
	
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SpeedHistoryGui"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "HistoryFrame"
	frame.Parent = screenGui
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BorderColor3 = Color3.fromRGB(100, 100, 100)
	frame.BorderSizePixel = 2
	frame.Position = UDim2.new(0.1, 0, 0.1, 0)
	frame.Size = UDim2.new(0, 500, 0, 400)

	
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Parent = frame
	titleLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	titleLabel.BorderSizePixel = 0
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.Size = UDim2.new(1, 0, 0, 30)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.Text = "📋 HISTÓRICO DE VELOCIDADES - F1B"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true

	
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Parent = frame
	closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeButton.BorderSizePixel = 0
	closeButton.Position = UDim2.new(1, -30, 0, 5)
	closeButton.Size = UDim2.new(0, 25, 0, 20)
	closeButton.Font = Enum.Font.SourceSansBold
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true

	
	local scrollingFrame = Instance.new("ScrollingFrame")
	scrollingFrame.Name = "HistoryScroll"
	scrollingFrame.Parent = frame
	scrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	scrollingFrame.BorderSizePixel = 0
	scrollingFrame.Position = UDim2.new(0, 5, 0, 35)
	scrollingFrame.Size = UDim2.new(1, -10, 1, -40)
	scrollingFrame.ScrollBarThickness = 8
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

	
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = scrollingFrame
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 2)

	historyGui = {
		ScreenGui = screenGui,
		Frame = frame,
		ScrollingFrame = scrollingFrame,
		CloseButton = closeButton
	}

	
	makeFrameDraggable(frame)

	
	closeButton.MouseButton1Click:Connect(function()
		screenGui:Destroy()
		historyGui = nil
	end)

	return historyGui
end

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
	billboardGui.Enabled = billboardsVisible
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
		if parent and (parent:IsA("GuiBase2d") or parent:IsA("BillboardGui")) then
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

local function addToSpeedHistory(playerName, maxSpeed)
	local now = os.time()
	local timeStr = os.date("%H:%M:%S", now)
	
	
	table.insert(speedHistory, {
		playerName = playerName,
		maxSpeed = maxSpeed,
		timestamp = timeStr,
		time = now
	})
	
	
	if #speedHistory > 100 then
		table.remove(speedHistory, 1)
	end
end

local function checkSpeedLimit(playerName, maxSpeed)
	local speedInputText = guiElements.TextBox.Text
	if speedInputText == "" or speedInputText == nil then
		return
	end
	
	
	local speedLimit = tonumber(speedInputText)
	if not speedLimit then
		return 
	end
	
	
	if maxSpeed > speedLimit then
	
		local now = os.clock()
		local lastAlert = lastSpeedAlert[playerName] or 0
		
		if (now - lastAlert) > 1 then 
			lastSpeedAlert[playerName] = now
			
			
			local notification = Notifier.new(
				"⚠️ ALERTA DE VELOCIDADE",
				string.format("Player %s ultrapassou o limite!\nVelocidade: %.2f (Limite: %.2f)", 
					playerName, maxSpeed, speedLimit),
				4
			)
			notification:Show()
		end
	end
end

local function updateHistoryGui()
	if not historyGui or not historyGui.ScreenGui.Enabled then
		return
	end
	
	
	for _, child in ipairs(historyGui.ScrollingFrame:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	
	if #speedHistory == 0 then
		
		local noDataLabel = Instance.new("TextLabel")
		noDataLabel.Parent = historyGui.ScrollingFrame
		noDataLabel.BackgroundTransparency = 1
		noDataLabel.Size = UDim2.new(1, 0, 0, 20)
		noDataLabel.Font = Enum.Font.SourceSans
		noDataLabel.Text = "Nenhuma velocidade registrada ainda."
		noDataLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
		noDataLabel.TextScaled = true
	else
		
		for i, entry in ipairs(speedHistory) do
			local playerObj = Players:FindFirstChild(entry.playerName)
			local displayName = playerObj and (playerObj.DisplayName or entry.playerName) or entry.playerName
			
			local entryLabel = Instance.new("TextLabel")
			entryLabel.Parent = historyGui.ScrollingFrame
			entryLabel.BackgroundColor3 = i % 2 == 0 and Color3.fromRGB(40, 40, 40) or Color3.fromRGB(30, 30, 30)
			entryLabel.BorderSizePixel = 0
			entryLabel.Size = UDim2.new(1, 0, 0, 25)
			entryLabel.Font = Enum.Font.SourceSans
			entryLabel.Text = string.format("  [%s] %s: %.2f", 
				entry.timestamp, displayName, entry.maxSpeed)
			entryLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			entryLabel.TextXAlignment = Enum.TextXAlignment.Left
			entryLabel.TextScaled = true
		end
		
		
		historyGui.ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, #speedHistory * 27)
	end
end

local function showSpeedLog()
	
	if not historyGui then
		createHistoryGui()
	end
	
	
	updateHistoryGui()
	
	
	historyGui.ScreenGui.Enabled = true
end

local function toggleBillboardsVisibility()
	billboardsVisible = not billboardsVisible

	for _, label in pairs(playerBillboards) do
		if label and label.Parent and label.Parent:IsA("BillboardGui") then
			label.Parent.Enabled = billboardsVisible
		end
	end

	local statusMsg = billboardsVisible and "On" or "Off"
	Notifier.new("Script", ("Status %s"):format(statusMsg), 2):Show()
end

local function updateAllPlayersMaxSpeeds()
	if not Vehicles then return end

	local now = os.clock()
	if (now - lastUpdate) < 1 then return end
	lastUpdate = now

	for playerName in pairs(playerBillboards) do
		local playerObj = Players:FindFirstChild(playerName)
		if playerObj and playerObj.Character then
			local humanoid = playerObj.Character:FindFirstChildOfClass("Humanoid")
			if not (humanoid and humanoid.SeatPart) then
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
				local key = string.format("Car:%s:%s", car.Name, seatedPlayer.Name)
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

		local key = string.format("Car:%s:%s", car.Name, seatedPlayer.Name)
		local previousSpeed = maxSpeeds[key]
		maxSpeeds[key] = maxSpeed

		
		if not previousSpeed or previousSpeed ~= maxSpeed then
			addToSpeedHistory(seatedPlayer.Name, maxSpeed)
		end

		local label = createPlayerBillboard(seatedPlayer)
		if label then
			local displayName = seatedPlayer.DisplayName or seatedPlayer.Name
			label.Text = ("MaxSpeed : %.2f\nName: %s"):format(maxSpeed, displayName)
		end
		
		
		checkSpeedLimit(seatedPlayer.Name, maxSpeed)
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


		local tempPlayer = { Name = entry.playerName }
		removePlayerBillboard(tempPlayer)
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
		print(string.format("Key: %s | MaxSpeed: %.2f", key, maxSpeed))
	end
	print("=== DEBUG PLAYER BILLBOARDS ===")
	for playerName, _ in pairs(playerBillboards) do
		print(string.format("Player: %s tem billboard", playerName))
	end
	print("========================")
end





local function onInput(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	
	if input.KeyCode == TOGGLE_BILLBOARD_KEY then
		toggleBillboardsVisibility()
	elseif input.KeyCode == LOG_KEY then
		showSpeedLog()
	end
end

UserInputService.InputBegan:Connect(onInput)

RunService.Heartbeat:Connect(function()
	updateAllPlayersMaxSpeeds()
	cleanupOfflinePlayers()
	updateHistoryGui() 
end)

Players.PlayerAdded:Connect(function(newPlayer)
	task.wait(2)
	updateAllPlayersMaxSpeeds()
end)

Players.PlayerRemoving:Connect(function(leavingPlayer)

	removePlayerBillboard(leavingPlayer)

	lastSpeedAlert[leavingPlayer.Name] = nil

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

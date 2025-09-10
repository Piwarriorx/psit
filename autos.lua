local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

-- Default wait time
local waitTime = 40
local rejoinEnabled = true
local manualOverride = false

-- Function to check if current time is within xx:00 to xx:20 (first 20 minutes of any hour)
local function isWithinTimeframe()
    local currentTime = os.date("*t")
    return currentTime.min >= 0 and currentTime.min <= 20
end

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RejoinGui"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Create Chathead Button (draggable, black and orange theme)
local chathead = Instance.new("TextButton")
chathead.Name = "Chathead"
chathead.Size = UDim2.new(0, 50, 0, 50)
chathead.Position = UDim2.new(0, 20, 0, 70)
chathead.Text = ""
chathead.Font = Enum.Font.SourceSansBold
chathead.TextSize = 24
chathead.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black
chathead.TextColor3 = Color3.new(1,1,1)
chathead.AutoButtonColor = false
chathead.Parent = screenGui
chathead.ZIndex = 10
chathead.ClipsDescendants = true
chathead.BorderSizePixel = 0
chathead.Style = Enum.ButtonStyle.RobloxRoundButton

-- Add UICorner to make it circular
local chatheadCorner = Instance.new("UICorner")
chatheadCorner.CornerRadius = UDim.new(0.5, 0)
chatheadCorner.Parent = chathead

-- Add UIStroke for orange border
local chatheadStroke = Instance.new("UIStroke")
chatheadStroke.Color = Color3.fromRGB(255, 165, 0) -- Orange
chatheadStroke.Thickness = 2
chatheadStroke.Transparency = 0.5
chatheadStroke.Parent = chathead

-- Add an icon (simple text or image)
local chatheadIcon = Instance.new("TextLabel")
chatheadIcon.Size = UDim2.new(1, 0, 1, 0)
chatheadIcon.Position = UDim2.new(0, 0, 0, 0)
chatheadIcon.Text = "⚡"
chatheadIcon.Font = Enum.Font.SourceSansBold
chatheadIcon.TextSize = 30
chatheadIcon.TextColor3 = Color3.fromRGB(255, 165, 0) -- Orange
chatheadIcon.BackgroundTransparency = 1
chatheadIcon.Parent = chathead

-- Create Menu Frame (hidden by default, positioned relative to chathead, black and orange theme)
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MenuFrame"
menuFrame.Size = UDim2.new(0, 400, 0, 90)
menuFrame.Position = UDim2.new(0, 80, 0, 70)  -- Initial position, will be updated on drag
menuFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- Black
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = screenGui
menuFrame.ZIndex = 9
menuFrame.ClipsDescendants = true
menuFrame.BackgroundTransparency = 0.3
menuFrame.AnchorPoint = Vector2.new(0,0)
menuFrame.Active = true
menuFrame.Draggable = false

-- Add UICorner to menuFrame
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menuFrame

-- Add UIStroke to menuFrame
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(255, 165, 0) -- Orange
menuStroke.Thickness = 2
menuStroke.Transparency = 0.5
menuStroke.Parent = menuFrame

-- Create Toggle Button inside menuFrame (black and orange theme)
local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 90, 0, 30)
toggleButton.Position = UDim2.new(0, 10, 0, 20)
toggleButton.Text = rejoinEnabled and "Rejoin: ON" or "Rejoin: OFF"
toggleButton.Font = Enum.Font.SourceSans
toggleButton.TextSize = 18
toggleButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Darker Orange
toggleButton.TextColor3 = Color3.fromRGB(20, 20, 20) -- Dark text
toggleButton.Parent = menuFrame

-- Add UICorner to toggleButton
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 5)
toggleCorner.Parent = toggleButton

-- Create Input Box for wait time inside menuFrame (black and orange theme)
local waitInput = Instance.new("TextBox")
waitInput.Size = UDim2.new(0, 80, 0, 30)
waitInput.Position = UDim2.new(0, 110, 0, 20)
waitInput.PlaceholderText = "Wait (sec)"
waitInput.Text = tostring(waitTime)
waitInput.ClearTextOnFocus = false
waitInput.Font = Enum.Font.SourceSans
waitInput.TextSize = 18
waitInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Dark gray
waitInput.TextColor3 = Color3.fromRGB(255, 140, 0) -- Darker Orange
waitInput.Parent = menuFrame

-- Add UICorner to waitInput
local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = waitInput

-- Add UIStroke to waitInput
local inputStroke = Instance.new("UIStroke")
inputStroke.Color = Color3.fromRGB(255, 140, 0) -- Darker Orange
inputStroke.Thickness = 1
inputStroke.Parent = waitInput

-- Create Debug TextLabel inside menuFrame to display current waitTime (black and orange theme)
local debugLabel = Instance.new("TextLabel")
debugLabel.Size = UDim2.new(0, 150, 0, 30)
debugLabel.Position = UDim2.new(0, 10, 0, 60)
debugLabel.Text = "Current waitTime: " .. tostring(waitTime)
debugLabel.Font = Enum.Font.SourceSans
debugLabel.TextSize = 18
debugLabel.TextColor3 = Color3.fromRGB(255, 140, 0) -- Darker Orange
debugLabel.BackgroundTransparency = 1
debugLabel.Parent = menuFrame

-- Create Update Button inside menuFrame (black and orange theme)
local updateButton = Instance.new("TextButton")
updateButton.Size = UDim2.new(0, 90, 0, 30)
updateButton.Position = UDim2.new(0, 210, 0, 20)
updateButton.Text = "Update"
updateButton.Font = Enum.Font.SourceSans
updateButton.TextSize = 18
updateButton.BackgroundColor3 = Color3.fromRGB(255, 140, 0) -- Darker Orange
updateButton.TextColor3 = Color3.fromRGB(20, 20, 20) -- Dark text
updateButton.Parent = menuFrame

-- Add UICorner to updateButton
local updateCorner = Instance.new("UICorner")
updateCorner.CornerRadius = UDim.new(0, 5)
updateCorner.Parent = updateButton

-- Toggle menu visibility on chathead click
chathead.MouseButton1Click:Connect(function()
    menuFrame.Visible = not menuFrame.Visible
end)

-- Dragging logic for chathead
local dragging
local dragInput
local dragStart
local startPos

local function updatePosition(input)
    local delta = input.Position - dragStart
    local newPos = UDim2.new(
        0,
        math.clamp(startPos.X.Offset + delta.X, 0, workspace.CurrentCamera.ViewportSize.X - chathead.AbsoluteSize.X),
        0,
        math.clamp(startPos.Y.Offset + delta.Y, 0, workspace.CurrentCamera.ViewportSize.Y - chathead.AbsoluteSize.Y)
    )
    chathead.Position = newPos
    -- Update menuFrame position to follow chathead (e.g., to the right)
    menuFrame.Position = UDim2.new(0, newPos.X.Offset + 60, 0, newPos.Y.Offset)
end

chathead.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = chathead.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

chathead.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        updatePosition(input)
    end
end)

-- Update wait time on input focus lost (for validation only)
waitInput.FocusLost:Connect(function(enterPressed)
    local input = tonumber(waitInput.Text)
    if input and input > 0 then
        waitInput.Text = tostring(input)
    else
        waitInput.Text = tostring(waitTime)
    end
end)

-- Toggle function (manual override, but will be overridden by time check)
toggleButton.MouseButton1Click:Connect(function()
    manualOverride = true
    rejoinEnabled = not rejoinEnabled
    if rejoinEnabled then
        toggleButton.Text = "Rejoin: ON"
    else
        toggleButton.Text = "Rejoin: OFF"
    end
end)

-- Update wait time function
updateButton.MouseButton1Click:Connect(function()
    local input = tonumber(waitInput.Text)
    if input and input > 0 then
        waitTime = input
        waitInput.Text = tostring(waitTime)
        debugLabel.Text = "Current waitTime: " .. tostring(waitTime)
    else
        waitInput.Text = tostring(waitTime)
    end
end)

-- Teleport logic
while true do
    -- Update rejoinEnabled based on current time if not manually overridden
    if not manualOverride then
        rejoinEnabled = isWithinTimeframe()
    end
    -- Update button text
    if rejoinEnabled then
        toggleButton.Text = "Rejoin: ON"
    else
        toggleButton.Text = "Rejoin: OFF"
    end

    if rejoinEnabled then
        local startTime = tick()
        local initialWait = waitTime
        local targetTime = startTime + waitTime
        debugLabel.Text = "Rejoin in: " .. math.ceil(waitTime)
        while tick() < targetTime do
            task.wait(1)
            if not rejoinEnabled then break end
            if waitTime ~= initialWait then
                startTime = tick()
                initialWait = waitTime
                targetTime = startTime + waitTime
            end
            local remaining = math.ceil(targetTime - tick())
            debugLabel.Text = "Rejoin in: " .. remaining
        end
        if rejoinEnabled then
            debugLabel.Text = "Rejoining..."
            TeleportService:Teleport(game.PlaceId, player)
        end
    else
        debugLabel.Text = "Rejoin: OFF"
        task.wait(1)
    end
end

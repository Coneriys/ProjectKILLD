-- Project KILLD Evade
local placeID = 9872472334
if game.PlaceId ~= placeID then
    return
end

-- Configuration
local ESPSettings = {
    Enabled = false,
    ShowBoxes = false, -- Disabled by default
    ShowNames = true,
    ShowDistance = true,
    ShowTracers = true,
    ShowEscapePath = true, -- Air path
    ShowFloorPath = true, -- Floor navigation path
    MaxDistance = 1000,
    BoxColor = Color3.fromRGB(255, 0, 0),
    TextColor = Color3.fromRGB(255, 255, 255),
    TracerColor = Color3.fromRGB(255, 0, 255), -- Purple tracers
    PathColor = Color3.fromRGB(0, 255, 0), -- Green air path
    FloorPathColor = Color3.fromRGB(0, 200, 255), -- Cyan floor path
    BoxTransparency = 0.7,
    TextSize = 14,
    PathThickness = 2,
    FloorPathThickness = 4, -- Thicker floor path
    PathLength = 50, -- Length of escape path visualization
    FloorPathNodes = 10, -- Number of nodes in floor path
    RefreshRate = 0.1, -- How often to update ESP (in seconds)
    DetectionDistance = 200, -- Distance to start showing escape path
    PathUpdateRate = 0.5, -- How often to update path direction (seconds)
    
    -- Third Person Settings
    ThirdPersonEnabled = false,
    ThirdPersonDistance = 5,
    ThirdPersonSmoothness = 0.5,
    
    -- BHop Settings
    BHopEnabled = false,
    BHopPower = 2.5
}

-- Global variables for tracking state
local ThirdPersonEnabled = false
local OriginalCameraType = nil
local OriginalMinZoom = nil
local OriginalMaxZoom = nil
local BHopRunning = false
local BHopConnection = nil
local LastPathUpdateTime = 0
local CurrentPathDirection = nil
local CurrentPathPoints = {}

-- Pre-define functions for camera
local function UpdateThirdPersonDistance(distance)
    local player = game:GetService("Players").LocalPlayer
    
    -- Get current zoom
    local currentZoom = player.CameraMaxZoomDistance
    
    -- Set distance
    local adjustedDistance = distance
    
    -- Apply gradual zoom
    local LerpToTarget = currentZoom + ((adjustedDistance - currentZoom) * ESPSettings.ThirdPersonSmoothness)
    
    -- Apply
    player.CameraMinZoomDistance = math.max(0.5, adjustedDistance - 1)
    player.CameraMaxZoomDistance = adjustedDistance + 1
    
    -- Set the camera's zoom
    workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * CFrame.new(0, 0, LerpToTarget - currentZoom)
end

local function ToggleThirdPerson(enabled)
    local player = game:GetService("Players").LocalPlayer
    
    if enabled then
        -- Save original camera settings
        OriginalCameraType = player.CameraMode
        OriginalMinZoom = player.CameraMinZoomDistance
        OriginalMaxZoom = player.CameraMaxZoomDistance
        
        -- Enable third person
        player.CameraMode = Enum.CameraMode.Classic
        player.CameraMinZoomDistance = 0.5
        player.CameraMaxZoomDistance = 20
        
        -- Set zoom to our desired amount
        UpdateThirdPersonDistance(ESPSettings.ThirdPersonDistance)
        
        ThirdPersonEnabled = true
        library:SendNotification("Third Person Enabled", 2)
    else
        -- Restore original camera settings if we have them saved
        if OriginalCameraType then
            player.CameraMode = OriginalCameraType
        end
        
        if OriginalMinZoom then
            player.CameraMinZoomDistance = OriginalMinZoom
        end
        
        if OriginalMaxZoom then
            player.CameraMaxZoomDistance = OriginalMaxZoom
        end
        
        ThirdPersonEnabled = false
        library:SendNotification("Third Person Disabled", 2)
    end
end

-- B-Hop function
local function ToggleBHop(enabled)
    if enabled then
        if BHopRunning then return end
        BHopRunning = true
        
        -- Create a new connection for the heartbeat
        BHopConnection = game:GetService("RunService").Heartbeat:Connect(function()
            local player = game:GetService("Players").LocalPlayer
            if not player or not player.Character then return end
            
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if not humanoid then return end
            
            -- Check if the player is moving
            local isMoving = humanoid.MoveDirection.Magnitude > 0
            
            -- Apply bunny hop - force jump whenever we're on the ground
            if humanoid.FloorMaterial ~= Enum.Material.Air and isMoving then
                -- Use Jump property instead of directly simulating space bar
                humanoid.Jump = true
                
                -- Apply forward motion boost when jumping
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local moveDirection = humanoid.MoveDirection
                    -- Create a new velocity that boosts in the direction of movement
                    local newVelocity = moveDirection * ESPSettings.BHopPower
                    -- Keep the Y velocity the same to not interfere with jump height
                    newVelocity = Vector3.new(newVelocity.X, rootPart.Velocity.Y, newVelocity.Z)
                    rootPart.Velocity = newVelocity
                end
            end
        end)
        
        library:SendNotification("Bunny Hop Enabled", 2)
    else
        BHopRunning = false
        if BHopConnection then
            BHopConnection:Disconnect()
            BHopConnection = nil
        end
        library:SendNotification("Bunny Hop Disabled", 2)
    end
end

-- Initialize UI Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "Project KILLD", 
    gamename = "Evade"
})
library:init()

-- Create Main Window
local Window = library.NewWindow({
    title = "Project KILLD | Evade",
    size = UDim2.new(0, 510, 0.6, 6)
})

-- Create Tabs
local ESPTab = Window:AddTab("  ESP  ")
local PathTab = Window:AddTab("  Navigation  ")
local MovementTab = Window:AddTab("  Movement  ")
local ThirdPersonTab = Window:AddTab("  Camera  ")
local SettingsTab = library:CreateSettingsTab(Window)

-- ESP Section
local ESPSection = ESPTab:AddSection("ESP Settings", 1)

-- ESP Toggle
ESPSection:AddToggle({
    text = "Enable ESP",
    state = ESPSettings.Enabled,
    flag = "ESP_Enabled",
    callback = function(value)
        ESPSettings.Enabled = value
    end
}):AddBind({
    text = "Toggle Key",
    bind = "LeftAlt",
    flag = "ESP_ToggleKey",
    mode = "toggle",
    callback = function(value)
        ESPSettings.Enabled = value
    end
})

-- ESP Options
ESPSection:AddToggle({
    text = "Show Boxes",
    state = ESPSettings.ShowBoxes,
    flag = "ESP_ShowBoxes",
    callback = function(value)
        ESPSettings.ShowBoxes = value
    end
})

ESPSection:AddToggle({
    text = "Show Names",
    state = ESPSettings.ShowNames,
    flag = "ESP_ShowNames",
    callback = function(value)
        ESPSettings.ShowNames = value
    end
})

ESPSection:AddToggle({
    text = "Show Distance",
    state = ESPSettings.ShowDistance,
    flag = "ESP_ShowDistance",
    callback = function(value)
        ESPSettings.ShowDistance = value
    end
})

ESPSection:AddToggle({
    text = "Show Tracers",
    state = ESPSettings.ShowTracers,
    flag = "ESP_ShowTracers",
    callback = function(value)
        ESPSettings.ShowTracers = value
    end
})

ESPSection:AddSeparator({
    text = "ESP Appearance"
})

ESPSection:AddSlider({
    text = "Max Distance",
    flag = "ESP_MaxDistance",
    min = 100,
    max = 5000,
    increment = 100,
    suffix = " studs",
    value = ESPSettings.MaxDistance,
    callback = function(value)
        ESPSettings.MaxDistance = value
    end
})

ESPSection:AddSlider({
    text = "Box Transparency",
    flag = "ESP_BoxTransparency",
    min = 0,
    max = 1,
    increment = 0.1,
    value = ESPSettings.BoxTransparency,
    callback = function(value)
        ESPSettings.BoxTransparency = value
    end
})

ESPSection:AddSlider({
    text = "Text Size",
    flag = "ESP_TextSize",
    min = 10,
    max = 24,
    increment = 1,
    value = ESPSettings.TextSize,
    callback = function(value)
        ESPSettings.TextSize = value
    end
})

ESPSection:AddColor({
    text = "Box Color",
    color = ESPSettings.BoxColor,
    flag = "ESP_BoxColor",
    callback = function(value)
        ESPSettings.BoxColor = value
    end
})

ESPSection:AddColor({
    text = "Text Color",
    color = ESPSettings.TextColor,
    flag = "ESP_TextColor",
    callback = function(value)
        ESPSettings.TextColor = value
    end
})

ESPSection:AddColor({
    text = "Tracer Color",
    color = ESPSettings.TracerColor,
    flag = "ESP_TracerColor",
    callback = function(value)
        ESPSettings.TracerColor = value
    end
})

-- Navigation Section
local NavSection = PathTab:AddSection("Floor Navigation", 1)

NavSection:AddToggle({
    text = "Show Escape Path",
    state = ESPSettings.ShowEscapePath,
    flag = "Path_ShowEscapePath",
    callback = function(value)
        ESPSettings.ShowEscapePath = value
    end
})

NavSection:AddToggle({
    text = "Show Floor Path",
    state = ESPSettings.ShowFloorPath,
    flag = "Path_ShowFloorPath",
    callback = function(value)
        ESPSettings.ShowFloorPath = value
    end
})

NavSection:AddSlider({
    text = "Detection Range",
    flag = "Path_DetectionRange",
    min = 50,
    max = 500,
    increment = 10,
    suffix = " studs",
    value = ESPSettings.DetectionDistance,
    callback = function(value)
        ESPSettings.DetectionDistance = value
    end
})

NavSection:AddSlider({
    text = "Path Length",
    flag = "Path_Length",
    min = 20,
    max = 200,
    increment = 5,
    suffix = " studs",
    value = ESPSettings.PathLength,
    callback = function(value)
        ESPSettings.PathLength = value
    end
})

NavSection:AddSlider({
    text = "Floor Path Thickness",
    flag = "Path_FloorThickness",
    min = 1,
    max = 10,
    increment = 1,
    value = ESPSettings.FloorPathThickness,
    callback = function(value)
        ESPSettings.FloorPathThickness = value
    end
})

NavSection:AddSlider({
    text = "Floor Path Nodes",
    flag = "Path_FloorNodes",
    min = 3,
    max = 20,
    increment = 1,
    value = ESPSettings.FloorPathNodes,
    callback = function(value)
        ESPSettings.FloorPathNodes = value
        UpdateFloorPathObjects() -- Recreate floor path objects when node count changes
    end
})

-- Add path update rate slider
NavSection:AddSlider({
    text = "Path Update Rate",
    flag = "Path_UpdateRate",
    min = 0.1,
    max = 2,
    increment = 0.1,
    suffix = " sec",
    value = ESPSettings.PathUpdateRate,
    callback = function(value)
        ESPSettings.PathUpdateRate = value
    end
})

NavSection:AddColor({
    text = "Air Path Color",
    color = ESPSettings.PathColor,
    flag = "Path_Color",
    callback = function(value)
        ESPSettings.PathColor = value
    end
})

NavSection:AddColor({
    text = "Floor Path Color",
    color = ESPSettings.FloorPathColor,
    flag = "Path_FloorColor",
    callback = function(value)
        ESPSettings.FloorPathColor = value
    end
})

-- Movement Section (BHop)
local MovementSection = MovementTab:AddSection("Movement", 1)

MovementSection:AddToggle({
    text = "Enable Bunny Hop",
    state = ESPSettings.BHopEnabled,
    flag = "BHop_Enabled",
    callback = function(value)
        ESPSettings.BHopEnabled = value
        ToggleBHop(value)
    end
}):AddBind({
    text = "Toggle Key",
    bind = "B",
    flag = "BHop_ToggleKey",
    mode = "toggle",
    callback = function(value)
        ESPSettings.BHopEnabled = value
        ToggleBHop(value)
    end
})

MovementSection:AddSlider({
    text = "BHop Power",
    flag = "BHop_Power",
    min = 1,
    max = 5,
    increment = 0.1,
    value = ESPSettings.BHopPower,
    callback = function(value)
        ESPSettings.BHopPower = value
    end
})

-- Third Person Camera Section
local ThirdPersonSection = ThirdPersonTab:AddSection("Third Person Camera", 1)

ThirdPersonSection:AddToggle({
    text = "Enable Third Person",
    state = ESPSettings.ThirdPersonEnabled,
    flag = "ThirdPerson_Enabled",
    callback = function(value)
        ESPSettings.ThirdPersonEnabled = value
        ToggleThirdPerson(value)
    end
}):AddBind({
    text = "Toggle Key",
    bind = "T",
    flag = "ThirdPerson_ToggleKey",
    mode = "toggle",
    callback = function(value)
        ESPSettings.ThirdPersonEnabled = value
        ToggleThirdPerson(value)
    end
})

ThirdPersonSection:AddSlider({
    text = "Camera Distance",
    flag = "ThirdPerson_Distance",
    min = 2,
    max = 20,
    increment = 0.5,
    suffix = " studs",
    value = ESPSettings.ThirdPersonDistance,
    callback = function(value)
        ESPSettings.ThirdPersonDistance = value
        if ESPSettings.ThirdPersonEnabled then
            UpdateThirdPersonDistance(value)
        end
    end
})

ThirdPersonSection:AddSlider({
    text = "Camera Smoothness",
    flag = "ThirdPerson_Smoothness",
    min = 0.1,
    max = 1,
    increment = 0.1,
    value = ESPSettings.ThirdPersonSmoothness,
    callback = function(value)
        ESPSettings.ThirdPersonSmoothness = value
    end
})

-- Advanced Settings Section
local AdvancedSection = ESPTab:AddSection("Advanced", 2)

AdvancedSection:AddSlider({
    text = "Refresh Rate",
    flag = "ESP_RefreshRate",
    min = 0.01,
    max = 1,
    increment = 0.01,
    suffix = "s",
    value = ESPSettings.RefreshRate,
    callback = function(value)
        ESPSettings.RefreshRate = value
    end
})

AdvancedSection:AddButton({
    text = "Reset ESP",
    confirm = true,
    callback = function()
        ClearESP()
        library:SendNotification("ESP has been reset", 3)
    end
})

-- ESP Implementation
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local UIS = game:GetService("UserInputService")

-- Store ESP objects
local ESPObjects = {}

-- Navigation Drawing Objects
local NavigationElements = {
    EscapePath = Drawing.new("Line"),
    PathArrow = Drawing.new("Triangle"),
    WarningText = Drawing.new("Text"),
    FloorPathNodes = {} -- Will hold floor path line segments
}

-- Configure navigation elements
NavigationElements.EscapePath.Visible = false
NavigationElements.EscapePath.Color = ESPSettings.PathColor
NavigationElements.EscapePath.Thickness = ESPSettings.PathThickness

NavigationElements.PathArrow.Visible = false
NavigationElements.PathArrow.Color = ESPSettings.PathColor
NavigationElements.PathArrow.Filled = true
NavigationElements.PathArrow.Transparency = 1

NavigationElements.WarningText.Visible = false
NavigationElements.WarningText.Color = Color3.fromRGB(255, 255, 0)
NavigationElements.WarningText.Size = 18
NavigationElements.WarningText.Center = true
NavigationElements.WarningText.Outline = true

-- Function to initialize/update floor path objects
function UpdateFloorPathObjects()
    -- Clear existing floor path objects
    for _, line in pairs(NavigationElements.FloorPathNodes) do
        line:Remove()
    end
    NavigationElements.FloorPathNodes = {}
    
    -- Create new floor path objects based on current node count
    for i = 1, ESPSettings.FloorPathNodes do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = ESPSettings.FloorPathColor
        line.Thickness = ESPSettings.FloorPathThickness
        table.insert(NavigationElements.FloorPathNodes, line)
    end
end

-- Initialize floor path objects
UpdateFloorPathObjects()

-- Function to check if entity is a NextBot (not a player)
local function IsNextBot(entity)
    -- Check if entity has HumanoidRootPart and Humanoid
    if not entity:FindFirstChild("HumanoidRootPart") or not entity:FindFirstChild("Humanoid") then 
        return false 
    end
    
    -- Check if this entity is not a player
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character == entity then
            return false -- This is a player, not a NextBot
        end
    end
    
    return true -- Entity has Humanoid/HumanoidRootPart and is not a player character
end

-- Function to create ESP for an entity
local function CreateESP(entity)
    -- Only create ESP for NextBots, not players
    if not IsNextBot(entity) then return end
    
    local espObject = {
        Entity = entity,
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Connection = nil
    }
    
    -- Configure Box
    espObject.Box.Visible = false
    espObject.Box.Color = ESPSettings.BoxColor
    espObject.Box.Thickness = 1
    espObject.Box.Transparency = 1 - ESPSettings.BoxTransparency
    espObject.Box.Filled = false
    
    -- Configure Name Text
    espObject.Name.Visible = false
    espObject.Name.Color = ESPSettings.TextColor
    espObject.Name.Size = ESPSettings.TextSize
    espObject.Name.Center = true
    espObject.Name.Outline = true
    
    -- Configure Distance Text
    espObject.Distance.Visible = false
    espObject.Distance.Color = ESPSettings.TextColor
    espObject.Distance.Size = ESPSettings.TextSize
    espObject.Distance.Center = true
    espObject.Distance.Outline = true
    
    -- Configure Tracer
    espObject.Tracer.Visible = false
    espObject.Tracer.Color = ESPSettings.TracerColor
    espObject.Tracer.Thickness = 1
    espObject.Tracer.Transparency = 1
    
    -- Add to ESP objects
    ESPObjects[entity] = espObject
    
    -- Return the created ESP object
    return espObject
end

-- Function to update ESP for an entity
local function UpdateESP(espObject)
    local entity = espObject.Entity
    if not entity or not entity.Parent then
        RemoveESP(entity)
        return
    end
    
    local humanoidRootPart = entity:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then
        espObject.Box.Visible = false
        espObject.Name.Visible = false
        espObject.Distance.Visible = false
        espObject.Tracer.Visible = false
        return
    end
    
    local humanoid = entity:FindFirstChild("Humanoid")
    local vector, onScreen = Camera:WorldToViewportPoint(humanoidRootPart.Position)
    local distance = (humanoidRootPart.Position - Camera.CFrame.Position).Magnitude
    
    if onScreen and distance <= ESPSettings.MaxDistance and ESPSettings.Enabled then
        -- Update Box
        if ESPSettings.ShowBoxes then
            local rootPosition = humanoidRootPart.Position
            local headPosition = rootPosition + Vector3.new(0, 3, 0)
            
            local rootPoint = Camera:WorldToViewportPoint(rootPosition)
            local headPoint = Camera:WorldToViewportPoint(headPosition)
            
            local boxSize = headPoint.Y - rootPoint.Y
            local boxWidth = boxSize / 2
            
            espObject.Box.Size = Vector2.new(boxWidth, boxSize)
            espObject.Box.Position = Vector2.new(vector.X - boxWidth / 2, vector.Y - boxSize / 2)
            espObject.Box.Color = ESPSettings.BoxColor
            espObject.Box.Transparency = 1 - ESPSettings.BoxTransparency
            espObject.Box.Visible = true
        else
            espObject.Box.Visible = false
        end
        
        -- Update Name
        if ESPSettings.ShowNames then
            local name = entity.Name
            if humanoid then
                name = humanoid.DisplayName ~= "" and humanoid.DisplayName or entity.Name
            end
            
            espObject.Name.Text = name
            espObject.Name.Position = Vector2.new(vector.X, vector.Y - 40)
            espObject.Name.Color = ESPSettings.TextColor
            espObject.Name.Size = ESPSettings.TextSize
            espObject.Name.Visible = true
        else
            espObject.Name.Visible = false
        end
        
        -- Update Distance
        if ESPSettings.ShowDistance then
            espObject.Distance.Text = math.floor(distance) .. " studs"
            espObject.Distance.Position = Vector2.new(vector.X, vector.Y + 20)
            espObject.Distance.Color = ESPSettings.TextColor
            espObject.Distance.Size = ESPSettings.TextSize
            espObject.Distance.Visible = true
        else
            espObject.Distance.Visible = false
        end
        
        -- Update Tracer
        if ESPSettings.ShowTracers then
            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 30) -- Bottom center
            espObject.Tracer.From = screenCenter
            espObject.Tracer.To = Vector2.new(vector.X, vector.Y)
            espObject.Tracer.Color = ESPSettings.TracerColor
            espObject.Tracer.Visible = true
        else
            espObject.Tracer.Visible = false
        end
    else
        -- Hide ESP if not on screen or too far
        espObject.Box.Visible = false
        espObject.Name.Visible = false
        espObject.Distance.Visible = false
        espObject.Tracer.Visible = false
    end
end

-- Function to remove ESP for an entity
local function RemoveESP(entity)
    local espObject = ESPObjects[entity]
    if espObject then
        if espObject.Box then espObject.Box:Remove() end
        if espObject.Name then espObject.Name:Remove() end
        if espObject.Distance then espObject.Distance:Remove() end
        if espObject.Tracer then espObject.Tracer:Remove() end
        if espObject.Connection then espObject.Connection:Disconnect() end
        ESPObjects[entity] = nil
    end
end

-- Function to clear all ESP
function ClearESP()
    for entity, espObject in pairs(ESPObjects) do
        RemoveESP(entity)
    end
    
    -- Also reset navigation elements
    NavigationElements.EscapePath.Visible = false
    NavigationElements.PathArrow.Visible = false
    NavigationElements.WarningText.Visible = false
    
    -- Hide all floor path segments
    for _, line in pairs(NavigationElements.FloorPathNodes) do
        line.Visible = false
    end
    
    -- Disable third person and bhop
    if ThirdPersonEnabled then
        ToggleThirdPerson(false)
    end
    
    if BHopRunning then
        ToggleBHop(false)
    end
end

-- Check existing entities
local function CheckExistingEntities()
    if game.Workspace:FindFirstChild("Game") and game.Workspace.Game:FindFirstChild("Players") then
        for _, entity in pairs(game.Workspace.Game.Players:GetChildren()) do
            if not ESPObjects[entity] and IsNextBot(entity) then
                CreateESP(entity)
            end
        end
    end
end

-- Function to update all ESP objects
local function UpdateAllESP()
    for _, espObject in pairs(ESPObjects) do
        UpdateESP(espObject)
    end
end

-- Listen for new entities
local function SetupEntityAddedListener()
    if game.Workspace:FindFirstChild("Game") and game.Workspace.Game:FindFirstChild("Players") then
        game.Workspace.Game.Players.ChildAdded:Connect(function(entity)
            wait(0.5) -- Wait a bit for the entity to load completely
            if not ESPObjects[entity] and IsNextBot(entity) then
                CreateESP(entity)
            end
        end)
        
        game.Workspace.Game.Players.ChildRemoved:Connect(function(entity)
            RemoveESP(entity)
        end)
    end
end

-- Navigation System

-- Function to get all obstacles in the map (including invisible barriers)
local function GetAllObstacles()
    local obstacles = {}
    
    -- Add obstacles from different map locations
    local mapLocations = {
        workspace.Game.Map.Parts,
        workspace.Game.Map.Parts.Map,
        workspace.Game.Map.Parts.ImmovableProps,
        workspace.Game.Map.InvisParts -- Added invisible barriers
    }
    
    for _, location in pairs(mapLocations) do
        if location then
            for _, part in pairs(location:GetDescendants()) do
                if part:IsA("BasePart") then
                    table.insert(obstacles, part)
                end
            end
        end
    end
    
    return obstacles
end

-- Function to check if a path is clear
local function IsPathClear(start, direction, distance, obstacles)
    local ray = Ray.new(start, direction * distance)
    local hit, hitPos = workspace:FindPartOnRayWithWhitelist(ray, obstacles)
    return not hit, hit and hitPos or start + direction * distance
end

-- Function to cast a ray downwards to find floor position
local function GetFloorPosition(position, obstacles)
    local floorRay = Ray.new(position + Vector3.new(0, 1, 0), Vector3.new(0, -50, 0)) -- Cast 50 studs down
    local hit, hitPos = workspace:FindPartOnRayWithWhitelist(floorRay, obstacles)
    return hit and hitPos or position
end

-- Function to find the best escape direction with more stability
local function FindBestEscapeDirection(playerPos, nextBotPos, obstacles)
    -- If we already have a path direction and it hasn't been long enough to update
    local currentTime = tick()
    if CurrentPathDirection and currentTime - LastPathUpdateTime < ESPSettings.PathUpdateRate then
        -- Return the existing direction and points
        return CurrentPathDirection, (CurrentPathDirection * ESPSettings.PathLength).Magnitude, CurrentPathPoints
    end
    
    -- Base direction away from the NextBot
    local baseDirection = (playerPos - nextBotPos).Unit
    
    -- Check multiple directions in 15-degree increments
    local bestDirection = baseDirection
    local longestClearDistance = 0
    local pathPoints = {}
    
    -- Test several directions to find the best one
    for angleOffset = -180, 180, 15 do
        local angle = math.rad(angleOffset)
        local testDirection = Vector3.new(
            baseDirection.X * math.cos(angle) - baseDirection.Z * math.sin(angle),
            0,
            baseDirection.X * math.sin(angle) + baseDirection.Z * math.cos(angle)
        ).Unit
        
        local isClear, endPos = IsPathClear(playerPos, testDirection, ESPSettings.PathLength, obstacles)
        local clearDistance = (endPos - playerPos).Magnitude
        
        if clearDistance > longestClearDistance then
            longestClearDistance = clearDistance
            bestDirection = testDirection
        end
    end
    
    -- Generate path points along the best direction
    for i = 1, ESPSettings.FloorPathNodes do
        local segmentLength = (longestClearDistance / ESPSettings.FloorPathNodes) * i
        local pointPos = playerPos + bestDirection * segmentLength
        local floorPos = GetFloorPosition(pointPos, obstacles)
        table.insert(pathPoints, floorPos)
    end
    
    -- Store the current direction and update time
    CurrentPathDirection = bestDirection
    LastPathUpdateTime = currentTime
    CurrentPathPoints = pathPoints
    
    return bestDirection, longestClearDistance, pathPoints
end

-- Function to update the navigation visualization
local function UpdateNavigation()
    -- Reset visibility if ESP is disabled
    if not ESPSettings.Enabled then
        NavigationElements.EscapePath.Visible = false
        NavigationElements.PathArrow.Visible = false
        NavigationElements.WarningText.Visible = false
        
        for _, line in pairs(NavigationElements.FloorPathNodes) do
            line.Visible = false
        end
        return
    end
    
    -- Check if player character exists
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        NavigationElements.EscapePath.Visible = false
        NavigationElements.PathArrow.Visible = false
        NavigationElements.WarningText.Visible = false
        
        for _, line in pairs(NavigationElements.FloorPathNodes) do
            line.Visible = false
        end
        return
    end
    
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local playerPos = hrp.Position
    
    -- Find closest NextBot
    local closestBot = nil
    local closestDistance = math.huge
    
    for entity, espObject in pairs(ESPObjects) do
        if entity and entity.Parent and entity:FindFirstChild("HumanoidRootPart") then
            local botPos = entity.HumanoidRootPart.Position
            local distance = (botPos - playerPos).Magnitude
            
            if distance < closestDistance then
                closestBot = entity
                closestDistance = distance
            end
        end
    end
    
    -- Only show navigation if a NextBot is within range
    if closestBot and closestDistance <= ESPSettings.DetectionDistance then
        local obstacles = GetAllObstacles()
        local botPos = closestBot.HumanoidRootPart.Position
        
        -- Find best escape direction and path points
        local escapeDir, pathLength, pathPoints = FindBestEscapeDirection(playerPos, botPos, obstacles)
        pathLength = math.min(pathLength, ESPSettings.PathLength)
        
        -- Calculate path end point
        local endPoint = playerPos + escapeDir * pathLength
        
        -- Update escape path if enabled
        if ESPSettings.ShowEscapePath then
            -- Convert to screen coordinates
            local startScreen = Camera:WorldToViewportPoint(playerPos)
            local endScreen = Camera:WorldToViewportPoint(endPoint)
            
            -- Update line
            NavigationElements.EscapePath.From = Vector2.new(startScreen.X, startScreen.Y)
            NavigationElements.EscapePath.To = Vector2.new(endScreen.X, endScreen.Y)
            NavigationElements.EscapePath.Color = ESPSettings.PathColor
            NavigationElements.EscapePath.Thickness = ESPSettings.PathThickness
            NavigationElements.EscapePath.Visible = true
            
            -- Calculate arrow points
            local direction = (Vector2.new(endScreen.X, endScreen.Y) - Vector2.new(startScreen.X, startScreen.Y)).Unit
            local arrowSize = 10
            local arrowPoint = Vector2.new(endScreen.X, endScreen.Y)
            local perpendicular = Vector2.new(-direction.Y, direction.X) * arrowSize
            
            NavigationElements.PathArrow.PointA = arrowPoint
            NavigationElements.PathArrow.PointB = arrowPoint - direction * arrowSize + perpendicular
            NavigationElements.PathArrow.PointC = arrowPoint - direction * arrowSize - perpendicular
            NavigationElements.PathArrow.Color = ESPSettings.PathColor
            NavigationElements.PathArrow.Visible = true
        else
            NavigationElements.EscapePath.Visible = false
            NavigationElements.PathArrow.Visible = false
        end
        
        -- Update floor path if enabled
        if ESPSettings.ShowFloorPath then
            -- Make sure the number of line segments matches the number of path points - 1
            if #NavigationElements.FloorPathNodes ~= ESPSettings.FloorPathNodes then
                UpdateFloorPathObjects()
            end
            
            -- Draw floor path segments connecting the path points
            for i = 1, #NavigationElements.FloorPathNodes do
                local line = NavigationElements.FloorPathNodes[i]
                
                if i < #pathPoints then
                    local pointA = pathPoints[i]
                    local pointB = pathPoints[i+1]
                    
                    -- Only show if both points are visible on screen
                    local screenA, onScreenA = Camera:WorldToViewportPoint(pointA)
                    local screenB, onScreenB = Camera:WorldToViewportPoint(pointB)
                    
                    if onScreenA and onScreenB then
                        line.From = Vector2.new(screenA.X, screenA.Y)
                        line.To = Vector2.new(screenB.X, screenB.Y)
                        line.Color = ESPSettings.FloorPathColor
                        line.Thickness = ESPSettings.FloorPathThickness
                        
                        -- Make the line gradually fade in opacity as it gets further away
                        local alpha = 1 - (i / #NavigationElements.FloorPathNodes * 0.5)
                        line.Transparency = alpha
                        
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            -- Hide floor path if disabled
            for _, line in pairs(NavigationElements.FloorPathNodes) do
                line.Visible = false
            end
        end
        
        -- Update warning text
        NavigationElements.WarningText.Text = "⚠️ NextBot: " .. math.floor(closestDistance) .. " studs"
        NavigationElements.WarningText.Position = Vector2.new(Camera.ViewportSize.X / 2, 50)
        
        -- Change color based on distance
        if closestDistance < 50 then
            NavigationElements.WarningText.Color = Color3.fromRGB(255, 0, 0) -- Red when very close
        elseif closestDistance < 100 then
            NavigationElements.WarningText.Color = Color3.fromRGB(255, 165, 0) -- Orange when moderately close
        else
            NavigationElements.WarningText.Color = Color3.fromRGB(255, 255, 0) -- Yellow when in detection range
        end
        
        NavigationElements.WarningText.Visible = true
    else
        -- Hide navigation if no NextBot is in range
        NavigationElements.EscapePath.Visible = false
        NavigationElements.PathArrow.Visible = false
        NavigationElements.WarningText.Visible = false
        
        for _, line in pairs(NavigationElements.FloorPathNodes) do
            line.Visible = false
        end
        
        -- Reset path when no bots around
        CurrentPathDirection = nil
        LastPathUpdateTime = 0
        CurrentPathPoints = {}
    end
end

-- Listen for user input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed then
        -- Third person toggle with T key
        if input.KeyCode == Enum.KeyCode.T then
            ESPSettings.ThirdPersonEnabled = not ESPSettings.ThirdPersonEnabled
            ToggleThirdPerson(ESPSettings.ThirdPersonEnabled)
        end
        
        -- BHop toggle with B key
        if input.KeyCode == Enum.KeyCode.B then
            ESPSettings.BHopEnabled = not ESPSettings.BHopEnabled
            ToggleBHop(ESPSettings.BHopEnabled)
        end
    end
end)

-- Main update loop
RunService:BindToRenderStep("ESP", 200, function()
    CheckExistingEntities()
    UpdateAllESP()
    UpdateNavigation()
end)

-- Setup Initial Events
CheckExistingEntities()
SetupEntityAddedListener()

-- Send notification when loaded
library:SendNotification("Project KILLD Loaded Successfully", 5)

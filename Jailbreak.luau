if _G.ProjectKILLDRunning then
    return
end
_G.ProjectKILLDRunning = true

local placeID = 606849621
if game.PlaceId ~= placeID then
    library:SendNotification("This script only works in Jailbreak!", 5)
    return
end

-- Initialize the UI Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "Project KILLD",
    gamename = "Jailbreak",
})

library:init()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local loadStartTime = os.clock()

-- Configuration
local Config = {
    -- Main Settings
    ESP = {
        Enabled = false,
        PoliceEnabled = true,
        PrisonerEnabled = true,
        CriminalEnabled = true,
        BoxEnabled = true,
        NameEnabled = true,
        DistanceEnabled = true,
        TracersEnabled = true,
        TeamColorEnabled = true,
        MaxDistance = 2000,
        BoxColors = {
            Police = Color3.fromRGB(0, 0, 255),
            Prisoner = Color3.fromRGB(255, 165, 0),
            Criminal = Color3.fromRGB(255, 0, 0)
        },
        BoxThickness = 2,
        TracerThickness = 1,
        TextSize = 14,
        TextColor = Color3.fromRGB(255, 255, 255)
    },
    Movement = {
        FlyEnabled = false,
        FlySpeed = 300,
        WalkSpeed = 30,
        JumpPower = 50,
        NoClip = false
    },
    Robbery = {
        NotificationsEnabled = true,
        Status = {},
        Names = {
            ["BANK"] = "Rising City Bank",
            ["BANK2"] = "Crater Bank",
            ["JEWELRY"] = "Jewelry Store",
            ["MUSEUM"] = "Museum",
            ["POWER_PLANT"] = "Power Plant",
            ["TRAIN_PASSENGER"] = "Passenger Train",
            ["TRAIN_CARGO"] = "Cargo Train",
            ["CARGO_SHIP"] = "Cargo Ship",
            ["CARGO_PLANE"] = "Cargo Plane",
            ["STORE_GAS"] = "Gas Station",
            ["STORE_DONUT"] = "Donut Store",
            ["MONEY_TRUCK"] = "Money Truck",
            ["TOMB"] = "Tomb",
            ["CASINO"] = "Casino",
            ["MANSION"] = "Mansion",
            ["OIL_RIG"] = "Oil Rig"
        },
        StatusEnum = {
            OPENED = 0,
            STARTED = 1,
            CLOSED = 2
        }
    },
    Toggles = {
        CrateESP = false,
        WallShoot = false,
        GlideWithG = false,
        ReplaceParachute = false,
        NoRagdoll = false,
        KeycardBypass = false,
        HoldEBypass = false,
        ForceDaytime = false,
        LockOnExit = false,
        DeleteRadio = false,
        ShootThroughWalls = false,
        ReducedShotgunSpread = false,
        SingleShotgunBullet = false
    },
    AntiAim = {
        Enabled = false,
        SpinSpeed = 20,  -- Rotations per second
        YawOffset = 0,   -- Horizontal spin offset
        PitchOffset = 0, -- Vertical tilt
        SpinMode = "Spin" -- "Spin", "Jitter", or "Static"
    },
    WorldMods = {
        Enabled = false,
        TerrainColor = Color3.fromRGB(0, 255, 0), -- Default green
        AmbientColor = Color3.fromRGB(255, 255, 255), -- Default white
        BrightnessLevel = 1 -- Normal brightness
    },
    Aimbot = {
        Enabled = false,
        SilentAim = false,
        FOV = 200,
        FOVVisible = true,
        FOVColor = Color3.fromRGB(255, 255, 255),
        TeamCheck = true,
        TargetPart = "Head", -- Head, Torso, etc.
        Smoothness = 0.5, -- Lower = faster (for visible aimbot)
        WallCheck = true, -- New: Check for walls
        VisibilityCheck = true, -- New: Check visibility
        TargetPriority = "FOV", -- FOV or Distance based targeting
        HitChance = 100, -- New: Hit chance percentage
        HitboxExpansion = 0.5 -- New: Make hitboxes easier to hit
    },
    Camera = {
        CustomFOV = false,
        FOVValue = 70 -- Default FOV
    }
}

-- Storage for drawing objects
local ESPObjects = {}
local CrateESPObjects = {}

-- State variables
local flying = false
local flyPos = Vector3.new()
local trainRob = true
local bankTruck = true
local wallChildren = {}
local equippeditems = {}
local casinoCode = "Checking..."

-- Movement state variables
local movementDirection = Vector3.new()
local antiAimRotation = 0

-- Silent aim state variables
local silentAimTarget = nil
local originalFireServer = nil
local originalInvokeServer = nil

-- Utility Functions
local function thread(func)
    return coroutine.resume(coroutine.create(function()
        return func()
    end))
end

local function notify(text)
    local formattedText = "<font color='#55AAFF'>[Project KILLD] " .. text .. "</font>"
    
    if TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService then
        game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {["Text"] = formattedText})
    else
        TextChatService.TextChannels.RBXGeneral:DisplaySystemMessage(formattedText)
    end
    
    library:SendNotification(text, 5)
end

local function tableCount(t)
    local count = 0
    for _, _ in pairs(t) do
        count = count + 1
    end
    return count
end

local function tableHas(table, value)
    for _, v in pairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

local function watchProperty(object, property, callback)
    local current = object[property]
    local elapsedTime = 0
    local enabled = true
    local connection = {}
    
    connection.Stop = function()
        enabled = false
    end
    
    thread(function()
        while enabled do
            if object[property] ~= current then
                thread(function()
                    callback(object[property], current, elapsedTime)
                end)
                elapsedTime = 0
                current = object[property]
            end
            elapsedTime = elapsedTime + task.wait()
        end
    end)
    
    return connection
end

local function watchTable(table, callback)
    local count = tableCount(table)
    local clone = table.clone(table)
    local elapsedTime = 0
    local enabled = true
    local connection = {}
    
    connection.Stop = function()
        enabled = false
    end
    
    thread(function()
        while enabled do
            if tableCount(table) ~= count then
                if tableCount(table) > count then
                    for i, v in pairs(table) do
                        if clone[i] == nil then
                            thread(function()
                                callback(i, v, elapsedTime)
                            end)
                        end
                    end
                    elapsedTime = 0
                end
                count = tableCount(table)
                clone = table.clone(table)
            end
            elapsedTime = elapsedTime + task.wait()
        end
    end)
    
    return connection
end

local function keyDown(keycode)
    return UserInputService:IsKeyDown(keycode) and not UserInputService:GetFocusedTextBox()
end

local function getVehicleModel()
    local vehicleUtils = require(ReplicatedStorage.Vehicle.VehicleUtils)
    return vehicleUtils.GetLocalVehicleModel()
end

local function isDriverOfVehicle()
    local model = getVehicleModel()
    if model then
        local vehicleUtils = require(ReplicatedStorage.Vehicle.VehicleUtils)
        local seats = vehicleUtils.getSeats(model)
        for _, seat in pairs(seats) do
            if seat.Part.Name == "Seat" and seat.Player == LocalPlayer then
                return true
            end
        end
    end
    return false
end

local function getPlayerTeam(player)
    local team = player.Team
    if team then
        return team.Name
    end
    return "Unknown"
end

local function getEquippedItem()
    for itemName, equipped in pairs(equippeditems) do
        if equipped then
            return itemName
        end
    end
    return nil
end

local function getVelocity(pos1, pos2, speed)
    local distance = (pos2 - pos1)
    local mag = distance.Magnitude
    return (distance/mag) * speed
end

-- Fix for isVisible function (replace your current isVisible function)
local function isVisible(origin, target)
    if not Config.Aimbot.VisibilityCheck then return true end
    
    -- Create ray from origin to target
    local direction = (target.Position - origin).Unit * 1000
    local ray = Ray.new(origin, direction)
    
    -- Setup ignore list safely (avoid "Parent is not a valid member" error)
    local ignoreList = {LocalPlayer.Character}
    
    -- Add target's parent to ignore list only if it exists
    if target and target.Parent then
        table.insert(ignoreList, target.Parent)
    end
    
    -- Add walls to ignore list if wall shooting is enabled
    if Config.Toggles.ShootThroughWalls then
        for _, wall in ipairs(wallChildren) do
            table.insert(ignoreList, wall)
        end
    end
    
    -- Check ray collision
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    
    -- Consider it visible if hit point is close to target
    if hit then
        local hitDistance = (position - target.Position).Magnitude
        return hitDistance < 5 -- 5 studs tolerance
    end
    
    return true
end

-- Integrated movement and anti-aim system
local function setupIntegratedMovement()
    local lastUpdateTime = tick()
    
    RunService.Heartbeat:Connect(function()
        local deltaTime = tick() - lastUpdateTime
        lastUpdateTime = tick()
        
        -- Get character root part
        local hrp = nil
        local vehicle = nil
        local flySpeed = Config.Movement.FlySpeed
        local maxDistance = flySpeed * 2
        
        -- Check if we're in a vehicle
        vehicle = getVehicleModel()
        if vehicle and isDriverOfVehicle() then
            hrp = vehicle.PrimaryPart
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                if LocalPlayer.Character.Humanoid.Health > 0 and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    hrp = LocalPlayer.Character.HumanoidRootPart
                end
            end
            
            if flySpeed > 150 then
                flySpeed = 150 -- Cap speed when not in vehicle
            end
        end
        
        if not hrp then return end
        
        -- Calculate movement direction
        local movementVelocity = Vector3.new(0, 0, 0)
        
        if flying and Config.Movement.FlyEnabled then
            local frontOffset = CFrame.new() + Vector3.new(0, 0, -maxDistance)
            local backOffset = CFrame.new() + Vector3.new(0, 0, maxDistance)
            local leftOffset = CFrame.new() + Vector3.new(-maxDistance, 0, 0)
            local rightOffset = CFrame.new() + Vector3.new(maxDistance, 0, 0)
            local upOffset = CFrame.new() + Vector3.new(0, maxDistance, 0)
            local downOffset = CFrame.new() + Vector3.new(0, -maxDistance, 0)
            
            -- Reset rotation velocity if we're flying
            hrp.RotVelocity = Vector3.new()
            
            -- Calculate movement directions based on key presses
            if keyDown(Enum.KeyCode.W) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (hrp.CFrame * frontOffset).Position, flySpeed)
            end
            
            if keyDown(Enum.KeyCode.S) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (hrp.CFrame * backOffset).Position, flySpeed)
            end
            
            if keyDown(Enum.KeyCode.A) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (hrp.CFrame * leftOffset).Position, flySpeed)
            end
            
            if keyDown(Enum.KeyCode.D) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (hrp.CFrame * rightOffset).Position, flySpeed)
            end
            
            if keyDown(Enum.KeyCode.E) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (CFrame.new(hrp.Position) * upOffset).Position, flySpeed)
            end
            
            if keyDown(Enum.KeyCode.Q) then
                movementVelocity = movementVelocity + getVelocity(hrp.Position, (CFrame.new(hrp.Position) * downOffset).Position, flySpeed)
            end
            
            -- Apply velocity
            hrp.Velocity = movementVelocity
            
            -- Save current position if we're not moving
            if not keyDown(Enum.KeyCode.W) and not keyDown(Enum.KeyCode.A) and not keyDown(Enum.KeyCode.S) and 
               not keyDown(Enum.KeyCode.D) and not keyDown(Enum.KeyCode.Q) and not keyDown(Enum.KeyCode.E) then
                flyPos = hrp.Position
            else
                flyPos = hrp.Position
            end
        end
        
        -- Handle anti-aim (rotation) separately from movement
        if Config.AntiAim.Enabled then
            -- Only apply anti-aim if we're not in a vehicle
            if not vehicle then
                -- Update rotation based on anti-aim settings
                if Config.AntiAim.SpinMode == "Spin" then
                    -- Regular spinning motion
                    antiAimRotation = antiAimRotation + deltaTime * Config.AntiAim.SpinSpeed * 360
                    if antiAimRotation >= 360 then antiAimRotation = antiAimRotation - 360 end
                    
                    -- Preserve position but apply rotation
                    local currentPos = hrp.Position
                    hrp.CFrame = CFrame.new(currentPos) * 
                                CFrame.Angles(math.rad(Config.AntiAim.PitchOffset), 
                                             math.rad(antiAimRotation + Config.AntiAim.YawOffset), 0)
                                             
                elseif Config.AntiAim.SpinMode == "Jitter" then
                    -- Rapid direction changes
                    antiAimRotation = (math.floor(tick() * Config.AntiAim.SpinSpeed) % 2 == 0) and 90 or -90
                    
                    -- Preserve position but apply rotation
                    local currentPos = hrp.Position
                    hrp.CFrame = CFrame.new(currentPos) * 
                                CFrame.Angles(math.rad(Config.AntiAim.PitchOffset), 
                                             math.rad(antiAimRotation + Config.AntiAim.YawOffset), 0)
                                             
                elseif Config.AntiAim.SpinMode == "Static" then
                    -- Fixed angle, apply once
                    local currentPos = hrp.Position
                    hrp.CFrame = CFrame.new(currentPos) * 
                                CFrame.Angles(math.rad(Config.AntiAim.PitchOffset), 
                                             math.rad(Config.AntiAim.YawOffset), 0)
                end
                
                -- If flying is also enabled, make sure we maintain the appropriate forward direction 
                -- so that W, A, S, D controls work relative to camera
                if flying and Config.Movement.FlyEnabled then
                    local lookDir = (Camera.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
                    local rightDir = Camera.CFrame.RightVector
                    local currentPos = hrp.Position
                    
                    -- This preserves anti-aim for others but lets fly controls work as expected
                    if movementVelocity.Magnitude > 0 then
                        -- Only update look direction when actively moving
                        hrp.CFrame = CFrame.new(currentPos, currentPos + lookDir) * 
                                     CFrame.Angles(math.rad(Config.AntiAim.PitchOffset), 
                                                  math.rad(antiAimRotation + Config.AntiAim.YawOffset), 0)
                    end
                end
            end
        end
        
        -- If fly enabled but not moving, maintain position
        if flying and Config.Movement.FlyEnabled and movementVelocity.Magnitude <= 0 then
            if not Config.AntiAim.Enabled then
                -- If anti-aim is not enabled, just look at where camera is facing
                hrp.CFrame = CFrame.new(flyPos, Camera.CFrame.Position + Camera.CFrame.LookVector * 10)
            end
            hrp.Velocity = Vector3.new(0, 0, 0)
        end
    end)
    
    -- Keybind for fly
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            flying = not flying
            Config.Movement.FlyEnabled = flying
            
            if flying then
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(2, 0, 0)
                end
                notify("Fly enabled - Press CTRL+F to disable")
            else
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
                notify("Fly disabled")
            end
        end
    end)
end

-- Completely revised silent aim implementation
local function setupSilentAim()
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 2
    FOVCircle.NumSides = 100
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.ZIndex = 999
    FOVCircle.Transparency = 1
    FOVCircle.Color = Config.Aimbot.FOVColor

    -- Improved findBestTarget function with error handling
    local function findBestTarget()
        local closestDistance = math.huge
        local closestPlayer = nil
        local closestFOVDistance = Config.Aimbot.FOV
        local closestFOVPlayer = nil
        
        for _, player in pairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            
            -- Basic validation
            if not player.Character or 
            not player.Character:FindFirstChild("Humanoid") or 
            player.Character.Humanoid.Health <= 0 then 
                continue 
            end
            
            -- Get target part with fallback
            local targetPart = player.Character:FindFirstChild(Config.Aimbot.TargetPart)
            if not targetPart then 
                targetPart = player.Character:FindFirstChild("HumanoidRootPart")
                if not targetPart then continue end
            end
            
            -- Team check
            if Config.Aimbot.TeamCheck and player.Team == LocalPlayer.Team then continue end
            
            -- Visibility/wall check with error handling
            if Config.Aimbot.WallCheck then
                local success, result = pcall(function()
                    return isVisible(Camera.CFrame.Position, targetPart)
                end)
                
                if not success or not result then continue end
            end
            
            -- Screen position check
            local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
            if not onScreen then continue end
            
            -- Calculate distances
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            local screenPos2D = Vector2.new(screenPos.X, screenPos.Y)
            local fovDistance = (screenPos2D - mousePos).Magnitude
            local actualDistance = (targetPart.Position - Camera.CFrame.Position).Magnitude
            
            -- Track closest by FOV
            if fovDistance < closestFOVDistance then
                closestFOVDistance = fovDistance
                closestFOVPlayer = player
            end
            
            -- Track closest by distance
            if actualDistance < closestDistance then
                closestDistance = actualDistance
                closestPlayer = player
            end
        end
        
        -- Return target based on priority setting
        if Config.Aimbot.TargetPriority == "FOV" then
            return closestFOVPlayer
        else -- "Distance"
            return closestPlayer
        end
    end
    
    -- Implementation for the namecall hook in your silent aim
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    setreadonly(mt, false)

    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        
        -- Apply silent aim only to Fire/InvokeServer calls
        if Config.Aimbot.Enabled and Config.Aimbot.SilentAim and 
        (method == "FireServer" or method == "InvokeServer") and 
        typeof(self) == "Instance" then
            
            -- Check if this is a weapon remote event
            local remoteName = self.Name:lower()
            if remoteName:find("hit") or remoteName:find("fire") or remoteName:find("damage") or remoteName:find("bullet") then
                -- Hit chance check
                if math.random(1, 100) > Config.Aimbot.HitChance then
                    return oldNamecall(self, ...)
                end
                
                -- Find target
                local target = findBestTarget()
                if target then
                    -- Get target part
                    local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart) or 
                                    target.Character:FindFirstChild("HumanoidRootPart")
                    
                    -- Modify arguments based on common remote patterns
                    if typeof(args[1]) == "Instance" and args[1]:IsA("BasePart") then
                        args[1] = targetPart
                    elseif typeof(args[1]) == "CFrame" then
                        args[1] = targetPart.CFrame
                    elseif typeof(args[1]) == "Vector3" then
                        args[1] = targetPart.Position
                    elseif typeof(args[1]) == "table" then
                        if args[1].Part then args[1].Part = targetPart end
                        if args[1].Position then args[1].Position = targetPart.Position end
                        if args[1].hit then args[1].hit = targetPart end
                    end
                    
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        
        return oldNamecall(self, ...)
    end)

    setreadonly(mt, true)
    
    -- Update FOV circle
    RunService.RenderStepped:Connect(function()
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.Aimbot.FOV
        FOVCircle.Visible = Config.Aimbot.Enabled and Config.Aimbot.FOVVisible
        FOVCircle.Color = Config.Aimbot.FOVColor
        
        -- Update target if aimbot is enabled
        if Config.Aimbot.Enabled and Config.Aimbot.SilentAim then
            silentAimTarget = findBestTarget()
        else
            silentAimTarget = nil
        end
    end)
    
    -- Cleanup when script is stopped
    game:GetService("Players").PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            FOVCircle:Remove()
            setreadonly(mt, false)
            mt.__namecall = oldNamecall
            setreadonly(mt, true)
        end
    end)
end

-- Feature Functions
local function setupESP()
    -- Create ESP for all players
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local esp = {}
            
            -- Box
            esp.Box = Drawing.new("Square")
            esp.Box.Thickness = Config.ESP.BoxThickness
            esp.Box.Filled = false
            esp.Box.Transparency = 1
            
            -- Player Name
            esp.Name = Drawing.new("Text")
            esp.Name.Size = Config.ESP.TextSize
            esp.Name.Center = true
            esp.Name.Outline = true
            esp.Name.Transparency = 1
            
            -- Distance
            esp.Distance = Drawing.new("Text")
            esp.Distance.Size = Config.ESP.TextSize
            esp.Distance.Center = true
            esp.Distance.Outline = true
            esp.Distance.Transparency = 1
            
            -- Tracer
            esp.Tracer = Drawing.new("Line")
            esp.Tracer.Thickness = Config.ESP.TracerThickness
            esp.Tracer.Transparency = 1
            
            ESPObjects[player] = esp
        end
    end
    
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            local esp = {}
            
            esp.Box = Drawing.new("Square")
            esp.Box.Thickness = Config.ESP.BoxThickness
            esp.Box.Filled = false
            esp.Box.Transparency = 1
            
            esp.Name = Drawing.new("Text")
            esp.Name.Size = Config.ESP.TextSize
            esp.Name.Center = true
            esp.Name.Outline = true
            esp.Name.Transparency = 1
            
            esp.Distance = Drawing.new("Text")
            esp.Distance.Size = Config.ESP.TextSize
            esp.Distance.Center = true
            esp.Distance.Outline = true
            esp.Distance.Transparency = 1
            
            esp.Tracer = Drawing.new("Line")
            esp.Tracer.Thickness = Config.ESP.TracerThickness
            esp.Tracer.Transparency = 1
            
            ESPObjects[player] = esp
        end
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        if ESPObjects[player] then
            for _, object in pairs(ESPObjects[player]) do
                object:Remove()
            end
            ESPObjects[player] = nil
        end
    end)
    
    -- Update ESP on RenderStepped
    RunService.RenderStepped:Connect(function()
        if not Config.ESP.Enabled then
            -- Hide all ESP objects if disabled
            for _, esp in pairs(ESPObjects) do
                for _, object in pairs(esp) do
                    object.Visible = false
                end
            end
            return
        end
        
        local tracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 50)
        
        for player, esp in pairs(ESPObjects) do
            if not player or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") or not player.Character:FindFirstChild("Humanoid") then
                for _, object in pairs(esp) do
                    object.Visible = false
                end
                continue
            end
            
            if player.Character.Humanoid.Health <= 0 then
                for _, object in pairs(esp) do
                    object.Visible = false
                end
                continue
            end
            
            local team = getPlayerTeam(player)
            
            -- Check if we should show ESP for this team
            local showESP = false
            if team == "Police" and Config.ESP.PoliceEnabled then
                showESP = true
            elseif team == "Prisoner" and Config.ESP.PrisonerEnabled then
                showESP = true
            elseif team == "Criminal" and Config.ESP.CriminalEnabled then
                showESP = true
            end
            
            if not showESP then
                for _, object in pairs(esp) do
                    object.Visible = false
                end
                continue
            end
            
            local hrp = player.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            
            local distance = (hrp.Position - Camera.CFrame.Position).Magnitude
            if onScreen and distance <= Config.ESP.MaxDistance then
                -- Calculate box size based on distance
                local size = 2000 / distance
                local boxSize = Vector2.new(size, size * 1.5)
                
                -- Update box
                esp.Box.Visible = Config.ESP.BoxEnabled
                esp.Box.Size = boxSize
                esp.Box.Position = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
                
                local boxColor = Color3.fromRGB(255, 255, 255)
                if Config.ESP.TeamColorEnabled then
                    if team == "Police" then
                        boxColor = Config.ESP.BoxColors.Police
                    elseif team == "Prisoner" then
                        boxColor = Config.ESP.BoxColors.Prisoner
                    elseif team == "Criminal" then
                        boxColor = Config.ESP.BoxColors.Criminal
                    end
                end
                
                esp.Box.Color = boxColor
                
                -- Update name
                esp.Name.Visible = Config.ESP.NameEnabled
                esp.Name.Text = player.Name
                esp.Name.Position = Vector2.new(pos.X, pos.Y - boxSize.Y / 2 - 15)
                esp.Name.Color = Config.ESP.TeamColorEnabled and boxColor or Config.ESP.TextColor
                
                -- Update distance
                esp.Distance.Visible = Config.ESP.DistanceEnabled
                esp.Distance.Text = math.floor(distance) .. "m"
                esp.Distance.Position = Vector2.new(pos.X, pos.Y + boxSize.Y / 2 + 5)
                esp.Distance.Color = Config.ESP.TeamColorEnabled and boxColor or Config.ESP.TextColor
                
                -- Update tracer
                esp.Tracer.Visible = Config.ESP.TracersEnabled
                esp.Tracer.From = tracerOrigin
                esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                esp.Tracer.Color = Config.ESP.TeamColorEnabled and boxColor or Config.ESP.TextColor
            else
                -- Hide if off screen or too far
                for _, object in pairs(esp) do
                    object.Visible = false
                end
            end
        end
    end)
end

local function setupCrateESP()
    -- Function to add ESP for a crate
    local function addCrateESP(crate)
        if crate.Name == "Drop" then
            local rootPart = crate:WaitForChild("Root", 5)
            if rootPart then
                local esp = {}
                
                -- Text label for crate
                esp.Label = Drawing.new("Text")
                esp.Label.Size = 18
                esp.Label.Center = true
                esp.Label.Outline = true
                esp.Label.Transparency = 1
                esp.Label.Color = Color3.fromRGB(85, 170, 255)
                
                -- Tracer for crate
                esp.Tracer = Drawing.new("Line")
                esp.Tracer.Thickness = 1
                esp.Tracer.Transparency = 1
                esp.Tracer.Color = Color3.fromRGB(85, 170, 255)
                
                CrateESPObjects[crate] = esp
                
                -- Remove ESP when crate is removed
                crate.AncestryChanged:Connect(function(_, parent)
                    if not parent then
                        for _, obj in pairs(CrateESPObjects[crate]) do
                            obj:Remove()
                        end
                        CrateESPObjects[crate] = nil
                    end
                end)
            end
        end
    end
    
    -- Add ESP for existing crates
    for _, child in pairs(workspace:GetChildren()) do
        if child.Name == "Drop" then
            addCrateESP(child)
        end
    end
    
    -- Add ESP for new crates
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "Drop" then
            addCrateESP(child)
        end
    end)
    
    -- Update crate ESP
    RunService.RenderStepped:Connect(function()
        if not Config.Toggles.CrateESP then
            for _, esp in pairs(CrateESPObjects) do
                for _, obj in pairs(esp) do
                    obj.Visible = false
                end
            end
            return
        end
        
        for crate, esp in pairs(CrateESPObjects) do
            if crate and crate:FindFirstChild("Root") then
                local rootPos = crate.Root.Position
                local pos, onScreen = Camera:WorldToViewportPoint(rootPos)
                
                if onScreen then
                    local distance = (rootPos - Camera.CFrame.Position).Magnitude
                    
                    -- Update label
                    esp.Label.Visible = true
                    esp.Label.Position = Vector2.new(pos.X, pos.Y - 40)
                    esp.Label.Text = "Crate | Distance: " .. math.floor(distance)
                    
                    -- Update tracer
                    esp.Tracer.Visible = true
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 50)
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                else
                    esp.Label.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                if esp then
                    esp.Label.Visible = false
                    esp.Tracer.Visible = false
                end
            end
        end
    end)
end

-- Functions to implement features
local function setupWorldMods()
    -- Setup terrain color changing
    local terrain = workspace:FindFirstChildOfClass("Terrain")
    if not terrain then return end
    
    -- Track changes to the color config
    RunService.RenderStepped:Connect(function()
        if Config.WorldMods.Enabled then
            -- Apply terrain color
            terrain.WaterColor = Config.WorldMods.TerrainColor
            terrain.WaterReflectance = 0.1 -- Reduce reflectance for better color visibility
            
            -- Apply ambient
            game:GetService("Lighting").Ambient = Config.WorldMods.AmbientColor
            game:GetService("Lighting").Brightness = Config.WorldMods.BrightnessLevel
        end
    end)
end

local function setupCameraFOV()
    -- Setup custom camera FOV
    RunService.RenderStepped:Connect(function()
        if Config.Camera.CustomFOV then
            workspace.CurrentCamera.FieldOfView = Config.Camera.FOVValue
        end
    end)
end

local function setupRobberyNotifier()
    local robberyStateFolder = ReplicatedStorage:FindFirstChild("RobberyState")
    if not robberyStateFolder then
        notify("Could not find robbery state folder")
        return
    end
    
    -- Initialize robbery status
    for _, robbery in pairs(robberyStateFolder:GetChildren()) do
        if robbery:IsA("IntValue") then
            local robberyKey = robbery.Name
            Config.Robbery.Status[robberyKey] = robbery.Value
            
            -- Connect to value changed
            robbery.Changed:Connect(function(newValue)
                local oldValue = Config.Robbery.Status[robberyKey]
                Config.Robbery.Status[robberyKey] = newValue
                
                -- Only notify if robbery notifications are enabled
                if Config.Robbery.NotificationsEnabled then
                    local robberyName = Config.Robbery.Names[robberyKey] or robberyKey
                    
                    -- CLOSED -> OPENED (ready to rob)
                    if oldValue == Config.Robbery.StatusEnum.CLOSED and newValue == Config.Robbery.StatusEnum.OPENED then
                        notify("🚨 " .. robberyName .. " is now OPEN!")
                    -- OPENED -> STARTED (someone started robbing)
                    elseif oldValue == Config.Robbery.StatusEnum.OPENED and newValue == Config.Robbery.StatusEnum.STARTED then
                        notify("🔴 " .. robberyName .. " robbery started!")
                    -- STARTED -> CLOSED (robbery ended)
                    elseif oldValue == Config.Robbery.StatusEnum.STARTED and newValue == Config.Robbery.StatusEnum.CLOSED then
                        notify("❌ " .. robberyName .. " robbery completed!")
                    end
                end
            end)
        end
    end
    
    -- Monitor world markers for robbery status
    local function setupWorldMarkers()
        local worldMarkersGui = LocalPlayer.PlayerGui:WaitForChild("WorldMarkersGui", 10)
        if not worldMarkersGui then return end
        
        local iconIDs = {
            ["bank truck"] = "6133383545",
            ["gas station"] = "4643750797",
            ["donut shop"] = "4643750660",
            ["museum"] = "4643749917",
            ["tomb"] = "6896911415",
            ["casino"] = "9255252609",
            ["mansion"] = "11831534984",
            ["power plant"] = "4643749556",
            ["jewelry"] = "4643749718",
            ["bank"] = "4643749317",
            ["cargo train"] = "7301405189",
            ["cargo plane"] = "7301406769",
            ["cargo ship"] = "7301406299",
            ["passenger train"] = "7301405813",
            ["oil rig"] = "15617962600"
        }
        
        -- Monitor existing markers
        for _, marker in pairs(worldMarkersGui:GetChildren()) do
            for _, imageLabel in pairs(marker:GetChildren()) do
                if imageLabel:FindFirstChild("ImageLabel") then
                    for name, id in pairs(iconIDs) do
                        if imageLabel.ImageLabel.Image == "rbxassetid://" .. id then
                            imageLabel:GetPropertyChangedSignal("ImageColor3"):Connect(function()
                                local color = imageLabel.ImageColor3
                                if color == Color3.new(0, 1, 0) then
                                    if name == "bank truck" then
                                        if bankTruck then
                                            bankTruck = false
                                            notify("The bank truck is open")
                                        end
                                    else
                                        notify("The " .. name .. " is open for robbery")
                                    end
                                else 
                                    if name == "bank truck" then
                                        bankTruck = true
                                    end
                                end
                            end)
                        end
                    end
                end
            end
        end
        
        -- Monitor new markers
        worldMarkersGui.ChildAdded:Connect(function(marker)
            task.wait(0.1) -- Wait for the marker to load
            if marker:FindFirstChild("ImageLabel") and marker.ImageLabel:FindFirstChild("ImageLabel") then
                local img = marker.ImageLabel.ImageLabel.Image
                for name, id in pairs(iconIDs) do
                    if img == "rbxassetid://" .. id then
                        if name == "cargo train" or name == "passenger train" then
                            if trainRob then
                                notify("The " .. name .. " has entered the map")
                                trainRob = false
                                
                                task.delay(4, function()
                                    trainRob = true
                                end)
                            end
                        elseif name == "cargo ship" then
                            notify("The cargo ship is coming!")
                        elseif name == "cargo plane" then
                            notify("The cargo plane is inbound!")
                        else
                            if marker.ImageLabel.ImageColor3 == Color3.new(0, 1, 0) then
                                if name == "bank truck" then
                                    if bankTruck then
                                        bankTruck = false
                                        notify("The bank truck is open")
                                    end
                                else
                                    notify("The " .. name .. " is open for robbery")
                                end
                            else
                                if name == "bank truck" then
                                    bankTruck = true
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
    
    thread(function()
        setupWorldMarkers()
    end)
end

local function setupWalkSpeed()
    RunService.RenderStepped:Connect(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Config.Movement.WalkSpeed
        end
    end)
end

local function setupNoRagdoll()
    if ReplicatedStorage.Module and ReplicatedStorage.Module:FindFirstChild("AlexRagdoll") then
        require(ReplicatedStorage.Module.AlexRagdoll).Ragdoll = function() return end
    end
    
    if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("Falling") then
        require(ReplicatedStorage.Game.Falling).StartRagdolling = function() return end
    end
    
    notify("Removed ragdolling. You may still take fall damage.")
end

local function setupKeycardBypass()
    if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("PlayerUtils") then
        local PlayerUtils = require(ReplicatedStorage.Game.PlayerUtils)
        if PlayerUtils.hasKey then
            PlayerUtils.hasKey = function()
                return true
            end
            notify("Keycard bypass enabled")
        else
            notify("Could not find hasKey function")
        end
    else
        notify("Could not find PlayerUtils module")
    end
end

local function setupHoldEBypass()
    if ReplicatedStorage.Module and ReplicatedStorage.Module:FindFirstChild("UI") then
        local moduleUI = require(ReplicatedStorage.Module.UI)
        local namesToAvoid = {
            "grab documents",
            "grab computer",
            "grab briefcase",
            "grab phone",
            "grab spyglasses",
            "grab cash",
            "rob",
            "open crate",
            "place tnt",
            "disable security"
        }
        
        RunService.Heartbeat:Connect(function()
            if not moduleUI.CircleAction or not moduleUI.CircleAction.Specs then return end
            
            for _, spec in pairs(moduleUI.CircleAction.Specs) do
                local actionName = spec.Name and spec.Name:lower() or ""
                local shouldBypass = true
                
                for _, avoidName in pairs(namesToAvoid) do
                    if actionName:find(avoidName) then
                        shouldBypass = false
                        break
                    end
                end
                
                if spec.Duration and shouldBypass then
                    spec.Timed = false
                end
            end
        end)
        
        notify("Hold E Bypass enabled. Cannot be used with: donut shop, gas station, air drops, passenger train items, and oil rig dynamite.")
    else
        notify("Could not find UI module")
    end
end

local function setupForceDaytime()
    game:GetService("Lighting").ClockTime = 12
    
    game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
        if Config.Toggles.ForceDaytime then
            game:GetService("Lighting").ClockTime = 12
        end
    end)
    
    notify("Forced daytime enabled")
end

local function setupParachuteGlider()
    if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("Paraglide") then
        local paraModule = require(ReplicatedStorage.Game.Paraglide)
        local originalParachute = paraModule.Parachute
        
        paraModule.Parachute = function(...)
            if Config.Toggles.ReplaceParachute then
                return paraModule.Glider(...)
            else
                return originalParachute(...)
            end
        end
        
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            
            if input.KeyCode == Enum.KeyCode.G and Config.Toggles.GlideWithG then
                paraModule.Glider()
            end
        end)
        
        notify("Parachute/glider mods enabled")
    else
        notify("Could not find paraglide module")
    end
end

local function setupVehicleLockOnExit()
    if ReplicatedStorage.Vehicle and ReplicatedStorage.Vehicle:FindFirstChild("VehicleUtils") then
        local vehicle = require(ReplicatedStorage.Vehicle.VehicleUtils)
        
        if vehicle.OnVehicleJumpExited and vehicle.OnVehicleJumpExited._handlerListHead then
            local originalExit = vehicle.OnVehicleJumpExited._handlerListHead._fn
            
            vehicle.OnVehicleJumpExited._handlerListHead._fn = function(...)
                if Config.Toggles.LockOnExit and isDriverOfVehicle() then
                    -- Check if car is unlocked
                    local isLocked = false
                    pcall(function()
                        local speedometer = LocalPlayer.PlayerGui.AppUI.Speedometer
                        if speedometer and speedometer.Top and speedometer.Top.Lock and speedometer.Top.Lock.Icon then
                            isLocked = speedometer.Top.Lock.Icon.Image ~= "rbxassetid://5928936296"
                        end
                    end)
                    
                    if not isLocked then
                        vehicle.toggleLocalLocked()
                    end
                end
                
                return originalExit(...)
            end
            
            notify("Vehicle lock on exit enabled")
        else
            notify("Could not find vehicle exit handler")
        end
    else
        notify("Could not find vehicle utils module")
    end
end

local function setupWallShooting()
    -- Collect all parts to ignore for wall shooting
    local ignoreNames = {"MansionRobbery", "Drop"}
    
    -- Add workspace children to ignore list
    for _, child in pairs(workspace:GetChildren()) do
        if not table.find(ignoreNames, child.Name) and not Players:GetPlayerFromCharacter(child) then
            table.insert(wallChildren, child)
            
            -- Special handling for Drop
            if child.Name == "Drop" then
                for _, v in pairs(child:GetChildren()) do
                    if v.Name ~= "NPCs" then
                        table.insert(wallChildren, v)
                    end
                end
                
                -- Remove from list when destroyed
                child.AncestryChanged:Connect(function(_, parent)
                    if not parent then
                        for i, v in pairs(wallChildren) do
                            if v:IsDescendantOf(child) then
                                table.remove(wallChildren, i)
                            end
                        end
                    end
                end)
            end
        end
    end
    
    -- Add special mansion parts
    if workspace:FindFirstChild("MansionRobbery") then
        for _, child in pairs(workspace.MansionRobbery:GetChildren()) do
            if child.Name ~= "ActiveBoss" and child.Name ~= "GuardsFolder" then
                table.insert(wallChildren, child)
            end
        end
    end
    
    -- Monitor for new objects
    workspace.ChildAdded:Connect(function(child)
        if not table.find(ignoreNames, child.Name) and not Players:GetPlayerFromCharacter(child) then
            table.insert(wallChildren, child)
            
            -- Special handling for Drop
            if child.Name == "Drop" then
                for _, v in pairs(child:GetChildren()) do
                    if v.Name ~= "NPCs" then
                        table.insert(wallChildren, v)
                    end
                end
            end
        end
    end)
    
    -- Remove from list when destroyed
    workspace.ChildRemoved:Connect(function(child)
        local index = table.find(wallChildren, child)
        if index then
            table.remove(wallChildren, index)
        end
    end)
    
    -- Hook the gun shooting function
    if ReplicatedStorage.Game and ReplicatedStorage.Game.Item and ReplicatedStorage.Game.Item:FindFirstChild("Gun") then
        local gunModule = require(ReplicatedStorage.Game.Item.Gun)
        local originalShoot = gunModule.Shoot
        
        gunModule.Shoot = function(...)
            local args = {...}
            local main = args[1]
            local equippedItem = getEquippedItem()
            
            -- Don't apply to plasma weapons (they don't work well with this hack)
            if Config.Toggles.ShootThroughWalls and equippedItem and equippedItem ~= "PlasmaPistol" and equippedItem ~= "PlasmaShotgun" then
                if main.Humanoid and main.Humanoid.Parent == LocalPlayer.Character then
                    for _, part in pairs(wallChildren) do
                        if not table.find(main.BulletEmitter.IgnoreList, part) then
                            table.insert(main.BulletEmitter.IgnoreList, part)
                        end
                    end
                end
            end
            
            return originalShoot(...)
        end
        
        notify("Wall shooting enabled")
    else
        notify("Could not find gun module")
    end
end

local function disableNPCGuns()
    if ReplicatedStorage.Game and ReplicatedStorage.Game.Item and ReplicatedStorage.Game.Item:FindFirstChild("Gun") then
        local gunModule = require(ReplicatedStorage.Game.Item.Gun)
        local originalShoot = gunModule.Shoot
        
        gunModule.Shoot = function(...)
            local args = {...}
            local target = args[1]
            
            if target and target.Humanoid and Players:FindFirstChild(target.Humanoid.Parent.Name) then
                return originalShoot(...)
            end
            -- If not from a player, don't shoot
        end
        
        notify("NPC guns disabled. NPCs may still shoot if another player is nearby (server-sided limitation)")
    end
end

local function modifyGuns()
    local itemConfig = ReplicatedStorage:FindFirstChild("Game"):FindFirstChild("ItemConfig")
    if not itemConfig then
        notify("Could not find item config")
        return
    end
    
    -- Modify all guns
    for _, module in pairs(itemConfig:GetChildren()) do
        pcall(function()
            local gun = require(module)
            
            -- Special handling for shotgun
            if module.Name == "Shotgun" then
                if Config.Toggles.ReducedShotgunSpread then
                    gun.BulletSpread = 0.02
                end
                
                if Config.Toggles.SingleShotgunBullet then
                    gun.BulletSpread = 0
                end
            end
            
            -- Common modifications for all guns
            gun.CamShakeMagnitude = 0
            gun.FireAuto = true
        end)
    end
    
    -- Modify grenade
    pcall(function()
        local grenade = require(itemConfig.Grenade)
        grenade.ReloadTime = 0
        grenade.FuseTime = 0.8
    end)
    
    -- Allow equipping items in more situations
    pcall(function()
        local inventorySystem = require(ReplicatedStorage.Inventory.InventoryItemSystem)
        for i, _ in pairs(inventorySystem._equipConditions) do
            inventorySystem._equipConditions[i] = function() return true end
        end
        for i, _ in pairs(inventorySystem._unequipConditions) do
            inventorySystem._unequipConditions[i] = function() return true end
        end
    end)
    
    notify("Guns modded: No recoil, auto-fire, faster grenades, and more")
end

local function modifyTazer()
    -- Look through registry tables for tazer values
    for i, v in pairs(getgc(true)) do
        if type(v) == "table" then
            -- Check if we can modify this table
            if rawget(v, "ReloadTime") and rawget(v, "ReloadTimeHit") then
                if typeof(v.ReloadTime) == "number" and typeof(v.ReloadTimeHit) == "number" then
                    -- This is likely the tazer table, modify the values
                    v.ReloadTime = 0
                    v.ReloadTimeHit = 0
                end
            end
        end
    end
    
    notify("Tazer cooldown removed")
end

local function trackCasinoCode()
    RunService.RenderStepped:Connect(function()
        if workspace:FindFirstChild("Casino") and workspace.Casino:FindFirstChild("RobberyDoor") and workspace.Casino.RobberyDoor:FindFirstChild("Codes") then
            local codes = workspace.Casino.RobberyDoor.Codes
            local isOpen = workspace.Casino:GetAttribute("CasinoRobberyOpen")
            
            if isOpen then
                local codeScreen
                for _, v in pairs(codes:GetChildren()) do
                    if v:FindFirstChildOfClass("Part") and v:FindFirstChildOfClass("Part"):FindFirstChild("SurfaceGui") and 
                       v:FindFirstChildOfClass("Part").SurfaceGui:FindFirstChild("TextLabel") and 
                       v:FindFirstChildOfClass("Part").SurfaceGui.TextLabel.Text ~= "" then
                        codeScreen = v
                        break
                    end
                end
                
                if codeScreen then
                    local txt = ""
                    local codeParts = {}
                    
                    -- Sort the code parts by position
                    for _, part in pairs(codeScreen:GetChildren()) do
                        if part:IsA("BasePart") and part:FindFirstChild("SurfaceGui") then
                            table.insert(codeParts, {
                                magnitude = part.Position.Magnitude,
                                text = part.SurfaceGui.TextLabel.Text
                            })
                        end
                    end
                    
                    table.sort(codeParts, function(a, b) return a.magnitude < b.magnitude end)
                    
                    for _, part in pairs(codeParts) do
                        txt = txt .. part.text
                    end
                    
                    -- Check if code is palindrome
                    if txt ~= string.reverse(txt) then
                        casinoCode = txt .. " (or " .. string.reverse(txt) .. ")"
                    else
                        casinoCode = txt
                    end
                end
            else
                casinoCode = "Casino is currently closed"
            end
        else
            casinoCode = "Casino building isn't loaded"
        end
    end)
end

local function setupAutoRespawn()
    notify("Click Respawn again to confirm")
    
    local confirmTime = os.time() + 3
    local confirmed = false
    
    return function()
        if confirmed then
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.Health = 0
                confirmed = false
            end
        else
            confirmed = true
            notify("Click Respawn again to confirm")
            
            spawn(function()
                while confirmed do
                    if os.time() > confirmTime then
                        confirmed = false
                        notify("Respawn cancelled")
                        break
                    end
                    wait(0.1)
                end
            end)
        end
    end
end

-- Hook inventory equip remote to track equipped items
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    if self.Name == "InventoryEquipRemote" and method == "FireServer" and self.Parent and self.Parent.Parent == LocalPlayer.Folder then
        equippeditems[self.Parent.Name] = args[1]
    end
    
    return oldNamecall(self, ...)
end)

-- GUI Setup
local Window = library:NewWindow({
    title = "Project KILLD | Jailbreak", -- Mainwindow Text
    size = UDim2.new(0, 510, 0.6, 6)
})

-- Create Tabs
local MainTab = Window:AddTab("Main")
local ESPTab = Window:AddTab("ESP")
local GunTab = Window:AddTab("Guns")
local VehicleTab = Window:AddTab("Vehicle")
local MovementTab = Window:AddTab("Movement")
local UtilityTab = Window:AddTab("Utility")
local SettingsTab = library:CreateSettingsTab(Window)

-- Main Tab
local MainSection = MainTab:AddSection("Information", 1)

-- Casino Code Display
local casinoCodeText = MainSection:AddButton({
    enabled = true,
    text = "Casino Code: Checking...",
    callback = function() end  -- Empty callback since it's just for display
})

-- Then instead of updating a label, we would update the button text:
spawn(function()
    while wait(1) do
        casinoCodeText:SetText("Casino Code: " .. casinoCode)
    end
end)

-- Robbery Notifications
MainSection:AddToggle({
    text = "Robbery Notifications",
    state = Config.Robbery.NotificationsEnabled,
    flag = "RobberyNotifications",
    callback = function(value)
        Config.Robbery.NotificationsEnabled = value
    end
})

-- Other Main Options
local MainUtilSection = MainTab:AddSection("Utilities", 2)

MainUtilSection:AddButton({
    text = "Respawn",
    callback = setupAutoRespawn()
})

MainUtilSection:AddButton({
    text = "Delete Radio GUI",
    callback = function()
        Config.Toggles.DeleteRadio = true
        RunService.RenderStepped:Connect(function()
            if Config.Toggles.DeleteRadio and LocalPlayer.PlayerGui:FindFirstChild("RadioGui") then
                LocalPlayer.PlayerGui.RadioGui:Destroy()
            end
        end)
        notify("Radio GUI will be auto-deleted")
    end
})

MainUtilSection:AddButton({
    text = "Infinite Yield",
    callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end
})

-- ESP Tab
local ESPSection = ESPTab:AddSection("ESP Settings", 1)

ESPSection:AddToggle({
    text = "Player ESP",
    state = Config.ESP.Enabled,
    flag = "ESPEnabled",
    callback = function(value)
        Config.ESP.Enabled = value
    end
})

-- Team ESP Settings
ESPSection:AddToggle({
    text = "Police ESP",
    state = Config.ESP.PoliceEnabled,
    flag = "PoliceESP",
    callback = function(value)
        Config.ESP.PoliceEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Prisoner ESP",
    state = Config.ESP.PrisonerEnabled,
    flag = "PrisonerESP",
    callback = function(value)
        Config.ESP.PrisonerEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Criminal ESP",
    state = Config.ESP.CriminalEnabled,
    flag = "CriminalESP",
    callback = function(value)
        Config.ESP.CriminalEnabled = value
    end
})

ESPSection:AddSeparator({
    text = "ESP Features"
})

ESPSection:AddToggle({
    text = "Box ESP",
    state = Config.ESP.BoxEnabled,
    flag = "BoxESP",
    callback = function(value)
        Config.ESP.BoxEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Name ESP",
    state = Config.ESP.NameEnabled,
    flag = "NameESP",
    callback = function(value)
        Config.ESP.NameEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Distance ESP",
    state = Config.ESP.DistanceEnabled,
    flag = "DistanceESP",
    callback = function(value)
        Config.ESP.DistanceEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Tracers",
    state = Config.ESP.TracersEnabled,
    flag = "TracersESP",
    callback = function(value)
        Config.ESP.TracersEnabled = value
    end
})

ESPSection:AddToggle({
    text = "Use Team Colors",
    state = Config.ESP.TeamColorEnabled,
    flag = "TeamColorESP",
    callback = function(value)
        Config.ESP.TeamColorEnabled = value
    end
})

ESPSection:AddSlider({
    text = "ESP Max Distance",
    flag = "ESPDistance",
    min = 100,
    max = 5000,
    increment = 100,
    value = Config.ESP.MaxDistance,
    callback = function(value)
        Config.ESP.MaxDistance = value
    end
})

local OtherESPSection = ESPTab:AddSection("Other ESP", 2)

OtherESPSection:AddToggle({
    text = "Crate ESP",
    state = Config.Toggles.CrateESP,
    flag = "CrateESP",
    callback = function(value)
        Config.Toggles.CrateESP = value
    end
})

-- Gun Tab
local GunSection = GunTab:AddSection("Gun Mods", 1)

GunSection:AddButton({
    text = "Mod All Guns",
    callback = function()
        modifyGuns()
    end
})

GunSection:AddToggle({
    text = "Shoot Through Walls",
    state = Config.Toggles.ShootThroughWalls,
    flag = "WallShoot",
    callback = function(value)
        Config.Toggles.ShootThroughWalls = value
    end
})

GunSection:AddButton({
    text = "Disable NPC Guns",
    callback = function()
        disableNPCGuns()
    end
})

GunSection:AddButton({
    text = "No Tazer Cooldown",
    callback = function()
        modifyTazer()
    end
})

GunSection:AddToggle({
    text = "Reduced Shotgun Spread",
    state = Config.Toggles.ReducedShotgunSpread,
    flag = "ReducedShotgunSpread",
    callback = function(value)
        Config.Toggles.ReducedShotgunSpread = value
        modifyGuns()
    end
})

GunSection:AddToggle({
    text = "Single Shotgun Bullet",
    state = Config.Toggles.SingleShotgunBullet,
    flag = "SingleShotgunBullet",
    callback = function(value)
        Config.Toggles.SingleShotgunBullet = value
        modifyGuns()
    end
})

-- Vehicle Tab
local VehicleSection = VehicleTab:AddSection("Vehicle Mods", 1)

VehicleSection:AddToggle({
    text = "Auto-Lock Vehicle on Exit",
    state = Config.Toggles.LockOnExit,
    flag = "LockOnExit",
    callback = function(value)
        Config.Toggles.LockOnExit = value
        setupVehicleLockOnExit()
    end
})

-- Movement Tab
local MovementSection = MovementTab:AddSection("Movement", 1)

MovementSection:AddToggle({
    text = "Fly",
    state = Config.Movement.FlyEnabled,
    flag = "FlyEnabled",
    callback = function(value)
        Config.Movement.FlyEnabled = value
        flying = value
    end
}):AddBind({
    enabled = true,
    text = "Fly Keybind",
    bind = "F",
    flag = "FlyKeybind",
    mode = "toggle",
    callback = function(value)
        Config.Movement.FlyEnabled = value
        flying = value
    end
})

MovementSection:AddSlider({
    enabled = true,
    text = "Fly Speed",
    flag = "FlySpeed",
    suffix = "",
    min = 50,
    max = 600,
    increment = 50,
    callback = function(value)
        Config.Movement.FlySpeed = value
    end
})

MovementSection:AddSlider({
    text = "Walk Speed",
    flag = "WalkSpeed",
    min = 16,
    max = 150,
    increment = 2,
    value = Config.Movement.WalkSpeed,
    callback = function(value)
        Config.Movement.WalkSpeed = value
    end
})

MovementSection:AddToggle({
    text = "Toggle Gravity (0/196)",
    state = workspace.Gravity == 0,
    flag = "GravityToggle",
    callback = function(value)
        if value then
            workspace.Gravity = 0
        else
            workspace.Gravity = 196
        end
    end
})

-- Glider Section
local GliderSection = MovementTab:AddSection("Glider", 2)

GliderSection:AddToggle({
    text = "G Key to Glide",
    state = Config.Toggles.GlideWithG,
    flag = "GKeyGlide",
    callback = function(value)
        Config.Toggles.GlideWithG = value
    end
})

GliderSection:AddToggle({
    text = "Replace Parachute with Glider",
    state = Config.Toggles.ReplaceParachute,
    flag = "ReplaceParachute",
    callback = function(value)
        Config.Toggles.ReplaceParachute = value
    end
})

-- Utility Tab
local UtilitySection = UtilityTab:AddSection("Game Utilities", 1)

UtilitySection:AddToggle({
    text = "Keycard Bypass",
    state = Config.Toggles.KeycardBypass,
    flag = "KeycardBypass",
    callback = function(value)
        Config.Toggles.KeycardBypass = value
        if value then
            setupKeycardBypass()
        end
    end
})

UtilitySection:AddToggle({
    text = "Hold E Bypass",
    state = Config.Toggles.HoldEBypass,
    flag = "HoldEBypass",
    callback = function(value)
        Config.Toggles.HoldEBypass = value
        if value then
            setupHoldEBypass()
        end
    end
})

UtilitySection:AddToggle({
    text = "No Ragdoll",
    state = Config.Toggles.NoRagdoll,
    flag = "NoRagdoll",
    callback = function(value)
        Config.Toggles.NoRagdoll = value
        if value then
            setupNoRagdoll()
        end
    end
})

UtilitySection:AddToggle({
    text = "Force Daytime",
    state = Config.Toggles.ForceDaytime,
    flag = "ForceDaytime",
    callback = function(value)
        Config.Toggles.ForceDaytime = value
        if value then
            setupForceDaytime()
        end
    end
})

-- Creating AntiAim tab in UI
local AATab = Window:AddTab("Anti-Aim")
local AASection = AATab:AddSection("Spinbot", 1)

AASection:AddToggle({
    enabled = true,
    text = "Enable Anti-Aim",
    state = Config.AntiAim.Enabled,
    flag = "AntiAim_Enabled",
    callback = function(value)
        Config.AntiAim.Enabled = value
    end
})

AASection:AddList({
    enabled = true,
    text = "Spin Mode", 
    tooltip = "Type of rotation to apply",
    selected = Config.AntiAim.SpinMode,
    multi = false,
    values = {"Spin", "Jitter", "Static"},
    flag = "AntiAim_Mode",
    callback = function(value)
        Config.AntiAim.SpinMode = value
    end
})

AASection:AddSlider({
    enabled = true,
    text = "Spin Speed",
    flag = "AntiAim_Speed",
    suffix = " rps",
    min = 1,
    max = 100,
    increment = 1,
    value = Config.AntiAim.SpinSpeed,
    callback = function(value)
        Config.AntiAim.SpinSpeed = value
    end
})

AASection:AddSlider({
    enabled = true,
    text = "Yaw Offset",
    flag = "AntiAim_Yaw",
    suffix = "°",
    min = 0,
    max = 360,
    increment = 15,
    value = Config.AntiAim.YawOffset,
    callback = function(value)
        Config.AntiAim.YawOffset = value
    end
})

AASection:AddSlider({
    enabled = true,
    text = "Pitch Offset",
    flag = "AntiAim_Pitch",
    suffix = "°",
    min = -89,
    max = 89,
    increment = 5,
    value = Config.AntiAim.PitchOffset,
    callback = function(value)
        Config.AntiAim.PitchOffset = value
    end
})

-- UI Tabs for the new features
local AimbotTab = Window:AddTab("Aimbot")
local VisualTab = Window:AddTab("Visuals")

-- Aimbot UI
local AimbotSection = AimbotTab:AddSection("Silent Aim", 1)

AimbotSection:AddToggle({
    enabled = true,
    text = "Enable Silent Aim",
    state = Config.Aimbot.Enabled,
    flag = "Aimbot_Enabled",
    callback = function(value)
        Config.Aimbot.Enabled = value
        Config.Aimbot.SilentAim = value
    end
})

AimbotSection:AddToggle({
    enabled = true,
    text = "Team Check",
    state = Config.Aimbot.TeamCheck,
    flag = "Aimbot_TeamCheck",
    callback = function(value)
        Config.Aimbot.TeamCheck = value
    end
})

AimbotSection:AddToggle({
    enabled = true,
    text = "Wall Check",
    state = Config.Aimbot.WallCheck,
    flag = "Aimbot_WallCheck",
    callback = function(value)
        Config.Aimbot.WallCheck = value
    end
})

AimbotSection:AddToggle({
    enabled = true,
    text = "Show FOV Circle",
    state = Config.Aimbot.FOVVisible,
    flag = "FOV_Visible",
    callback = function(value)
        Config.Aimbot.FOVVisible = value
    end
})

AimbotSection:AddSlider({
    enabled = true,
    text = "FOV Size",
    flag = "Aimbot_FOV",
    suffix = "px",
    min = 50,
    max = 800,
    increment = 10,
    value = Config.Aimbot.FOV,
    callback = function(value)
        Config.Aimbot.FOV = value
    end
})

AimbotSection:AddSlider({
    enabled = true,
    text = "Hit Chance",
    flag = "Aimbot_HitChance",
    suffix = "%",
    min = 1,
    max = 100,
    increment = 1,
    value = Config.Aimbot.HitChance,
    callback = function(value)
        Config.Aimbot.HitChance = value
    end
})

AimbotSection:AddList({
    enabled = true,
    text = "Target Part", 
    selected = Config.Aimbot.TargetPart,
    multi = false,
    values = {"Head", "HumanoidRootPart", "Torso", "LeftArm", "RightArm", "LeftLeg", "RightLeg"},
    flag = "Aimbot_Part",
    callback = function(value)
        Config.Aimbot.TargetPart = value
    end
})

AimbotSection:AddList({
    enabled = true,
    text = "Target Priority", 
    selected = Config.Aimbot.TargetPriority,
    multi = false,
    values = {"FOV", "Distance"},
    flag = "Aimbot_Priority",
    callback = function(value)
        Config.Aimbot.TargetPriority = value
    end
})

AimbotSection:AddColor({
    enabled = true,
    text = "FOV Circle Color",
    color = Config.Aimbot.FOVColor,
    flag = "FOV_Color",
    callback = function(value)
        Config.Aimbot.FOVColor = value
    end
})

-- Visuals UI
local VisualsSection = VisualTab:AddSection("World Modification", 1)

VisualsSection:AddToggle({
    enabled = true,
    text = "Enable World Mods",
    state = Config.WorldMods.Enabled,
    flag = "World_Enabled",
    callback = function(value)
        Config.WorldMods.Enabled = value
    end
})

VisualsSection:AddColor({
    enabled = true,
    text = "Terrain Color",
    color = Config.WorldMods.TerrainColor,
    flag = "Terrain_Color",
    callback = function(value)
        Config.WorldMods.TerrainColor = value
    end
})

VisualsSection:AddColor({
    enabled = true,
    text = "Ambient Light",
    color = Config.WorldMods.AmbientColor,
    flag = "Ambient_Color",
    callback = function(value)
        Config.WorldMods.AmbientColor = value
    end
})

VisualsSection:AddSlider({
    enabled = true,
    text = "Brightness",
    flag = "World_Brightness",
    suffix = "x",
    min = 0,
    max = 5,
    increment = 0.1,
    value = Config.WorldMods.BrightnessLevel,
    callback = function(value)
        Config.WorldMods.BrightnessLevel = value
    end
})

local CameraSection = VisualTab:AddSection("Camera", 2)

CameraSection:AddToggle({
    enabled = true,
    text = "Custom FOV",
    state = Config.Camera.CustomFOV,
    flag = "Custom_FOV",
    callback = function(value)
        Config.Camera.CustomFOV = value
    end
})

CameraSection:AddSlider({
    enabled = true,
    text = "FOV Value",
    flag = "FOV_Value",
    suffix = "°",
    min = 30,
    max = 120,
    increment = 1,
    value = Config.Camera.FOVValue,
    callback = function(value)
        Config.Camera.FOVValue = value
    end
})

-- Initialize functionality
thread(function()
    -- Set up core systems
    setupESP()
    setupCrateESP()
    setupRobberyNotifier()
    setupIntegratedMovement() -- Use integrated movement (fixes fly and anti-aim conflict)
    setupWalkSpeed()
    setupWallShooting()
    setupParachuteGlider()
    setupVehicleLockOnExit()
    trackCasinoCode()
    setupWorldMods()
    setupCameraFOV()
    setupSilentAim() -- Use the new silent aim implementation
    
    -- Send a notification when everything is ready
    local loadTime = string.format("%.2f", os.clock() - loadStartTime)
    notify("Project KILLD loaded in " .. loadTime .. "s")
    notify("Press Left Ctrl+F to toggle Fly")
end)

-- Clean up on script stop
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        -- Clean up ESP
        for player, esp in pairs(ESPObjects) do
            for _, object in pairs(esp) do
                object:Remove()
            end
        end
        
        -- Clean up crate ESP
        for _, esp in pairs(CrateESPObjects) do
            for _, object in pairs(esp) do
                object:Remove()
            end
        end
        
        -- Reset player's camera offset
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
        
        _G.ProjectKILLDRunning = false
    end
end)

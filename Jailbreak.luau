if _G.ScriptAlreadyRunning then
    return
end
_G.ScriptAlreadyRunning = true

-- Initialize the UI Library
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/drillygzzly/Roblox-UI-Libs/main/1%20Tokyo%20Lib%20(FIXED)/Tokyo%20Lib%20Source.lua"))({
    cheatname = "Project KILLD", -- watermark text
    gamename = "Jailbreak", -- watermark text
})

library:init()

local function BZWQK_fake_script() -- yeah yeah yeah
    local Decimals = 4
    local Clock = os.clock()
    local ValueText = "Value Is Now :"
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer

    -- Destroy the anti-cheat remote
    if ReplicatedStorage:FindFirstChild("HawkeyeRemoteFunction") then
        local hawkeye = ReplicatedStorage:FindFirstChild("HawkeyeRemoteFunction")
        if hawkeye and hawkeye.Parent then
            hawkeye:Destroy()
        end
    end

    -- ESP Configuration
    local ESPSettings = {
        Enabled = false,
        PoliceESP = true,
        PrisonerESP = true,
        CriminalESP = true,
        BoxEnabled = true,
        NameEnabled = true,
        DistanceEnabled = true,
        TracersEnabled = true,
        TeamColorESP = true,
        MaxDistance = 2000,
        BoxColor = {
            Police = Color3.fromRGB(0, 0, 255),      -- Blue
            Prisoner = Color3.fromRGB(255, 165, 0),  -- Orange
            Criminal = Color3.fromRGB(255, 0, 0)     -- Red
        },
        BoxThickness = 2,
        TracerThickness = 1,
        TracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 50), -- Bottom middle
        TextSize = 14,
        TextColor = Color3.fromRGB(255, 255, 255)
    }

    -- Movement Hacks Configuration
    local MovementSettings = {
        FlyEnabled = false,
        FlySpeed = 300, -- Default fly speed
        WalkSpeed = 30,  -- Default walk speed
        JumpPower = 50,  -- Default jump power
        CrateESP = false,
        WallShoot = false,
        GlideWithG = false,
        ReplaceParachute = false,
        NoRagdoll = false,
        KeycardBypass = false,
        HoldEBypass = false,
        ForceDaytime = false,
        LockOnExit = false
    }
    
    -- Helper functions for fly
    local function GetVelocity(pos1, pos2, StudsPerSecond)
        local distance = (pos2 - pos1)
        local mag = distance.Magnitude
        return (distance/mag) * StudsPerSecond
    end
    
    local function keyDown(keycode)
        return UserInputService:IsKeyDown(keycode) and not UserInputService:GetFocusedTextBox()
    end
    
    local function getmodel()
        -- Check if player is in a vehicle
        local vehicle = nil
        
        -- Attempt to get player's vehicle
        if workspace.VehicleSpawns then
            for _, veh in pairs(workspace.VehicleSpawns:GetDescendants()) do
                if veh:IsA("Model") and veh:FindFirstChild("Seat") then
                    if veh.Seat.Occupant and veh.Seat.Occupant.Parent == LocalPlayer.Character then
                        vehicle = veh
                        break
                    end
                end
            end
        end
        
        -- Check Cars folder if exists
        if not vehicle and workspace:FindFirstChild("Cars") then
            for _, veh in pairs(workspace.Cars:GetChildren()) do
                if veh:IsA("Model") and veh:FindFirstChild("Seat") then
                    if veh.Seat.Occupant and veh.Seat.Occupant.Parent == LocalPlayer.Character then
                        vehicle = veh
                        break
                    end
                end
            end
        end
        
        return vehicle
    end
    
    local function isdriver()
        -- Check if player is the driver of a vehicle
        local vehicle = getmodel()
        if vehicle and vehicle:FindFirstChild("Seat") then
            if vehicle.Seat.Occupant and vehicle.Seat.Occupant.Parent == LocalPlayer.Character then
                return true
            end
        end
        return false
    end
    
    -- Robbery Notification Configuration
    local RobberySettings = {
        Notifications = true,
        RobberyStatus = {},
        RobberyNames = {
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
            ["HOME_VAULT"] = "Home Vault",
            ["TOMB"] = "Tomb",
            ["CROWN_JEWEL"] = "Crown Jewel",
            ["MANSION"] = "Mansion",
            ["OIL_RIG"] = "Oil Rig"
        },
        StatusEnum = {
            OPENED = 0,
            STARTED = 1,
            CLOSED = 2
        }
    }
    
    -- Fly Hack Variables
    local flying = false
    local pos = Vector3.new()
    local trainRob = true
    local bankTruck = true
    
    -- Wallhack variables
    local wallChildren = {}

    -- ESP Drawing Objects
    local ESPObjects = {}
    local CrateESPObjects = {}
    
    -- Function to get team of a player
    local function GetPlayerTeam(player)
        local team = player.Team
        if team then
            local teamName = team.Name
            if teamName == "Police" then
                return "Police"
            elseif teamName == "Prisoner" then
                return "Prisoner"
            elseif teamName == "Criminal" then
                return "Criminal"
            end
        end
        return "Unknown"
    end
    
    -- Function to create ESP objects for a player
    local function CreateESP(player)
        if player == LocalPlayer then return end
        
        local esp = {}
        
        -- Box
        esp.Box = Drawing.new("Square")
        esp.Box.Thickness = ESPSettings.BoxThickness
        esp.Box.Filled = false
        esp.Box.Transparency = 1
        
        -- Name
        esp.Name = Drawing.new("Text")
        esp.Name.Size = ESPSettings.TextSize
        esp.Name.Center = true
        esp.Name.Outline = true
        esp.Name.Transparency = 1
        
        -- Distance
        esp.Distance = Drawing.new("Text")
        esp.Distance.Size = ESPSettings.TextSize
        esp.Distance.Center = true
        esp.Distance.Outline = true
        esp.Distance.Transparency = 1
        
        -- Tracer
        esp.Tracer = Drawing.new("Line")
        esp.Tracer.Thickness = ESPSettings.TracerThickness
        esp.Tracer.Transparency = 1
        
        ESPObjects[player] = esp
    end
    
    -- Function to remove ESP objects for a player
    local function RemoveESP(player)
        if ESPObjects[player] then
            for _, object in pairs(ESPObjects[player]) do
                object:Remove()
            end
            ESPObjects[player] = nil
        end
    end
    
    -- Function to create ESP for crates
    local function SetupCrateESP()
        -- Clean up existing ESP objects
        for _, obj in pairs(CrateESPObjects) do
            for _, drawing in pairs(obj) do
                drawing:Remove()
            end
        end
        CrateESPObjects = {}
        
        -- Function to add ESP for a crate
        local function AddCrateESP(crate)
            if crate.Name == "Drop" then
                local rootPart = crate:WaitForChild("Root", 5)
                if rootPart then
                    local esp = {}
                    
                    -- Text for crate
                    esp.Text = Drawing.new("Text")
                    esp.Text.Size = 18
                    esp.Text.Center = true
                    esp.Text.Outline = true
                    esp.Text.Transparency = 1
                    esp.Text.Color = Color3.fromRGB(85, 170, 255)
                    
                    -- Tracer for crate
                    esp.Tracer = Drawing.new("Line")
                    esp.Tracer.Thickness = 1
                    esp.Tracer.Transparency = 1
                    esp.Tracer.Color = Color3.fromRGB(85, 170, 255)
                    
                    CrateESPObjects[crate] = esp
                    
                    -- Remove ESP when crate is removed
                    crate.AncestryChanged:Connect(function(_, parent)
                        if not parent then
                            if CrateESPObjects[crate] then
                                for _, obj in pairs(CrateESPObjects[crate]) do
                                    obj:Remove()
                                end
                                CrateESPObjects[crate] = nil
                            end
                        end
                    end)
                end
            end
        end
        
        -- Add ESP for existing crates
        for _, child in pairs(workspace:GetChildren()) do
            if child.Name == "Drop" then
                AddCrateESP(child)
            end
        end
        
        -- Add ESP for new crates
        workspace.ChildAdded:Connect(function(child)
            if child.Name == "Drop" then
                AddCrateESP(child)
            end
        end)
    end
    
    -- Function to update crate ESP
    local function UpdateCrateESP()
        if not MovementSettings.CrateESP then
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
                    
                    -- Update text
                    esp.Text.Visible = true
                    esp.Text.Position = Vector2.new(pos.X, pos.Y - 40)
                    esp.Text.Text = "Crate | Distance: " .. math.floor(distance)
                    
                    -- Update tracer
                    esp.Tracer.Visible = true
                    esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 50)
                    esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                else
                    esp.Text.Visible = false
                    esp.Tracer.Visible = false
                end
            else
                if esp then
                    esp.Text.Visible = false
                    esp.Tracer.Visible = false
                end
            end
        end
    end

    -- Function to activate No Tazer
    local function NoTazer()
        local function hasval(t, child)
            local success, prop = pcall(function()
                return t[child]
            end)
            return success and prop ~= nil
        end
        
        for i, v in pairs(getreg()) do
            if type(v) == "table" then
                if isreadonly and setreadonly and isreadonly(v) then
                    setreadonly(v, false)
                end
                if hasval(v, "ReloadTime") and hasval(v, "ReloadTimeHit") and type(v.ReloadTime) == "number" and type(v.ReloadTimeHit) == "number" then
                    v.ReloadTime = 0
                    v.ReloadTimeHit = 0
                end
            end
        end
    end
    
    -- Function to remove ragdoll effect
    local function RemoveRagdoll()
        if ReplicatedStorage.Module and ReplicatedStorage.Module:FindFirstChild("AlexRagdoll") then
            require(ReplicatedStorage.Module.AlexRagdoll).Ragdoll = nil
        end
        
        if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("Falling") then
            require(ReplicatedStorage.Game.Falling).StartRagdolling = nil
        end
        
        library:SendNotification("Removed ragdolling. (You may still take fall damage)", 6)
    end
    
    -- Function to bypass keycard requirement
    local function KeycardBypass()
        if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("PlayerUtils") then
            require(ReplicatedStorage.Game.PlayerUtils).hasKey = function()
                return true
            end
        end
        
        library:SendNotification("Keycard bypass enabled", 5)
    end
    
    -- Function to enable Hold E bypass
    local function EnableHoldEBypass()
        if ReplicatedStorage.Module and ReplicatedStorage.Module:FindFirstChild("UI") then
            local moduleUI = require(ReplicatedStorage.Module.UI)
            local namesToAvoid = {
                "grab documents",
                "grab computer",
                "grab briefcase",
                "grab phone",
                "grab spyglasses",
                "grab Cash",
                "rob",
                "open crate",
                "place tnt",
                "disable security"
            }
            
            RunService.Heartbeat:Connect(function()
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
            
            library:SendNotification("Hold E Bypass enabled. Some actions excluded.", 6)
        end
    end
    
    -- Function to force daytime
    local function ForceDaytime()
        game:GetService("Lighting").ClockTime = 12
        
        -- Keep forcing daytime
        local connection
        connection = game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
            if not MovementSettings.ForceDaytime then
                connection:Disconnect()
                return
            end
            game:GetService("Lighting").ClockTime = 12
        end)
        
        library:SendNotification("Forced daytime enabled", 4)
    end
    
    -- Function to set up wall shooting hack
    local function SetupWallShoot()
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
        
        -- Hook the gun shooting function if available
        if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("Item") and ReplicatedStorage.Game.Item:FindFirstChild("Gun") then
            local gunModule = require(ReplicatedStorage.Game.Item.Gun)
            local originalShoot = gunModule.Shoot
            
            gunModule.Shoot = function(...)
                local args = {...}
                local main = args[1]
                local equippedItem = getEquippedItem()
                
                -- Don't apply to plasma weapons (they don't work well with this hack)
                if MovementSettings.WallShoot and equippedItem and equippedItem ~= "PlasmaPistol" and equippedItem ~= "PlasmaShotgun" then
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
            
            library:SendNotification("Wall shooting hack enabled (toggle in the menu)", 5)
        end
    end
    
    -- Function to manage vehicle locking on exit
    local function SetupVehicleLockOnExit()
        -- Get necessary vehicle modules
        local vehicleModule
        if ReplicatedStorage.Vehicle and ReplicatedStorage.Vehicle:FindFirstChild("VehicleUtils") then
            vehicleModule = require(ReplicatedStorage.Vehicle.VehicleUtils)
            
            -- Store original exit function if available
            if vehicleModule.OnVehicleJumpExited and vehicleModule.OnVehicleJumpExited._handlerListHead then
                local originalExit = vehicleModule.OnVehicleJumpExited._handlerListHead._fn
                
                -- Replace with our version that locks the vehicle
                vehicleModule.OnVehicleJumpExited._handlerListHead._fn = function(...)
                    if MovementSettings.LockOnExit and isdriver() then
                        -- Check if car is unlocked
                        local locked
                        pcall(function()
                            local lockIcon = LocalPlayer.PlayerGui.AppUI.Speedometer.Top.Lock.Icon.Image
                            locked = lockIcon ~= "rbxassetid://5928936296"
                        end)
                        
                        if not locked then
                            vehicleModule.toggleLocalLocked()
                        end
                    end
                    
                    return originalExit(...)
                end
            end
        end
    end
    
    -- Function to set up parachute/glider replacement
    local function SetupParachuteGlider()
        -- Get the paraglide module
        local paraModule
        if ReplicatedStorage.Game and ReplicatedStorage.Game:FindFirstChild("Paraglide") then
            paraModule = require(ReplicatedStorage.Game.Paraglide)
            
            -- Store original parachute function
            local originalParachute = paraModule.Parachute
            
            -- Replace with our version that uses glider instead
            paraModule.Parachute = function(...)
                if MovementSettings.ReplaceParachute then
                    return paraModule.Glider(...)
                else
                    return originalParachute(...)
                end
            end
            
            -- Set up G key to activate glider
            UserInputService.InputBegan:Connect(function(input, processed)
                if not processed and input.KeyCode == Enum.KeyCode.G and MovementSettings.GlideWithG then
                    paraModule.Glider()
                end
            end)
        end
    end

    -- Robbery Notification System
    local function SetupRobberyNotifications()
        local RobberyStateFolder = ReplicatedStorage:FindFirstChild("RobberyState")
        if not RobberyStateFolder then
            warn("RobberyState folder not found in ReplicatedStorage")
            return
        end
        
        -- Initialize robbery status
        for _, robbery in pairs(RobberyStateFolder:GetChildren()) do
            if robbery:IsA("IntValue") then
                local robberyKey = robbery.Name
                RobberySettings.RobberyStatus[robberyKey] = robbery.Value
                
                -- Connect to value changed
                robbery.Changed:Connect(function(newValue)
                    local oldValue = RobberySettings.RobberyStatus[robberyKey]
                    RobberySettings.RobberyStatus[robberyKey] = newValue
                    
                    -- Only notify if robbery notifications are enabled
                    if RobberySettings.Notifications then
                        local robberyName = RobberySettings.RobberyNames[robberyKey] or robberyKey
                        
                        -- Check for status change from CLOSED to OPENED (ready to rob)
                        if oldValue == RobberySettings.StatusEnum.CLOSED and newValue == RobberySettings.StatusEnum.OPENED then
                            library:SendNotification("🚨 " .. robberyName .. " is now OPEN!", 10)
                        -- Check for status change from OPENED to STARTED (someone started robbing)
                        elseif oldValue == RobberySettings.StatusEnum.OPENED and newValue == RobberySettings.StatusEnum.STARTED then
                            library:SendNotification("🔴 " .. robberyName .. " robbery started!", 8)
                        -- Check for status change from STARTED to CLOSED (robbery ended)
                        elseif oldValue == RobberySettings.StatusEnum.STARTED and newValue == RobberySettings.StatusEnum.CLOSED then
                            library:SendNotification("❌ " .. robberyName .. " robbery completed!", 8)
                        end
                    end
                end)
            end
        end
        
        -- Set up world markers for robbery tracking
        local function SetupWorldMarkers()
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            local worldMarkersGui = playerGui:WaitForChild("WorldMarkersGui", 10)
            
            if not worldMarkersGui then return end
            
            local IconIds = {
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
            
            for _, marker in pairs(worldMarkersGui:GetChildren()) do
                for _, imageLabel in pairs(marker:GetChildren()) do
                    if imageLabel:FindFirstChild("ImageLabel") then
                        for name, id in pairs(IconIds) do
                            if imageLabel.ImageLabel.Image == "rbxassetid://" .. id then
                                imageLabel:GetPropertyChangedSignal("ImageColor3"):Connect(function()
                                    local color = imageLabel.ImageColor3
                                    if color == Color3.new(0, 1, 0) then
                                        if name == "bank truck" then
                                            if bankTruck then
                                                bankTruck = false
                                                library:SendNotification("The bank truck is open.", 8)
                                            end
                                        else
                                            library:SendNotification("The " .. name .. " is open for robbery.", 8)
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
            
            worldMarkersGui.ChildAdded:Connect(function(marker)
                task.wait(0.1) -- Wait for the marker to load
                if marker:FindFirstChild("ImageLabel") and marker.ImageLabel:FindFirstChild("ImageLabel") then
                    local img = marker.ImageLabel.ImageLabel.Image
                    for name, id in pairs(IconIds) do
                        if img == "rbxassetid://" .. id then
                            if name == "cargo train" or name == "passenger train" then
                                if trainRob then
                                    library:SendNotification("The " .. name .. " has entered the map.", 8)
                                    trainRob = false
                                    
                                    task.delay(4, function()
                                        trainRob = true
                                    end)
                                end
                            elseif name == "cargo ship" then
                                library:SendNotification("The cargo ship is coming!", 8)
                            elseif name == "cargo plane" then
                                library:SendNotification("The cargo plane is inbound!", 8)
                            else
                                if marker.ImageLabel.ImageColor3 == Color3.new(0, 1, 0) then
                                    if name == "bank truck" then
                                        if bankTruck then
                                            bankTruck = false
                                            library:SendNotification("The bank truck is open.", 8)
                                        end
                                    else
                                        library:SendNotification("The " .. name .. " is open for robbery.", 8)
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
        
        task.spawn(SetupWorldMarkers)
    end
    
    -- Function to get currently equipped item
    local equippeditems = {}
    local function getEquippedItem()
        for itemName, equipped in pairs(equippeditems) do
            if equipped then
                return itemName
            end
        end
        return nil
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
    
    -- Function to modify gun stats
    local function ModifyGuns()
        local itemConfig = ReplicatedStorage:FindFirstChild("Game"):FindFirstChild("ItemConfig")
        if not itemConfig then return end
        
        for _, module in pairs(itemConfig:GetChildren()) do
            pcall(function()
                local gun = require(module)
                
                -- For shotgun
                if module.Name == "Shotgun" then
                    gun.BulletSpread = 0.02
                end
                
                -- Common modifications
                gun.CamShakeMagnitude = 0
                gun.FireAuto = true
            end)
        end
        
        -- Adjust grenade
        pcall(function()
            local grenade = require(itemConfig.Grenade)
            grenade.ReloadTime = 0
            grenade.FuseTime = 0.8
        end)
        
        -- Allow equipping in any situation
        pcall(function()
            local inventorySystem = require(ReplicatedStorage.Inventory.InventoryItemSystem)
            for i, _ in pairs(inventorySystem._equipConditions) do
                inventorySystem._equipConditions[i] = function() return true end
            end
            for i, _ in pairs(inventorySystem._unequipConditions) do
                inventorySystem._unequipConditions[i] = function() return true end
            end
        end)
        
        library:SendNotification("Guns modded: No recoil, auto-fire, fast grenades", 6)
    end

    local Window = library.NewWindow({
        title = "Project KILLD | Jailbreak", -- Mainwindow Text
        size = UDim2.new(0, 510, 0.6, 6)
    })

    -- Create a fake script for anti-cheat bypass
    local script = Instance.new("LocalScript", gethui())
    
    -- Create Tabs
    local MainTab = Window:AddTab("Main")
    local ESPTab = Window:AddTab("ESP")
    local MovementTab = Window:AddTab("Movement")
    local ExploitsTab = Window:AddTab("Exploits")
    local SettingsTab = library:CreateSettingsTab(Window)
    
    -- ESP Section
    local ESPSection = ESPTab:AddSection("ESP Settings", 1)
    
    -- Enable/Disable ESP Toggle
    ESPSection:AddToggle({
        text = "ESP Enabled",
        state = false,
        flag = "ESP_Enabled",
        callback = function(value)
            ESPSettings.Enabled = value
        end
    })
    
    -- Team ESP Settings
    ESPSection:AddToggle({
        text = "Police ESP",
        state = true,
        flag = "Police_ESP",
        callback = function(value)
            ESPSettings.PoliceESP = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Prisoner ESP",
        state = true,
        flag = "Prisoner_ESP",
        callback = function(value)
            ESPSettings.PrisonerESP = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Criminal ESP",
        state = true,
        flag = "Criminal_ESP",
        callback = function(value)
            ESPSettings.CriminalESP = value
        end
    })
    
    ESPSection:AddSeparator({
        enabled = true,
        text = "ESP Features"
    })
    
    -- ESP Features
    ESPSection:AddToggle({
        text = "Box ESP",
        state = true,
        flag = "Box_ESP",
        callback = function(value)
            ESPSettings.BoxEnabled = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Name ESP",
        state = true,
        flag = "Name_ESP",
        callback = function(value)
            ESPSettings.NameEnabled = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Distance ESP",
        state = true,
        flag = "Distance_ESP",
        callback = function(value)
            ESPSettings.DistanceEnabled = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Tracers",
        state = true,
        flag = "Tracers_ESP",
        callback = function(value)
            ESPSettings.TracersEnabled = value
        end
    })
    
    ESPSection:AddToggle({
        text = "Team Colors",
        state = true,
        flag = "Team_Colors",
        callback = function(value)
            ESPSettings.TeamColorESP = value
        end
    })
    
    -- ESP Distance Slider
    ESPSection:AddSlider({
        text = "ESP Distance",
        flag = "ESP_Distance",
        min = 100,
        max = 5000,
        increment = 100,
        callback = function(value)
            ESPSettings.MaxDistance = value
        end
    })
    
    -- Crate ESP Toggle
    ESPSection:AddToggle({
        text = "Crate ESP",
        state = false,
        flag = "Crate_ESP",
        callback = function(value)
            MovementSettings.CrateESP = value
            if value and #CrateESPObjects == 0 then
                SetupCrateESP()
            end
        end
    })
    
    -- Movement Section
    local MovementSection = MovementTab:AddSection("Movement Hacks", 1)
    
    -- Fly Hack
    MovementSection:AddToggle({
        text = "Fly",
        state = false,
        flag = "Fly_Enabled",
        callback = function(value)
            MovementSettings.FlyEnabled = value
            flying = value
            
            if value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(2, 0, 0)
            else
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end
    }):AddBind({
        text = "Fly Keybind",
        bind = "F",
        flag = "Fly_Keybind",
        mode = "toggle",
        callback = function(value)
            MovementSettings.FlyEnabled = value
            flying = value
            
            if value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(2, 0, 0)
            else
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                    LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
                end
            end
        end
    })
    
    -- Fly Speed
    MovementSection:AddSlider({
        text = "Fly Speed",
        flag = "Fly_Speed",
        min = 20,
        max = 600,
        increment = 20,
        callback = function(value)
            MovementSettings.FlySpeed = value
        end
    })
    
    -- Walk Speed
    MovementSection:AddToggle({
        text = "Walk Speed",
        state = false,
        flag = "WalkSpeed_Enabled",
        callback = function(value)
            if value then
                -- Create loop to ensure speed is always applied
                RunService.RenderStepped:Connect(function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.WalkSpeed = MovementSettings.WalkSpeed
                    end
                end)
            end
        end
    })
    
    MovementSection:AddSlider({
        text = "Walk Speed Value",
        flag = "WalkSpeed_Value",
        min = 16,
        max = 150,
        increment = 2,
        callback = function(value)
            MovementSettings.WalkSpeed = value
        end
    })
    
    -- Gravity Toggle
    MovementSection:AddToggle({
        text = "Toggle Gravity (0/196)",
        state = false,
        flag = "Gravity_Toggle",
        callback = function(value)
            if value then
                workspace.Gravity = 0
            else
                workspace.Gravity = 196
            end
        end
    })
    
    -- Glide Options
    MovementSection:AddToggle({
        text = "G Key to Glide",
        state = false,
        flag = "G_Glide",
        callback = function(value)
            MovementSettings.GlideWithG = value
        end
    })
    
    MovementSection:AddToggle({
        text = "Replace Parachute with Glider",
        state = false,
        flag = "Replace_Parachute",
        callback = function(value)
            MovementSettings.ReplaceParachute = value
        end
    })
    
    -- Exploits section for Jailbreak specific features
    local ExploitSection = ExploitsTab:AddSection("Game Exploits", 1)
    
    -- No Ragdoll
    ExploitSection:AddToggle({
        text = "Remove Ragdoll",
        state = false,
        flag = "No_Ragdoll",
        callback = function(value)
            MovementSettings.NoRagdoll = value
            if value then
                RemoveRagdoll()
            end
        end
    })
    
    -- Keycard Bypass
    ExploitSection:AddToggle({
        text = "Keycard Bypass",
        state = false,
        flag = "Keycard_Bypass",
        callback = function(value)
            MovementSettings.KeycardBypass = value
            if value then
                KeycardBypass()
            end
        end
    })
    
    -- Hold E Bypass
    ExploitSection:AddToggle({
        text = "Hold E Bypass",
        state = false,
        flag = "HoldE_Bypass",
        callback = function(value)
            MovementSettings.HoldEBypass = value
            if value then
                EnableHoldEBypass()
            end
        end
    })
    
    -- Force Daytime
    ExploitSection:AddToggle({
        text = "Force Daytime",
        state = false,
        flag = "Force_Daytime",
        callback = function(value)
            MovementSettings.ForceDaytime = value
            if value then
                ForceDaytime()
            end
        end
    })
    
    -- Wall Shooting
    ExploitSection:AddToggle({
        text = "Shoot Through Walls",
        state = false,
        flag = "Wall_Shoot",
        callback = function(value)
            MovementSettings.WallShoot = value
            
            if value and #wallChildren == 0 then
                SetupWallShoot()
            end
        end
    })
    
    -- Auto Lock Vehicle
    ExploitSection:AddToggle({
        text = "Auto-Lock Vehicle on Exit",
        state = false,
        flag = "Lock_On_Exit",
        callback = function(value)
            MovementSettings.LockOnExit = value
            
            if value then
                SetupVehicleLockOnExit()
            end
        end
    })
    
    -- Mod Guns
    ExploitSection:AddButton({
        text = "Mod Guns",
        callback = function()
            ModifyGuns()
        end
    })
    
    -- No Tazer
    ExploitSection:AddButton({
        text = "No Tazer Cooldown",
        callback = function()
            NoTazer()
        end
    })
    
    -- Main Tab
    local MainSection = MainTab:AddSection("Jailbreak Features", 1)
    
    -- Robbery Notifications
    MainSection:AddToggle({
        text = "Robbery Notifications",
        state = true,
        flag = "Robbery_Notifications",
        callback = function(value)
            RobberySettings.Notifications = value
        end
    })
    
    -- Delete Radio GUI
    MainSection:AddButton({
        text = "Delete Radio GUI",
        callback = function()
            RunService.RenderStepped:Connect(function()
                if LocalPlayer.PlayerGui:FindFirstChild("RadioGui") then
                    LocalPlayer.PlayerGui.RadioGui:Destroy()
                end
            end)
            library:SendNotification("Radio GUI will be auto-deleted", 4)
        end
    })
    
    -- Respawn Button
    MainSection:AddButton({
        text = "Respawn",
        callback = function()
            library:SendNotification("Click again to confirm respawn", 3)
            task.wait(0.5)
            
            -- Create temporary confirmation button
            local confirmed = false
            local confirmButton = MainSection:AddButton({
                text = "CONFIRM RESPAWN",
                callback = function()
                    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                        LocalPlayer.Character.Humanoid.Health = 0
                    end
                    confirmed = true
                end
            })
            
            -- Remove confirmation button after 3 seconds
            task.delay(3, function()
                if not confirmed then
                    -- Code to remove the button would go here if possible
                    -- If the UI library doesn't support removing buttons, this won't work
                end
            end)
        end
    })
    
    -- Infinite Yield
    MainSection:AddButton({
        text = "Infinite Yield",
        callback = function()
            loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        end
    })
    
    -- Create ESP for all existing players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESP(player)
        end
    end
    
    -- Handle player joining
    Players.PlayerAdded:Connect(function(player)
        CreateESP(player)
    end)
    
    -- Handle player leaving
    Players.PlayerRemoving:Connect(function(player)
        RemoveESP(player)
    end)
    
    -- Fly implementation with RunService
    RunService.Heartbeat:Connect(function()
        local hrp
        local flyspeed = MovementSettings.FlySpeed
        local maxdistance = flyspeed * 2
        local invehicle = getmodel()
        
        if invehicle and isdriver() then
            hrp = invehicle.PrimaryPart
        else
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.RootPart then
                hrp = LocalPlayer.Character.Humanoid.RootPart
            end
            if flyspeed > 150 then
                flyspeed = 150
            end
        end
        
        if hrp then
            local frontoffset = CFrame.new() + Vector3.new(0, 0, -maxdistance)
            local backoffset = CFrame.new() + Vector3.new(0, 0, maxdistance)
            local leftoffset = CFrame.new() + Vector3.new(-maxdistance, 0, 0)
            local rightoffset = CFrame.new() + Vector3.new(maxdistance, 0, 0)
            local upoffset = CFrame.new() + Vector3.new(0, maxdistance, 0)
            local downoffset = CFrame.new() + Vector3.new(0, -maxdistance, 0)
            local velocity = Vector3.new()
            
            if flying then
                hrp.RotVelocity = Vector3.new()
                
                if keyDown(Enum.KeyCode.W) then
                    velocity = velocity + GetVelocity(hrp.Position, (hrp.CFrame*frontoffset).Position, flyspeed)
                end
                
                if keyDown(Enum.KeyCode.S) then
                    velocity = velocity + GetVelocity(hrp.Position, (hrp.CFrame*backoffset).Position, flyspeed)
                end
                
                if keyDown(Enum.KeyCode.A) then
                    velocity = velocity + GetVelocity(hrp.Position, (hrp.CFrame*leftoffset).Position, flyspeed)
                end
                
                if keyDown(Enum.KeyCode.D) then
                    velocity = velocity + GetVelocity(hrp.Position, (hrp.CFrame*rightoffset).Position, flyspeed)
                end
                
                if keyDown(Enum.KeyCode.E) then
                    velocity = velocity + GetVelocity(hrp.Position, (CFrame.new(hrp.Position)*upoffset).Position, flyspeed)
                end
                
                if keyDown(Enum.KeyCode.Q) then
                    velocity = velocity + GetVelocity(hrp.Position, (CFrame.new(hrp.Position)*downoffset).Position, flyspeed)
                end
                
                hrp.Velocity = velocity
                hrp.CFrame = CFrame.new(hrp.Position, (workspace.CurrentCamera.CFrame*frontoffset).Position)
            end
            
            if flying and not keyDown(Enum.KeyCode.W) and not keyDown(Enum.KeyCode.A) and not keyDown(Enum.KeyCode.S) and not keyDown(Enum.KeyCode.D) and not keyDown(Enum.KeyCode.Q) and not keyDown(Enum.KeyCode.E) then
                hrp.CFrame = CFrame.new(pos, (workspace.CurrentCamera.CFrame*frontoffset).Position)
                hrp.Velocity = Vector3.new()
            else
                pos = hrp.Position
            end
        end
    end)
    
    -- Keybind for fly
    UserInputService.InputBegan:Connect(function(key, processed)
        if processed then return end
        if key.KeyCode == Enum.KeyCode.F and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            flying = not flying
            MovementSettings.FlyEnabled = flying
            
            if flying then
                LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(2, 0, 0)
            else
                LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
        end
    end)
    
    -- Update ESP
    RunService.RenderStepped:Connect(function()
        -- Update player ESP
        if not ESPSettings.Enabled then
            -- Hide all ESP objects if disabled
            for _, esp in pairs(ESPObjects) do
                for _, object in pairs(esp) do
                    object.Visible = false
                end
            end
        else
            -- Update tracer origin if viewport size changes
            if Camera.ViewportSize ~= ESPSettings.TracerOrigin then
                ESPSettings.TracerOrigin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 50)
            end
            
            for player, esp in pairs(ESPObjects) do
                if player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
                    local team = GetPlayerTeam(player)
                    
                    -- Check if we should show ESP for this team
                    local showESP = false
                    if team == "Police" and ESPSettings.PoliceESP then
                        showESP = true
                    elseif team == "Prisoner" and ESPSettings.PrisonerESP then
                        showESP = true
                    elseif team == "Criminal" and ESPSettings.CriminalESP then
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
                    if onScreen and distance <= ESPSettings.MaxDistance then
                        -- Calculate box size based on distance
                        local size = 2000 / distance
                        local boxSize = Vector2.new(size, size * 1.5)
                        
                        -- Update box
                        esp.Box.Visible = ESPSettings.BoxEnabled
                        esp.Box.Size = boxSize
                        esp.Box.Position = Vector2.new(pos.X - boxSize.X / 2, pos.Y - boxSize.Y / 2)
                        esp.Box.Color = ESPSettings.BoxColor[team] or Color3.fromRGB(255, 255, 255)
                        
                        -- Update name
                        esp.Name.Visible = ESPSettings.NameEnabled
                        esp.Name.Text = player.Name
                        esp.Name.Position = Vector2.new(pos.X, pos.Y - boxSize.Y / 2 - 15)
                        esp.Name.Color = ESPSettings.TeamColorESP and ESPSettings.BoxColor[team] or ESPSettings.TextColor
                        
                        -- Update distance
                        esp.Distance.Visible = ESPSettings.DistanceEnabled
                        esp.Distance.Text = math.floor(distance) .. "m"
                        esp.Distance.Position = Vector2.new(pos.X, pos.Y + boxSize.Y / 2 + 5)
                        esp.Distance.Color = ESPSettings.TeamColorESP and ESPSettings.BoxColor[team] or ESPSettings.TextColor
                        
                        -- Update tracer
                        esp.Tracer.Visible = ESPSettings.TracersEnabled
                        esp.Tracer.From = ESPSettings.TracerOrigin
                        esp.Tracer.To = Vector2.new(pos.X, pos.Y)
                        esp.Tracer.Color = ESPSettings.TeamColorESP and ESPSettings.BoxColor[team] or ESPSettings.TextColor
                    else
                        -- Hide if off screen or too far
                        for _, object in pairs(esp) do
                            object.Visible = false
                        end
                    end
                else
                    -- Hide if player is not valid
                    for _, object in pairs(esp) do
                        object.Visible = false
                    end
                end
            end
        end
        
        -- Update crate ESP if enabled
        if MovementSettings.CrateESP then
            UpdateCrateESP()
        end
    end)
    
    -- Set up all required features
    task.spawn(function()
        SetupRobberyNotifications()
        SetupParachuteGlider()
        SetupWallShoot() -- Set up but don't enable until toggled
        SetupVehicleLockOnExit()
        SetupCrateESP()
    end)
    
    -- Clean up on script stop
    local OnScriptEnd = Instance.new("BindableEvent")
    OnScriptEnd.Event:Connect(function()
        -- Clean up ESP
        for player, esp in pairs(ESPObjects) do
            RemoveESP(player)
        end
        
        -- Clean up crate ESP
        for _, esp in pairs(CrateESPObjects) do
            for _, object in pairs(esp) do
                object:Remove()
            end
        end
        
        -- Reset CameraOffset if fly was enabled
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.CameraOffset = Vector3.new(0, 0, 0)
        end
    end)
    
    -- Send load notification
    local Time = (string.format("%."..tostring(Decimals).."f", os.clock() - Clock))
    library:SendNotification(("Project KILLD loaded in "..tostring(Time).."s"), 6)
    library:SendNotification("Press F to toggle Fly (or Ctrl+F)", 5)
    
    -- Make an initial check of currently open robberies
    task.spawn(function()
        task.wait(3) -- Wait a bit for everything to initialize
        
        local RobberyStateFolder = ReplicatedStorage:FindFirstChild("RobberyState")
        if RobberyStateFolder then
            for _, robbery in pairs(RobberyStateFolder:GetChildren()) do
                if robbery:IsA("IntValue") and robbery.Value == RobberySettings.StatusEnum.OPENED then
                    local robberyName = RobberySettings.RobberyNames[robbery.Name] or robbery.Name
                    library:SendNotification("🚨 " .. robberyName .. " is currently OPEN!", 10)
                end
            end
        end
    end)
end

coroutine.wrap(BZWQK_fake_script)()

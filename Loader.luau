-- Project KILLD Loader
-- Automatically detects the game and loads the appropriate script

local function notifyUser(message, duration)
    -- Create a simple notification if GUI is not loaded
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ProjectKILLDNotification"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.85, -30)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.2
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, 0)
    textLabel.Position = UDim2.new(0, 10, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 16
    textLabel.Font = Enum.Font.GothamMedium
    textLabel.Text = message
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = frame
    
    frame.Parent = screenGui
    screenGui.Parent = game:GetService("CoreGui")
    
    -- Fade-in animation
    frame.BackgroundTransparency = 1
    textLabel.TextTransparency = 1
    
    game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
    game:GetService("TweenService"):Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
    
    -- Remove after specified duration
    spawn(function()
        wait(duration)
        game:GetService("TweenService"):Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        game:GetService("TweenService"):Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
        wait(0.5)
        screenGui:Destroy()
    end)
end

-- Error tracking
local success, errorMsg = pcall(function()
    -- Get current PlaceId
    local currentPlaceId = game.PlaceId
    
    -- Map of PlaceIds to script URLs
    local scriptsMap = {
        [606849621] = "https://raw.githubusercontent.com/Coneriys/ProjectKILLD/refs/heads/main/Jailbreak.luau", -- Jailbreak
        [9872472334] = "https://raw.githubusercontent.com/Coneriys/ProjectKILLD/refs/heads/main/Evade.luau", -- Evade
    }
    
    -- Game names for notifications
    local gameNames = {
        [606849621] = "Jailbreak",
        [9872472334] = "Evade",
    }
    
    local scriptUrl = scriptsMap[currentPlaceId]
    local gameName = gameNames[currentPlaceId] or "Unknown Game"
    
    if scriptUrl then
        -- Show loading notification
        notifyUser("Project KILLD: Loading script for " .. gameName .. "...", 3)
        
        -- Fetch script content for current game
        local scriptContent = game:HttpGet(scriptUrl)
        
        -- Execute the script
        notifyUser("Project KILLD: Executing script for " .. gameName, 3)
        loadstring(scriptContent)()
    else
        -- If script for current game not found
        local supportedGames = ""
        for id, name in pairs(gameNames) do
            supportedGames = supportedGames .. "\n• " .. name
        end
        
        notifyUser("Project KILLD: This game is not supported (PlaceId: " .. currentPlaceId .. ").\n\nSupported games:" .. supportedGames, 7)
    end
end)

-- Error handling
if not success then
    notifyUser("Project KILLD: Error while loading:\n" .. tostring(errorMsg), 10)
end

local Library = {
    Flags = {},
    Objects = {},
    Drawings = {},
    Config = {
        MainColor = Color3.fromRGB(25, 25, 25),
        AccentColor = Color3.fromRGB(0, 170, 255),
        TextColor = Color3.fromRGB(255, 255, 255),
        Font = Drawing.Fonts.Plex,
        FontSize = 13
    }
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

function Library:Create(type, properties)
    local object = Drawing.new(type)
    for property, value in pairs(properties) do
        object[property] = value
    end
    table.insert(self.Drawings, object)
    return object
end

function Library:CreateWindow(title, position)
    local window = {
        Title = title,
        Position = position or Vector2.new(100, 100),
        Size = Vector2.new(500, 350),
        Dragging = false,
        DragStart = Vector2.new(),
        Elements = {},
        ElementYOffset = 40 -- Начальное смещение для элементов
    }

    -- Background
    window.Background = self:Create("Square", {
        Size = window.Size,
        Position = window.Position,
        Color = self.Config.MainColor,
        Filled = true,
        Visible = true,
        Transparency = 1
    })

    -- Title bar
    window.TitleBar = self:Create("Square", {
        Size = Vector2.new(window.Size.X, 30),
        Position = window.Position,
        Color = Color3.fromRGB(30, 30, 30),
        Filled = true,
        Visible = true,
        Transparency = 1
    })

    -- Title
    window.TitleText = self:Create("Text", {
        Text = title,
        Position = window.Position + Vector2.new(10, 5),
        Color = self.Config.TextColor,
        Font = self.Config.Font,
        Size = self.Config.FontSize,
        Visible = true,
        Transparency = 1
    })

    -- Dragging functionality
    UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = UserInputService:GetMouseLocation()
            if mousePos.X >= window.Position.X and 
               mousePos.X <= window.Position.X + window.Size.X and
               mousePos.Y >= window.Position.Y and
               mousePos.Y <= window.Position.Y + 30 then
                window.Dragging = true
                window.DragStart = mousePos - window.Position
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            window.Dragging = false
        end
    end)

    RunService.RenderStepped:Connect(function()
        if window.Dragging then
            local mousePos = UserInputService:GetMouseLocation()
            local newPosition = mousePos - window.DragStart
            
            window.Position = newPosition
            window.Background.Position = newPosition
            window.TitleBar.Position = newPosition
            window.TitleText.Position = newPosition + Vector2.new(10, 5)

            -- Update all elements
            for _, element in pairs(window.Elements) do
                if element.UpdatePosition then
                    element:UpdatePosition()
                end
            end
        end
    end)

    function window:AddButton(text, callback)
        local button = {
            Text = text,
            Callback = callback,
            Position = self.Position + Vector2.new(10, self.ElementYOffset)
        }

        button.Background = Library:Create("Square", {
            Size = Vector2.new(480, 25),
            Position = button.Position,
            Color = Library.Config.AccentColor,
            Filled = true,
            Visible = true,
            Transparency = 1
        })

        button.Label = Library:Create("Text", {
            Text = text,
            Position = button.Position + Vector2.new(5, 5),
            Color = Library.Config.TextColor,
            Font = Library.Config.Font,
            Size = Library.Config.FontSize,
            Visible = true,
            Transparency = 1
        })

        function button:UpdatePosition()
            local newPos = window.Position + Vector2.new(10, window.ElementYOffset)
            self.Position = newPos
            self.Background.Position = newPos
            self.Label.Position = newPos + Vector2.new(5, 5)
        end

        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                if mousePos.X >= button.Position.X and
                   mousePos.X <= button.Position.X + 480 and
                   mousePos.Y >= button.Position.Y and
                   mousePos.Y <= button.Position.Y + 25 then
                    button.Callback()
                end
            end
        end)

        table.insert(self.Elements, button)
        self.ElementYOffset = self.ElementYOffset + 35
        return button
    end

    function window:AddToggle(text, default, callback)
        local toggle = {
            Text = text,
            State = default or false,
            Callback = callback,
            Position = self.Position + Vector2.new(10, self.ElementYOffset)
        }

        toggle.Background = Library:Create("Square", {
            Size = Vector2.new(20, 20),
            Position = toggle.Position,
            Color = toggle.State and Library.Config.AccentColor or Library.Config.MainColor,
            Filled = true,
            Visible = true,
            Transparency = 1
        })

        toggle.Border = Library:Create("Square", {
            Size = Vector2.new(20, 20),
            Position = toggle.Position,
            Color = Library.Config.AccentColor,
            Filled = false,
            Visible = true,
            Transparency = 1
        })

        toggle.Label = Library:Create("Text", {
            Text = text,
            Position = toggle.Position + Vector2.new(30, 2),
            Color = Library.Config.TextColor,
            Font = Library.Config.Font,
            Size = Library.Config.FontSize,
            Visible = true,
            Transparency = 1
        })

        function toggle:UpdatePosition()
            local newPos = window.Position + Vector2.new(10, window.ElementYOffset)
            self.Position = newPos
            self.Background.Position = newPos
            self.Border.Position = newPos
            self.Label.Position = newPos + Vector2.new(30, 2)
        end

        function toggle:Set(state)
            self.State = state
            self.Background.Color = state and Library.Config.AccentColor or Library.Config.MainColor
            self.Callback(state)
        end

        UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                local mousePos = UserInputService:GetMouseLocation()
                if mousePos.X >= toggle.Position.X and
                   mousePos.X <= toggle.Position.X + 20 and
                   mousePos.Y >= toggle.Position.Y and
                   mousePos.Y <= toggle.Position.Y + 20 then
                    toggle:Set(not toggle.State)
                end
            end
        end)

        table.insert(self.Elements, toggle)
        self.ElementYOffset = self.ElementYOffset + 35
        return toggle
    end

    -- ESP функционал остается тем же
    function window:CreateESP(part)
        local esp = {
            Part = part,
            Enabled = true
        }

        esp.Box = Library:Create("Square", {
            Thickness = 1,
            Color = Library.Config.AccentColor,
            Filled = false,
            Visible = true,
            Transparency = 1
        })

        esp.Name = Library:Create("Text", {
            Text = part.Name,
            Color = Library.Config.TextColor,
            Font = Library.Config.Font,
            Size = Library.Config.FontSize,
            Visible = true,
            Transparency = 1
        })

        RunService.RenderStepped:Connect(function()
            if esp.Enabled and part and part:IsA("BasePart") then
                local vector, onScreen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
                
                if onScreen then
                    local size = part.Size * Vector3.new(1, 1.5, 1)
                    local corners = {
                        workspace.CurrentCamera:WorldToViewportPoint(part.CFrame * CFrame.new(-size.X/2, -size.Y/2, -size.Z/2).Position),
                        workspace.CurrentCamera:WorldToViewportPoint(part.CFrame * CFrame.new(size.X/2, -size.Y/2, -size.Z/2).Position),
                        workspace.CurrentCamera:WorldToViewportPoint(part.CFrame * CFrame.new(-size.X/2, size.Y/2, -size.Z/2).Position),
                        workspace.CurrentCamera:WorldToViewportPoint(part.CFrame * CFrame.new(size.X/2, size.Y/2, -size.Z/2).Position)
                    }

                    local minX, minY = math.huge, math.huge
                    local maxX, maxY = -math.huge, -math.huge

                    for _, corner in pairs(corners) do
                        minX = math.min(minX, corner.X)
                        minY = math.min(minY, corner.Y)
                        maxX = math.max(maxX, corner.X)
                        maxY = math.max(maxY, corner.Y)
                    end

                    esp.Box.Visible = true
                    esp.Box.Position = Vector2.new(minX, minY)
                    esp.Box.Size = Vector2.new(maxX - minX, maxY - minY)

                    esp.Name.Visible = true
                    esp.Name.Position = Vector2.new(minX, minY - 20)
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
            end
        end)

        return esp
    end

    return window
end

return Library

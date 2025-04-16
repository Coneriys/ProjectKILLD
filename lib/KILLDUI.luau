--[[
    KILLDUI v1.0
    
    Современная UI библиотека для создания красивых интерфейсов в Roblox
    Поддерживает стеклянный (glassmorphism) дизайн с размытием и тенями
    
    Автор: KILLD
]]

local KILLDUI = {}
KILLDUI.__index = KILLDUI

-- Настройки по умолчанию
KILLDUI.Config = {
    -- Цветовая схема
    Colors = {
        Background = Color3.fromRGB(25, 25, 30),
        Primary = Color3.fromRGB(60, 100, 200),
        Secondary = Color3.fromRGB(80, 80, 120),
        Text = Color3.fromRGB(230, 230, 255),
        TextDim = Color3.fromRGB(180, 180, 200),
        Success = Color3.fromRGB(100, 230, 100),
        Warning = Color3.fromRGB(255, 200, 80),
        Error = Color3.fromRGB(255, 100, 100),
        Panel = Color3.fromRGB(35, 35, 45),
        Shadow = Color3.fromRGB(0, 0, 0)
    },
    
    -- Эффекты
    Effects = {
        BlurSize = 20,
        GlassTransparency = 0.3,
        ShadowTransparency = 0.5,
        CornerRadius = 8,
        StrokeThickness = 1.5,
        AnimationSpeed = 0.2
    },
    
    -- Шрифты
    Fonts = {
        Header = Enum.Font.GothamBold,
        Text = Enum.Font.Gotham,
        Button = Enum.Font.GothamSemibold
    },
    
    -- Размеры шрифтов
    FontSizes = {
        Title = 18,
        Header = 16,
        Text = 14,
        Small = 12
    }
}

-- Приватные переменные
local blurEffects = {}
local activeUIs = {}

-- Утилиты
local function deepCopy(original)
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            copy[k] = deepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

local function createBlurEffect()
    local blur = Instance.new("BlurEffect")
    blur.Size = KILLDUI.Config.Effects.BlurSize
    blur.Parent = game:GetService("Lighting")
    table.insert(blurEffects, blur)
    return blur
end

local function removeBlurEffect(blur)
    for i, effect in ipairs(blurEffects) do
        if effect == blur then
            effect:Destroy()
            table.remove(blurEffects, i)
            break
        end
    end
end

local function cleanupAllBlurs()
    for _, blur in ipairs(blurEffects) do
        blur:Destroy()
    end
    blurEffects = {}
end

-- Создание элементов интерфейса
local function createRoundedFrame(name, size, position, bgColor, parent, cornerRadius)
    local frame = Instance.new("Frame")
    frame.Name = name
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = bgColor
    frame.BorderSizePixel = 0
    frame.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, cornerRadius or KILLDUI.Config.Effects.CornerRadius)
    corner.Parent = frame
    
    return frame
end

local function createStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness or KILLDUI.Config.Effects.StrokeThickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function createShadow(parent, size, transparency)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://6014261993"
    shadow.ImageColor3 = KILLDUI.Config.Colors.Shadow
    shadow.ImageTransparency = transparency or KILLDUI.Config.Effects.ShadowTransparency
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(49, 49, 450, 450)
    shadow.Size = UDim2.new(1, size or 30, 1, size or 30)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.ZIndex = -1
    shadow.Parent = parent
end

local function createGradient(parent, colorSeq, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colorSeq
    gradient.Rotation = rotation or 45
    gradient.Parent = parent
    return gradient
end

local function createGlossEffect(parent, transparency)
    local glossEffect = Instance.new("Frame")
    glossEffect.Name = "GlossEffect"
    glossEffect.Size = UDim2.new(1, 0, 0.5, 0)
    glossEffect.Position = UDim2.new(0, 0, 0, 0)
    glossEffect.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    glossEffect.BackgroundTransparency = transparency or 0.85
    glossEffect.BorderSizePixel = 0
    glossEffect.Parent = parent
    
    local glossCorner = Instance.new("UICorner")
    glossCorner.CornerRadius = UDim.new(0, KILLDUI.Config.Effects.CornerRadius)
    glossCorner.Parent = glossEffect
    
    return glossEffect
end

-- Конструктор основного класса
function KILLDUI.new(config)
    local self = setmetatable({}, KILLDUI)
    
    -- Применить пользовательские настройки
    if config then
        for key, value in pairs(config) do
            if type(value) == "table" and type(KILLDUI.Config[key]) == "table" then
                for subKey, subValue in pairs(value) do
                    KILLDUI.Config[key][subKey] = subValue
                end
            else
                KILLDUI.Config[key] = value
            end
        end
    end
    
    -- Инициализация основных компонентов
    self.ScreenGui = Instance.new("ScreenGui")
    self.ScreenGui.Name = "KILLDUI_" .. tostring(math.random(1000, 9999))
    self.ScreenGui.ResetOnSpawn = false
    self.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    self.ScreenGui.IgnoreGuiInset = true
    
    -- Разместить UI в правильном месте
    if syn and syn.protect_gui then
        syn.protect_gui(self.ScreenGui)
        self.ScreenGui.Parent = game:GetService("CoreGui")
    elseif gethui then
        self.ScreenGui.Parent = gethui()
    else
        self.ScreenGui.Parent = game:GetService("CoreGui")
    end
    
    -- Добавить эффект размытия
    self.BlurEffect = createBlurEffect()
    
    -- Фон для затемнения
    self.DimBackground = Instance.new("Frame")
    self.DimBackground.Name = "DimBackground"
    self.DimBackground.Size = UDim2.new(1, 0, 1, 0)
    self.DimBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    self.DimBackground.BackgroundTransparency = 0.5
    self.DimBackground.BorderSizePixel = 0
    self.DimBackground.Parent = self.ScreenGui
    
    -- Сохранить в список активных UI
    table.insert(activeUIs, self)
    
    return self
end

-- Создание окна
function KILLDUI:CreateWindow(title, size)
    local windowSize = size or UDim2.new(0, 500, 0, 350)
    
    -- Создаем основной фрейм окна
    local window = createRoundedFrame(
        title or "Window",
        windowSize,
        UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
        KILLDUI.Config.Colors.Background,
        self.ScreenGui,
        12
    )
    
    -- Добавляем тень
    createShadow(window, 40)
    
    -- Добавляем градиент
    createGradient(window, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 40, 60)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 30, 45))
    }))
    
    -- Добавляем стеклянный эффект обводки
    local stroke = createStroke(window, Color3.fromRGB(255, 255, 255), 1)
    stroke.Transparency = 0.7
    
    -- Создаем шапку окна
    local header = createRoundedFrame(
        "Header",
        UDim2.new(1, -20, 0, 40),
        UDim2.new(0, 10, 0, 10),
        KILLDUI.Config.Colors.Panel,
        window,
        8
    )
    
    -- Градиент для шапки
    createGradient(header, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 100)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 80))
    }), 90)
    
    -- Глянцевый эффект
    createGlossEffect(header)
    
    -- Иконка
    local logoContainer = Instance.new("Frame")
    logoContainer.Name = "LogoContainer"
    logoContainer.Size = UDim2.new(0, 24, 0, 24)
    logoContainer.Position = UDim2.new(0, 12, 0.5, -12)
    logoContainer.BackgroundTransparency = 1
    logoContainer.Parent = header
    
    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://10723415903"  -- Иконка галочки
    logo.ImageColor3 = Color3.fromRGB(200, 220, 255)
    logo.Parent = logoContainer
    
    -- Заголовок с тенью
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -100, 1, 0)
    titleLabel.Position = UDim2.new(0, 44, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = KILLDUI.Config.Colors.Text
    titleLabel.Font = KILLDUI.Config.Fonts.Header
    titleLabel.TextSize = KILLDUI.Config.FontSizes.Title
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title or "KILLDUI Window"
    titleLabel.Parent = header
    
    -- Тень для текста
    local titleShadow = Instance.new("TextLabel")
    titleShadow.Name = "TitleShadow"
    titleShadow.Size = UDim2.new(1, 0, 1, 0)
    titleShadow.Position = UDim2.new(0, 1, 0, 1)
    titleShadow.BackgroundTransparency = 1
    titleShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleShadow.TextTransparency = 0.7
    titleShadow.Font = KILLDUI.Config.Fonts.Header
    titleShadow.TextSize = KILLDUI.Config.FontSizes.Title
    titleShadow.TextXAlignment = Enum.TextXAlignment.Left
    titleShadow.Text = titleLabel.Text
    titleShadow.ZIndex = -1
    titleShadow.Parent = titleLabel
    
    -- Кнопка закрытия
    local closeButtonContainer = createRoundedFrame(
        "CloseButtonContainer",
        UDim2.new(0, 30, 0, 30),
        UDim2.new(1, -40, 0.5, -15),
        KILLDUI.Config.Colors.Error,
        header,
        15
    )
    closeButtonContainer.BackgroundTransparency = 0.9
    
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(1, 0, 1, 0)
    closeButton.BackgroundTransparency = 1
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = KILLDUI.Config.Fonts.Header
    closeButton.TextSize = 16
    closeButton.Text = "✕"
    closeButton.Parent = closeButtonContainer
    
    -- Эффект наведения для кнопки закрытия
    closeButton.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(closeButtonContainer, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {BackgroundTransparency = 0.5}):Play()
    end)
    
    closeButton.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(closeButtonContainer, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {BackgroundTransparency = 0.9}):Play()
    end)
    
    -- Функция закрытия окна
    closeButton.MouseButton1Click:Connect(function()
        self:CloseWindow(window)
    end)
    
    -- Создаем контейнер контента
    local contentContainer = createRoundedFrame(
        "ContentContainer",
        UDim2.new(1, -20, 1, -60),
        UDim2.new(0, 10, 0, 60),
        KILLDUI.Config.Colors.Panel,
        window,
        8
    )
    contentContainer.BackgroundTransparency = 0.2
    createStroke(contentContainer, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Создаем функционал перетаскивания
    local dragToggle, dragStart, startPos = false, nil, nil
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        local position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        
        game:GetService("TweenService"):Create(window, TweenInfo.new(
            0.1,
            Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out
        ), {Position = position}):Play()
    end
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragToggle = true
            dragStart = input.Position
            startPos = window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragToggle = false
                end
            end)
        end
    end)
    
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragToggle then
            updateDrag(input)
        end
    end)
    
    -- Возвращаем объекты для дальнейшего использования
    local windowObj = {
        Frame = window,
        Header = header,
        Content = contentContainer,
        Title = titleLabel
    }
    
    -- Привязываем методы для создания элементов
    windowObj.CreateTab = function(name)
        return self:CreateTab(windowObj, name)
    end
    
    windowObj.CreateButton = function(text, callback)
        return self:CreateButton(contentContainer, text, callback)
    end
    
    windowObj.CreateToggle = function(text, default, callback)
        return self:CreateToggle(contentContainer, text, default, callback)
    end
    
    windowObj.CreateSlider = function(text, min, max, default, callback)
        return self:CreateSlider(contentContainer, text, min, max, default, callback)
    end
    
    windowObj.CreateTextbox = function(text, placeholder, callback)
        return self:CreateTextbox(contentContainer, text, placeholder, callback)
    end
    
    windowObj.CreateLabel = function(text)
        return self:CreateLabel(contentContainer, text)
    end
    
    windowObj.CreateDropdown = function(text, options, callback)
        return self:CreateDropdown(contentContainer, text, options, callback)
    end
    
    -- Анимируем появление окна
    window.Size = UDim2.new(0, 0, 0, 0)
    window.Position = UDim2.new(0.5, 0, 0.5, 0)
    window.BackgroundTransparency = 1
    
    game:GetService("TweenService"):Create(window, TweenInfo.new(
        0.5,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ), {
        Size = windowSize,
        Position = UDim2.new(0.5, -windowSize.X.Offset/2, 0.5, -windowSize.Y.Offset/2),
        BackgroundTransparency = 0
    }):Play()
    
    return windowObj
end

-- Закрытие окна с анимацией
function KILLDUI:CloseWindow(window)
    local windowFrame = typeof(window) == "table" and window.Frame or window
    
    game:GetService("TweenService"):Create(windowFrame, TweenInfo.new(
        0.5,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.In
    ), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1
    }):Play()
    
    task.delay(0.5, function()
        if windowFrame and windowFrame.Parent then
            windowFrame:Destroy()
        end
    end)
end

-- Создание кнопки
function KILLDUI:CreateButton(parent, text, callback)
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.Size = UDim2.new(1, -20, 0, 36)
    buttonContainer.Position = UDim2.new(0, 10, 0, 10)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = parent
    
    local button = createRoundedFrame(
        "Button_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Primary,
        buttonContainer,
        8
    )
    
    -- Градиент для кнопки
    createGradient(button, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 120, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 80, 180))
    }), 90)
    
    -- Глянцевый эффект
    createGlossEffect(button)
    
    -- Текст кнопки
    local buttonText = Instance.new("TextLabel")
    buttonText.Name = "ButtonText"
    buttonText.Size = UDim2.new(1, 0, 1, 0)
    buttonText.BackgroundTransparency = 1
    buttonText.TextColor3 = Color3.fromRGB(255, 255, 255)
    buttonText.Font = KILLDUI.Config.Fonts.Button
    buttonText.TextSize = KILLDUI.Config.FontSizes.Text
    buttonText.Text = text
    buttonText.Parent = button
    
    -- Функционал кнопки
    local buttonClick = Instance.new("TextButton")
    buttonClick.Name = "ButtonClick"
    buttonClick.Size = UDim2.new(1, 0, 1, 0)
    buttonClick.BackgroundTransparency = 1
    buttonClick.Text = ""
    buttonClick.Parent = button
    
    -- Анимации наведения и нажатия
    buttonClick.MouseEnter:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, -2)}):Play()
    end)
    
    buttonClick.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0)}):Play()
    end)
    
    buttonClick.MouseButton1Down:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed / 2
        ), {Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2)}):Play()
    end)
    
    buttonClick.MouseButton1Up:Connect(function()
        game:GetService("TweenService"):Create(button, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed / 2
        ), {Size = UDim2.new(1, 4, 1, 4), Position = UDim2.new(0, -2, 0, -2)}):Play()
        
        if callback then
            callback()
        end
    end)
    
    return buttonContainer
end

-- Создание переключателя
function KILLDUI:CreateToggle(parent, text, default, callback)
    local toggleContainer = Instance.new("Frame")
    toggleContainer.Name = "ToggleContainer"
    toggleContainer.Size = UDim2.new(1, -20, 0, 36)
    toggleContainer.Position = UDim2.new(0, 10, 0, 10)
    toggleContainer.BackgroundTransparency = 1
    toggleContainer.Parent = parent
    
    local toggleFrame = createRoundedFrame(
        "Toggle_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        toggleContainer,
        8
    )
    toggleFrame.BackgroundTransparency = 0.2
    createStroke(toggleFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст переключателя
    local toggleText = Instance.new("TextLabel")
    toggleText.Name = "ToggleText"
    toggleText.Size = UDim2.new(1, -60, 1, 0)
    toggleText.Position = UDim2.new(0, 10, 0, 0)
    toggleText.BackgroundTransparency = 1
    toggleText.TextColor3 = KILLDUI.Config.Colors.Text
    toggleText.Font = KILLDUI.Config.Fonts.Text
    toggleText.TextSize = KILLDUI.Config.FontSizes.Text
    toggleText.TextXAlignment = Enum.TextXAlignment.Left
    toggleText.Text = text
    toggleText.Parent = toggleFrame
    
    -- Индикатор переключателя
    local toggleIndicator = createRoundedFrame(
        "Indicator",
        UDim2.new(0, 40, 0, 22),
        UDim2.new(1, -50, 0.5, -11),
        Color3.fromRGB(60, 60, 70),
        toggleFrame,
        11
    )
    
    local toggleButton = createRoundedFrame(
        "Button",
        UDim2.new(0, 18, 0, 18),
        UDim2.new(0, 2, 0.5, -9),
        Color3.fromRGB(200, 200, 220),
        toggleIndicator,
        9
    )
    
    -- Состояние переключателя
    local enabled = default or false
    
    -- Обновление внешнего вида
    local function updateToggle()
        if enabled then
            game:GetService("TweenService"):Create(toggleIndicator, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed
            ), {BackgroundColor3 = KILLDUI.Config.Colors.Primary}):Play()
            
            game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed
            ), {Position = UDim2.new(0, 20, 0.5, -9)}):Play()
        else
            game:GetService("TweenService"):Create(toggleIndicator, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed
            ), {BackgroundColor3 = Color3.fromRGB(60, 60, 70)}):Play()
            
            game:GetService("TweenService"):Create(toggleButton, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed
            ), {Position = UDim2.new(0, 2, 0.5, -9)}):Play()
        end
        
        if callback then
            callback(enabled)
        end
    end
    
    -- Установка начального состояния
    updateToggle()
    
    -- Обработка нажатия
    local toggleClick = Instance.new("TextButton")
    toggleClick.Name = "ToggleClick"
    toggleClick.Size = UDim2.new(1, 0, 1, 0)
    toggleClick.BackgroundTransparency = 1
    toggleClick.Text = ""
    toggleClick.Parent = toggleFrame
    
    toggleClick.MouseButton1Click:Connect(function()
        enabled = not enabled
        updateToggle()
    end)
    
    return toggleContainer
end

-- Создание слайдера
function KILLDUI:CreateSlider(parent, text, min, max, default, callback)
    min = min or 0
    max = max or 100
    default = default or min
    
    local sliderContainer = Instance.new("Frame")
    sliderContainer.Name = "SliderContainer"
    sliderContainer.Size = UDim2.new(1, -20, 0, 50)
    sliderContainer.Position = UDim2.new(0, 10, 0, 10)
    sliderContainer.BackgroundTransparency = 1
    sliderContainer.Parent = parent
    
    local sliderFrame = createRoundedFrame(
        "Slider_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        sliderContainer,
        8
    )
    sliderFrame.BackgroundTransparency = 0.2
    createStroke(sliderFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст слайдера
    local sliderText = Instance.new("TextLabel")
    sliderText.Name = "SliderText"
    sliderText.Size = UDim2.new(1, -20, 0, 20)
    sliderText.Position = UDim2.new(0, 10, 0, 5)
    sliderText.BackgroundTransparency = 1
    sliderText.TextColor3 = KILLDUI.Config.Colors.Text
    sliderText.Font = KILLDUI.Config.Fonts.Text
    sliderText.TextSize = KILLDUI.Config.FontSizes.Text
    sliderText.TextXAlignment = Enum.TextXAlignment.Left
    sliderText.Text = text
    sliderText.Parent = sliderFrame
    
    -- Отображение значения
    local valueText = Instance.new("TextLabel")
    valueText.Name = "ValueText"
    valueText.Size = UDim2.new(0, 50, 0, 20)
    valueText.Position = UDim2.new(1, -60, 0, 5)
    valueText.BackgroundTransparency = 1
    valueText.TextColor3 = KILLDUI.Config.Colors.Primary
    valueText.Font = KILLDUI.Config.Fonts.Text
    valueText.TextSize = KILLDUI.Config.FontSizes.Text
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.Text = tostring(default)
    valueText.Parent = sliderFrame
    
    -- Фон слайдера
    local sliderBg = createRoundedFrame(
        "SliderBg",
        UDim2.new(1, -20, 0, 6),
        UDim2.new(0, 10, 0, 30),
        Color3.fromRGB(40, 40, 50),
        sliderFrame,
        3
    )
    
    -- Индикатор слайдера
    -- Индикатор слайдера
    local sliderFill = createRoundedFrame(
        "SliderFill",
        UDim2.new(0, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Primary,
        sliderBg,
        3
    )
    
    -- Градиент для слайдера
    createGradient(sliderFill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 255))
    }), 90)
    
    -- Кнопка (рукоятка) слайдера
    local sliderButton = createRoundedFrame(
        "SliderButton",
        UDim2.new(0, 16, 0, 16),
        UDim2.new(0, 0, 0.5, -8),
        Color3.fromRGB(255, 255, 255),
        sliderFrame,
        8
    )
    createShadow(sliderButton, 10, 0.3)
    
    -- Текущее значение слайдера
    local currentValue = default
    
    -- Функция обновления слайдера
    local function updateSlider(value)
        -- Ограничиваем значение между min и max
        value = math.clamp(value, min, max)
        currentValue = value
        
        -- Обновляем текст значения
        valueText.Text = tostring(math.floor(value * 10) / 10)
        
        -- Рассчитываем процент
        local percent = (value - min) / (max - min)
        
        -- Обновляем позицию кнопки
        local buttonPosX = math.floor(percent * (sliderBg.AbsoluteSize.X - sliderButton.AbsoluteSize.X))
        sliderButton.Position = UDim2.new(0, buttonPosX, 0.5, -8)
        
        -- Обновляем заполнение
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        
        -- Вызываем колбэк
        if callback then
            callback(value)
        end
    end
    
    -- Устанавливаем начальное значение
    updateSlider(default)
    
    -- Обработка перетаскивания
    local dragging = false
    
    sliderButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    
    sliderButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            
            -- Рассчитываем новое значение слайдера на основе позиции клика
            local relativeX = input.Position.X - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            local value = min + percent * (max - min)
            
            updateSlider(value)
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            -- Рассчитываем новое значение слайдера на основе позиции мыши
            local relativeX = input.Position.X - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            local value = min + percent * (max - min)
            
            updateSlider(value)
        end
    end)
    
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return sliderContainer
end

-- Создание текстового поля
function KILLDUI:CreateTextbox(parent, text, placeholder, callback)
    local textboxContainer = Instance.new("Frame")
    textboxContainer.Name = "TextboxContainer"
    textboxContainer.Size = UDim2.new(1, -20, 0, 60)
    textboxContainer.Position = UDim2.new(0, 10, 0, 10)
    textboxContainer.BackgroundTransparency = 1
    textboxContainer.Parent = parent
    
    local textboxFrame = createRoundedFrame(
        "Textbox_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        textboxContainer,
        8
    )
    textboxFrame.BackgroundTransparency = 0.2
    createStroke(textboxFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст подписи
    local textboxLabel = Instance.new("TextLabel")
    textboxLabel.Name = "TextboxLabel"
    textboxLabel.Size = UDim2.new(1, -20, 0, 20)
    textboxLabel.Position = UDim2.new(0, 10, 0, 5)
    textboxLabel.BackgroundTransparency = 1
    textboxLabel.TextColor3 = KILLDUI.Config.Colors.Text
    textboxLabel.Font = KILLDUI.Config.Fonts.Text
    textboxLabel.TextSize = KILLDUI.Config.FontSizes.Text
    textboxLabel.TextXAlignment = Enum.TextXAlignment.Left
    textboxLabel.Text = text
    textboxLabel.Parent = textboxFrame
    
    -- Фон поля ввода
    local inputBg = createRoundedFrame(
        "InputBg",
        UDim2.new(1, -20, 0, 26),
        UDim2.new(0, 10, 0, 28),
        Color3.fromRGB(30, 30, 40),
        textboxFrame,
        6
    )
    createStroke(inputBg, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Поле ввода
    local textbox = Instance.new("TextBox")
    textbox.Name = "Textbox"
    textbox.Size = UDim2.new(1, -16, 1, -8)
    textbox.Position = UDim2.new(0, 8, 0, 4)
    textbox.BackgroundTransparency = 1
    textbox.TextColor3 = KILLDUI.Config.Colors.Text
    textbox.PlaceholderColor3 = Color3.fromRGB(120, 120, 150)
    textbox.PlaceholderText = placeholder or "Введите текст..."
    textbox.Text = ""
    textbox.Font = KILLDUI.Config.Fonts.Text
    textbox.TextSize = KILLDUI.Config.FontSizes.Text
    textbox.TextXAlignment = Enum.TextXAlignment.Left
    textbox.ClearTextOnFocus = false
    textbox.Parent = inputBg
    
    -- Анимации фокуса
    textbox.Focused:Connect(function()
        game:GetService("TweenService"):Create(inputBg, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {BackgroundColor3 = Color3.fromRGB(35, 35, 50)}):Play()
    end)
    
    textbox.FocusLost:Connect(function(enterPressed)
        game:GetService("TweenService"):Create(inputBg, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed
        ), {BackgroundColor3 = Color3.fromRGB(30, 30, 40)}):Play()
        
        if callback then
            callback(textbox.Text, enterPressed)
        end
    end)
    
    return textboxContainer
end

-- Создание выпадающего списка
function KILLDUI:CreateDropdown(parent, text, options, callback)
    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Name = "DropdownContainer"
    dropdownContainer.Size = UDim2.new(1, -20, 0, 60)
    dropdownContainer.Position = UDim2.new(0, 10, 0, 10)
    dropdownContainer.BackgroundTransparency = 1
    dropdownContainer.Parent = parent
    
    local dropdownFrame = createRoundedFrame(
        "Dropdown_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        dropdownContainer,
        8
    )
    dropdownFrame.BackgroundTransparency = 0.2
    dropdownFrame.ClipsDescendants = true
    createStroke(dropdownFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст подписи
    local dropdownLabel = Instance.new("TextLabel")
    dropdownLabel.Name = "DropdownLabel"
    dropdownLabel.Size = UDim2.new(1, -20, 0, 20)
    dropdownLabel.Position = UDim2.new(0, 10, 0, 5)
    dropdownLabel.BackgroundTransparency = 1
    dropdownLabel.TextColor3 = KILLDUI.Config.Colors.Text
    dropdownLabel.Font = KILLDUI.Config.Fonts.Text
    dropdownLabel.TextSize = KILLDUI.Config.FontSizes.Text
    dropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
    dropdownLabel.Text = text
    dropdownLabel.Parent = dropdownFrame
    
    -- Кнопка выбора
    local selectionButton = createRoundedFrame(
        "SelectionButton",
        UDim2.new(1, -20, 0, 26),
        UDim2.new(0, 10, 0, 28),
        Color3.fromRGB(35, 35, 50),
        dropdownFrame,
        6
    )
    createStroke(selectionButton, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст выбора
    local selectionText = Instance.new("TextLabel")
    selectionText.Name = "SelectionText"
    selectionText.Size = UDim2.new(1, -30, 1, 0)
    selectionText.Position = UDim2.new(0, 10, 0, 0)
    selectionText.BackgroundTransparency = 1
    selectionText.TextColor3 = KILLDUI.Config.Colors.Text
    selectionText.Font = KILLDUI.Config.Fonts.Text
    selectionText.TextSize = KILLDUI.Config.FontSizes.Text
    selectionText.TextXAlignment = Enum.TextXAlignment.Left
    selectionText.TextTruncate = Enum.TextTruncate.AtEnd
    selectionText.Text = "Выберите..."
    selectionText.Parent = selectionButton
    
    -- Иконка стрелки
    local arrowIcon = Instance.new("ImageLabel")
    arrowIcon.Name = "ArrowIcon"
    arrowIcon.Size = UDim2.new(0, 16, 0, 16)
    arrowIcon.Position = UDim2.new(1, -20, 0.5, -8)
    arrowIcon.BackgroundTransparency = 1
    arrowIcon.Image = "rbxassetid://6031091004"  -- Стрелка
    arrowIcon.ImageColor3 = KILLDUI.Config.Colors.Text
    arrowIcon.Rotation = 90  -- Направление вниз
    arrowIcon.Parent = selectionButton
    
    -- Контейнер для вариантов
    local optionsContainer = createRoundedFrame(
        "OptionsContainer",
        UDim2.new(1, -20, 0, 0),  -- Начальная высота 0
        UDim2.new(0, 10, 0, 60),
        Color3.fromRGB(25, 25, 35),
        dropdownFrame,
        6
    )
    optionsContainer.BackgroundTransparency = 0.1
    optionsContainer.Visible = false
    createStroke(optionsContainer, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Список вариантов
    local optionsList = Instance.new("ScrollingFrame")
    optionsList.Name = "OptionsList"
    optionsList.Size = UDim2.new(1, -10, 1, -10)
    optionsList.Position = UDim2.new(0, 5, 0, 5)
    optionsList.BackgroundTransparency = 1
    optionsList.ScrollBarThickness = 4
    optionsList.ScrollBarImageColor3 = KILLDUI.Config.Colors.Secondary
    optionsList.ScrollBarImageTransparency = 0.5
    optionsList.CanvasSize = UDim2.new(0, 0, 0, 0)  -- Будет обновлено
    optionsList.Parent = optionsContainer
    
    -- Авторасположение вариантов
    local optionsLayout = Instance.new("UIListLayout")
    optionsLayout.Padding = UDim.new(0, 2)
    optionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    optionsLayout.Parent = optionsList
    
    -- Расчет высоты списка
    local maxOptionsVisible = 5
    local optionHeight = 24
    local listHeight = math.min(#options, maxOptionsVisible) * (optionHeight + optionsLayout.Padding.Offset)
    
    -- Обновление размера списка
    optionsList.CanvasSize = UDim2.new(0, 0, 0, #options * (optionHeight + optionsLayout.Padding.Offset))
    
    -- Выбранное значение
    local selectedOption = nil
    
    -- Открытие/закрытие списка
    local isOpen = false
    local function toggleDropdown()
        isOpen = not isOpen
        
        if isOpen then
            -- Показать варианты
            optionsContainer.Visible = true
            
            -- Анимация открытия
            game:GetService("TweenService"):Create(optionsContainer, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Size = UDim2.new(1, -20, 0, listHeight)}):Play()
            
            game:GetService("TweenService"):Create(arrowIcon, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Rotation = 270}):Play()
            
            game:GetService("TweenService"):Create(dropdownContainer, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Size = UDim2.new(1, -20, 0, 60 + listHeight + 10)}):Play()
        else
            -- Анимация закрытия
            game:GetService("TweenService"):Create(optionsContainer, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Size = UDim2.new(1, -20, 0, 0)}):Play()
            
            game:GetService("TweenService"):Create(arrowIcon, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Rotation = 90}):Play()
            
            game:GetService("TweenService"):Create(dropdownContainer, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed,
                Enum.EasingStyle.Quint,
                Enum.EasingDirection.Out
            ), {Size = UDim2.new(1, -20, 0, 60)}):Play()
            
            -- Скрыть варианты после анимации
            task.delay(KILLDUI.Config.Effects.AnimationSpeed, function()
                if not isOpen then
                    optionsContainer.Visible = false
                end
            end)
        end
    end
    
    -- Создаем кнопку для нажатия
    local dropdownButton = Instance.new("TextButton")
    dropdownButton.Name = "DropdownButton"
    dropdownButton.Size = UDim2.new(1, 0, 1, 0)
    dropdownButton.BackgroundTransparency = 1
    dropdownButton.Text = ""
    dropdownButton.Parent = selectionButton
    
    dropdownButton.MouseButton1Click:Connect(toggleDropdown)
    
    -- Создание вариантов списка
    for i, option in ipairs(options) do
        local optionButton = createRoundedFrame(
            "Option_" .. i,
            UDim2.new(1, -4, 0, optionHeight),
            UDim2.new(0, 2, 0, 0),
            Color3.fromRGB(40, 40, 60),
            optionsList,
            4
        )
        optionButton.BackgroundTransparency = 0.4
        optionButton.LayoutOrder = i
        
        local optionText = Instance.new("TextLabel")
        optionText.Name = "OptionText"
        optionText.Size = UDim2.new(1, -16, 1, 0)
        optionText.Position = UDim2.new(0, 8, 0, 0)
        optionText.BackgroundTransparency = 1
        optionText.TextColor3 = KILLDUI.Config.Colors.Text
        optionText.Font = KILLDUI.Config.Fonts.Text
        optionText.TextSize = KILLDUI.Config.FontSizes.Text
        optionText.TextXAlignment = Enum.TextXAlignment.Left
        optionText.Text = option
        optionText.Parent = optionButton
        
        local optionClick = Instance.new("TextButton")
        optionClick.Name = "OptionClick"
        optionClick.Size = UDim2.new(1, 0, 1, 0)
        optionClick.BackgroundTransparency = 1
        optionClick.Text = ""
        optionClick.Parent = optionButton
        
        -- Анимация наведения
        optionClick.MouseEnter:Connect(function()
            game:GetService("TweenService"):Create(optionButton, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed / 2
            ), {BackgroundTransparency = 0.1}):Play()
        end)
        
        optionClick.MouseLeave:Connect(function()
            game:GetService("TweenService"):Create(optionButton, TweenInfo.new(
                KILLDUI.Config.Effects.AnimationSpeed / 2
            ), {BackgroundTransparency = 0.4}):Play()
        end)
        
        -- Выбор варианта
        optionClick.MouseButton1Click:Connect(function()
            selectedOption = option
            selectionText.Text = option
            toggleDropdown()
            
            if callback then
                callback(option)
            end
        end)
    end
    
    return dropdownContainer
end

-- Создание текстовой метки
function KILLDUI:CreateLabel(parent, text)
    local labelContainer = Instance.new("Frame")
    labelContainer.Name = "LabelContainer"
    labelContainer.Size = UDim2.new(1, -20, 0, 30)
    labelContainer.Position = UDim2.new(0, 10, 0, 10)
    labelContainer.BackgroundTransparency = 1
    labelContainer.Parent = parent
    
    local labelFrame = createRoundedFrame(
        "Label_" .. string.sub(text, 1, 10),
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        labelContainer,
        8
    )
    labelFrame.BackgroundTransparency = 0.5
    createStroke(labelFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    local labelText = Instance.new("TextLabel")
    labelText.Name = "LabelText"
    labelText.Size = UDim2.new(1, -20, 1, 0)
    labelText.Position = UDim2.new(0, 10, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.TextColor3 = KILLDUI.Config.Colors.Text
    labelText.Font = KILLDUI.Config.Fonts.Text
    labelText.TextSize = KILLDUI.Config.FontSizes.Text
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Text = text
    labelText.Parent = labelFrame
    
    -- Метод для обновления текста
    local labelObj = {
        Container = labelContainer,
        Frame = labelFrame,
        TextLabel = labelText
    }
    
    function labelObj:SetText(newText)
        labelText.Text = newText
    end
    
    return labelObj
end

-- Создание секции вкладок
function KILLDUI:CreateTab(windowObj, name)
    -- Добавим контейнер для вкладок, если его еще нет
    if not windowObj.TabContainer then
        -- Создаем контейнер для заголовков вкладок
        local tabHeaderContainer = createRoundedFrame(
            "TabHeaderContainer",
            UDim2.new(1, -20, 0, 40),
            UDim2.new(0, 10, 0, 10),
            KILLDUI.Config.Colors.Panel,
            windowObj.Content,
            8
        )
        tabHeaderContainer.BackgroundTransparency = 0.2
        createStroke(tabHeaderContainer, KILLDUI.Config.Colors.Secondary, 1)
        
        -- Добавляем горизонтальный скролл для заголовков
        local headerScroll = Instance.new("ScrollingFrame")
        headerScroll.Name = "HeaderScroll"
        headerScroll.Size = UDim2.new(1, -10, 1, -10)
        headerScroll.Position = UDim2.new(0, 5, 0, 5)
        headerScroll.BackgroundTransparency = 1
        headerScroll.BorderSizePixel = 0
        headerScroll.ScrollBarThickness = 4
        headerScroll.ScrollingDirection = Enum.ScrollingDirection.X
        headerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        headerScroll.Parent = tabHeaderContainer
        
        -- Создаем контейнер для содержимого вкладок
        local tabContentContainer = createRoundedFrame(
            "TabContentContainer",
            UDim2.new(1, -20, 1, -60),
            UDim2.new(0, 10, 0, 60),
            KILLDUI.Config.Colors.Panel,
            windowObj.Content,
            8
        )
        tabContentContainer.BackgroundTransparency = 0.2
        createStroke(tabContentContainer, KILLDUI.Config.Colors.Secondary, 1)
        
        -- Сохраняем ссылки
        windowObj.TabContainer = {
            HeaderContainer = tabHeaderContainer,
            HeaderScroll = headerScroll,
            ContentContainer = tabContentContainer,
            Tabs = {},
            ActiveTab = nil
        }
        
        -- Добавляем горизонтальный список для кнопок вкладок
        local headerList = Instance.new("UIListLayout")
        headerList.FillDirection = Enum.FillDirection.Horizontal
        headerList.Padding = UDim.new(0, 5)
        headerList.SortOrder = Enum.SortOrder.LayoutOrder
        headerList.Parent = headerScroll
        
        -- Обновляем размер холста при добавлении вкладок
        headerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            headerScroll.CanvasSize = UDim2.new(0, headerList.AbsoluteContentSize.X, 0, 0)
        end)
    end
    
    -- Создаем кнопку вкладки
    local tabButton = createRoundedFrame(
        "Tab_" .. tostring(name),  -- Преобразуем name в строку
        UDim2.new(0, 100, 1, -10),
        UDim2.new(0, 0, 0, 5),
        KILLDUI.Config.Colors.Secondary,
        windowObj.TabContainer.HeaderScroll,
        6
    )
    tabButton.BackgroundTransparency = 0.7
    tabButton.LayoutOrder = #windowObj.TabContainer.Tabs + 1
    
    -- Добавляем текст вкладки
    local tabText = Instance.new("TextLabel")
    tabText.Name = "TabText"
    tabText.Size = UDim2.new(1, 0, 1, 0)
    tabText.BackgroundTransparency = 1
    tabText.TextColor3 = KILLDUI.Config.Colors.Text
    tabText.Font = KILLDUI.Config.Fonts.Button
    tabText.TextSize = KILLDUI.Config.FontSizes.Text
    tabText.Text = tostring(name)  -- Преобразуем name в строку
    tabText.Parent = tabButton
    
    -- Создаем контейнер содержимого вкладки
    local tabContent = createRoundedFrame(
        "Content_" .. tostring(name),  -- Преобразуем name в строку
        UDim2.new(1, -10, 1, -10),
        UDim2.new(0, 5, 0, 5),
        Color3.fromRGB(30, 30, 40),
        windowObj.TabContainer.ContentContainer,
        6
    )
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    
    -- Создаем скроллинг для содержимого
    local contentScroll = Instance.new("ScrollingFrame")
    contentScroll.Name = "ContentScroll"
    contentScroll.Size = UDim2.new(1, -10, 1, -10)
    contentScroll.Position = UDim2.new(0, 5, 0, 5)
    contentScroll.BackgroundTransparency = 1
    contentScroll.BorderSizePixel = 0
    contentScroll.ScrollBarThickness = 4
    contentScroll.ScrollBarImageColor3 = KILLDUI.Config.Colors.Secondary
    contentScroll.ScrollBarImageTransparency = 0.5
    contentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentScroll.Parent = tabContent
    
    -- Добавляем вертикальный список для элементов вкладки
    local contentList = Instance.new("UIListLayout")
    contentList.Padding = UDim.new(0, 8)
    contentList.SortOrder = Enum.SortOrder.LayoutOrder
    contentList.Parent = contentScroll
    
    -- Обновляем размер холста при добавлении элементов
    contentList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentScroll.CanvasSize = UDim2.new(0, 0, 0, contentList.AbsoluteContentSize.Y + 10)
    end)
    
    -- Добавляем функционал нажатия
    local tabClickButton = Instance.new("TextButton")
    tabClickButton.Name = "TabClickButton"
    tabClickButton.Size = UDim2.new(1, 0, 1, 0)
    tabClickButton.BackgroundTransparency = 1
    tabClickButton.Text = ""
    tabClickButton.Parent = tabButton
    
    -- Функция для активации вкладки
    local function activateTab(tab)
        -- Деактивируем текущую активную вкладку
        if windowObj.TabContainer.ActiveTab then
            local activeTab = windowObj.TabContainer.ActiveTab
            activeTab.Button.BackgroundTransparency = 0.7
            activeTab.Content.Visible = false
        end
        
        -- Активируем новую вкладку
        tab.Button.BackgroundTransparency = 0.3
        tab.Content.Visible = true
        windowObj.TabContainer.ActiveTab = tab
    end
    
    -- Создаем объект вкладки
    local tabObj = {
        Button = tabButton,
        Content = tabContent,
        ScrollFrame = contentScroll
    }
    
    -- Добавляем вкладку в список
    table.insert(windowObj.TabContainer.Tabs, tabObj)
    
    -- Обработчик нажатия - теперь правильно ссылается на объект
    tabClickButton.MouseButton1Click:Connect(function()
        activateTab(tabObj)
    end)
    
    -- Добавляем методы для создания элементов
    tabObj.CreateButton = function(text, callback)
        return self:CreateButton(contentScroll, text, callback)
    end
    
    tabObj.CreateToggle = function(text, default, callback)
        return self:CreateToggle(contentScroll, text, default, callback)
    end
    
    tabObj.CreateSlider = function(text, min, max, default, callback)
        return self:CreateSlider(contentScroll, text, min, max, default, callback)
    end
    
    tabObj.CreateTextbox = function(text, placeholder, callback)
        return self:CreateTextbox(contentScroll, text, placeholder, callback)
    end
    
    tabObj.CreateLabel = function(text)
        return self:CreateLabel(contentScroll, text)
    end
    
    tabObj.CreateDropdown = function(text, options, callback)
        return self:CreateDropdown(contentScroll, text, options, callback)
    end
    
    -- Активируем первую вкладку
    if #windowObj.TabContainer.Tabs == 1 then
        activateTab(tabObj)
    end
    
    return tabObj
end

-- Создание уведомления
function KILLDUI:CreateNotification(title, message, type, duration)
    type = type or "info"  -- info, success, warning, error
    duration = duration or 5  -- секунд
    
    -- Выбор цвета уведомления по типу
    local colors = {
        info = KILLDUI.Config.Colors.Primary,
        success = KILLDUI.Config.Colors.Success,
        warning = KILLDUI.Config.Colors.Warning,
        error = KILLDUI.Config.Colors.Error
    }
    
    local notifColor = colors[type] or KILLDUI.Config.Colors.Primary
    
    -- Создаем контейнер уведомлений, если его еще нет
    if not self.NotificationContainer then
        self.NotificationContainer = Instance.new("Frame")
        self.NotificationContainer.Name = "NotificationContainer"
        self.NotificationContainer.Size = UDim2.new(0, 300, 1, -10)
        self.NotificationContainer.Position = UDim2.new(1, -310, 0, 5)
        self.NotificationContainer.BackgroundTransparency = 1
        self.NotificationContainer.Parent = self.ScreenGui
        
        -- Создаем вертикальный список для уведомлений
        local notifList = Instance.new("UIListLayout")
        notifList.Padding = UDim.new(0, 10)
        notifList.SortOrder = Enum.SortOrder.LayoutOrder
        notifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
        notifList.Parent = self.NotificationContainer
    end
    
    -- Создаем уведомление
    local notification = createRoundedFrame(
        "Notification_" .. tick(),
        UDim2.new(1, 0, 0, 0),  -- Высота будет изменена
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(30, 30, 40),
        self.NotificationContainer,
        10
    )
    notification.BackgroundTransparency = 0.1
    notification.LayoutOrder = -tick()  -- Для сортировки новых уведомлений сверху
    createShadow(notification, 30)
    
    -- Полоса цвета типа
    local colorBar = createRoundedFrame(
        "ColorBar",
        UDim2.new(0, 4, 1, -20),
        UDim2.new(0, 10, 0, 10),
        notifColor,
        notification,
        2
    )
    
    -- Верхняя часть с заголовком
    local headerContainer = Instance.new("Frame")
    headerContainer.Name = "HeaderContainer"
    headerContainer.Size = UDim2.new(1, -30, 0, 26)
    headerContainer.Position = UDim2.new(0, 20, 0, 10)
    headerContainer.BackgroundTransparency = 1
    headerContainer.Parent = notification
    
    -- Иконка типа
    local typeIcon = Instance.new("ImageLabel")
    typeIcon.Name = "TypeIcon"
    typeIcon.Size = UDim2.new(0, 20, 0, 20)
    typeIcon.Position = UDim2.new(0, 0, 0, 3)
    typeIcon.BackgroundTransparency = 1
    
    -- Выбор иконки по типу
    local icons = {
        info = "rbxassetid://7059346373",     -- Инфо
        success = "rbxassetid://7733774602",  -- Галочка
        warning = "rbxassetid://7734010488",  -- Восклицательный знак
        error = "rbxassetid://7733924046"     -- Крестик
    }
    
    typeIcon.Image = icons[type] or icons.info
    typeIcon.ImageColor3 = notifColor
    typeIcon.Parent = headerContainer
    
    -- Заголовок
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -30, 0, 20)
    titleLabel.Position = UDim2.new(0, 30, 0, 3)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = KILLDUI.Config.Colors.Text
    titleLabel.Font = KILLDUI.Config.Fonts.Header
    titleLabel.TextSize = KILLDUI.Config.FontSizes.Title - 2
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Text = title
    titleLabel.Parent = headerContainer
    
    -- Кнопка закрытия
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -20, 0, 3)
    closeButton.BackgroundTransparency = 1
    closeButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    closeButton.Font = KILLDUI.Config.Fonts.Header
    closeButton.TextSize = KILLDUI.Config.FontSizes.Text
    closeButton.Text = "✕"
    closeButton.Parent = headerContainer
    
    -- Текст сообщения
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Size = UDim2.new(1, -30, 0, 0)  -- Высота будет изменена
    messageLabel.Position = UDim2.new(0, 20, 0, 40)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextColor3 = KILLDUI.Config.Colors.TextDim
    messageLabel.Font = KILLDUI.Config.Fonts.Text
    messageLabel.TextSize = KILLDUI.Config.FontSizes.Text
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top
    messageLabel.TextWrapped = true
    messageLabel.Text = message
    messageLabel.Parent = notification
    
    -- Рассчитываем высоту сообщения
    local textSize = game:GetService("TextService"):GetTextSize(
        message,
        KILLDUI.Config.FontSizes.Text,
        KILLDUI.Config.Fonts.Text,
        Vector2.new(notification.AbsoluteSize.X - 30, 1000)
    )
    
    -- Устанавливаем высоту сообщения и уведомления
    messageLabel.Size = UDim2.new(1, -30, 0, textSize.Y)
    notification.Size = UDim2.new(1, 0, 0, textSize.Y + 60)
    
    -- Полоса прогресса автозакрытия
    local progressBar = createRoundedFrame(
        "ProgressBar",
        UDim2.new(1, -20, 0, 2),
        UDim2.new(0, 10, 1, -8),
        notifColor,
        notification,
        2
    )
    
    -- Начало анимаций
    notification.BackgroundTransparency = 1
    notification.Position = UDim2.new(1, 20, 0, 0)
    
    -- Анимация появления
    game:GetService("TweenService"):Create(notification, TweenInfo.new(
        0.5,
        Enum.EasingStyle.Back,
        Enum.EasingDirection.Out
    ), {
        BackgroundTransparency = 0.1,
        Position = UDim2.new(0, 0, 0, 0)
    }):Play()
    
    -- Анимация полосы прогресса
    game:GetService("TweenService"):Create(progressBar, TweenInfo.new(
        duration,
        Enum.EasingStyle.Linear
    ), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()
    
    -- Функция закрытия уведомления
    local function closeNotification()
        game:GetService("TweenService"):Create(notification, TweenInfo.new(
            0.5,
            Enum.EasingStyle.Back,
            Enum.EasingDirection.In
        ), {
            BackgroundTransparency = 1,
            Position = UDim2.new(1, 20, 0, 0)
        }):Play()
        
        task.delay(0.5, function()
            notification:Destroy()
        end)
    end
    
    -- Закрытие по нажатию на кнопку
    closeButton.MouseButton1Click:Connect(closeNotification)
    
    -- Автоматическое закрытие
    task.delay(duration, closeNotification)
    
    return notification
end

-- Очистка и закрытие UI
function KILLDUI:Destroy()
    -- Анимация исчезновения
    game:GetService("TweenService"):Create(self.DimBackground, TweenInfo.new(0.5), {
        BackgroundTransparency = 1
    }):Play()
    
    -- Убираем размытие
    if self.BlurEffect then
        removeBlurEffect(self.BlurEffect)
    end
    
    -- Удаляем из списка активных UI
    for i, ui in ipairs(activeUIs) do
        if ui == self then
            table.remove(activeUIs, i)
            break
        end
    end
    
    -- Удаляем ScreenGui после анимаций
    task.delay(0.5, function()
        if self.ScreenGui then
            self.ScreenGui:Destroy()
        end
    end)
end

-- Закрытие всех UI и очистка ресурсов
function KILLDUI.DestroyAll()
    for _, ui in ipairs(activeUIs) do
        ui:Destroy()
    end
    
    activeUIs = {}
    cleanupAllBlurs()
end

-- Создание подсказки
function KILLDUI:CreateTooltip(parent, text)
    -- Создаем контейнер для подсказки
    local tooltip = createRoundedFrame(
        "Tooltip",
        UDim2.new(0, 0, 0, 0),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(20, 20, 30),
        self.ScreenGui,
        8
    )
    tooltip.ZIndex = 1000
    tooltip.BackgroundTransparency = 0.1
    tooltip.Visible = false
    createStroke(tooltip, KILLDUI.Config.Colors.Secondary, 1)
    createShadow(tooltip, 20)
    
    -- Текст подсказки
    local tooltipText = Instance.new("TextLabel")
    tooltipText.Name = "TooltipText"
    tooltipText.Size = UDim2.new(1, -16, 1, -16)
    tooltipText.Position = UDim2.new(0, 8, 0, 8)
    tooltipText.BackgroundTransparency = 1
    tooltipText.TextColor3 = KILLDUI.Config.Colors.Text
    tooltipText.Font = KILLDUI.Config.Fonts.Text
    tooltipText.TextSize = KILLDUI.Config.FontSizes.Small
    tooltipText.TextWrapped = true
    tooltipText.Text = text
    tooltipText.ZIndex = 1001
    tooltipText.Parent = tooltip
    
    -- Показ при наведении
    parent.MouseEnter:Connect(function()
        -- Рассчитываем размер текста
        local textSize = game:GetService("TextService"):GetTextSize(
            text,
            KILLDUI.Config.FontSizes.Small,
            KILLDUI.Config.Fonts.Text,
            Vector2.new(200, 1000)
        )
        
        -- Устанавливаем размер подсказки
        tooltip.Size = UDim2.new(0, math.min(250, textSize.X + 20), 0, textSize.Y + 20)
        
        -- Обновляем позицию
        local parentPos = parent.AbsolutePosition
        local parentSize = parent.AbsoluteSize
        tooltip.Position = UDim2.new(0, parentPos.X + parentSize.X + 10, 0, parentPos.Y)
        
        -- Показываем подсказку с анимацией
        tooltip.BackgroundTransparency = 1
        tooltip.Visible = true
        
        game:GetService("TweenService"):Create(tooltip, TweenInfo.new(
            0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), {
            BackgroundTransparency = 0.1
        }):Play()
    end)
    
    -- Скрытие подсказки
    parent.MouseLeave:Connect(function()
        game:GetService("TweenService"):Create(tooltip, TweenInfo.new(
            0.2,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), {
            BackgroundTransparency = 1
        }):Play()
        
        task.delay(0.2, function()
            tooltip.Visible = false
        end)
    end)
    
    return tooltip
end

-- Создание цветового выбора
function KILLDUI:CreateColorPicker(parent, text, defaultColor, callback)
    local colorPickerContainer = Instance.new("Frame")
    colorPickerContainer.Name = "ColorPickerContainer"
    colorPickerContainer.Size = UDim2.new(1, -20, 0, 60)
    colorPickerContainer.Position = UDim2.new(0, 10, 0, 10)
    colorPickerContainer.BackgroundTransparency = 1
    colorPickerContainer.Parent = parent
    
    local colorPickerFrame = createRoundedFrame(
        "ColorPicker_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        colorPickerContainer,
        8
    )
    colorPickerFrame.BackgroundTransparency = 0.2
    createStroke(colorPickerFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст подписи
    local colorPickerLabel = Instance.new("TextLabel")
    colorPickerLabel.Name = "ColorPickerLabel"
    colorPickerLabel.Size = UDim2.new(1, -120, 0, 20)
    colorPickerLabel.Position = UDim2.new(0, 10, 0, 5)
    colorPickerLabel.BackgroundTransparency = 1
    colorPickerLabel.TextColor3 = KILLDUI.Config.Colors.Text
    colorPickerLabel.Font = KILLDUI.Config.Fonts.Text
    colorPickerLabel.TextSize = KILLDUI.Config.FontSizes.Text
    colorPickerLabel.TextXAlignment = Enum.TextXAlignment.Left
    colorPickerLabel.Text = text
    colorPickerLabel.Parent = colorPickerFrame
    
    -- Предпросмотр цвета
    local colorPreview = createRoundedFrame(
        "ColorPreview",
        UDim2.new(0, 30, 0, 30),
        UDim2.new(1, -40, 0.5, -15),
        defaultColor or Color3.fromRGB(255, 255, 255),
        colorPickerFrame,
        6
    )
    createStroke(colorPreview, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Значения RGB
    local rgbValues = Instance.new("TextLabel")
    rgbValues.Name = "RGBValues"
    rgbValues.Size = UDim2.new(1, -90, 0, 20)
    rgbValues.Position = UDim2.new(0, 10, 0, 30)
    rgbValues.BackgroundTransparency = 1
    rgbValues.TextColor3 = KILLDUI.Config.Colors.TextDim
    rgbValues.Font = KILLDUI.Config.Fonts.Text
    rgbValues.TextSize = KILLDUI.Config.FontSizes.Small
    rgbValues.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Форматирование RGB значений
    local function updateRGBText(color)
        local r = math.floor(color.R * 255)
        local g = math.floor(color.G * 255)
        local b = math.floor(color.B * 255)
        rgbValues.Text = string.format("RGB: %d, %d, %d", r, g, b)
    end
    
    updateRGBText(defaultColor or Color3.fromRGB(255, 255, 255))
    rgbValues.Parent = colorPickerFrame
    
    -- Кнопка для выбора цвета
    local pickButton = Instance.new("TextButton")
    pickButton.Name = "PickButton"
    pickButton.Size = UDim2.new(1, 0, 1, 0)
    pickButton.BackgroundTransparency = 1
    pickButton.Text = ""
    pickButton.Parent = colorPreview
    
    -- Панель выбора цвета
    local pickerPanel = createRoundedFrame(
        "PickerPanel",
        UDim2.new(0, 200, 0, 220),
        UDim2.new(1, 10, 0, 0),
        KILLDUI.Config.Colors.Panel,
        colorPreview,
        8
    )
    pickerPanel.Visible = false
    pickerPanel.ZIndex = 100
    createStroke(pickerPanel, KILLDUI.Config.Colors.Secondary, 1)
    createShadow(pickerPanel, 20)
    
    -- Палитра цветов (HSV)
    local hsvPalette = createRoundedFrame(
        "HSVPalette",
        UDim2.new(1, -20, 0, 150),
        UDim2.new(0, 10, 0, 10),
        Color3.fromRGB(255, 0, 0),
        pickerPanel,
        6
    )
    hsvPalette.ZIndex = 101
    
    -- Создаем градиенты для HSV палитры
    local saturationGradient = Instance.new("UIGradient")
    saturationGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
    })
    saturationGradient.Transparency = NumberSequence.new(0)
    saturationGradient.Rotation = 90
    saturationGradient.Parent = hsvPalette
    
    local valueGradient = Instance.new("UIGradient")
    valueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    valueGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0)
    })
    valueGradient.Rotation = 0
    valueGradient.Parent = hsvPalette
    
    -- Курсор выбора на палитре
    local paletteSelector = createRoundedFrame(
        "PaletteSelector",
        UDim2.new(0, 10, 0, 10),
        UDim2.new(0.5, -5, 0.5, -5),
        Color3.fromRGB(255, 255, 255),
        hsvPalette,
        5
    )
    paletteSelector.ZIndex = 102
    createStroke(paletteSelector, Color3.fromRGB(0, 0, 0), 1)
    
    -- Полоса выбора оттенка (Hue)
    local hueSlider = createRoundedFrame(
        "HueSlider",
        UDim2.new(1, -20, 0, 20),
        UDim2.new(0, 10, 0, 170),
        Color3.fromRGB(255, 255, 255),
        pickerPanel,
        6
    )
    hueSlider.ZIndex = 101
    
    -- Градиент для полосы оттенка
    local hueGradient = Instance.new("UIGradient")
    hueGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),    -- Red
        ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)), -- Yellow
        ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),   -- Green
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),  -- Cyan
        ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),   -- Blue
        ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)), -- Magenta
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))     -- Red
    })
    hueGradient.Transparency = NumberSequence.new(0)
    hueGradient.Rotation = 0
    hueGradient.Parent = hueSlider
    
    -- Курсор выбора на полосе оттенка
    local hueSelector = createRoundedFrame(
        "HueSelector",
        UDim2.new(0, 6, 1, 0),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(255, 255, 255),
        hueSlider,
        3
    )
    hueSelector.ZIndex = 102
    createStroke(hueSelector, Color3.fromRGB(0, 0, 0), 1)
    
    -- Кнопки для подтверждения и отмены
    local confirmButton = createRoundedFrame(
        "ConfirmButton",
        UDim2.new(0.5, -15, 0, 20),
        UDim2.new(0, 10, 0, 190),
        KILLDUI.Config.Colors.Success,
        pickerPanel,
        6
    )
    confirmButton.ZIndex = 101
    
    local confirmText = Instance.new("TextLabel")
    confirmText.Name = "ConfirmText"
    confirmText.Size = UDim2.new(1, 0, 1, 0)
    confirmText.BackgroundTransparency = 1
    confirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmText.Font = KILLDUI.Config.Fonts.Button
    confirmText.TextSize = KILLDUI.Config.FontSizes.Small
    confirmText.Text = "Применить"
    confirmText.ZIndex = 102
    confirmText.Parent = confirmButton
    
    local confirmClickButton = Instance.new("TextButton")
    confirmClickButton.Name = "ConfirmClickButton"
    confirmClickButton.Size = UDim2.new(1, 0, 1, 0)
    confirmClickButton.BackgroundTransparency = 1
    confirmClickButton.Text = ""
    confirmClickButton.ZIndex = 102
    confirmClickButton.Parent = confirmButton
    
    local cancelButton = createRoundedFrame(
        "CancelButton",
        UDim2.new(0.5, -15, 0, 20),
        UDim2.new(0.5, 5, 0, 190),
        KILLDUI.Config.Colors.Error,
        pickerPanel,
        6
    )
    cancelButton.ZIndex = 101
    
    local cancelText = Instance.new("TextLabel")
    cancelText.Name = "CancelText"
    cancelText.Size = UDim2.new(1, 0, 1, 0)
    cancelText.BackgroundTransparency = 1
    cancelText.TextColor3 = Color3.fromRGB(255, 255, 255)
    cancelText.Font = KILLDUI.Config.Fonts.Button
    cancelText.TextSize = KILLDUI.Config.FontSizes.Small
    cancelText.Text = "Отмена"
    cancelText.ZIndex = 102
    cancelText.Parent = cancelButton
    
    local cancelClickButton = Instance.new("TextButton")
    cancelClickButton.Name = "CancelClickButton"
    cancelClickButton.Size = UDim2.new(1, 0, 1, 0)
    cancelClickButton.BackgroundTransparency = 1
    cancelClickButton.Text = ""
    cancelClickButton.ZIndex = 102
    cancelClickButton.Parent = cancelButton
    
    -- Текущие значения HSV
    local currentH, currentS, currentV = 0, 1, 1
    local selectedColor = defaultColor or Color3.fromRGB(255, 0, 0)
    local function updateColor()
        local color = Color3.fromHSV(currentH, currentS, currentV)
        selectedColor = color
        colorPreview.BackgroundColor3 = color
        updateRGBText(color)
        hsvPalette.BackgroundColor3 = Color3.fromHSV(currentH, 1, 1)
    end
    
    -- Инициализация начальных значений из defaultColor
    if defaultColor then
        local h, s, v = Color3.toHSV(defaultColor)
        currentH, currentS, currentV = h, s, v
        hueSelector.Position = UDim2.new(h, -3, 0, 0)
        paletteSelector.Position = UDim2.new(s, -5, 1 - v, -5)
        hsvPalette.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
    end
    
    -- Функция для открытия панели выбора цвета
    local isOpen = false
    local function toggleColorPicker()
        isOpen = not isOpen
        pickerPanel.Visible = isOpen
    end
    
    -- Обработка нажатия на предпросмотр цвета
    pickButton.MouseButton1Click:Connect(toggleColorPicker)
    
    -- Выбор оттенка (Hue)
    hueSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local function updateHue()
                local relative = math.clamp((input.Position.X - hueSlider.AbsolutePosition.X) / hueSlider.AbsoluteSize.X, 0, 1)
                hueSelector.Position = UDim2.new(relative, -3, 0, 0)
                currentH = relative
                updateColor()
            end
            
            updateHue()
            
            local connection
            connection = game:GetService("UserInputService").InputChanged:Connect(function(newInput)
                if newInput.UserInputType == Enum.UserInputType.MouseMovement then
                    input.Position = newInput.Position
                    updateHue()
                end
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(newInput)
                if newInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)
    
    -- Выбор насыщенности и значения (Saturation & Value)
    hsvPalette.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local function updateSV()
                local relativeX = math.clamp((input.Position.X - hsvPalette.AbsolutePosition.X) / hsvPalette.AbsoluteSize.X, 0, 1)
                local relativeY = math.clamp((input.Position.Y - hsvPalette.AbsolutePosition.Y) / hsvPalette.AbsoluteSize.Y, 0, 1)
                
                paletteSelector.Position = UDim2.new(relativeX, -5, relativeY, -5)
                currentS = relativeX
                currentV = 1 - relativeY
                updateColor()
            end
            
            updateSV()
            
            local connection
            connection = game:GetService("UserInputService").InputChanged:Connect(function(newInput)
                if newInput.UserInputType == Enum.UserInputType.MouseMovement then
                    input.Position = newInput.Position
                    updateSV()
                end
            end)
            
            game:GetService("UserInputService").InputEnded:Connect(function(newInput)
                if newInput.UserInputType == Enum.UserInputType.MouseButton1 then
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        end
    end)
    
    -- Подтверждение выбора
    confirmClickButton.MouseButton1Click:Connect(function()
        pickerPanel.Visible = false
        isOpen = false
        if callback then
            callback(selectedColor)
        end
    end)
    
    -- Отмена выбора
    cancelClickButton.MouseButton1Click:Connect(function()
        pickerPanel.Visible = false
        isOpen = false
        -- Восстанавливаем предыдущий цвет
        colorPreview.BackgroundColor3 = defaultColor or Color3.fromRGB(255, 0, 0)
        updateRGBText(defaultColor or Color3.fromRGB(255, 0, 0))
    end)
    
    -- Закрытие при нажатии вне панели
    game:GetService("UserInputService").InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local mousePos = game:GetService("UserInputService"):GetMouseLocation()
            local pickerPos = pickerPanel.AbsolutePosition
            local pickerSize = pickerPanel.AbsoluteSize
            
            if isOpen and (
                mousePos.X < pickerPos.X or 
                mousePos.Y < pickerPos.Y or 
                mousePos.X > pickerPos.X + pickerSize.X or 
                mousePos.Y > pickerPos.Y + pickerSize.Y
            ) then
                if not (
                    mousePos.X >= colorPreview.AbsolutePosition.X and
                    mousePos.Y >= colorPreview.AbsolutePosition.Y and
                    mousePos.X <= colorPreview.AbsolutePosition.X + colorPreview.AbsoluteSize.X and
                    mousePos.Y <= colorPreview.AbsolutePosition.Y + colorPreview.AbsoluteSize.Y
                ) then
                    pickerPanel.Visible = false
                    isOpen = false
                end
            end
        end
    end)
    
    return colorPickerContainer
end

-- Создание прогресс-бара
function KILLDUI:CreateProgressBar(parent, text, initialValue, callback)
    local progressContainer = Instance.new("Frame")
    progressContainer.Name = "ProgressContainer"
    progressContainer.Size = UDim2.new(1, -20, 0, 50)
    progressContainer.Position = UDim2.new(0, 10, 0, 10)
    progressContainer.BackgroundTransparency = 1
    progressContainer.Parent = parent
    
    local progressFrame = createRoundedFrame(
        "Progress_" .. text,
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Panel,
        progressContainer,
        8
    )
    progressFrame.BackgroundTransparency = 0.2
    createStroke(progressFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Текст подписи
    local progressLabel = Instance.new("TextLabel")
    progressLabel.Name = "ProgressLabel"
    progressLabel.Size = UDim2.new(1, -20, 0, 20)
    progressLabel.Position = UDim2.new(0, 10, 0, 5)
    progressLabel.BackgroundTransparency = 1
    progressLabel.TextColor3 = KILLDUI.Config.Colors.Text
    progressLabel.Font = KILLDUI.Config.Fonts.Text
    progressLabel.TextSize = KILLDUI.Config.FontSizes.Text
    progressLabel.TextXAlignment = Enum.TextXAlignment.Left
    progressLabel.Text = text
    progressLabel.Parent = progressFrame
    
    -- Фон прогресс-бара
    local progressBg = createRoundedFrame(
        "ProgressBg",
        UDim2.new(1, -20, 0, 8),
        UDim2.new(0, 10, 0, 30),
        Color3.fromRGB(40, 40, 50),
        progressFrame,
        4
    )
    
    -- Индикатор прогресса
    local progressFill = createRoundedFrame(
        "ProgressFill",
        UDim2.new(initialValue or 0, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        KILLDUI.Config.Colors.Primary,
        progressBg,
        4
    )
    
    -- Градиент для индикатора
    createGradient(progressFill, ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 170, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 120, 255))
    }), 90)
    
    -- Отображение процента
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "PercentLabel"
    percentLabel.Size = UDim2.new(0, 40, 0, 20)
    percentLabel.Position = UDim2.new(1, -50, 0, 5)
    percentLabel.BackgroundTransparency = 1
    percentLabel.TextColor3 = KILLDUI.Config.Colors.Primary
    percentLabel.Font = KILLDUI.Config.Fonts.Text
    percentLabel.TextSize = KILLDUI.Config.FontSizes.Text
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Text = tostring(math.floor((initialValue or 0) * 100)) .. "%"
    percentLabel.Parent = progressFrame
    
    -- Метод для обновления значения
    local progressObj = {
        Container = progressContainer,
        Fill = progressFill,
        Label = percentLabel
    }
    
    function progressObj:SetValue(value)
        -- Ограничиваем значение между 0 и 1
        value = math.clamp(value, 0, 1)
        
        -- Анимация обновления
        game:GetService("TweenService"):Create(progressFill, TweenInfo.new(
            KILLDUI.Config.Effects.AnimationSpeed,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.Out
        ), {Size = UDim2.new(value, 0, 1, 0)}):Play()
        
        -- Обновляем текст
        percentLabel.Text = tostring(math.floor(value * 100)) .. "%"
        
        -- Вызываем колбэк
        if callback then
            callback(value)
        end
    end
    
    return progressObj
end

-- Создание разделителя
function KILLDUI:CreateDivider(parent, text)
    local dividerContainer = Instance.new("Frame")
    dividerContainer.Name = "DividerContainer"
    dividerContainer.Size = UDim2.new(1, -20, 0, 20)
    dividerContainer.Position = UDim2.new(0, 10, 0, 10)
    dividerContainer.BackgroundTransparency = 1
    dividerContainer.Parent = parent
    
    -- Линия слева
    local leftLine = Instance.new("Frame")
    leftLine.Name = "LeftLine"
    leftLine.Size = UDim2.new(0.5, -60, 0, 1)
    leftLine.Position = UDim2.new(0, 0, 0.5, 0)
    leftLine.BackgroundColor3 = KILLDUI.Config.Colors.Secondary
    leftLine.BackgroundTransparency = 0.5
    leftLine.BorderSizePixel = 0
    leftLine.Parent = dividerContainer
    
    -- Линия справа
    local rightLine = Instance.new("Frame")
    rightLine.Name = "RightLine"
    rightLine.Size = UDim2.new(0.5, -60, 0, 1)
    rightLine.Position = UDim2.new(0.5, 60, 0.5, 0)
    rightLine.BackgroundColor3 = KILLDUI.Config.Colors.Secondary
    rightLine.BackgroundTransparency = 0.5
    rightLine.BorderSizePixel = 0
    rightLine.Parent = dividerContainer
    
    -- Текст
    if text and text ~= "" then
        local dividerText = Instance.new("TextLabel")
        dividerText.Name = "DividerText"
        dividerText.Size = UDim2.new(0, 120, 1, 0)
        dividerText.Position = UDim2.new(0.5, -60, 0, 0)
        dividerText.BackgroundTransparency = 1
        dividerText.TextColor3 = KILLDUI.Config.Colors.TextDim
        dividerText.Font = KILLDUI.Config.Fonts.Text
        dividerText.TextSize = KILLDUI.Config.FontSizes.Small
        dividerText.Text = text
        dividerText.Parent = dividerContainer
    else
        -- Если текста нет, просто создаем сплошную линию
        leftLine.Size = UDim2.new(1, 0, 0, 1)
        rightLine.Visible = false
    end
    
    return dividerContainer
end

-- Создание панели с кодом
function KILLDUI:CreateCodeBox(parent, text, language)
    local codeBoxContainer = Instance.new("Frame")
    codeBoxContainer.Name = "CodeBoxContainer"
    codeBoxContainer.Size = UDim2.new(1, -20, 0, 200) -- Высота будет изменена
    codeBoxContainer.Position = UDim2.new(0, 10, 0, 10)
    codeBoxContainer.BackgroundTransparency = 1
    codeBoxContainer.Parent = parent
    
    local codeBoxFrame = createRoundedFrame(
        "CodeBox",
        UDim2.new(1, 0, 1, 0),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(25, 25, 35),
        codeBoxContainer,
        8
    )
    createStroke(codeBoxFrame, KILLDUI.Config.Colors.Secondary, 1)
    
    -- Заголовок с языком
    local headerBar = createRoundedFrame(
        "HeaderBar",
        UDim2.new(1, 0, 0, 30),
        UDim2.new(0, 0, 0, 0),
        Color3.fromRGB(30, 30, 40),
        codeBoxFrame,
        8
    )
    headerBar.ClipsDescendants = true
    
    -- Убираем закругления снизу у заголовка
    local headerMask = Instance.new("Frame")
    headerMask.Name = "HeaderMask"
    headerMask.Size = UDim2.new(1, 0, 0.5, 0)
    headerMask.Position = UDim2.new(0, 0, 0.5, 0)
    headerMask.BackgroundColor3 = headerBar.BackgroundColor3
    headerMask.BorderSizePixel = 0
    headerMask.Parent = headerBar
    
    -- Текст языка
    local languageLabel = Instance.new("TextLabel")
    languageLabel.Name = "LanguageLabel"
    languageLabel.Size = UDim2.new(0, 100, 1, 0)
    languageLabel.Position = UDim2.new(0, 10, 0, 0)
    languageLabel.BackgroundTransparency = 1
    languageLabel.TextColor3 = KILLDUI.Config.Colors.Primary
    languageLabel.Font = KILLDUI.Config.Fonts.Header
    languageLabel.TextSize = KILLDUI.Config.FontSizes.Small
    languageLabel.TextXAlignment = Enum.TextXAlignment.Left
    languageLabel.Text = language or "Code"
    languageLabel.Parent = headerBar
    
    -- Кнопка копирования
    local copyButton = createRoundedFrame(
        "CopyButton",
        UDim2.new(0, 70, 0, 22),
        UDim2.new(1, -80, 0.5, -11),
        KILLDUI.Config.Colors.Panel,
        headerBar,
        4
    )
    copyButton.BackgroundTransparency = 0.5
    
    local copyText = Instance.new("TextLabel")
    copyText.Name = "CopyText"
    copyText.Size = UDim2.new(1, 0, 1, 0)
    copyText.BackgroundTransparency = 1
    copyText.TextColor3 = KILLDUI.Config.Colors.Text
    copyText.Font = KILLDUI.Config.Fonts.Text
    copyText.TextSize = KILLDUI.Config.FontSizes.Small
    copyText.Text = "Copy"
    copyText.Parent = copyButton
    
    local copyButtonClick = Instance.new("TextButton")
    copyButtonClick.Name = "CopyButtonClick"
    copyButtonClick.Size = UDim2.new(1, 0, 1, 0)
    copyButtonClick.BackgroundTransparency = 1
    copyButtonClick.Text = ""
    copyButtonClick.Parent = copyButton
    
    -- Контейнер для текста кода
    local codeContainer = Instance.new("ScrollingFrame")
    codeContainer.Name = "CodeContainer"
    codeContainer.Size = UDim2.new(1, -10, 1, -40)
    codeContainer.Position = UDim2.new(0, 5, 0, 35)
    codeContainer.BackgroundTransparency = 1
    codeContainer.BorderSizePixel = 0
    codeContainer.ScrollBarThickness = 4
    codeContainer.ScrollBarImageColor3 = KILLDUI.Config.Colors.Secondary
    codeContainer.ScrollBarImageTransparency = 0.5
    codeContainer.Parent = codeBoxFrame
    
    -- Нумерация строк
    local lineNumbers = Instance.new("TextLabel")
    lineNumbers.Name = "LineNumbers"
    lineNumbers.Size = UDim2.new(0, 30, 1, 0)
    lineNumbers.Position = UDim2.new(0, 0, 0, 0)
    lineNumbers.BackgroundTransparency = 1
    lineNumbers.TextColor3 = KILLDUI.Config.Colors.TextDim
    lineNumbers.Font = KILLDUI.Config.Fonts.Text
    lineNumbers.TextSize = KILLDUI.Config.FontSizes.Small
    lineNumbers.TextYAlignment = Enum.TextYAlignment.Top
    lineNumbers.TextXAlignment = Enum.TextXAlignment.Right
    lineNumbers.Text = "1"
    lineNumbers.Parent = codeContainer
    
    -- Текст кода
    local codeText = Instance.new("TextLabel")
    codeText.Name = "CodeText"
    codeText.Size = UDim2.new(1, -35, 1, 0)
    codeText.Position = UDim2.new(0, 35, 0, 0)
    codeText.BackgroundTransparency = 1
    codeText.TextColor3 = KILLDUI.Config.Colors.Text
    codeText.Font = KILLDUI.Config.Fonts.Text
    codeText.TextSize = KILLDUI.Config.FontSizes.Small
    codeText.TextYAlignment = Enum.TextYAlignment.Top
    codeText.TextXAlignment = Enum.TextXAlignment.Left
    codeText.Text = text or ""
    codeText.RichText = true
    codeText.Parent = codeContainer
    
    -- Обрабатываем нумерацию строк
    local function updateLineNumbers()
        local lines = 1
        for i = 1, #codeText.Text do
            if string.sub(codeText.Text, i, i) == "\n" then
                lines = lines + 1
            end
        end
        
        local numbers = {}
        for i = 1, lines do
            table.insert(numbers, i)
        end
        
        lineNumbers.Text = table.concat(numbers, "\n")
    end
    
    updateLineNumbers()
    
    -- Обновляем размер на основе количества строк
    local function updateSize()
        local textSize = game:GetService("TextService"):GetTextSize(
            codeText.Text,
            KILLDUI.Config.FontSizes.Small,
            KILLDUI.Config.Fonts.Text,
            Vector2.new(codeText.AbsoluteSize.X, 1000)
        )
        
        -- Ограничиваем высоту максимум в 300 пикселей
        local height = math.min(textSize.Y + 50, 300)
        codeBoxContainer.Size = UDim2.new(1, -20, 0, height)
        
        -- Обновляем размер содержимого прокрутки
        codeContainer.CanvasSize = UDim2.new(0, 0, 0, textSize.Y + 20)
    end
    
    updateSize()
    
    -- Функционал копирования кода
    copyButtonClick.MouseButton1Click:Connect(function()
        setclipboard(codeText.Text)
        
        -- Анимация нажатия
        local originalText = copyText.Text
        copyText.Text = "Copied!"
        copyText.TextColor3 = KILLDUI.Config.Colors.Success
        
        task.delay(1, function()
            copyText.Text = originalText
            copyText.TextColor3 = KILLDUI.Config.Colors.Text
        end)
    end)
    
    -- Объект с методами
    local codeBoxObj = {
        Container = codeBoxContainer,
        Frame = codeBoxFrame,
        TextLabel = codeText
    }
    
    function codeBoxObj:SetText(newText)
        codeText.Text = newText
        updateLineNumbers()
        updateSize()
    end
    
    return codeBoxObj
end

-- Возвращаем библиотеку
return KILLDUI

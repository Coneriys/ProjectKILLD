--[[
    KILLDUI - Современная UI библиотека для Roblox
    Версия 1.0.0
    
    Особенности:
    - Компонентный подход к созданию интерфейсов
    - Анимации и плавные переходы
    - Адаптивный дизайн
    - Темная и светлая темы
    - Простое API для разработчиков
]]

local KILLDUI = {}
KILLDUI.__index = KILLDUI

-- Конфигурация по умолчанию
KILLDUI.Config = {
    Theme = {
        Dark = {
            Background = Color3.fromRGB(30, 30, 30),
            SecondaryBackground = Color3.fromRGB(45, 45, 45),
            Text = Color3.fromRGB(255, 255, 255),
            SecondaryText = Color3.fromRGB(180, 180, 180),
            Accent = Color3.fromRGB(113, 84, 242),
            Error = Color3.fromRGB(255, 64, 64),
            Success = Color3.fromRGB(64, 255, 123),
            Warning = Color3.fromRGB(255, 185, 64)
        },
        Light = {
            Background = Color3.fromRGB(242, 242, 242),
            SecondaryBackground = Color3.fromRGB(225, 225, 225),
            Text = Color3.fromRGB(30, 30, 30),
            SecondaryText = Color3.fromRGB(90, 90, 90),
            Accent = Color3.fromRGB(113, 84, 242),
            Error = Color3.fromRGB(235, 64, 64),
            Success = Color3.fromRGB(64, 235, 123),
            Warning = Color3.fromRGB(235, 165, 64)
        }
    },
    Animation = {
        Duration = 0.3,
        EasingStyle = Enum.EasingStyle.Quint,
        EasingDirection = Enum.EasingDirection.Out
    },
    Font = {
        Regular = Enum.Font.GothamMedium,
        Bold = Enum.Font.GothamBold,
        Light = Enum.Font.GothamSemibold
    }
}

-- Вспомогательные функции
local Utility = {}

-- Создание Tween анимации
function Utility.Tween(instance, properties, duration, easingStyle, easingDirection)
    duration = duration or KILLDUI.Config.Animation.Duration
    easingStyle = easingStyle or KILLDUI.Config.Animation.EasingStyle
    easingDirection = easingDirection or KILLDUI.Config.Animation.EasingDirection
    
    local tweenInfo = TweenInfo.new(duration, easingStyle, easingDirection)
    local tween = game:GetService("TweenService"):Create(instance, tweenInfo, properties)
    tween:Play()
    
    return tween
end

-- Создание нового элемента интерфейса
function Utility.Create(className, properties)
    local instance = Instance.new(className)
    
    for property, value in pairs(properties or {}) do
        instance[property] = value
    end
    
    return instance
end

-- Инициализация библиотеки
function KILLDUI.new(options)
    local self = setmetatable({}, KILLDUI)
    
    -- Применение пользовательских настроек
    self.Options = options or {}
    self.CurrentTheme = self.Options.Theme or "Dark"
    
    -- Создание основного контейнера
    self.ScreenGui = Utility.Create("ScreenGui", {
        Name = "KILLDUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = game:GetService("CoreGui")
    })
    
    -- Инициализация системы уведомлений
    self.NotificationSystem = self:CreateNotificationSystem()
    
    return self
end

-- Система уведомлений
function KILLDUI:CreateNotificationSystem()
    local notificationSystem = {}
    local notificationContainer = Utility.Create("Frame", {
        Name = "NotificationContainer",
        AnchorPoint = Vector2.new(1, 0),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -20, 0, 20),
        Size = UDim2.new(0, 300, 1, -40),
        Parent = self.ScreenGui
    })
    
    local listLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = notificationContainer
    })
    
    function notificationSystem:Show(options)
        options = options or {}
        local title = options.Title or "Уведомление"
        local message = options.Message or ""
        local duration = options.Duration or 5
        local type = options.Type or "Info" -- Info, Success, Warning, Error
        
        local theme = KILLDUI.Config.Theme[self.CurrentTheme]
        
        -- Определение цвета в зависимости от типа уведомления
        local color
        if type == "Success" then
            color = theme.Success
        elseif type == "Warning" then
            color = theme.Warning
        elseif type == "Error" then
            color = theme.Error
        else
            color = theme.Accent
        end
        
        -- Создание уведомления
        local notification = Utility.Create("Frame", {
            Name = "Notification",
            BackgroundColor3 = theme.SecondaryBackground,
            Size = UDim2.new(1, 0, 0, 0), -- Начальная высота 0 для анимации
            ClipsDescendants = true,
            Parent = notificationContainer
        })
        
        -- Скругление углов
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = notification
        })
        
        -- Индикатор типа уведомления
        local indicator = Utility.Create("Frame", {
            Name = "Indicator",
            BackgroundColor3 = color,
            Size = UDim2.new(0, 4, 1, 0),
            Position = UDim2.new(0, 0, 0, 0),
            Parent = notification
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = indicator
        })
        
        -- Заголовок
        local titleLabel = Utility.Create("TextLabel", {
            Name = "Title",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 24),
            Position = UDim2.new(0, 16, 0, 10),
            Text = title,
            TextColor3 = theme.Text,
            TextSize = 16,
            Font = KILLDUI.Config.Font.Bold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = notification
        })
        
        -- Текст уведомления
        local messageLabel = Utility.Create("TextLabel", {
            Name = "Message",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 0),
            Position = UDim2.new(0, 16, 0, 34),
            Text = message,
            TextColor3 = theme.SecondaryText,
            TextSize = 14,
            Font = KILLDUI.Config.Font.Regular,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextWrapped = true,
            Parent = notification
        })
        
        -- Расчет высоты текста
        local textBounds = game:GetService("TextService"):GetTextSize(
            message,
            14,
            KILLDUI.Config.Font.Regular,
            Vector2.new(280, 1000)
        )
        
        messageLabel.Size = UDim2.new(1, -20, 0, textBounds.Y)
        notification.Size = UDim2.new(1, 0, 0, 50 + textBounds.Y)
        
        -- Кнопка закрытия
        local closeButton = Utility.Create("TextButton", {
            Name = "CloseButton",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -30, 0, 10),
            Size = UDim2.new(0, 20, 0, 20),
            Text = "×",
            TextColor3 = theme.SecondaryText,
            TextSize = 20,
            Font = KILLDUI.Config.Font.Bold,
            Parent = notification
        })
        
        -- Анимация появления
        notification.Size = UDim2.new(1, 0, 0, 0)
        Utility.Tween(notification, {Size = UDim2.new(1, 0, 0, 50 + textBounds.Y)}, 0.3)
        
        -- Функция закрытия уведомления
        local function closeNotification()
            Utility.Tween(notification, {Size = UDim2.new(1, 0, 0, 0)}, 0.3).Completed:Connect(function()
                notification:Destroy()
            end)
        end
        
        closeButton.MouseButton1Click:Connect(closeNotification)
        
        -- Автоматическое закрытие через указанное время
        if duration > 0 then
            task.delay(duration, closeNotification)
        end
        
        return notification
    end
    
    return notificationSystem
end

-- Создание окна
function KILLDUI:CreateWindow(options)
    options = options or {}
    local window = {}
    
    local theme = KILLDUI.Config.Theme[self.CurrentTheme]
    
    -- Создание фона окна (затемнение)
    local windowBackground = Utility.Create("Frame", {
        Name = "WindowBackground",
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Size = UDim2.fromScale(1, 1),
        Parent = self.ScreenGui
    })
    
    -- Создание основного окна
    local windowFrame = Utility.Create("Frame", {
        Name = options.Title or "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = theme.Background,
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(options.Width or 500, options.Height or 350),
        Parent = windowBackground
    })
    
    -- Скругление углов
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = windowFrame
    })
    
    -- Создание заголовка окна
    local titleBar = Utility.Create("Frame", {
        Name = "TitleBar",
        BackgroundColor3 = theme.SecondaryBackground,
        Size = UDim2.new(1, 0, 0, 40),
        Parent = windowFrame
    })
    
    Utility.Create("UICorner", {
        CornerRadius = UDim.new(0, 8),
        Parent = titleBar
    })
    
    -- Обрезка углов нижней части заголовка
    local titleBarCover = Utility.Create("Frame", {
        Name = "TitleBarCover",
        BackgroundColor3 = theme.SecondaryBackground,
        Position = UDim2.new(0, 0, 1, -8),
        Size = UDim2.new(1, 0, 0, 8),
        Parent = titleBar
    })
    
    -- Заголовок окна
    local titleLabel = Utility.Create("TextLabel", {
        Name = "Title",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 15, 0, 0),
        Size = UDim2.new(1, -40, 1, 0),
        Font = KILLDUI.Config.Font.Bold,
        Text = options.Title or "Окно",
        TextColor3 = theme.Text,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = titleBar
    })
    
    -- Кнопка закрытия
    local closeButton = Utility.Create("TextButton", {
        Name = "CloseButton",
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -15, 0.5, 0),
        Size = UDim2.new(0, 20, 0, 20),
        Font = KILLDUI.Config.Font.Bold,
        Text = "×",
        TextColor3 = theme.Text,
        TextSize = 24,
        Parent = titleBar
    })
    
    -- Контейнер для содержимого
    local contentContainer = Utility.Create("ScrollingFrame", {
        Name = "ContentContainer",
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 40),
        Size = UDim2.new(1, 0, 1, -40),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = theme.Accent,
        Parent = windowFrame
    })
    
    -- Отступы внутри контейнера
    Utility.Create("UIPadding", {
        PaddingBottom = UDim.new(0, 15),
        PaddingLeft = UDim.new(0, 15),
        PaddingRight = UDim.new(0, 15),
        PaddingTop = UDim.new(0, 15),
        Parent = contentContainer
    })
    
    -- Автоматическое расположение элементов
    local listLayout = Utility.Create("UIListLayout", {
        Padding = UDim.new(0, 10),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = contentContainer
    })
    
    -- Обновление размера контейнера при добавлении элементов
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        contentContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
    end)
    
    -- Функции для оконного API
    
    -- Закрытие окна
    closeButton.MouseButton1Click:Connect(function()
        Utility.Tween(windowFrame, {Position = UDim2.new(0.5, 0, 1.5, 0)}, 0.5).Completed:Connect(function()
            windowBackground:Destroy()
        end)
    end)
    
    -- Добавление кнопки
    function window:AddButton(options)
        options = options or {}
        local button = {}
        
        local buttonFrame = Utility.Create("Frame", {
            Name = "ButtonFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Parent = contentContainer
        })
        
        local buttonElement = Utility.Create("TextButton", {
            Name = options.Title or "Button",
            BackgroundColor3 = theme.Accent,
            Size = UDim2.new(1, 0, 1, 0),
            Font = KILLDUI.Config.Font.Bold,
            Text = options.Title or "Кнопка",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14,
            Parent = buttonFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = buttonElement
        })
        
        -- Эффекты кнопки
        buttonElement.MouseEnter:Connect(function()
            Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255, 255, 255), 0.2)}, 0.2)
        end)
        
        buttonElement.MouseLeave:Connect(function()
            Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent}, 0.2)
        end)
        
        buttonElement.MouseButton1Down:Connect(function()
            Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent:Lerp(Color3.new(0, 0, 0), 0.1)}, 0.1)
        end)
        
        buttonElement.MouseButton1Up:Connect(function()
            Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent}, 0.1)
        end)
        
        -- Подключение callback функции
        if options.Callback and type(options.Callback) == "function" then
            buttonElement.MouseButton1Click:Connect(options.Callback)
        end
        
        return button
    end
    
    -- Добавление переключателя
    function window:AddToggle(options)
        options = options or {}
        local toggle = {}
        toggle.Value = options.Default or false
        
        local toggleFrame = Utility.Create("Frame", {
            Name = "ToggleFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 40),
            Parent = contentContainer
        })
        
        local toggleLabel = Utility.Create("TextLabel", {
            Name = "ToggleLabel",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -60, 1, 0),
            Font = KILLDUI.Config.Font.Regular,
            Text = options.Title or "Переключатель",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = toggleFrame
        })
        
        local toggleBackground = Utility.Create("Frame", {
            Name = "ToggleBackground",
            AnchorPoint = Vector2.new(1, 0.5),
            BackgroundColor3 = toggle.Value and theme.Accent or theme.SecondaryBackground,
            Position = UDim2.new(1, 0, 0.5, 0),
            Size = UDim2.new(0, 50, 0, 24),
            Parent = toggleFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 12),
            Parent = toggleBackground
        })
        
        local toggleIndicator = Utility.Create("Frame", {
            Name = "ToggleIndicator",
            AnchorPoint = Vector2.new(0, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = toggle.Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
            Size = UDim2.new(0, 20, 0, 20),
            Parent = toggleBackground
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 10),
            Parent = toggleIndicator
        })
        
        -- Функция обновления состояния переключателя
        function toggle:Set(value)
            toggle.Value = value
            
            Utility.Tween(toggleBackground, {
                BackgroundColor3 = toggle.Value and theme.Accent or theme.SecondaryBackground
            }, 0.3)
            
            Utility.Tween(toggleIndicator, {
                Position = toggle.Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
            }, 0.3)
            
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(toggle.Value)
            end
        end
        
        -- Обработка нажатий
        toggleBackground.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                toggle:Set(not toggle.Value)
            end
        end)
        
        toggleFrame.MouseButton1Click:Connect(function()
            toggle:Set(not toggle.Value)
        end)
        
        -- Установка начального значения
        toggle:Set(toggle.Value)
        
        return toggle
    end
    
    -- Добавление слайдера
    function window:AddSlider(options)
        options = options or {}
        local slider = {}
        
        local min = options.Min or 0
        local max = options.Max or 100
        local default = math.clamp(options.Default or min, min, max)
        
        slider.Value = default
        
        local sliderFrame = Utility.Create("Frame", {
            Name = "SliderFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 55),
            Parent = contentContainer
        })
        
        local sliderLabel = Utility.Create("TextLabel", {
            Name = "SliderLabel",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, -50, 0, 20),
            Font = KILLDUI.Config.Font.Regular,
            Text = options.Title or "Слайдер",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = sliderFrame
        })
        
        local valueLabel = Utility.Create("TextLabel", {
            Name = "ValueLabel",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -45, 0, 0),
            Size = UDim2.new(0, 45, 0, 20),
            Font = KILLDUI.Config.Font.Regular,
            Text = tostring(slider.Value),
            TextColor3 = theme.SecondaryText,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Right,
            Parent = sliderFrame
        })
        
        local sliderBackground = Utility.Create("Frame", {
            Name = "SliderBackground",
            BackgroundColor3 = theme.SecondaryBackground,
            Position = UDim2.new(0, 0, 0, 25),
            Size = UDim2.new(1, 0, 0, 10),
            Parent = sliderFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 5),
            Parent = sliderBackground
        })
        
        local sliderFill = Utility.Create("Frame", {
            Name = "SliderFill",
            BackgroundColor3 = theme.Accent,
            Size = UDim2.new((slider.Value - min) / (max - min), 0, 1, 0),
            Parent = sliderBackground
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 5),
            Parent = sliderFill
        })
        
        local sliderIndicator = Utility.Create("Frame", {
            Name = "SliderIndicator",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            Position = UDim2.new((slider.Value - min) / (max - min), 0, 0.5, 0),
            Size = UDim2.new(0, 16, 0, 16),
            Parent = sliderBackground
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 8),
            Parent = sliderIndicator
        })
        
        -- Функция установки значения слайдера
        function slider:Set(value)
            local value = math.clamp(value, min, max)
            slider.Value = value
            
            local percent = (value - min) / (max - min)
            
            Utility.Tween(sliderFill, {
                Size = UDim2.new(percent, 0, 1, 0)
            }, 0.2)
            
            Utility.Tween(sliderIndicator, {
                Position = UDim2.new(percent, 0, 0.5, 0)
            }, 0.2)
            
            valueLabel.Text = tostring(math.floor(value * 100) / 100)
            
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(value)
            end
        end
        
        -- Обработка перетаскивания
        local isDragging = false
        
        sliderBackground.MouseButton1Down:Connect(function()
            isDragging = true
        end)
        
        sliderIndicator.MouseButton1Down:Connect(function()
            isDragging = true
        end)
        
        game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                isDragging = false
            end
        end)
        
        game:GetService("UserInputService").InputChanged:Connect(function(input)
            if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePosition = game:GetService("UserInputService"):GetMouseLocation()
                local framePosition = sliderBackground.AbsolutePosition
                local frameSize = sliderBackground.AbsoluteSize
                
                local relativeX = math.clamp((mousePosition.X - framePosition.X) / frameSize.X, 0, 1)
                local value = min + (relativeX * (max - min))
                
                slider:Set(value)
            end
        end)
        
        -- Установка начального значения
        slider:Set(default)
        
        return slider
    end
    
    -- Добавление текстового поля ввода
    function window:AddTextBox(options)
        options = options or {}
        local textBox = {}
        
        local textBoxFrame = Utility.Create("Frame", {
            Name = "TextBoxFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 65),
            Parent = contentContainer
        })
        
        local textBoxLabel = Utility.Create("TextLabel", {
            Name = "TextBoxLabel",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Font = KILLDUI.Config.Font.Regular,
            Text = options.Title or "Текстовое поле",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = textBoxFrame
        })
        
        local textBoxBackground = Utility.Create("Frame", {
            Name = "TextBoxBackground",
            BackgroundColor3 = theme.SecondaryBackground,
            Position = UDim2.new(0, 0, 0, 25),
            Size = UDim2.new(1, 0, 0, 40),
            Parent = textBoxFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = textBoxBackground
        })
        
        local textBoxInput = Utility.Create("TextBox", {
            Name = "TextBoxInput",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -20, 1, 0),
            Font = KILLDUI.Config.Font.Regular,
            PlaceholderColor3 = theme.SecondaryText,
            PlaceholderText = options.Placeholder or "Введите текст...",
            Text = options.Default or "",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            ClearTextOnFocus = options.ClearTextOnFocus,
            Parent = textBoxBackground
        })
        
        -- Обработка изменений
        textBoxInput.FocusLost:Connect(function(enterPressed)
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(textBoxInput.Text, enterPressed)
            end
        end)
        
        -- Функция получения и установки текста
        function textBox:GetText()
            return textBoxInput.Text
        end
        
        function textBox:SetText(text)
            textBoxInput.Text = text or ""
            
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(textBoxInput.Text, false)
            end
        end
        
        return textBox
    end
    
    -- Добавление выпадающего списка
    function window:AddDropdown(options)
        options = options or {}
        local dropdown = {}
        
        dropdown.Selected = options.Default or options.Options and options.Options[1] or ""
        dropdown.Open = false
        
        local dropdownFrame = Utility.Create("Frame", {
            Name = "DropdownFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 65),
            ClipsDescendants = true,
            Parent = contentContainer
        })
        
        local dropdownLabel = Utility.Create("TextLabel", {
            Name = "DropdownLabel",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 0),
            Size = UDim2.new(1, 0, 0, 20),
            Font = KILLDUI.Config.Font.Regular,
            Text = options.Title or "Выпадающий список",
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dropdownFrame
        })
        
        local dropdownButton = Utility.Create("TextButton", {
            Name = "DropdownButton",
            BackgroundColor3 = theme.SecondaryBackground,
            Position = UDim2.new(0, 0, 0, 25),
            Size = UDim2.new(1, 0, 0, 40),
            Font = KILLDUI.Config.Font.Regular,
            Text = "",
            TextColor3 = theme.Text,
            TextSize = 14,
            Parent = dropdownFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = dropdownButton
        })
        
        local selectedOption = Utility.Create("TextLabel", {
            Name = "SelectedOption",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(1, -50, 1, 0),
            Font = KILLDUI.Config.Font.Regular,
            Text = dropdown.Selected,
            TextColor3 = theme.Text,
            TextSize = 14,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = dropdownButton
        })
        
        local dropdownIcon = Utility.Create("ImageLabel", {
            Name = "DropdownIcon",
            BackgroundTransparency = 1,
            Position = UDim2.new(1, -30, 0.5, -7),
            Size = UDim2.new(0, 14, 0, 14),
            Image = "rbxassetid://7072706318", -- Down arrow icon
            ImageColor3 = theme.Text,
            Parent = dropdownButton
        })
        
        local optionsContainer = Utility.Create("Frame", {
            Name = "OptionsContainer",
            BackgroundColor3 = theme.SecondaryBackground,
            Position = UDim2.new(0, 0, 0, 70),
            Size = UDim2.new(1, 0, 0, 0), -- Начальное значение 0 для анимации
            Visible = false,
            ClipsDescendants = true,
            Parent = dropdownFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = optionsContainer
        })
        
        local optionsList = Utility.Create("ScrollingFrame", {
            Name = "OptionsList",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = theme.Accent,
            Parent = optionsContainer
        })
        
        Utility.Create("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 5),
            Parent = optionsList
        })
        
        local optionsLayout = Utility.Create("UIListLayout", {
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = optionsList
        })
        
        -- Обновление размера списка опций
        optionsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            optionsList.CanvasSize = UDim2.new(0, 0, 0, optionsLayout.AbsoluteContentSize.Y)
        end)
        
        -- Функция для создания элемента списка
        local function createOption(text)
            local option = Utility.Create("TextButton", {
                Name = text,
                BackgroundColor3 = theme.Background,
                Size = UDim2.new(1, 0, 0, 30),
                Font = KILLDUI.Config.Font.Regular,
                Text = text,
                TextColor3 = theme.Text,
                TextSize = 14,
                Parent = optionsList
            })
            
            Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = option
            })
            
            option.MouseEnter:Connect(function()
                Utility.Tween(option, {BackgroundColor3 = theme.Accent}, 0.2)
                Utility.Tween(option, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
            end)
            
            option.MouseLeave:Connect(function()
                Utility.Tween(option, {BackgroundColor3 = theme.Background}, 0.2)
                Utility.Tween(option, {TextColor3 = theme.Text}, 0.2)
            end)
            
            option.MouseButton1Click:Connect(function()
                dropdown:Select(text)
                dropdown:Toggle(false)
            end)
            
            return option
        end
        
        -- Функция выбора опции
        function dropdown:Select(option)
            dropdown.Selected = option
            selectedOption.Text = option
            
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(option)
            end
        end
        
        -- Функция переключения выпадающего списка
        function dropdown:Toggle(state)
            if state == nil then
                state = not dropdown.Open
            end
            
            dropdown.Open = state
            
            if state then
                optionsContainer.Visible = true
                Utility.Tween(optionsContainer, {Size = UDim2.new(1, 0, 0, math.min(#options.Options * 35, 150))}, 0.3)
                Utility.Tween(dropdownIcon, {Rotation = 180}, 0.3)
            else
                Utility.Tween(optionsContainer, {Size = UDim2.new(1, 0, 0, 0)}, 0.3).Completed:Connect(function()
                    if not dropdown.Open then
                        optionsContainer.Visible = false
                    end
                end)
                Utility.Tween(dropdownIcon, {Rotation = 0}, 0.3)
            end
        end
        
        -- Заполнение списка опций
        for _, option in ipairs(options.Options or {}) do
            createOption(option)
        end
        
        -- Обработка нажатия на кнопку выпадающего списка
        dropdownButton.MouseButton1Click:Connect(function()
            dropdown:Toggle()
        end)
        
        -- Установка начального значения
        if dropdown.Selected ~= "" then
            dropdown:Select(dropdown.Selected)
        end
        
        return dropdown
    end
    
    -- Добавление разделителя
    function window:AddDivider(options)
        options = options or {}
        
        local dividerFrame = Utility.Create("Frame", {
            Name = "DividerFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 15),
            Parent = contentContainer
        })
        
        local dividerLine = Utility.Create("Frame", {
            Name = "DividerLine",
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = theme.SecondaryBackground,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            Size = UDim2.new(1, 0, 0, 1),
            Parent = dividerFrame
        })
        
        if options.Text then
            dividerLine.Size = UDim2.new(1, -60, 0, 1)
            
            local dividerText = Utility.Create("TextLabel", {
                Name = "DividerText",
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundColor3 = theme.Background,
                Position = UDim2.new(0.5, 0, 0.5, 0),
                Size = UDim2.new(0, 50, 0, 15),
                Font = KILLDUI.Config.Font.Regular,
                Text = options.Text,
                TextColor3 = theme.SecondaryText,
                TextSize = 12,
                Parent = dividerFrame
            })
            
            Utility.Create("UIPadding", {
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                Parent = dividerText
            })
        end
    end
    
    -- Добавление вкладок
    function window:AddTabs(options)
        options = options or {}
        local tabs = {}
        tabs.Selected = nil
        tabs.Buttons = {}
        tabs.Containers = {}
        
        -- Создание контейнера для вкладок
        local tabsFrame = Utility.Create("Frame", {
            Name = "TabsFrame",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 35),
            Parent = contentContainer
        })
        
        local tabsContainer = Utility.Create("Frame", {
            Name = "TabsContainer",
            BackgroundColor3 = theme.SecondaryBackground,
            Size = UDim2.new(1, 0, 1, 0),
            Parent = tabsFrame
        })
        
        Utility.Create("UICorner", {
            CornerRadius = UDim.new(0, 6),
            Parent = tabsContainer
        })
        
        local tabButtons = Utility.Create("ScrollingFrame", {
            Name = "TabButtons",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, 0),
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 0,
            Parent = tabsContainer
        })
        
        local tabsLayout = Utility.Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            Padding = UDim.new(0, 5),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = tabButtons
        })
        
        Utility.Create("UIPadding", {
            PaddingBottom = UDim.new(0, 5),
            PaddingLeft = UDim.new(0, 5),
            PaddingRight = UDim.new(0, 5),
            PaddingTop = UDim.new(0, 5),
            Parent = tabButtons
        })
        
        -- Обновление размера контейнера кнопок вкладок
        tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            tabButtons.CanvasSize = UDim2.new(0, tabsLayout.AbsoluteContentSize.X, 0, 0)
        end)
        
        -- Создание контейнера для контента вкладок
        local tabsContentFrame = Utility.Create("Frame", {
            Name = "TabsContentFrame",
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 0, 0, 40),
            Size = UDim2.new(1, 0, 0, 200),
            Parent = contentContainer
        })
        
        -- Функция выбора вкладки
        function tabs:SelectTab(tabName)
            for name, button in pairs(tabs.Buttons) do
                if name == tabName then
                    Utility.Tween(button, {BackgroundColor3 = theme.Accent}, 0.2)
                    Utility.Tween(button.TabText, {TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                    tabs.Containers[name].Visible = true
                else
                    Utility.Tween(button, {BackgroundColor3 = theme.Background}, 0.2)
                    Utility.Tween(button.TabText, {TextColor3 = theme.Text}, 0.2)
                    tabs.Containers[name].Visible = false
                end
            end
            
            tabs.Selected = tabName
            
            if options.Callback and type(options.Callback) == "function" then
                options.Callback(tabName)
            end
        end
        
        -- Функция добавления вкладки
        function tabs:AddTab(tabOptions)
            tabOptions = tabOptions or {}
            local tabName = tabOptions.Name or "Вкладка " .. (#tabs.Buttons + 1)
            
            -- Создание кнопки вкладки
            local tabButton = Utility.Create("TextButton", {
                Name = tabName .. "Button",
                BackgroundColor3 = theme.Background,
                Size = UDim2.new(0, 0, 1, 0), -- Начальная ширина 0 для автоматического размера
                AutomaticSize = Enum.AutomaticSize.X,
                Font = KILLDUI.Config.Font.Regular,
                Text = "",
                Parent = tabButtons
            })
            
            Utility.Create("UICorner", {
                CornerRadius = UDim.new(0, 4),
                Parent = tabButton
            })
            
            local tabText = Utility.Create("TextLabel", {
                Name = "TabText",
                BackgroundTransparency = 1,
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(1, 0, 1, 0),
                Font = KILLDUI.Config.Font.Regular,
                Text = tabName,
                TextColor3 = theme.Text,
                TextSize = 14,
                Parent = tabButton
            })
            
            Utility.Create("UIPadding", {
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 10),
                PaddingRight = UDim.new(0, 10),
                PaddingTop = UDim.new(0, 5),
                Parent = tabButton
            })
            
            tabButton.TabText = tabText
            
            -- Создание контейнера для контента вкладки
            local tabContainer = Utility.Create("ScrollingFrame", {
                Name = tabName .. "Container",
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0),
                CanvasSize = UDim2.new(0, 0, 0, 0),
                ScrollBarThickness = 4,
                ScrollBarImageColor3 = theme.Accent,
                Visible = false,
                Parent = tabsContentFrame
            })
            
            Utility.Create("UIPadding", {
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft = UDim.new(0, 5),
                PaddingRight = UDim.new(0, 5),
                PaddingTop = UDim.new(0, 5),
                Parent = tabContainer
            })
            
            local tabContentLayout = Utility.Create("UIListLayout", {
                Padding = UDim.new(0, 10),
                SortOrder = Enum.SortOrder.LayoutOrder,
                Parent = tabContainer
            })
            
            -- Обновление размера контента вкладки
            tabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabContentLayout.AbsoluteContentSize.Y)
            end)
            
            -- Добавление в списки
            tabs.Buttons[tabName] = tabButton
            tabs.Containers[tabName] = tabContainer
            
            -- Обработка нажатия на кнопку вкладки
            tabButton.MouseButton1Click:Connect(function()
                tabs:SelectTab(tabName)
            end)
            
            -- Анимация при наведении
            tabButton.MouseEnter:Connect(function()
                if tabs.Selected ~= tabName then
                    Utility.Tween(tabButton, {BackgroundColor3 = theme.Background:Lerp(theme.Accent, 0.3)}, 0.2)
                end
            end)
            
            tabButton.MouseLeave:Connect(function()
                if tabs.Selected ~= tabName then
                    Utility.Tween(tabButton, {BackgroundColor3 = theme.Background}, 0.2)
                end
            end)
            
            -- Функции для добавления элементов во вкладку
            local tab = {}
            
            function tab:AddButton(options)
                options = options or {}
                
                local buttonFrame = Utility.Create("Frame", {
                    Name = "ButtonFrame",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 40),
                    Parent = tabContainer
                })
                
                local buttonElement = Utility.Create("TextButton", {
                    Name = options.Title or "Button",
                    BackgroundColor3 = theme.Accent,
                    Size = UDim2.new(1, 0, 1, 0),
                    Font = KILLDUI.Config.Font.Bold,
                    Text = options.Title or "Кнопка",
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                    TextSize = 14,
                    Parent = buttonFrame
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 6),
                    Parent = buttonElement
                })
                
                -- Эффекты кнопки
                buttonElement.MouseEnter:Connect(function()
                    Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent:Lerp(Color3.fromRGB(255, 255, 255), 0.2)}, 0.2)
                end)
                
                buttonElement.MouseLeave:Connect(function()
                    Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent}, 0.2)
                end)
                
                buttonElement.MouseButton1Down:Connect(function()
                    Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent:Lerp(Color3.new(0, 0, 0), 0.1)}, 0.1)
                end)
                
                buttonElement.MouseButton1Up:Connect(function()
                    Utility.Tween(buttonElement, {BackgroundColor3 = theme.Accent}, 0.1)
                end)
                
                -- Подключение callback функции
                if options.Callback and type(options.Callback) == "function" then
                    buttonElement.MouseButton1Click:Connect(options.Callback)
                end
                
                return buttonElement
            end
            
            -- Дублирование функций из основного окна
            tab.AddToggle = function(options)
                options = options or {}
                
                local toggle = {}
                toggle.Value = options.Default or false
                
                local toggleFrame = Utility.Create("Frame", {
                    Name = "ToggleFrame",
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 0, 40),
                    Parent = tabContainer
                })
                
                local toggleLabel = Utility.Create("TextLabel", {
                    Name = "ToggleLabel",
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Font = KILLDUI.Config.Font.Regular,
                    Text = options.Title or "Переключатель",
                    TextColor3 = theme.Text,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = toggleFrame
                })
                
                local toggleBackground = Utility.Create("Frame", {
                    Name = "ToggleBackground",
                    AnchorPoint = Vector2.new(1, 0.5),
                    BackgroundColor3 = toggle.Value and theme.Accent or theme.SecondaryBackground,
                    Position = UDim2.new(1, 0, 0.5, 0),
                    Size = UDim2.new(0, 50, 0, 24),
                    Parent = toggleFrame
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 12),
                    Parent = toggleBackground
                })
                
                local toggleIndicator = Utility.Create("Frame", {
                    Name = "ToggleIndicator",
                    AnchorPoint = Vector2.new(0, 0.5),
                    BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                    Position = toggle.Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                    Size = UDim2.new(0, 20, 0, 20),
                    Parent = toggleBackground
                })
                
                Utility.Create("UICorner", {
                    CornerRadius = UDim.new(0, 10),
                    Parent = toggleIndicator
                })
                
                -- Функция обновления состояния переключателя
                function toggle:Set(value)
                    toggle.Value = value
                    
                    Utility.Tween(toggleBackground, {
                        BackgroundColor3 = toggle.Value and theme.Accent or theme.SecondaryBackground
                    }, 0.3)
                    
                    Utility.Tween(toggleIndicator, {
                        Position = toggle.Value and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                    }, 0.3)
                    
                    if options.Callback and type(options.Callback) == "function" then
                        options.Callback(toggle.Value)
                    end
                end
                
                -- Обработка нажатий
                toggleBackground.MouseButton1Click:Connect(function()
                    toggle:Set(not toggle.Value)
                end)
                
                toggleFrame.MouseButton1Click:Connect(function()
                    toggle:Set(not toggle.Value)
                end)
                
                -- Установка начального значения
                toggle:Set(toggle.Value)
                
                return toggle
            end
            
            tab.AddSlider = function(options)
                return window:AddSlider(setmetatable(options or {}, {__index = {Parent = tabContainer}}))
            end
            
            tab.AddTextBox = function(options)
                return window:AddTextBox(setmetatable(options or {}, {__index = {Parent = tabContainer}}))
            end
            
            tab.AddDropdown = function(options)
                return window:AddDropdown(setmetatable(options or {}, {__index = {Parent = tabContainer}}))
            end
            
            tab.AddDivider = function(options)
                return window:AddDivider(setmetatable(options or {}, {__index = {Parent = tabContainer}}))
            end
            
            return tab
        end
        
        -- Если есть предопределенные вкладки, добавляем их
        if options.Tabs and type(options.Tabs) == "table" then
            for _, tabInfo in ipairs(options.Tabs) do
                tabs:AddTab(tabInfo)
            end
            
            -- Автоматически выбираем первую вкладку
            local firstTabName = options.Tabs[1] and options.Tabs[1].Name
            if firstTabName then
                tabs:SelectTab(firstTabName)
            end
        end
        
        return tabs
    end
    
    return window
end

-- Добавление уведомления
function KILLDUI:Notify(options)
    return self.NotificationSystem:Show(options)
end

-- Изменение темы
function KILLDUI:SetTheme(themeName)
    if KILLDUI.Config.Theme[themeName] then
        self.CurrentTheme = themeName
        -- Здесь можно добавить логику обновления существующих элементов
    else
        warn("KILLDUI: Theme '" .. tostring(themeName) .. "' does not exist")
    end
end

-- Получение текущей темы
function KILLDUI:GetTheme()
    return KILLDUI.Config.Theme[self.CurrentTheme]
end

-- Создание собственной темы
function KILLDUI:CreateTheme(themeName, themeColors)
    if type(themeName) == "string" and type(themeColors) == "table" then
        KILLDUI.Config.Theme[themeName] = themeColors
    else
        warn("KILLDUI: Invalid theme parameters")
    end
end

-- Уничтожение UI
function KILLDUI:Destroy()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

-- Пример использования
--[[
    local UI = KILLDUI.new()
    
    local mainWindow = UI:CreateWindow({
        Title = "KILLDUI Demo",
        Width = 500,
        Height = 350
    })
    
    mainWindow:AddButton({
        Title = "Нажми меня",
        Callback = function()
            UI:Notify({
                Title = "Успех!",
                Message = "Вы успешно нажали на кнопку",
                Duration = 3,
                Type = "Success"
            })
        end
    })
    
    local toggle = mainWindow:AddToggle({
        Title = "Включить что-то",
        Default = false,
        Callback = function(value)
            print("Переключатель:", value)
        end
    })
    
    local slider = mainWindow:AddSlider({
        Title = "Громкость",
        Min = 0,
        Max = 100,
        Default = 50,
        Callback = function(value)
            print("Громкость:", value)
        end
    })
    
    local dropdown = mainWindow:AddDropdown({
        Title = "Выберите опцию",
        Options = {"Опция 1", "Опция 2", "Опция 3"},
        Default = "Опция 1",
        Callback = function(option)
            print("Выбрана опция:", option)
        end
    })
    
    local textBox = mainWindow:AddTextBox({
        Title = "Введите имя",
        Placeholder = "Ваше имя...",
        Default = "",
        Callback = function(text, enterPressed)
            if enterPressed then
                print("Имя:", text)
            end
        end
    })
    
    mainWindow:AddDivider({
        Text = "Настройки"
    })
    
    local tabs = mainWindow:AddTabs({
        Tabs = {
            {Name = "Основное"},
            {Name = "Настройки"},
            {Name = "Информация"}
        }
    })
    
    tabs:AddTab({Name = "Еще"})
    
    local mainTab = tabs.Tabs["Основное"]
    mainTab:AddButton({
        Title = "Кнопка во вкладке",
        Callback = function()
            print("Нажата кнопка во вкладке")
        end
    })
]]

return KILLDUI

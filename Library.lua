-- Linoria-Style Left-Tab Custom UI Library (350x300, 2-Column Zigzag GroupBoxes, Soft Blue Accent)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

local Library = {
    AccentColor = Color3.fromRGB(115, 185, 255), -- 연한 파란색 기본 포인트
    BackgroundColor = Color3.fromRGB(22, 22, 25),
    SurfaceColor = Color3.fromRGB(28, 28, 32),
    ElementColor = Color3.fromRGB(36, 36, 42),
    BorderOuter = Color3.fromRGB(10, 10, 12),      -- 바깥 검정 선
    BorderInner = Color3.fromRGB(62, 62, 70),      -- 안쪽 회색 선
    TextColor = Color3.fromRGB(235, 238, 245),
    SubTextColor = Color3.fromRGB(155, 160, 172),
    Font = Enum.Font.Code,
    Windows = {},
    ToggleKey = Enum.KeyCode.RightControl,
    Signals = {},
    Unloaded = false,
}

local function safeGetParent()
    local ok, gui = pcall(function()
        return CoreGui
    end)
    if ok and gui then
        return gui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function create(className, props, children)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

-- 리노리아 특유의 [검정 외곽선 -> 회색 내곽선 -> 내부 채움] 2중 보더 프레임
local function makeLinoriaFrame(parent, size, pos, bgColor, zIndex)
    local outer = create("Frame", {
        Name = "LinoriaOuter",
        Size = size or UDim2.fromOffset(100, 100),
        Position = pos or UDim2.fromOffset(0, 0),
        BackgroundColor3 = bgColor or Library.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        ZIndex = zIndex or 1,
        Parent = parent,
    })

    local innerStroke = create("UIStroke", {
        Name = "LinoriaGreyStroke",
        Color = Library.BorderInner,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = outer,
    })

    return outer, innerStroke
end

local function makeThinBorder(parent, color, zIndex)
    return create("UIStroke", {
        Color = color or Library.BorderInner,
        Thickness = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        LineJoinMode = Enum.LineJoinMode.Miter,
        Parent = parent,
    })
end

local function makeDraggable(dragHandle, targetFrame)
    local dragging = false
    local dragInput = nil
    local startPos = nil
    local startInputPos = nil

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInputPos = input.Position
            startPos = targetFrame.Position

            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if conn then
                        conn:Disconnect()
                    end
                end
            end)
        end
    end)

    dragHandle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - startInputPos
            targetFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function Library:Notify(text, duration)
    duration = duration or 3
    if not self._NotifyHolder then
        return
    end

    local notif = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Library.SurfaceColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Parent = self._NotifyHolder,
    })
    makeThinBorder(notif, Library.BorderInner)

    create("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Parent = notif,
    })

    create("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.fromOffset(10, 0),
        BackgroundTransparency = 1,
        Text = tostring(text),
        TextColor3 = Library.TextColor,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = notif,
    })

    task.delay(duration, function()
        if notif and notif.Parent then
            notif:Destroy()
        end
    end)
end

function Library:SetAccentColor(color)
    self.AccentColor = color
    for _, fn in ipairs(self._AccentCallbacks or {}) do
        pcall(fn, color)
    end
end

function Library:OnAccentChanged(callback)
    self._AccentCallbacks = self._AccentCallbacks or {}
    table.insert(self._AccentCallbacks, callback)
    pcall(callback, self.AccentColor)
end

function Library:Unload()
    self.Unloaded = true
    for _, conn in ipairs(self.Signals) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    self.Signals = {}
    if self._ScreenGui then
        self._ScreenGui:Destroy()
        self._ScreenGui = nil
    end
end

function Library:CreateWindow(options)
    options = options or {}
    local titleText = options.Title or "LINORIA LEFT UI"
    local subTitleText = options.SubTitle or "v1.0"
    local size = options.Size or UDim2.fromOffset(350, 300)
    local leftTabWidth = options.TabWidth or 92

    if self._ScreenGui then
        self._ScreenGui:Destroy()
    end

    local screenGui = create("ScreenGui", {
        Name = "LinoriaLeftStyleUI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = safeGetParent(),
    })
    self._ScreenGui = screenGui

    -- 화면을 끄고 여는 전용 플로팅 토글 버튼 (드래그 가능 + 클릭 토글)
    local quickToggleBtn = create("TextButton", {
        Name = "QuickToggleButton",
        Size = UDim2.fromOffset(78, 26),
        Position = UDim2.new(0, 14, 0.5, -150),
        BackgroundColor3 = Library.SurfaceColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Text = "[ UI : ON ]",
        TextColor3 = Library.AccentColor,
        Font = Library.Font,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = screenGui,
    })
    makeThinBorder(quickToggleBtn, Library.BorderInner)

    -- 알림 영역 (우측 상단)
    local notifyHolder = create("Frame", {
        Name = "NotifyHolder",
        Size = UDim2.fromOffset(220, 180),
        Position = UDim2.new(1, -234, 0, 14),
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Parent = notifyHolder,
    })
    self._NotifyHolder = notifyHolder

    -- 메인 윈도우 (기본 350x300)
    local mainFrame = makeLinoriaFrame(
        screenGui,
        size,
        UDim2.new(0.5, -size.X.Offset / 2, 0.5, -size.Y.Offset / 2),
        Library.BackgroundColor
    )
    mainFrame.Name = "MainWindow"
    mainFrame.Active = true

    -- 상단 타이틀 바
    local topBarHeight = 26
    local topBar = create("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, topBarHeight),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.SurfaceColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Parent = mainFrame,
    })
    makeThinBorder(topBar, Library.BorderInner)

    -- 상단 포인트 라인 (연한 파란색)
    local accentBar = create("Frame", {
        Name = "TopAccentLine",
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.AccentColor,
        BorderSizePixel = 0,
        Parent = topBar,
    })
    self:OnAccentChanged(function(col)
        accentBar.BackgroundColor3 = col
    end)

    local titleLabel = create("TextLabel", {
        Name = "TitleLabel",
        Size = UDim2.new(1, -90, 1, -2),
        Position = UDim2.fromOffset(8, 2),
        BackgroundTransparency = 1,
        Text = titleText,
        TextColor3 = Library.TextColor,
        Font = Library.Font,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = topBar,
    })

    local subTitleLabel = create("TextLabel", {
        Name = "SubTitleLabel",
        Size = UDim2.new(0, 44, 1, -2),
        Position = UDim2.new(1, -86, 0, 2),
        BackgroundTransparency = 1,
        Text = subTitleText,
        TextColor3 = Library.SubTextColor,
        Font = Library.Font,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = topBar,
    })

    -- 창 내부 전용 최소화/닫기 버튼 ("_" 숨기기, "X" 닫기)
    local minBtn = create("TextButton", {
        Name = "MinimizeBtn",
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -40, 0.5, -9),
        BackgroundColor3 = Library.ElementColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Text = "_",
        TextColor3 = Library.TextColor,
        Font = Library.Font,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = topBar,
    })
    makeThinBorder(minBtn, Library.BorderInner)

    local closeBtn = create("TextButton", {
        Name = "CloseBtn",
        Size = UDim2.fromOffset(18, 18),
        Position = UDim2.new(1, -20, 0.5, -9),
        BackgroundColor3 = Library.ElementColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Text = "X",
        TextColor3 = Color3.fromRGB(255, 110, 110),
        Font = Library.Font,
        TextSize = 12,
        AutoButtonColor = false,
        Parent = topBar,
    })
    makeThinBorder(closeBtn, Library.BorderInner)

    local isVisible = true
    local function setWindowVisible(state)
        isVisible = state
        mainFrame.Visible = isVisible
        if isVisible then
            quickToggleBtn.Text = "[ UI : ON ]"
            quickToggleBtn.TextColor3 = Library.AccentColor
        else
            quickToggleBtn.Text = "[ UI : OFF ]"
            quickToggleBtn.TextColor3 = Library.SubTextColor
        end
    end

    quickToggleBtn.MouseButton1Click:Connect(function()
        setWindowVisible(not isVisible)
    end)

    minBtn.MouseButton1Click:Connect(function()
        setWindowVisible(false)
    end)

    closeBtn.MouseButton1Click:Connect(function()
        setWindowVisible(false)
    end)

    table.insert(self.Signals, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Library.ToggleKey then
            setWindowVisible(not isVisible)
        end
    end))

    makeDraggable(topBar, mainFrame)
    makeDraggable(quickToggleBtn, quickToggleBtn)

    -- 바디 영역 (왼쪽 세로 탭 영역 + 오른쪽 컨텐츠 영역)
    local bodyFrame = create("Frame", {
        Name = "BodyFrame",
        Size = UDim2.new(1, 0, 1, -topBarHeight),
        Position = UDim2.fromOffset(0, topBarHeight),
        BackgroundTransparency = 1,
        Parent = mainFrame,
    })

    -- 왼쪽 탭 컬럼
    local leftTabColumn = create("ScrollingFrame", {
        Name = "LeftTabColumn",
        Size = UDim2.new(0, leftTabWidth, 1, 0),
        Position = UDim2.fromOffset(0, 0),
        BackgroundColor3 = Library.SurfaceColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Library.AccentColor,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Parent = bodyFrame,
    })
    makeThinBorder(leftTabColumn, Library.BorderInner)

    create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
        Parent = leftTabColumn,
    })
    create("UIPadding", {
        PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6),
        PaddingLeft = UDim.new(0, 6),
        PaddingRight = UDim.new(0, 6),
        Parent = leftTabColumn,
    })

    -- 오른쪽 컨텐츠 영역
    local contentArea = create("Frame", {
        Name = "ContentArea",
        Size = UDim2.new(1, -leftTabWidth, 1, 0),
        Position = UDim2.fromOffset(leftTabWidth, 0),
        BackgroundColor3 = Library.BackgroundColor,
        BorderSizePixel = 1,
        BorderColor3 = Library.BorderOuter,
        Parent = bodyFrame,
    })
    makeThinBorder(contentArea, Library.BorderInner)

    local WindowObj = {
        Tabs = {},
        ActiveTab = nil,
    }

    local function selectTab(tabObj)
        if WindowObj.ActiveTab == tabObj then
            return
        end
        WindowObj.ActiveTab = tabObj

        for _, t in ipairs(WindowObj.Tabs) do
            local active = (t == tabObj)
            t.Page.Visible = active
            t.Button.BackgroundColor3 = active and Library.ElementColor or Library.SurfaceColor
            t.Label.TextColor3 = active and Library.AccentColor or Library.SubTextColor
            t.Indicator.Visible = active
        end
    end

    -- 왼쪽에 탭을 생성하는 함수 (Main 탭 등)
    function WindowObj:AddTab(tabName)
        local tabIndex = #WindowObj.Tabs + 1

        local tabBtn = create("TextButton", {
            Name = "TabBtn_" .. tostring(tabName),
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Library.SurfaceColor,
            BorderSizePixel = 1,
            BorderColor3 = Library.BorderOuter,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = tabIndex,
            Parent = leftTabColumn,
        })
        makeThinBorder(tabBtn, Library.BorderInner)

        local indicator = create("Frame", {
            Name = "ActiveIndicator",
            Size = UDim2.fromOffset(3, 18),
            Position = UDim2.new(0, 3, 0.5, -9),
            BackgroundColor3 = Library.AccentColor,
            BorderSizePixel = 0,
            Visible = false,
            Parent = tabBtn,
        })
        Library:OnAccentChanged(function(col)
            indicator.BackgroundColor3 = col
            if WindowObj.ActiveTab and WindowObj.ActiveTab.Button == tabBtn then
                tabBtn.Label.TextColor3 = col
            end
        end)

        local tabLabel = create("TextLabel", {
            Name = "Label",
            Size = UDim2.new(1, -12, 1, 0),
            Position = UDim2.fromOffset(10, 0),
            BackgroundTransparency = 1,
            Text = tostring(tabName),
            TextColor3 = Library.SubTextColor,
            Font = Library.Font,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = tabBtn,
        })

        -- 탭별 스크롤 페이지
        local page = create("ScrollingFrame", {
            Name = "Page_" .. tostring(tabName),
            Size = UDim2.new(1, 0, 1, 0),
            Position = UDim2.fromOffset(0, 0),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Library.AccentColor,
            CanvasSize = UDim2.fromOffset(0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.None,
            Visible = false,
            Parent = contentArea,
        })

        create("UIPadding", {
            PaddingTop = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft = UDim.new(0, 8),
            PaddingRight = UDim.new(0, 8),
            Parent = page,
        })

        local TabObj = {
            Name = tabName,
            Button = tabBtn,
            Label = tabLabel,
            Indicator = indicator,
            Page = page,
            GroupBoxes = {},
        }

        --[[
            그룹박스 배치 규칙:
            1번째: 왼쪽 위 (col 0, row 0)
            2번째: 오른쪽 위 (col 1, row 0)
            3번째: 아래쪽 왼쪽 (col 0, row 1)
            4번째: 아래쪽 오른쪽 (col 1, row 1)
            5번째: 아래쪽 왼쪽 (col 0, row 2) ...
        ]]
        local function refreshGroupBoxLayout()
            local padLeft = 8
            local padTop = 8
            local gapX = 8
            local gapY = 10

            local availableWidth = math.max(120, contentArea.AbsoluteSize.X - (padLeft * 2))
            local boxWidth = math.max(60, math.floor((availableWidth - gapX) / 2))
            local boxHeight = 148

            local maxBottom = 0

            for idx, gb in ipairs(TabObj.GroupBoxes) do
                local zeroIdx = idx - 1
                local col = zeroIdx % 2
                local row = math.floor(zeroIdx / 2)

                local xPos = padLeft + (col * (boxWidth + gapX))
                local yPos = padTop + (row * (boxHeight + gapY))

                gb.Frame.Position = UDim2.fromOffset(xPos, yPos)
                gb.Frame.Size = UDim2.fromOffset(boxWidth, boxHeight)

                local bottomEdge = yPos + boxHeight + padTop
                if bottomEdge > maxBottom then
                    maxBottom = bottomEdge
                end
            end

            page.CanvasSize = UDim2.fromOffset(0, maxBottom)
        end

        contentArea:GetPropertyChangedSignal("AbsoluteSize"):Connect(refreshGroupBoxLayout)

        tabBtn.MouseButton1Click:Connect(function()
            selectTab(TabObj)
            refreshGroupBoxLayout()
        end)

        -- 그룹박스 생성 함수 (리노리아 특유 회색+검정 선, 연한 파란색 포인트)
        function TabObj:AddGroupBox(groupTitle)
            local gbIndex = #TabObj.GroupBoxes + 1

            local gbFrame = create("Frame", {
                Name = "GroupBox_" .. tostring(groupTitle) .. "_" .. gbIndex,
                Size = UDim2.fromOffset(110, 148),
                Position = UDim2.fromOffset(0, 0),
                BackgroundColor3 = Library.SurfaceColor,
                BorderSizePixel = 1,
                BorderColor3 = Library.BorderOuter, -- 검정 외곽선
                Parent = page,
            })

            -- 리노리아 특유 회색 내부 테두리
            create("UIStroke", {
                Color = Library.BorderInner,
                Thickness = 1,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                LineJoinMode = Enum.LineJoinMode.Miter,
                Parent = gbFrame,
            })

            -- 상단 연한 파란색 악센트 선
            local topLine = create("Frame", {
                Name = "AccentTopLine",
                Size = UDim2.new(1, -2, 0, 2),
                Position = UDim2.fromOffset(1, 1),
                BackgroundColor3 = Library.AccentColor,
                BorderSizePixel = 0,
                Parent = gbFrame,
            })
            Library:OnAccentChanged(function(col)
                topLine.BackgroundColor3 = col
            end)

            -- 그룹박스 헤더 (회색+검정 구분선 포함)
            local headerFrame = create("Frame", {
                Name = "Header",
                Size = UDim2.new(1, 0, 0, 22),
                Position = UDim2.fromOffset(0, 3),
                BackgroundColor3 = Library.BackgroundColor,
                BorderSizePixel = 1,
                BorderColor3 = Library.BorderOuter,
                Parent = gbFrame,
            })
            makeThinBorder(headerFrame, Library.BorderInner)

            local headerLabel = create("TextLabel", {
                Name = "Title",
                Size = UDim2.new(1, -8, 1, 0),
                Position = UDim2.fromOffset(6, 0),
                BackgroundTransparency = 1,
                Text = tostring(groupTitle),
                TextColor3 = Library.AccentColor,
                Font = Library.Font,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextTruncate = Enum.TextTruncate.AtEnd,
                Parent = headerFrame,
            })
            Library:OnAccentChanged(function(col)
                headerLabel.TextColor3 = col
            end)

            -- 그룹박스 내부 컨트롤 스크롤 영역
            local innerScroll = create("ScrollingFrame", {
                Name = "InnerContent",
                Size = UDim2.new(1, -8, 1, -31),
                Position = UDim2.fromOffset(4, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 2,
                ScrollBarImageColor3 = Library.AccentColor,
                CanvasSize = UDim2.fromOffset(0, 0),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = gbFrame,
            })

            create("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 5),
                Parent = innerScroll,
            })
            create("UIPadding", {
                PaddingTop = UDim.new(0, 2),
                PaddingBottom = UDim.new(0, 4),
                Parent = innerScroll,
            })

            local GroupBoxObj = {
                Frame = gbFrame,
                Container = innerScroll,
                Elements = {},
            }

            table.insert(TabObj.GroupBoxes, GroupBoxObj)
            refreshGroupBoxLayout()

            -- 1. Label
            function GroupBoxObj:AddLabel(text)
                local lbl = create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 18),
                    BackgroundTransparency = 1,
                    Text = tostring(text),
                    TextColor3 = Library.SubTextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextWrapped = true,
                    Parent = innerScroll,
                })
                return {
                    SetText = function(_, newText)
                        lbl.Text = tostring(newText)
                    end,
                }
            end

            -- 2. Button
            function GroupBoxObj:AddButton(btnOptions)
                btnOptions = type(btnOptions) == "table" and btnOptions or { Text = tostring(btnOptions) }
                local text = btnOptions.Text or "Button"
                local callback = btnOptions.Callback or function() end

                local btn = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 22),
                    BackgroundColor3 = Library.ElementColor,
                    BorderSizePixel = 1,
                    BorderColor3 = Library.BorderOuter,
                    Text = text,
                    TextColor3 = Library.TextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    AutoButtonColor = false,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = innerScroll,
                })
                makeThinBorder(btn, Library.BorderInner)

                btn.MouseEnter:Connect(function()
                    btn.BorderColor3 = Library.AccentColor
                end)
                btn.MouseLeave:Connect(function()
                    btn.BorderColor3 = Library.BorderOuter
                end)
                btn.MouseButton1Click:Connect(function()
                    btn.BackgroundColor3 = Library.AccentColor
                    btn.TextColor3 = Color3.fromRGB(15, 15, 18)
                    task.delay(0.08, function()
                        if btn and btn.Parent then
                            btn.BackgroundColor3 = Library.ElementColor
                            btn.TextColor3 = Library.TextColor
                        end
                    end)
                    pcall(callback)
                end)

                return {
                    SetText = function(_, t)
                        btn.Text = tostring(t)
                    end,
                }
            end

            -- 3. Toggle (SaveManager 연동 지원)
            function GroupBoxObj:AddToggle(flag, toggleOptions)
                toggleOptions = toggleOptions or {}
                local text = toggleOptions.Text or flag
                local state = toggleOptions.Default == true
                local callback = toggleOptions.Callback or function() end

                local row = create("TextButton", {
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = "",
                    AutoButtonColor = false,
                    Parent = innerScroll,
                })

                local box = create("Frame", {
                    Size = UDim2.fromOffset(14, 14),
                    Position = UDim2.new(0, 0, 0.5, -7),
                    BackgroundColor3 = state and Library.AccentColor or Library.ElementColor,
                    BorderSizePixel = 1,
                    BorderColor3 = Library.BorderOuter,
                    Parent = row,
                })
                makeThinBorder(box, Library.BorderInner)

                local lbl = create("TextLabel", {
                    Size = UDim2.new(1, -20, 1, 0),
                    Position = UDim2.fromOffset(20, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = state and Library.TextColor or Library.SubTextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = row,
                })

                local ToggleObj = {
                    Type = "Toggle",
                    Value = state,
                }

                local function applyState(val, skipCallback)
                    state = val
                    ToggleObj.Value = val
                    box.BackgroundColor3 = val and Library.AccentColor or Library.ElementColor
                    lbl.TextColor3 = val and Library.TextColor or Library.SubTextColor
                    if not skipCallback then
                        pcall(callback, val)
                    end
                end

                Library:OnAccentChanged(function(col)
                    if state then
                        box.BackgroundColor3 = col
                    end
                end)

                function ToggleObj:SetValue(val)
                    applyState(not not val, false)
                end

                row.MouseButton1Click:Connect(function()
                    applyState(not state, false)
                end)

                if flag then
                    Library.Flags = Library.Flags or {}
                    Library.Flags[flag] = ToggleObj
                end

                applyState(state, true)
                return ToggleObj
            end

            -- 4. Slider (SaveManager 연동 지원)
            function GroupBoxObj:AddSlider(flag, sliderOptions)
                sliderOptions = sliderOptions or {}
                local text = sliderOptions.Text or flag
                local minVal = sliderOptions.Min or 0
                local maxVal = sliderOptions.Max or 100
                local defaultVal = sliderOptions.Default or minVal
                local rounding = sliderOptions.Rounding or 0
                local callback = sliderOptions.Callback or function() end

                local function roundNum(n)
                    if rounding <= 0 then
                        return math.floor(n + 0.5)
                    end
                    local mult = 10 ^ rounding
                    return math.floor(n * mult + 0.5) / mult
                end

                local currentVal = math.clamp(roundNum(defaultVal), minVal, maxVal)

                local wrapper = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 30),
                    BackgroundTransparency = 1,
                    Parent = innerScroll,
                })

                local titleLbl = create("TextLabel", {
                    Size = UDim2.new(0.68, 0, 0, 14),
                    Position = UDim2.fromOffset(0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Library.SubTextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = wrapper,
                })

                local valLbl = create("TextLabel", {
                    Size = UDim2.new(0.32, 0, 0, 14),
                    Position = UDim2.new(0.68, 0, 0, 0),
                    BackgroundTransparency = 1,
                    Text = tostring(currentVal),
                    TextColor3 = Library.AccentColor,
                    Font = Library.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Right,
                    Parent = wrapper,
                })
                Library:OnAccentChanged(function(col)
                    valLbl.TextColor3 = col
                end)

                local barBg = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 12),
                    Position = UDim2.fromOffset(0, 16),
                    BackgroundColor3 = Library.ElementColor,
                    BorderSizePixel = 1,
                    BorderColor3 = Library.BorderOuter,
                    Parent = wrapper,
                })
                makeThinBorder(barBg, Library.BorderInner)

                local fillBar = create("Frame", {
                    Size = UDim2.new(0, 0, 1, 0),
                    Position = UDim2.fromOffset(0, 0),
                    BackgroundColor3 = Library.AccentColor,
                    BorderSizePixel = 0,
                    Parent = barBg,
                })
                Library:OnAccentChanged(function(col)
                    fillBar.BackgroundColor3 = col
                end)

                local SliderObj = {
                    Type = "Slider",
                    Value = currentVal,
                }

                local function setSliderValue(v, skipCallback)
                    local clamped = math.clamp(roundNum(tonumber(v) or minVal), minVal, maxVal)
                    currentVal = clamped
                    SliderObj.Value = clamped
                    valLbl.Text = tostring(clamped)

                    local ratio = (maxVal == minVal) and 0 or ((clamped - minVal) / (maxVal - minVal))
                    fillBar.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)

                    if not skipCallback then
                        pcall(callback, clamped)
                    end
                end

                function SliderObj:SetValue(v)
                    setSliderValue(v, false)
                end

                local sliding = false
                local function updateFromX(inputX)
                    local absPos = barBg.AbsolutePosition.X
                    local absSize = math.max(1, barBg.AbsoluteSize.X)
                    local alpha = math.clamp((inputX - absPos) / absSize, 0, 1)
                    local raw = minVal + (maxVal - minVal) * alpha
                    setSliderValue(raw, false)
                end

                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        sliding = true
                        updateFromX(input.Position.X)
                        local conn
                        conn = input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                sliding = false
                                if conn then
                                    conn:Disconnect()
                                end
                            end
                        end)
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                        updateFromX(input.Position.X)
                    end
                end)

                if flag then
                    Library.Flags = Library.Flags or {}
                    Library.Flags[flag] = SliderObj
                end

                setSliderValue(currentVal, true)
                return SliderObj
            end

            -- 5. Input / TextBox (SaveManager 연동 지원)
            function GroupBoxObj:AddInput(flag, inputOptions)
                inputOptions = inputOptions or {}
                local text = inputOptions.Text or flag
                local placeholder = inputOptions.Placeholder or "입력..."
                local defaultVal = inputOptions.Default or ""
                local callback = inputOptions.Callback or function() end

                local wrapper = create("Frame", {
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    Parent = innerScroll,
                })

                create("TextLabel", {
                    Size = UDim2.new(1, 0, 0, 13),
                    Position = UDim2.fromOffset(0, 0),
                    BackgroundTransparency = 1,
                    Text = text,
                    TextColor3 = Library.SubTextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Parent = wrapper,
                })

                local box = create("TextBox", {
                    Size = UDim2.new(1, 0, 0, 18),
                    Position = UDim2.fromOffset(0, 14),
                    BackgroundColor3 = Library.ElementColor,
                    BorderSizePixel = 1,
                    BorderColor3 = Library.BorderOuter,
                    Text = tostring(defaultVal),
                    PlaceholderText = tostring(placeholder),
                    PlaceholderColor3 = Library.SubTextColor,
                    TextColor3 = Library.TextColor,
                    Font = Library.Font,
                    TextSize = 11,
                    ClearTextOnFocus = false,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    Parent = wrapper,
                })
                makeThinBorder(box, Library.BorderInner)

                local InputObj = {
                    Type = "Input",
                    Value = tostring(defaultVal),
                }

                local function setInputValue(v, skipCallback)
                    local str = tostring(v or "")
                    InputObj.Value = str
                    box.Text = str
                    if not skipCallback then
                        pcall(callback, str)
                    end
                end

                function InputObj:SetValue(v)
                    setInputValue(v, false)
                end

                box.FocusLost:Connect(function()
                    setInputValue(box.Text, false)
                end)

                if flag then
                    Library.Flags = Library.Flags or {}
                    Library.Flags[flag] = InputObj
                end

                return InputObj
            end

            return GroupBoxObj
        end

        table.insert(WindowObj.Tabs, TabObj)

        -- 첫 번째 탭(예: Main)은 기본 선택
        if #WindowObj.Tabs == 1 then
            selectTab(TabObj)
            refreshGroupBoxLayout()
        end

        return TabObj
    end

    return WindowObj
end

return Library

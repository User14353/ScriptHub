--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=]

-- ============================================================
--  EXIRE REANIMATE HUB  –  Refactored Edition
--  Features:
--    • Auto-scales to screen size
--    • Draggable window
--    • Working Minimize button
--    • Scrollable script list built from a simple table
--    • Persists through death (PlayerGui, ResetOnSpawn = false)
--    • Rig button sends 2 chat messages (rig msg + ignore note)
-- ============================================================

-- ┌─────────────────────────────────────────────────────────────┐
-- │  ADD YOUR SCRIPTS HERE – just fill in this table            │
-- │                                                             │
-- │  Fields per entry:                                          │
-- │    name        – card title                                 │
-- │    description – shown below name (keybinds etc)            │
-- │    rigMessage  – chat msg sent when Rig is clicked          │
-- │    onRun       – function called when Run is clicked        │
-- └─────────────────────────────────────────────────────────────┘
local Scripts = {
    {
        name        = "Lightning Cannon",
        description = "Press Q to activate. Does something cool.",
        rigMessage  = "-gh 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 150381051 4504231783 6678172953",
        onRun       = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/LightningCannon.lua"))()

            print("Running LC")
        end,
    },
    {
        name        = "Star Glitcher",
        description = "just you average star glitcher, keybindss on bottom left.",
        rigMessage  = "-gh 5316539421 5316549755 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 5699795428 5316479641",
        onRun       = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/StarGlitcher.lua"))()

            print("Running SG")
        end,
    },
    -- Copy and paste a new block like this to add more scripts:
    -- {
    --     name        = "My Script",
    --     description = "Keybind: F. What it does.",
    --     rigMessage  = "My Script By Exire",
    --     onRun       = function() loadstring(game:HttpGet("URL"))() end,
    -- },
}

-- ============================================================
--  INTERNAL – do not edit below unless you know what you're doing
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- ── Blacklist ──────────────────────────────────────────────────
local BlacklistedIDs = {} -- Add/remove IDs here

-- ── Shared chat sender (supports both modern & legacy) ─────────
local function sendChat(msg)
    local generalChannel = TextChatService:FindFirstChild("RBXGeneral", true)
    if generalChannel then
        generalChannel:SendAsync(msg)
    else
        local legacyEvent = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
        if legacyEvent then
            legacyEvent:FireServer(msg, "All")
        end
    end
end

-- ── Rig handler: sends rig message, then the ignore note 0.1s later ──
local function handleRig(rigMessage)
    if table.find(BlacklistedIDs, Player.UserId) then
        warn("[ExireHub] Execution blocked: You are on the blacklist.")
        return
    end
    sendChat(rigMessage)
    task.delay(0.1, function()
        sendChat("-sh")
    end)
end

-- ── Build the GUI ──────────────────────────────────────────────
local function buildHub()
    local existing = Player.PlayerGui:FindFirstChild("ExireReanimateHub")
    if existing then existing:Destroy() end

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name            = "ExireReanimateHub"
    ScreenGui.ResetOnSpawn    = false   -- live on death
    ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent          = Player.PlayerGui

    -- ── MainFrame (scale-based so it fits any resolution) ──────
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name                 = "MainFrame"
    Main.BorderSizePixel      = 0
    Main.BackgroundColor3     = Color3.fromRGB(0, 0, 0)
    Main.BackgroundTransparency = 0.5
    Main.Size                 = UDim2.new(0.277, 0, 0.493, 0)
    Main.Position             = UDim2.new(0.31, 0, 0.177, 0)
    Main.ClipsDescendants     = true

    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius   = UDim.new(0, 12)

    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Transparency   = 0.3
    MainStroke.Thickness      = 3

    local MainStrokeGrad = Instance.new("UIGradient", MainStroke)
    MainStrokeGrad.Rotation   = 90
    MainStrokeGrad.Color      = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
    }

    local MainGrad = Instance.new("UIGradient", Main)
    MainGrad.Rotation         = -90
    MainGrad.Color            = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45)),
    }

    -- ── Title bar ──────────────────────────────────────────────
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Name             = "TitleBar"
    TitleBar.BorderSizePixel  = 0
    TitleBar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    TitleBar.BackgroundTransparency = 0.5
    TitleBar.Size             = UDim2.new(1, 0, 0.085, 0)
    TitleBar.Position         = UDim2.new(0, 0, 0, 0)

    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.BorderSizePixel      = 0
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size                 = UDim2.new(0.85, 0, 1, 0)
    TitleLabel.Position             = UDim2.new(0.02, 0, 0, 0)
    TitleLabel.TextColor3           = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled           = true
    TitleLabel.TextXAlignment       = Enum.TextXAlignment.Left
    TitleLabel.FontFace             = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text                 = "  Exire Reanimate ScriptHub"

    -- Minimize button
    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Name               = "Minimize"
    MinBtn.BorderSizePixel    = 0
    MinBtn.BackgroundColor3   = Color3.fromRGB(30, 30, 30)
    MinBtn.BackgroundTransparency = 0.3
    MinBtn.Size               = UDim2.new(0.1, 0, 1, 0)
    MinBtn.Position           = UDim2.new(0.9, 0, 0, 0)
    MinBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled         = true
    MinBtn.FontFace           = Font.new("rbxasset://fonts/families/Zekton.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.Text               = "–"

    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

    -- ── ScrollingFrame ─────────────────────────────────────────
    local ScrollFrame = Instance.new("ScrollingFrame", Main)
    ScrollFrame.Name                = "ScriptHolder"
    ScrollFrame.BorderSizePixel     = 0
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.Size                = UDim2.new(0.94, 0, 0.88, 0)
    ScrollFrame.Position            = UDim2.new(0.03, 0, 0.1, 0)
    ScrollFrame.ScrollBarThickness  = 5
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
    ScrollFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScrollFrame.ClipsDescendants    = true

    local ListLayout = Instance.new("UIListLayout", ScrollFrame)
    ListLayout.Padding              = UDim.new(0, 8)
    ListLayout.SortOrder            = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment  = Enum.HorizontalAlignment.Center

    local ListPadding = Instance.new("UIPadding", ScrollFrame)
    ListPadding.PaddingTop          = UDim.new(0, 6)
    ListPadding.PaddingBottom       = UDim.new(0, 6)

    -- ── Generate a card for each script ───────────────────────
    local function hoverEffect(btn, enterColor, leaveColor)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = enterColor}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = leaveColor}):Play()
        end)
    end

    for i, scriptData in ipairs(Scripts) do
        local Card = Instance.new("Frame", ScrollFrame)
        Card.Name                   = "Card_" .. i
        Card.LayoutOrder            = i
        Card.BorderSizePixel        = 0
        Card.BackgroundColor3       = Color3.fromRGB(30, 30, 30)
        Card.BackgroundTransparency = 0.4
        Card.Size                   = UDim2.new(0.96, 0, 0, 100)

        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

        local CardGrad = Instance.new("UIGradient", Card)
        CardGrad.Rotation = -90
        CardGrad.Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 10)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 55, 55)),
        }

        local CardStroke = Instance.new("UIStroke", Card)
        CardStroke.Thickness    = 1
        CardStroke.Color        = Color3.fromRGB(70, 70, 70)
        CardStroke.Transparency = 0.5

        -- Name label
        local NameLabel = Instance.new("TextLabel", Card)
        NameLabel.BorderSizePixel       = 0
        NameLabel.BackgroundTransparency = 1
        NameLabel.Size                  = UDim2.new(0.5, 0, 0.28, 0)
        NameLabel.Position              = UDim2.new(0.02, 0, 0.06, 0)
        NameLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
        NameLabel.TextScaled            = true
        NameLabel.TextXAlignment        = Enum.TextXAlignment.Left
        NameLabel.FontFace              = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        NameLabel.Text                  = scriptData.name or "Unnamed Script"

        -- Description label
        local DescLabel = Instance.new("TextLabel", Card)
        DescLabel.BorderSizePixel       = 0
        DescLabel.BackgroundTransparency = 1
        DescLabel.Size                  = UDim2.new(0.5, 0, 0.5, 0)
        DescLabel.Position              = UDim2.new(0.02, 0, 0.4, 0)
        DescLabel.TextColor3            = Color3.fromRGB(200, 200, 200)
        DescLabel.TextScaled            = true
        DescLabel.TextXAlignment        = Enum.TextXAlignment.Left
        DescLabel.TextWrapped           = true
        DescLabel.FontFace              = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        DescLabel.Text                  = scriptData.description or ""

        -- Run button
        local RunBtn = Instance.new("TextButton", Card)
        RunBtn.Name                 = "RunButton"
        RunBtn.BorderSizePixel      = 0
        RunBtn.BackgroundColor3     = Color3.fromRGB(15, 15, 15)
        RunBtn.BackgroundTransparency = 0.3
        RunBtn.Size                 = UDim2.new(0.35, 0, 0.42, 0)
        RunBtn.Position             = UDim2.new(0.53, 0, 0.06, 0)
        RunBtn.TextColor3           = Color3.fromRGB(255, 255, 255)
        RunBtn.TextScaled           = true
        RunBtn.FontFace             = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RunBtn.Text                 = "Run"

        Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 8)
        hoverEffect(RunBtn, Color3.fromRGB(60, 60, 60), Color3.fromRGB(15, 15, 15))

        -- Rig button
        local RigBtn = Instance.new("TextButton", Card)
        RigBtn.Name                 = "RigButton"
        RigBtn.BorderSizePixel      = 0
        RigBtn.BackgroundColor3     = Color3.fromRGB(15, 15, 15)
        RigBtn.BackgroundTransparency = 0.3
        RigBtn.Size                 = UDim2.new(0.16, 0, 0.35, 0)
        RigBtn.Position             = UDim2.new(0.53, 0, 0.57, 0)
        RigBtn.TextColor3           = Color3.fromRGB(255, 255, 255)
        RigBtn.TextScaled           = true
        RigBtn.FontFace             = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RigBtn.Text                 = "Rig"

        Instance.new("UICorner", RigBtn).CornerRadius = UDim.new(0, 8)
        hoverEffect(RigBtn, Color3.fromRGB(60, 60, 60), Color3.fromRGB(15, 15, 15))

        -- ── Callbacks ─────────────────────────────────────────
        RunBtn.MouseButton1Click:Connect(function()
            if scriptData.onRun then
                local ok, err = pcall(scriptData.onRun)
                if not ok then warn("[ExireHub] Run error: " .. tostring(err)) end
            end
        end)

        RigBtn.MouseButton1Click:Connect(function()
            -- sends scriptData.rigMessage, then "-sh ignore..." 0.1s later
            handleRig(scriptData.rigMessage or "Rig")
        end)
    end

    -- ── Minimize logic ─────────────────────────────────────────
    local minimized  = false
    local normalSize = Main.Size
    local miniHeight = TitleBar.Size.Y.Scale + 0.005

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(normalSize.X.Scale, 0, miniHeight, 0)
            }):Play()
            MinBtn.Text = "+"
        else
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = normalSize
            }):Play()
            MinBtn.Text = "–"
        end
    end)

    -- ── Drag logic ─────────────────────────────────────────────
    local dragging = false
    local dragStart, startPos

    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = Main.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = input.Position - dragStart
            local vp    = workspace.CurrentCamera.ViewportSize
            Main.Position = UDim2.new(
                startPos.X.Scale + delta.X / vp.X, startPos.X.Offset,
                startPos.Y.Scale + delta.Y / vp.Y, startPos.Y.Offset
            )
        end
    end)
end

-- ── Build immediately ──────────────────────────────────────────
buildHub()

-- ── Rebuild if destroyed after death ──────────────────────────
Player.CharacterAdded:Connect(function()
    if not Player.PlayerGui:FindFirstChild("ExireReanimateHub") then
        buildHub()
    end
end)

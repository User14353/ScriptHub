--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=]

-- ============================================================
--  EXIRE REANIMATE HUB
--  • Scales to any screen size
--  • Draggable title bar
--  • Minimize collapses ONLY the body (title bar never moves/squishes)
--  • Scrollable script cards auto-built from table
--  • Lives through death (ResetOnSpawn = false)
--  • Rig sends rigMessage then "-sh" 0.8s later
-- ============================================================

local Scripts = {
    {
        name        = "Lightning Cannon",
        description = "Keybinds are: F [Equip/DeEquip],  Z [Minigun],  X [PowerUp],  V [die...Die...DIE],  R [Taunt],  Q [Dash]",
        rigMessage  = "-gh 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 150381051 4504231783 6678172953",
        onRun       = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/LightningCannon.lua"))()
            print("Running LC")
        end,
    },
    {
        name        = "Star Glitcher",
        description = "just your average star glitcher, keybinds on bottom left.",
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
--  INTERNAL
-- ============================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player            = Players.LocalPlayer

local BlacklistedIDs    = {}  -- empty

local function sendChat(msg)
    local ch = TextChatService:FindFirstChild("RBXGeneral", true)
    if ch then
        ch:SendAsync(msg)
    else
        local ev = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
        if ev then ev:FireServer(msg, "All") end
    end
end

local function handleRig(rigMessage)
    if table.find(BlacklistedIDs, Player.UserId) then
        warn("[ExireHub] Blocked: user is blacklisted.")
        return
    end
    sendChat(rigMessage)
    task.delay(0.8, function()
        sendChat("-sh")
    end)
end

-- ── Constants (all pixel-based so nothing warps at odd resolutions) ──
local WIN_W      = 532   -- window width  (pixels)
local WIN_H      = 532   -- window height (pixels)
local TITLE_H    = 45    -- title bar height (pixels)
local CARD_H     = 100   -- each script card height (pixels)
local CARD_PAD   = 8     -- gap between cards (pixels)

local function buildHub()
    local existing = Player.PlayerGui:FindFirstChild("ExireReanimateHub")
    if existing then existing:Destroy() end

    -- ── ScreenGui ──────────────────────────────────────────────
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "ExireReanimateHub"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent         = Player.PlayerGui

    -- ── Outer shell — fixed pixel size, scale-positioned ───────
    -- Using pixels for size keeps all inner elements consistent.
    -- Position uses scale so it sits at the same relative spot on any screen.
    local Shell = Instance.new("Frame", ScreenGui)
    Shell.Name                  = "Shell"
    Shell.BorderSizePixel       = 0
    Shell.BackgroundTransparency = 1
    Shell.Size                  = UDim2.fromOffset(WIN_W, WIN_H)
    Shell.Position              = UDim2.new(0.31, 0, 0.177, 0)
    Shell.ClipsDescendants      = false

    -- ── Title bar — fixed pixel height, NEVER clipped ──────────
    local TitleBar = Instance.new("Frame", Shell)
    TitleBar.Name                  = "TitleBar"
    TitleBar.BorderSizePixel       = 0
    TitleBar.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    TitleBar.BackgroundTransparency = 0.4
    TitleBar.Size                  = UDim2.new(1, 0, 0, TITLE_H)
    TitleBar.Position              = UDim2.fromOffset(0, 0)
    TitleBar.ZIndex                = 10
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TitleStroke = Instance.new("UIStroke", TitleBar)
    TitleStroke.Thickness    = 2
    TitleStroke.Transparency = 0.5
    TitleStroke.Color        = Color3.fromRGB(80, 80, 80)

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.BorderSizePixel        = 0
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size                   = UDim2.new(1, -60, 1, 0)
    TitleLabel.Position               = UDim2.fromOffset(12, 0)
    TitleLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextSize               = 18
    TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left
    TitleLabel.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text                   = "Exire Reanimate ScriptHub"
    TitleLabel.ZIndex                 = 11

    -- Minimize button — lives inside TitleBar, pixel-sized, never scales
    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Name                   = "Minimize"
    MinBtn.BorderSizePixel        = 0
    MinBtn.BackgroundColor3       = Color3.fromRGB(20, 20, 20)
    MinBtn.BackgroundTransparency = 0.3
    MinBtn.Size                   = UDim2.fromOffset(40, TITLE_H)
    MinBtn.Position               = UDim2.new(1, -40, 0, 0)
    MinBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    MinBtn.TextSize               = 22
    MinBtn.FontFace               = Font.new("rbxasset://fonts/families/Zekton.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.Text                   = "–"
    MinBtn.ZIndex                 = 12
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

    -- ── Body — sits directly below the title bar ────────────────
    -- This is the ONLY thing that changes size on minimize.
    local BODY_H = WIN_H - TITLE_H

    local Body = Instance.new("Frame", Shell)
    Body.Name                  = "Body"
    Body.BorderSizePixel       = 0
    Body.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    Body.BackgroundTransparency = 0.5
    Body.Size                  = UDim2.fromOffset(WIN_W, BODY_H)
    Body.Position              = UDim2.fromOffset(0, TITLE_H)
    Body.ClipsDescendants      = true
    Body.ZIndex                = 5
    Instance.new("UICorner", Body).CornerRadius = UDim.new(0, 12)

    local BodyGrad = Instance.new("UIGradient", Body)
    BodyGrad.Rotation = -90
    BodyGrad.Color    = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 10)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45)),
    }

    local BodyStroke = Instance.new("UIStroke", Body)
    BodyStroke.Thickness    = 2
    BodyStroke.Transparency = 0.4
    BodyStroke.Color        = Color3.fromRGB(60, 60, 60)

    -- ── ScrollingFrame inside Body ─────────────────────────────
    local Scroll = Instance.new("ScrollingFrame", Body)
    Scroll.Name                  = "ScriptHolder"
    Scroll.BorderSizePixel       = 0
    Scroll.BackgroundTransparency = 1
    Scroll.Size                  = UDim2.new(1, -14, 1, -10)
    Scroll.Position              = UDim2.fromOffset(7, 5)
    Scroll.ScrollBarThickness    = 4
    Scroll.ScrollBarImageColor3  = Color3.fromRGB(160, 160, 160)
    Scroll.CanvasSize            = UDim2.fromOffset(0, 0)
    Scroll.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    Scroll.ClipsDescendants      = true
    Scroll.ZIndex                = 6

    local ListLayout = Instance.new("UIListLayout", Scroll)
    ListLayout.Padding             = UDim.new(0, CARD_PAD)
    ListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ListPad = Instance.new("UIPadding", Scroll)
    ListPad.PaddingTop    = UDim.new(0, 6)
    ListPad.PaddingBottom = UDim.new(0, 6)

    -- ── Hover helper ───────────────────────────────────────────
    local function hover(btn, on, off)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = on}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = off}):Play()
        end)
    end

    -- ── Script cards ───────────────────────────────────────────
    local CARD_W = WIN_W - 28  -- card pixel width (scroll width minus padding)

    for i, data in ipairs(Scripts) do
        local Card = Instance.new("Frame", Scroll)
        Card.Name                   = "Card_" .. i
        Card.LayoutOrder            = i
        Card.BorderSizePixel        = 0
        Card.BackgroundColor3       = Color3.fromRGB(18, 18, 18)
        Card.BackgroundTransparency = 0.3
        Card.Size                   = UDim2.fromOffset(CARD_W, CARD_H)
        Card.ZIndex                 = 6
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

        local cg = Instance.new("UIGradient", Card)
        cg.Rotation = -90
        cg.Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 8, 8)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 50, 50)),
        }

        local cs = Instance.new("UIStroke", Card)
        cs.Thickness    = 1
        cs.Color        = Color3.fromRGB(65, 65, 65)
        cs.Transparency = 0.4

        -- Script name label  — top left, fixed pixel size
        local NameLbl = Instance.new("TextLabel", Card)
        NameLbl.BorderSizePixel        = 0
        NameLbl.BackgroundTransparency = 1
        NameLbl.Size                   = UDim2.fromOffset(260, 24)
        NameLbl.Position               = UDim2.fromOffset(10, 8)
        NameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        NameLbl.TextSize               = 16
        NameLbl.TextXAlignment         = Enum.TextXAlignment.Left
        NameLbl.TextTruncate           = Enum.TextTruncate.AtEnd
        NameLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        NameLbl.Text                   = data.name or "Unnamed"
        NameLbl.ZIndex                 = 7

        -- Description label — bottom left, fixed pixel size
        local DescLbl = Instance.new("TextLabel", Card)
        DescLbl.BorderSizePixel        = 0
        DescLbl.BackgroundTransparency = 1
        DescLbl.Size                   = UDim2.fromOffset(260, 58)
        DescLbl.Position               = UDim2.fromOffset(10, 36)
        DescLbl.TextColor3             = Color3.fromRGB(190, 190, 190)
        DescLbl.TextSize               = 13
        DescLbl.TextXAlignment         = Enum.TextXAlignment.Left
        DescLbl.TextWrapped            = true
        DescLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        DescLbl.Text                   = data.description or ""
        DescLbl.ZIndex                 = 7

        -- Run button — right side, top, pixel-sized
        local RunBtn = Instance.new("TextButton", Card)
        RunBtn.Name                   = "RunButton"
        RunBtn.BorderSizePixel        = 0
        RunBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RunBtn.BackgroundTransparency = 0.5
        RunBtn.Size                   = UDim2.fromOffset(165, 41)
        RunBtn.Position               = UDim2.fromOffset(CARD_W - 175, 7)
        RunBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RunBtn.TextSize               = 18
        RunBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RunBtn.Text                   = "Run"
        RunBtn.ZIndex                 = 8
        Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0, 8)
        hover(RunBtn, Color3.fromRGB(50, 50, 50), Color3.fromRGB(0, 0, 0))

        -- Rig button — right side, bottom, pixel-sized
        local RigBtn = Instance.new("TextButton", Card)
        RigBtn.Name                   = "RigButton"
        RigBtn.BorderSizePixel        = 0
        RigBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RigBtn.BackgroundTransparency = 0.5
        RigBtn.Size                   = UDim2.fromOffset(72, 33)
        RigBtn.Position               = UDim2.fromOffset(CARD_W - 82, 57)
        RigBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RigBtn.TextSize               = 16
        RigBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RigBtn.Text                   = "Rig"
        RigBtn.ZIndex                 = 8
        Instance.new("UICorner", RigBtn).CornerRadius = UDim.new(0, 8)
        hover(RigBtn, Color3.fromRGB(50, 50, 50), Color3.fromRGB(0, 0, 0))

        -- Callbacks
        RunBtn.MouseButton1Click:Connect(function()
            if data.onRun then
                local ok, err = pcall(data.onRun)
                if not ok then warn("[ExireHub] Run error: " .. tostring(err)) end
            end
        end)

        RigBtn.MouseButton1Click:Connect(function()
            handleRig(data.rigMessage or "Rig")
        end)
    end

    -- ── Minimize — only Body changes, Shell/TitleBar untouched ─
    local minimized = false

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Body, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(WIN_W, 0)
            }):Play()
            MinBtn.Text = "+"
        else
            TweenService:Create(Body, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(WIN_W, BODY_H)
            }):Play()
            MinBtn.Text = "–"
        end
    end)

    -- ── Drag — moves Shell, title bar drags naturally ───────────
    local dragging, dragStart, startPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = Shell.Position
        end
    end)

    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (
            inp.UserInputType == Enum.UserInputType.MouseMovement or
            inp.UserInputType == Enum.UserInputType.Touch
        ) then
            local delta = inp.Position - dragStart
            local vp    = workspace.CurrentCamera.ViewportSize
            Shell.Position = UDim2.new(
                startPos.X.Scale + delta.X / vp.X, 0,
                startPos.Y.Scale + delta.Y / vp.Y, 0
            )
        end
    end)
end

buildHub()

Player.CharacterAdded:Connect(function()
    if not Player.PlayerGui:FindFirstChild("ExireReanimateHub") then
        buildHub()
    end
end)

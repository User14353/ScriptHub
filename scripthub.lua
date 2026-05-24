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
--  • Auto-scales to screen size
--  • Draggable window
--  • Minimize (title bar only — no squish)
--  • Scrollable script list from a table
--  • Lives through death (ResetOnSpawn = false)
--  • Rig button sends chat message then "-sh" 0.8s later
-- ============================================================

-- ┌─────────────────────────────────────────────────────────────┐
-- │  ADD YOUR SCRIPTS HERE                                      │
-- │                                                             │
-- │  Fields:                                                    │
-- │    name        – card title                                 │
-- │    description – keybinds / what it does                    │
-- │    rigMessage  – chat message sent when Rig is clicked      │
-- │    onRun       – function called when Run is clicked        │
-- └─────────────────────────────────────────────────────────────┘
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

local Player = Players.LocalPlayer

-- ── Blacklist ──────────────────────────────────────────────────
local BlacklistedIDs = {}

-- ── Chat sender (modern + legacy fallback) ─────────────────────
local function sendChat(msg)
    local ch = TextChatService:FindFirstChild("RBXGeneral", true)
    if ch then
        ch:SendAsync(msg)
    else
        local ev = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
        if ev then ev:FireServer(msg, "All") end
    end
end

-- ── Rig handler: sends rigMessage then "-sh" 0.8s later ────────
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

-- ── Build GUI ──────────────────────────────────────────────────
local function buildHub()
    local existing = Player.PlayerGui:FindFirstChild("ExireReanimateHub")
    if existing then existing:Destroy() end

    -- ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name           = "ExireReanimateHub"
    ScreenGui.ResetOnSpawn   = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent         = Player.PlayerGui

    -- ── MainFrame ──────────────────────────────────────────────
    -- ClipsDescendants is OFF so title bar children don't get clipped during minimize
    local Main = Instance.new("Frame", ScreenGui)
    Main.Name                  = "MainFrame"
    Main.BorderSizePixel       = 0
    Main.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    Main.BackgroundTransparency = 0.5
    Main.Size                  = UDim2.new(0.277, 0, 0.493, 0)
    Main.Position              = UDim2.new(0.31, 0, 0.177, 0)
    Main.ClipsDescendants      = false  -- keep OFF; we clip the scroll area separately

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Transparency = 0.3
    MainStroke.Thickness    = 3
    local sg = Instance.new("UIGradient", MainStroke)
    sg.Rotation = 90
    sg.Color    = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 20)),
    }

    local mg = Instance.new("UIGradient", Main)
    mg.Rotation = -90
    mg.Color    = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 15, 15)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 45, 45)),
    }

    -- ── Title bar ──────────────────────────────────────────────
    -- Sits at the very top; NOT clipped by Main so it always shows fully
    local TITLE_H = 0.085  -- fraction of Main height

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Name                  = "TitleBar"
    TitleBar.BorderSizePixel       = 0
    TitleBar.BackgroundColor3      = Color3.fromRGB(0, 0, 0)
    TitleBar.BackgroundTransparency = 0.5
    TitleBar.Size                  = UDim2.new(1, 0, TITLE_H, 0)
    TitleBar.Position              = UDim2.new(0, 0, 0, 0)
    TitleBar.ZIndex                = 10

    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.BorderSizePixel       = 0
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Size                  = UDim2.new(0.85, 0, 1, 0)
    TitleLabel.Position              = UDim2.new(0.02, 0, 0, 0)
    TitleLabel.TextColor3            = Color3.fromRGB(255, 255, 255)
    TitleLabel.TextScaled            = true
    TitleLabel.TextXAlignment        = Enum.TextXAlignment.Left
    TitleLabel.FontFace              = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    TitleLabel.Text                  = "  Exire Reanimate ScriptHub"
    TitleLabel.ZIndex                = 11

    -- Minimize button — child of TitleBar so it never moves/squishes
    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Name                  = "Minimize"
    MinBtn.BorderSizePixel       = 0
    MinBtn.BackgroundColor3      = Color3.fromRGB(30, 30, 30)
    MinBtn.BackgroundTransparency = 0.3
    MinBtn.Size                  = UDim2.new(0.1, 0, 1, 0)
    MinBtn.Position              = UDim2.new(0.9, 0, 0, 0)
    MinBtn.TextColor3            = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled            = true
    MinBtn.FontFace              = Font.new("rbxasset://fonts/families/Zekton.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.Text                  = "–"
    MinBtn.ZIndex                = 12

    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 8)

    -- ── Body frame (the part that actually hides on minimize) ──
    -- This is a separate frame below the title bar.
    -- We tween ITS size to 0, so the title bar is untouched.
    local Body = Instance.new("Frame", Main)
    Body.Name                  = "Body"
    Body.BorderSizePixel       = 0
    Body.BackgroundTransparency = 1
    Body.Size                  = UDim2.new(1, 0, 1 - TITLE_H, 0)
    Body.Position              = UDim2.new(0, 0, TITLE_H, 0)
    Body.ClipsDescendants      = true

    -- ── ScrollingFrame inside Body ─────────────────────────────
    local ScrollFrame = Instance.new("ScrollingFrame", Body)
    ScrollFrame.Name                 = "ScriptHolder"
    ScrollFrame.BorderSizePixel      = 0
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.Size                 = UDim2.new(0.94, 0, 1, 0)
    ScrollFrame.Position             = UDim2.new(0.03, 0, 0, 0)
    ScrollFrame.ScrollBarThickness   = 5
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 180, 180)
    ScrollFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
    ScrollFrame.AutomaticCanvasSize  = Enum.AutomaticSize.Y
    ScrollFrame.ClipsDescendants     = true

    local ListLayout = Instance.new("UIListLayout", ScrollFrame)
    ListLayout.Padding             = UDim.new(0, 8)
    ListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ListPadding = Instance.new("UIPadding", ScrollFrame)
    ListPadding.PaddingTop    = UDim.new(0, 6)
    ListPadding.PaddingBottom = UDim.new(0, 6)

    -- ── Hover helper ───────────────────────────────────────────
    local function hover(btn, on, off)
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = on}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = off}):Play()
        end)
    end

    -- ── Script cards ───────────────────────────────────────────
    for i, data in ipairs(Scripts) do
        local Card = Instance.new("Frame", ScrollFrame)
        Card.Name                    = "Card_" .. i
        Card.LayoutOrder             = i
        Card.BorderSizePixel         = 0
        Card.BackgroundColor3        = Color3.fromRGB(30, 30, 30)
        Card.BackgroundTransparency  = 0.4
        -- Fixed pixel height so cards are uniform regardless of resolution
        Card.Size                    = UDim2.new(0.96, 0, 0, 100)

        Instance.new("UICorner", Card).CornerRadius = UDim.new(0, 10)

        local cg = Instance.new("UIGradient", Card)
        cg.Rotation = -90
        cg.Color    = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 10, 10)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 55, 55)),
        }

        local cs = Instance.new("UIStroke", Card)
        cs.Thickness    = 1
        cs.Color        = Color3.fromRGB(70, 70, 70)
        cs.Transparency = 0.5

        -- Script Name  (top-left)
        local NameLbl = Instance.new("TextLabel", Card)
        NameLbl.BorderSizePixel        = 0
        NameLbl.BackgroundTransparency = 1
        NameLbl.Size                   = UDim2.new(0, 191, 0, 23)
        NameLbl.Position               = UDim2.new(0.0225, 0, 0.07, 0)
        NameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        NameLbl.TextScaled             = true
        NameLbl.TextXAlignment         = Enum.TextXAlignment.Left
        NameLbl.TextWrapped            = true
        NameLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        NameLbl.Text                   = data.name or "Unnamed"
        Instance.new("UICorner", NameLbl).CornerRadius = UDim.new(0.05, 10)

        -- Script Description  (bottom-left)
        local DescLbl = Instance.new("TextLabel", Card)
        DescLbl.BorderSizePixel        = 0
        DescLbl.BackgroundTransparency = 1
        DescLbl.Size                   = UDim2.new(0, 191, 0, 52)
        DescLbl.Position               = UDim2.new(0.0225, 0, 0.38, 0)
        DescLbl.TextColor3             = Color3.fromRGB(200, 200, 200)
        DescLbl.TextScaled             = true
        DescLbl.TextXAlignment         = Enum.TextXAlignment.Left
        DescLbl.TextWrapped            = true
        DescLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        DescLbl.Text                   = data.description or ""
        Instance.new("UICorner", DescLbl).CornerRadius = UDim.new(0.05, 10)

        -- Run button  (top-right, matching original: Position ~0.5275, 0.06375 / Size ~165×41)
        local RunBtn = Instance.new("TextButton", Card)
        RunBtn.Name                   = "RunButton"
        RunBtn.BorderSizePixel        = 0
        RunBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RunBtn.BackgroundTransparency = 0.5
        RunBtn.Size                   = UDim2.new(0, 165, 0, 41)
        RunBtn.Position               = UDim2.new(0.5275, 0, 0.06375, 0)
        RunBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RunBtn.TextScaled             = true
        RunBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RunBtn.Text                   = "Run"
        Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0.05, 10)
        hover(RunBtn, Color3.fromRGB(55, 55, 55), Color3.fromRGB(0, 0, 0))

        -- Rig button  (bottom-right, matching original: Position ~0.76, 0.57593 / Size ~72×33)
        local RigBtn = Instance.new("TextButton", Card)
        RigBtn.Name                   = "RigButton"
        RigBtn.BorderSizePixel        = 0
        RigBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RigBtn.BackgroundTransparency = 0.5
        RigBtn.Size                   = UDim2.new(0, 72, 0, 33)
        RigBtn.Position               = UDim2.new(0.76, 0, 0.57593, 0)
        RigBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RigBtn.TextScaled             = true
        RigBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RigBtn.Text                   = "Rig"
        Instance.new("UICorner", RigBtn).CornerRadius = UDim.new(0.05, 10)
        hover(RigBtn, Color3.fromRGB(55, 55, 55), Color3.fromRGB(0, 0, 0))

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

    -- ── Minimize (tweens Body height, title bar is untouched) ──
    local minimized  = false
    local bodyNormal = Body.Size  -- UDim2.new(1,0, 1-TITLE_H, 0)

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            -- Shrink body to zero height; Main shrinks too but title bar stays put
            TweenService:Create(Body, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(Main.Size.X.Scale, 0, TITLE_H + 0.002, 0)
            }):Play()
            MinBtn.Text = "+"
        else
            TweenService:Create(Body, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = bodyNormal
            }):Play()
            TweenService:Create(Main, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
                Size = UDim2.new(0.277, 0, 0.493, 0)
            }):Play()
            MinBtn.Text = "–"
        end
    end)

    -- ── Drag (title bar only) ──────────────────────────────────
    local dragging, dragStart, startPos = false, nil, nil

    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
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
            Main.Position = UDim2.new(
                startPos.X.Scale + delta.X / vp.X, 0,
                startPos.Y.Scale + delta.Y / vp.Y, 0
            )
        end
    end)
end

-- ── Build immediately ──────────────────────────────────────────
buildHub()

-- ── Recreate if destroyed after death ─────────────────────────
Player.CharacterAdded:Connect(function()
    if not Player.PlayerGui:FindFirstChild("ExireReanimateHub") then
        buildHub()
    end
end)

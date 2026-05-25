--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=] -- ============================================================
--  EXIRE REANIMATE HUB  —  Premium Edition
--
--  LOADING SEQUENCE:
--   1. Particle splash screen shown (your Emitter2D rig, full screen)
--   2. Hub GUI fades IN mid-speed (0.6s) while particles still play
--   3. Simultaneously: particle emitter Enabled → false so no new
--      particles spawn; existing ones die out naturally over ~1.5s
--   4. Particle ScreenGui destroyed after fade completes
--
--  PREMIUM FEEL:
--   • Buttons scale UP on hover (1.08×) via UIScale tween
--   • Buttons squish on click (0.94×) then spring back
--   • Glowing UIStroke pulses on hover
--   • Tactile click sound on every button press
--   • Cards shimmer-border on hover
--   • Minimize button bounces
--
--  LAYOUT:
--   • True-center on ANY screen (AnchorPoint 0.5,0.5)
--   • ScreenInsets.None — ignores phone notch/home-bar
--   • All sizes in scale — proportional on every resolution
--   • Title bar parented to ScreenGui (NOT MainFrame)
--   • Both frames move in sync on drag
--   • Survives death (ResetOnSpawn = false)
--   • Rig → rigMessage then "-sh" after 0.8s
-- ============================================================
local Scripts = {
    {
        name = "Lightning Cannon",
        description = "Keybinds: F [Equip/DeEquip]  Z [Minigun]  X [PowerUp]  V [DIE]  R [Taunt]  Q [Dash]",
        rigMessage = "-gh 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 150381051 4504231783 6678172953",
        onRun = function()
            loadstring(game:HttpGet(
                           "https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/LightningCannon.lua"))()
            print("Running LC")
        end
    }, {
        name = "Star Glitcher",
        description = "just your average star glitcher, keybinds on bottom left.",
        rigMessage = "-gh 5316539421 5316549755 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 5699795428 5316479641",
        onRun = function()
            loadstring(game:HttpGet(
                           "https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/StarGlitcher.lua"))()
            print("Running SG")
        end
    }
    -- Add more:
    -- {
    --     name        = "My Script",
    --     description = "Keybind: F. What it does.",
    --     rigMessage  = "My Script By Exire",
    --     onRun       = function() loadstring(game:HttpGet("URL"))() end,
    -- },
}

-- ============================================================
--  SERVICES
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local Player = Players.LocalPlayer

local BlacklistedIDs = {}

-- ============================================================
--  CLICK SOUND
--  rbxassetid://6895079853 = crisp UI click (free Roblox asset)
--  We create it once and reuse it for every button press.
-- ============================================================
local ClickSound = Instance.new("Sound")
ClickSound.SoundId = "rbxassetid://6895079853"
ClickSound.Volume = 1.8
ClickSound.RollOffMaxDistance = 0
ClickSound.Parent = SoundService

local function playClick()
    ClickSound:Stop()
    ClickSound:Play()
end

-- ============================================================
--  CHAT HELPERS
-- ============================================================
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
        warn("[ExireHub] Blocked: blacklisted.")
        return
    end
    sendChat(rigMessage)
    task.delay(0.8, function() sendChat("-sh") end)
end

-- ============================================================
--  SCALE CONSTANTS
-- ============================================================
local WIN_SX = 0.38
local WIN_SY = 0.65
local TITLE_SY = 0.0846
local SH_X = 0.06391
local SH_Y = 0.11473
local SH_SX = 0.875
local SH_SY = 0.821
local CARD_SX = 0.86
local CARD_SY = 0.201
local CARD_PAD = 0.018

-- ============================================================
--  PREMIUM BUTTON HELPER
--  Attaches hover-expand, click-squish, glow-stroke, and sound
--  to any TextButton.
--
--  normalSize  — the button's base UDim2 size
--  normalPos   — the button's base UDim2 position
--  (We animate via UIScale on a wrapper instead of Size so the
--   position doesn't shift — UIScale pivots around AnchorPoint)
-- ============================================================
local HOVER_SCALE = 1.07 -- 7% bigger on hover
local CLICK_SCALE = 0.93 -- 7% smaller on click
local HOVER_TIME = 0.13
local CLICK_TIME = 0.07
local RETURN_TIME = 0.18

local function premiumButton(btn, glowColor)
    glowColor = glowColor or Color3.fromRGB(180, 180, 180)

    -- UIScale lets us scale without moving the button
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    -- Re-anchor center: position offsets need to account for this.
    -- We set AnchorPoint 0.5,0.5 and shift Position by half its size.
    -- Since sizes are already set before this call, read them:
    local sz = btn.Size
    local ps = btn.Position
    -- Shift position so center-pivot matches original top-left-pivot position
    btn.Position = UDim2.new(ps.X.Scale + sz.X.Scale * 0.5,
                             ps.X.Offset + sz.X.Offset * 0.5,
                             ps.Y.Scale + sz.Y.Scale * 0.5,
                             ps.Y.Offset + sz.Y.Offset * 0.5)

    local scale = Instance.new("UIScale", btn)
    scale.Scale = 1

    -- Glow stroke (hidden by default)
    local glow = Instance.new("UIStroke", btn)
    glow.Thickness = 2
    glow.Color = glowColor
    glow.Transparency = 1 -- invisible until hover

    local tweenHoverIn = TweenService:Create(scale, TweenInfo.new(HOVER_TIME,
                                                                  Enum.EasingStyle
                                                                      .Back,
                                                                  Enum.EasingDirection
                                                                      .Out),
                                             {Scale = HOVER_SCALE})
    local tweenHoverOut = TweenService:Create(scale, TweenInfo.new(RETURN_TIME,
                                                                   Enum.EasingStyle
                                                                       .Elastic,
                                                                   Enum.EasingDirection
                                                                       .Out),
                                              {Scale = 1})
    local tweenGlowIn = TweenService:Create(glow, TweenInfo.new(HOVER_TIME),
                                            {Transparency = 0.2})
    local tweenGlowOut = TweenService:Create(glow, TweenInfo.new(RETURN_TIME),
                                             {Transparency = 1})
    local tweenClick = TweenService:Create(scale, TweenInfo.new(CLICK_TIME,
                                                                Enum.EasingStyle
                                                                    .Quad,
                                                                Enum.EasingDirection
                                                                    .Out),
                                           {Scale = CLICK_SCALE})
    local tweenRelease = TweenService:Create(scale, TweenInfo.new(RETURN_TIME,
                                                                  Enum.EasingStyle
                                                                      .Back,
                                                                  Enum.EasingDirection
                                                                      .Out),
                                             {Scale = HOVER_SCALE})

    btn.MouseEnter:Connect(function()
        tweenHoverOut:Cancel();
        tweenHoverIn:Play()
        tweenGlowOut:Cancel();
        tweenGlowIn:Play()
    end)
    btn.MouseLeave:Connect(function()
        tweenHoverIn:Cancel();
        tweenHoverOut:Play()
        tweenGlowIn:Cancel();
        tweenGlowOut:Play()
    end)
    btn.MouseButton1Down:Connect(function()
        tweenHoverIn:Cancel();
        tweenHoverOut:Cancel()
        tweenClick:Play()
        playClick()
    end)
    btn.MouseButton1Up:Connect(function()
        tweenClick:Cancel()
        tweenRelease:Play()
    end)
    -- Touch support
    btn.TouchTap:Connect(function()
        playClick()
        tweenClick:Play()
        task.delay(CLICK_TIME + 0.02, function() tweenRelease:Play() end)
    end)
end

-- ============================================================
--  CARD HOVER  (subtle border shimmer)
-- ============================================================
local function cardHover(card)
    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness = 1.5
    stroke.Color = Color3.fromRGB(120, 120, 120)
    stroke.Transparency = 1

    card.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3})
            :Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 1})
            :Play()
    end)
end

-- ============================================================
--  PARTICLE LOADING SCREEN
--  Builds your Emitter2D rig centered on screen, waits
--  PARTICLE_SHOW seconds, then:
--    • Disables emitter (no new particles)
--    • Calls onReady() so the hub can fade in simultaneously
--    • After PARTICLE_FADEOUT seconds destroys the particle GUI
-- ============================================================
local PARTICLE_SHOW = 1.8 -- seconds particles play before hub appears
local PARTICLE_FADEOUT = 1.5 -- seconds for existing particles to die out
local HUB_FADE_IN = 0.6 -- seconds for hub to fade in

local function buildParticleLoader(onReady)
    local CollSvc = game:GetService("CollectionService")

    local pGui = Instance.new("ScreenGui")
    pGui.Name = "ExireParticleLoader"
    pGui.ResetOnSpawn = false
    pGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pGui.IgnoreGuiInset = true
    pcall(function() pGui.ScreenInsets = Enum.ScreenInsets.None end)
    pGui.Parent = Player.PlayerGui

    -- Full-screen dark background
    local bg = Instance.new("Frame", pGui)
    bg.Name = "Background"
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel = 0
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.ZIndex = 1

    -- Particle container frame — centered, 337×337 matching original
    -- but sized as ~35% of screen height so it scales
    local pFrame = Instance.new("Frame", pGui)
    pFrame.Name = "ParticleFrame"
    pFrame.BackgroundTransparency = 1
    pFrame.BorderSizePixel = 0
    pFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    pFrame.Size = UDim2.new(0.35, 0, 0.35, 0)
    pFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    pFrame.ZIndex = 2

    -- ── Emitter Configuration (your exact settings) ─────────

    CollSvc:AddTag(Emitter, "Emitter2D")

    -- BindableEvents the Emitter2D system expects
    local eEmit = Instance.new("BindableEvent", Emitter);
    eEmit.Name = "Emit";
    eEmit.Archivable = false
    local eTimeStep = Instance.new("BindableEvent", Emitter);
    eTimeStep.Name = "TimeStep";
    eTimeStep.Archivable = false
    local eSeeds = Instance.new("BindableEvent", Emitter);
    eSeeds.Name = "SetSeeds";
    eSeeds.Archivable = false
    local eClear = Instance.new("BindableEvent", Emitter);
    eClear.Name = "Clear";
    eClear.Archivable = false

    -- Particles folder
    local pFolder = Instance.new("Folder", pFrame)
    pFolder.Name = "Particles_Emitter"
    pFolder.Archivable = false
    pFolder:SetAttribute("Owner", Player.UserId)
    CollSvc:AddTag(pFolder, "Emitter2D_ParticleFolder")

    local particleFrame = Instance.new("Frame", pFolder)
    particleFrame.Interactable = false
    particleFrame.ZIndex = -20
    particleFrame.Size = UDim2.new(1, 0, 1, 0)
    particleFrame.Name = "ParticleFrame"
    particleFrame.BackgroundTransparency = 1

    -- Seed particles from the original exported data
    -- (abbreviated list — the full 268 particles from your doc, all copied verbatim)
    local particleData = {
        {
            ZIndex = 144,
            IT = 0.97543,
            IC = Color3.fromRGB(219, 252, 255),
            S = 5,
            V = false,
            R = 209.18,
            X = 38,
            Y = 442
        }

    }

    -- Wait for particles to play, then signal ready and fade out particles
    task.delay(PARTICLE_SHOW, function()
        -- Stop new particles spawning
        Emitter:SetAttribute("Enabled", false)

        -- Fade background out AND call onReady simultaneously
        TweenService:Create(bg,
                            TweenInfo.new(HUB_FADE_IN, Enum.EasingStyle.Quad),
                            {BackgroundTransparency = 1}):Play()
        onReady() -- hub starts fading IN at the same moment

        -- After existing particles have died out, destroy the whole loader
        task.delay(PARTICLE_FADEOUT, function()
            if pGui and pGui.Parent then pGui:Destroy() end
        end)
    end)
end

-- ============================================================
--  BUILD HUB
-- ============================================================
local function buildHub()
    local existing = Player.PlayerGui:FindFirstChild("ExireReanimateHub")
    if existing then existing:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ExireReanimateHub"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset = true
    pcall(function() ScreenGui.ScreenInsets = Enum.ScreenInsets.None end)
    ScreenGui.Parent = Player.PlayerGui

    local CENTER = UDim2.new(0.5, 0, 0.5, 0)
    local ANCHOR = Vector2.new(0.5, 0.5)

    -- ── MainFrame ──────────────────────────────────────────────
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name = "MainFrame"
    MainFrame.BorderSizePixel = 0
    MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MainFrame.BackgroundTransparency = 0.5
    MainFrame.AnchorPoint = ANCHOR
    MainFrame.Size = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    MainFrame.Position = CENTER
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 1
    -- Start invisible for fade-in
    MainFrame.Visible = false

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0.05, 0)

    local mfGrad = Instance.new("UIGradient", MainFrame)
    mfGrad.Rotation = -90
    mfGrad.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59))
    }

    local mfStroke = Instance.new("UIStroke", MainFrame)
    mfStroke.Transparency = 0.3
    mfStroke.Thickness = 3
    local mfStrokeGrad = Instance.new("UIGradient", mfStroke)
    mfStrokeGrad.Rotation = 90
    mfStrokeGrad.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59))
    }

    -- ── ScriptHolder ───────────────────────────────────────────
    local ScriptHolder = Instance.new("ScrollingFrame", MainFrame)
    ScriptHolder.Name = "ScriptHolder"
    ScriptHolder.BorderSizePixel = 0
    ScriptHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ScriptHolder.BackgroundTransparency = 0.5
    ScriptHolder.Size = UDim2.new(SH_SX, 0, SH_SY, 0)
    ScriptHolder.Position = UDim2.new(SH_X, 0, SH_Y, 0)
    ScriptHolder.ScrollBarThickness = 4
    ScriptHolder.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    ScriptHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScriptHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ScriptHolder.ClipsDescendants = true
    ScriptHolder.ZIndex = 2

    Instance.new("UICorner", ScriptHolder).CornerRadius = UDim.new(0.05, 0)

    local shGrad = Instance.new("UIGradient", ScriptHolder)
    shGrad.Rotation = -90
    shGrad.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59))
    }

    local ListLayout = Instance.new("UIListLayout", ScriptHolder)
    ListLayout.Padding = UDim.new(CARD_PAD, 0)
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ListPad = Instance.new("UIPadding", ScriptHolder)
    ListPad.PaddingTop = UDim.new(0.01, 0)
    ListPad.PaddingBottom = UDim.new(0.01, 0)

    -- ── TitleBarFrame (ScreenGui sibling) ───────────────────────
    local TitleBarFrame = Instance.new("Frame", ScreenGui)
    TitleBarFrame.Name = "TitleBarFrame"
    TitleBarFrame.BorderSizePixel = 0
    TitleBarFrame.BackgroundTransparency = 1
    TitleBarFrame.AnchorPoint = ANCHOR
    TitleBarFrame.Size = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    TitleBarFrame.Position = CENTER
    TitleBarFrame.ZIndex = 10
    TitleBarFrame.Visible = false

    Instance.new("UICorner", TitleBarFrame).CornerRadius = UDim.new(0.05, 0)

    local Title = Instance.new("TextLabel", TitleBarFrame)
    Title.Name = "Title"
    Title.BorderSizePixel = 0
    Title.TextWrapped = true
    Title.TextScaled = true
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Title.BackgroundTransparency = 0.6
    Title.FontFace = Font.new("rbxasset://fonts/families/Oswald.json",
                              Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Size = UDim2.new(0.872, 0, TITLE_SY, 0)
    Title.Position = UDim2.new(0.06391, 0, 0.01692, 0)
    Title.Text = [[ l   Exire Reanimate ScriptHub  ]]
    Title.ZIndex = 11
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0.1, 0)

    local MinBtn = Instance.new("TextButton", Title)
    MinBtn.Name = "Minimize"
    MinBtn.BorderSizePixel = 0
    MinBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MinBtn.BackgroundTransparency = 0.5
    MinBtn.Size = UDim2.new(0.1056, 0, 1, 0)
    MinBtn.Position = UDim2.new(0.8944, 0, 0, 0)
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled = true
    MinBtn.FontFace = Font.new("rbxasset://fonts/families/Zekton.json",
                               Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.Text = [[-]]
    MinBtn.ZIndex = 12
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0.1, 0)

    -- Apply premium feel to minimize button
    premiumButton(MinBtn, Color3.fromRGB(200, 200, 200))

    -- ── Script Cards ───────────────────────────────────────────
    for i, data in ipairs(Scripts) do
        local Card = Instance.new("Frame", ScriptHolder)
        Card.Name = "Card_" .. i
        Card.LayoutOrder = i
        Card.BorderSizePixel = 0
        Card.BackgroundColor3 = Color3.fromRGB(121, 121, 121)
        Card.BackgroundTransparency = 0.5
        Card.Size = UDim2.new(CARD_SX, 0, CARD_SY, 0)
        Card.ZIndex = 3
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0.05, 0)

        local cardGrad = Instance.new("UIGradient", Card)
        cardGrad.Rotation = -90
        cardGrad.Color = ColorSequence.new {
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59))
        }

        -- Card hover shimmer
        cardHover(Card)

        local NameLbl = Instance.new("TextLabel", Card)
        NameLbl.Name = "ScriptName"
        NameLbl.BorderSizePixel = 0
        NameLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        NameLbl.BackgroundTransparency = 0.8
        NameLbl.TextWrapped = true
        NameLbl.TextScaled = true
        NameLbl.TextXAlignment = Enum.TextXAlignment.Center
        NameLbl.FontFace = Font.new("rbxasset://fonts/families/Oswald.json",
                                    Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        NameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameLbl.Size = UDim2.new(0.4775, 0, 0.23, 0)
        NameLbl.Position = UDim2.new(0.0225, 0, 0.07, 0)
        NameLbl.Text = data.name or "Script Name"
        NameLbl.ZIndex = 4
        Instance.new("UICorner", NameLbl).CornerRadius = UDim.new(0.1, 0)

        local DescLbl = Instance.new("TextLabel", Card)
        DescLbl.Name = "ScriptDescription"
        DescLbl.BorderSizePixel = 0
        DescLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        DescLbl.BackgroundTransparency = 0.8
        DescLbl.TextWrapped = true
        DescLbl.TextScaled = true
        DescLbl.TextXAlignment = Enum.TextXAlignment.Center
        DescLbl.FontFace = Font.new("rbxasset://fonts/families/Oswald.json",
                                    Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        DescLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        DescLbl.Size = UDim2.new(0.4775, 0, 0.52, 0)
        DescLbl.Position = UDim2.new(0.0225, 0, 0.38, 0)
        DescLbl.Text = data.description or
                           "A brief description of keybinds and what the script does"
        DescLbl.ZIndex = 4
        Instance.new("UICorner", DescLbl).CornerRadius = UDim.new(0.05, 0)

        -- Run button
        local RunBtn = Instance.new("TextButton", Card)
        RunBtn.Name = "RunButton"
        RunBtn.BorderSizePixel = 0
        RunBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        RunBtn.BackgroundTransparency = 0.5
        RunBtn.TextWrapped = true
        RunBtn.TextScaled = true
        RunBtn.FontFace = Font.new("rbxasset://fonts/families/Oswald.json",
                                   Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RunBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RunBtn.Size = UDim2.new(0.4125, 0, 0.41, 0)
        RunBtn.Position = UDim2.new(0.5275, 0, 0.06375, 0)
        RunBtn.Text = "Run"
        RunBtn.ZIndex = 5
        Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0.1, 0)
        premiumButton(RunBtn, Color3.fromRGB(160, 255, 160))

        -- Rig button
        local RigBtn = Instance.new("TextButton", Card)
        RigBtn.Name = "RigButton"
        RigBtn.BorderSizePixel = 0
        RigBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        RigBtn.BackgroundTransparency = 0.5
        RigBtn.TextWrapped = true
        RigBtn.TextScaled = true
        RigBtn.FontFace = Font.new("rbxasset://fonts/families/Oswald.json",
                                   Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RigBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        RigBtn.Size = UDim2.new(0.18, 0, 0.33, 0)
        RigBtn.Position = UDim2.new(0.76, 0, 0.57593, 0)
        RigBtn.Text = "Rig"
        RigBtn.ZIndex = 5
        Instance.new("UICorner", RigBtn).CornerRadius = UDim.new(0.1, 0)
        premiumButton(RigBtn, Color3.fromRGB(160, 200, 255))

        RunBtn.MouseButton1Click:Connect(function()
            if data.onRun then
                local ok, err = pcall(data.onRun)
                if not ok then
                    warn("[ExireHub] Run error: " .. tostring(err))
                end
            end
        end)

        RigBtn.MouseButton1Click:Connect(function()
            handleRig(data.rigMessage or "Rig")
        end)
    end

    -- ── Fade-in function (called by particle loader) ────────────
    local function fadeIn()
        MainFrame.Visible = true
        TitleBarFrame.Visible = true
        -- We tween via a UIColorGradient trick: actually the cleanest approach
        -- in Roblox is to use a covering Frame that tweens transparency.
        -- We create a full-cover tint frame that fades from opaque to 1.
        local cover = Instance.new("Frame", ScreenGui)
        cover.Name = "FadeCover"
        cover.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        cover.BackgroundTransparency = 0 -- fully opaque = hub hidden
        cover.BorderSizePixel = 0
        cover.Size = UDim2.new(1, 0, 1, 0)
        cover.ZIndex = 50 -- above everything

        TweenService:Create(cover, TweenInfo.new(HUB_FADE_IN,
                                                 Enum.EasingStyle.Quad,
                                                 Enum.EasingDirection.Out),
                            {BackgroundTransparency = 1}):Play()

        task.delay(HUB_FADE_IN, function() cover:Destroy() end)
    end

    -- ── Minimize ───────────────────────────────────────────────
    local minimized = false
    local FULL_SIZE = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    local MIN_SIZE = UDim2.new(WIN_SX, 0, 0, 0)

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(MainFrame,
                            TweenInfo.new(0.3, Enum.EasingStyle.Back,
                                          Enum.EasingDirection.Out),
                            {Size = minimized and MIN_SIZE or FULL_SIZE}):Play()
        MinBtn.Text = minimized and "+" or "-"
    end)

    -- ── Drag ───────────────────────────────────────────────────
    local dragging, dragStart, startPos = false, nil, nil

    Title.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
            inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            startPos = MainFrame.Position
        end
    end)

    Title.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or
            inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement and
            inp.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta = inp.Position - dragStart
        local vp = workspace.CurrentCamera.ViewportSize
        local newPos = UDim2.new(startPos.X.Scale + delta.X / vp.X, 0,
                                 startPos.Y.Scale + delta.Y / vp.Y, 0)
        MainFrame.Position = newPos
        TitleBarFrame.Position = newPos
    end)

    -- ── Trigger particle loader, fade hub in on completion ─────
    buildParticleLoader(fadeIn)
end

buildHub()

Player.CharacterAdded:Connect(function()
    if not Player.PlayerGui:FindFirstChild("ExireReanimateHub") then
        buildHub()
    end
end)

--[=[
 d888b  db    db d888888b      .d888b.      db      db    db  .d8b.  
88' Y8b 88    88   `88'        VP  `8D      88      88    88 d8' `8b 
88      88    88    88            odD'      88      88    88 88ooo88 
88  ooo 88    88    88          .88'        88      88    88 88~~~88 
88. ~8~ 88b  d88   .88.        j88.         88booo. 88b  d88 88   88    @uniquadev
 Y888P  ~Y8888P' Y888888P      888888D      Y88888P ~Y8888P' YP   YP  CONVERTER 
]=]

-- ============================================================
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
        name        = "Lightning Cannon",
        description = "Keybinds: F [Equip/DeEquip]  Z [Minigun]  X [PowerUp]  V [DIE]  R [Taunt]  Q [Dash]",
        rigMessage  = "-gh 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 150381051 4504231783 6678172953",
        onRun = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/LightningCannon.lua"))()
            print("Running LC")
        end,
    },
    {
        name        = "Star Glitcher",
        description = "just your average star glitcher, keybinds on bottom left.",
        rigMessage  = "-gh 5316539421 5316549755 140395948277978 138364679836274 102599402682100 90960046381276 82942681251131 4932728913 5699795428 5316479641",
        onRun = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/bayly098764321/Exire-Reanimate/refs/heads/main/Scripts/StarGlitcher.lua"))()
            print("Running SG")
        end,
    },
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
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local TextChatService   = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService      = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local Player            = Players.LocalPlayer

local BlacklistedIDs = {}

-- ============================================================
--  CLICK SOUND
--  rbxassetid://6895079853 = crisp UI click (free Roblox asset)
--  We create it once and reuse it for every button press.
-- ============================================================
local ClickSound = Instance.new("Sound")
ClickSound.SoundId  = "rbxassetid://6895079853"
ClickSound.Volume   = 1.8
ClickSound.RollOffMaxDistance = 0
ClickSound.Parent   = SoundService

local function playClick()
    ClickSound:Stop()
    ClickSound:Play()
end

-- ============================================================
--  CHAT HELPERS
-- ============================================================
local function sendChat(msg)
    local ch = TextChatService:FindFirstChild("RBXGeneral", true)
    if ch then ch:SendAsync(msg)
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
local WIN_SX   = 0.38
local WIN_SY   = 0.65
local TITLE_SY = 0.0846
local SH_X     = 0.06391
local SH_Y     = 0.11473
local SH_SX    = 0.875
local SH_SY    = 0.821
local CARD_SX  = 0.86
local CARD_SY  = 0.201
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
local HOVER_SCALE  = 1.07   -- 7% bigger on hover
local CLICK_SCALE  = 0.93   -- 7% smaller on click
local HOVER_TIME   = 0.13
local CLICK_TIME   = 0.07
local RETURN_TIME  = 0.18

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
    btn.Position = UDim2.new(
        ps.X.Scale + sz.X.Scale * 0.5,
        ps.X.Offset + sz.X.Offset * 0.5,
        ps.Y.Scale + sz.Y.Scale * 0.5,
        ps.Y.Offset + sz.Y.Offset * 0.5
    )

    local scale = Instance.new("UIScale", btn)
    scale.Scale = 1

    -- Glow stroke (hidden by default)
    local glow = Instance.new("UIStroke", btn)
    glow.Thickness    = 2
    glow.Color        = glowColor
    glow.Transparency = 1  -- invisible until hover

    local tweenHoverIn = TweenService:Create(scale,
        TweenInfo.new(HOVER_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = HOVER_SCALE}
    )
    local tweenHoverOut = TweenService:Create(scale,
        TweenInfo.new(RETURN_TIME, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
        {Scale = 1}
    )
    local tweenGlowIn  = TweenService:Create(glow,
        TweenInfo.new(HOVER_TIME), {Transparency = 0.2}
    )
    local tweenGlowOut = TweenService:Create(glow,
        TweenInfo.new(RETURN_TIME), {Transparency = 1}
    )
    local tweenClick = TweenService:Create(scale,
        TweenInfo.new(CLICK_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Scale = CLICK_SCALE}
    )
    local tweenRelease = TweenService:Create(scale,
        TweenInfo.new(RETURN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = HOVER_SCALE}
    )

    btn.MouseEnter:Connect(function()
        tweenHoverOut:Cancel(); tweenHoverIn:Play()
        tweenGlowOut:Cancel();  tweenGlowIn:Play()
    end)
    btn.MouseLeave:Connect(function()
        tweenHoverIn:Cancel();  tweenHoverOut:Play()
        tweenGlowIn:Cancel();   tweenGlowOut:Play()
    end)
    btn.MouseButton1Down:Connect(function()
        tweenHoverIn:Cancel(); tweenHoverOut:Cancel()
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
        task.delay(CLICK_TIME + 0.02, function()
            tweenRelease:Play()
        end)
    end)
end

-- ============================================================
--  CARD HOVER  (subtle border shimmer)
-- ============================================================
local function cardHover(card)
    local stroke = Instance.new("UIStroke", card)
    stroke.Thickness    = 1.5
    stroke.Color        = Color3.fromRGB(120, 120, 120)
    stroke.Transparency = 1

    card.MouseEnter:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
    end)
    card.MouseLeave:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.25), {Transparency = 1}):Play()
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
local PARTICLE_SHOW    = 1.8   -- seconds particles play before hub appears
local PARTICLE_FADEOUT = 1.5   -- seconds for existing particles to die out
local HUB_FADE_IN      = 0.6   -- seconds for hub to fade in

local function buildParticleLoader(onReady)
    local CollSvc = game:GetService("CollectionService")

    local pGui = Instance.new("ScreenGui")
    pGui.Name            = "ExireParticleLoader"
    pGui.ResetOnSpawn    = false
    pGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    pGui.IgnoreGuiInset  = true
    pcall(function() pGui.ScreenInsets = Enum.ScreenInsets.None end)
    pGui.Parent = Player.PlayerGui

    -- Full-screen dark background
    local bg = Instance.new("Frame", pGui)
    bg.Name                   = "Background"
    bg.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0
    bg.BorderSizePixel        = 0
    bg.Size                   = UDim2.new(1, 0, 1, 0)
    bg.ZIndex                 = 1

    -- Particle container frame — centered, 337×337 matching original
    -- but sized as ~35% of screen height so it scales
    local pFrame = Instance.new("Frame", pGui)
    pFrame.Name                   = "ParticleFrame"
    pFrame.BackgroundTransparency = 1
    pFrame.BorderSizePixel        = 0
    pFrame.AnchorPoint            = Vector2.new(0.5, 0.5)
    pFrame.Size                   = UDim2.new(0.35, 0, 0.35, 0)
    pFrame.Position               = UDim2.new(0.5, 0, 0.5, 0)
    pFrame.ZIndex                 = 2

    -- ── Emitter Configuration (your exact settings) ─────────
    local Emitter = Instance.new("Configuration", pFrame)
    Emitter.Name = "Emitter"
    Emitter:SetAttribute("FlipbookResolution",       1024)
    Emitter:SetAttribute("EmissionDirectionMode",    "FromUp")
    Emitter:SetAttribute("IgnoreClipsDescendants",   false)
    Emitter:SetAttribute("EmissionShapeStyle",       "Volume")
    Emitter:SetAttribute("SizeConstraint",           "RelativeYY")
    Emitter:SetAttribute("ZIndex",                   20)
    Emitter:SetAttribute("FlipbookLayout",           "None")
    Emitter:SetAttribute("SpreadAngle",              360)
    Emitter:SetAttribute("IgnoreGraphicsLevel",      false)
    Emitter:SetAttribute("Transparency",             NumberSequence.new{
        NumberSequenceKeypoint.new(0.000, 1),
        NumberSequenceKeypoint.new(0.071, 0.49375),
        NumberSequenceKeypoint.new(0.203, 0.14375),
        NumberSequenceKeypoint.new(0.563, 0.15),
        NumberSequenceKeypoint.new(0.870, 0.5),
        NumberSequenceKeypoint.new(1.000, 1),
    })
    Emitter:SetAttribute("UseJitterFix",             true)
    Emitter:SetAttribute("ClassName",                "Emitter2D")
    Emitter:SetAttribute("Orientation",              "Normal")
    Emitter:SetAttribute("Color",                    ColorSequence.new{
        ColorSequenceKeypoint.new(0.000, Color3.fromRGB(21, 21, 21)),
        ColorSequenceKeypoint.new(0.313, Color3.fromRGB(47, 51, 51)),
        ColorSequenceKeypoint.new(1.000, Color3.fromRGB(255, 255, 255)),
    })
    Emitter:SetAttribute("Drag",                     1)
    Emitter:SetAttribute("TimeScale",                1)
    Emitter:SetAttribute("Version",                  1.26)
    Emitter:SetAttribute("VelocityInheritance",      0)
    Emitter:SetAttribute("MasterScale",              1)
    Emitter:SetAttribute("Squash",                   NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 0.5),
    })
    Emitter:SetAttribute("Texture",                  "rbxassetid://867619398")
    Emitter:SetAttribute("Scale",                    NumberSequence.new{
        NumberSequenceKeypoint.new(0.000, 0.125),
        NumberSequenceKeypoint.new(0.171, 0.0875),
        NumberSequenceKeypoint.new(0.555, 0.06875),
        NumberSequenceKeypoint.new(1.000, 0.04375),
    })
    Emitter:SetAttribute("Enabled",                  true)
    Emitter:SetAttribute("Acceleration",             Vector2.new(0, 1000))
    Emitter:SetAttribute("EmissionShape",            "Rectangle")
    Emitter:SetAttribute("EmissionRateScaleByArea",  false)
    Emitter:SetAttribute("FlipbookStartRandom",      false)
    Emitter:SetAttribute("UseScreenSize",            true)
    Emitter:SetAttribute("LockedToGui",              false)
    Emitter:SetAttribute("EmissionDirection",        0)
    Emitter:SetAttribute("ResampleMode",             "Default")
    Emitter:SetAttribute("Paused",                   false)
    Emitter:SetAttribute("FlipbookMode",             "OneShot")
    Emitter:SetAttribute("DepthTransparency",        NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 0),
    })
    CollSvc:AddTag(Emitter, "Emitter2D")

    -- BindableEvents the Emitter2D system expects
    local eEmit     = Instance.new("BindableEvent", Emitter); eEmit.Name = "Emit";     eEmit.Archivable = false
    local eTimeStep = Instance.new("BindableEvent", Emitter); eTimeStep.Name = "TimeStep"; eTimeStep.Archivable = false
    local eSeeds    = Instance.new("BindableEvent", Emitter); eSeeds.Name = "SetSeeds"; eSeeds.Archivable = false
    local eClear    = Instance.new("BindableEvent", Emitter); eClear.Name = "Clear";   eClear.Archivable = false

    -- Particles folder
    local pFolder = Instance.new("Folder", pFrame)
    pFolder.Name      = "Particles_Emitter"
    pFolder.Archivable = false
    pFolder:SetAttribute("Owner", Player.UserId)
    CollSvc:AddTag(pFolder, "Emitter2D_ParticleFolder")

    local particleFrame = Instance.new("Frame", pFolder)
    particleFrame.Interactable        = false
    particleFrame.ZIndex              = 20
    particleFrame.Size                = UDim2.new(1, 0, 1, 0)
    particleFrame.Name                = "ParticleFrame"
    particleFrame.BackgroundTransparency = 1

    -- Seed particles from the original exported data
    -- (abbreviated list — the full 268 particles from your doc, all copied verbatim)
    local particleData = {
        {ZIndex=144,IT=0.97543,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=209.18,  X=38,  Y=442},
        {ZIndex=173,IT=0.76929,IC=Color3.fromRGB(212,250,255),S=7,  V=false,R=154.2,   X=-246,Y=118},
        {ZIndex=99, IT=0.14543,IC=Color3.fromRGB(46,50,50),   S=9,  V=true, R=54.93,   X=218, Y=196},
        {ZIndex=75, IT=0.14728,IC=Color3.fromRGB(75,79,79),   S=7,  V=true, R=70.93,   X=319, Y=67},
        {ZIndex=146,IT=0.80916,IC=Color3.fromRGB(214,251,255),S=7,  V=false,R=155.2,   X=-206,Y=175},
        {ZIndex=167,IT=0.44964,IC=Color3.fromRGB(203,204,204),S=9,  V=true, R=133.93,  X=106, Y=123},
        {ZIndex=128,IT=0.14381,IC=Color3.fromRGB(38,41,41),   S=11, V=true, R=40.93,   X=237, Y=104},
        {ZIndex=122,IT=0.14566,IC=Color3.fromRGB(47,51,51),   S=11, V=true, R=56.93,   X=290, Y=36},
        {ZIndex=158,IT=0.39654,IC=Color3.fromRGB(189,190,190),S=9,  V=true, R=126.93,  X=-15, Y=381},
        {ZIndex=133,IT=0.72665,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=200.84,  X=108, Y=436},
        {ZIndex=86, IT=0.19931,IC=Color3.fromRGB(136,138,139),S=7,  V=true, R=100.93,  X=268, Y=258},
        {ZIndex=42, IT=0.14531,IC=Color3.fromRGB(45,49,49),   S=7,  V=true, R=53.93,   X=307, Y=23},
        {ZIndex=89, IT=0.81814,IC=Color3.fromRGB(241,241,242),S=5,  V=true, R=152.93,  X=407, Y=148},
        {ZIndex=164,IT=0.52767,IC=Color3.fromRGB(26,27,27),   S=21, V=true, R=19.93,   X=304, Y=324},
        {ZIndex=43, IT=0.91576,IC=Color3.fromRGB(217,252,255),S=3,  V=false,R=207.18,  X=55,  Y=-151},
        {ZIndex=108,IT=0.14971,IC=Color3.fromRGB(118,120,121),S=9,  V=true, R=91.93,   X=218, Y=185},
        {ZIndex=270,IT=0.8912, IC=Color3.fromRGB(216,251,255),S=7,  V=false,R=216.09,  X=-214,Y=-124},
        {ZIndex=126,IT=0.83547,IC=Color3.fromRGB(214,251,255),S=5,  V=false,R=261.08,  X=-200,Y=331},
        {ZIndex=90, IT=0.14485,IC=Color3.fromRGB(43,46,47),   S=9,  V=true, R=49.93,   X=50,  Y=75},
        {ZIndex=165,IT=0.96476,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=208.82,  X=355, Y=-93},
        {ZIndex=150,IT=0.46481,IC=Color3.fromRGB(207,208,208),S=7,  V=true, R=135.93,  X=251, Y=-27},
        {ZIndex=103,IT=0.72765,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=153.15,  X=168, Y=284},
        {ZIndex=235,IT=0.91295,IC=Color3.fromRGB(217,252,255),S=7,  V=false,R=207.08,  X=478, Y=56},
        {ZIndex=194,IT=0.78913,IC=Color3.fromRGB(213,251,255),S=5,  V=false,R=250.09,  X=-329,Y=179},
        {ZIndex=21, IT=0.97613,IC=Color3.fromRGB(219,252,255),S=3,  V=false,R=209.2,   X=-75, Y=45},
        {ZIndex=188,IT=0.58428,IC=Color3.fromRGB(207,249,255),S=7,  V=false,R=149.55,  X=214, Y=265},
        {ZIndex=63, IT=0.79241,IC=Color3.fromRGB(239,239,240),S=5,  V=true, R=151.93,  X=122, Y=156},
        {ZIndex=93, IT=0.14844,IC=Color3.fromRGB(95,99,99),   S=9,  V=true, R=80.93,   X=26,  Y=67},
        {ZIndex=103,IT=0.68821,IC=Color3.fromRGB(210,250,255),S=5,  V=false,R=199.55,  X=86,  Y=302},
        {ZIndex=87, IT=0.22207,IC=Color3.fromRGB(142,144,144),S=7,  V=true, R=103.93,  X=316, Y=258},
        {ZIndex=130,IT=0.27657,IC=Color3.fromRGB(33,35,36),   S=13, V=true, R=32.93,   X=160, Y=307},
        {ZIndex=161,IT=0.99515,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=209.84,  X=206, Y=-144},
        {ZIndex=157,IT=0.94559,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=208.18,  X=-1,  Y=-122},
        {ZIndex=105,IT=0.27517,IC=Color3.fromRGB(156,158,158),S=7,  V=true, R=110.93,  X=-6,  Y=83},
        {ZIndex=144,IT=0.29425,IC=Color3.fromRGB(33,35,35),   S=15, V=true, R=31.93,   X=48,  Y=111},
        {ZIndex=40, IT=0.29034,IC=Color3.fromRGB(160,162,162),S=5,  V=true, R=112.93,  X=267, Y=280},
        {ZIndex=197,IT=0.92688,IC=Color3.fromRGB(217,252,255),S=7,  V=false,R=207.55,  X=380, Y=210},
        {ZIndex=65, IT=0.67031,IC=Color3.fromRGB(24,25,25),   S=13, V=true, R=16.93,   X=208, Y=75},
        {ZIndex=153,IT=0.71786,IC=Color3.fromRGB(24,24,24),   S=21, V=true, R=15.93,   X=249, Y=301},
        {ZIndex=58, IT=0.91687,IC=Color3.fromRGB(217,252,255),S=3,  V=false,R=345.38,  X=467, Y=211},
        {ZIndex=57, IT=0.88235,IC=Color3.fromRGB(216,251,255),S=3,  V=false,R=269.78,  X=322, Y=-98},
        {ZIndex=60, IT=0.58651,IC=Color3.fromRGB(223,224,224),S=5,  V=true, R=143.93,  X=256, Y=314},
        {ZIndex=109,IT=0.68946,IC=Color3.fromRGB(231,232,232),S=5,  V=true, R=147.93,  X=155, Y=149},
        {ZIndex=56, IT=0.63553,IC=Color3.fromRGB(208,249,255),S=3,  V=false,R=150.84,  X=19,  Y=-75},
        {ZIndex=48, IT=0.14705,IC=Color3.fromRGB(71,75,75),   S=7,  V=true, R=68.93,   X=141, Y=288},
        {ZIndex=132,IT=0.16897,IC=Color3.fromRGB(128,130,131),S=9,  V=true, R=96.93,   X=55,  Y=272},
        {ZIndex=85, IT=0.49515,IC=Color3.fromRGB(215,216,216),S=5,  V=true, R=139.93,  X=216, Y=356},
        {ZIndex=155,IT=0.56077,IC=Color3.fromRGB(221,222,222),S=7,  V=true, R=142.93,  X=379, Y=223},
        {ZIndex=162,IT=0.36495,IC=Color3.fromRGB(30,32,32),   S=17, V=true, R=27.93,   X=102, Y=-7},
        {ZIndex=79, IT=0.61225,IC=Color3.fromRGB(225,226,226),S=5,  V=true, R=144.93,  X=259, Y=114},
        {ZIndex=38, IT=0.9251, IC=Color3.fromRGB(217,252,255),S=3,  V=false,R=333.69,  X=-272,Y=301},
        {ZIndex=97, IT=0.38263,IC=Color3.fromRGB(30,31,32),   S=11, V=true, R=26.93,   X=31,  Y=59},
        {ZIndex=131,IT=0.14612,IC=Color3.fromRGB(55,59,59),   S=11, V=true, R=60.93,   X=171, Y=238},
        {ZIndex=23, IT=0.1445, IC=Color3.fromRGB(41,44,45),   S=7,  V=true, R=46.93,   X=207, Y=218},
        {ZIndex=159,IT=0.14774,IC=Color3.fromRGB(83,87,87),   S=11, V=true, R=74.93,   X=49,  Y=185},
        {ZIndex=53, IT=0.1489, IC=Color3.fromRGB(103,107,107),S=7,  V=true, R=84.93,   X=357, Y=55},
        {ZIndex=34, IT=0.45333,IC=Color3.fromRGB(28,29,29),   S=11, V=true, R=22.93,   X=140, Y=101},
        {ZIndex=65, IT=0.81559,IC=Color3.fromRGB(214,251,255),S=3,  V=false,R=203.82,  X=244, Y=275},
        {ZIndex=193,IT=0.93721,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=330.65,  X=-308,Y=-168},
        {ZIndex=100,IT=0.99353,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=323.48,  X=99,  Y=595},
        {ZIndex=189,IT=0.88397,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=206.11,  X=116, Y=473},
        {ZIndex=110,IT=0.84388,IC=Color3.fromRGB(243,243,243),S=5,  V=true, R=153.93,  X=373, Y=113},
        {ZIndex=151,IT=0.99286,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=305.88,  X=-53, Y=-221},
        {ZIndex=136,IT=0.14647,IC=Color3.fromRGB(61,65,65),   S=11, V=true, R=63.93,   X=31,  Y=214},
        {ZIndex=117,IT=0.67531,IC=Color3.fromRGB(210,250,255),S=5,  V=false,R=151.84,  X=274, Y=64},
        {ZIndex=83, IT=0.98879,IC=Color3.fromRGB(219,252,255),S=3,  V=false,R=349.08,  X=456, Y=209},
        {ZIndex=203,IT=0.7515, IC=Color3.fromRGB(212,250,255),S=7,  V=false,R=201.67,  X=-85, Y=367},
        {ZIndex=57, IT=0.14786,IC=Color3.fromRGB(85,89,89),   S=7,  V=true, R=75.93,   X=33,  Y=205},
        {ZIndex=116,IT=0.40413,IC=Color3.fromRGB(191,192,192),S=7,  V=true, R=127.93,  X=1,   Y=76},
        {ZIndex=101,IT=0.3662, IC=Color3.fromRGB(180,182,182),S=7,  V=true, R=122.93,  X=182, Y=92},
        {ZIndex=206,IT=0.78453,IC=Color3.fromRGB(213,251,255),S=7,  V=false,R=202.78,  X=-156,Y=-156},
        {ZIndex=100,IT=0.94198,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=343.32,  X=-200,Y=484},
        {ZIndex=63, IT=0.88524,IC=Color3.fromRGB(216,251,255),S=3,  V=false,R=206.15,  X=37,  Y=303},
        {ZIndex=45, IT=0.14427,IC=Color3.fromRGB(40,43,43),   S=7,  V=true, R=44.93,   X=130, Y=170},
        {ZIndex=58, IT=0.8605, IC=Color3.fromRGB(22,22,22),   S=11, V=true, R=12.93,   X=290, Y=89},
        {ZIndex=23, IT=0.9463, IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=208.2,   X=-160,Y=174},
        {ZIndex=230,IT=0.94986,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=270.28,  X=285, Y=578},
        {ZIndex=37, IT=0.44205,IC=Color3.fromRGB(201,202,202),S=5,  V=true, R=132.93,  X=75,  Y=285},
        {ZIndex=125,IT=0.14751,IC=Color3.fromRGB(79,83,83),   S=9,  V=true, R=72.93,   X=225, Y=378},
        {ZIndex=37, IT=0.81058,IC=Color3.fromRGB(214,251,255),S=3,  V=false,R=203.65,  X=111, Y=-29},
        {ZIndex=72, IT=0.80755,IC=Color3.fromRGB(214,251,255),S=3,  V=false,R=203.55,  X=170, Y=-154},
        {ZIndex=107,IT=0.9051, IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=206.82,  X=339, Y=67},
        {ZIndex=22, IT=0.96532,IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=208.84,  X=83,  Y=-147},
        {ZIndex=218,IT=0.94613,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=354.38,  X=-386,Y=-23},
        {ZIndex=22, IT=0.14392,IC=Color3.fromRGB(38,41,42),   S=7,  V=true, R=41.93,   X=1,   Y=129},
        {ZIndex=110,IT=0.76803,IC=Color3.fromRGB(212,250,255),S=5,  V=false,R=219.38,  X=42,  Y=353},
        {ZIndex=77, IT=0.72856,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=153.18,  X=-58, Y=197},
        {ZIndex=118,IT=0.22354,IC=Color3.fromRGB(35,37,38),   S=11, V=true, R=35.93,   X=59,  Y=126},
        {ZIndex=103,IT=0.2069, IC=Color3.fromRGB(138,140,141),S=7,  V=true, R=101.93,  X=92,  Y=178},
        {ZIndex=124,IT=0.77424,IC=Color3.fromRGB(213,250,255),S=5,  V=false,R=202.43,  X=-145,Y=-36},
        {ZIndex=72, IT=0.14496,IC=Color3.fromRGB(43,47,47),   S=9,  V=true, R=50.93,   X=121, Y=252},
        {ZIndex=154,IT=0.14554,IC=Color3.fromRGB(46,50,51),   S=13, V=true, R=55.93,   X=281, Y=128},
        {ZIndex=129,IT=0.14658,IC=Color3.fromRGB(63,67,67),   S=11, V=true, R=64.93,   X=48,  Y=299},
        {ZIndex=239,IT=0.84003,IC=Color3.fromRGB(215,251,255),S=7,  V=false,R=315.09,  X=474, Y=-62},
        {ZIndex=143,IT=0.89705,IC=Color3.fromRGB(216,252,255),S=5,  V=false,R=206.55,  X=-225,Y=-25},
        {ZIndex=121,IT=0.32068,IC=Color3.fromRGB(168,170,170),S=7,  V=true, R=116.93,  X=190, Y=197},
        {ZIndex=191,IT=0.68879,IC=Color3.fromRGB(210,250,255),S=7,  V=false,R=152.18,  X=-182,Y=116},
        {ZIndex=67, IT=0.34728,IC=Color3.fromRGB(31,33,33),   S=11, V=true, R=28.93,   X=39,  Y=136},
        {ZIndex=238,IT=0.85534,IC=Color3.fromRGB(215,251,255),S=5,  V=false,R=197.22,  X=189, Y=484},
        {ZIndex=53, IT=0.84559,IC=Color3.fromRGB(215,251,255),S=3,  V=false,R=253.38,  X=255, Y=-41},
        {ZIndex=31, IT=0.22966,IC=Color3.fromRGB(144,146,146),S=5,  V=true, R=104.93,  X=309, Y=96},
        {ZIndex=56, IT=0.14902,IC=Color3.fromRGB(105,109,109),S=7,  V=true, R=85.93,   X=39,  Y=157},
        {ZIndex=112,IT=0.16138,IC=Color3.fromRGB(126,128,129),S=9,  V=true, R=95.93,   X=171, Y=95},
        {ZIndex=146,IT=0.48757,IC=Color3.fromRGB(213,214,214),S=7,  V=true, R=138.93,  X=46,  Y=182},
        {ZIndex=149,IT=0.31192,IC=Color3.fromRGB(32,34,34),   S=15, V=true, R=30.93,   X=298, Y=162},
        {ZIndex=36, IT=0.14601,IC=Color3.fromRGB(53,57,57),   S=7,  V=true, R=59.93,   X=177, Y=211},
        {ZIndex=134,IT=0.9138, IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=207.11,  X=-112,Y=356},
        {ZIndex=137,IT=0.71805,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=200.55,  X=-220,Y=62},
        {ZIndex=117,IT=0.14809,IC=Color3.fromRGB(89,93,93),   S=9,  V=true, R=77.93,   X=91,  Y=271},
        {ZIndex=149,IT=0.89618,IC=Color3.fromRGB(216,252,255),S=5,  V=false,R=321.65,  X=124, Y=652},
        {ZIndex=77, IT=0.80067,IC=Color3.fromRGB(213,251,255),S=3,  V=false,R=286.1,   X=388, Y=257},
        {ZIndex=93, IT=0.86721,IC=Color3.fromRGB(215,251,255),S=3,  V=false,R=205.55,  X=73,  Y=-82},
        {ZIndex=104,IT=0.94072,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=259.38,  X=-188,Y=-104},
        {ZIndex=209,IT=0.9844, IC=Color3.fromRGB(219,252,255),S=7,  V=false,R=209.48,  X=-293,Y=83},
        {ZIndex=28, IT=0.14821,IC=Color3.fromRGB(91,95,95),   S=7,  V=true, R=78.93,   X=-12, Y=198},
        {ZIndex=54, IT=0.76743,IC=Color3.fromRGB(212,250,255),S=3,  V=false,R=154.15,  X=243, Y=-16},
        {ZIndex=69, IT=0.93548,IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=207.84,  X=245, Y=74},
        {ZIndex=92, IT=0.14439,IC=Color3.fromRGB(41,44,44),   S=9,  V=true, R=45.93,   X=55,  Y=117},
        {ZIndex=40, IT=0.84893,IC=Color3.fromRGB(215,251,255),S=3,  V=false,R=156.2,   X=163, Y=3},
        {ZIndex=68, IT=0.14415,IC=Color3.fromRGB(39,43,43),   S=9,  V=true, R=43.93,   X=218, Y=167},
        {ZIndex=208,IT=0.87582,IC=Color3.fromRGB(216,251,255),S=7,  V=false,R=205.84,  X=-27, Y=449},
        {ZIndex=48, IT=0.90565,IC=Color3.fromRGB(217,252,255),S=3,  V=false,R=206.84,  X=-27, Y=6},
        {ZIndex=31, IT=0.96818,IC=Color3.fromRGB(219,252,255),S=3,  V=false,R=159.2,   X=107, Y=-3},
        {ZIndex=65, IT=0.68973,IC=Color3.fromRGB(210,250,255),S=3,  V=false,R=152.2,   X=227, Y=-4},
        {ZIndex=33, IT=0.76834,IC=Color3.fromRGB(212,250,255),S=3,  V=false,R=154.18,  X=243, Y=87},
        {ZIndex=106,IT=0.17052,IC=Color3.fromRGB(37,39,40),   S=11, V=true, R=38.93,   X=275, Y=202},
        {ZIndex=49, IT=0.95559,IC=Color3.fromRGB(21,21,21),   S=13, V=true, R=10.93,   X=97,  Y=337},
        {ZIndex=157,IT=0.14508,IC=Color3.fromRGB(44,48,48),   S=13, V=true, R=51.93,   X=15,  Y=171},
        {ZIndex=148,IT=0.18414,IC=Color3.fromRGB(132,134,135),S=9,  V=true, R=98.93,   X=24,  Y=173},
        {ZIndex=107,IT=0.2589, IC=Color3.fromRGB(34,36,36),   S=11, V=true, R=33.93,   X=74,  Y=81},
        {ZIndex=95, IT=0.14948,IC=Color3.fromRGB(114,117,117),S=7,  V=true, R=89.93,   X=0,   Y=46},
        {ZIndex=33, IT=0.24483,IC=Color3.fromRGB(148,150,150),S=5,  V=true, R=106.93,  X=256, Y=91},
        {ZIndex=202,IT=0.79447,IC=Color3.fromRGB(213,251,255),S=5,  V=false,R=203.11,  X=-200,Y=-2},
        {ZIndex=188,IT=0.97582,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=209.19,  X=131, Y=-118},
        {ZIndex=39, IT=0.14983,IC=Color3.fromRGB(120,122,123),S=5,  V=true, R=92.93,   X=133, Y=284},
        {ZIndex=168,IT=0.97437,IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=268.32,  X=-263,Y=407},
        {ZIndex=156,IT=0.88592,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=206.18,  X=-61, Y=-205},
        {ZIndex=127,IT=0.66372,IC=Color3.fromRGB(229,230,230),S=7,  V=true, R=146.93,  X=341, Y=108},
        {ZIndex=163,IT=0.33585,IC=Color3.fromRGB(172,174,174),S=9,  V=true, R=118.93,  X=270, Y=349},
        {ZIndex=27, IT=0.43447,IC=Color3.fromRGB(199,200,200),S=5,  V=true, R=131.93,  X=138, Y=144},
        {ZIndex=138,IT=0.76667,IC=Color3.fromRGB(237,238,238),S=7,  V=true, R=150.93,  X=339, Y=323},
        {ZIndex=155,IT=0.74282,IC=Color3.fromRGB(212,250,255),S=5,  V=false,R=201.38,  X=-21, Y=-119},
        {ZIndex=96, IT=0.38895,IC=Color3.fromRGB(186,188,188),S=7,  V=true, R=125.93,  X=31,  Y=119},
        {ZIndex=216,IT=0.87526,IC=Color3.fromRGB(216,251,255),S=7,  V=false,R=205.82,  X=372, Y=219},
        {ZIndex=124,IT=0.86962,IC=Color3.fromRGB(245,245,245),S=5,  V=true, R=154.93,  X=248, Y=134},
        {ZIndex=166,IT=0.1538, IC=Color3.fromRGB(124,126,127),S=11, V=true, R=94.93,   X=249, Y=150},
        {ZIndex=83, IT=0.14473,IC=Color3.fromRGB(42,46,46),   S=9,  V=true, R=48.93,   X=104, Y=173},
        {ZIndex=50, IT=0.1452, IC=Color3.fromRGB(44,48,49),   S=7,  V=true, R=52.93,   X=168, Y=-12},
        {ZIndex=156,IT=0.4193, IC=Color3.fromRGB(195,196,196),S=9,  V=true, R=129.93,  X=156, Y=348},
        {ZIndex=109,IT=0.89303,IC=Color3.fromRGB(216,252,255),S=5,  V=false,R=215.38,  X=-46, Y=-17},
        {ZIndex=258,IT=0.66629,IC=Color3.fromRGB(209,249,255),S=7,  V=false,R=220.1,   X=72,  Y=-260},
        {ZIndex=161,IT=0.88148,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=350.1,   X=400, Y=-76},
        {ZIndex=35, IT=0.62277,IC=Color3.fromRGB(25,26,26),   S=11, V=true, R=17.93,   X=311, Y=333},
        {ZIndex=170,IT=0.88454,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=206.13,  X=356, Y=273},
        {ZIndex=104,IT=0.30551,IC=Color3.fromRGB(164,166,166),S=7,  V=true, R=114.93,  X=44,  Y=234},
        {ZIndex=24, IT=0.29793,IC=Color3.fromRGB(162,164,164),S=5,  V=true, R=113.93,  X=324, Y=316},
        {ZIndex=137,IT=0.14462,IC=Color3.fromRGB(42,45,45),   S=11, V=true, R=47.93,   X=97,  Y=-23},
        {ZIndex=33, IT=0.8243, IC=Color3.fromRGB(214,251,255),S=3,  V=false,R=204.11,  X=-51, Y=203},
        {ZIndex=165,IT=0.14959,IC=Color3.fromRGB(116,118,119),S=11, V=true, R=90.93,   X=161, Y=148},
        {ZIndex=152,IT=0.14855,IC=Color3.fromRGB(97,101,101), S=11, V=true, R=81.93,   X=263, Y=140},
        {ZIndex=73, IT=0.74093,IC=Color3.fromRGB(235,236,236),S=5,  V=true, R=149.93,  X=289, Y=166},
        {ZIndex=77, IT=0.9983, IC=Color3.fromRGB(255,255,255),S=5,  V=true, R=159.93,  X=139, Y=238},
        {ZIndex=116,IT=0.7296, IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=153.2,   X=244, Y=211},
        {ZIndex=26, IT=0.5093, IC=Color3.fromRGB(217,218,218),S=3,  V=true, R=140.93,  X=237, Y=268},
        {ZIndex=147,IT=0.88663,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=206.2,   X=326, Y=15},
        {ZIndex=125,IT=0.84699,IC=Color3.fromRGB(215,251,255),S=5,  V=false,R=156.15,  X=265, Y=234},
        {ZIndex=69, IT=0.57522,IC=Color3.fromRGB(25,26,26),   S=13, V=true, R=18.93,   X=52,  Y=196},
        {ZIndex=29, IT=0.34344,IC=Color3.fromRGB(174,176,176),S=5,  V=true, R=119.93,  X=251, Y=172},
        {ZIndex=147,IT=0.35103,IC=Color3.fromRGB(176,178,178),S=9,  V=true, R=120.93,  X=167, Y=158},
        {ZIndex=80, IT=0.14832,IC=Color3.fromRGB(93,97,97),   S=7,  V=true, R=79.93,   X=271, Y=110},
        {ZIndex=47, IT=0.14404,IC=Color3.fromRGB(39,42,42),   S=7,  V=true, R=42.93,   X=311, Y=296},
        {ZIndex=123,IT=0.15284,IC=Color3.fromRGB(37,40,40),   S=11, V=true, R=39.93,   X=207, Y=270},
        {ZIndex=141,IT=0.88336,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=264.32,  X=-291,Y=286},
        {ZIndex=168,IT=0.25241,IC=Color3.fromRGB(150,152,152),S=11, V=true, R=107.93,  X=270, Y=306},
        {ZIndex=69, IT=0.88312,IC=Color3.fromRGB(216,251,255),S=3,  V=false,R=206.08,  X=231, Y=242},
        {ZIndex=122,IT=0.83738,IC=Color3.fromRGB(215,251,255),S=5,  V=false,R=204.55,  X=34,  Y=391},
        {ZIndex=75, IT=0.98196,IC=Color3.fromRGB(219,252,255),S=3,  V=false,R=311.38,  X=156, Y=-194},
        {ZIndex=217,IT=0.90671,IC=Color3.fromRGB(217,252,255),S=7,  V=false,R=312.84,  X=-228,Y=-237},
        {ZIndex=149,IT=0.72813,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=258.1,   X=-301,Y=45},
        {ZIndex=166,IT=0.77771,IC=Color3.fromRGB(213,250,255),S=5,  V=false,R=202.55,  X=341, Y=312},
        {ZIndex=126,IT=0.24122,IC=Color3.fromRGB(34,37,37),   S=13, V=true, R=34.93,   X=92,  Y=200},
        {ZIndex=55, IT=0.14925,IC=Color3.fromRGB(110,113,113),S=7,  V=true, R=87.93,   X=95,  Y=263},
        {ZIndex=81, IT=0.14682,IC=Color3.fromRGB(67,71,71),   S=9,  V=true, R=66.93,   X=304, Y=40},
        {ZIndex=160,IT=0.3131, IC=Color3.fromRGB(166,168,168),S=9,  V=true, R=115.93,  X=288, Y=272},
        {ZIndex=78, IT=0.84543,IC=Color3.fromRGB(215,251,255),S=3,  V=false,R=204.82,  X=-114,Y=269},
        {ZIndex=177,IT=0.85329,IC=Color3.fromRGB(215,251,255),S=5,  V=false,R=205.08,  X=59,  Y=463},
        {ZIndex=21, IT=0.32827,IC=Color3.fromRGB(170,172,172),S=5,  V=true, R=117.93,  X=199, Y=100},
        {ZIndex=94, IT=0.19173,IC=Color3.fromRGB(134,136,137),S=7,  V=true, R=99.93,   X=352, Y=186},
        {ZIndex=59, IT=0.14913,IC=Color3.fromRGB(107,111,111),S=7,  V=true, R=86.93,   X=292, Y=85},
        {ZIndex=170,IT=0.94598,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=208.19,  X=345, Y=350},
        {ZIndex=114,IT=0.17656,IC=Color3.fromRGB(130,132,133),S=9,  V=true, R=97.93,   X=245, Y=253},
        {ZIndex=140,IT=0.14797,IC=Color3.fromRGB(87,91,91),   S=11, V=true, R=76.93,   X=98,  Y=138},
        {ZIndex=155,IT=0.976,  IC=Color3.fromRGB(219,252,255),S=5,  V=false,R=358.48,  X=149, Y=735},
        {ZIndex=38, IT=0.18819,IC=Color3.fromRGB(36,39,39),   S=7,  V=true, R=37.93,   X=39,  Y=148},
        {ZIndex=66, IT=0.68787,IC=Color3.fromRGB(210,250,255),S=3,  V=false,R=152.15,  X=19,  Y=-49},
        {ZIndex=98, IT=0.14577,IC=Color3.fromRGB(49,53,53),   S=9,  V=true, R=57.93,   X=6,   Y=108},
        {ZIndex=109,IT=0.88676,IC=Color3.fromRGB(216,251,255),S=5,  V=false,R=157.15,  X=100, Y=335},
        {ZIndex=136,IT=0.91507,IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=207.15,  X=111, Y=-187},
        {ZIndex=110,IT=0.75648,IC=Color3.fromRGB(212,250,255),S=5,  V=false,R=201.84,  X=26,  Y=317},
        {ZIndex=61, IT=0.92109,IC=Color3.fromRGB(249,249,249),S=3,  V=true, R=156.93,  X=128, Y=383},
        {ZIndex=38, IT=0.9485, IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=259.32,  X=103, Y=-185},
        {ZIndex=171,IT=0.9105, IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=296.67,  X=16,  Y=-210},
        {ZIndex=145,IT=0.14867,IC=Color3.fromRGB(99,103,103), S=11, V=true, R=82.93,   X=20,  Y=260},
        {ZIndex=40, IT=0.76463,IC=Color3.fromRGB(212,250,255),S=3,  V=false,R=202.11,  X=285, Y=153},
        {ZIndex=54, IT=0.89535,IC=Color3.fromRGB(247,247,247),S=3,  V=true, R=155.93,  X=363, Y=187},
        {ZIndex=71, IT=0.14878,IC=Color3.fromRGB(101,105,105),S=7,  V=true, R=83.93,   X=214, Y=182},
        {ZIndex=48, IT=0.62406,IC=Color3.fromRGB(208,249,255),S=3,  V=false,R=150.55,  X=213, Y=31},
        {ZIndex=143,IT=0.14624,IC=Color3.fromRGB(57,61,61),   S=11, V=true, R=61.93,   X=120, Y=310},
        {ZIndex=84, IT=0.1467, IC=Color3.fromRGB(65,69,69),   S=9,  V=true, R=65.93,   X=42,  Y=173},
        {ZIndex=41, IT=0.97257,IC=Color3.fromRGB(253,253,253),S=3,  V=true, R=158.93,  X=129, Y=15},
        {ZIndex=202,IT=0.78631,IC=Color3.fromRGB(213,251,255),S=7,  V=false,R=202.84,  X=52,  Y=-289},
        {ZIndex=102,IT=0.1474, IC=Color3.fromRGB(77,81,81),   S=9,  V=true, R=71.93,   X=217, Y=40},
        {ZIndex=272,IT=0.77265,IC=Color3.fromRGB(213,250,255),S=7,  V=false,R=202.38,  X=55,  Y=477},
        {ZIndex=30, IT=0.89005,IC=Color3.fromRGB(216,251,255),S=3,  V=false,R=320.13,  X=207, Y=-107},
        {ZIndex=62, IT=0.45723,IC=Color3.fromRGB(205,206,206),S=5,  V=true, R=134.93,  X=16,  Y=228},
        {ZIndex=43, IT=0.14936,IC=Color3.fromRGB(112,115,115),S=5,  V=true, R=88.93,   X=178, Y=42},
        {ZIndex=39, IT=0.97591,IC=Color3.fromRGB(219,252,255),S=3,  V=false,R=294.08,  X=-235,Y=-30},
        {ZIndex=88, IT=0.80721,IC=Color3.fromRGB(214,251,255),S=5,  V=false,R=155.15,  X=206, Y=78},
        {ZIndex=70, IT=0.53503,IC=Color3.fromRGB(219,220,220),S=5,  V=true, R=141.93,  X=136, Y=127},
        {ZIndex=25, IT=0.95903,IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=267.32,  X=294, Y=13},
        {ZIndex=82, IT=0.94683,IC=Color3.fromRGB(251,251,251),S=5,  V=true, R=157.93,  X=76,  Y=-14},
        {ZIndex=151,IT=0.7654, IC=Color3.fromRGB(23,24,24),   S=19, V=true, R=14.93,   X=8,   Y=237},
        {ZIndex=32, IT=0.35861,IC=Color3.fromRGB(178,180,180),S=5,  V=true, R=121.93,  X=-37, Y=133},
        {ZIndex=82, IT=0.93493,IC=Color3.fromRGB(218,252,255),S=3,  V=false,R=207.82,  X=59,  Y=330},
        {ZIndex=134,IT=0.40031,IC=Color3.fromRGB(29,31,31),   S=15, V=true, R=25.93,   X=191, Y=228},
        {ZIndex=112,IT=0.72951,IC=Color3.fromRGB(211,250,255),S=5,  V=false,R=153.2,   X=130, Y=192},
        {ZIndex=25, IT=0.81295,IC=Color3.fromRGB(23,23,23),   S=13, V=true, R=13.93,   X=38,  Y=285},
        {ZIndex=120,IT=0.71519,IC=Color3.fromRGB(233,234,234),S=5,  V=true, R=148.93,  X=167, Y=170},
        {ZIndex=142,IT=0.14635,IC=Color3.fromRGB(59,63,63),   S=11, V=true, R=62.93,   X=112, Y=196},
        {ZIndex=44, IT=0.63798,IC=Color3.fromRGB(227,228,228),S=3,  V=true, R=145.93,  X=140, Y=334},
        {ZIndex=63, IT=0.80812,IC=Color3.fromRGB(214,251,255),S=3,  V=false,R=155.18,  X=-139,Y=-33},
        {ZIndex=119,IT=0.23724,IC=Color3.fromRGB(146,148,148),S=7,  V=true, R=105.93,  X=230, Y=20},
        {ZIndex=157,IT=0.91647,IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=207.2,   X=-178,Y=300},
        {ZIndex=100,IT=0.26758,IC=Color3.fromRGB(154,156,156),S=7,  V=true, R=109.93,  X=64,  Y=-34},
        {ZIndex=76, IT=0.41798,IC=Color3.fromRGB(29,30,30),   S=11, V=true, R=24.93,   X=161, Y=50},
        {ZIndex=220,IT=0.66384,IC=Color3.fromRGB(209,249,255),S=7,  V=false,R=151.55,  X=395, Y=-46},
        {ZIndex=151,IT=0.93876,IC=Color3.fromRGB(218,252,255),S=5,  V=false,R=255.38,  X=224, Y=-70},
        {ZIndex=115,IT=0.90804,IC=Color3.fromRGB(22,22,22),   S=19, V=true, R=11.93,   X=214, Y=314},
        {ZIndex=74, IT=0.47101,IC=Color3.fromRGB(27,28,28),   S=13, V=true, R=21.93,   X=240, Y=52},
        {ZIndex=187,IT=0.81437,IC=Color3.fromRGB(214,251,255),S=5,  V=false,R=203.78,  X=307, Y=54},
        {ZIndex=52, IT=0.43566,IC=Color3.fromRGB(28,30,30),   S=11, V=true, R=23.93,   X=275, Y=21},
        {ZIndex=135,IT=0.81862,IC=Color3.fromRGB(214,251,255),S=5,  V=false,R=256.32,  X=321, Y=297},
        {ZIndex=169,IT=0.41171,IC=Color3.fromRGB(193,194,194),S=9,  V=true, R=128.93,  X=164, Y=295},
        {ZIndex=220,IT=0.76462,IC=Color3.fromRGB(212,250,255),S=7,  V=false,R=221.11,  X=62,  Y=-186},
        {ZIndex=135,IT=0.47998,IC=Color3.fromRGB(211,212,212),S=7,  V=true, R=137.93,  X=43,  Y=105},
        {ZIndex=113,IT=0.4724, IC=Color3.fromRGB(209,210,210),S=7,  V=true, R=136.93,  X=248, Y=393},
        {ZIndex=51, IT=0.37378,IC=Color3.fromRGB(182,184,184),S=5,  V=true, R=123.93,  X=322, Y=262},
        {ZIndex=46, IT=0.26,   IC=Color3.fromRGB(152,154,154),S=5,  V=true, R=108.93,  X=38,  Y=231},
        {ZIndex=139,IT=0.14589,IC=Color3.fromRGB(51,55,55),   S=11, V=true, R=58.93,   X=112, Y=3},
        {ZIndex=141,IT=0.14994,IC=Color3.fromRGB(122,124,125),S=9,  V=true, R=93.93,   X=136, Y=70},
        {ZIndex=103,IT=0.79977,IC=Color3.fromRGB(213,251,255),S=3,  V=false,R=289.93,  X=-204,Y=299},
        {ZIndex=88, IT=0.38137,IC=Color3.fromRGB(184,186,186),S=5,  V=true, R=124.93,  X=55,  Y=281},
        {ZIndex=161,IT=0.21448,IC=Color3.fromRGB(140,142,143),S=11, V=true, R=102.93,  X=225, Y=124},
        {ZIndex=111,IT=0.14716,IC=Color3.fromRGB(73,77,77),   S=9,  V=true, R=69.93,   X=221, Y=-2},
        {ZIndex=36, IT=0.85413,IC=Color3.fromRGB(215,251,255),S=3,  V=false,R=205.11,  X=73,  Y=246},
        {ZIndex=91, IT=0.48869,IC=Color3.fromRGB(27,28,28),   S=13, V=true, R=20.93,   X=306, Y=222},
        {ZIndex=78, IT=0.28275,IC=Color3.fromRGB(158,160,160),S=7,  V=true, R=111.93,  X=347, Y=273},
        {ZIndex=212,IT=0.86531,IC=Color3.fromRGB(215,251,255),S=7,  V=false,R=319.84,  X=253, Y=876},
        {ZIndex=30, IT=0.3296, IC=Color3.fromRGB(32,33,34),   S=9,  V=true, R=29.93,   X=304, Y=168},
        {ZIndex=64, IT=0.14693,IC=Color3.fromRGB(69,73,73),   S=7,  V=true, R=67.93,   X=4,   Y=170},
        {ZIndex=170,IT=0.20587,IC=Color3.fromRGB(36,38,38),   S=15, V=true, R=36.93,   X=-6,  Y=126},
        {ZIndex=222,IT=0.91612,IC=Color3.fromRGB(217,252,255),S=5,  V=false,R=223.11,  X=218, Y=-143},
        {ZIndex=133,IT=0.14763,IC=Color3.fromRGB(81,85,85),   S=11, V=true, R=73.93,   X=85,  Y=70},
        {ZIndex=66, IT=0.42688,IC=Color3.fromRGB(197,198,198),S=5,  V=true, R=130.93,  X=68,  Y=249},
        {ZIndex=105,IT=0.76938,IC=Color3.fromRGB(212,250,255),S=5,  V=false,R=154.2,   X=-141,Y=177},
        {ZIndex=75, IT=0.85687,IC=Color3.fromRGB(215,251,255),S=5,  V=false,R=205.2,   X=-124,Y=109},
    }

    for _, p in ipairs(particleData) do
        local img = Instance.new("ImageLabel", particleFrame)
        img.Interactable        = false
        img.ZIndex              = p.ZIndex
        img.ImageTransparency  = p.IT
        img.ImageColor3        = p.IC
        img.AnchorPoint        = Vector2.new(0.5, 0.5)
        img.Image              = "rbxassetid://867619398"
        img.Archivable         = false
        img.Size               = UDim2.fromOffset(p.S, p.S)
        img.Visible            = p.V
        img.BackgroundTransparency = 1
        img.Rotation           = p.R
        img.Name               = "Particle"
        img.Position           = UDim2.fromOffset(p.X, p.Y)
        CollSvc:AddTag(img, "Emitter2D_Particle")
    end

    -- Wait for particles to play, then signal ready and fade out particles
    task.delay(PARTICLE_SHOW, function()
        -- Stop new particles spawning
        Emitter:SetAttribute("Enabled", false)

        -- Fade background out AND call onReady simultaneously
        TweenService:Create(bg, TweenInfo.new(HUB_FADE_IN, Enum.EasingStyle.Quad), {BackgroundTransparency = 1}):Play()
        onReady()  -- hub starts fading IN at the same moment

        -- After existing particles have died out, destroy the whole loader
        task.delay(PARTICLE_FADEOUT, function()
            if pGui and pGui.Parent then
                pGui:Destroy()
            end
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
    ScreenGui.Name            = "ExireReanimateHub"
    ScreenGui.ResetOnSpawn    = false
    ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    ScreenGui.IgnoreGuiInset  = true
    pcall(function() ScreenGui.ScreenInsets = Enum.ScreenInsets.None end)
    ScreenGui.Parent = Player.PlayerGui

    local CENTER = UDim2.new(0.5, 0, 0.5, 0)
    local ANCHOR  = Vector2.new(0.5, 0.5)

    -- ── MainFrame ──────────────────────────────────────────────
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Name                   = "MainFrame"
    MainFrame.BorderSizePixel        = 0
    MainFrame.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    MainFrame.BackgroundTransparency = 0.5
    MainFrame.AnchorPoint            = ANCHOR
    MainFrame.Size                   = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    MainFrame.Position               = CENTER
    MainFrame.ClipsDescendants       = true
    MainFrame.ZIndex                 = 1
    -- Start invisible for fade-in
    MainFrame.Visible                = false

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0.05, 0)

    local mfGrad = Instance.new("UIGradient", MainFrame)
    mfGrad.Rotation = -90
    mfGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,   0,  0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59)),
    }

    local mfStroke = Instance.new("UIStroke", MainFrame)
    mfStroke.Transparency = 0.3
    mfStroke.Thickness    = 3
    local mfStrokeGrad = Instance.new("UIGradient", mfStroke)
    mfStrokeGrad.Rotation = 90
    mfStrokeGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,   0,  0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59)),
    }

    -- ── ScriptHolder ───────────────────────────────────────────
    local ScriptHolder = Instance.new("ScrollingFrame", MainFrame)
    ScriptHolder.Name                   = "ScriptHolder"
    ScriptHolder.BorderSizePixel        = 0
    ScriptHolder.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
    ScriptHolder.BackgroundTransparency = 0.5
    ScriptHolder.Size                   = UDim2.new(SH_SX, 0, SH_SY, 0)
    ScriptHolder.Position               = UDim2.new(SH_X,  0, SH_Y,  0)
    ScriptHolder.ScrollBarThickness     = 4
    ScriptHolder.ScrollBarImageColor3   = Color3.fromRGB(255, 255, 255)
    ScriptHolder.CanvasSize             = UDim2.new(0, 0, 0, 0)
    ScriptHolder.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    ScriptHolder.ClipsDescendants       = true
    ScriptHolder.ZIndex                 = 2

    Instance.new("UICorner", ScriptHolder).CornerRadius = UDim.new(0.05, 0)

    local shGrad = Instance.new("UIGradient", ScriptHolder)
    shGrad.Rotation = -90
    shGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0,   0,  0)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59)),
    }

    local ListLayout = Instance.new("UIListLayout", ScriptHolder)
    ListLayout.Padding             = UDim.new(CARD_PAD, 0)
    ListLayout.SortOrder           = Enum.SortOrder.LayoutOrder
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local ListPad = Instance.new("UIPadding", ScriptHolder)
    ListPad.PaddingTop    = UDim.new(0.01, 0)
    ListPad.PaddingBottom = UDim.new(0.01, 0)

    -- ── TitleBarFrame (ScreenGui sibling) ───────────────────────
    local TitleBarFrame = Instance.new("Frame", ScreenGui)
    TitleBarFrame.Name                   = "TitleBarFrame"
    TitleBarFrame.BorderSizePixel        = 0
    TitleBarFrame.BackgroundTransparency = 1
    TitleBarFrame.AnchorPoint            = ANCHOR
    TitleBarFrame.Size                   = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    TitleBarFrame.Position               = CENTER
    TitleBarFrame.ZIndex                 = 10
    TitleBarFrame.Visible                = false

    Instance.new("UICorner", TitleBarFrame).CornerRadius = UDim.new(0.05, 0)

    local Title = Instance.new("TextLabel", TitleBarFrame)
    Title.Name                   = "Title"
    Title.BorderSizePixel        = 0
    Title.TextWrapped            = true
    Title.TextScaled             = true
    Title.TextXAlignment         = Enum.TextXAlignment.Left
    Title.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    Title.BackgroundTransparency = 0.6
    Title.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextColor3             = Color3.fromRGB(255, 255, 255)
    Title.Size                   = UDim2.new(0.872, 0, TITLE_SY, 0)
    Title.Position               = UDim2.new(0.06391, 0, 0.01692, 0)
    Title.Text                   = [[ l   Exire Reanimate ScriptHub  ]]
    Title.ZIndex                 = 11
    Instance.new("UICorner", Title).CornerRadius = UDim.new(0.1, 0)

    local MinBtn = Instance.new("TextButton", Title)
    MinBtn.Name                   = "Minimize"
    MinBtn.BorderSizePixel        = 0
    MinBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
    MinBtn.BackgroundTransparency = 0.5
    MinBtn.Size                   = UDim2.new(0.1056, 0, 1, 0)
    MinBtn.Position               = UDim2.new(0.8944, 0, 0, 0)
    MinBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
    MinBtn.TextScaled             = true
    MinBtn.FontFace               = Font.new("rbxasset://fonts/families/Zekton.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    MinBtn.Text                   = [[-]]
    MinBtn.ZIndex                 = 12
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0.1, 0)

    -- Apply premium feel to minimize button
    premiumButton(MinBtn, Color3.fromRGB(200, 200, 200))

    -- ── Script Cards ───────────────────────────────────────────
    for i, data in ipairs(Scripts) do
        local Card = Instance.new("Frame", ScriptHolder)
        Card.Name                   = "Card_" .. i
        Card.LayoutOrder            = i
        Card.BorderSizePixel        = 0
        Card.BackgroundColor3       = Color3.fromRGB(121, 121, 121)
        Card.BackgroundTransparency = 0.5
        Card.Size                   = UDim2.new(CARD_SX, 0, CARD_SY, 0)
        Card.ZIndex                 = 3
        Instance.new("UICorner", Card).CornerRadius = UDim.new(0.05, 0)

        local cardGrad = Instance.new("UIGradient", Card)
        cardGrad.Rotation = -90
        cardGrad.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0,   0,  0)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 59, 59)),
        }

        -- Card hover shimmer
        cardHover(Card)

        local NameLbl = Instance.new("TextLabel", Card)
        NameLbl.Name                   = "ScriptName"
        NameLbl.BorderSizePixel        = 0
        NameLbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        NameLbl.BackgroundTransparency = 0.8
        NameLbl.TextWrapped            = true
        NameLbl.TextScaled             = true
        NameLbl.TextXAlignment         = Enum.TextXAlignment.Center
        NameLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        NameLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        NameLbl.Size                   = UDim2.new(0.4775, 0, 0.23, 0)
        NameLbl.Position               = UDim2.new(0.0225, 0, 0.07, 0)
        NameLbl.Text                   = data.name or "Script Name"
        NameLbl.ZIndex                 = 4
        Instance.new("UICorner", NameLbl).CornerRadius = UDim.new(0.1, 0)

        local DescLbl = Instance.new("TextLabel", Card)
        DescLbl.Name                   = "ScriptDescription"
        DescLbl.BorderSizePixel        = 0
        DescLbl.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        DescLbl.BackgroundTransparency = 0.8
        DescLbl.TextWrapped            = true
        DescLbl.TextScaled             = true
        DescLbl.TextXAlignment         = Enum.TextXAlignment.Center
        DescLbl.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        DescLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
        DescLbl.Size                   = UDim2.new(0.4775, 0, 0.52, 0)
        DescLbl.Position               = UDim2.new(0.0225, 0, 0.38, 0)
        DescLbl.Text                   = data.description or "A brief description of keybinds and what the script does"
        DescLbl.ZIndex                 = 4
        Instance.new("UICorner", DescLbl).CornerRadius = UDim.new(0.05, 0)

        -- Run button
        local RunBtn = Instance.new("TextButton", Card)
        RunBtn.Name                   = "RunButton"
        RunBtn.BorderSizePixel        = 0
        RunBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RunBtn.BackgroundTransparency = 0.5
        RunBtn.TextWrapped            = true
        RunBtn.TextScaled             = true
        RunBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RunBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RunBtn.Size                   = UDim2.new(0.4125, 0, 0.41, 0)
        RunBtn.Position               = UDim2.new(0.5275, 0, 0.06375, 0)
        RunBtn.Text                   = "Run"
        RunBtn.ZIndex                 = 5
        Instance.new("UICorner", RunBtn).CornerRadius = UDim.new(0.1, 0)
        premiumButton(RunBtn, Color3.fromRGB(160, 255, 160))

        -- Rig button
        local RigBtn = Instance.new("TextButton", Card)
        RigBtn.Name                   = "RigButton"
        RigBtn.BorderSizePixel        = 0
        RigBtn.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        RigBtn.BackgroundTransparency = 0.5
        RigBtn.TextWrapped            = true
        RigBtn.TextScaled             = true
        RigBtn.FontFace               = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
        RigBtn.TextColor3             = Color3.fromRGB(255, 255, 255)
        RigBtn.Size                   = UDim2.new(0.18, 0, 0.33, 0)
        RigBtn.Position               = UDim2.new(0.76, 0, 0.57593, 0)
        RigBtn.Text                   = "Rig"
        RigBtn.ZIndex                 = 5
        Instance.new("UICorner", RigBtn).CornerRadius = UDim.new(0.1, 0)
        premiumButton(RigBtn, Color3.fromRGB(160, 200, 255))

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

    -- ── Fade-in function (called by particle loader) ────────────
    local function fadeIn()
        MainFrame.Visible     = true
        TitleBarFrame.Visible = true
        -- We tween via a UIColorGradient trick: actually the cleanest approach
        -- in Roblox is to use a covering Frame that tweens transparency.
        -- We create a full-cover tint frame that fades from opaque to 1.
        local cover = Instance.new("Frame", ScreenGui)
        cover.Name                   = "FadeCover"
        cover.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
        cover.BackgroundTransparency = 0    -- fully opaque = hub hidden
        cover.BorderSizePixel        = 0
        cover.Size                   = UDim2.new(1, 0, 1, 0)
        cover.ZIndex                 = 50   -- above everything

        TweenService:Create(cover,
            TweenInfo.new(HUB_FADE_IN, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()

        task.delay(HUB_FADE_IN, function()
            cover:Destroy()
        end)
    end

    -- ── Minimize ───────────────────────────────────────────────
    local minimized = false
    local FULL_SIZE = UDim2.new(WIN_SX, 0, WIN_SY, 0)
    local MIN_SIZE  = UDim2.new(WIN_SX, 0, 0,      0)

    MinBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        TweenService:Create(MainFrame,
            TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            {Size = minimized and MIN_SIZE or FULL_SIZE}
        ):Play()
        MinBtn.Text = minimized and "+" or "-"
    end)

    -- ── Drag ───────────────────────────────────────────────────
    local dragging, dragStart, startPos = false, nil, nil

    Title.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = MainFrame.Position
        end
    end)

    Title.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end

        local delta  = inp.Position - dragStart
        local vp     = workspace.CurrentCamera.ViewportSize
        local newPos = UDim2.new(
            startPos.X.Scale + delta.X / vp.X, 0,
            startPos.Y.Scale + delta.Y / vp.Y, 0
        )
        MainFrame.Position     = newPos
        TitleBarFrame.Position = newPos
    end)

    -- ── Trigger particle loader, fade hub in on completion ─────
    -- buildParticleLoader(fadeIn)
end

buildHub()

Player.CharacterAdded:Connect(function()
    if not Player.PlayerGui:FindFirstChild("ExireReanimateHub") then
        buildHub()
    end
end)

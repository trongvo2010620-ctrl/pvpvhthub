--[[
    VHT HUB PVP by Hoàng Trọng DEV
    Executor: Delta
    Chức năng: Silent Aim Gun, Camera Aim Skill,
               ESP Box + Info + Máu, Hitbox Expander, Team Check
    Lưu ý: Chỉ dùng cho mục đích học tập
]]

-- ========== 1. KHỞI TẠO ==========
if not game:IsLoaded() then game.Loaded:Wait() end
repeat task.wait() until game:IsLoaded() and game.Players.LocalPlayer

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LP:GetMouse()

-- ========== 2. BẢO VỆ GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VHTHubPVP"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game:GetService("CoreGui")
elseif gethui then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "VHT_ESP"
ESPFolder.Parent = ScreenGui

-- ========== 3. CONFIG ==========
local Config = {
    SilentGun = false,
    SilentGunFOV = 200,
    SilentGunTeamCheck = true,
    SilentGunTarget = "FOV",

    SkillAim = false,
    SkillAimFOV = 200,
    SkillAimSmooth = 0.15,
    SkillAimTeamCheck = true,
    SkillAimTarget = "FOV",

    ESPEnabled = false,
    ESPBox = true,
    ESPInfo = true,
    ESPHealth = true,
    ESPTeamCheck = true,
    ESPMaxDistance = 1500,

    HitboxEnabled = false,
    HitboxSize = 15,
    HitboxTeamCheck = true,

    ShowFOV = false,
}

-- ========== 4. GUI (MENU TABS) ==========
local function CreateToggle(parent, name, y, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.95, 0, 0, 30)
    Btn.Position = UDim2.new(0.025, 0, 0, y)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    Btn.BorderSizePixel = 0
    Btn.Text = name .. ": OFF"
    Btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.Gotham
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    local state = false
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = name .. ": " .. (state and "ON" or "OFF")
        Btn.BackgroundColor3 = state and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(45, 45, 65)
        callback(state)
    end)
end

local function CreateSlider(parent, name, y, min, max, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.95, 0, 0, 40)
    Frame.Position = UDim2.new(0.025, 0, 0, y)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(210, 210, 210)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.Parent = Frame
    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(0.9, 0, 0, 5)
    Bar.Position = UDim2.new(0.05, 0, 0, 25)
    Bar.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    Bar.BorderSizePixel = 0
    Bar.Parent = Frame
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(0, 3)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(0, 160, 100)
    Fill.BorderSizePixel = 0
    Fill.Parent = Bar
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 3)
    local dragging = false
    Bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true end
    end)
    Bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + (max - min) * rel)
            Label.Text = name .. ": " .. val
            callback(val)
        end
    end)
end

local function CreateInput(parent, name, y, default, callback)
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0.95, 0, 0, 36)
    Frame.Position = UDim2.new(0.025, 0, 0, y)
    Frame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Frame.BorderSizePixel = 0
    Frame.Parent = parent
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.45, 0, 1, 0)
    Label.Position = UDim2.new(0.05, 0, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(210, 210, 210)
    Label.TextSize = 11
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Frame
    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0.45, 0, 0, 24)
    Box.Position = UDim2.new(0.5, 0, 0, 6)
    Box.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    Box.BorderSizePixel = 0
    Box.Text = tostring(default)
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.TextSize = 12
    Box.Font = Enum.Font.Gotham
    Box.Parent = Frame
    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
    Box.FocusLost:Connect(function()
        local num = tonumber(Box.Text)
        if num then callback(num) else Box.Text = tostring(default) end
    end)
end

local function CreateButton(parent, name, y, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(0.95, 0, 0, 30)
    Btn.Position = UDim2.new(0.025, 0, 0, y)
    Btn.BackgroundColor3 = Color3.fromRGB(55, 55, 80)
    Btn.BorderSizePixel = 0
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    Btn.TextSize = 12
    Btn.Font = Enum.Font.Gotham
    Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    Btn.MouseButton1Click:Connect(function() callback(Btn) end)
end

local function CreateSectionLabel(parent, name, y)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.95, 0, 0, 20)
    lbl.Position = UDim2.new(0.025, 0, 0, y)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.TextColor3 = Color3.fromRGB(0, 218, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = parent
end

-- ===== MENU CHÍNH =====
local MainMenu = Instance.new("Frame")
MainMenu.Size = UDim2.new(0, 480, 0, 400)
MainMenu.Position = UDim2.new(0, 20, 0, 60)
MainMenu.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainMenu.BorderSizePixel = 0
MainMenu.Active = true
MainMenu.Draggable = true
MainMenu.Parent = ScreenGui
Instance.new("UICorner", MainMenu).CornerRadius = UDim.new(0, 10)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
Title.BorderSizePixel = 0
Title.Text = "VHT HUB PVP"
Title.TextColor3 = Color3.fromRGB(0, 218, 255)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.Parent = MainMenu
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -70)
Sidebar.Position = UDim2.new(0, 0, 0, 45)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = MainMenu

local TabHolder = Instance.new("Frame")
TabHolder.Size = UDim2.new(1, -140, 1, -70)
TabHolder.Position = UDim2.new(0, 135, 0, 45)
TabHolder.BackgroundTransparency = 1
TabHolder.Parent = MainMenu

local Footer = Instance.new("TextLabel")
Footer.Size = UDim2.new(1, 0, 0, 25)
Footer.Position = UDim2.new(0, 0, 1, -25)
Footer.BackgroundTransparency = 1
Footer.Text = "Hoàng Trọng DEV"
Footer.TextColor3 = Color3.fromRGB(0, 218, 255)
Footer.TextSize = 13
Footer.Font = Enum.Font.GothamBold
Footer.Parent = MainMenu

local tabs = {}
local tabButtons = {}

local function RegisterTab(name)
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 4
    page.ScrollBarImageColor3 = Color3.fromRGB(0, 218, 255)
    page.CanvasSize = UDim2.new(0, 0, 0, 400)
    page.Visible = false
    page.Parent = TabHolder
    tabs[name] = page

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 30)
    btn.Position = UDim2.new(0, 5, 0, #tabButtons * 35)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(210, 210, 210)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    table.insert(tabButtons, btn)

    btn.MouseButton1Click:Connect(function()
        for n, p in pairs(tabs) do p.Visible = (n == name) end
        for _, b in ipairs(tabButtons) do
            b.BackgroundColor3 = (b == btn) and Color3.fromRGB(0, 160, 100) or Color3.fromRGB(35, 35, 50)
        end
    end)
    return page
end

-- ===== TAB MAIN =====
local MainTab = RegisterTab("MAIN")
local y = 5
CreateSectionLabel(MainTab, "SILENT AIM GUN", y); y = y + 22
CreateToggle(MainTab, "Silent Gun", y, function(v) Config.SilentGun = v end); y = y + 34
CreateToggle(MainTab, "Gun Team Check", y, function(v) Config.SilentGunTeamCheck = v end); y = y + 34
CreateSlider(MainTab, "Gun FOV", y, 50, 500, 200, function(v) Config.SilentGunFOV = v end); y = y + 44
CreateButton(MainTab, "Gun Target: FOV", y, function(btn)
    local modes = {"FOV", "Nearest", "LowestHP"}
    local idx = 1
    for i, m in ipairs(modes) do if m == Config.SilentGunTarget then idx = i break end end
    idx = idx % #modes + 1
    Config.SilentGunTarget = modes[idx]
    btn.Text = "Gun Target: " .. modes[idx]
end); y = y + 34

CreateSectionLabel(MainTab, "CAMERA AIM SKILL", y); y = y + 22
CreateToggle(MainTab, "Skill Aim", y, function(v) Config.SkillAim = v end); y = y + 34
CreateToggle(MainTab, "Skill Team Check", y, function(v) Config.SkillAimTeamCheck = v end); y = y + 34
CreateSlider(MainTab, "Skill FOV", y, 50, 500, 200, function(v) Config.SkillAimFOV = v end); y = y + 44
CreateSlider(MainTab, "Skill Smooth", y, 1, 100, 15, function(v) Config.SkillAimSmooth = v / 100 end); y = y + 44
CreateButton(MainTab, "Skill Target: FOV", y, function(btn)
    local modes = {"FOV", "Nearest", "LowestHP"}
    local idx = 1
    for i, m in ipairs(modes) do if m == Config.SkillAimTarget then idx = i break end end
    idx = idx % #modes + 1
    Config.SkillAimTarget = modes[idx]
    btn.Text = "Skill Target: " .. modes[idx]
end); y = y + 34
MainTab.CanvasSize = UDim2.new(0, 0, 0, y + 10)

-- ===== TAB ESP =====
local ESPTab = RegisterTab("ESP")
y = 5
CreateSectionLabel(ESPTab, "ESP PLAYER", y); y = y + 22
CreateToggle(ESPTab, "ESP Player", y, function(v) Config.ESPEnabled = v end); y = y + 34
CreateToggle(ESPTab, "ESP Box", y, function(v) Config.ESPBox = v end); y = y + 34
CreateToggle(ESPTab, "ESP Info", y, function(v) Config.ESPInfo = v end); y = y + 34
CreateToggle(ESPTab, "ESP Health", y, function(v) Config.ESPHealth = v end); y = y + 34
CreateToggle(ESPTab, "ESP Team Check", y, function(v) Config.ESPTeamCheck = v end); y = y + 34
CreateSlider(ESPTab, "ESP Max Distance", y, 100, 5000, 1500, function(v) Config.ESPMaxDistance = v end); y = y + 44
ESPTab.CanvasSize = UDim2.new(0, 0, 0, y + 10)

-- ===== TAB HITBOX =====
local HitboxTab = RegisterTab("HITBOX")
y = 5
CreateSectionLabel(HitboxTab, "HITBOX EXPANDER", y); y = y + 22
CreateToggle(HitboxTab, "Hitbox Expander", y, function(v) Config.HitboxEnabled = v end); y = y + 34
CreateToggle(HitboxTab, "Hitbox Team Check", y, function(v) Config.HitboxTeamCheck = v end); y = y + 34
CreateInput(HitboxTab, "Hitbox Size", y, 15, function(v) Config.HitboxSize = v end); y = y + 40
HitboxTab.CanvasSize = UDim2.new(0, 0, 0, y + 10)

-- ===== TAB EXTRA =====
local ExtraTab = RegisterTab("EXTRA")
y = 5
CreateSectionLabel(ExtraTab, "EXTRA", y); y = y + 22
CreateToggle(ExtraTab, "Show FOV Circle", y, function(v) Config.ShowFOV = v end); y = y + 34
ExtraTab.CanvasSize = UDim2.new(0, 0, 0, y + 10)

-- Mở tab MAIN mặc định
tabs["MAIN"].Visible = true
tabButtons[1].BackgroundColor3 = Color3.fromRGB(0, 160, 100)
-- ========== 5. HÀM TIỆN ÍCH ==========
local function GetRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(model)
    if not model or not model.Parent then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

-- ========== 6. TÌM MỤC TIÊU ==========
local function FindTarget(fov, teamCheck, mode)
    local root = GetRoot()
    if not root then return nil end
    mode = mode or "FOV"
    local center = Camera.ViewportSize / 2
    local best, bestScore = nil, math.huge

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and IsAlive(p.Character) then
            if teamCheck and p.Team == LP.Team then continue end
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hrp and hum then
                local score
                if mode == "Nearest" then
                    score = (root.Position - hrp.Position).Magnitude
                elseif mode == "LowestHP" then
                    score = hum.Health
                else
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then continue end
                    score = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if score > fov then continue end
                end
                if score < bestScore then
                    best, bestScore = hrp, score
                end
            end
        end
    end
    return best
end

-- ========== 7. SILENT AIM GUN ==========
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if Config.SilentGun and self == Mouse and (key == "Hit" or key == "Target") then
        local target = FindTarget(Config.SilentGunFOV, Config.SilentGunTeamCheck, Config.SilentGunTarget)
        if target then
            return CFrame.new(target.Position)
        end
    end
    return oldIndex(self, key)
end)

-- ========== 8. CAMERA AIM SKILL ==========
RunService.RenderStepped:Connect(function()
    if Config.SkillAim then
        local target = FindTarget(Config.SkillAimFOV, Config.SkillAimTeamCheck, Config.SkillAimTarget)
        if target then
            local newCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Config.SkillAimSmooth)
        end
    end
end)

-- ========== 9. ESP SYSTEM ==========
local ESPCache = {}

local function CreateESPForPlayer(player)
    if not player.Character then return end
    local char = player.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if ESPCache[player] then
        for _, v in pairs(ESPCache[player]) do
            if v and v.Parent then v:Destroy() end
        end
    end
    ESPCache[player] = {}

    local color = Color3.fromRGB(255, 50, 50)
    if player.Team == LP.Team then
        color = Color3.fromRGB(50, 255, 50)
    end

    if Config.ESPBox then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "ESPBox"
        box.Adornee = hrp
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = hrp.Size + Vector3.new(0.3, 0.3, 0.3)
        box.Transparency = 0.4
        box.Color3 = color
        box.Parent = ESPFolder
        table.insert(ESPCache[player], box)
    end

    if Config.ESPInfo or Config.ESPHealth then
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPInfo"
        billboard.Adornee = hrp
        billboard.Size = UDim2.new(0, 220, 0, 70)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Parent = ESPFolder
        table.insert(ESPCache[player], billboard)

        if Config.ESPInfo then
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 18)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = color
            nameLabel.TextStrokeTransparency = 0
            nameLabel.TextSize = 13
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.Parent = billboard

            local distLabel = Instance.new("TextLabel")
            distLabel.Name = "DistLabel"
            distLabel.Size = UDim2.new(1, 0, 0, 16)
            distLabel.Position = UDim2.new(0, 0, 0, 18)
            distLabel.BackgroundTransparency = 1
            distLabel.Text = "0m"
            distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            distLabel.TextStrokeTransparency = 0
            distLabel.TextSize = 11
            distLabel.Font = Enum.Font.Gotham
            distLabel.Parent = billboard
        end

        if Config.ESPHealth then
            local hpBg = Instance.new("Frame")
            hpBg.Name = "HPBg"
            hpBg.Size = UDim2.new(1, 0, 0, 8)
            hpBg.Position = UDim2.new(0, 0, 0, 38)
            hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            hpBg.BorderSizePixel = 0
            hpBg.Parent = billboard
            Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 3)

            local hpFill = Instance.new("Frame")
            hpFill.Name = "HPFill"
            hpFill.Size = UDim2.new(1, 0, 1, 0)
            hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            hpFill.BorderSizePixel = 0
            hpFill.Parent = hpBg
            Instance.new("UICorner", hpFill).CornerRadius = UDim.new(0, 3)

            local hpText = Instance.new("TextLabel")
            hpText.Name = "HPText"
            hpText.Size = UDim2.new(1, 0, 0, 14)
            hpText.Position = UDim2.new(0, 0, 0, 48)
            hpText.BackgroundTransparency = 1
            hpText.Text = "100/100"
            hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
            hpText.TextStrokeTransparency = 0
            hpText.TextSize = 11
            hpText.Font = Enum.Font.Gotham
            hpText.Parent = billboard
        end
    end
end

local function RemoveESPForPlayer(player)
    if ESPCache[player] then
        for _, v in pairs(ESPCache[player]) do
            if v and v.Parent then v:Destroy() end
        end
        ESPCache[player] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if not Config.ESPEnabled then return end
    local root = GetRoot()
    if not root then return end

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character and IsAlive(p.Character) then
            if Config.ESPTeamCheck and p.Team == LP.Team then
                RemoveESPForPlayer(p)
                continue
            end

            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then continue end

            local dist = (root.Position - hrp.Position).Magnitude
            if dist > Config.ESPMaxDistance then
                RemoveESPForPlayer(p)
                continue
            end

            if not ESPCache[p] then
                CreateESPForPlayer(p)
            end

            if ESPCache[p] then
                local billboard = ESPCache[p][2]
                if billboard and billboard.Parent then
                    local distLabel = billboard:FindFirstChild("DistLabel")
                    if distLabel then distLabel.Text = math.floor(dist) .. "m" end

                    local hpBg = billboard:FindFirstChild("HPBg")
                    if hpBg then
                        local hpFill = hpBg:FindFirstChild("HPFill")
                        local hpText = billboard:FindFirstChild("HPText")
                        if hpFill then
                            local ratio = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                            hpFill.Size = UDim2.new(ratio, 0, 1, 0)
                            if ratio > 0.6 then
                                hpFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                            elseif ratio > 0.3 then
                                hpFill.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
                            else
                                hpFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                            end
                        end
                        if hpText then
                            hpText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                        end
                    end
                end
            end
        else
            RemoveESPForPlayer(p)
        end
    end
end)

Players.PlayerRemoving:Connect(function(p) RemoveESPForPlayer(p) end)

task.spawn(function()
    while task.wait(0.5) do
        if not Config.ESPEnabled then
            for p, _ in pairs(ESPCache) do RemoveESPForPlayer(p) end
        end
    end
end)

-- ========== 10. HITBOX EXPANDER ==========
local OriginalSizes = {}

local function ExpandHitbox(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end
    local hrp = model.HumanoidRootPart
    if not OriginalSizes[model] then
        OriginalSizes[model] = hrp.Size
    end
    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
    hrp.Transparency = 0.7
    hrp.CanCollide = false
    hrp.Massless = true
end

local function ResetHitbox(model)
    if not model or not model:FindFirstChild("HumanoidRootPart") then return end
    local hrp = model.HumanoidRootPart
    if OriginalSizes[model] then
        hrp.Size = OriginalSizes[model]
        OriginalSizes[model] = nil
    end
    hrp.Transparency = 1
    hrp.CanCollide = false
end

task.spawn(function()
    while task.wait(0.2) do
        if Config.HitboxEnabled then
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LP and p.Character and IsAlive(p.Character) then
                    if Config.HitboxTeamCheck and p.Team == LP.Team then continue end
                    ExpandHitbox(p.Character)
                end
            end
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character then ResetHitbox(p.Character) end
            end
        end
    end
end)

-- ========== 11. FOV CIRCLE ==========
local FOVCircle = Instance.new("Frame")
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.Visible = false
FOVCircle.Parent = ScreenGui
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1, 0)
local FOVStroke = Instance.new("UIStroke")
FOVStroke.Color = Color3.fromRGB(0, 255, 100)
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.3
FOVStroke.Parent = FOVCircle

RunService.RenderStepped:Connect(function()
    if Config.ShowFOV and (Config.SilentGun or Config.SkillAim) then
        FOVCircle.Visible = true
        local fov = Config.SilentGun and Config.SilentGunFOV or Config.SkillAimFOV
        FOVCircle.Size = UDim2.new(0, fov * 2, 0, fov * 2)
        FOVCircle.Position = UDim2.new(0.5, -fov, 0.5, -fov)
    else
        FOVCircle.Visible = false
    end
end)

-- ========== 12. THÔNG BÁO ==========
StarterGui:SetCore("SendNotification", {
    Title = "VHT HUB PVP",
    Text = "Script đã sẵn sàng!",
    Duration = 5
})

print("[VHT HUB PVP by Hoàng Trọng DEV] Loaded!")

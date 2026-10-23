-- 3v3 Arena Ultimate VIP Stealth Hub (Ultimate Team Fix Edition)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- الحفاظ على السكربت وتشغيله تلقائياً عند الانتقال بين المابات واللوبي (Teleport Fix)
pcall(function()
    if queue_on_teleport then
        queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/vekokoop/new-v5/refs/heads/main/script.lua"))()')
    end
end)

----------------------------------------------------
-- 1. ABSOLUTE CLEANUP (PREVENT OVERLAP)
----------------------------------------------------
if _G.Arena3v3Connections then
    for _, conn in pairs(_G.Arena3v3Connections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
end
_G.Arena3v3Connections = {}

if CoreGui:FindFirstChild("Arena3v3VIPHub") then
    CoreGui.Arena3v3VIPHub:Destroy()
end

for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Highlight") and v.Name == "VIP_ESP_Highlight" then
        v:Destroy()
    end
end

----------------------------------------------------
-- 2. ADVANCED ARENA TEAM & ENEMY DETECTOR (FIXED)
----------------------------------------------------
local function IsEnemy(p)
    if p == LocalPlayer then return false end
    
    -- 1. فحص التيم الرسمي إن وجد
    if LocalPlayer.Team and p.Team then
        return p.Team ~= LocalPlayer.Team
    end
    
    -- 2. فحص مجلدات الفريق في الـ Workspace
    if LocalPlayer.Character and p.Character then
        local myParent = LocalPlayer.Character.Parent
        local pParent = p.Character.Parent
        if myParent and pParent and myParent ~= workspace and pParent ~= workspace then
            return myParent ~= pParent
        end
    end
    
    -- 3. فحص الـ Attributes المخصصة للماب
    local localAttr = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("Side") or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("Team"))
    local pAttr = p:GetAttribute("Team") or p:GetAttribute("Side") or (p.Character and p.Character:GetAttribute("Team"))
    if localAttr and pAttr then
        return localAttr ~= pAttr
    end
    
    -- 4. فحص لون الفريق (TeamColor)
    if LocalPlayer.TeamColor and p.TeamColor then
        if LocalPlayer.TeamColor ~= BrickColor.new("Medium stone grey") and p.TeamColor ~= BrickColor.new("Medium stone grey") then
            return LocalPlayer.TeamColor ~= p.TeamColor
        end
    end
    
    -- 5. فحص قيم الـ leaderstats إن وجدت
    local localStats = LocalPlayer:FindFirstChild("leaderstats")
    local pStats = p:FindFirstChild("leaderstats")
    if localStats and pStats then
        local lTeam = localStats:FindFirstChild("Team") or localStats:FindFirstChild("Side")
        local pTeam = pStats:FindFirstChild("Team") or pStats:FindFirstChild("Side")
        if lTeam and pTeam then
            return lTeam.Value ~= pTeam.Value
        end
    end
    
    return true
end

----------------------------------------------------
-- 3. CREATE UI ELEMENTS
----------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Arena3v3VIPHub"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false

-- Floating VIP Button (Touch Friendly)
local ToggleButton = Instance.new("TextButton")
ToggleButton.Name = "ToggleButton"
ToggleButton.Parent = ScreenGui
ToggleButton.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
ToggleButton.Position = UDim2.new(0.03, 0, 0.2, 0)
ToggleButton.Size = UDim2.new(0, 55, 0, 55)
ToggleButton.Font = Enum.Font.FredokaOne
ToggleButton.Text = "👑 VIP"
ToggleButton.TextColor3 = Color3.fromRGB(255, 215, 0)
ToggleButton.TextSize = 16
ToggleButton.Active = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

-- Main VIP Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 22)
MainFrame.Position = UDim2.new(0.15, 0, 0.15, 0)
MainFrame.Size = UDim2.new(0, 420, 0, 360)
MainFrame.Visible = true
MainFrame.Active = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Draggable Header
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = MainFrame
TitleLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
TitleLabel.Size = UDim2.new(1, 0, 0, 45)
TitleLabel.Font = Enum.Font.FredokaOne
TitleLabel.Text = "  👑 3v3 Arena VIP Hub [v5 Fixed]"
TitleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
TitleLabel.TextSize = 15
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", TitleLabel).CornerRadius = UDim.new(0, 12)

----------------------------------------------------
-- 4. TOUCH & DRAG MECHANICS (iPad Safe)
----------------------------------------------------
local function MakeDraggable(guiObject)
    local dragging, dragInput, dragStart, startPos
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(MainFrame)
MakeDraggable(ToggleButton)

local lastToggleTime = 0
ToggleButton.MouseButton1Click:Connect(function()
    if os.clock() - lastToggleTime > 0.2 then
        lastToggleTime = os.clock()
        MainFrame.Visible = not MainFrame.Visible
    end
end)

----------------------------------------------------
-- 5. SETTINGS & FOV
----------------------------------------------------
local Settings = {
    Aimbot = false,
    FOV = 120,
    ESP = false
}

local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = Settings.FOV
FOVCircle.Color = Color3.fromRGB(255, 215, 0)
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Transparency = 0.8
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

----------------------------------------------------
-- 6. UI CONTROLS BUILDER
----------------------------------------------------
local function CreateButton(name, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = MainFrame
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.Size = UDim2.new(0.9, 0, 0, 42)
    btn.Font = Enum.Font.SourceSansBold
    btn.Text = name .. ": [OFF]"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local state = false
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 100) or Color3.fromRGB(35, 35, 50)
        btn.Text = name .. (state and ": [ON]" or ": [OFF]")
        callback(state)
    end)
    return btn
end

----------------------------------------------------
-- 7. DYNAMIC ESP (GREEN TEAM / RED ENEMIES)
----------------------------------------------------
local espHighlights = {}

local function ApplyESPToChar(player, char)
    if not Settings.ESP or player == LocalPlayer or not char then return end
    
    if espHighlights[player] then
        espHighlights[player]:Destroy()
        espHighlights[player] = nil
    end

    local hl = Instance.new("Highlight")
    hl.Name = "VIP_ESP_Highlight"
    hl.Parent = char
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    if IsEnemy(player) then
        hl.FillColor = Color3.fromRGB(255, 50, 50) -- أحمر للخصم
    else
        hl.FillColor = Color3.fromRGB(0, 255, 100) -- أخضر لتيمك
    end
    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
    espHighlights[player] = hl
end

local function RefreshAllESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            ApplyESPToChar(player, player.Character)
        end
    end
end

local pAddedConn = Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if Settings.ESP then ApplyESPToChar(player, char) end
    end)
end)
table.insert(_G.Arena3v3Connections, pAddedConn)

for _, p in pairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        p.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if Settings.ESP then ApplyESPToChar(p, char) end
        end)
    end
end

local espRenderConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        if Settings.ESP then
            RefreshAllESP()
            for player, hl in pairs(espHighlights) do
                if not player.Parent or not player.Character or not player.Character:FindFirstChild("Humanoid") or player.Character.Humanoid.Health <= 0 then
                    if hl then hl:Destroy() end
                    espHighlights[player] = nil
                end
            end
        end
    end)
end)
table.insert(_G.Arena3v3Connections, espRenderConn)

----------------------------------------------------
-- 8. AIMBOT (STRICT ENEMY ONLY LOCK)
----------------------------------------------------
local function GetClosestEnemy()
    local target, shortest = nil, Settings.FOV
    for _, p in pairs(Players:GetPlayers()) do
        if IsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
            local char = p.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local head = char.Head
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                    if dist < shortest then
                        shortest = dist
                        target = head
                    end
                end
            end
        end
    end
    return target
end

local aimConn = RunService.RenderStepped:Connect(function()
    pcall(function()
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = Settings.FOV
        if Settings.Aimbot then
            local t = GetClosestEnemy()
            if t then
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, t.Position)
            end
        end
    end)
end)
table.insert(_G.Arena3v3Connections, aimConn)

----------------------------------------------------
-- 9. UI CONTROLS & FOV SLIDER CONTROLS
----------------------------------------------------
CreateButton("ESP Wallhack (Green Team / Red Enemy)", 60, function(v)
    Settings.ESP = v
    if v then
        RefreshAllESP()
    else
        for _, hl in pairs(espHighlights) do if hl then hl:Destroy() end end
        espHighlights = {}
    end
end)

CreateButton("Aimbot (Strict Enemy Head Lock)", 115, function(v)
    Settings.Aimbot = v
    FOVCircle.Visible = v
end)

local FOVFrame = Instance.new("Frame")
FOVFrame.Parent = MainFrame
FOVFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 38)
FOVFrame.Position = UDim2.new(0.05, 0, 0, 170)
FOVFrame.Size = UDim2.new(0.9, 0, 0, 50)
Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(0, 8)

local FOVLabel = Instance.new("TextLabel")
FOVLabel.Parent = FOVFrame
FOVLabel.BackgroundTransparency = 1
FOVLabel.Position = UDim2.new(0.05, 0, 0, 0)
FOVLabel.Size = UDim2.new(0.4, 0, 1, 0)
FOVLabel.Font = Enum.Font.SourceSansBold
FOVLabel.Text = "FOV Size: " .. tostring(Settings.FOV)
FOVLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
FOVLabel.TextSize = 15
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left

local MinusBtn = Instance.new("TextButton")
MinusBtn.Parent = FOVFrame
MinusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
MinusBtn.Position = UDim2.new(0.5, 0, 0.15, 0)
MinusBtn.Size = UDim2.new(0, 40, 0, 35)
MinusBtn.Font = Enum.Font.FredokaOne
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinusBtn.TextSize = 20
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Parent = FOVFrame
PlusBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
PlusBtn.Position = UDim2.new(0.75, 0, 0.15, 0)
PlusBtn.Size = UDim2.new(0, 40, 0, 35)
PlusBtn.Font = Enum.Font.FredokaOne
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
PlusBtn.TextSize = 20
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

MinusBtn.MouseButton1Click:Connect(function()
    if Settings.FOV > 30 then
        Settings.FOV = Settings.FOV - 15
        FOVCircle.Radius = Settings.FOV
        FOVLabel.Text = "FOV Size: " .. tostring(Settings.FOV)
    end
end)

PlusBtn.MouseButton1Click:Connect(function()
    if Settings.FOV < 400 then
        Settings.FOV = Settings.FOV + 15
        FOVCircle.Radius = Settings.FOV
        FOVLabel.Text = "FOV Size: " .. tostring(Settings.FOV)
    end
end)

print("3v3 Arena VIP Hub v5 Fixed & Loaded!")

--[[
    AETHERIUS HUB PRO // Professional Edition (Natural Poses & New Trolls)
    UI Framework: Fluent UI Library
    Target Exec: Delta / Hydrogen / Wave / Arceus X
]]--

-- 1. Carregamento da UI Library (Fluent)
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

-- 2. Serviços e Variáveis Globais
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local Camera = Workspace.CurrentCamera
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local SelectedTargetName = ""
local ActiveTrollConnection = nil
local InfJumpConnection = nil
local CurrentAlignPos = nil
local CurrentAlignRot = nil
local Attachment0 = nil
local Attachment1 = nil

-- Configurações
local Settings = {
    OrbitRadius = 4,
    OrbitSpeed = 0.04,
    BackpackDistance = 0.85,
    WalkSpeed = 35,
}

-- 3. Criação da Janela Principal (Tema Preto / Dark)
local Window = Fluent:CreateWindow({
    Title = "MushYO // AETHERIUS HUB PRO",
    SubTitle = "by Aetherius Team",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 380),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightControl
})

-- Botão Flutuante (Cogumelo 🍄) Fixo e Visível na Tela
local ScreenGuiToggle = Instance.new("ScreenGui")
ScreenGuiToggle.Name = "AetheriusFloatingToggle"
ScreenGuiToggle.ResetOnSpawn = false
ScreenGuiToggle.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGuiToggle)
        ScreenGuiToggle.Parent = game:GetService("CoreGui")
    else
        ScreenGuiToggle.Parent = PlayerGui
    end
end)
if not ScreenGuiToggle.Parent then ScreenGuiToggle.Parent = PlayerGui end

local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "ToggleBtn"
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.02, 0, 0.4, 0)
OpenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
OpenBtn.Text = "🍄"
OpenBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
OpenBtn.TextSize = 24
OpenBtn.Font = Enum.Font.GothamBold
OpenBtn.Active = true
OpenBtn.Draggable = true
OpenBtn.Visible = true
OpenBtn.Parent = ScreenGuiToggle

local OpenCorner = Instance.new("UICorner")
OpenCorner.CornerRadius = UDim.new(0, 12)
OpenCorner.Parent = OpenBtn

local OpenStroke = Instance.new("UIStroke")
OpenStroke.Color = Color3.fromRGB(0, 200, 255)
OpenStroke.Thickness = 2
OpenStroke.Parent = OpenBtn

local isHubVisible = true
OpenBtn.MouseButton1Click:Connect(function()
    isHubVisible = not isHubVisible
    pcall(function()
        if Window.DialogHolder and Window.DialogHolder.Parent then
            Window.DialogHolder.Parent.Visible = isHubVisible
        elseif Window.Root then
            Window.Root.Visible = isHubVisible
        end
    end)
    if isHubVisible then
        OpenBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    else
        OpenBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 100)
    end
end)

-- Abas
local Tabs = {
    Home = Window:AddTab({ Title = "Home", Icon = "home" }),
    Target = Window:AddTab({ Title = "Target & Exploits", Icon = "target" }),
    Visuals = Window:AddTab({ Title = "Visuals (ESP)", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc / Character", Icon = "user" }),
    Settings = Window:AddTab({ Title = "Configurações", Icon = "settings" })
}

-- --- ABA HOME ---
Tabs.Home:AddParagraph({
    Title = "Bem-vindo ao Aetherius Pro, " .. LocalPlayer.DisplayName .. "!",
    Content = "• Arraste o botão de cogumelo (🍄) pela tela.\n• Toque nele para abrir ou fechar o Hub.\n• Selecione um jogador na aba 'Target & Exploits'."
})

-- --- FUNÇÕES UTILITÁRIAS & FÍSICA ---
local function GetPlayerList()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p.Name .. " (" .. p.DisplayName .. ")")
        end
    end
    if #list == 0 then table.insert(list, "Nenhum Jogador Encontrado") end
    return list
end

local function GetTargetPlayer()
    if SelectedTargetName == "" or SelectedTargetName == "Nenhum Jogador Encontrado" then return nil end
    local cleanName = string.split(SelectedTargetName, " (")[1]
    return Players:FindFirstChild(cleanName)
end

local function GetTargetPart(char)
    if not char then return nil end
    return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function ClearPhysics()
    if ActiveTrollConnection then
        if typeof(ActiveTrollConnection) == "RBXScriptConnection" then
            ActiveTrollConnection:Disconnect()
        end
        ActiveTrollConnection = nil
    end
    if CurrentAlignPos then CurrentAlignPos:Destroy() CurrentAlignPos = nil end
    if CurrentAlignRot then CurrentAlignRot:Destroy() CurrentAlignRot = nil end
    if Attachment0 then Attachment0:Destroy() Attachment0 = nil end
    if Attachment1 then Attachment1:Destroy() Attachment1 = nil end

    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Sit = false
            hum.PlatformStand = false
        end
        if hrp then
            for _, v in pairs(char:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = true end
            end
        end
    end
    Camera.CameraSubject = char and char:FindFirstChildOfClass("Humanoid")
end

local function SetupAlignPhysics(myHRP, targetPart)
    Attachment0 = Instance.new("Attachment", myHRP)
    Attachment1 = Instance.new("Attachment", targetPart)

    CurrentAlignPos = Instance.new("AlignPosition")
    CurrentAlignPos.Attachment0 = Attachment0
    CurrentAlignPos.Attachment1 = Attachment1
    CurrentAlignPos.MaxForce = 999999
    CurrentAlignPos.MaxVelocity = 200
    CurrentAlignPos.Responsiveness = 200
    CurrentAlignPos.Parent = myHRP

    CurrentAlignRot = Instance.new("AlignOrientation")
    CurrentAlignRot.Attachment0 = Attachment0
    CurrentAlignRot.Attachment1 = Attachment1
    CurrentAlignRot.MaxTorque = 999999
    CurrentAlignRot.Responsiveness = 200
    CurrentAlignRot.Parent = myHRP
end

-- --- ABA TARGET & EXPLOITS ---
local PlayerDropdown = Tabs.Target:AddDropdown("TargetSelect", {
    Title = "Selecione o Player Alvo",
    Values = GetPlayerList(),
    Multi = false,
    Default = 1,
})

PlayerDropdown:OnChanged(function(Value)
    SelectedTargetName = Value
end)

Tabs.Target:AddButton({
    Title = "🔄 Atualizar Lista de Jogadores",
    Callback = function()
        PlayerDropdown:SetValues(GetPlayerList())
        Fluent:Notify({ Title = "Lista Atualizada", Content = "Jogadores do servidor recarregados.", Duration = 3 })
    end
})

Players.PlayerAdded:Connect(function() PlayerDropdown:SetValues(GetPlayerList()) end)
Players.PlayerRemoving:Connect(function() PlayerDropdown:SetValues(GetPlayerList()) end)

Tabs.Target:AddSection("Troll Features (Poses Naturais & Visíveis para Todos)")

-- Toggle: Homem Aranha
local SpiderToggle = Tabs.Target:AddToggle("SpiderMode", { Title = "🕷️ Homem-Aranha (De Cabeça p/ Baixo)", Default = false })
SpiderToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetHead = target.Character:FindFirstChild("Head")
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetHead and hum then
                hum.PlatformStand = true
                SetupAlignPhysics(myHRP, targetHead)
                Attachment1.CFrame = CFrame.new(0, -1.2, 0) * CFrame.Angles(0, 0, math.rad(180))

                ActiveTrollConnection = RunService.Stepped:Connect(function()
                    for _, part in pairs(myChar:GetChildren()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                end)
            end
        else
            SpiderToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle: Orbitar em Meditação
local OrbitToggle = Tabs.Target:AddToggle("OrbitMode", { Title = "🧘 Orbitar em Meditação (360°)", Default = false })
local orbitAngle = 0
OrbitToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetTorso = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetTorso and hum then
                hum.Sit = true
                SetupAlignPhysics(myHRP, targetTorso)

                ActiveTrollConnection = RunService.Heartbeat:Connect(function()
                    if target.Character and targetTorso and myHRP then
                        orbitAngle = orbitAngle + Settings.OrbitSpeed
                        local radius = Settings.OrbitRadius
                        local offset = Vector3.new(math.cos(orbitAngle) * radius, 1.0, math.sin(orbitAngle) * radius)
                        Attachment1.CFrame = CFrame.new(offset, targetTorso.Position)
                    else
                        OrbitToggle:SetValue(false)
                    end
                end)
            end
        else
            OrbitToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle: Mochila Encolhida
local BackpackToggle = Tabs.Target:AddToggle("BackpackMode", { Title = "🎒 Mochila Encolhida (Nas Costas)", Default = false })
BackpackToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetTorso = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetTorso and hum then
                hum.Sit = true
                SetupAlignPhysics(myHRP, targetTorso)
                Attachment1.CFrame = CFrame.new(0, 0.2, Settings.BackpackDistance) * CFrame.Angles(0, math.rad(180), 0)
            end
        else
            BackpackToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle: Carrossel Humano (Tornado)
local TornadoToggle = Tabs.Target:AddToggle("TornadoMode", { Title = "🎠 Carrossel Humano (Tornado Espiral)", Default = false })
local tornadoAngle = 0
TornadoToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetTorso = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetTorso and hum then
                hum.Sit = true
                SetupAlignPhysics(myHRP, targetTorso)

                ActiveTrollConnection = RunService.Heartbeat:Connect(function()
                    if target.Character and targetTorso and myHRP then
                        tornadoAngle = tornadoAngle + 0.08
                        local tornadoHeight = math.sin(tick() * 4) * 1.5
                        local radius = 3.5
                        local offset = Vector3.new(math.cos(tornadoAngle) * radius, 0.8 + tornadoHeight, math.sin(tornadoAngle) * radius)
                        Attachment1.CFrame = CFrame.new(offset, targetTorso.Position)
                    else
                        TornadoToggle:SetValue(false)
                    end
                end)
            end
        else
            TornadoToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle: Encarar Cara a Cara (Sósia)
local MirrorToggle = Tabs.Target:AddToggle("MirrorMode", { Title = "🪞 Encarar Cara a Cara (Sósia Fixo)", Default = false })
MirrorToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetHRP = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and hum then
                hum.PlatformStand = false

                ActiveTrollConnection = RunService.Heartbeat:Connect(function()
                    if target.Character and targetHRP and myHRP then
                        myHRP.Velocity = Vector3.zero
                        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, math.rad(180), 0)
                    else
                        MirrorToggle:SetValue(false)
                    end
                end)
            end
        else
            MirrorToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- --- NOVAS OPÇÕES DE TROLL ---

-- Toggle 1: Carona nas Costas (Piggyback) [NOVO]
local PiggyToggle = Tabs.Target:AddToggle("PiggyMode", { Title = "🐎 Carona nas Costas (Piggyback)", Default = false })
PiggyToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetTorso = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetTorso and hum then
                hum.Sit = true -- Fica sentado perfeitamente montado nas costas
                SetupAlignPhysics(myHRP, targetTorso)
                -- Encaixa bem alto nas costas do alvo, virado para frente junto com ele
                Attachment1.CFrame = CFrame.new(0, 1.2, 0.2) * CFrame.Angles(0, 0, 0)
            end
        else
            PiggyToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle 2: Surfista de Cabeça (Head Surf) [NOVO]
local SurfToggle = Tabs.Target:AddToggle("SurfMode", { Title = "🛹 Surfista de Cabeça (Em cima dele)", Default = false })
SurfToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetHead = target.Character:FindFirstChild("Head") or GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetHead and hum then
                hum.PlatformStand = false
                SetupAlignPhysics(myHRP, targetHead)
                -- Fica em pé bem em cima da cabeça do jogador
                Attachment1.CFrame = CFrame.new(0, 2.2, 0) * CFrame.Angles(0, 0, 0)
            end
        else
            SurfToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Toggle 3: Sombra Zumbi (Colado Atrás Passinho a Passinho) [NOVO]
local ZombieToggle = Tabs.Target:AddToggle("ZombieMode", { Title = "🧟 Sombra Zumbi (Grudado Atrás)", Default = false })
ZombieToggle:OnChanged(function(state)
    ClearPhysics()
    if state then
        local target = GetTargetPlayer()
        local myChar = LocalPlayer.Character
        if target and target.Character and myChar and myChar:FindFirstChild("HumanoidRootPart") then
            local targetHRP = GetTargetPart(target.Character)
            local myHRP = myChar.HumanoidRootPart
            local hum = myChar:FindFirstChildOfClass("Humanoid")
            
            if targetHRP and hum then
                hum.PlatformStand = false

                ActiveTrollConnection = RunService.Heartbeat:Connect(function()
                    if target.Character and targetHRP and myHRP then
                        myHRP.Velocity = Vector3.zero
                        -- Segue milimetricamente colado nas costas do alvo
                        myHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, 1.2)
                    else
                        ZombieToggle:SetValue(false)
                    end
                end)
            end
        else
            ZombieToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Jogador alvo não encontrado.", Duration = 3 })
        end
    end
end)

-- Sliders
local OrbitRadiusSlider = Tabs.Target:AddSlider("OrbitRadius", { Title = "Raio do Orbitar", Default = 4, Min = 2, Max = 15, Rounding = 1 })
OrbitRadiusSlider:OnChanged(function(Value) Settings.OrbitRadius = Value end)

local BackpackDistSlider = Tabs.Target:AddSlider("BackpackDist", { Title = "Distância da Mochila", Default = 0.85, Min = 0.3, Max = 3, Rounding = 2 })
BackpackDistSlider:OnChanged(function(Value) 
    Settings.BackpackDistance = Value 
    if Attachment1 and BackpackToggle.Value then
        Attachment1.CFrame = CFrame.new(0, 0.2, Settings.BackpackDistance) * CFrame.Angles(0, math.rad(180), 0)
    end
end)

-- --- ABA VISUALS (ESP) ---
local ESPHighlight = nil
local ESPToggle = Tabs.Visuals:AddToggle("ESPToggle", { Title = "Ativar Highlight ESP no Alvo", Default = false })

ESPToggle:OnChanged(function(state)
    if ESPHighlight then ESPHighlight:Destroy() ESPHighlight = nil end
    if state then
        local target = GetTargetPlayer()
        if target and target.Character then
            ESPHighlight = Instance.new("Highlight")
            ESPHighlight.Name = "AetheriusESP"
            ESPHighlight.FillColor = Color3.fromRGB(0, 200, 255)
            ESPHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
            ESPHighlight.FillTransparency = 0.5
            ESPHighlight.Parent = target.Character
            Fluent:Notify({ Title = "ESP Ativado", Content = "Destacando: " .. target.Name, Duration = 3 })
        else
            ESPToggle:SetValue(false)
            Fluent:Notify({ Title = "Erro", Content = "Selecione um alvo válido.", Duration = 3 })
        end
    end
end)

-- --- ABA MISC ---
local SpeedSlider = Tabs.Misc:AddSlider("SpeedBoost", { Title = "Velocidade de Caminhada (WalkSpeed)", Default = 16, Min = 16, Max = 150, Rounding = 0 })
SpeedSlider:OnChanged(fu

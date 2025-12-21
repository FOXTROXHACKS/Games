Speed = 60 
FARMTOGGLE = true


local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Vim = game:GetService("VirtualInputManager")

local player = Players.LocalPlayer
local currentTween = nil 

-- === LIMPIEZA ===
if CoreGui:FindFirstChild("ChristmasCoreFarm") then
    CoreGui.ChristmasCoreFarm:Destroy()
end

-- === CONFIGURACIÓN ===
local VELOCIDAD = Speed 
local autoFarmActive = FARMTOGGLE
local moviendo = false
local notifiedFinished = false 
local waitingForStart = false

-- === INTERFAZ ===
local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "ChristmasCoreFarm"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 220, 0, 135)
frame.Position = UDim2.new(0.5, -110, 0.2, 0)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
frame.Draggable = true 
Instance.new("UICorner", frame)

local statusLabel = Instance.new("TextLabel", frame)
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Text = "Status: Ready"
statusLabel.TextColor3 = Color3.new(1,1,1)
statusLabel.BackgroundTransparency = 1
statusLabel.TextSize = 13
statusLabel.Font = Enum.Font.GothamMedium

local btnOnce = Instance.new("TextButton", frame)
btnOnce.Text = "Collect Once"
btnOnce.Size = UDim2.new(0, 200, 0, 35)
btnOnce.Position = UDim2.new(0, 10, 0, 40)
btnOnce.BackgroundColor3 = Color3.fromRGB(0, 100, 180)
btnOnce.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", btnOnce)

local btnAuto = Instance.new("TextButton", frame)
btnAuto.Text = "AutoFarm: OFF"
btnAuto.Size = UDim2.new(0, 200, 0, 35)
btnAuto.Position = UDim2.new(0, 10, 0, 85)
btnAuto.BackgroundColor3 = Color3.fromRGB(120, 30, 30)
btnAuto.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", btnAuto)

-- === FUNCIONES DE APOYO ===

local function notify(msg)
    statusLabel.Text = "Status: " .. msg
end

local function checkHealth()
    local char = player.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if hum then
        if hum.Health < 30 then
            notify("Low health")
            task.wait(2)
            Vim:SendMouseButtonEvent(500, 500, 0, true, game, 0)
            task.wait(0.1)
            Vim:SendMouseButtonEvent(500, 500, 0, false, game, 0)
            return false
        end
    end
    return true
end

local function identificarEstructura()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil, nil, "Map not found" end
    local fGifts, fTrees = nil, nil
    for _, eventFolder in ipairs(map:GetChildren()) do
        for _, subFolder in ipairs(eventFolder:GetChildren()) do
            if subFolder:FindFirstChild("GiftHandle", true) then fGifts = subFolder end
            if subFolder:FindFirstChild("ChristmasTree", true) then fTrees = subFolder end
        end
        if fGifts or fTrees then break end 
    end
    if not fGifts then return nil, fTrees, "There's no gifts" end
    if not fTrees then return fGifts, nil, "Tree wasn't found" end
    return fGifts, fTrees, nil
end

local function obtenerArbolMasCercano(carpetaTrees)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not carpetaTrees then return nil end
    local arbolCercano, distMin = nil, math.huge
    for _, arbol in ipairs(carpetaTrees:GetChildren()) do
        if (arbol:IsA("Model") or arbol:IsA("BasePart")) and arbol.Name ~= "Restrictor" then
            local dist = (hrp.Position - arbol:GetPivot().Position).Magnitude
            if dist < distMin then distMin = dist; arbolCercano = arbol end
        end
    end
    return arbolCercano
end

local function moverA(objetivo, itemClave)
    local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false, "No RootPart" end
    local punto = objetivo:FindFirstChild(itemClave, true) or objetivo
    local targetCF = punto:GetPivot()
    local dist = (hrp.Position - targetCF.Position).Magnitude
    
    currentTween = TweenService:Create(hrp, TweenInfo.new(dist / VELOCIDAD, Enum.EasingStyle.Linear), {
        CFrame = targetCF + Vector3.new(0, 4, 0)
    })
    currentTween:Play()
    return true, currentTween
end

-- === CICLO PRINCIPAL ===

local function ciclo(esAuto)
    if moviendo or waitingForStart then return end
    if not checkHealth() then return end 

    local cGifts, cTrees, err = identificarEstructura()
    
    if err or not cGifts or #cGifts:GetChildren() == 0 then 
        notify("Waiting for round...")
        notifiedFinished = true
        return 
    end

    if esAuto and notifiedFinished and not waitingForStart then
        waitingForStart = true
        for i = 40, 1, -1 do
            if not autoFarmActive then break end
            notify("Starting in: " .. i .. "s")
            task.wait(1)
        end
        waitingForStart = false
        notifiedFinished = false
    end

    if not autoFarmActive and esAuto then 
        notify("Off")
        return 
    end

    local regalo = nil
    for _, v in ipairs(cGifts:GetChildren()) do
        if (v:IsA("Model") or v:IsA("BasePart")) and v.Name ~= "Restrictor" then
            regalo = v break
        end
    end
    
    if not regalo then return end

    moviendo = true
    notify("Going to Gift...")
    local ok1, res1 = moverA(regalo, "GiftHandle")
    if ok1 then 
        while res1.PlaybackState == Enum.PlaybackState.Playing do
            if esAuto and not autoFarmActive then res1:Cancel(); moviendo = false; notify("Off"); return end
            if not checkHealth() then res1:Cancel(); moviendo = false; return end
            task.wait(0.1)
        end
    end
    
    task.wait(0.5)
    if esAuto and not autoFarmActive then moviendo = false; notify("Off"); return end
    
    notify("Collecting Gift")
    Vim:SendMouseButtonEvent(500, 500, 0, true, game, 0)
    task.wait(0.1)
    Vim:SendMouseButtonEvent(500, 500, 0, false, game, 0)
    task.wait(1.5)
    
    local arbolDestino = obtenerArbolMasCercano(cTrees)
    if arbolDestino then
        notify("Going to closest Tree...")
        local ok2, tw2 = moverA(arbolDestino, "ChristmasTree")
        if ok2 then 
            while tw2.PlaybackState == Enum.PlaybackState.Playing do
                if esAuto and not autoFarmActive then tw2:Cancel(); moviendo = false; notify("Off"); return end
                if not checkHealth() then tw2:Cancel(); moviendo = false; return end
                task.wait(0.1)
            end
            notify("You've collected a gift.")
            if not esAuto then notifiedFinished = false end
        end
    else
        notify("Tree wasn't found")
    end
    
    moviendo = false
end

-- === EVENTOS ===
btnOnce.MouseButton1Click:Connect(function()
    task.spawn(function()
        ciclo(false)
    end)
end)

btnAuto.MouseButton1Click:Connect(function()
    autoFarmActive = not autoFarmActive
    notifiedFinished = false 
    waitingForStart = false
    
    if not autoFarmActive then
        if currentTween then currentTween:Cancel() end
        moviendo = false
        waitingForStart = false
        notify("Off") -- Aquí forzamos el estado a Off inmediatamente
    else
        notify("Ready")
    end
    
    btnAuto.Text = autoFarmActive and "AutoFarm: ON" or "AutoFarm: OFF"
    btnAuto.BackgroundColor3 = autoFarmActive and Color3.fromRGB(30, 120, 30) or Color3.fromRGB(120, 30, 30)
end)

task.spawn(function()
    while screenGui.Parent do
        if autoFarmActive and not moviendo then 
            ciclo(true) 
        end
        task.wait(1) 
    end
end)
-- === CONFIGURACIÓN DE INTERFAZ ===
local CoreGui = game:GetService("CoreGui")

-- Limpieza si ya existe
if CoreGui:FindFirstChild("GiftCounterUI") then
    CoreGui.GiftCounterUI:Destroy()
end

local screenGui = Instance.new("ScreenGui", CoreGui)
screenGui.Name = "GiftCounterUI"

local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 150, 0, 80)
frame.Position = UDim2.new(0.5, -75, 0.05, 0) -- Aparece arriba al centro
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Active = true
frame.Draggable = true 
Instance.new("UICorner", frame)

local counterLabel = Instance.new("TextLabel", frame)
counterLabel.Size = UDim2.new(1, 0, 0, 40)
counterLabel.Position = UDim2.new(0, 0, 0, 5)
counterLabel.Text = "Gifts: 0/0"
counterLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
counterLabel.BackgroundTransparency = 1
counterLabel.TextSize = 18
counterLabel.Font = Enum.Font.GothamBold

local btnScan = Instance.new("TextButton", frame)
btnScan.Text = "SCAN ROUND"
btnScan.Size = UDim2.new(0, 130, 0, 25)
btnScan.Position = UDim2.new(0, 10, 0, 45)
btnScan.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
btnScan.TextColor3 = Color3.new(1, 1, 1)
btnScan.TextSize = 12
btnScan.Font = Enum.Font.GothamMedium
Instance.new("UICorner", btnScan)

-- === LÓGICA DE CONTEO ===
local totalMax = 0
local currentFolder = nil

local function getGiftsFolder()
    local map = workspace:FindFirstChild("Map")
    if not map then return nil end
    
    for _, eventFolder in ipairs(map:GetChildren()) do
        for _, sub in ipairs(eventFolder:GetChildren()) do
            -- Buscamos por el item clave que ya conocemos
            if sub:FindFirstChild("GiftHandle", true) then
                return sub
            end
        end
    end
    return nil
end

local function updateDisplay()
    if not currentFolder then
        counterLabel.Text = "Gifts: 0/0"
        return
    end
    
    local count = 0
    for _, item in ipairs(currentFolder:GetChildren()) do
        if item.Name ~= "Restrictor" then
            count = count + 1
        end
    end
    
    -- Si por alguna razón hay más de lo que scaneamos, actualizamos el max automáticamente
    if count > totalMax then totalMax = count end
    
    counterLabel.Text = "Gifts: " .. count .. "/" .. totalMax
end

local function scan()
    local folder = getGiftsFolder()
    if folder then
        currentFolder = folder
        local count = 0
        for _, item in ipairs(folder:GetChildren()) do
            if item.Name ~= "Restrictor" then
                count = count + 1
            end
        end
        totalMax = count
        updateDisplay()
        warn("SCAN COMPLETED: Found " .. totalMax .. " gifts in " .. folder:GetFullName())
    else
        totalMax = 0
        currentFolder = nil
        updateDisplay()
        warn("SCAN FAILED: No gift folder found in Workspace.Map")
    end
end

-- Ejecutar scan al presionar el botón
btnScan.MouseButton1Click:Connect(scan)

-- Loop para actualizar el conteo actual (por si otros recogen regalos)
task.spawn(function()
    while screenGui.Parent do
        if currentFolder then
            updateDisplay()
        else
            -- Si no tenemos carpeta, intentamos buscarla silenciosamente
            local folder = getGiftsFolder()
            if folder then 
                currentFolder = folder 
                -- Si es la primera vez que la encuentra sola, hace un scan automático
                if totalMax == 0 then scan() end
            end
        end
        task.wait(1) -- Actualiza cada segundo
    end
end)

-- Scan inicial al ejecutar
scan()
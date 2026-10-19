-- Fix the four existing notification cards whose UIStroke outlines their letters.
-- Run once in stopped Studio Edit. The existing scripts are backed up intact.
local ServerStorage = game:GetService("ServerStorage")
local backupRoot = ServerStorage:FindFirstChild("HudBackup")
assert(backupRoot, "HudBackup missing")
assert(not backupRoot:FindFirstChild("PopupReadability1Originals"), "already installed")

local function boundaryGateClient()
    local found
    for _, boundary in ipairs(workspace:GetChildren()) do
        if boundary.Name == "Boundary" then
            local candidate = boundary:FindFirstChild("GateClient")
            if candidate then
                assert(not found, "multiple live GateClient scripts")
                found = candidate
            end
        end
    end
    assert(found, "live GateClient missing")
    return found
end

local targets = {
    {workspace.BadgeCase.BadgeCaseClient, {
        {
            'toast.Size = UDim2.fromOffset(440, 44)',
            'toast.Size = UDim2.new(0.9, 0, 0, 52)',
        },
        {
            'toast.Font = Enum.Font.FredokaOne; toast.TextSize = 18; toast.TextColor3 = INK',
            'toast.Font = Enum.Font.GothamMedium; toast.TextSize = 17; toast.TextColor3 = CREAM',
        },
        {
            'corner(toast, UDim.new(0, 14)); stroke(toast, GOLD, 2)',
            'corner(toast, UDim.new(0, 14)); local toastBorder = stroke(toast, GOLD, 1.5); toastBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; toastBorder.Transparency = 0.2\nlocal toastMax = Instance.new("UISizeConstraint"); toastMax.MaxSize = Vector2.new(440, 52); toastMax.Parent = toast',
        },
    }},
    {workspace.PostOffice.PostClient, {
        {
            'toast.Size = UDim2.fromOffset(420, 48)',
            'toast.Size = UDim2.new(0.9, 0, 0, 56)',
        },
        {
            'toast.FontFace = FONT; toast.TextSize = 20',
            'toast.Font = Enum.Font.GothamMedium; toast.TextSize = 18',
        },
        {
            'toast.TextColor3 = RGB(255, 205, 40)',
            'toast.TextColor3 = RGB(255, 246, 220)',
        },
        {
            'corner(toast, UDim.new(0, 14)); stroke(toast, RGB(255, 205, 40), 2, 0.2)',
            'corner(toast, UDim.new(0, 14)); local toastBorder = stroke(toast, RGB(240, 200, 90), 1.5, 0.2); toastBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border\nlocal toastMax = Instance.new("UISizeConstraint"); toastMax.MaxSize = Vector2.new(420, 104); toastMax.Parent = toast',
        },
        {
            'toast.Text = text; toast.Visible = true',
            'local v = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)\n\tlocal width = math.min(420, v.X * 0.9)\n\tlocal textHeight = game:GetService("TextService"):GetTextSize(text, 18, Enum.Font.GothamMedium, Vector2.new(width - 28, 1000)).Y\n\ttoast.Size = UDim2.new(0.9, 0, 0, math.max(56, math.min(104, textHeight + 16)))\n\ttoast.Text = text; toast.Visible = true',
        },
    }},
    {boundaryGateClient(), {
        {
            'lbl.Size = UDim2.new(0, 560, 0, 64); lbl.Position = UDim2.new(0.5, -280, 0.2, 0)',
            'lbl.AnchorPoint = Vector2.new(0.5, 0); lbl.Size = UDim2.new(0.9, 0, 0, 72); lbl.Position = UDim2.new(0.5, 0, 0.2, 0)',
        },
        {
            'lbl.Font = Enum.Font.FredokaOne; lbl.TextSize = 22',
            'lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 19',
        },
        {
            'corner.Parent = lbl',
            'corner.Parent = lbl\nlocal maxWidth = Instance.new("UISizeConstraint"); maxWidth.MaxSize = Vector2.new(560, 72); maxWidth.Parent = lbl',
        },
        {
            'stroke.Thickness = 2; stroke.Parent = lbl',
            'stroke.Thickness = 1.5; stroke.Transparency = 0.2; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = lbl',
        },
    }},
    {workspace.SeaGlass.SeaGlassClient, {
        {
            'toast.FontFace = FONT; toast.TextSize = 16',
            'toast.Font = Enum.Font.GothamMedium; toast.TextSize = 17',
        },
        {
            'toast.TextColor3 = CREAM; toast.TextScaled = true;',
            'toast.TextColor3 = CREAM; toast.TextScaled = false; toast.TextWrapped = true;',
        },
        {
            'corner(toast, 10); stroke(toast, GOLD, 2)',
            'corner(toast, 10); local toastBorder = stroke(toast, GOLD, 1.5); toastBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; toastBorder.Transparency = 0.2',
        },
        {
            'toast.Size = UDim2.fromOffset(math.min(320, v.X - 40), 34)',
            'local width = math.min(420, v.X - 40)\n\tlocal textHeight = game:GetService("TextService"):GetTextSize(text, 17, Enum.Font.GothamMedium, Vector2.new(width - 24, 1000)).Y\n\ttoast.Size = UDim2.fromOffset(width, math.max(52, math.min(104, textHeight + 16)))',
        },
    }},
}

local function replaceOne(source, old, new, label)
    local startAt, endAt = source:find(old, 1, true)
    assert(startAt, "missing pattern in " .. label .. ": " .. old)
    assert(not source:find(old, endAt + 1, true), "repeated pattern in " .. label .. ": " .. old)
    return source:sub(1, startAt - 1) .. new .. source:sub(endAt + 1)
end

local prepared = {}
for _, item in ipairs(targets) do
    local script = item[1]
    assert(script:IsA("Script") and script.RunContext == Enum.RunContext.Client, "unexpected client script: " .. script:GetFullName())
    local source = script.Source
    for _, change in ipairs(item[2]) do
        source = replaceOne(source, change[1], change[2], script:GetFullName())
    end
    table.insert(prepared, {script = script, source = source})
end

local backups = Instance.new("Folder")
backups.Name = "PopupReadability1Originals"
backups.Parent = backupRoot
for _, change in ipairs(prepared) do
    local original = change.script:Clone()
    original.Name = change.script.Name .. "_before_popup_readability1"
    original.Parent = backups
    change.script.Source = change.source
    change.script:SetAttribute("PopupReadabilityVersion", 1)
end
print("QQ POPUP READABILITY1: badge, mail, locked-area and sea-glass notice lettering made lighter; decorative gold outlines now border their cards")
print("QQ POPUP READABILITY1: four original client Scripts backed up; phone-width cards and longer messages fit; no gameplay or award logic changed")

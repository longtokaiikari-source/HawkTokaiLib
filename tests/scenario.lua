-- The same scenario runs against the old block and the new one. IS_NEW_FLAG is set by the runner.
local ESP = Library.ESP
local IS_NEW = IS_NEW_FLAG
local fails = 0
local function check(ok, label)
    print((ok and "ok   " or "FAIL ") .. label)
    if not ok then
        fails = fails + 1
    end
end

local function mockWindow()
    local window = { Scale = { Scale = 1 }, Open = true, Minimized = false, _render = {}, _unload = {} }
    function window._listen(self, kind, fn, owner)
        if kind == "Render" then
            table.insert(self._render, fn)
        end
        return function()
            for index, item in ipairs(self._render) do
                if item == fn then
                    table.remove(self._render, index)
                    break
                end
            end
        end
    end
    function window.OnUnload(self, fn)
        table.insert(self._unload, fn)
    end
    function window.Fire(self)
        local list = {}
        for index, item in ipairs(self._render) do
            list[index] = item
        end
        for _, item in ipairs(list) do
            item()
        end
    end
    return window
end

local previewWindow = mockWindow()
local function frame()
    RunService.RenderStepped:_fire()
    previewWindow:Fire()
end

local camera = new_instance("Camera")
camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
camera.FieldOfView = 70
camera.ViewportSize = Vector2.new(1920, 1080)
workspace.CurrentCamera = camera

local world = new_instance("Folder")
local previewWorld = new_instance("WorldModel")
local OFFSETS = {
    Head = Vector3.new(0, 3, 0), UpperTorso = Vector3.new(0, 1, 0), LowerTorso = Vector3.new(0, 0, 0),
    LeftUpperArm = Vector3.new(-1.5, 1, 0), LeftLowerArm = Vector3.new(-1.5, 0, 0), LeftHand = Vector3.new(-1.5, -1, 0),
    RightUpperArm = Vector3.new(1.5, 1, 0), RightLowerArm = Vector3.new(1.5, 0, 0), RightHand = Vector3.new(1.5, -1, 0),
    LeftUpperLeg = Vector3.new(-0.5, -1.5, 0), LeftLowerLeg = Vector3.new(-0.5, -2.5, 0), LeftFoot = Vector3.new(-0.5, -3.5, 0),
    RightUpperLeg = Vector3.new(0.5, -1.5, 0), RightLowerLeg = Vector3.new(0.5, -2.5, 0), RightFoot = Vector3.new(0.5, -3.5, 0),
}
local function makeCharacter(name, origin, health, parent)
    local model = new_instance("Model")
    model.Name = name
    local root = new_instance("Part")
    root.Name = "HumanoidRootPart"
    root.CFrame = CFrame.new(origin)
    root.Size = Vector3.new(2, 2, 1)
    root.Parent = model
    local humanoid = new_instance("Humanoid")
    humanoid.Health = health or 100
    humanoid.MaxHealth = 100
    humanoid.RigType = Enum.HumanoidRigType.R15
    humanoid.Parent = model
    for partName, offset in pairs(OFFSETS) do
        local part = new_instance("Part")
        part.Name = partName
        part.CFrame = CFrame.new(origin + offset)
        part.Size = Vector3.new(1, 1, 1)
        part.Parent = model
    end
    model.PrimaryPart = root
    model.Parent = parent
    return model
end

local teamA = { Name = "Team A" }
local me = Players.LocalPlayer
me.Team = teamA
table.insert(Players._list, me)
local function addPlayer(name, team, character)
    local player = { Name = name, Team = team, Character = character }
    table.insert(Players._list, player)
    return player
end
local near = addPlayer("Near", nil, makeCharacter("Near", Vector3.new(0, 10, -50), nil, world))
local rightSide = addPlayer("Right", nil, makeCharacter("Right", Vector3.new(30, 10, -40), nil, world))
local far = addPlayer("Far", nil, makeCharacter("Far", Vector3.new(0, 10, -3000), nil, world))
local behind = addPlayer("Behind", nil, makeCharacter("Behind", Vector3.new(0, 10, 60), nil, world))
local mate = addPlayer("Mate", teamA, makeCharacter("Mate", Vector3.new(-10, 10, -60), nil, world))
local dead = addPlayer("Dead", nil, makeCharacter("Dead", Vector3.new(-20, 10, -70), 0, world))
local noChar = addPlayer("NoChar", nil, nil)
local leaver = addPlayer("Leaver", nil, makeCharacter("Leaver", Vector3.new(15, 10, -80), nil, world))
local previewModel = makeCharacter("Preview", Vector3.new(0, 2, 0), nil, previewWorld)

local function removePlayer(player)
    for index, item in ipairs(Players._list) do
        if item == player then
            table.remove(Players._list, index)
            break
        end
    end
    Players.PlayerRemoving:_fire(player)
end

local controls = {}
local function mockHandle(window, model)
    local media = new_instance("Frame")
    media.AbsoluteSize = Vector2.new(400, 300)
    local cam = new_instance("Camera")
    cam.CFrame = CFrame.lookAt(Vector3.new(0, 2, 6), Vector3.new(0, 2, 0))
    cam.FieldOfView = 32
    cam.ViewportSize = Vector2.new(400, 300)
    return { Media = media, Camera = cam, Window = window, Model = model }
end
local function mockGroupbox()
    local group = {}
    local function record(kind)
        return function(self, opts)
            controls[opts.Flag or opts.Name] = { kind = kind, opts = opts }
            return {}
        end
    end
    group.CreateToggle = record("Toggle")
    group.CreateSlider = record("Slider")
    group.CreateDropdown = record("Dropdown")
    group.CreateColorPicker = record("ColorPicker")
    group.CreateViewport = function(self, opts)
        local handle = mockHandle(previewWindow, previewModel)
        controls[opts.Name] = { kind = "Viewport", opts = opts, handle = handle }
        return handle
    end
    return group
end
local sub = {}
function sub.AddLeftGroupbox(self, opts) return mockGroupbox() end
function sub.AddRightGroupbox(self, opts) return mockGroupbox() end
local function set(flag, value)
    local control = controls[flag]
    assert(control, "no control " .. flag)
    control.opts.Callback(value)
end
local function drawerOf(player)
    return ESP.State and ESP.State.Drawers[player]
end

ESP.Build(sub, previewWindow)
set("ESP_Enabled", true)
frame()
frame()

if IS_NEW then
    check(ESP.State ~= nil, "game overlay exists after Build")
    local d = drawerOf(near)
    check(d ~= nil and d.BoxShown == true, "near player is drawn")
    local r = drawerOf(rightSide)
    check(r ~= nil and r.BoxShown == true, "player to the right is drawn")
    local f = drawerOf(far)
    check(f == nil or f.BoxShown == false, "far player stays hidden beyond the max distance")
    local b = drawerOf(behind)
    check(b == nil or b.BoxShown == false, "player behind the camera stays hidden")
    local m = drawerOf(mate)
    check(m == nil or m.BoxShown == false, "teammate hidden while Hide teammates is on")
    local dd = drawerOf(dead)
    check(dd == nil or dd.BoxShown == false, "dead player stays hidden")
    local c = d.Box
    local centre = c.Position.XO + c.Size.XO / 2
    check(math.abs(centre - 960) < 1, "near box is centred on the screen (" .. centre .. ")")
    check(c.Position.YO < 540 and c.Position.YO + c.Size.YO > 540, "near box spans the screen centre vertically")

    local scene = { Config = ESP.Config, Game = true }
    ESP.Basis(scene, camera, 1920, 1080)
    local ahead = ESP.Project(scene, Vector3.new(0, 10, -100))
    check(ahead ~= nil and math.abs(ahead.X - 960) < 1e-6 and math.abs(ahead.Y - 540) < 1e-6, "a point straight ahead projects to the screen centre")
    local toRight = ESP.Project(scene, Vector3.new(1, 10, -100))
    check(toRight ~= nil and toRight.X > 960, "+X projects to the right")
    local above = ESP.Project(scene, Vector3.new(0, 11, -100))
    check(above ~= nil and above.Y < 540, "+Y projects upward")
    check(ESP.Project(scene, Vector3.new(0, 10, 50)) == nil, "a point behind the camera projects to nil")
end
check(#WARNINGS == 0, "no warnings while the basic features run")

set("ESP_Box3D", true)
set("ESP_Skeleton", true)
set("ESP_Tracer", true)
set("ESP_Highlight", true)
set("ESP_Rainbow", true)
set("ESP_HideTeammates", false)
set("ESP_MaxDistance", 5000)
for i = 1, 30 do
    frame()
end
check(#WARNINGS == 0, "no errors with every feature on")
if IS_NEW then
    local d = drawerOf(near)
    check(d.Highlight ~= nil and d.Highlight.Enabled == true, "near player is highlighted")
    check(d.Highlight.Adornee == near.Character, "the highlight sits on the character")
    check(d.Used > 20, "3D box and skeleton lines are in use (" .. d.Used .. ")")
    check(drawerOf(mate).BoxShown == true, "teammate drawn once Hide teammates is off")
    check(drawerOf(far).BoxShown == true, "far player drawn once the max distance allows it")
end

set("ESP_TracerFrom", { "Mouse" })
for i = 1, 5 do
    frame()
end
set("ESP_TracerFrom", "Center")
for i = 1, 5 do
    frame()
end
check(#WARNINGS == 0, "tracers from the mouse and from the centre run without errors")

removePlayer(leaver)
frame()
if IS_NEW then
    check(drawerOf(leaver) == nil, "a player who leaves loses their frames")
    check(ESP.State.Players[leaver] == nil, "a player who leaves is no longer tracked")
end
check(#WARNINGS == 0, "a player leaving runs without errors")

set("ESP_Enabled", false)
frame()
if IS_NEW then
    check(ESP.State.Shown == false and drawerOf(near).BoxShown == false, "turning ESP off hides every frame")
end
set("ESP_Enabled", true)
frame()
if IS_NEW then
    check(drawerOf(near).BoxShown == true, "turning ESP back on draws again")
end

local preview = ESP.Previews[1]
check(preview ~= nil, "the preview has an attachment")
if IS_NEW and preview then
    check(preview.Drawer.BoxShown == true, "the preview draws the model's box")
    check(preview.Drawer.Highlight == nil, "the preview draws no highlight")
    check(preview.Drawer.Used > 0, "the preview draws skeleton lines")
end
check(#WARNINGS == 0, "the preview runs without errors")

if preview then
    ESP.Detach(preview)
end
check(#ESP.Previews == 0, "detach removes the preview")
ESP.Shutdown()
if IS_NEW then
    check(ESP.State == nil, "shutdown clears the game overlay")
end
check(#WARNINGS == 0, "no warnings across the whole run")

local function setAll(on)
    set("ESP_Box3D", on)
    set("ESP_Tracer", on)
    set("ESP_Highlight", on)
    set("ESP_Rainbow", on)
    set("ESP_Skeleton", true)
    set("ESP_Box2D", true)
    set("ESP_Name", true)
    set("ESP_Distance", true)
    set("ESP_Health", true)
end
local function perf(label)
    ESP.Build(sub, previewWindow)
    set("ESP_Enabled", true)
    for i = 1, 10 do
        frame()
    end
    local w0, c0 = WRITES, CREATES
    for i = 1, 60 do
        frame()
    end
    print(string.format("PERF %s writes_per_frame=%.1f creates_per_frame=%.2f", label, (WRITES - w0) / 60, (CREATES - c0) / 60))
    ESP.Shutdown()
end
setAll(true)
perf("all_on")
setAll(false)
perf("default")

print("RESULT fails=" .. fails .. " warnings=" .. #WARNINGS)
for _, message in ipairs(WARNINGS) do
    print("WARN " .. message)
end

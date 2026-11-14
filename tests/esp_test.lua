-- tests/esp_test.lua: runs the ESP of Source.luau against a mock of the Roblox API. Plain Lua, no Python.
-- From the project folder:  lua tests/esp_test.lua      (Lua 5.3 or newer)
-- It checks the geometry, the rules, the components, the callbacks and the cleanup. Nothing is rendered,
-- so this cannot show what the ESP looks like. Run it in an executor before you trust a build.

-- Mock of the Roblox API the port touches (Lua 5.3). It checks logic and the geometry, not rendering.
WRITES, CREATES, WARNINGS = 0, 0, {}

function warn(message)
	table.insert(WARNINGS, tostring(message))
end

function math.clamp(x, low, high)
	if x < low then
		return low
	elseif x > high then
		return high
	end
	return x
end

function math.atan2(y, x)
	return math.atan(y, x)
end

local V3, V2, C3, CF = {}, {}, {}, {}

local function newV3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
local function newV2(x, y)
	return setmetatable({ X = x or 0, Y = y or 0 }, V2)
end
local function newC3(r, g, b)
	return setmetatable({ R = r or 0, G = g or 0, B = b or 0 }, C3)
end

V3.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	end
	return V3[k]
end
V3.__add = function(a, b) return newV3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return newV3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then
		return newV3(b.X * a, b.Y * a, b.Z * a)
	end
	return newV3(a.X * b, a.Y * b, a.Z * b)
end
V3.__unm = function(a) return newV3(-a.X, -a.Y, -a.Z) end
function V3.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3.Cross(a, b)
	return newV3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end

V2.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y)
	end
	return V2[k]
end
V2.__add = function(a, b) return newV2(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return newV2(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(a) == "number" then
		return newV2(b.X * a, b.Y * a)
	end
	return newV2(a.X * b, a.Y * b)
end

C3.__index = C3
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end
function C3.fromRGB(r, g, b) return newC3(r / 255, g / 255, b / 255) end
function C3.new(r, g, b) return newC3(r, g, b) end
function C3.fromHSV(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	local m = i % 6
	if m == 0 then return newC3(v, t, p) end
	if m == 1 then return newC3(q, v, p) end
	if m == 2 then return newC3(p, v, t) end
	if m == 3 then return newC3(p, q, v) end
	if m == 4 then return newC3(t, p, v) end
	return newC3(v, p, q)
end

UDim2 = {}
function UDim2.fromOffset(x, y) return { XS = 0, XO = x, YS = 0, YO = y } end
function UDim2.fromScale(x, y) return { XS = x, XO = 0, YS = y, YO = 0 } end

CF.__index = CF
CF.__mul = function(a, b)
	if getmetatable(b) ~= V3 then
		error("CFrame * " .. type(b) .. " is not modelled")
	end
	local p, r, u, l = a.Position, a.RightVector, a.UpVector, a.LookVector
	return newV3(
		p.X + r.X * b.X + u.X * b.Y - l.X * b.Z,
		p.Y + r.Y * b.X + u.Y * b.Y - l.Y * b.Z,
		p.Z + r.Z * b.X + u.Z * b.Y - l.Z * b.Z)
end
function CF.PointToObjectSpace(self, point)
	local d = point - self.Position
	return newV3(d:Dot(self.RightVector), d:Dot(self.UpVector), -d:Dot(self.LookVector))
end

CFrame = {}
function CFrame.new(position)
	return setmetatable({ Position = position or newV3(0, 0, 0), RightVector = newV3(1, 0, 0), UpVector = newV3(0, 1, 0), LookVector = newV3(0, 0, -1) }, CF)
end
function CFrame.Angles(x, y, z)
	return CFrame.new(newV3(0, 0, 0))
end
function CFrame.lookAt(eye, target)
	local look = target - eye
	look = look * (1 / look.Magnitude)
	local right = look:Cross(newV3(0, 1, 0))
	right = right * (1 / right.Magnitude)
	local up = right:Cross(look)
	return setmetatable({ Position = eye, RightVector = right, UpVector = up, LookVector = look }, CF)
end

Vector3 = { new = function(x, y, z) return newV3(x, y, z) end }
Vector2 = { new = function(x, y) return newV2(x, y) end }
Color3 = C3
Enum = {
	HumanoidRigType = { R15 = "R15", R6 = "R6" },
	HighlightDepthMode = { AlwaysOnTop = "AlwaysOnTop", Occluded = "Occluded" },
}

local InstMethods, InstMT, SignalMT, ConnMT = {}, {}, {}, { __index = {} }
SignalMT.__index = SignalMT

local function classIs(name, want)
	if name == want or want == "Instance" then
		return true
	end
	if want == "BasePart" then
		return name == "Part"
	end
	return false
end

local function setParent(child, parent)
	local old = rawget(child, "_parent")
	if old then
		for index, item in ipairs(old._children) do
			if item == child then
				table.remove(old._children, index)
				break
			end
		end
	end
	rawset(child, "_parent", parent)
	if parent then
		table.insert(parent._children, child)
	end
end

InstMT.__index = function(t, k)
	local method = InstMethods[k]
	if method then
		return method
	end
	if k == "Parent" then
		return rawget(t, "_parent")
	end
	local props = rawget(t, "_p")
	local value = props[k]
	if value == nil and k == "Position" and props.CFrame then
		return props.CFrame.Position
	end
	return value
end
InstMT.__newindex = function(t, k, v)
	WRITES = WRITES + 1
	if k == "Parent" then
		setParent(t, v)
	else
		rawget(t, "_p")[k] = v
	end
end

function new_instance(className)
	CREATES = CREATES + 1
	local props = { ClassName = className }
	if className == "Frame" or className == "ScreenGui" or className == "ImageLabel" or className == "TextLabel" then
		props.AbsoluteSize = newV2(400, 300)
	end
	return setmetatable({ _p = props, _children = {}, _isInstance = true }, InstMT)
end

function InstMethods.Destroy(self)
	if rawget(self, "_destroyed") then
		return
	end
	rawset(self, "_destroyed", true)
	local list = {}
	for index, child in ipairs(self._children) do
		list[index] = child
	end
	for _, child in ipairs(list) do
		child:Destroy()
	end
	setParent(self, nil)
end

function InstMethods.IsA(self, className)
	return classIs(self._p.ClassName, className)
end

function InstMethods.IsDescendantOf(self, ancestor)
	local node = self
	while node do
		if node == ancestor then
			return true
		end
		node = rawget(node, "_parent")
	end
	return false
end

function InstMethods.FindFirstChild(self, name, recursive)
	for _, child in ipairs(self._children) do
		if child._p.Name == name then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = child:FindFirstChild(name, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function InstMethods.FindFirstChildOfClass(self, className)
	for _, child in ipairs(self._children) do
		if child._p.ClassName == className then
			return child
		end
	end
	return nil
end

function InstMethods.FindFirstChildWhichIsA(self, className, recursive)
	for _, child in ipairs(self._children) do
		if child:IsA(className) then
			return child
		end
	end
	if recursive then
		for _, child in ipairs(self._children) do
			local found = child:FindFirstChildWhichIsA(className, true)
			if found then
				return found
			end
		end
	end
	return nil
end

function InstMethods.GetPivot(self)
	local props = self._p
	if props.CFrame then
		return props.CFrame
	end
	if props.PrimaryPart then
		return props.PrimaryPart._p.CFrame
	end
	for _, child in ipairs(self._children) do
		if child:IsA("BasePart") then
			return child._p.CFrame
		end
	end
	return CFrame.new(newV3(0, 0, 0))
end

function InstMethods.GetBoundingBox(self)
	local parts = {}
	local function collect(node)
		for _, child in ipairs(node._children) do
			if child:IsA("BasePart") then
				table.insert(parts, child)
			end
			collect(child)
		end
	end
	collect(self)
	if #parts == 0 then
		error("GetBoundingBox: the model has no parts")
	end
	local low, high
	for _, part in ipairs(parts) do
		local p = part._p.CFrame.Position
		local s = part._p.Size
		local a = newV3(p.X - s.X / 2, p.Y - s.Y / 2, p.Z - s.Z / 2)
		local b = newV3(p.X + s.X / 2, p.Y + s.Y / 2, p.Z + s.Z / 2)
		if not low then
			low, high = a, b
		else
			low = newV3(math.min(low.X, a.X), math.min(low.Y, a.Y), math.min(low.Z, a.Z))
			high = newV3(math.max(high.X, b.X), math.max(high.Y, b.Y), math.max(high.Z, b.Z))
		end
	end
	local center = (low + high) * 0.5
	return CFrame.new(center), high - low
end

local function newSignal()
	return setmetatable({ _fns = {} }, SignalMT)
end

function SignalMT.Connect(self, fn)
	local connection = setmetatable({ _signal = self, _fn = fn }, ConnMT)
	table.insert(self._fns, connection)
	return connection
end

ConnMT.__index.Disconnect = function(connection)
	local list = connection._signal._fns
	for index, item in ipairs(list) do
		if item == connection then
			table.remove(list, index)
			break
		end
	end
	connection._fn = nil
end

function SignalMT._fire(self, ...)
	local list = {}
	for index, connection in ipairs(self._fns) do
		list[index] = connection
	end
	for _, connection in ipairs(list) do
		if connection._fn then
			connection._fn(...)
		end
	end
end

Players = { _list = {}, PlayerAdded = newSignal(), PlayerRemoving = newSignal() }
function Players.GetPlayers(self)
	local list = {}
	for index, player in ipairs(self._list) do
		list[index] = player
	end
	return list
end
Players.LocalPlayer = { Name = "Me" }
RunService = { RenderStepped = newSignal() }
UserInputService = { MouseLocation = newV2(100, 100) }
function UserInputService.GetMouseLocation(self)
	return self.MouseLocation
end
workspace = new_instance("Workspace")
CoreGui = new_instance("CoreGui")
function defaultParent()
	return CoreGui
end
function create(className, props)
	local object = new_instance(className)
	if props then
		for key, value in pairs(props) do
			if key ~= "Parent" then
				object[key] = value
			end
		end
		if props.Parent ~= nil then
			object.Parent = props.Parent
		end
	end
	return object
end
Library = { Fonts = { Regular = "Regular", Medium = "Medium", Bold = "Bold" } }

-- Roblox's typeof: Color3, Vector3, Vector2 and CFrame are their own types, not tables.
function typeof(value)
	local kind = type(value)
	if kind == "table" then
		if rawget(value, "_isInstance") then
			return "Instance"
		end
		local mt = getmetatable(value)
		if mt == C3 then return "Color3" end
		if mt == V3 then return "Vector3" end
		if mt == V2 then return "Vector2" end
		if mt == CF then return "CFrame" end
		return "table"
	end
	if value == nil then
		return "nil"
	end
	return kind
end

-- Reads the ESP block from Source.luau and changes the two forms that Lua 5.3 does not have: "a += b" and the
-- generic "for ... in t do". The block then runs in the same global environment as the mock.
do
	local file = io.open("Source.luau", "r") or io.open("../Source.luau", "r")
	assert(file, "Source.luau was not found: run this from the project folder")
	local source = file:read("a")
	file:close()
	local first = source:find("-- // ESP // --", 1, true)
	local last = source:find("\nreturn Library\nend)()", 1, true)
	assert(first and last, "the ESP block was not found in Source.luau")
	local lines = {}
	for line in (source:sub(first, last - 1) .. "\n"):gmatch("(.-)\n") do
		if not line:match("^%s*%-%-") then
			local indent, target, value = line:match("^(%s*)([%w_%.]+)%s*%+=%s*(.-)%s*$")
			if indent then
				line = indent .. target .. " = " .. target .. " + (" .. value .. ")"
			end
			local space, names, expr = line:match("^(%s*)for%s+(.-)%s+in%s+(.-)%s+do%s*$")
			if space and not expr:find("pairs(", 1, true) then
				line = space .. "for " .. names .. " in pairs(" .. expr .. ") do"
			end
		end
		lines[#lines + 1] = line
	end
	local chunk, err = load(table.concat(lines, "\n"), "=ESP block")
	assert(chunk, err)
	chunk()
end

-- The scenario for the port. Each check prints ok or FAIL.
local ESP = Library.ESP
local fails = 0
local function check(ok, label)
	print((ok and "ok   " or "FAIL ") .. label)
	if not ok then
		fails = fails + 1
	end
end
local function step(count)
	for _ = 1, (count or 1) do
		RunService.RenderStepped:_fire(1 / 60)
	end
end
local function mockWindow()
	local window = { Scale = { Scale = 1 }, Open = true, Minimized = false, _render = {} }
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
		self.unload = fn
	end
	function window.Fire(self)
		for _, item in ipairs({ table.unpack(self._render) }) do
			item()
		end
	end
	return window
end

local previewWindow = mockWindow()

-- The world: a camera at the origin looking down -Z, and the characters in the workspace.
local camera = new_instance("Camera")
camera.CFrame = CFrame.lookAt(Vector3.new(0, 10, 0), Vector3.new(0, 10, -100))
camera.FieldOfView = 70
camera.ViewportSize = Vector2.new(1920, 1080)
workspace.CurrentCamera = camera

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
me.Character = makeCharacter("Me", Vector3.new(0, 10, 0), nil, workspace)
table.insert(Players._list, me)
local function addPlayer(name, team, character)
	local player = { Name = name, Team = team, Character = character }
	table.insert(Players._list, player)
	return player
end
local near = addPlayer("Near", nil, makeCharacter("Near", Vector3.new(0, 10, -50), nil, workspace))
local rightSide = addPlayer("Right", nil, makeCharacter("Right", Vector3.new(30, 10, -40), nil, workspace))
local far = addPlayer("Far", nil, makeCharacter("Far", Vector3.new(0, 10, -3000), nil, workspace))
local behind = addPlayer("Behind", nil, makeCharacter("Behind", Vector3.new(0, 10, 60), nil, workspace))
local mate = addPlayer("Mate", teamA, makeCharacter("Mate", Vector3.new(-10, 10, -60), nil, workspace))
local dead = addPlayer("Dead", nil, makeCharacter("Dead", Vector3.new(-20, 10, -70), 0, workspace))
local leaver = addPlayer("Leaver", nil, makeCharacter("Leaver", Vector3.new(15, 10, -80), nil, workspace))

-- The preview: a WorldModel holding one character, and a viewport handle the same shape as Tab:Viewport returns.
local previewWorld = new_instance("WorldModel")
local previewModel = makeCharacter("Avatar", Vector3.new(0, 2, 0), nil, previewWorld)
local previewCamera = new_instance("Camera")
previewCamera.CFrame = CFrame.lookAt(Vector3.new(0, 2, 6), Vector3.new(0, 2, 0))
previewCamera.FieldOfView = 32
previewCamera.ViewportSize = Vector2.new(400, 300)
local previewMedia = new_instance("Frame")
previewMedia.AbsoluteSize = Vector2.new(400, 300)
local handle = { Media = previewMedia, Camera = previewCamera, Window = previewWindow, World = previewWorld, Model = previewModel }

-- The HawkTokai controls, recorded by flag so the checks can press them.
local controls = {}
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
local function objectOf(player)
	return ESP.PlayerObjects[player]
end

-- 1. The tab is built from the library's own controls, and the preview is attached.
ESP:Build(sub, previewWindow)
check(controls["ESP_Players"] ~= nil and controls["ESP_Box2D"] ~= nil and controls["ESP_Skeleton"] ~= nil, "the tab is built with its flags")
check(controls["Preview"] ~= nil and #ESP.Attachments == 1, "the preview is attached to the viewport")
check(#WARNINGS == 0, "no warnings while building")

-- 2. Automatic players: one object per character, the teammate hidden, the dead hidden.
set("ESP_Players", true)
step(3)
check(objectOf(near) ~= nil and objectOf(rightSide) ~= nil and objectOf(behind) ~= nil, "every other player gets an object")
check(objectOf(me) == nil, "the local player gets no object")
local objNear = objectOf(near)
local box = objNear.Components.Box2D.Frames[1]
check(box.Visible == true, "the 2D box of the player in front is shown")
check(math.abs((box.Position.XO + box.Size.XO / 2) - 960) < 1, "the box is centred on the screen when the player is straight ahead")
check(objectOf(mate).CurrentSettings.Visible == false and objectOf(mate).Components.Box2D.Frames[1].Visible == false, "a teammate is hidden while Hide teammates is on")
check(objectOf(dead).CurrentSettings.Visible == false, "a dead player is hidden")
check(#WARNINGS == 0, "no warnings while the players are drawn")

-- 3. Max distance: the far player is hidden beyond it.
set("ESP_MaxDistance", 1500)
step(2)
check(objectOf(far).Components.Box2D.Frames[1].Visible == false, "a player beyond the max distance is hidden")
set("ESP_MaxDistance", 5000)
step(2)
check(objectOf(far).Components.Box2D.Frames[1].Visible == true, "the same player comes back when the max distance allows it")

-- 4. Behind the camera: the arrow, not the box.
local objBehind = objectOf(behind)
check(objBehind._LastScreenPos[2] == false, "a player behind the camera is not in front")
check(objBehind.Components.Billboard.Frames[1].Visible == false, "the name of a player behind the camera is hidden")
set("ESP_Arrow", true)
step(2)
check(objBehind.Components.Arrow.Frames[1].Visible == true, "the arrow points at a player behind the camera")
check(objNear.Components.Arrow.Frames[1].Visible == false, "the arrow stays hidden for a player in front")

-- 5. 3D box, tracer, skeleton, health bar.
set("ESP_Box3D", true)
set("ESP_Tracer", true)
set("ESP_Health", true)
step(2)
check(objNear.Components.Box3D.Pools[1].Shown == 12, "the 3D box draws its twelve edges (" .. objNear.Components.Box3D.Pools[1].Shown .. ")")
check(objNear.Components.Tracer.Pools[1].Shown == 1, "the tracer draws one line")
check(objNear.Components.Skeleton.Pools[1].Shown > 0, "the skeleton draws its bones (" .. objNear.Components.Skeleton.Pools[1].Shown .. ")")
check(objNear.Components.Health.Frames[1].Visible == true, "the health bar is shown in front")
check(#WARNINGS == 0, "no warnings with every drawing on")

-- 6. Highlight in the game: adorned to the character in front, not to one behind.
local hl = objNear.Components.Highlighter.Instances[1]
check(hl.ClassName == "Highlight" and hl.Adornee == near.Character, "the highlight sits on the character in front")
check(objBehind.Components.Highlighter.Instances[1].Adornee == nil, "the highlight is off for a character behind")

-- 7. The preview: its own scene, a box and skeleton, and no highlight.
local attachment = ESP.Attachments[1]
step(2)
check(attachment.Object ~= nil and attachment.Object.Scene.Kind == "preview", "the preview model gets an object in the preview scene")
check(attachment.Object.Components.Highlighter == nil, "the preview draws no highlight")
check(attachment.Object.Components.Box2D.Frames[1].Visible == true, "the preview draws the box of the model")
check(#attachment.Overlay._children > 0, "the preview draws into its overlay")
check(#WARNINGS == 0, "no warnings in the preview")

-- 8. Selection box with a border colour that is set (the original reads a border colour it never set).
local selection = ESP:Add({ Model = rightSide.Character, ESPType = "selectionbox", BorderColor = Color3.new(1, 0, 0) })
step(2)
local selBox = selection.Components.Highlighter.Instances[1]
check(selBox.ClassName == "SelectionBox" and selBox.Color3 == Color3.new(1, 0, 0), "a selection box takes the border colour")
selection:Destroy()
check(selection.Deleted == true and selection.Components.Highlighter == nil, "a destroyed object removes its components")

-- 9. Callbacks: before and after each frame, and the two destroy callbacks.
local counts = { before = 0, after = 0, destroyed = 0, func = 0 }
local cb = ESP:Add({
	Model = near.Character,
	Name = "Callbacks",
	BeforeUpdate = function(object) counts.before = counts.before + 1 end,
	AfterUpdate = function(object) counts.after = counts.after + 1 end,
	OnDestroy = { Fire = function() counts.destroyed = counts.destroyed + 1 end },
	OnDestroyFunc = function() counts.func = counts.func + 1 end,
})
step(3)
check(counts.before >= 3 and counts.after >= 3, "the before and after callbacks run every frame")
cb:Destroy()
check(counts.destroyed == 1 and counts.func == 1, "the destroy callbacks run once each")

-- 10. A bad ESPType is refused, the way the original refuses it.
check(pcall(function() ESP:Add({ Model = near.Character, ESPType = "bogus" }) end) == false, "an invalid ESPType is refused")

-- 11. Rainbow changes the colour every frame.
set("ESP_Rainbow", true)
local before = ESP.RainbowColor
step(10)
check(ESP.RainbowColor ~= before, "the rainbow colour moves while Rainbow is on")
set("ESP_Rainbow", false)

-- 12. Clear removes the objects, and the automatic players make theirs again on the next frame.
ESP:Clear()
check(next(ESP.Objects) == nil, "Clear removes every object")
step(1)
check(objectOf(near) ~= nil, "the automatic players are made again after Clear")

-- 13. Destroy: the connection goes, the scene goes, and nothing can be added afterwards.
ESP:Destroy()
check(ESP.Destroyed == true and ESP.Connection == nil and ESP.GameScene == nil, "Destroy stops the loop and removes the game scene")
check(pcall(function() ESP:Add({ Model = near.Character }) end) == false, "nothing can be added after Destroy")
check(rawget(attachment.Overlay, "_destroyed") == true, "Destroy removes the preview overlay")
check(#WARNINGS == 0, "no warnings across the whole run")

print("RESULT fails=" .. fails .. " warnings=" .. #WARNINGS)
for _, message in ipairs(WARNINGS) do
	print("WARN " .. message)
end

if fails > 0 or #WARNINGS > 0 then
	os.exit(1)
end

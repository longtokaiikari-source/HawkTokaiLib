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
UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset } end }
RaycastParams = { new = function() return {} end }
local function encodeJson(value)
	if type(value) == "table" then
		local parts = {}
		if #value > 0 then
			for _, item in ipairs(value) do
				table.insert(parts, encodeJson(item))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		for key, item in pairs(value) do
			table.insert(parts, string.format("%q:%s", tostring(key), encodeJson(item)))
		end
		table.sort(parts)
		return "{" .. table.concat(parts, ",") .. "}"
	elseif type(value) == "string" then
		return string.format("%q", value)
	elseif type(value) == "number" then
		return string.format("%.17g", value)
	elseif type(value) == "boolean" then
		return tostring(value)
	end
	error("cannot encode " .. type(value))
end
local function decodeJson(text)
	local pos = 1
	local function skip()
		pos = text:find("[^ \t\r\n]", pos) or #text + 1
	end
	local parseValue
	function parseValue()
		skip()
		local c = text:sub(pos, pos)
		if c == "{" then
			pos = pos + 1
			local object = {}
			skip()
			if text:sub(pos, pos) == "}" then
				pos = pos + 1
				return object
			end
			while true do
				skip()
				local _, keyEnd, key = text:find('^"([^"]*)"', pos)
				pos = keyEnd + 1
				skip()
				pos = pos + 1
				object[key] = parseValue()
				skip()
				local sep = text:sub(pos, pos)
				pos = pos + 1
				if sep == "}" then
					return object
				end
			end
		elseif c == "[" then
			pos = pos + 1
			local list = {}
			skip()
			if text:sub(pos, pos) == "]" then
				pos = pos + 1
				return list
			end
			while true do
				table.insert(list, parseValue())
				skip()
				local sep = text:sub(pos, pos)
				pos = pos + 1
				if sep == "]" then
					return list
				end
			end
		elseif c == '"' then
			local _, stringEnd, str = text:find('^"([^"]*)"', pos)
			pos = stringEnd + 1
			return str
		elseif text:sub(pos, pos + 3) == "true" then
			pos = pos + 4
			return true
		elseif text:sub(pos, pos + 4) == "false" then
			pos = pos + 5
			return false
		else
			local _, numberEnd, num = text:find("^(-?[%d%.eE%+%-]+)", pos)
			if not num then
				error("cannot decode at " .. pos)
			end
			pos = numberEnd + 1
			return tonumber(num)
		end
	end
	return parseValue()
end
HttpService = {
	JSONEncode = function(self, value) return encodeJson(value) end,
	JSONDecode = function(self, text) return decodeJson(text) end,
}
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
	RaycastFilterType = { Exclude = "Exclude", Include = "Include" },
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

function InstMethods.Raycast(self, origin, direction, params)
	local override = self.RaycastOverride
	if override then
		return override(origin, direction, params)
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
local OFFSETS_R6 = {
	Head = Vector3.new(0, 2, 0), Torso = Vector3.new(0, 0, 0),
	["Left Arm"] = Vector3.new(-1.5, 0, 0), ["Right Arm"] = Vector3.new(1.5, 0, 0),
	["Left Leg"] = Vector3.new(-0.5, -2, 0), ["Right Leg"] = Vector3.new(0.5, -2, 0),
}
local function makeCharacter(name, origin, health, parent, rig)
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
	humanoid.RigType = rig == "R6" and Enum.HumanoidRigType.R6 or Enum.HumanoidRigType.R15
	humanoid.Parent = model
	for partName, offset in pairs(rig == "R6" and OFFSETS_R6 or OFFSETS) do
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
	group.CreateInput = record("Input")
	group.CreateButton = record("Button")
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
local tab = {}
function tab.CreateSubTab(self, opts) return sub end
ESP:Build(tab, previewWindow)
check(controls["ESP_Highlighters"] ~= nil and controls["ESP_Box2DMode"] ~= nil and controls["ESP_Skeleton"] ~= nil and controls["ESP_Names"] ~= nil, "the pages are built with their flags")
check(controls["Preview"] ~= nil and #ESP.Attachments == 1, "the preview is attached to the viewport")
check(#WARNINGS == 0, "no warnings while building")

-- 2. Automatic players: one object per character, the teammate hidden, the dead hidden.
step(3)
check(ESP.GlobalConfig.Highlighters == false and ESP.GlobalConfig.Billboards == false, "the highlight and the names are off until their pages turn them on")
set("ESP_Box2DMode", "Full")
set("ESP_Skeleton", true)
set("ESP_Names", true)
set("ESP_Highlighters", true)
step(2)
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
check(objBehind.Components.Arrow.Pools[1].Shown == 6, "the arrow draws six lines for a player behind the camera (" .. objBehind.Components.Arrow.Pools[1].Shown .. ")")
check(objBehind.Components.Arrow.Pools[1].Items[1].Position.YO > 540, "a player straight behind points the arrow down the screen")
check(objNear.Components.Arrow.Pools[1].Shown == 0, "the arrow stays hidden for a player in front")

-- 5. 3D box, tracer, skeleton, health bar.
set("ESP_Box3DMode", "Full")
set("ESP_Tracer", true)
set("ESP_HealthMode", "Left")
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

-- 7b. R6 and R15: each rig gets its own skeleton, the box fits the body, and the text and bars follow the box.
local six = addPlayer("Six", nil, makeCharacter("Six", Vector3.new(20, 10, -30), nil, workspace, "R6"))
step(2)
local objSix = objectOf(six)
set("ESP_Skeleton", true)
set("ESP_Box2DMode", "Full")
set("ESP_HealthMode", "Left")
set("ESP_Tracer", true)
step(2)
check(objSix.Components.Skeleton.Pools[1].Shown == 9, "the R6 skeleton draws its nine bones (" .. objSix.Components.Skeleton.Pools[1].Shown .. ")")
check(objNear.Components.Skeleton.Pools[1].Shown == 26, "the R15 skeleton draws its 26 bones (" .. objNear.Components.Skeleton.Pools[1].Shown .. ")")
check(objSix.Components.Box2D.Frames[1].Visible == true and objSix.Components.Box2D.Frames[2].Visible == true, "the full box of an R6 shows its black outline under the line")
set("ESP_Box2DMode", "Corner")
step(2)
check(objSix.Components.Box2D.Pools[1].Shown == 8, "the corner box draws its eight corners (" .. objSix.Components.Box2D.Pools[1].Shown .. ")")
check(objSix.Components.Box2D.Frames[1].Visible == false, "the corner box hides the full frame")
set("ESP_Box2DMode", "Full")
set("ESP_HealthMode", "Bottom")
step(2)
check(objSix.Components.Health.Frames[1].Size.YO == 4, "the bottom health bar is four pixels tall")
set("ESP_HealthMode", "Left")
step(2)
local nameLabel, distanceLabel = objSix.Components.Billboard.Frames[1], objSix.Components.Billboard.Frames[2]
check(nameLabel.Position.YO < distanceLabel.Position.YO, "the name sits above the distance")
check(distanceLabel.Text:match("^%[%d+m%]$") ~= nil, "the distance reads in metres: " .. tostring(distanceLabel.Text))
check(#WARNINGS == 0, "no warnings for either rig")

-- 7c. An arrow for a player off the right edge of the screen sits on the right of the centre.
local edge = addPlayer("Edge", nil, makeCharacter("Edge", Vector3.new(400, 10, -40), nil, workspace))
step(2)
local objEdge = objectOf(edge)
check(objEdge.Components.Arrow.Pools[1].Shown == 6, "an arrow draws for a player off the right edge (" .. objEdge.Components.Arrow.Pools[1].Shown .. ")")
check(objEdge.Components.Arrow.Pools[1].Items[1].Position.XO > 960, "the arrow for a player on the right sits on the right")
check(#WARNINGS == 0, "no warnings from the arrows")

-- 7d. The dropdowns: each choice sets its box or bar, and the health bar's side moves it.
set("ESP_Box3DMode", "Corner")
step(2)
check(objSix.Components.Box3D.Pools[1].Shown == 24, "the corner 3D box draws three short lines per corner (" .. objSix.Components.Box3D.Pools[1].Shown .. ")")
set("ESP_Box3DMode", "Full")
step(2)
check(objSix.Components.Box3D.Pools[1].Shown == 12, "the full 3D box draws its twelve edges again (" .. objSix.Components.Box3D.Pools[1].Shown .. ")")
set("ESP_Box2DMode", "Filled")
step(2)
check(objSix.Components.Box2D.Frames[1].BackgroundTransparency == 0.5, "the Filled choice tints the 2D box")
set("ESP_Box2DMode", "Off")
step(2)
check(objSix.Components.Box2D.Frames[1].Visible == false and objSix.Components.Box2D.Pools[1].Shown == 0, "Off hides the 2D box")
set("ESP_Box2DMode", "Full")
set("ESP_HealthMode", "Left")
step(2)
local leftX = objSix.Components.Health.Frames[1].Position.XO
set("ESP_HealthMode", "Right")
step(2)
local rightX = objSix.Components.Health.Frames[1].Position.XO
check(rightX > leftX, "the right health bar sits right of the left one")
set("ESP_HealthMode", "Off")
step(2)
check(objSix.Components.Health.Frames[1].Visible == false, "Off hides the health bar")
set("ESP_HealthMode", "Left")
step(2)
check(#WARNINGS == 0, "no warnings from the dropdown choices")

-- 7e. The new options: the highlight depth, the visible check, the health number, the head dot, the held item,
-- the distance fade, the FOV ring and the crosshair.
set("ESP_HighlightDepth", "Behind walls")
step(2)
check(objNear.Components.Highlighter.Instances[1].DepthMode == "Occluded", "a highlight behind walls is occluded")
set("ESP_HighlightDepth", "Through walls")
step(2)
check(objNear.Components.Highlighter.Instances[1].DepthMode == "AlwaysOnTop", "a highlight through walls is always on top")
set("ESP_HighlightFill", 0.3)
step(2)
check(math.abs(objNear.Components.Highlighter.Instances[1].FillTransparency - 0.3) < 0.001, "the highlight fill follows its slider")
local wall = new_instance("Part")
set("ESP_VisibleEvery", 1)
set("ESP_VisibleCheck", true)
workspace.RaycastOverride = function() return { Instance = wall } end
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.HiddenColor, "a player behind a wall is drawn in the hidden colour")
workspace.RaycastOverride = nil
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "a player in view is drawn in the visible colour")
set("ESP_VisibleCheck", false)
set("ESP_VisibleOnly", true)
workspace.RaycastOverride = function() return { Instance = wall } end
step(2)
check(objNear.Components.Billboard.Frames[1].Visible == false and objNear.Components.Box2D.Frames[1].Visible == false, "only visible hides a player behind a wall")
workspace.RaycastOverride = nil
set("ESP_VisibleOnly", false)
step(2)
check(objNear.Components.Billboard.Frames[1].Visible == true, "the player comes back once the wall is gone")
set("ESP_HealthText", true)
step(2)
check(objSix.Components.Health.Frames[2].Visible == true and objSix.Components.Health.Frames[2].Text == "100", "the health number shows the health (" .. tostring(objSix.Components.Health.Frames[2].Text) .. ")")
set("ESP_HealthText", false)
set("ESP_HeadDots", true)
step(2)
check(objNear.Components.HeadDot.Frames[1].Visible == true, "the head dot shows on a head in view")
set("ESP_HeadDots", false)
local rifle = new_instance("Tool")
rifle.Name = "Rifle"
rifle.Parent = six.Character
set("ESP_ShowTool", true)
step(2)
check(string.find(objSix.Components.Billboard.Frames[1].Text, "Rifle", 1, true) ~= nil, "the held item shows after the name")
set("ESP_ShowTool", false)
local maxDistance = ESP.Settings.MaxDistance or 5000
local dim = addPlayer("Dim", nil, makeCharacter("Dim", Vector3.new(0, 10, -maxDistance * 0.8), nil, workspace))
step(2)
local objDim = objectOf(dim)
set("ESP_Fade", true)
step(2)
local fadeNow = objDim.Components.Billboard.Frames[1].TextTransparency
check(fadeNow > 0.4 and fadeNow < 0.6, "a player at 80% of the max distance is about half faded (" .. tostring(fadeNow) .. ")")
check(objNear.Components.Billboard.Frames[1].TextTransparency == 0, "a player up close is not faded")
set("ESP_Fade", false)
set("ESP_FOVRadius", 100)
set("ESP_FOV", true)
set("ESP_Crosshair", true)
step(2)
check(ESP.Overlay.Ring.Visible == true and ESP.Overlay.Ring.Size.XO == 200, "the FOV ring is drawn at its radius")
check(ESP.Overlay.Cross.Shown == 4, "the crosshair draws four lines (" .. tostring(ESP.Overlay.Cross.Shown) .. ")")
set("ESP_FOV", false)
set("ESP_Crosshair", false)
step(2)
check(ESP.Overlay.Ring.Visible == false and ESP.Overlay.Cross.Shown == 0, "the overlay goes when it is turned off")
check(#WARNINGS == 0, "no warnings from the new options")

-- 7f. Team colours, friend colours, the names, the radar and the look-up interval.
near.Team = { Name = "Red", TeamColor = { Color = Color3.fromRGB(255, 40, 40) } }
near.DisplayName = "Nearly"
set("ESP_TeamColours", true)
set("ESP_DisplayNames", true)
set("ESP_TeamName", true)
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == near.Team.TeamColor.Color, "a player on a team is drawn in the team colour")
check(string.find(objNear.Components.Billboard.Frames[1].Text, "Nearly", 1, true) ~= nil, "the display name is shown when Display names is on (" .. tostring(objNear.Components.Billboard.Frames[1].Text) .. ")")
check(string.find(objNear.Components.Billboard.Frames[1].Text, "[Red]", 1, true) ~= nil, "the team name is shown after the name")
check(objNear.Components.Highlighter.Instances[1].FillColor == near.Team.TeamColor.Color, "the highlight takes the team colour too")
near.UserId = 777
me.IsFriendsWith = function(self, id) return id == 777 end
set("ESP_FriendColours", true)
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.FriendColor, "a friend is drawn in the friend colour, before the team colour")
set("ESP_FriendColours", false)
set("ESP_TeamColours", false)
set("ESP_DisplayNames", false)
set("ESP_TeamName", false)
step(2)
check(string.find(objNear.Components.Billboard.Frames[1].Text, "Nearly", 1, true) == nil, "the user name is shown again when Display names is off")
set("ESP_Radar", true)
step(2)
check(ESP.Overlay.RadarBack.Visible == true and objNear.Components.Radar.Frames[1].Visible == true, "the radar shows its back and the players")
local centreX, centreY = 1920 - 16 - 55, 16 + 55
check(objNear.Components.Radar.Frames[1].Position.YO < centreY, "a player in front is above the middle of the radar")
check(objBehind.Components.Radar.Frames[1].Position.YO > centreY, "a player behind is below the middle of the radar")
check(objEdge.Components.Radar.Frames[1].Position.XO > centreX, "a player far to the right sits on the right edge of the radar")
set("ESP_Radar", false)
step(2)
check(objNear.Components.Radar.Frames[1].Visible == false, "the radar dots go with the radar")
local looks = 0
local nearHead = objNear.CurrentSettings.Model:FindFirstChild("Head").Position
set("ESP_VisibleEvery", 4)
set("ESP_VisibleCheck", true)
workspace.RaycastOverride = function(origin, direction, params)
    local gap = (origin + direction) - nearHead
    if math.abs(gap.X) + math.abs(gap.Y) + math.abs(gap.Z) < 0.01 then
        looks = looks + 1
    end
    return nil
end
for _ = 1, 8 do
    step(1)
end
workspace.RaycastOverride = nil
check(looks >= 2 and looks <= 3, "the visible check looks at a player every fourth frame (" .. looks .. " looks in 8 frames)")
set("ESP_VisibleCheck", false)
set("ESP_VisibleEvery", 1)
step(2)
check(#WARNINGS == 0, "no warnings from the new options")

-- 7g. The wall check: a player is green when any part of it can be seen, and red when none can. A hand or a foot showing
-- is enough. A see-through part and a part that cannot collide do not hide anything, and a player behind the camera is red.
set("ESP_VisibleEvery", 1)
set("ESP_VisibleCheck", true)
local wallPart = new_instance("Part")
local function onlyAt(point)
    return function(origin, direction)
        local gap = (origin + direction) - point
        if math.abs(gap.X) + math.abs(gap.Y) + math.abs(gap.Z) < 0.01 then
            return nil
        end
        return { Instance = wallPart }
    end
end
workspace.RaycastOverride = function() return { Instance = wallPart } end
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.HiddenColor, "a player behind a wall is red")
workspace.RaycastOverride = onlyAt(objNear.CurrentSettings.Model:FindFirstChild("RightHand").Position)
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "a player with a hand showing is green")
workspace.RaycastOverride = onlyAt(objNear.CurrentSettings.Model:FindFirstChild("LeftFoot").Position)
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "a player with a foot showing is green")
workspace.RaycastOverride = onlyAt(objSix.CurrentSettings.Model:FindFirstChild("Left Arm").Position)
step(2)
check(objSix.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "an R6 player with an arm showing is green")
workspace.RaycastOverride = function() return { Instance = wallPart } end
wallPart.Transparency = 0.8
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "a see-through wall does not hide the player")
wallPart.Transparency = 0
wallPart.CanCollide = false
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.VisibleColor, "a part that cannot collide does not hide the player")
wallPart.CanCollide = true
step(2)
check(objNear.Components.Billboard.Frames[1].TextColor3 == ESP.GlobalConfig.HiddenColor, "a solid wall hides the player again")
check(objBehind._Visible == false, "a player behind the camera is red")
workspace.RaycastOverride = nil
set("ESP_VisibleCheck", false)
set("ESP_VisibleEvery", 1)
step(2)
check(#WARNINGS == 0, "no warnings from the wall check")

-- 7h. Show dead, the nearest limit, and presets.
set("ESP_ShowDead", true)
step(3)
local deadSettings = objectOf(dead).CurrentSettings
check(deadSettings.Visible == true and math.abs(deadSettings.Color.R - 120 / 255) < 0.01, "a dead player is drawn in grey when Show dead is on")
set("ESP_ShowDead", false)
step(3)
check(objectOf(dead).CurrentSettings.Visible == false, "a dead player is hidden again when Show dead is off")
local function countShown()
    local shown = 0
    for _, object in pairs(ESP.PlayerObjects) do
        if object.Components.Billboard.Frames[1].Visible == true then
            shown = shown + 1
        end
    end
    return shown
end
set("ESP_NearestLimit", 1)
step(2)
check(countShown() <= 1, "only the nearest player keeps its ESP with the limit at 1 (" .. countShown() .. " shown)")
set("ESP_NearestLimit", 0)
step(2)
check(countShown() >= 2, "every player keeps its ESP with the limit at 0 (" .. countShown() .. " shown)")
set("ESP_Color", Color3.fromRGB(10, 200, 30))
set("ESP_TextSize", 18)
local saved = ESP:Export()
check(type(saved) == "string" and string.find(saved, "Settings", 1, true) ~= nil, "a preset is text with the settings in it")
set("ESP_TextSize", 12)
set("ESP_Color", Color3.fromRGB(255, 255, 255))
check(ESP:Import(saved) == true and ESP.Settings.TextSize == 18, "a preset brings back the text size")
check(math.abs(ESP.Settings.Color.G - 200 / 255) < 0.01 and math.abs(ESP.Settings.Color.R - 10 / 255) < 0.01, "a preset brings back the colour")
local refused, reason = ESP:Import("not a preset")
check(refused == false and reason ~= nil, "text that is not a preset is refused")
check(#WARNINGS == 0, "no warnings from the new options")

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

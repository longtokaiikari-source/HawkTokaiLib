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

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

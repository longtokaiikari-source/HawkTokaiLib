-- ESP.luau: the ESP of HawkTokaiLib, in its own file. Nothing loads it by itself: load it after the library, as Example_ESP.luau shows.
-- The file returns a function that takes the library and returns the ESP. The helpers it needs come from
-- Library._helpers, which the library hands over, so the two files stay in step.
return function(Library)
	local env = Library._helpers
	local create, label, corner, stroke, defaultParent = env.create, env.label, env.corner, env.stroke, env.defaultParent
	local Players, RunService, UserInputService, HttpService = env.Players, env.RunService, env.UserInputService, env.HttpService
-- // ESP // --
-- The objects, settings, callbacks and components are its own. The drawing is
-- Frames, so one code path draws over the game and over a 3D preview. Highlight, SelectionBox and the handle
-- adornments need the world, so they are drawn in the game only.
Library.ESP = Library.ESP or {}
do
	local ESP = Library.ESP
	local P = {}

	ESP.Destroyed = false
	ESP.Objects = ESP.Objects or {}
	ESP.PlayerObjects = ESP.PlayerObjects or {}
	ESP.Attachments = ESP.Attachments or {}
	ESP.Scenes = ESP.Scenes or {}
	ESP.Counter = ESP.Counter or 0
	ESP.RainbowColor = ESP.RainbowColor or Color3.new(1, 0, 0)
	ESP.RainbowStep = ESP.RainbowStep or 0
	ESP.RainbowHue = ESP.RainbowHue or 0

	-- The GlobalConfig names, plus Health. Font is a Font object, or nil for the library font.
	ESP.GlobalConfig = ESP.GlobalConfig or {
		IgnoreCharacter = false,
		Rainbow = false,
		Billboards = false,
		Distance = false,
		Highlighters = false,
		Tracers = true,
		Arrows = true,
		Boxes2D = true,
		Boxes3D = true,
		Skeleton = true,
		Health = true,
		DynamicText = true,
		Meters = true,
		VisibleCheck = false,
		VisibleOnly = false,
		VisibleColor = Color3.fromRGB(90, 255, 120),
		HiddenColor = Color3.fromRGB(255, 80, 80),
		HealthText = false,
		HeadDots = false,
		ShowTool = false,
		Fade = false,
		FadeStart = 0.6,
		FOV = false,
		FOVRadius = 120,
		Crosshair = false,
		DisplayNames = false,
		TeamName = false,
		TeamColours = false,
		FriendColours = false,
		FriendColor = Color3.fromRGB(70, 170, 255),
		VisibleEvery = 1,
		Radar = false,
		RadarRange = 150,
		RadarSize = 110,
		ShowDead = false,
		NearestLimit = 0,
		Font = nil,
	}
	-- Players: one object per character, always watched. AllyColor is used for teammates.
	ESP.Players = ESP.Players or { Enabled = false, HideTeammates = true, AllyColor = Color3.fromRGB(90, 200, 255) }
	-- The template for the automatic players and for the preview. ApplyTemplate pushes it to the objects that exist.
	ESP.Settings = ESP.Settings or {}

	P.ESPTypes = { text = true, sphereadornment = true, cylinderadornment = true, adornment = true, selectionbox = true, highlight = true }
	P.TracerFrom = { top = true, bottom = true, center = true, mouse = true }
	-- The eight corners are numbered: 1-4 the back face at +Z, 5-8 the front face at -Z.
	P.Edges = { { 1, 2 }, { 2, 4 }, { 4, 3 }, { 3, 1 }, { 1, 5 }, { 5, 6 }, { 6, 8 }, { 8, 7 }, { 7, 5 }, { 2, 6 }, { 4, 8 }, { 3, 7 } }
	P.R15 = {
		"LowerTorso", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "LeftLowerLeg", "LeftUpperLeg", "LowerTorso",
		"RightUpperLeg", "RightLowerLeg", "RightFoot", "RightLowerLeg", "RightUpperLeg", "LowerTorso",
		"UpperTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand", "LeftLowerArm", "LeftUpperArm", "UpperTorso",
		"RightUpperArm", "RightLowerArm", "RightHand", "RightLowerArm", "RightUpperArm", "UpperTorso", "Head",
	}
	P.R6 = { "Torso", "Left Arm", "Torso", "Right Arm", "Torso", "Left Leg", "Torso", "Right Leg", "Torso", "Head" }
	P.Defaults = {
		Visible = true,
		Color = Color3.new(1, 1, 1),
		MaxDistance = 5000,
		StudsOffset = Vector3.new(),
		TextSize = 16,
		ESPType = "Highlight",
		Thickness = 0.1,
		Transparency = 0.65,
		SurfaceColor = Color3.new(1, 1, 1),
		BorderColor = Color3.new(1, 1, 1),
		FillColor = Color3.new(1, 1, 1),
		OutlineColor = Color3.new(1, 1, 1),
		FillTransparency = 0.65,
		OutlineTransparency = 0,
		HighlightDepth = "Through walls",
		Tracer = { Enabled = false, Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 0, From = "Bottom", To = "Feet" },
		Arrow = { Enabled = false, Color = Color3.new(1, 1, 1), CenterOffset = 300, Size = 12 },
		Box2D = { Enabled = false, Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0, Filled = false, Style = "Full" },
		Box3D = { Enabled = false, Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0, Style = "Full" },
		Skeleton = { Enabled = false, Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0 },
		Health = { Enabled = false, Side = "Left", Gradient = true },
		OnDestroy = nil,
		OnDestroyFunc = nil,
		BeforeUpdate = nil,
		AfterUpdate = nil,
	}

	-- // Helpers // --
	function P.Copy(value)
		if typeof(value) ~= "table" then
			return value
		end
		local out = {}
		for key, item in value do
			out[key] = P.Copy(item)
		end
		return out
	end

	-- Fills the keys the data does not have from the template,.
	function P.Validate(data, template)
		if typeof(data) ~= "table" then
			return P.Copy(template)
		end
		for key, value in template do
			if typeof(value) == "table" then
				data[key] = P.Validate(data[key], value)
			elseif data[key] == nil then
				data[key] = value
			end
		end
		return data
	end

	function P.Safe(func, ...)
		if typeof(func) ~= "function" then
			return nil
		end
		local ok, result = pcall(func, ...)
		if ok then
			return result
		end
		warn("[HawkTokai ESP] callback error: " .. tostring(result))
		return nil
	end

	function P.Pivot(instance)
		if instance.ClassName == "Camera" then
			return instance.CFrame
		end
		return instance:GetPivot()
	end

	function P.PrimaryPart(instance)
		if typeof(instance) ~= "Instance" then
			return nil
		end
		if instance:IsA("Model") and instance.PrimaryPart then
			return instance.PrimaryPart
		end
		return instance:FindFirstChildWhichIsA("BasePart") or instance
	end

	function P.DistanceFrom(inst, from)
		if not inst or not from then
			return 9e9
		end
		local position = inst
		if typeof(inst) == "Instance" then
			position = P.Pivot(inst).Position
		end
		local origin = from
		if typeof(from) == "Instance" then
			origin = P.Pivot(from).Position
		end
		return (origin - position).Magnitude
	end

	function P.ColorOf(color)
		if ESP.GlobalConfig.Rainbow == true then
			return ESP.RainbowColor
		end
		return color
	end

	function P.Rainbow(delta)
		ESP.RainbowStep = ESP.RainbowStep + delta
		if ESP.RainbowStep >= 1 / 60 then
			ESP.RainbowStep = 0
			ESP.RainbowHue = ESP.RainbowHue + 1 / 400
			if ESP.RainbowHue > 1 then
				ESP.RainbowHue = 0
			end
			ESP.RainbowColor = Color3.fromHSV(ESP.RainbowHue, 0.8, 1)
		end
	end

	-- // Scenes // --
	-- A scene says where objects are drawn: the game (the world camera, a ScreenGui) or a preview (the viewport camera,
	-- an overlay). Camera, Size and Reference are functions, so they are read on every frame.
	function P.Reference()
		local camera = workspace.CurrentCamera
		if ESP.GlobalConfig.IgnoreCharacter == true then
			return camera
		end
		local localPlayer = Players.LocalPlayer
		local subject = camera and camera.CameraSubject
		if subject and subject:IsA("Humanoid") then
			if subject.Health <= 0 then
				return camera
			end
			if subject.Parent and subject.Parent ~= localPlayer.Character then
				return camera
			end
		end
		local character = localPlayer and localPlayer.Character
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso"))
		return root or camera
	end

	function P.EnsureGameScene()
		if ESP.GameScene then
			return ESP.GameScene
		end
		local folder = create("Folder", { Name = "HawkTokaiESP", Parent = defaultParent() })
		local container = create("ScreenGui", {
			Name = "HawkTokaiESP",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			DisplayOrder = 900,
			Parent = defaultParent(),
		})
		ESP.GameScene = {
			Kind = "game",
			World = workspace,
			Container = container,
			Folder = folder,
			Camera = function()
				return workspace.CurrentCamera
			end,
			Size = function()
				local camera = workspace.CurrentCamera
				if camera then
					return camera.ViewportSize
				end
				return Vector2.new(0, 0)
			end,
			Reference = P.Reference,
		}
		return ESP.GameScene
	end

	function P.ResolveScene(model)
		if ESP.GameScene and model:IsDescendantOf(workspace) then
			return ESP.GameScene
		end
		for _, scene in ESP.Scenes do
			if model:IsDescendantOf(scene.World) then
				return scene
			end
		end
		return nil
	end

	-- Projects a world point into the scene. Returns Vector3(x, y, depth) and whether it is in front of the camera.
	function P.Project(scene, point)
		local camera = scene.Camera()
		if not camera then
			return Vector3.new(0, 0, 0), false
		end
		local cf = camera.CFrame
		local offset = point - cf.Position
		local depth = offset:Dot(cf.LookVector)
		if depth <= 0 then
			return Vector3.new(0, 0, depth), false
		end
		local size = scene.Size()
		local half = math.tan(math.rad(camera.FieldOfView) * 0.5)
		local aspect = size.X / math.max(size.Y, 1)
		local x = offset:Dot(cf.RightVector) / (depth * half * aspect)
		local y = offset:Dot(cf.UpVector) / (depth * half)
		return Vector3.new((x * 0.5 + 0.5) * size.X, (0.5 - y * 0.5) * size.Y, depth), true
	end

	-- The eight corners of the model's bounding box.
	function P.Corners(scene, model)
		local cframe, size
		if model:IsA("Model") then
			local ok, boxCf, boxSize = pcall(model.GetBoundingBox, model)
			if ok then
				cframe, size = boxCf, boxSize
			end
		end
		if not (cframe and size) then
			local primary = P.PrimaryPart(model)
			if primary and primary:IsA("BasePart") then
				cframe, size = primary.CFrame, primary.Size
			end
		end
		if not (cframe and size) then
			return false, {}, {}, 0, 0, 0, 0
		end
		local sx, sy, sz = size.X / 2, size.Y / 2, size.Z / 2
		local world = {
			cframe * Vector3.new(sx, sy, sz), cframe * Vector3.new(sx, sy, -sz),
			cframe * Vector3.new(sx, -sy, sz), cframe * Vector3.new(sx, -sy, -sz),
			cframe * Vector3.new(-sx, sy, sz), cframe * Vector3.new(-sx, sy, -sz),
			cframe * Vector3.new(-sx, -sy, sz), cframe * Vector3.new(-sx, -sy, -sz),
		}
		local screen = {}
		local visible = 0
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		for index, point in world do
			local pos, inFront = P.Project(scene, point)
			screen[index] = pos
			if inFront then
				visible = visible + 1
				minX = math.min(minX, pos.X)
				minY = math.min(minY, pos.Y)
				maxX = math.max(maxX, pos.X)
				maxY = math.max(maxY, pos.Y)
			end
		end
		return visible > 0, world, screen, minX, minY, maxX, maxY
	end

	-- // Components // --
	-- A pool of line Frames. Begin, then Line for each line, then End hides the ones that were not used.
	function P.LinePool(container)
		local pool = { Items = {}, Used = 0, Shown = 0 }
		function pool.Begin()
			pool.Used = 0
		end
		function pool.Line(a, b, color, thickness, transparency)
			pool.Used += 1
			local item = pool.Items[pool.Used]
			if not item then
				item = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false, ZIndex = 4, Parent = container })
				pool.Items[pool.Used] = item
			end
			local delta = b - a
			local length = delta.Magnitude
			if length < 0.5 then
				item.Visible = false
				return
			end
			local mid = (a + b) * 0.5
			item.Position = UDim2.fromOffset(mid.X, mid.Y)
			item.Size = UDim2.fromOffset(length, thickness)
			item.Rotation = math.deg(math.atan2(delta.Y, delta.X))
			item.BackgroundColor3 = color
			item.BackgroundTransparency = transparency
			item.Visible = true
		end
		function pool.End()
			for index = pool.Used + 1, pool.Shown do
				pool.Items[index].Visible = false
			end
			pool.Shown = pool.Used
		end
		function pool.Hide()
			for index = 1, pool.Shown do
				pool.Items[index].Visible = false
			end
			pool.Used = 0
			pool.Shown = 0
		end
		function pool.Destroy()
			for _, item in pool.Items do
				item:Destroy()
			end
			pool.Items = {}
			pool.Used = 0
			pool.Shown = 0
		end
		return pool
	end

	-- A component has Update, Show, Hide and Destroy. Hide clears what it drew until Show; Update decides each frame.
	function P.NewComponent(frames, pools, instances)
		local component = { Visible = true, Frames = frames or {}, Pools = pools or {}, Instances = instances or {} }
		function component.Show()
			component.Visible = true
		end
		function component.Hide()
			component.Visible = false
			for _, frame in component.Frames do
				frame.Visible = false
			end
			for _, pool in component.Pools do
				pool.Hide()
			end
			for _, instance in component.Instances do
				instance.Adornee = nil
			end
		end
		function component.Destroy()
			for _, frame in component.Frames do
				frame:Destroy()
			end
			for _, pool in component.Pools do
				pool.Destroy()
			end
			for _, instance in component.Instances do
				instance:Destroy()
			end
			component.Frames = {}
			component.Pools = {}
			component.Instances = {}
		end
		return component
	end

	-- The screen box of a character, from its bounding box. Nil while the character is behind the camera.
	function P.Box(object)
		local screen = object._LastScreenPos
		if not (screen and screen[2] == true and object._CornerOnScreen == true) then
			return nil
		end
		return object._MinX, object._MinY, object._MaxX, object._MaxY
	end
	-- The text size follows the box: small far away, full size close up.
	function P.TextSizeFor(object, size)
		if ESP.GlobalConfig.DynamicText == false then
			return size
		end
		local _, minY, _, maxY = P.Box(object)
		local height = minY and (maxY - minY) or 100
		return math.max(math.floor(size * math.clamp(height * 0.016, 0.5, 1) + 0.5), 6)
	end
	-- The colour a part of the ESP is drawn in. With the visible check on, a character you can see and one behind a
	-- wall are drawn in two colours. Otherwise a friend has the friend colour (when Friend colours is on), then a player
	-- on a team has the team's colour (when Team colours is on), and anyone else has the colour given.
	function P.Tint(object, color)
		local gc = ESP.GlobalConfig
		if gc.VisibleCheck == true and object._Visible ~= nil then
			if object._Visible then
				return gc.VisibleColor
			end
			return gc.HiddenColor
		end
		local player = object._Player
		if player then
			if gc.FriendColours == true and object._Friend == true then
				return gc.FriendColor
			end
			if gc.TeamColours == true and player.Team and player.Team.TeamColor then
				return player.Team.TeamColor.Color
			end
		end
		return color
	end
	-- The name written above a character: its display name when Display names is on, otherwise its user name.
	function P.DisplayName(object)
		local player = object._Player
		if ESP.GlobalConfig.DisplayNames == true and player and player.DisplayName then
			return tostring(player.DisplayName)
		end
		return tostring(object.CurrentSettings.Name)
	end
	-- How faded the text and the lines are: none up to a fraction of the max distance, then fully faded at the max.
	function P.Fade(object)
		if ESP.GlobalConfig.Fade ~= true then
			return 0
		end
		local distance = object._LastDistance or 0
		local maxDistance = object.CurrentSettings.MaxDistance or 1000
		local start = maxDistance * (ESP.GlobalConfig.FadeStart or 0.6)
		if distance <= start then
			return 0
		end
		return math.clamp((distance - start) / math.max(maxDistance - start, 1), 0, 1)
	end
	-- The name sits above the box and the distance below it. Without a box, both sit over the
	-- head, so the character still gets its text.
	function P.Billboard(object, scene)
		local name = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromOffset(240, 30),
			BackgroundTransparency = 1,
			FontFace = ESP.GlobalConfig.Font or Library.Fonts.Regular,
			TextStrokeTransparency = 0,
			Visible = false,
			ZIndex = 5,
			Parent = scene.Container,
		})
		create("UIStroke", { Parent = name })
		local distance = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.fromOffset(240, 20),
			BackgroundTransparency = 1,
			FontFace = ESP.GlobalConfig.Font or Library.Fonts.Regular,
			TextStrokeTransparency = 0,
			Visible = false,
			ZIndex = 5,
			Parent = scene.Container,
		})
		create("UIStroke", { Parent = distance })
		local component = P.NewComponent({ name, distance })
		local lastName, lastDistance = nil, nil
		function component.Update()
			local settings = object.CurrentSettings
			local screen = object._LastScreenPos
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.Billboards == true
			name.Visible = shown == true
			distance.Visible = shown == true and ESP.GlobalConfig.Distance == true
			if not shown then
				return
			end
			local minX, minY, maxX, maxY = P.Box(object)
			local x, top, below
			if minX then
				x = (minX + maxX) / 2
				top = minY - 3
				below = maxY + 2
				if settings.Health.Enabled == true and settings.Health.Side == "Bottom" then
					below = below + 6
				end
			else
				local textPos = P.Project(scene, P.Pivot(settings.TextModel).Position + settings.StudsOffset)
				x, top, below = textPos.X, textPos.Y, textPos.Y + 2
			end
			name.Position = UDim2.fromOffset(x, top)
			distance.Position = UDim2.fromOffset(x, below)
			local nameSize = P.TextSizeFor(object, settings.TextSize)
			name.TextSize = nameSize
			distance.TextSize = math.max(nameSize - 3, 6)
			local color = P.Tint(object, P.ColorOf(settings.Color))
			name.TextColor3 = color
			distance.TextColor3 = color
			local fade = P.Fade(object)
			name.TextTransparency = fade
			distance.TextTransparency = fade
			local label = P.DisplayName(object)
			if ESP.GlobalConfig.TeamName == true and object._Player and object._Player.Team then
				label = label .. " [" .. tostring(object._Player.Team.Name) .. "]"
			end
			if ESP.GlobalConfig.ShowTool == true and settings.Model then
				local tool = settings.Model:FindFirstChildOfClass("Tool")
				if tool then
					label = label .. " [" .. tostring(tool.Name) .. "]"
				end
			end
			if label ~= lastName then
				name.Text = label
				lastName = label
			end
			local studs = object._LastDistance or 0
			local text = ESP.GlobalConfig.Meters ~= false and string.format("[%dm]", math.floor(studs * 0.28)) or string.format("[%d]", math.floor(studs))
			if text ~= lastDistance then
				distance.Text = text
				lastDistance = text
			end
		end
		return component
	end

	-- The highlight of the game: Highlight, SelectionBox or a handle adornment, parented to the game folder.
	function P.Highlighter(object, scene)
		local settings = object.CurrentSettings
		local kind = settings.ESPType
		if kind == "text" or scene.Kind ~= "game" then
			return nil
		end
		local model = settings.Model
		local instance
		if kind == "sphereadornment" or kind == "cylinderadornment" or kind == "adornment" then
			local size = Vector3.new(4, 4, 4)
			if model:IsA("Model") then
				local ok, _, boxSize = pcall(model.GetBoundingBox, model)
				if ok and boxSize then
					size = boxSize
				end
			elseif model:IsA("BasePart") then
				size = model.Size
			end
			if kind == "sphereadornment" then
				instance = create("SphereHandleAdornment", {
					Name = object.Index, AlwaysOnTop = true, ZIndex = 10, Radius = size.X * 1.085,
					CFrame = CFrame.Angles(math.rad(90), 0, 0), Color3 = settings.Color, Transparency = settings.Transparency,
					Parent = scene.Folder,
				})
			elseif kind == "cylinderadornment" then
				instance = create("CylinderHandleAdornment", {
					Name = object.Index, AlwaysOnTop = true, ZIndex = 10, Height = size.Y * 2, Radius = size.X * 1.085,
					CFrame = CFrame.Angles(math.rad(90), 0, 0), Color3 = settings.Color, Transparency = settings.Transparency,
					Parent = scene.Folder,
				})
			else
				instance = create("BoxHandleAdornment", {
					Name = object.Index, AlwaysOnTop = true, ZIndex = 10, Size = size,
					Color3 = settings.Color, Transparency = settings.Transparency, Parent = scene.Folder,
				})
			end
		elseif kind == "selectionbox" then
			instance = create("SelectionBox", {
				Name = object.Index, Color3 = settings.BorderColor, LineThickness = settings.Thickness,
				SurfaceColor3 = settings.SurfaceColor, SurfaceTransparency = settings.Transparency, Parent = scene.Folder,
			})
		else
			instance = create("Highlight", {
				Name = object.Index, FillColor = settings.FillColor, OutlineColor = settings.OutlineColor,
				FillTransparency = settings.FillTransparency, OutlineTransparency = settings.OutlineTransparency,
				Parent = scene.Folder,
			})
		end
		local component = P.NewComponent({}, {}, { instance })
		function component.Update()
			local current = object.CurrentSettings
			local screen = object._LastScreenPos
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.Highlighters == true
			if not shown then
				instance.Adornee = nil
				return
			end
			instance.Adornee = current.Model
			local through = current.HighlightDepth ~= "Behind walls"
			if instance.ClassName == "Highlight" then
				instance.DepthMode = through and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
			else
				instance.AlwaysOnTop = through
			end
			if kind == "selectionbox" then
				instance.Color3 = P.ColorOf(current.BorderColor)
				instance.LineThickness = current.Thickness
				instance.SurfaceColor3 = P.ColorOf(current.SurfaceColor)
				instance.SurfaceTransparency = current.Transparency
			elseif kind == "highlight" then
				instance.FillColor = P.Tint(object, P.ColorOf(current.FillColor))
				instance.OutlineColor = P.Tint(object, P.ColorOf(current.OutlineColor))
				instance.FillTransparency = current.FillTransparency
				instance.OutlineTransparency = current.OutlineTransparency
			else
				instance.Color3 = P.ColorOf(current.Color)
				instance.Transparency = current.Transparency
			end
		end
		return component
	end

	-- The line from the chosen point of the screen to the model: Top, Bottom, Center or Mouse.
	function P.TracerOrigin(scene, from)
		local size = scene.Size()
		if from == "top" then
			return Vector2.new(size.X / 2, 0)
		elseif from == "center" then
			return Vector2.new(size.X / 2, size.Y / 2)
		elseif from == "mouse" and scene.Kind == "game" then
			local mouse = UserInputService:GetMouseLocation()
			return Vector2.new(mouse.X, mouse.Y)
		end
		return Vector2.new(size.X / 2, size.Y)
	end

	function P.Tracer(object, scene)
		local pool = P.LinePool(scene.Container)
		local component = P.NewComponent({}, { pool })
		function component.Update()
			local settings = object.CurrentSettings
			local screen = object._LastScreenPos
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.Tracers == true and settings.Tracer.Enabled == true
			pool.Begin()
			if shown then
				local from = P.TracerOrigin(scene, string.lower(tostring(settings.Tracer.From)))
				local target = P.TracerTarget(object, settings)
				pool.Line(from, target, P.Tint(object, P.ColorOf(settings.Tracer.Color)), settings.Tracer.Thickness, settings.Tracer.Transparency)
			end
			pool.End()
		end
		return component
	end
	-- Where the tracer ends on the character: the feet (the bottom middle of the box) by default, or the middle, or
	-- the head. Without a box it ends at the root, as before.
	function P.TracerTarget(object, settings)
		local minX, minY, maxX, maxY = P.Box(object)
		if not minX then
			local root = object._LastScreenPos[1]
			return Vector2.new(root.X, root.Y)
		end
		local x = (minX + maxX) / 2
		local mode = string.lower(tostring(settings.Tracer.To or "Feet"))
		if mode == "head" then
			return Vector2.new(x, minY)
		elseif mode == "center" then
			return Vector2.new(x, (minY + maxY) / 2)
		end
		return Vector2.new(x, maxY)
	end
	-- A screen-edge arrow for a target that is off the screen or behind the camera. It is drawn with lines, in the
	-- style of the rest of the ESP: a black outline under the coloured line, and the name and distance behind it.
	-- The direction comes from where the target sits in the camera's own frame, so it is right behind the camera too.
	function P.Arrow(object, scene)
		local pool = P.LinePool(scene.Container)
		local label = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(240, 16),
			BackgroundTransparency = 1,
			FontFace = ESP.GlobalConfig.Font or Library.Fonts.Regular,
			TextSize = 13,
			TextStrokeTransparency = 0,
			Visible = false,
			ZIndex = 6,
			Parent = scene.Container,
		})
		create("UIStroke", { Parent = label })
		local component = P.NewComponent({ label }, { pool })
		local lastText = nil
		function component.Update()
			local settings = object.CurrentSettings
			local world = object._LastWorld
			local screen = object._LastScreenPos
			local camera = scene.Camera()
			local size = scene.Size()
			local onScreen = screen ~= nil and screen[2] == true and screen[1].X >= 0 and screen[1].X <= size.X and screen[1].Y >= 0 and screen[1].Y <= size.Y
			local shown = component.Visible and world ~= nil and camera ~= nil and not onScreen and ESP.GlobalConfig.Arrows == true and settings.Arrow.Enabled == true
			pool.Begin()
			label.Visible = false
			if not shown then
				pool.End()
				return
			end
			-- Where the target sits in the camera's frame: right is +X and up is +Y. The screen's Y grows downwards.
			local cf = camera.CFrame
			local offset = world - cf.Position
			local right, up = offset:Dot(cf.RightVector), offset:Dot(cf.UpVector)
			local length = math.sqrt(right * right + up * up)
			local dx, dy = 0, 1
			if length > 0.001 then
				dx, dy = right / length, -up / length
			end
			local center = Vector2.new(size.X / 2, size.Y / 2)
			local ring = math.min((settings.Arrow.CenterOffset or 300) * size.Y / 1080, math.min(size.X, size.Y) / 2 - 40)
			local pos = Vector2.new(center.X + dx * ring, center.Y + dy * ring)
			local half = settings.Arrow.Size or 12
			local tip = Vector2.new(pos.X + dx * half, pos.Y + dy * half)
			local tail = Vector2.new(pos.X - dx * half, pos.Y - dy * half)
			local base = Vector2.new(tip.X - dx * half * 0.9, tip.Y - dy * half * 0.9)
			local wing = half * 0.6
			local leftWing = Vector2.new(base.X - dy * wing, base.Y + dx * wing)
			local rightWing = Vector2.new(base.X + dy * wing, base.Y - dx * wing)
			local color = P.Tint(object, P.ColorOf(settings.Color))
			local black = Color3.new(0, 0, 0)
			-- The black outline first, then the coloured line over it, as the box does.
			pool.Line(tail, tip, black, 3, 0)
			pool.Line(tip, leftWing, black, 3, 0)
			pool.Line(tip, rightWing, black, 3, 0)
			pool.Line(tail, tip, color, 1.5, 0)
			pool.Line(tip, leftWing, color, 1.5, 0)
			pool.Line(tip, rightWing, color, 1.5, 0)
			pool.End()
			-- The name and the distance sit behind the tail, towards the centre, so they stay on the screen.
			local text = tostring(settings.Name)
			if ESP.GlobalConfig.Distance == true then
				local studs = object._LastDistance or 0
				local meters = ESP.GlobalConfig.Meters ~= false and string.format("[%dm]", math.floor(studs * 0.28)) or string.format("[%d]", math.floor(studs))
				text = text .. " " .. meters
			end
			if text ~= lastText then
				label.Text = text
				lastText = text
			end
			label.Position = UDim2.fromOffset(tail.X - dx * 14, tail.Y - dy * 14)
			label.TextColor3 = color
			label.Visible = ESP.GlobalConfig.Billboards == true
		end
		return component
	end

	-- The 2D box. Full is a box with a black outline under the coloured line. Corner draws eight
	-- short lines, a quarter of the shorter side long, on the four corners. Filled tints the inside. The colour follows
	-- the visible check, and the lines fade with the distance when Distance fade is on.
	function P.Box2D(object, scene)
		local frame = create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 2, Parent = scene.Container })
		local stroke = create("UIStroke", { Parent = frame })
		local outline = create("Frame", { BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, ZIndex = 1, Parent = scene.Container })
		local outlineStroke = create("UIStroke", { Color = Color3.new(0, 0, 0), Parent = outline })
		local pool = P.LinePool(scene.Container)
		local component = P.NewComponent({ frame, outline }, { pool })
		function component.Update()
			local settings = object.CurrentSettings
			local minX, minY, maxX, maxY = P.Box(object)
			local shown = component.Visible and minX ~= nil and ESP.GlobalConfig.Boxes2D == true and settings.Box2D.Enabled == true
			pool.Begin()
			if not shown then
				frame.Visible = false
				outline.Visible = false
				pool.End()
				return
			end
			local color = P.Tint(object, P.ColorOf(settings.Box2D.Color))
			local thickness = settings.Box2D.Thickness
			local transparency = math.max(settings.Box2D.Transparency, P.Fade(object))
			if settings.Box2D.Style == "Corner" then
				frame.Visible = false
				outline.Visible = false
				local length = math.min(maxX - minX, maxY - minY) * 0.25
				local function edge(ax, ay, bx, by)
					pool.Line(Vector2.new(ax, ay), Vector2.new(bx, by), color, thickness, transparency)
				end
				edge(minX, minY, minX + length, minY)
				edge(minX, minY, minX, minY + length)
				edge(maxX, minY, maxX - length, minY)
				edge(maxX, minY, maxX, minY + length)
				edge(minX, maxY, minX + length, maxY)
				edge(minX, maxY, minX, maxY - length)
				edge(maxX, maxY, maxX - length, maxY)
				edge(maxX, maxY, maxX, maxY - length)
				pool.End()
				return
			end
			pool.End()
			local position = UDim2.fromOffset(minX, minY)
			local size = UDim2.fromOffset(maxX - minX, maxY - minY)
			frame.Position = position
			frame.Size = size
			outline.Position = position
			outline.Size = size
			frame.Visible = true
			outline.Visible = true
			frame.BackgroundColor3 = color
			frame.BackgroundTransparency = settings.Box2D.Filled == true and 0.5 or 1
			stroke.Color = color
			stroke.Thickness = thickness
			stroke.Transparency = transparency
			outlineStroke.Thickness = thickness + 2
			outlineStroke.Transparency = transparency
		end
		return component
	end

	function P.Box3D(object, scene)
		local pool = P.LinePool(scene.Container)
		local component = P.NewComponent({}, { pool })
		function component.Update()
			local settings = object.CurrentSettings
			local screen = object._LastScreenPos
			local corners = object._ScreenCorners
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.Boxes3D == true and settings.Box3D.Enabled == true and corners ~= nil
			pool.Begin()
			if shown then
				local color = P.Tint(object, P.ColorOf(settings.Box3D.Color))
				local thickness = settings.Box3D.Thickness
				local transparency = settings.Box3D.Transparency
				local cornersOnly = settings.Box3D.Style == "Corner"
				for _, edge in P.Edges do
					local a, b = corners[edge[1]], corners[edge[2]]
					if a and b and a.Z > 0 and b.Z > 0 then
						local pa, pb = Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y)
						if cornersOnly then
							pool.Line(pa, pa + (pb - pa) * 0.25, color, thickness, transparency)
							pool.Line(pb, pb + (pa - pb) * 0.25, color, thickness, transparency)
						else
							pool.Line(pa, pb, color, thickness, transparency)
						end
					end
				end
			end
			pool.End()
		end
		return component
	end

	-- The skeleton follows its part sequence. A part that is missing or behind the camera breaks the line.
	function P.Skeleton(object, scene)
		local model = object.CurrentSettings.Model
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local sequence = nil
		if humanoid then
			if humanoid.RigType == Enum.HumanoidRigType.R15 then
				sequence = P.R15
			else
				sequence = P.R6
			end
		end
		if not sequence then
			warn("[HawkTokai ESP] could not detect the rig type for " .. tostring(object.CurrentSettings.Name))
			return nil
		end
		local pool = P.LinePool(scene.Container)
		local component = P.NewComponent({}, { pool })
		function component.Update()
			local settings = object.CurrentSettings
			local screen = object._LastScreenPos
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.Skeleton == true and settings.Skeleton.Enabled == true
			pool.Begin()
			if shown then
				local color = P.Tint(object, P.ColorOf(settings.Skeleton.Color))
				local previous = nil
				for _, partName in sequence do
					local part = settings.Model:FindFirstChild(partName)
					local point, inFront = nil, false
					if part then
						point, inFront = P.Project(scene, part.Position)
					end
					if inFront then
						local current = Vector2.new(point.X, point.Y)
						if previous then
							pool.Line(previous, current, color, settings.Skeleton.Thickness, settings.Skeleton.Transparency)
						end
						previous = current
					else
						previous = nil
					end
				end
			end
			pool.End()
		end
		return component
	end

	-- A health bar beside the 2D box.
	-- The health bar: on the left, on the right, or under the box. Gradient colours it from red to green by health.
	-- Health number writes the health beside the bar, so the number reads without a second look.
	function P.Health(object, scene)
		local back = create("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, BorderSizePixel = 0, Visible = false, ZIndex = 4, Parent = scene.Container })
		local fill = create("Frame", {
			AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = Color3.fromRGB(80, 220, 90), BorderSizePixel = 0, ZIndex = 5, Parent = back,
		})
		local number = create("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(44, 14),
			BackgroundTransparency = 1,
			FontFace = ESP.GlobalConfig.Font or Library.Fonts.Regular,
			TextSize = 12,
			TextStrokeTransparency = 0,
			TextColor3 = Color3.new(1, 1, 1),
			Visible = false,
			ZIndex = 5,
			Parent = scene.Container,
		})
		create("UIStroke", { Parent = number })
		local component = P.NewComponent({ back, number })
		function component.Update()
			local settings = object.CurrentSettings
			local humanoid = settings.Model:FindFirstChildOfClass("Humanoid")
			local minX, minY, maxX, maxY = P.Box(object)
			local shown = component.Visible and minX ~= nil and ESP.GlobalConfig.Health == true and settings.Health.Enabled == true and humanoid ~= nil
			back.Visible = shown == true
			number.Visible = shown == true and ESP.GlobalConfig.HealthText == true
			if not shown then
				return
			end
			local fraction = humanoid.MaxHealth > 0 and math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1) or 0
			if settings.Health.Side == "Bottom" then
				back.Position = UDim2.fromOffset(minX - 1, maxY + 2)
				back.Size = UDim2.fromOffset(maxX - minX + 2, 4)
				fill.AnchorPoint = Vector2.new(0, 0)
				fill.Position = UDim2.fromScale(0, 0)
				fill.Size = UDim2.fromScale(fraction, 1)
				number.Position = UDim2.fromOffset(maxX + 18, maxY + 4)
			else
				local onLeft = settings.Health.Side ~= "Right"
				local x = onLeft and (minX - 5) or (maxX + 3)
				back.Position = UDim2.fromOffset(x, minY)
				back.Size = UDim2.fromOffset(3, maxY - minY)
				fill.AnchorPoint = Vector2.new(0, 1)
				fill.Position = UDim2.fromScale(0, 1)
				fill.Size = UDim2.fromScale(1, fraction)
				number.Position = UDim2.fromOffset(onLeft and (x - 26) or (x + 26), (minY + maxY) / 2)
			end
			number.Text = tostring(math.floor(humanoid.Health))
			if settings.Health.Gradient == false then
				fill.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
			else
				fill.BackgroundColor3 = Color3.fromHSV(fraction * 0.3, 1, 1)
			end
		end
		return component
	end
	-- The points of a character the wall check looks at. A rig R15 has its head, body, hands and feet; a rig R6 has its six
	-- parts. A player is seen when a ray from the camera reaches any one of them, so a hand or a foot showing from behind
	-- a wall is enough to draw the player as seen.
	P.WallCheckR15 = { "Head", "UpperTorso", "LowerTorso", "LeftHand", "RightHand", "LeftFoot", "RightFoot" }
	P.WallCheckR6 = { "Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg" }
	-- The instances a ray is not stopped by: every player's character, so a teammate in front does not decide the check,
	-- and the model being checked. Only the scenery stops a ray.
	function P.Ignored(model)
		local list = {}
		for _, player in Players:GetPlayers() do
			if player.Character then
				table.insert(list, player.Character)
			end
		end
		table.insert(list, model)
		return list
	end
	-- Whether a ray that hit something is stopped by it. A part that cannot collide does not stop it, nor does a part
	-- that is see-through; anything else does.
	function P.Blocks(hit)
		local part = hit.Instance
		if not part then
			return true
		end
		if part.CanCollide == false then
			return false
		end
		return (part.Transparency or 0) < 0.5
	end
	-- Whether any point of a character can be seen from the camera. A character with none of the named parts is checked
	-- at its primary part.
	function P.LineOfSight(scene, model)
		local camera = scene.Camera()
		if not camera then
			return true
		end
		local origin = camera.CFrame.Position
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local names = humanoid and humanoid.RigType == Enum.HumanoidRigType.R6 and P.WallCheckR6 or P.WallCheckR15
		local points = {}
		for _, name in names do
			local part = model:FindFirstChild(name)
			if part then
				table.insert(points, part)
			end
		end
		if #points == 0 then
			local root = P.PrimaryPart(model)
			if root then
				table.insert(points, root)
			end
		end
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = P.Ignored(model)
		for _, part in points do
			local hit = workspace:Raycast(origin, part.Position - origin, params)
			if hit == nil or not P.Blocks(hit) then
				return true
			end
		end
		return false
	end
	-- A small dot on the head, in the colour of the object, to see where the head is.
	function P.HeadDot(object, scene)
		local dot = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 5,
			Parent = scene.Container,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local component = P.NewComponent({ dot })
		function component.Update()
			local settings = object.CurrentSettings
			local screen = object._LastScreenPos
			local head = settings.Model and settings.Model:FindFirstChild("Head")
			local shown = component.Visible and screen ~= nil and screen[2] == true and ESP.GlobalConfig.HeadDots == true and head ~= nil
			dot.Visible = shown == true
			if not shown then
				return
			end
			local point = P.Project(scene, head.Position)
			dot.Position = UDim2.fromOffset(point.X, point.Y)
			dot.BackgroundColor3 = P.Tint(object, P.ColorOf(settings.Color))
		end
		return component
	end
	-- The overlay of the game view: a field-of-view ring around the centre, a crosshair at the centre, and the back of
	-- the radar in the top corner.
	function P.DrawOverlay(scene)
		local overlay = ESP.Overlay
		if not overlay then
			local ring = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 3,
				Parent = scene.Container,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
			create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.3, Parent = ring })
			local radarBack = create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(12, 12, 14),
				BackgroundTransparency = 0.35,
				BorderSizePixel = 0,
				Visible = false,
				ZIndex = 6,
				Parent = scene.Container,
			})
			create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = radarBack })
			create("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.4, Parent = radarBack })
			overlay = { Ring = ring, Cross = P.LinePool(scene.Container), RadarBack = radarBack }
			ESP.Overlay = overlay
		end
		local size = scene.Size()
		local center = Vector2.new(size.X / 2, size.Y / 2)
		overlay.Ring.Visible = ESP.GlobalConfig.FOV == true
		if overlay.Ring.Visible then
			local radius = ESP.GlobalConfig.FOVRadius or 120
			overlay.Ring.Position = UDim2.fromOffset(center.X, center.Y)
			overlay.Ring.Size = UDim2.fromOffset(radius * 2, radius * 2)
		end
		local radarSize = ESP.GlobalConfig.RadarSize or 110
		overlay.RadarBack.Visible = ESP.GlobalConfig.Radar == true
		overlay.RadarBack.Position = UDim2.fromOffset(size.X - 16 - radarSize / 2, 16 + radarSize / 2)
		overlay.RadarBack.Size = UDim2.fromOffset(radarSize, radarSize)
		local cross = overlay.Cross
		cross.Begin()
		if ESP.GlobalConfig.Crosshair == true then
			local gap, length = 4, 8
			local white = Color3.new(1, 1, 1)
			cross.Line(Vector2.new(center.X - gap - length, center.Y), Vector2.new(center.X - gap, center.Y), white, 1, 0)
			cross.Line(Vector2.new(center.X + gap, center.Y), Vector2.new(center.X + gap + length, center.Y), white, 1, 0)
			cross.Line(Vector2.new(center.X, center.Y - gap - length), Vector2.new(center.X, center.Y - gap), white, 1, 0)
			cross.Line(Vector2.new(center.X, center.Y + gap), Vector2.new(center.X, center.Y + gap + length), white, 1, 0)
		end
		cross.End()
	end
	-- A radar in the corner of the game view. Each player is a dot placed by where it is from the camera, and the radar
	-- turns with the view. A player past the range sits on the edge of the radar.
	function P.Radar(object, scene)
		local dot = create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(6, 6),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 7,
			Parent = scene.Container,
		})
		create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = dot })
		local component = P.NewComponent({ dot })
		function component.Update()
			local settings = object.CurrentSettings
			local camera = scene.Camera()
			local world = object._LastWorld
			local shown = component.Visible and scene == ESP.GameScene and ESP.GlobalConfig.Radar == true and camera ~= nil and world ~= nil and settings.Visible ~= false
			dot.Visible = false
			if not shown then
				return
			end
			local cf = camera.CFrame
			local look = Vector3.new(cf.LookVector.X, 0, cf.LookVector.Z)
			local side = Vector3.new(cf.RightVector.X, 0, cf.RightVector.Z)
			local lookLength = math.sqrt(look.X * look.X + look.Z * look.Z)
			local sideLength = math.sqrt(side.X * side.X + side.Z * side.Z)
			if lookLength < 0.001 or sideLength < 0.001 then
				return
			end
			look = Vector3.new(look.X / lookLength, 0, look.Z / lookLength)
			side = Vector3.new(side.X / sideLength, 0, side.Z / sideLength)
			local offset = world - cf.Position
			local size = scene.Size()
			local radius = (ESP.GlobalConfig.RadarSize or 110) / 2
			local range = ESP.GlobalConfig.RadarRange or 150
			local x = offset:Dot(side) / range * radius
			local y = -offset:Dot(look) / range * radius
			local length = math.sqrt(x * x + y * y)
			local edge = radius - 4
			if length > edge then
				x, y = x * edge / length, y * edge / length
			end
			dot.Position = UDim2.fromOffset(size.X - 16 - radius + x, 16 + radius + y)
			dot.BackgroundColor3 = P.Tint(object, P.ColorOf(settings.Color))
			dot.Visible = true
		end
		return component
	end
	function P.BuildComponents(object)
		local scene = object.Scene
		object.Components.Billboard = P.Billboard(object, scene)
		object.Components.Highlighter = P.Highlighter(object, scene)
		object.Components.Tracer = P.Tracer(object, scene)
		object.Components.Arrow = P.Arrow(object, scene)
		object.Components.Box2D = P.Box2D(object, scene)
		object.Components.Box3D = P.Box3D(object, scene)
		object.Components.Skeleton = P.Skeleton(object, scene)
		object.Components.Health = P.Health(object, scene)
		object.Components.HeadDot = P.HeadDot(object, scene)
		object.Components.Radar = P.Radar(object, scene)
	end

	function P.HideAll(object, force)
		if force ~= true and object.Hidden then
			return
		end
		object.Hidden = true
		for _, component in object.Components do
			component.Hide()
		end
	end

	function P.ShowAll(object, force)
		if force ~= true and not object.Hidden then
			return
		end
		object.Hidden = false
		for _, component in object.Components do
			component.Show()
		end
	end

	-- // Objects // --
	function ESP:Add(settings)
		assert(ESP.Destroyed ~= true, "ESP is destroyed, load it again.")
		assert(typeof(settings) == "table", string.format("settings; expected table, got %s", typeof(settings)))
		assert(typeof(settings.Model) == "Instance", string.format("settings.Model; expected Instance, got %s", typeof(settings.Model)))
		if not settings.ESPType then
			settings.ESPType = "Highlight"
		end
		assert(typeof(settings.ESPType) == "string", string.format("settings.ESPType; expected string, got %s", typeof(settings.ESPType)))
		settings.ESPType = string.lower(settings.ESPType)
		assert(P.ESPTypes[settings.ESPType] == true, "settings.ESPType; invalid ESPType, got " .. settings.ESPType)
		if typeof(settings.Name) ~= "string" then
			settings.Name = settings.Model.Name
		end
		if typeof(settings.TextModel) ~= "Instance" then
			settings.TextModel = settings.Model
		end
		P.Init()

		local data = P.Validate(P.Copy(settings), P.Copy(P.Defaults))
		data.Name = settings.Name
		data.Model = settings.Model
		data.TextModel = settings.TextModel
		data.ESPType = settings.ESPType
		if P.TracerFrom[string.lower(tostring(data.Tracer.From))] == nil then
			warn("[HawkTokai ESP] invalid Tracer.From, defaulting to Bottom.")
			data.Tracer.From = "Bottom"
		end

		ESP.Counter = ESP.Counter + 1
		local original = P.Copy(data)
		local current = data
		local object = {
			Index = tostring(ESP.Counter),
			Deleted = false,
			Hidden = false,
			Components = {},
			Scene = nil,
			Root = nil,
			OriginalSettings = setmetatable({}, {
				__index = function(_, key)
					return original[key]
				end,
				__newindex = function() end,
				__metatable = "The metatable is locked",
			}),
			CurrentSettings = setmetatable({}, {
				__index = function(_, key)
					return current[key]
				end,
				__newindex = function(_, key, value)
					if key == "Model" or key == "TextModel" or key == "ESPType" then
						error(string.format("%s cannot be changed, it is read-only.", key))
					end
					rawset(current, key, value)
				end,
				__metatable = "The metatable is locked",
			}),
		}

		function object:Destroy()
			if object.Deleted then
				return
			end
			object.Deleted = true
			ESP.Objects[object.Index] = nil
			for _, component in object.Components do
				component.Destroy()
			end
			object.Components = {}
			local callbacks = object.OriginalSettings
			if callbacks.OnDestroy and callbacks.OnDestroy.Fire then
				P.Safe(callbacks.OnDestroy.Fire, callbacks.OnDestroy)
			end
			if callbacks.OnDestroyFunc then
				P.Safe(callbacks.OnDestroyFunc)
			end
		end

		function object:Show(force)
			if object.Deleted then
				return
			end
			current.Visible = true
			P.ShowAll(object, force)
		end

		function object:Hide(force)
			if object.Deleted then
				return
			end
			current.Visible = false
			P.HideAll(object, force)
		end

		function object:ToggleVisibility(force)
			if object.Deleted then
				return
			end
			current.Visible = not current.Visible
			if current.Visible then
				P.ShowAll(object, force)
			else
				P.HideAll(object, force)
			end
		end

		function object:SetEveryColor(color, includeComponents)
			if object.Deleted then
				return
			end
			current.Color = color
			current.SurfaceColor = color
			current.BorderColor = color
			current.FillColor = color
			current.OutlineColor = color
			if includeComponents == true then
				for _, name in { "Tracer", "Arrow", "Box2D", "Box3D", "Skeleton" } do
					if typeof(current[name]) == "table" then
						current[name].Color = color
					end
				end
			end
		end

		-- One frame for this object: the scene, the distance, the screen position, the corners, the callbacks and the
		-- components. The order is fixed.
		function object:Render()
			if object.Deleted then
				return
			end
			if not object.Scene then
				object.Scene = P.ResolveScene(current.Model)
				if not object.Scene then
					P.HideAll(object, true)
					return
				end
				P.BuildComponents(object)
			end
			local scene = object.Scene
			local camera = scene.Camera()
			local reference = scene.Reference()
			if current.Visible == false or not (camera and reference) then
				P.HideAll(object, true)
				return
			end
			local root = object.Root
			if not root or root.Parent == nil then
				root = P.PrimaryPart(current.Model)
				object.Root = root
			end
			local rootInstance = root or current.Model
			local distance = P.DistanceFrom(rootInstance, reference)
			object._LastDistance = distance
			if distance > current.MaxDistance then
				P.HideAll(object, true)
				return
			end
			local screen, inFront = P.Project(scene, P.Pivot(rootInstance).Position)
			object._LastScreenPos = { screen, inFront }
			object._LastWorld = P.Pivot(rootInstance).Position
			if ESP.GlobalConfig.FriendColours == true and object._Player and object._Friend == nil then
				local ok, friend = pcall(function()
					return Players.LocalPlayer:IsFriendsWith(object._Player.UserId)
				end)
				object._Friend = ok and friend == true
			end
			if ESP.GlobalConfig.VisibleCheck == true or ESP.GlobalConfig.VisibleOnly == true then
				object._VisibleCountdown = (object._VisibleCountdown or 0) - 1
				if object._VisibleCountdown <= 0 or object._VisibleKnown == nil or not inFront then
					object._VisibleKnown = inFront and P.LineOfSight(scene, current.Model) or false
					object._VisibleCountdown = math.max(ESP.GlobalConfig.VisibleEvery or 1, 1)
				end
				object._Visible = object._VisibleKnown
			else
				object._VisibleKnown = nil
				object._VisibleCountdown = 0
				object._Visible = nil
			end
			if ESP.GlobalConfig.VisibleOnly == true and object._Visible == false then
				P.HideAll(object, true)
				return
			end
			if object._Culled == true then
				P.HideAll(object, true)
				return
			end

			local gc = ESP.GlobalConfig
			local wantCorners = inFront
			if wantCorners then
				local onScreen, _, corners, minX, minY, maxX, maxY = P.Corners(scene, current.Model)
				object._CornerOnScreen = onScreen
				object._ScreenCorners = corners
				object._MinX, object._MinY, object._MaxX, object._MaxY = minX, minY, maxX, maxY
			else
				object._CornerOnScreen = false
				object._ScreenCorners = nil
			end

			if object.OriginalSettings.Visible == false then
				P.HideAll(object)
			else
				P.ShowAll(object)
			end
			if current.BeforeUpdate then
				P.Safe(current.BeforeUpdate, object)
			end
			for name, component in object.Components do
				local ok, err = pcall(component.Update)
				if not ok then
					warn("[HawkTokai ESP] error updating " .. name .. ": " .. tostring(err))
				end
			end
			if current.AfterUpdate then
				P.Safe(current.AfterUpdate, object)
			end
		end

		ESP.Objects[object.Index] = object
		return object
	end

	-- // Players and previews // --
	function P.SyncPlayers()
		local localPlayer = Players.LocalPlayer
		local config = ESP.Players
		local seen = {}
		for _, player in Players:GetPlayers() do
			if player ~= localPlayer then
				seen[player] = true
				local character = player.Character
				local object = ESP.PlayerObjects[player]
				if object and (object.Deleted or object.CurrentSettings.Model ~= character) then
					object:Destroy()
					object = nil
					ESP.PlayerObjects[player] = nil
				end
				if config.Enabled == true and character and character:IsA("Model") and not object then
					local settings = P.Copy(ESP.Settings)
					settings.Model = character
					settings.Name = player.Name
					object = ESP:Add(settings)
					ESP.PlayerObjects[player] = object
					object._Player = player
				end
				if object then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					local alive = humanoid ~= nil and humanoid.Health > 0
					local teammate = player.Team ~= nil and player.Team == localPlayer.Team
					local shownDead = ESP.GlobalConfig.ShowDead == true and not alive
					object.CurrentSettings.Visible = config.Enabled == true and (alive or shownDead) and not (config.HideTeammates == true and teammate)
					if shownDead then
						object.CurrentSettings.Color = Color3.fromRGB(120, 120, 120)
					elseif teammate then
						object.CurrentSettings.Color = config.AllyColor
					else
						object.CurrentSettings.Color = ESP.Settings.Color or Color3.new(1, 1, 1)
					end
				end
			end
		end
		for player, object in ESP.PlayerObjects do
			if not seen[player] or config.Enabled ~= true then
				object:Destroy()
				ESP.PlayerObjects[player] = nil
			end
		end
	end

	function P.SyncPreview(attachment)
		local handle = attachment.Handle
		local model = handle.Model
		local object = attachment.Object
		if object and (object.Deleted or object.CurrentSettings.Model ~= model) then
			object:Destroy()
			object = nil
			attachment.Object = nil
		end
		if not object and typeof(model) == "Instance" then
			local settings = P.Copy(ESP.Settings)
			settings.Model = model
			attachment.Object = ESP:Add(settings)
		end
	end

	function ESP:AttachPreview(handle)
		assert(ESP.Destroyed ~= true, "ESP is destroyed, load it again.")
		assert(typeof(handle) == "table" and handle.Window and handle.Media and handle.Camera and handle.World, "AttachPreview expects the handle of a Tab:Viewport.")
		P.Init()
		local window = handle.Window
		local overlay = create("Frame", {
			Name = "ESPOverlay", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
			ClipsDescendants = true, ZIndex = 3, Parent = handle.Media,
		})
		local scene = {
			Kind = "preview",
			World = handle.World,
			Container = overlay,
			Camera = function()
				return handle.Camera
			end,
			Size = function()
				local scale = math.max(window.Scale.Scale, 0.05)
				return Vector2.new(overlay.AbsoluteSize.X / scale, overlay.AbsoluteSize.Y / scale)
			end,
			Reference = function()
				return handle.Camera
			end,
		}
		table.insert(ESP.Scenes, scene)
		local attachment = { Handle = handle, Scene = scene, Overlay = overlay, Object = nil }
		function attachment:Detach()
			if attachment.Object then
				attachment.Object:Destroy()
				attachment.Object = nil
			end
			for index, item in ESP.Scenes do
				if item == scene then
					table.remove(ESP.Scenes, index)
					break
				end
			end
			for index, item in ESP.Attachments do
				if item == attachment then
					table.remove(ESP.Attachments, index)
					break
				end
			end
			if overlay.Parent then
				overlay:Destroy()
			end
		end
		table.insert(ESP.Attachments, attachment)
		return attachment
	end

	-- // Frame loop // --
	function P.Step(delta)
		if ESP.Destroyed == true then
			return
		end
		if ESP.GlobalConfig.Rainbow == true then
			P.Rainbow(delta)
		end
		P.SyncPlayers()
		P.RankPlayers()
		if ESP.GameScene then
			P.DrawOverlay(ESP.GameScene)
		end
		for _, attachment in ESP.Attachments do
			P.SyncPreview(attachment)
		end
		for _, object in ESP.Objects do
			if not object.Deleted then
				local current = object.CurrentSettings
				if not (current.Model and current.Model.Parent) then
					object:Destroy()
				else
					local ok, err = pcall(object.Render, object)
					if not ok then
						warn("[HawkTokai ESP] " .. tostring(err))
					end
				end
			end
		end
	end

	function P.Init()
		if ESP.Connection then
			return
		end
		P.EnsureGameScene()
		ESP.Connection = RunService.RenderStepped:Connect(P.Step)
	end

	-- Removes every object. The automatic players and the previews make their objects again on the next frame.
	function ESP:Clear()
		local list = {}
		for _, object in ESP.Objects do
			table.insert(list, object)
		end
		for _, object in list do
			object:Destroy()
		end
		for _, object in ESP.PlayerObjects do
			object:Destroy()
		end
		ESP.PlayerObjects = {}
		for _, attachment in ESP.Attachments do
			attachment.Object = nil
		end
	end

	-- Removes the automatic objects so that they are made again with the current ESPType.
	function ESP:ResetAutomatic()
		for _, object in ESP.PlayerObjects do
			object:Destroy()
		end
		ESP.PlayerObjects = {}
		for _, attachment in ESP.Attachments do
			if attachment.Object then
				attachment.Object:Destroy()
				attachment.Object = nil
			end
		end
	end

	-- Pushes the template to every object that exists. ESPType and Model cannot change, so use ResetAutomatic.
	function ESP:ApplyTemplate()
		local skip = { Model = true, TextModel = true, ESPType = true, Name = true }
		for _, object in ESP.Objects do
			for key, value in ESP.Settings do
				if not skip[key] then
					object.CurrentSettings[key] = P.Copy(value)
				end
			end
		end
	end

	function ESP:Destroy()
		if ESP.Destroyed then
			return
		end
		ESP:Clear()
		local list = {}
		for _, attachment in ESP.Attachments do
			table.insert(list, attachment)
		end
		for _, attachment in list do
			attachment:Detach()
		end
		if ESP.Connection then
			ESP.Connection:Disconnect()
			ESP.Connection = nil
		end
		if ESP.GameScene then
			ESP.GameScene.Container:Destroy()
			ESP.GameScene.Folder:Destroy()
			ESP.GameScene = nil
		end
		ESP.Destroyed = true
	end

	-- // Tab // --
	-- The ESP tab: the players and the drawing in the left groupboxes, the colours and the preview on the right.
	-- Presets: the ESP's settings as text, so one set can be copied, kept and pasted back. A colour is kept as its red,
	-- green and blue. Things that are not data, such as the models and the fonts, are left out.
	P.PresetLeftOut = { Model = true, TextModel = true, Font = true }
	function P.IsColour(value)
		return typeof(value) == "Color3"
	end
	function P.ToPlain(value, depth)
		if depth > 8 then
			return nil
		end
		if P.IsColour(value) then
			return { R = value.R, G = value.G, B = value.B }
		end
		local kind = type(value)
		if kind == "number" or kind == "string" or kind == "boolean" then
			return value
		end
		if kind ~= "table" then
			return nil
		end
		local plain = {}
		for key, item in value do
			if not P.PresetLeftOut[key] and (type(key) == "string" or type(key) == "number") then
				local converted = P.ToPlain(item, depth + 1)
				if converted ~= nil then
					plain[key] = converted
				end
			end
		end
		return plain
	end
	function P.FromPlain(value)
		if type(value) ~= "table" then
			return value
		end
		if type(value.R) == "number" and type(value.G) == "number" and type(value.B) == "number" then
			return Color3.new(value.R, value.G, value.B)
		end
		local result = {}
		for key, item in value do
			result[key] = P.FromPlain(item)
		end
		return result
	end
	function P.MergeInto(target, source)
		for key, value in source do
			if not P.PresetLeftOut[key] and value ~= nil then
				local colour = P.IsColour(value) or (type(value) == "table" and type(value.R) == "number")
				if type(value) == "table" and not colour and type(target[key]) == "table" then
					P.MergeInto(target[key], value)
				else
					target[key] = value
				end
			end
		end
	end
	-- The text of the ESP's settings, to copy and keep.
	function ESP:Export()
		return HttpService:JSONEncode({
			Settings = P.ToPlain(ESP.Settings, 0),
			Config = P.ToPlain(ESP.GlobalConfig, 0),
			Players = P.ToPlain(ESP.Players, 0),
		})
	end
	-- Applies a preset made by Export. Returns false and a reason when the text is not one.
	function ESP:Import(text)
		local ok, data = pcall(function()
			return HttpService:JSONDecode(text)
		end)
		if not ok or type(data) ~= "table" then
			return false, "that is not a preset"
		end
		data = P.FromPlain(data)
		if type(data.Settings) == "table" then
			P.MergeInto(ESP.Settings, data.Settings)
		end
		if type(data.Config) == "table" then
			P.MergeInto(ESP.GlobalConfig, data.Config)
		end
		if type(data.Players) == "table" then
			P.MergeInto(ESP.Players, data.Players)
		end
		ESP.Players.Enabled = true
		ESP:ApplyTemplate()
		P.RefreshControls()
		return true
	end
	-- The players nearest the camera keep their ESP when the nearest limit is on; the rest are left out.
	function P.RankPlayers()
		local limit = ESP.GlobalConfig.NearestLimit or 0
		local list = {}
		for _, object in ESP.PlayerObjects do
			if not object.Deleted then
				table.insert(list, object)
			end
		end
		table.sort(list, function(a, b)
			return (a._LastDistance or math.huge) < (b._LastDistance or math.huge)
		end)
		for index, object in list do
			object._Culled = limit > 0 and index > limit
		end
	end
    -- The option a stored value stands for. Stored values are kept in lower case, so the match ignores case.
    function P.OptionFor(value, options)
        for _, option in options do
            if string.lower(option) == string.lower(tostring(value)) then
                return option
            end
        end
        return options[1]
    end
    -- How each control of the ESP tab reads its current value, by its flag. A preset uses them to update the controls
    -- it has changed, so the tab shows what was applied without being reopened.
    P.Bound = {}
    function P.Bind(flag, getter)
        P.Bound[flag] = getter
    end
    function P.RefreshControls()
        local flags = Library.Flags or {}
        for flag, getter in P.Bound do
            local element = flags[flag]
            if element and type(element.Set) == "function" then
                local ok, value = pcall(getter)
                if ok and value ~= nil then
                    pcall(element.Set, element, value, true)
                end
            end
        end
    end
	function ESP:Build(tab, window)
		P.Init()
		if window and window.OnUnload then
			window:OnUnload(function()
				ESP:Destroy()
			end)
		end
		P.Validate(ESP.Settings, P.Copy(P.Defaults))
		local settings = ESP.Settings
		local config = ESP.GlobalConfig
		local players = ESP.Players
		-- The players are always watched. Each page turns on its own feature, so nothing is drawn until its page says so.
		players.Enabled = true
		P.Bind("ESP_HideTeammates", function() return players.HideTeammates end)
		P.Bind("ESP_MaxDistance", function() return settings.MaxDistance end)
		P.Bind("ESP_Rainbow", function() return config.Rainbow end)
		P.Bind("ESP_IgnoreCharacter", function() return config.IgnoreCharacter end)
		P.Bind("ESP_ShowDead", function() return config.ShowDead == true end)
		P.Bind("ESP_NearestLimit", function() return config.NearestLimit or 0 end)
		P.Bind("ESP_Names", function() return config.Billboards end)
		P.Bind("ESP_Distance", function() return config.Distance end)
		P.Bind("ESP_ShowTool", function() return ESP.GlobalConfig.ShowTool == true end)
		P.Bind("ESP_DynamicText", function() return ESP.GlobalConfig.DynamicText ~= false end)
		P.Bind("ESP_Meters", function() return ESP.GlobalConfig.Meters ~= false end)
		P.Bind("ESP_TextSize", function() return settings.TextSize end)
		P.Bind("ESP_DisplayNames", function() return config.DisplayNames == true end)
		P.Bind("ESP_TeamName", function() return config.TeamName == true end)
		P.Bind("ESP_Box2DMode", function() return settings.Box2D.Enabled ~= true and "Off" or settings.Box2D.Style == "Corner" and "Corner" or settings.Box2D.Filled == true and "Filled" or "Full" end)
		P.Bind("ESP_Box3DMode", function() return settings.Box3D.Enabled ~= true and "Off" or settings.Box3D.Style == "Corner" and "Corner" or "Full" end)
		P.Bind("ESP_Thickness", function() return settings.Box2D.Thickness end)
		P.Bind("ESP_Highlighters", function() return config.Highlighters == true end)
		P.Bind("ESP_Type", function() return P.OptionFor(settings.ESPType, { "Highlight", "SelectionBox", "SphereAdornment", "CylinderAdornment", "Adornment", "Text" }) end)
		P.Bind("ESP_HighlightDepth", function() return settings.HighlightDepth or "Through walls" end)
		P.Bind("ESP_HighlightFill", function() return settings.FillTransparency end)
		P.Bind("ESP_HighlightOutline", function() return settings.OutlineTransparency end)
		P.Bind("ESP_Tracer", function() return settings.Tracer.Enabled end)
		P.Bind("ESP_TracerFrom", function() return P.OptionFor(settings.Tracer.From, { "Top", "Bottom", "Center", "Mouse" }) end)
		P.Bind("ESP_TracerTo", function() return settings.Tracer.To or "Feet" end)
		P.Bind("ESP_HealthMode", function() return settings.Health.Enabled ~= true and "Off" or settings.Health.Side or "Left" end)
		P.Bind("ESP_HealthGradient", function() return settings.Health.Gradient ~= false end)
		P.Bind("ESP_HealthText", function() return ESP.GlobalConfig.HealthText == true end)
		P.Bind("ESP_Skeleton", function() return settings.Skeleton.Enabled end)
		P.Bind("ESP_HeadDots", function() return ESP.GlobalConfig.HeadDots == true end)
		P.Bind("ESP_ArrowSize", function() return settings.Arrow.Size or 12 end)
		P.Bind("ESP_Arrow", function() return settings.Arrow.Enabled end)
		P.Bind("ESP_ArrowOffset", function() return settings.Arrow.CenterOffset end)
		P.Bind("ESP_VisibleCheck", function() return ESP.GlobalConfig.VisibleCheck == true end)
		P.Bind("ESP_VisibleOnly", function() return ESP.GlobalConfig.VisibleOnly == true end)
		P.Bind("ESP_Fade", function() return ESP.GlobalConfig.Fade == true end)
		P.Bind("ESP_FadeStart", function() return config.FadeStart or 0.6 end)
		P.Bind("ESP_VisibleEvery", function() return config.VisibleEvery or 1 end)
		P.Bind("ESP_FOV", function() return ESP.GlobalConfig.FOV == true end)
		P.Bind("ESP_FOVRadius", function() return ESP.GlobalConfig.FOVRadius or 120 end)
		P.Bind("ESP_Crosshair", function() return ESP.GlobalConfig.Crosshair == true end)
		P.Bind("ESP_Radar", function() return config.Radar == true end)
		P.Bind("ESP_RadarRange", function() return config.RadarRange or 150 end)
		P.Bind("ESP_RadarSize", function() return config.RadarSize or 110 end)
		P.Bind("ESP_Color", function() return settings.Color end)
		P.Bind("ESP_VisibleColor", function() return ESP.GlobalConfig.VisibleColor end)
		P.Bind("ESP_HiddenColor", function() return ESP.GlobalConfig.HiddenColor end)
		P.Bind("ESP_AllyColor", function() return players.AllyColor end)
		P.Bind("ESP_TracerColor", function() return settings.Tracer.Color end)
		P.Bind("ESP_TeamColours", function() return config.TeamColours == true end)
		P.Bind("ESP_FriendColours", function() return config.FriendColours == true end)
		P.Bind("ESP_FriendColor", function() return config.FriendColor end)

		-- One page for each feature.
		local pagePlayers = tab:CreateSubTab({ Name = "Players" })
		local gPlayers = pagePlayers:AddLeftGroupbox({ Name = "Players", Icon = "users" })
		gPlayers:CreateToggle({ Name = "Hide teammates", CurrentValue = players.HideTeammates, Flag = "ESP_HideTeammates", Callback = function(value)
			players.HideTeammates = value == true
		end })
		gPlayers:CreateSlider({ Name = "Max distance", Range = { 50, 5000 }, Increment = 50, Suffix = " studs", CurrentValue = settings.MaxDistance, Flag = "ESP_MaxDistance", Callback = function(value)
			settings.MaxDistance = value
			ESP:ApplyTemplate()
		end })
		gPlayers:CreateToggle({ Name = "Rainbow", CurrentValue = config.Rainbow, Flag = "ESP_Rainbow", Callback = function(value)
			config.Rainbow = value == true
		end })
		gPlayers:CreateToggle({ Name = "Ignore my character", Desc = "Measures distance from the camera", CurrentValue = config.IgnoreCharacter, Flag = "ESP_IgnoreCharacter", Callback = function(value)
			config.IgnoreCharacter = value == true
		end })

		gPlayers:CreateToggle({ Name = "Show dead", Desc = "Draws the dead players in grey, instead of hiding them", CurrentValue = config.ShowDead == true, Flag = "ESP_ShowDead", Callback = function(value)
			config.ShowDead = value == true
		end })
		gPlayers:CreateSlider({ Name = "Nearest players", Desc = "Only this many players nearest the camera keep their ESP; 0 keeps everyone", Range = { 0, 30 }, Increment = 1, CurrentValue = config.NearestLimit or 0, Flag = "ESP_NearestLimit", Callback = function(value)
			config.NearestLimit = value
		end })
		local pageNames = tab:CreateSubTab({ Name = "Names" })
		local gNames = pageNames:AddLeftGroupbox({ Name = "Names" })
		gNames:CreateToggle({ Name = "Names", CurrentValue = config.Billboards, Flag = "ESP_Names", Callback = function(value)
			config.Billboards = value == true
		end })
		gNames:CreateToggle({ Name = "Distance", CurrentValue = config.Distance, Flag = "ESP_Distance", Callback = function(value)
			config.Distance = value == true
		end })
		gNames:CreateToggle({ Name = "Held item", Desc = "Shows the tool a character holds, after its name", CurrentValue = ESP.GlobalConfig.ShowTool == true, Flag = "ESP_ShowTool", Callback = function(value)
			ESP.GlobalConfig.ShowTool = value == true
		end })
		gNames:CreateToggle({ Name = "Scale text with distance", CurrentValue = ESP.GlobalConfig.DynamicText ~= false, Flag = "ESP_DynamicText", Callback = function(value)
			ESP.GlobalConfig.DynamicText = value == true
		end })
		gNames:CreateToggle({ Name = "Distance in metres", CurrentValue = ESP.GlobalConfig.Meters ~= false, Flag = "ESP_Meters", Callback = function(value)
			ESP.GlobalConfig.Meters = value == true
		end })
		gNames:CreateSlider({ Name = "Text size", Range = { 10, 24 }, Increment = 1, CurrentValue = settings.TextSize, Flag = "ESP_TextSize", Callback = function(value)
			settings.TextSize = value
			ESP:ApplyTemplate()
		end })

		gNames:CreateToggle({ Name = "Display names", Desc = "Shows the display name instead of the user name", CurrentValue = config.DisplayNames == true, Flag = "ESP_DisplayNames", Callback = function(value)
			config.DisplayNames = value == true
		end })
		gNames:CreateToggle({ Name = "Team name", Desc = "Adds the team name after the name", CurrentValue = config.TeamName == true, Flag = "ESP_TeamName", Callback = function(value)
			config.TeamName = value == true
		end })
		local pageBoxes = tab:CreateSubTab({ Name = "Boxes" })
		local gBoxes = pageBoxes:AddLeftGroupbox({ Name = "Boxes", Icon = "box" })
		gBoxes:CreateDropdown({ Name = "2D box", Options = { "Off", "Full", "Corner", "Filled" }, CurrentOption = settings.Box2D.Enabled ~= true and "Off" or settings.Box2D.Style == "Corner" and "Corner" or settings.Box2D.Filled == true and "Filled" or "Full", Flag = "ESP_Box2DMode", Callback = function(value)
			local choice = type(value) == "table" and value[1] or value
			settings.Box2D.Enabled = choice ~= "Off"
			settings.Box2D.Style = choice == "Corner" and "Corner" or "Full"
			settings.Box2D.Filled = choice == "Filled"
			ESP:ApplyTemplate()
		end })
		gBoxes:CreateDropdown({ Name = "3D box", Options = { "Off", "Full", "Corner" }, CurrentOption = settings.Box3D.Enabled ~= true and "Off" or settings.Box3D.Style == "Corner" and "Corner" or "Full", Flag = "ESP_Box3DMode", Callback = function(value)
			local choice = type(value) == "table" and value[1] or value
			settings.Box3D.Enabled = choice ~= "Off"
			settings.Box3D.Style = choice == "Corner" and "Corner" or "Full"
			ESP:ApplyTemplate()
		end })
		gBoxes:CreateSlider({ Name = "Line thickness", Range = { 1, 4 }, Increment = 0.5, CurrentValue = settings.Box2D.Thickness, Flag = "ESP_Thickness", Callback = function(value)
			settings.Box2D.Thickness = value
			settings.Box3D.Thickness = value
			settings.Skeleton.Thickness = value
			settings.Tracer.Thickness = value
			ESP:ApplyTemplate()
		end })

		local pageHighlight = tab:CreateSubTab({ Name = "Highlight" })
		local gHighlight = pageHighlight:AddLeftGroupbox({ Name = "Highlight" })
		gHighlight:CreateToggle({ Name = "Enable highlight", Desc = "Off until you turn it on", CurrentValue = config.Highlighters == true, Flag = "ESP_Highlighters", Callback = function(value)
			config.Highlighters = value == true
		end })
		gHighlight:CreateDropdown({ Name = "Highlight", Options = { "Highlight", "SelectionBox", "SphereAdornment", "CylinderAdornment", "Adornment", "Text" }, CurrentOption = P.OptionFor(settings.ESPType, { "Highlight", "SelectionBox", "SphereAdornment", "CylinderAdornment", "Adornment", "Text" }), Flag = "ESP_Type", Callback = function(value)
			if type(value) == "table" then
				value = value[1]
			end
			settings.ESPType = string.lower(tostring(value))
			ESP:ResetAutomatic()
		end })
		gHighlight:CreateDropdown({ Name = "Highlight depth", Options = { "Through walls", "Behind walls" }, CurrentOption = settings.HighlightDepth or "Through walls", Flag = "ESP_HighlightDepth", Callback = function(value)
			if type(value) == "table" then
				value = value[1]
			end
			settings.HighlightDepth = tostring(value)
			ESP:ApplyTemplate()
		end })
		gHighlight:CreateSlider({ Name = "Highlight fill", Range = { 0, 1 }, Increment = 0.05, CurrentValue = settings.FillTransparency, Flag = "ESP_HighlightFill", Callback = function(value)
			settings.FillTransparency = value
			ESP:ApplyTemplate()
		end })
		gHighlight:CreateSlider({ Name = "Highlight outline", Range = { 0, 1 }, Increment = 0.05, CurrentValue = settings.OutlineTransparency, Flag = "ESP_HighlightOutline", Callback = function(value)
			settings.OutlineTransparency = value
			ESP:ApplyTemplate()
		end })

		local pageTracers = tab:CreateSubTab({ Name = "Tracers" })
		local gTracers = pageTracers:AddLeftGroupbox({ Name = "Tracers" })
		gTracers:CreateToggle({ Name = "Enable tracers", CurrentValue = settings.Tracer.Enabled, Flag = "ESP_Tracer", Callback = function(value)
			settings.Tracer.Enabled = value == true
			ESP:ApplyTemplate()
		end })
		gTracers:CreateDropdown({ Name = "Tracer from", Options = { "Top", "Bottom", "Center", "Mouse" }, CurrentOption = P.OptionFor(settings.Tracer.From, { "Top", "Bottom", "Center", "Mouse" }), Flag = "ESP_TracerFrom", Callback = function(value)
			if type(value) == "table" then
				value = value[1]
			end
			settings.Tracer.From = string.lower(tostring(value))
			ESP:ApplyTemplate()
		end })
		gTracers:CreateDropdown({ Name = "Tracer to", Options = { "Feet", "Center", "Head" }, CurrentOption = settings.Tracer.To or "Feet", Flag = "ESP_TracerTo", Callback = function(value)
			if type(value) == "table" then
				value = value[1]
			end
			settings.Tracer.To = tostring(value)
			ESP:ApplyTemplate()
		end })

		local pageHealth = tab:CreateSubTab({ Name = "Health" })
		local gHealth = pageHealth:AddLeftGroupbox({ Name = "Health" })
		gHealth:CreateDropdown({ Name = "Health bar", Options = { "Off", "Left", "Right", "Bottom" }, CurrentOption = settings.Health.Enabled ~= true and "Off" or settings.Health.Side or "Left", Flag = "ESP_HealthMode", Callback = function(value)
			local choice = type(value) == "table" and value[1] or value
			settings.Health.Enabled = choice ~= "Off"
			if choice ~= "Off" then
				settings.Health.Side = tostring(choice)
			end
			ESP:ApplyTemplate()
		end })
		gHealth:CreateToggle({ Name = "Health gradient", CurrentValue = settings.Health.Gradient ~= false, Flag = "ESP_HealthGradient", Callback = function(value)
			settings.Health.Gradient = value == true
			ESP:ApplyTemplate()
		end })
		gHealth:CreateToggle({ Name = "Health number", CurrentValue = ESP.GlobalConfig.HealthText == true, Flag = "ESP_HealthText", Callback = function(value)
			ESP.GlobalConfig.HealthText = value == true
		end })

		local pageSkeleton = tab:CreateSubTab({ Name = "Skeleton" })
		local gSkeleton = pageSkeleton:AddLeftGroupbox({ Name = "Skeleton" })
		gSkeleton:CreateToggle({ Name = "Enable skeleton", CurrentValue = settings.Skeleton.Enabled, Flag = "ESP_Skeleton", Callback = function(value)
			settings.Skeleton.Enabled = value == true
			ESP:ApplyTemplate()
		end })
		gSkeleton:CreateToggle({ Name = "Head dot", CurrentValue = ESP.GlobalConfig.HeadDots == true, Flag = "ESP_HeadDots", Callback = function(value)
			ESP.GlobalConfig.HeadDots = value == true
		end })

		local pageArrows = tab:CreateSubTab({ Name = "Arrows" })
		local gArrows = pageArrows:AddLeftGroupbox({ Name = "Arrows" })
		gArrows:CreateSlider({ Name = "Arrow size", Range = { 6, 24 }, Increment = 1, CurrentValue = settings.Arrow.Size or 12, Flag = "ESP_ArrowSize", Callback = function(value)
			settings.Arrow.Size = value
			ESP:ApplyTemplate()
		end })
		gArrows:CreateToggle({ Name = "Enable arrows", Desc = "Points at targets off the screen or behind you", CurrentValue = settings.Arrow.Enabled, Flag = "ESP_Arrow", Callback = function(value)
			settings.Arrow.Enabled = value == true
			ESP:ApplyTemplate()
		end })
		gArrows:CreateSlider({ Name = "Arrow distance", Range = { 100, 800 }, Increment = 10, CurrentValue = settings.Arrow.CenterOffset, Flag = "ESP_ArrowOffset", Callback = function(value)
			settings.Arrow.CenterOffset = value
			ESP:ApplyTemplate()
		end })

		local pageVisibility = tab:CreateSubTab({ Name = "Visibility" })
		local gVisibility = pageVisibility:AddLeftGroupbox({ Name = "Visibility" })
		gVisibility:CreateToggle({ Name = "Wall check", Desc = "Green when any part of a player can be seen, red when none can", CurrentValue = ESP.GlobalConfig.VisibleCheck == true, Flag = "ESP_VisibleCheck", Callback = function(value)
			ESP.GlobalConfig.VisibleCheck = value == true
		end })
		gVisibility:CreateToggle({ Name = "Only visible", Desc = "Hides the players behind a wall", CurrentValue = ESP.GlobalConfig.VisibleOnly == true, Flag = "ESP_VisibleOnly", Callback = function(value)
			ESP.GlobalConfig.VisibleOnly = value == true
		end })
		gVisibility:CreateToggle({ Name = "Distance fade", Desc = "Text and lines fade out towards the max distance", CurrentValue = ESP.GlobalConfig.Fade == true, Flag = "ESP_Fade", Callback = function(value)
			ESP.GlobalConfig.Fade = value == true
		end })
		gVisibility:CreateSlider({ Name = "Fade start", Desc = "Where the fade starts, as a share of the max distance", Range = { 0.1, 1 }, Increment = 0.05, CurrentValue = config.FadeStart or 0.6, Flag = "ESP_FadeStart", Callback = function(value)
			config.FadeStart = value
		end })

		gVisibility:CreateSlider({ Name = "Check every", Desc = "Frames between two looks at a player, so the visible check costs less", Range = { 1, 10 }, Increment = 1, Suffix = " frames", CurrentValue = config.VisibleEvery or 1, Flag = "ESP_VisibleEvery", Callback = function(value)
			config.VisibleEvery = value
		end })
		local pageOverlay = tab:CreateSubTab({ Name = "Overlay" })
		local gOverlay = pageOverlay:AddLeftGroupbox({ Name = "Overlay", Icon = "crosshair" })
		gOverlay:CreateToggle({ Name = "FOV circle", CurrentValue = ESP.GlobalConfig.FOV == true, Flag = "ESP_FOV", Callback = function(value)
			ESP.GlobalConfig.FOV = value == true
		end })
		gOverlay:CreateSlider({ Name = "FOV radius", Range = { 20, 400 }, Increment = 5, CurrentValue = ESP.GlobalConfig.FOVRadius or 120, Flag = "ESP_FOVRadius", Callback = function(value)
			ESP.GlobalConfig.FOVRadius = value
		end })
		gOverlay:CreateToggle({ Name = "Crosshair", CurrentValue = ESP.GlobalConfig.Crosshair == true, Flag = "ESP_Crosshair", Callback = function(value)
			ESP.GlobalConfig.Crosshair = value == true
		end })

		gOverlay:CreateToggle({ Name = "Radar", Desc = "A radar in the corner, turning with the view", CurrentValue = config.Radar == true, Flag = "ESP_Radar", Callback = function(value)
			config.Radar = value == true
		end })
		gOverlay:CreateSlider({ Name = "Radar range", Range = { 50, 600 }, Increment = 10, Suffix = " studs", CurrentValue = config.RadarRange or 150, Flag = "ESP_RadarRange", Callback = function(value)
			config.RadarRange = value
		end })
		gOverlay:CreateSlider({ Name = "Radar size", Range = { 80, 220 }, Increment = 10, Suffix = " px", CurrentValue = config.RadarSize or 110, Flag = "ESP_RadarSize", Callback = function(value)
			config.RadarSize = value
		end })
		local pageColours = tab:CreateSubTab({ Name = "Colours" })
		local gColours = pageColours:AddLeftGroupbox({ Name = "Colours" })
		gColours:CreateColorPicker({ Name = "Enemy color", Color = settings.Color, Flag = "ESP_Color", Callback = function(value)
			settings.Color = value
			ESP:ApplyTemplate()
		end })
		gColours:CreateColorPicker({ Name = "Visible colour", Color = ESP.GlobalConfig.VisibleColor, Flag = "ESP_VisibleColor", Callback = function(value)
			ESP.GlobalConfig.VisibleColor = value
		end })
		gColours:CreateColorPicker({ Name = "Hidden colour", Color = ESP.GlobalConfig.HiddenColor, Flag = "ESP_HiddenColor", Callback = function(value)
			ESP.GlobalConfig.HiddenColor = value
		end })
		gColours:CreateColorPicker({ Name = "Ally color", Color = players.AllyColor, Flag = "ESP_AllyColor", Callback = function(value)
			players.AllyColor = value
		end })
		gColours:CreateColorPicker({ Name = "Tracer color", Color = settings.Tracer.Color, Flag = "ESP_TracerColor", Callback = function(value)
			settings.Tracer.Color = value
			ESP:ApplyTemplate()
		end })

		gColours:CreateToggle({ Name = "Team colours", Desc = "Players are drawn in their team's colour", CurrentValue = config.TeamColours == true, Flag = "ESP_TeamColours", Callback = function(value)
			config.TeamColours = value == true
		end })
		gColours:CreateToggle({ Name = "Friend colours", Desc = "Your friends are drawn in the friend colour, before the team colour", CurrentValue = config.FriendColours == true, Flag = "ESP_FriendColours", Callback = function(value)
			config.FriendColours = value == true
		end })
		gColours:CreateColorPicker({ Name = "Friend colour", Color = config.FriendColor, Flag = "ESP_FriendColor", Callback = function(value)
			config.FriendColor = value
		end })
		local pagePreview = tab:CreateSubTab({ Name = "Preview" })
		local gPreview = pagePreview:AddLeftGroupbox({ Name = "Preview", Icon = "box" })
		local view = gPreview:CreateViewport({ Name = "Preview", Desc = "The same ESP, on a model", Model = "Avatar", Height = 260, SpinSpeed = 20 })
		ESP:AttachPreview(view)
		-- Presets: the settings as text. Copy keeps them in the clipboard; Apply reads the text box back into the ESP.
		local pagePresets = tab:CreateSubTab({ Name = "Presets" })
		local gPresets = pagePresets:AddLeftGroupbox({ Name = "Preset" })
		local presetText = ""
		gPresets:CreateInput({ Name = "Preset text", Placeholder = "paste a preset here", Callback = function(text)
			presetText = tostring(text or "")
		end })
		gPresets:CreateButton({ Name = "Apply preset", Callback = function()
			local ok, reason = ESP:Import(presetText)
			Library:Notify({ Title = "ESP", Content = ok and "Preset applied. Reopen the tabs to see the new values." or tostring(reason), Duration = 3 })
		end })
		gPresets:CreateButton({ Name = "Copy preset", Callback = function()
			local text = ESP:Export()
			presetText = text
			if type(setclipboard) == "function" then
				pcall(setclipboard, text)
			end
			Library:Notify({ Title = "ESP", Content = "Preset copied.", Duration = 2 })
		end })

	end
end
	return Library.ESP
end

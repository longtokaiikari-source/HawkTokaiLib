# Changelog (ESP)

## [Unreleased]

### Changed

- **ESP health bar**: a black outline around a dark track, and the fill takes its colour from health (green when full, yellow at half, red when low, blended between). `ESP.HealthColor(fraction)` returns that colour.
- **ESP radar marker**: your own character is a white dot with a black outline and a pointer, in the middle of the radar, always pointing up because the radar turns with the view.

### Added

- **ESP speed**: the Names page has a Speed toggle (`GlobalConfig.Speed`) that adds each player's horizontal speed beside its distance, in m/s, or st/s with Meters off. Falling does not count; off by default.
- **ESP damage numbers**: `GlobalConfig.DamageText` (the Damage numbers toggle on the Health page) writes a red `-N` or a green `+N` over a player when its health changes. Each number rises and fades in about a second; off by default.
- **ESP**: `Library.ESP` now has its own objects and settings: `Add`, `Clear`, `Destroy`, per-object settings, the Highlight, SelectionBox and adornment types, the Tracer `Top` origin, the Arrow, the filled 2D box, the 3D box, the skeleton, the four callbacks and the global names. A health bar is added.
- **ESP preview**: `Library.ESP:AttachPreview(handle)` draws the ESP over a 3D preview with the same settings and components as the game, without the highlight.
- **ESP tests**: `tests/esp_test.lua` is plain Lua, with no Python. It runs the ESP against a mock of the Roblox API and checks geometry, rules, components, callbacks and cleanup. It does not render.
- **ESP corner box**: `Box2D.Style = "Corner"` draws eight short corner lines. `"Full"` (the default) keeps the box with a black outline under the coloured line.
- **ESP text**: the name sits above the box and the distance below it. Distances read in metres by default (`ESP.GlobalConfig.Meters = false` for studs), and the text scales with the box (`ESP.GlobalConfig.DynamicText`).
- **ESP health bar sides**: `Health.Side` is Left, Right or Bottom. `Health.Gradient` colours the bar by health: green when full, yellow at half, red when low.
- **ESP tracer target**: `Tracer.To` is Feet (the default), Center or Head.
- **ESP highlight depth**: `HighlightDepth` is `"Through walls"` (the default, always on top) or `"Behind walls"` (occluded by walls). Adornments and selection boxes follow it too. The fill and outline transparency have sliders.
- **ESP visible check**: `GlobalConfig.VisibleCheck` colours a player you can see and one behind a wall in two colours (`VisibleColor` and `HiddenColor`). `GlobalConfig.VisibleOnly` hides the players behind a wall. A ray from the camera to the head decides, and the local character and the player are not in the way.
- **ESP health number**: `GlobalConfig.HealthText` writes the health beside the health bar.
- **ESP head dot**: `GlobalConfig.HeadDots` draws a small dot on each head in view.
- **ESP held item**: `GlobalConfig.ShowTool` adds the tool a character holds after its name.
- **ESP distance fade**: `GlobalConfig.Fade` fades the name and the 2D box with the distance, from `FadeStart` of the max distance (default 0.6).
- **FOV circle and crosshair**: `GlobalConfig.FOV` with `FOVRadius` draws a ring around the centre of the game view, and `GlobalConfig.Crosshair` draws a crosshair there.
- **ESP team colours**: `GlobalConfig.TeamColours` draws each player in its team's colour (Colours page).
- **ESP friend colours**: `GlobalConfig.FriendColours` draws your friends in `FriendColor`, which wins over the team colour (Colours page).
- **ESP display names and team name**: `GlobalConfig.DisplayNames` writes the display name instead of the user name, and `GlobalConfig.TeamName` adds the team name after it (Names page).
- **ESP radar**: `GlobalConfig.Radar` draws a radar in the top right corner of the game view. Each player is a dot placed by where it is from the camera, and the radar turns with the view. `RadarRange` (studs) and `RadarSize` (pixels) set its scale (Overlay page).
- **ESP visible check interval**: `GlobalConfig.VisibleEvery` (3 by default) sets how many frames pass between two looks at a player (Visibility page).
- **ESP presets**: the Presets page copies the ESP's settings as text (`ESP:Export()`) and applies a preset back (`ESP:Import(text)`). Colours are kept, and the models and fonts are left out. The controls update at once, and the players stay watched whatever a preset says.
- **ESP show dead**: `GlobalConfig.ShowDead` draws dead players in grey instead of hiding them (Players page).
- **ESP nearest players**: `GlobalConfig.NearestLimit` keeps the ESP of only that many players nearest the camera; 0 keeps everyone (Players page).
- **ESP is in ESP.luau, its own file**: `Library.ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/ESP.luau"))()(Library)` loads it after the library. Nothing loads it by itself.

### Changed

- The example's ESP tab shows the automatic players, ESP for one model with `Library.ESP:Add`, and the show, remove and clear buttons.
- The ESP API is replaced by the port's: `Add`, `Clear`, `Destroy`, `AttachPreview`, `Players`, `Settings` and `GlobalConfig`. The old `Start`, `Stop`, `Attach`, `Detach`, `Shutdown` and `Config` are gone. The tab is still `Library.ESP:Build(sub, Window)`.
- **ESP measures every object in front of the camera**, so the text, the health bar and the tracer all have the box to work from.
- **ESP arrow** is drawn with lines, in the box's style: a black outline under the coloured line, with the name and distance behind the tail. It reads the target's place in the camera's own frame, so it points the right way behind the camera too. `Arrow.Size` (default 12) sets its size, with a slider in the drawing tab. It used to be an image from the web.
- **ESP tab, one page for each feature**: `Library.ESP:Build(tab, window)` takes the tab (not a sub tab) and makes the pages Players, Names, Boxes, Highlight, Tracers, Health, Skeleton, Arrows, Visibility, Overlay, Colours and Preview. Each page turns its own feature on, so the features no longer pile up on each other.
- **ESP defaults**: the names, the distance and the highlight start off, and the 2D box and the skeleton are off until their pages turn them on.
- **ESP colours in one place**: the highlight and the arrow take the same colour as the rest of the ESP, so a friend, a team or a visible or hidden player is drawn the same way everywhere.
- **ESP wall check**: the check looks at several points of each player, the head, the body, the hands and the feet (or the six parts of an R6). A player is green when any point can be seen and red when none can. Parts that cannot collide, and see-through parts, do not block the check; other players do not block it either. A player behind the camera is red. The control is called Wall check, and `VisibleEvery` defaults to 1 (every frame).
- **ESP is in ESP.luau, its own file**: `Library.ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/ESP.luau"))()(Library)` loads it after the library. Nothing loads it by itself.
- **ESP is in ESP.luau, its own file**: `Library.ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/longtokaiikari-source/HawkTokaiLib/refs/heads/main/ESP.luau"))()(Library)` loads it after the library. Nothing loads it by itself.

### Fixed

- **ESP wall check** no longer decides from the head alone, which kept a player red while a hand or a foot was showing.
- **ESP tracer and highlight dropdowns** show the choice that is stored, not a fixed one.
- **Page row lights**: the lights and arrows at the ends of a long row of pages (the sub tabs, like ESP's) show only while pages are out of view on that side. Before, the far end kept its light after the row was dragged to the end, when the window was scaled below full size.

### Removed

- `tokaihub-esp.luau`, an earlier standalone copy of the ESP: `Library.ESP` replaces it. The copy had a second block after its final `return`, so it did not load, and its `SelectionBox` read a `BorderColor` it never set.
- **Automatic players switch**: the players are always watched, so there is no master switch to turn ESP on. The first-run switch-on of the 2D box and the skeleton is gone too.

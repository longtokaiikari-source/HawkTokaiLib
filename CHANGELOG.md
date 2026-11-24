# Changelog

Every notable change to HawkTokaiLib is listed here, newest first. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Upgrade notes

- The Loader and the Example have changed. Paste the new `Loader.luau` into your executor, and the new `Example.luau` into Junkie's Original Code.
- `EasterEgg` is set in the Loader's `RunProtected` options, or in `Home.EasterEgg`. It is no longer in the key gate.
- The window starts with the normal text (`None`). Players pick a font in Configs > Font.

### Added


- **Friends card** on the Home: how many friends you have, how many are online, how many are in this server, and how many are offline. The list is read page by page every 25 seconds, off the frame loop; a failed read keeps the last numbers. The idea is taken from the dashboard of Luna Interface Suite (BSD 3-Clause, Copyright (c) 2024 Nebula Softworks); the code is written for this library.

- **Home rebuilt**: the cards run in a new order: profile, config line, four live tiles, activity and notes side by side, world clock, server, game and links, shortcuts, executor, tip. The egg input stays last, bottom right.
- **Activity feed**: the last eight things that happened this session: notices, players joining and leaving, hiding the name or the avatar, the window hidden, stats reset. Newest first, with how long ago.
- **Notes**: a note pad on the Home that keeps what you type while the script runs.

- **Load report**: a load says how many settings it applied, how many wait for controls this script does not have yet, and how many did not fit. The load and autoload notices show it.
- **Backups and Restore**: a save that replaces a file keeps the old one under `backups/`. The config manager's Restore button, or `Window:RestoreBackup(name)`, puts it back.
- **Refresh**: the config manager has a Refresh button that rereads the list, like Obsidian's Refresh List.
- **Home config status**: a line under the banner shows the loaded config, whether it has unsaved changes, and the autoload config. `Home = { ConfigStatus = false }` hides it.

- **Autoload notice**: at start the player is told that the autoload config loaded, or why it did not.
- `Window:SetConfigIgnore(list)` leaves flags out of configs, and `Window:SetLoadingOrder(order)` sets the element types values apply in. Both follow Obsidian's save manager.

- **Config safety**: the status line shows `(unsaved changes)` when the settings differ from the loaded config. **Load** asks before it discards unsaved changes, **Create** asks before it overwrites a config with the same name, and the status line says so when the executor has no file functions. `Window:HasUnsavedChanges()` is new.

- **Key combos**: a keybind or `BindToggle` takes a key with Ctrl, Shift or Alt, such as `"Ctrl+K"` or `"Shift+F3"`. Plain keys work as before and are saved the same way.
- **Keybind capture**: Backspace or Delete clears a keybind, Escape cancels, and a modifier pressed on its own does not bind.
- **Keybind conflicts**: a keybind that takes a key already used by another keybind or a toggle binding shows an amber chip and a notice naming the other one.
- **Window toggle key**: `ToggleUIKeybind` and `Window:SetKeybind` take combos too.
- **Home world clock**: an analogue face with turning hour, minute and second hands, the digital time, the city of the chosen GMT offset and the date. The hands and the digits come from one UTC time plus the offset.
- **Home**: an In server card with headshots of the players, a rotating Tip card (`Home.Tips`), a Shortcuts card (`Home.Shortcuts`), and a time-of-day greeting in the banner unless `Welcome` is set.
- **Executor check** before the key gate. It runs the UNC tests and stops the load below 70 (`UNC = { Fail = 70, Warn = 80 }`), shows a banner from 70 to 79, and loads normally from 80. `UNC = false` skips it. `Library:GetExecutorScore()` returns the score.
- **Status cards** while the executor check runs and while the protected script loads. The window's own loader takes over when the window opens.
- **Close button** on the key gate. It closes the gate and stops the load.
- **Fonts**: a Font picker in Configs with 17 fonts. Fifteen come with Roblox and need no download. Two are downloaded presets: `Tahoma8` (pixel Tahoma 8px) and `ValleySans`. The choice is saved with the configs. API: `Library:SetFont`, `Library.FontPresets`, `Library.BuiltinFonts`, `Library.FontOrder`, `Library.DefaultFont`.
- **Background music**: `Window:SetMusic`, `SetMusicPlaying`, `IsMusicPlaying`, `SetMusicVolume`, `GetMusicVolume`. A Music group appears in Configs once a track is set.
- **3D preview toolbar**: reset the view, pause or play the spin, zoom in, zoom out, and cycle the lighting presets. The mouse wheel zooms while the pointer is over the preview. Lighting presets live in `Library.ViewportLights`. New options: `Lighting`, `Glow`, `Shadow`, `Toolbar`. New methods: `SetPitch`, `Zoom`, `ResetView`, `SetLighting`, `SetGlow`, `SetShadow`, `GetInfo`.
- **Dependency boxes**: `Tab:DependencyBox({ Depends = toggle, Value = true })` shows its controls only while the other control holds that value.
- **Log element**: `Tab:Log` with timestamps, colours, a Clear button, and the methods `Log`, `Clear` and `GetLines`.
- **One-time welcome**: `Window:Welcome({ Key, Title, Text, Button })` and `Window:ResetWelcome(key)`.
- **`Window:OnUnload(callback)`** runs when the window is destroyed. Use it to stop your own loops and connections.
- **Hidden egg on Home**: a Code input that stays hidden until you tap the Home avatar five times within four seconds. Typing the secret phrase shows a Play button. Play shows a picture full screen with a sound, then kicks the player. Both files download into the workspace folder.
- **Motion**: buttons squeeze when pressed and spring back, and the ripple starts at the press point. A band of light sweeps across a button on hover. Dialog buttons get the same press feel. A keybind waiting for a key shows three bouncing dots.
- **Button wave**: the press ripple is a wave of light from the press point that spreads toward the corners and fades as it goes.
- **Keybind ring**: while a keybind waits for a key, a soft ring breathes around the box.
- **Input underline**: an accent line grows out from the middle while the field has focus.
- **3D preview**: zoom and reset ease in; a flick keeps the model turning; drag up or down to tilt; two quick presses reset the view; the glow brightens on hover.
- **Popped-out preview**: a 3D preview inside a popped-out group box has a grip in its bottom-right corner; drag it to resize the preview.
- **UNC cache**: a passing executor check is kept for six hours (`UNC = { Cache = false }` turns that off). A failing card lists the missing features.
- **Check progress**: the executor check shows a progress bar with the number of tests done.
- **Floating group boxes**: a popped-out box has a grip in its bottom-right corner that changes its width, kept for the next pop-out. Pressing a floating box brings it to the front of the others.
- **Preview pop-out**: the 3D preview has a pop-out button in its header, like a group box's. It floats the preview in its own panel, which the header drags; the button or the slot docks it back with the same flight as a group box. A floating preview's grip changes its width and height.
- **Viewport handles**: a viewport handle now exposes `Window`, `Media`, `Camera` and `World`, so an overlay can draw on it.
- **Brand mark**: a round badge with an accent ring on the window header, the loader and the key gate.
- **Discord invite** `https://discord.gg/deVVQEVybd` is used by the Home example, the key gate and the executor card.
- **Player list**: `Tab:PlayerList({ Name, Height, Actions })`, a live list of the players in the server. Each row has the avatar, the name, the team colour and the distance, and a small button for each action you give it. Rows follow players joining and leaving.
- **R6 and R15 tests**: the test checks both rigs side by side, with the skeleton bones, the box, the health bar and the text.
- **UI segmented control**: `Tab:Segmented({ Name, Desc, Options, Default, Callback })` shows its choices as pills, with the chosen one lit. `Tab:CreateSegmented` is the same. The example has a demo on the Objects page.
- **Credits**: the README credits the developer (longtokai) and the testers (dokkimane, longtokai).
- **Backdrop test**: `tests/backdrop_test.lua` runs the backdrop's light step on its own, with plain Lua.

### Changed

- **Colours**: the surfaces, strokes, accent and text moved to a neutral dark grey with a lilac-blue accent, close to the default palette of Starlight Interface Suite. Only colour values changed; no code was copied.

- **Activity and Notes** sit side by side at the same height.

- **Home rebuilt**: the live numbers are four tiles (FPS and ping with a bar history, players in the server, session time). Activity and Notes sit side by side, and the cards keep one style. The `Stats` option no longer chooses the tiles; the four are fixed.

- **Home cards**: every card heading has an icon tile, a bold title and a short line under it. The cards share one 12 px corner, and long titles are cut at the end instead of pushing past the card. The egg input is unchanged.
- **Home banner**: a little taller, the avatar is bigger and sits inside a thin accent ring, the greeting is in the accent colour, and Home cards have 12 px between them.
- **Configs are an addon**: the config code, the config manager, the Home config line and the cloud configs moved from `Source.luau` to `addons/Config.luau`. Load it after the library, as the example does. The API names are unchanged. The library hands an addon its helpers through `Library._ui`, its window and tab classes through `Library._classes`, and two hooks through `Library._flagHooks` and `Library._homeCards`.

- **Clean console**: problems the library works around (a download that failed, an icon missing from the set, a font this client lacks, an internal guard that caught an error) are kept in `Library:GetDiagnostics()` instead of printed. Warnings remain for your own callback errors, a protected script that fails to load, and a wrong `SetMusic` id.
- **Home**: the config line under the banner shows a status dot: green when saved, amber when there are unsaved changes, grey when no config is loaded.

- `ConfigurationSaving.Enabled` did nothing and is removed from the docs and the example. Only `FolderName` and `FileName` are read.

- **Settings are kept by configs, not saved on their own**: the font, the watermark and keybind-list switches and their positions, the island position, the clock zone, and the background music and volume are part of the configs the player creates. The font starts at the default until a config loads. The cloud sort lasts for the session.

- `Keybind` `Callback` gets the held modifiers as a second argument, `{ Ctrl = true, ... }`, empty for a plain key.
- `Keybind` `OnChanged` and `Get()` return the combo text for a combo, and the `KeyCode` for a plain key as before.
- Keybinds and toggle bindings do not fire while a text box has focus.

- **Sliders**: the filled part runs from a deeper accent at the start to the bright accent at the knob, and the knob has a light ring so it stands clear of the track.
- **Dialogs**: the icon and a hairline along the top take the dialog's type colour (success, warning or error), and the card has a faint sheen.
- **Groupbox headers**: the icon sits in a small accent-tinted tile, and a hairline separates the header from the body on every tab.
- **Keybind list**: each key is a keycap chip, a dot lights up in the accent colour while its toggle is on, and hold or toggle is written beside the key.
- **Watermark**: a pill with an accent dot before the title, and small FPS, PING and TIME labels with their values beside them. FPS and ping are coloured green, amber or red by how good they are.
- **Home world clock hands**: each hand is now a frame centred on the face, so the hands turn about the middle of the clock instead of drifting off it.
- **Home**: cards have a faint light along the top, the banner has an accent line along its top edge, and each stat figure has an accent bar beside it.
- **Example**: has an `ESP` tab, like Main. It loads `ESP.luau` from this repo; `Source.luau` never builds the ESP.
- **ESP is not in the library**: `Source.luau` never builds it. `Example.luau` loads `ESP.luau` from this repo and shows the ESP tab. Its docs are in `esp/`.

- The executor check waits at most four seconds for a character, and stops waiting for slow tests after twelve seconds.
- Key gate redesign: wider panel, brand badge, a "Secured with Junkie" chip, a focus ring on the key input, and hover and press feel on its buttons.
- Keybind waiting state shows dots instead of `...`.
- Button ripple starts on press instead of on release.
- 3D preview: a drag does not start on the toolbar.
- The Loader and the Example no longer force a font.
- README and llms.txt document all of the above.
- **Press feel on every small button**: a press squeezes the button to 97%, and the release eases back without overshooting. The light sweeps across the visible shape only. Settings button rows and the dropdown's Select all and Clear all use the same feel.
- **FPS and ping history**: each bar keeps the colour it was read with. The newest bar is strongest, older bars fade, and empty slots are dim.
- **Execs**: the count on the home card is read again on every stats tick, so a run from another session shows up.

### Fixed

- **Avatar on the Home**: one circle with the same surface and thin border as the other avatar boxes. The picture is clipped to the circle and the stand-in icon sits at its centre.

- **Right-side lines**: each page list keeps 8 px at both sides, so its scrollbar sits in the margin and no longer covers a card's right line.

- **Avatar boxes match**: the banner's avatar box was tinted accent blue, unlike the other avatar boxes. It now uses the same surface and thin border as the in-server heads, and the island's face does too.
- **Hidden avatar icon**: the stand-in icon sat 14 px off the centre of its circle. It is centred now.

- **Hide avatar** now hides the avatars in the In server card too, our own included. They swap for the user icon, like the banner avatar.
- **Card side lines**: the page lists keep 2 px on each side, so the side lines of cards, rows and the sub-tab strip sit clear of the list's edge and are no longer cut off. The store list in the Cloud tab gets the same 2 px.

- **Page margins**: every page list keeps its 24 px side margins in its position and size, not in a UIPadding. Cards that span the list (scale 1) used to run past the right margin and get cut off by the scrolling list.

- **Themes on any executor**: saving, listing, loading, the default theme and delete no longer depend on `isfile`, `isfolder` or `listfiles` being right. A name with `/` or other unsafe characters is refused.
- **Executions counter and background picture**: they read their files directly, so the count no longer resets to 0 and a picture is not downloaded again on an executor that answers `isfile` wrongly.

- **Home**: the tier chip showed the library logo, which is a full-colour mark, in red. It now shows a tier icon in the accent colour.
- **Home**: the name and avatar switches read as the opposite of the content they control. They are now labelled "Hide name" and "Hide avatar".

- **Configs on any executor**: loading, autoload, delete and reset no longer depend on `isfile`, `isfolder` or `listfiles` answering right. A config is read from its file, the picker lists the configs the library wrote, and reset removes them by name. Before, an executor that answered those wrongly could not list, load or set autoload, so autoload did nothing after a re-run.

- **Configs and switches stay in sync**: loading a config (manually, on autoload or on reset) always runs each feature's callback for a value that changed. Before, `LoadAutoload(true)` and `LoadConfig(name, true)` skipped the callbacks, so a switch showed off while its feature kept running. The second argument is gone from `LoadConfig`, `LoadAutoload` and `ResetConfig`; an extra argument in an old script is ignored.
- **No writes on their own**: building the window no longer writes `configsettings.txt`, and nothing a player changes is written until they create or save a config.
- **Autoload only points at a created config**: `Window:SetAutoload` refuses a name that was never saved, so autoload can only pick a config the player made.

- A capture no longer swallows the next press of the same key. The window's hide key ignored any press of that key within 0.2 seconds of a capture.

- **Console clean-up**: a stand-in run of the example in a minimal and a full executor found no errors. Expected fallbacks no longer print: a missing icon warns once per name, an executor without file functions stays quiet about custom fonts and the egg, an empty font name means the default font, a character whose rig cannot be read shows nothing. The unload trace lines used for diagnosis are removed.
- **Example**: the ESP tab builds inside a protected call, so an error in the ESP cannot take the Settings tab or the Unload button with it.
- **Dialogs and panels**: the light on the dialog card was a gradient on the card itself, which faded the whole card, so the dialog looked see-through. The light is now a layer of its own that fades in with the dialog. Home cards and the watermark pill had the same fade and are solid again.
- **Dialogs**: the card's sheen used a gradient that did not reach full strength, so Roblox refused to build the dialog and Unload never asked. Fixed. A dialog that cannot open now shows an error notification.
- **Dialogs**: if a dialog fails while it is being built, its half-built overlay is removed, so it cannot block every click, and the error is printed. Unload prints a short trace (started, removed) so a failure shows where it stopped.
- **Dialogs**: the buttons and the backdrop ignore input for a quarter of a second after a dialog opens, so the click that opened it (Unload, for one) cannot also press Confirm. Unload asks first again.
- **Unload**: the window is now removed even when Unload runs on a thread that lost access to the GUI. The window is hidden first, then destroyed, and the library's own screen guis are removed with the last window, so nothing stays on screen or clickable. The Example's toggle button now shows on PC too.
- **Home world clock digits and date**: they are worked out from the seconds in GMT instead of os.date, so they match the hands on any device. The watermark time uses the same code.
- The SelectionBox border colour has a default now. A `BorderColor` was read but never set, which errors for the `SelectionBox` type.
- 3D preview drag on touch screens follows the finger, so dragging right turns the model right.
- Button wave now starts where the mouse or finger really pressed. Before, a touch screen could show it in a fixed spot.
- Button wave: presses on the right side of a button no longer show the wave toward the middle when the window is scaled down. The wave is now placed in the button's own units.
- Sliders jumped to the pointer when pressed in the empty space above or below the bar. The press catcher now hugs the bar, so only the bar and the knob start a drag.
- Bold text fell back to BuilderSans when the chosen font family had no bold face. It now falls back to that family's regular face.
- The egg no longer needs a Roblox video upload.
- **Preview spins again after it is popped out.** The window called its listeners one after another without protection, so one listener that errored stopped the rest, the preview's spin among them. Each listener now runs under `pcall`, and a failing one is reported once.
- **Button wave no longer spills out.** Compact buttons drew the wave over the whole card, description included. The wave, the squeeze and the light now belong to the visible box.
- **One wave per click.** Compact buttons and the dropdown no longer draw a second wave on click.
- **Report popup**: the reasons sit in a grid inside the card. Before, four reasons ran past the card's left edge.
- **Buttons that size themselves to their text** no longer stretch on press. They show a press as a colour change, because a button that follows its own text cannot hold a child sized by scale.
- **A popped-out preview keeps spinning** while the main window is closed.
- **Path names** in the file list drop Windows separators too, so a file name is read the same on both systems.
- **Backdrop light** follows the Backdrop Tint. Before, the glow, the embers, the petals, the matrix and the fireflies stayed on at zero tint; now they go out with it, and snow and rain are unchanged.

### Removed

- **The old stats card** and its graph and figure helpers, replaced by the tiles.


- `assets/egg.mp4` is no longer used, so it is left out of the package. The video showed a black screen with no sound on the tested executor.
- The hidden egg in the key gate, moved to Home.
- The forced `Tahoma8` font in the Loader and the Example.
- The music track and its ID from the Example.


## [0.1.0] - the fork

The first version of the library, forked from an earlier UI project and rebranded as HawkTokaiLib. Every reference to the old name is replaced.

### Added

- Watermark with a corner readout (`SetWatermark`, `SetWatermarkEnabled`).
- Keybind list overlay (`SetKeybindListVisible`).
- `BindToggle` with Toggle and Hold modes.
- Code block element with a copy button and Lua syntax highlighting.
- World clock on Home with 38 time zones (GMT-12 to GMT+14), shared with the watermark.
- Edge glow on the sub-tab row.
- 3D viewport with a gradient backdrop, an accent glow, a ground shadow and warmer default lighting.
- Key system: `RequireKey` with Keys, Validate and Junkie support, a saved key, and `RunProtected`.
- Junkie SDK integration for the key check and the key link.
- The HawkTokai logo, embedded in the library.

### Changed

- The license card is removed from Home. The key expiry moved to the profile chip.

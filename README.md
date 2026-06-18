# Open RTS

![Open RTS](./media/screenshots/screenshot_1400x650.png "Open RTS")

Open Source real-time strategy game made with Godot 4.

## Purposes of this project

This game is not going to be a very advanced RTS that would compete with other games of this genre. Instead, it will focus on simplicity and clean design so that it can:
 - showcase Godot 4 capabilities in terms of developing RTS games
 - provide an open-source project template for creating RTS games
 - educate game creators on creating RTS game mechanics

## Features

 - [x] 1 species
 - [x] 2 resources
 - [x] resource refineries as forward drop-off points with late-tech ore purifier yield boosts
 - [x] base power economy with basic and late-tech reactor plants
 - [x] structure selling with resource refunds
 - [x] barracks with rifle, rocket, flak, heavy machinegun, shock, grenadier, mortar, cryo, sniper, rail sniper, saboteur, infiltrator, and commando infantry production
 - [x] terrain and air units with scout, interceptor, gunship, rocket gunship, bomber, and heavy airship roles
 - [x] deathmatch mode (human vs AI or AI vs AI) with Easy, Normal, and Hard AI profiles
 - [x] base-elimination win/loss conditions with mission result screen
 - [x] runtime player switching
 - [x] basic fog of war
 - [x] units disappearing in fog of war
 - [x] radar-gated minimap with low-power outages
 - [x] tech-gated support powers and superweapons: radar sweep, orbital strike, EMP pulse, chrono relay, shield overdrive, nanite repair swarm, weather storm, strategic missile, and paradrop
 - [x] tech-gated advanced defense towers, prism obelisks, and powered electric perimeter segments
 - [x] swarm movement to position
 - [x] swarm movement to unit
 - [x] attack-move, guard-area, Alt force-move, scatter, and visible Shift-queued waypoint commands for mobile combat units
 - [x] patrol orders that keep mobile combat units cycling between two points
 - [x] hold-position stance for combat units
 - [x] control groups, camera bookmarks, production-building shortcuts with Shift+Alt same-type selection and multi-structure production queuing, and all-army selection hotkeys
 - [x] pause-menu game speed control for slower tactical play or faster skirmish cleanup
 - [x] engineer, mobile crawler, and powered repair-pad repairs
 - [x] engineer capture of enemy structures and saboteur infiltration that steals resources from economy targets
 - [x] expanded tech-gated vehicle roster with scout armor, deployable mobile construction vehicles, deployable siege drill tanks, missile support, tesla crawler, siege walkers, mobile repair, mobile shielding, mine-laying area denial, anti-air, electronic warfare, railgun, and lance beam armor
 - [x] AI mixed offense using vehicles, infantry, aircraft production lines, engineer capture raids, tactical support powers, enemy-facing production placement, and enemy-facing base defenses
 - [x] splash damage for artillery and bomber units
 - [x] temporary wreckage and scorch marks for destroyed visible units
 - [x] multi-step tech tree buildings
 - [x] veteran and elite combat unit progression
 - [x] simple UI
 - [x] polished UI with expanded 6x6 production and construction command panels, generated command art, and Web-safe runtime icon fallbacks
 - [x] sounds and voice feedback with unit selection/order acknowledgements, low-power alerts, construction/repair/sell cues, capture/loss/promotion/crate cues, tactical support-power, and superweapon warning cues
 - [x] music
 - [x] VFX

## Godot compatibility

The current release and Web export are developed with Godot `4.6.3`.

 - use Godot `4.6.3` for release exports and browser builds.
 - older compatibility branches are kept for historical engine support.

 - support for Godot `4.2` is available on `godot-4.2-support` branch.
 - support for Godot `4.1` is available on `godot-4.1-support` branch.
 - support for Godot `4.0` is available on `godot-4.0-support` branch.

## Web build

The browser build is published from `docs/` for GitHub Pages. Configure Pages to deploy from the `main` branch and `/docs` folder.

Useful release commands:

 - `make release-smoke` runs the focused release gate for menus, skirmish setup, unit registry, command-panel icons, support powers, AI support powers, win/loss flow, and release debug flags.
 - `make final-check` runs the full automated manual regression suite plus release smoke/showcase scenes before treating a build as final.
 - `make manual-tests TEST_SCENES=TestCommandIconRender,TestHudCommandPanel` runs selected automated manual scenes while developing focused fixes.
 - `make publish-web` refreshes the Web export and validates the packaged `docs/index.pck`.
 - `make publish-web-verified` runs the release smoke gate first, then refreshes and validates the Web export.
 - `make publish-web-final` runs `final-check`, refreshes the Web export, and validates the packaged `docs/index.pck`.

## Screenshots

![Screenshot 1](./media/screenshots/screenshot_2_1920x1080.png "Screenshot 1")

![Screenshot 2](./media/screenshots/screenshot_3_1920x1080.png "Screenshot 2")

![Screenshot 3](./media/screenshots/screenshot_4_1920x1080.png "Screenshot 3")

## Contributing

Everyone is free to fix bugs or perform refactoring just by opening PR. As for features, please refer to existing issue or create one before starting implementation.

## Credits

### Core contributors
 - Pawel Lampe (Lampe Games)

### Contributors

See [contributors](https://github.com/lampe-games/godot-open-rts/graphs/contributors) page.

### Assets
 - 3D Space Kit by [Kenney](https://www.kenney.nl/assets/space-kit)
 - RTS concept icons generated for this project with OpenAI image generation, including a Red Alert 2-inspired support/advanced-tech pack.
 - Procedural RTS SFX and loopable music generated for this project with FFmpeg.

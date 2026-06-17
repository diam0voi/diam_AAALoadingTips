# [oSB] Loading Screen AAA Gaming Tips

A lightweight, non-intrusive mod written using OpenStarbound framework for Starbound game that adds AAA-games stylished gaming tips to the loading screen! It also provides a non-admin `/tip` chat command so players can pull tips manually in-game!

Half of all credits goes to genius Silver Sokolova!

## Features

- **Loading Screen Integration:** Smooth, wrapped, and colorized tips fade in and out during the *boot screen*!
- **In-Game Chat Command:** Anyone can type `/tip` in chat to see a random tip from their mod pool! it can be *base game* tip only, *specific mod* tip only, or *mixed*. Also type `/tip help` to see auto-detected mods with tips beside the base game!
- **Failsafe Design:** Safe checks that *won't let the game crash* or spam *useless* info in logs if something goes wrong or if you're running on default Starbound/other forks!
- **Dynamic Filtering:** Zero bloat. The pool *automatically* excludes tips from mods that aren't currently active!
- **Every mod support:** Anyone can patch tips config to add exclusive tips or change something, since patches have higher priority!

### Active Mod Aliases

Below is the list of built-in short names and aliases you can use with the `/tip <category>` command.

| Mod Name | Supported Aliases |
| :--- | :--- |
| **Base game** | `vanilla`, `base`, `v`, `game`, `starbound`, `sb`, `original`, `official` |
| **Arcana** | `arc`, `rcn`, `sva` |
| **Shellguard Expansion** | `sge`, `sg` |
| **Project Redemption** | `redemption`, `pr` |
| **Starforge** | `tsf`, `sf` |
| **Maple32** | `maple`, `m32`, `lemon` |
| **Lostbound** | `lost` |
| **Elithian Races** | `elithian`, `avikan`, `aegi`, `er` |
| **patman famous** | `patman`, `patmanf`, `parice`, `scungus`, `brongus`, `pat` |
| **Starburst Rework** | `starburst`, `sbrr`, `sr` |
| **Cosmosburst** | `cosmburst`, `cbr`, `acsr`, `srac` |
| **Ancient Cosmos** | `ac`, `pac` |
| **Enhanced Storage** | `storage`, `enhanced`, `neo` |
| **Frackin' Universe** | `fu` |

---

## Manual installation

1. Download the latest release.
2. Place the mod folder or `.pak` file inside your Starbound `mods` directory:
   `Starbound/mods/`

Or simply sub to my mod on Steam! 

---

## YOUR OWN TIPS!

This "framework" is built to be mod-friendly. You **don't** need to ask to make your mod supported; you can simply patch your tips into by yourself!

### Patch example

Create a file named `splash_tips.config.patch` in your mod's root directory and edit this example:

```json
[
  {
    "op": "add",
    "path": "/modTipsData/MyCoolMod2",
    "value": {
      "checkPath": "/items/generic/crafting/mycoolitem2.item",
      "specialName": "^#00ffff;My^#ff00ff;BEST^#ffff00;Mod2^reset;",
      "color": "ffffff",
      "aliases": ["mycoolmod2", "mycm2"],
      "tips": [
        "You can use ^#d35eae;colored text^reset; directly inside your tips!",
        "To use double quotes inside a tip, escape them with a backslashes like this: \"quoted text\"."
      ]
    }
  }
]
```

### Configuration values info:
- **`checkPath`** (Required): A unique **full** asset path (can be a `.species`, `.object`, `.png`, etc.) so my thingie can check if *the mod for which the tips are written is installed* on the player's side;
- **`color`** (Optional): String, 6-digit hex code to automatically apply plane color to your mod's name;
- **`specialName`** (Optional): String, a high-priority key that **overrides** the `color` property! Use this if you want to make every letter colorful using Starbound carets (like `"specialName": "^#D19B31;Ar^#AB544B;ca^#8A8CBF;na^reset;"`) or change the mod's name appearance;
- **`aliases`** (Optional): Array of shortnames, for players to type into the `/tip <name>` command;
- **`tips`** (Optional): Array of tips, supports Starbound inline caret colors! Keep them under ~120 characters for clean wrapping on loading screens.
### Overriding existing values (`replace`)
Because whole system is entirely data-driven, you can easily create `replace` patches to customize other mods' configurations or add new aliases to them in one patch.

```json
[
  {
    "op": "replace",
    "path": "/modTipsData/Lostbound/color",
    "value": "ff55ff"
  },
  {
    "op": "add",
    "path": "/modTipsData/Arcana/aliases/-",
    "value": "arcana_expansion"
  }
]
```

## Repo structure:
```
.
│   .gitattributes
│   .gitignore
│   LICENSE
│   player.config.patch
│   README.md
│   splash_tips.config
│   _metadata
│   _previewimage
│
├───.github
│   └───workflows
│           generate-clean-release.yml
│
├───cinematics
│       splash.cinematic.patch.lua
│
└───scripts
        aaatips_command.lua
```

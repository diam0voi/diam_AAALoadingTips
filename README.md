# [oSB] Loading Screen AAA Gaming Tips

A lightweight, non-intrusive mod written using OpenStarbound framework for the Starbound game that adds AAA-games stylished tips to the loading screen! It also provides a non-admin `/tip` chat command so players can pull tips manually.

Half of all credits goes to genius [SilverSokolova](https://github.com/SilverSokolova)!

## Features

- **Animated tips during loading (currenly only on game boot);**
- **In-game chat command:** it works even without oSB and has 4 attributes: type `/tip ` or `/tip <category>` to get random tip, `/tip aliases` to get the full list of what`<category>` thing understands, `/tip reload` to rebuilt the tips pool if you debugging, and `/tip ?` or `/tip help` to get a reminder + list of mods with tips;
- **Failsafe design:** there are lots of safety checks that *won't let the game crash* or spam *useless* info in logs if something goes wrong or if you're running on default Starbound/heavy modpacks;
- **Dynamic filtering:** final pool *automatically* excludes tips from mods that aren't currently active or when some tips were done incorrect, zero bloat;
- **Every mod support:** Anyone can patch tips config to add exclusive tips or change something.

### Manual installation from GitHub

In case you dont wanna install it from Steam:

1. Download the latest .zip release.
2. Place the unpacked folder inside your Starbound `mods` directory:
   `.../Starbound/mods/`

---

## Aliases

Below is the list of aliases you can use with the `/tip <category>` command as a demo, but thats not all, check `/tip aliases`!

There is always a `mod name` auto-alias for convenience, e.g. `project redemption`.

| Mod Name | Supported Aliases |
| :--- | :--- |
| **Base game** | `v`, `base`, `vanilla`, `official`, `starbound` |
| **Arcana** | `arcn` |
| **Shellguard Expansion** | `sg`, `sge`, `shellguard` |
| **Project Redemption** | `pr`, `redemption` |
| **The Starforge** | `sf`, `tsf`, `starforge` |
| **Maple32** | `m32`, `maple` |
| **Lostbound** | `lstbnd` |
| **Elithian Races** | `er`, `aegi`, `avikan`, `elithian` |
| **brongus drive** | `patman`, `patmanf`, `brongus` |
| **Starburst Rework** | `sbr`, `stbrst` |
| **Project Ancient Cosmos** | `ac`, `projectac`, `ancncsms`, `ancient cosmos` |
| **Cosmosburst** | `cbr`, `sbrac`, `cosmbrst` |
| **Enhanced Storage** | `storage` |
| **Raiizy's Forge** | `rf`, `raiizyforge` |
| **Frackin' Universe** | `fu` |

---

## YOUR OWN TIPS!

This project is built to be mod-friendly. You **don't** need to ask to make your mod supported; you can simply patch your tips into by yourself! Or feel free to suggest some

#### Patch example

Create a file named `splash_tips.config.patch` in your mod's root directory and edit this example:

```json
[
  {
    "op": "add",
    "path": "/modTipsData/MyCoolMod2",
    "value": {
      "checkPath": "/items/generic/crafting/mycoolitem2.item",
      "color": "ffffff",
      "specialName": "^#00ffff;My^#ff00ff;BEST^#ffff00;Mod2^reset;",
      "aliases": ["mycoolmod2", "mycm2"],
      "tips": [
        "You can use ^#d35eae;colored text^reset; directly inside your tips!",
        "To use double quotes inside a tip, escape them with a backslashes like this: \"quoted text\"."
      ]
    }
  }
]
```

Then, in your `_metadata` file, add this line at the end:

```json
"includes" : ["diam_AAALoadingTips"]
```

(don't forget the other lines as well lol)

### Configuration values info

- **`checkPath`** / **`checkPaths`** (Required unless using `checkAnyPath` or `alwaysActive`): *String* OR *Array of strings*. Checked to verify *whether the target mod(s) are installed on the player's side.*
  - If `checkPaths` array is given: passes if *all* the listed paths exist (AND logic - e.g. for tips about mods compatibility and such).
  - if `checkAnyPath` array is given: passes if *at least one* listed path exists (OR logic - e.g. useful for a Lite/Full mod editions). Can be combined with a singular `checkPath` for whatever reason???
  - If `"*"` is given: passes immediately.
- **`alwaysActive`** (Optional): *Boolean*. If `true`, skips all path checks and always loads this category's tips.
- **`color`** (Optional): *String*. Hex code (`"ff9933"` or `"#ff9933"`, supports 3/4/6/8-digit hex) to apply a plain color to your mod's name. Defaults to `"ffffff"`.
- **`specialName`** (Optional): *String*. A high-priority key that **overrides** the `color` property! Allows to customize the mod's display name and color it per-character.
- **`aliases`** (Optional): *Array of strings*. Shortnames for players to type into the `/tip <category>` command. Case-insensitive; reserved names (simply commands) and aliases already claimed by an earlier mod (sorted alphabetically) are skipped.
- **`tips`** (Required): *Array of strings*. Supports Starbound inline caret colors (named colors like `^cyan;`, 3/4/6/8-digit `^#hex;`, and `^reset;`; unsupported tags are automatically stripped). Keep them under ~120 characters for clean wrapping on loading screens.

> **Note:** On OpenStarbound, any popular asset extension (`.png`, `.ogg`, `.lua`, etc.) works; yet in case the game misbehaves - switch to JSON-based files (`.object`, `.item`, `.species`, etc.).


### Overriding existing stuff

You can easily create patches to customize other mods' tips or add something new to them in one patch.

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

## Repo structure

```
.
│   .gitattributes
│   .gitignore
│   .pre-commit-config.yaml
│   CONTRIBUTING.md
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

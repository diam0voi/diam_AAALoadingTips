# [oSB] Loading Screen AAA Gaming Tips

A lightweight, non-intrusive mod written using OpenStarbound framework for Starbound game that adds AAA-games stylished, context-aware gaming tips to the loading screen! It also provides a non-admin `/tip` chat command so players can pull tips manually in-game.

The framework scans the player's active mod list dynamically. Players will only see tips for the mods they actually have installed.

Half of all credits goes to genius Silver Sokolova!

## Features

- **Loading Screen Integration:** Smooth, wrapped, and colorized tips fade in and out during the loading cinematic!
- **In-Game Chat Command:** Anyone (including non-admins) can type `/tip` in chat to see a random tip from their pool!
- **Every mod support:** Anyone can patch original config to add exclusive tips or updated already existed ones!
- **Dynamic Filtering:** Zero bloat. The pool automatically excludes tips from mods that aren't currently active!
- **Failsafe Design:** Safe checks that won't crash the script if a mod is uninstalled or if you are running on vanilla Starbound/other forks.

---

## How to Install

1. Download the latest release.
2. Place the mod folder or `.pak` file inside your Starbound `mods` directory:
   `Starbound/mods/`

---

## How Modders Can Integrate Their Own Tips

This framework is built to be modular. You do not need to ask to make your mod supported; you can simply patch your tips into from your own mod.

### Example Patch Structure

Create a file named `splash_tips.config.patch` in your mod's root directory and edit this example:

```json
[
  {
    "op": "add",
    "path": "/modTipsData/MyAwesomeMod",
    "value": {
      "color": "ffffff", 
      "checkPath": "/items/active/weapons/myuniquestuff.activeitem",
      "tips": [
        "my tip #1",
        "my tip #2"
      ]
    }
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

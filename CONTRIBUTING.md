# Contributing to AAALoadingTips

Thanks for checking on this file!
It is a small project, so only a few components are utilized to keep things clean and shiny.

## Project layout

- `splash_tips.config`: built-in tip database;
- `cinematics/splash.cinematic.patch.lua`: boot screen tips rendering logic;
- `scripts/aaatips_command.lua`: `/tip` chat command logic;
- `player.config.patch`: makes the command available for players;
- `.github/workflows/generate-clean-release.yml`: current ci/cd;
- `cog.toml`: changelog builder;
- `.pre-commit-config.yaml`: local lint/format hooks.

---

## Git hooks: auto code style & validation

This repo uses local pre-commit git hooks to automate all the boring processes, including formatting!

To enable them locally:
1. Install [prek](https://github.com/j178/prek) (recommended, 0 dependencies) or [pre-commit](https://github.com/pre-commit/pre-commit) CLI utility by whichever way you prefer, so that your OS can detect it;
2. Activate the hooks from any terminal shell by running command in the repo root:
   - for `prek`: `prek install`
   - for `pre-commit`: `pre-commit install`
3. Hooks will now run automatically on each git commit or manually on `prek`/`pre-commit` command.

> If you use `pre-commit` and the commit-msg hook is missing, run:
> `pre-commit install --hook-type commit-msg`

### Code style and validation

Patches and config files are checked as JSON, and Lua files are formatted with default StyLua.

Don't forget to keep new tips under ~120 characters so they wrap cleanly on boot screen. Overall rules for working with tips follow the README guideline.

### Commit messages

Commit messages must comply with [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#specification), they are also checked by hooks.
See comprehensive commit types list [here](https://github.com/pvdlg/conventional-changelog-metahub#commit-types).

Example:

```text
fix(tips): correct 67 typos in the base game tips
```

#### (Optional): interactive Conventional Commit message wizard

There is actually no need to keep specification on your screen while writing a message.
You can simply install [koji](https://github.com/cococonscious/koji) (recommended, 0 dependencies) or [commitizen](https://github.com/commitizen/cz-cli) and use it to create true Conventional Commit messages without losing any speed and having to remember the rules!

<details>
<summary>IMPORTANT: Git for Windows + koji compatibility (Actual as of 2026.08.10) <--click on me</summary>

Due to koji using Windows-nonfriendly `cocogitto` utility core (no proper shebangs mapping i guess), you may need a custom hook to make it work with `prek`/`pre-commit`.

Save the following script as `.git/hooks/prepare-commit-msg` file:

```bash
#!/bin/bash

# skip on amends, merges, and default git commit -m
COMMIT_SOURCE=$2
if [ "$COMMIT_SOURCE" = "commit" ] || [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "message" ]; then
    exit 0
fi

exec < /dev/tty
koji --hook || true
```

Then run:

```bash
chmod +x .git/hooks/prepare-commit-msg
```

Check if it works by `git commit`.

</details>

## Release preview with CI/CD

A GitHub Actions workflow creates a clean release zip containing only the mod files. It ships to Steam Workshop like that as well!

- You can also run the workflow manually to get the clean version for yourself e.g. to proceed a final check:
  1. Push your branch to GitHub;
  2. Go to the repo main page --> *Actions* tab --> *Generate Clean Release* --> *Run* workflow w/o publishing the artefact.

## Questions?

Feel free to open an issue or use any other way to contact me!

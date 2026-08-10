# Claude Mission Config Skill

> **Use this page when:** you want an AI assistant (Claude or ChatGPT) to help configure WMP features for your own mission.

_Associated Files: `.claude/skills/mission-pack-config/SKILL.md`, `.claude/skills/mission-pack-config/references/*.md`, `.claude/skills/mission-pack-config/chatgpt/INSTRUCTIONS.md`_

The Claude Mission Config Skill teaches an AI assistant how WMP's features are configured — variable names, function signatures, defaults, and known gotchas — so it can help you set up loadouts, ACRE2, jamming, the Economy suite, and everything else in this pack without guessing. It's built from the same source of truth as the rest of this documentation, split into one short reference file per feature so the assistant only has to read the parts relevant to what you're asking about.

It ships as its **own separate download**, not inside the main WMP pack zip: `mission-pack-config-<version>.zip` on the [releases page](https://github.com/AdamWaldie/WaldosMissionPack/releases), alongside the main pack, patch, Compositions, and Unit Insignias zips.

That zip has the skill folder itself at the zip root (`mission-pack-config/SKILL.md`, no extra path prefix) — the shape claude.ai's/Claude Desktop's **Upload skill** dialog and the Skills API require. It's also the zip to use for a Claude Code mission-project drop-in; see **Setup with Claude** below for the one extra manual step that needs (moving the extracted folder under `.claude/skills/`).

## What it can and can't do for you

The skill is honest about its own limits, and you should expect it to say so rather than pretend:

- It can write and explain the exact `init.sqf` / `initServer.sqf` / `initPlayerLocal.sqf` / `description.ext` / `MissionConfig\economyConfig.sqf` snippets a feature needs, and — if it's running with file-editing tools against your actual mission project — apply them directly.
- It will **never edit `mission.sqm`**, under any circumstance. Placing objects, syncing a Game Logic, editing unit loadouts in ACE Arsenal, and disabling Binarization are Eden Editor steps only you can do; the skill gives you a precise checklist instead of pretending to do them.
- It will never touch `respawnOnStart` — that must stay `-1` for the loadout-saving system to work.
- If you're using it inside your own mission project (the normal case — you downloaded a WMP release and dropped it in), it won't assume WMP's own validator scripts are available, because those are development tooling that never ships in a release. It'll do a manual sanity check of any script it writes instead.

## Setup with Claude

**Claude Code** (the CLI, or Claude Code on the web): unzip `mission-pack-config-<version>.zip` and move the extracted `mission-pack-config/` folder into your mission project at `.claude/skills/mission-pack-config/` (create the `.claude/skills/` folders if they don't already exist), so it sits alongside your `init.sqf` and `mission.sqm`. Claude Code auto-discovers project skills under `.claude/skills/` — just ask it to configure a WMP feature (e.g. *"set up ACRE2 radios for my Viking squad on channels 1 and 5"*) and it will consult the skill automatically.

**Claude.ai / Claude Desktop**: download `mission-pack-config-<version>.zip` and use claude.ai's **Upload skill** dialog (drag-and-drop or click to upload) to add it directly as a skill — no unzipping needed, the archive is already in the shape it expects. If your workflow doesn't have that dialog, the same `mission-pack-config/` folder can be uploaded as a Project's knowledge instead, or its `SKILL.md` and `references/*.md` pasted in directly. Claude won't have file access to your mission project unless you're in an environment that grants it, so expect it to hand you snippets to paste yourself rather than edit files for you — this is the "patch mode" the skill describes internally.

## Setup with ChatGPT

ChatGPT has no equivalent to Claude Code's project-skill auto-discovery and no filesystem access to your mission project, so the skill ships a second, purpose-written entry point for it: `.claude/skills/mission-pack-config/chatgpt/INSTRUCTIONS.md`.

1. Create a [Custom GPT](https://chatgpt.com/gpts/editor) (or a Project, if you're using ChatGPT's Projects feature).
2. Paste the contents of `chatgpt/INSTRUCTIONS.md` into the Custom GPT's **Instructions** field.
3. Upload every file under `references/` (including the `economy/` subfolder) as **Knowledge** files.
4. Start asking it to help configure features, the same way you would with Claude.

Because ChatGPT can't see your mission project, it will ask you to paste the relevant section of your `init.sqf` (or whichever file a feature touches) before giving you a snippet with a precise insertion point — that's expected, not a limitation of the skill itself.

## Example prompts

- *"Enable the AI rebalance system with the VETERAN profile for a new mission."*
- *"Walk me through setting up a Mobile Command Post — what do I need to do in Eden versus in script?"*
- *"My supply crates are empty, what's wrong?"* (this is almost always the ACE Arsenal loadout issue — see [Logistics, Starter Crates, and Quartermaster](Logistics-System,-Starter-Crates-And-Quartermaster))
- *"Set up a radio jammer that only affects OPFOR within 500m and can be destroyed."*
- *"I want the Economy suite running with a Medium preset for three sides — what do I put in initServer.sqf?"*

## See also

- [Mission Configuration Reference](Mission-Configuration-Reference)
- [Feature Configuration Files](Feature-Configuration-Files)
- [Coding and Documentation Standards](Coding-Standards)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

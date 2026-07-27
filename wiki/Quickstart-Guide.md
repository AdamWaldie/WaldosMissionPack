# Quickstart Guide

> **Use this page when:** you are installing WMP into a mission for the first time.

This guide gets the pack loading with its required dependencies before you enable individual features.

## 1. Download the release

Download the latest `WMP-<version>.zip` from the [WMP releases page](https://github.com/AdamWaldie/WaldosMissionPack/releases/latest). Download the separate compositions archive if you want the prepared Eden compositions.

## 2. Load the required add-ons

WMP requires:

- CBA_A3
- ACE 3

Load optional integrations such as ACRE2, TFAR, Zeus Enhanced, or LAMBS only when your mission uses them.

## 3. Copy WMP into the mission folder

Copy the contents of the WMP archive into the mission root—the folder containing `mission.sqm`. Keep the supplied folder structure intact.

At minimum, confirm these paths exist:

```text
description.ext
init.sqf
initServer.sqf
initPlayerLocal.sqf
MissionScripts\WaldosFunctions.sqf
```

## 4. Keep `mission.sqm` unbinarized

In Eden, open **Attributes → General → Miscellaneous** and disable **Binarize the Scenario File**. WMP's mission-loadout tools need to read the mission file.

Save the mission once after changing this setting and verify that `mission.sqm` remains plain text.

## 5. Configure the mission entry files

Use the [Mission Configuration Reference](Mission-Configuration-Reference) while editing:

- `description.ext` for mission identity, respawn, includes, and end screens;
- `init.sqf` for client/server-wide feature toggles and optional integrations;
- `initServer.sqf` for authoritative mission setup;
- `initPlayerLocal.sqf` for local player behavior.

Change one feature area at a time. Leave optional systems disabled until their required objects and configuration are present.

## 6. Prepare playable loadouts

Edit playable-character loadouts in Eden or ACE Arsenal before the final save. WMP can derive logistics contents and respawn loadouts from those playable units.

If ACE is loaded, disable ACE Respawn in the mission/server ACE settings when using WMP's loadout restoration. See [Loadout Saving and Respawn](Loadout-Saving-and-Respawn).

## 7. Configure optional radio support

For ACRE2, give groups clear callsigns in Eden and configure the matching radio plan in `init.sqf`. Start with [ACRE2 Long-Range Radio Presetting](ACRE-2-Long-Range-Radio-Presetting).

TFAR-compatible features are documented on their individual pages, including [Radio Jamming](Radio-Jamming).

## 8. Test in hosted multiplayer

Use Eden's multiplayer preview or host the mission locally. A single-player editor preview cannot reproduce every locality, JIP, Zeus, or interaction path.

Before wider testing, verify:

- the mission reaches the player slot screen and starts;
- no WMP script errors appear;
- CBA and ACE are loaded;
- configured ACE and vanilla actions appear as documented;
- SafeStart, ENDEX, and other mission-flow systems are in the intended state;
- [Mission Diagnostics](Mission-Diagnostics) reports expected loaded, active, disabled, and unavailable features.

## Install the compositions

The compositions archive is separate from the mission pack.

1. Close Eden before replacing compositions.
2. Open the Arma 3 profile folder under Documents.
3. Open its `Compositions` folder.
4. Remove obsolete WMP composition versions when appropriate.
5. Copy the downloaded composition folders into `Compositions`.

Compositions accelerate setup but do not replace the scripts in the mission folder.

## Where to go next

- [Feature Index](Feature-Tutorials) — choose a capability.
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules) — build or test features through Zeus.
- [Zeus and Script API Parity](Zeus-And-Script-API-Parity) — export or reproduce Zeus-authored setup in mission script.
- [Mission Diagnostics](Mission-Diagnostics) — investigate missing or inactive features.

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

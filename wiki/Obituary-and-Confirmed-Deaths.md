# Obituary and Confirmed Deaths

> **Use this page when:** you want medics to formally confirm player deaths and include those
> confirmations in the mission diary and ENDEX report.

The Obituary system is enabled by default. It records useful information when a player dies, then
allows a qualified medic to confirm that death through ACE Self Interaction. Confirming a death
does not kill, revive, delete, or otherwise alter the casualty. It only creates the report.

## Fastest working setup

You normally do not need to add a call, module, or composition:

1. Keep `Waldo_Obituary_Enable` set to `true` in `MissionConfig\interfaceConfig.sqf`.
2. Give the intended user either the vanilla **Medic** trait or an ACE Medical medic/doctor role.
3. During play, stand within the configured radius of a dead player.
4. Open **ACE Self Interact > Pronounce Dead**.
5. Select the casualty by name.

The submenu lists every eligible body in range, nearest first. This avoids guessing which body the
medic meant when several casualties are close together.

## What players receive

After confirmation, WMP publishes a formatted KIA record containing:

- casualty name;
- time of death and time of assessment;
- cause of death;
- grid reference;
- assessor name; and
- a friendly-fire warning where applicable.

Every player receives a **Confirmed Deaths - Index** diary entry and one page per player name.
Repeated deaths are separated and numbered within that player's page. WMP deliberately does not
create one diary page per corpse because a long mission could quickly approach Arma's diary limits.

Confirmed deaths also appear in the ENDEX After-Action Report. This is separate from the ordinary
KIA count: KIA records that a death happened, while Confirmed Deaths records that a medic formally
assessed it.

## Settings

Edit these rows in `MissionConfig\interfaceConfig.sqf`. They are player-local presentation and
interaction settings; WMP loads them automatically.

| Setting | Default | Beginner meaning |
|---|---:|---|
| `Waldo_Obituary_Enable` | `true` | Enables death capture and the medic self-interaction. Set this to `false` to disable the complete feature. |
| `Waldo_Obituary_ChatAnnounce` | `true` | Also shows a short confirmation line in system chat. The full report remains in the diary. |
| `Waldo_Obituary_Radius` | `15` | Maximum distance in metres between the medic and a body listed by **Pronounce Dead**. |
| `Waldo_Obituary_DiaryPollInterval` | `3` | Advanced: seconds between local diary refresh checks. Leave this alone for normal missions. |

Example with a shorter working distance and no chat line:

```sqf
// MissionConfig\interfaceConfig.sqf
["Waldo_Obituary_Enable", true],
["Waldo_Obituary_ChatAnnounce", false],
["Waldo_Obituary_Radius", 8],
["Waldo_Obituary_DiaryPollInterval", 3]
```

## Who can pronounce a death

A player qualifies when either condition is true:

- the unit has Arma's vanilla `Medic` trait; or
- ACE Medical identifies the unit as a Medic or Doctor.

This supports missions that configure medical roles through ACE without also setting the vanilla
trait. Ordinary riflemen do not receive the action.

## Respawn, multiplayer, and JIP

- Death details are captured when the death occurs, before a player disconnect or respawn can change
  the names involved.
- The ACE self-action is reinstalled on each replacement player body after respawn.
- Confirmed reports are broadcast so current players receive the same record.
- A joining player rebuilds the diary from the current confirmed-death state.
- Friendly-fire detection distinguishes an ordinary player killer from a Zeus curator remotely
  controlling a unit.

## Why there is no composition or ZEN module

This feature belongs to each medic's player object and the bodies already created by gameplay. A
placed prop would not configure or demonstrate anything necessary, and a Zeus module would duplicate
the medic workflow. Use the full audit mission when you need a controlled live test.

## Troubleshooting

### Pronounce Dead is missing

Check all of the following:

1. ACE Medical and ACE Interaction are loaded.
2. `Waldo_Obituary_Enable` is `true`.
3. Your current player body has the vanilla Medic trait or an ACE medic/doctor role.
4. At least one eligible dead player is inside `Waldo_Obituary_Radius`.
5. If you have just respawned, run WMP Mission Diagnostics and inspect the obituary and respawn rows.

### The submenu is present but empty

There is no eligible player corpse inside the configured radius. AI bodies are not treated as
player obituary entries.

### The diary report is missing

Confirm that the death was actually selected in **Pronounce Dead**. Merely dying creates the cached
death details but does not add that casualty to Confirmed Deaths.

## See also

- [ENDEX and After-Action Report](ENDEX-Script-&-Custom-End-Screen)
- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Mission Diagnostics](Mission-Diagnostics)
- [Optional Feature Systems](Optional-Feature-Systems)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

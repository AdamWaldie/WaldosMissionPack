# Team Colour Setup

> **Use this page when:** you want fireteam colours assigned from role descriptions or need the group and role helpers.

_Associated Files: MissionScripts\MissionInit\InitHelpers\SetTeamColour.sqf_

WMP assigns players to ACE3 team colours at mission start using their Eden role description. No per-unit setup is required. The function reads each player's **Role Description** field and matches it to a colour.

Called automatically from `init.sqf`. Requires ACE3. No object Init call or module placement is needed.

## How It Works

On mission start, each player's Role Description (or unit class display name as a fallback) is checked against a keyword table. The first keyword match determines the ACE3 team colour assigned to that player. The check is case-insensitive and searches for the keyword anywhere in the role description string.

## Settings: keyword-to-colour mapping

| Team Colour | Matching Keywords |
|---|---|
| **Yellow** | Squad Leader, SL, Platoon Leader, PL, Platoon Sergeant, PSG, Company Commander, CC, Commanding Officer, CO, LT, Lieutenant, Major, Captain, Colonel, 1st Sergeant, 1SG, Delta, Yellow |
| **Red** | Alpha, Red |
| **Blue** | Bravo, Blue |
| **Green** | Medic, Charlie, Green |

Players whose role description matches none of the keywords are not assigned to any team.
`Assistant Squad Leader` and `ASL` also appear in the script's Red rules, but the earlier Yellow
`SQUAD LEADER` and `SL` checks match those names first. They currently resolve to Yellow. Use an
unambiguous `Alpha` role label when that assistant should be Red.

## Quick setup: recommended role description format

For best results, use the following convention in each unit's **Role Description** field in Eden:

```
[Team/Role] [Additional Info]@[Callsign]
```

Examples:
- `Alpha Rifleman@Viking-1-1` → assigned **Red**
- `Bravo Automatic Rifleman@Viking-1-2` → assigned **Blue**
- `Alpha Deputy@Viking-1` → assigned **Red**
- `SL@Odin` → assigned **Yellow**
- `Medic@Foxhound-2` → assigned **Green**

## Disabling

To disable automatic team colour assignment, comment out this line in `init.sqf`:

```sqf
call Waldo_fnc_SetTeamColour;
```

## Adding or Changing Mappings

The keyword table is in `SetTeamColour.sqf`. To add a new keyword, append to the `_teamMapping` array:

```sqf
["FORWARD OBSERVER", "GREEN"],
```

Each entry is `["KEYWORD IN CAPITALS", "COLOUR"]`. Valid colour strings are `"RED"`, `"BLUE"`, `"GREEN"`, and `"YELLOW"`.

---

## Related Helper Functions

Two additional functions parse the same role description format. Both are useful when writing custom scripts that need to know the player's callsign or role.

### `Waldo_fnc_GetPlayerGroup`

Returns the group callsign from the **group leader's** Role Description after `@`. It falls back
to the Eden group ID only when the leader's Role Description is empty. If a nonempty description
has no `@`, the current helper has no valid callsign part to read. Give the leader a complete
`Role@Callsign` description before using this helper.

```sqf
// Returns "VIKING-1" from role description "Alpha Rifleman@Viking-1"
private _groupCallsign = [player] call Waldo_fnc_GetPlayerGroup;
```

### `Waldo_fnc_GetPlayerRole`

Returns the part of the role description **before** the `@`. If no role description is set, it returns the unit class display name.

```sqf
// Returns "Alpha Rifleman" from role description "Alpha Rifleman@Viking-1"
private _roleName = call Waldo_fnc_GetPlayerRole;
```

Both functions return an empty string (or `"Infantry"` for `GetPlayerRole`) in singleplayer.

| Function | Argument type and default | Return type and result | Where it runs |
|---|---|---|---|
| `Waldo_fnc_SetTeamColour` | None | No useful value | Current player's interface during mission startup. |
| `Waldo_fnc_GetPlayerGroup` | Position 0: unit Object, default local `player` | String after `@` in the group leader's role, or uppercase Eden group ID when that role is empty. Empty in singleplayer. | Where the unit and leader's role description are available. |
| `Waldo_fnc_GetPlayerRole` | None; always reads local `player` | String before `@` in that player's role, or the unit class display name. `"Infantry"` in singleplayer. | Player interface. |

For example, `[player] call Waldo_fnc_GetPlayerGroup` returns a string you can show in a briefing. It does not alter the player's Arma group. The colour helper runs locally and does not set a mission-wide colour for AI.

## If a colour is wrong

Check the unit's Eden Role Description first. Matching ignores case and takes the first keyword in
the script's search order. For example, `ASL` contains `SL`, and the Yellow `SL` check currently
runs first. Use an unambiguous label such as `Alpha Deputy` for a Red assistant and test with ACE
team colours loaded.

## See also

- [Loadout Saving and Respawn](Loadout-Saving-and-Respawn)
- [Mission Configuration Reference](Mission-Configuration-Reference)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

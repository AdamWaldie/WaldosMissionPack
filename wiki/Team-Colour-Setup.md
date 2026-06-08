_Associated Files: MissionScripts\MissionInit\InitHelpers\SetTeamColour.sqf_

Automatically assigns players to ACE3 team colours at mission start based on their role description set in the Eden Editor. No per-unit configuration is required — the function reads each player's **Role Description** field and matches it to a colour.

Called automatically from `init.sqf`. Requires ACE3.

## How It Works

On mission start, each player's Role Description (or unit class display name as a fallback) is checked against a keyword table. The first keyword match determines the ACE3 team colour assigned to that player. The check is case-insensitive and searches for the keyword anywhere in the role description string.

## Keyword-to-Colour Mapping

| Team Colour | Matching Keywords |
|---|---|
| **Yellow** | Squad Leader, SL, Platoon Leader, PL, Platoon Sergeant, PSG, Company Commander, CC, Commanding Officer, CO, LT, Lieutenant, Major, Captain, Colonel, 1st Sergeant, 1SG, Delta, Yellow |
| **Red** | Assistant Squad Leader, ASL, Alpha, Red |
| **Blue** | Bravo, Blue |
| **Green** | Medic, Charlie, Green |

Players whose role description matches none of the keywords are not assigned to any team.

## Recommended Role Description Format

For best results, use the following convention in each unit's **Role Description** field in Eden:

```
[Team/Role] [Additional Info]@[Callsign]
```

Examples:
- `Alpha Rifleman@Viking-1-1` → assigned **Red**
- `Bravo Automatic Rifleman@Viking-1-2` → assigned **Blue**
- `ASL@Viking-1` → assigned **Red**
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

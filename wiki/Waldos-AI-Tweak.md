_Associated Files: MissionScripts\AiScripting\AISkillAdjustmentSystem.sqf_

This script adjusts AI sub-skill values to create a more responsive and balanced PvE experience. When used alongside LAMBS Danger, it unlocks additional AI behaviours that make enemies more dynamic while remaining manageable.

The system applies to **both pre-placed units and Zeus-spawned units** — Zeus curators are automatically patched at initialisation time to ensure consistent difficulty across the full mission.

## Modes

Two modes are available: `DAY` and `NIGHT`. Select which is active by commenting/uncommenting the appropriate line in `init.sqf`:

```sqf
"DAY" call Waldo_fnc_AITweak;   // use for daytime missions
// "NIGHT" call Waldo_fnc_AITweak; // use for nighttime missions
```

Below is the DAY mode function, uncommented, which places the AI into daytime mode.
!["DAY" call Waldo_fnc_AITweak;](https://i.imgur.com/N1YXEBx.png)

---

## DAY Mode

Applies a uniform, moderately challenging skill profile to all AI regardless of faction or role.

| Sub-skill | Value | Effect |
|---|---|---|
| `aimingspeed` | 0.42 | Moderate target acquisition speed |
| `aimingaccuracy` | 0.83 | Good accuracy at range |
| `aimingshake` | 0.36 | Controlled weapon shake |
| `spottime` | 0.80 | Slightly slower than vanilla at spotting |
| `spotdistance` | 1.00 | Full spotting range |
| `commanding` | 1.00 | Full command responsiveness |
| `general` | 1.00 | Full general skill |

---

## NIGHT Mode

Night mode applies faction-aware and role-aware skill values, and responds to actual in-game lighting conditions.

### Lighting-Based Spotting

| Condition | Has NVG (`hmd` equipped) | No NVG |
|---|---|---|
| Dark (lighting ≤ 5) | `spottime` / `spotdistance` = **0.015** — nearly blind | `spottime` / `spotdistance` = **0.52** — heavily degraded |
| Lit area (lighting > 5) | `spottime` / `spotdistance` = **1.00** — full | `spottime` / `spotdistance` = **1.00** — full |

This means NVG-equipped AI are extremely effective in their environment, while AI without NVGs are severely limited in dark conditions — closely matching realistic night-combat dynamics.

### Faction Awareness

Some factions receive an elevated skill profile to reflect elite status:

| Sub-skill | Elite factions | Default factions |
|---|---|---|
| `general` | 1.00 | 0.90 |
| `commanding` | 0.95 | 0.75 |
| `courage` | 1.00 | 0.75 |
| `aimingspeed` | 0.72 | 0.62 |
| `aimingaccuracy` | 0.92 | 0.83 |
| `aimingshake` | 0.26 | 0.36 |
| `reloadSpeed` | 1.00 | 0.75 |

Elite factions include RHS Russian forces (MSV, VDV, VMF, VVS), Iron Front / Liberation WW2 factions, 3CB British, OPTRE Covenant, and others. See the source file for the full list.

### Role Adjustments (Night Mode Only)

On top of faction values, specific roles receive further tuning at night:

| Role | Adjusted Sub-skills |
|---|---|
| Machine Gunner | `aimingspeed` 0.82, `aimingaccuracy` 0.82, `aimingshake` 0.35, `reloadSpeed` 0.80 |
| Sniper | `aimingspeed` 0.60, `aimingaccuracy` 0.95, `aimingshake` 0.10, `reloadSpeed` 0.80 |

---

## Zeus-Spawned Units

Units spawned by Zeus during the mission automatically receive the same skill profile as pre-placed units. No additional configuration is needed.

## LAMBS Danger Integration

When LAMBS Danger is loaded, AI will trigger a broader range of tactical behaviours (flanking, suppression, bounding overwatch). WMP's elevated `general` and `commanding` values are tuned specifically to complement LAMBS — the combination produces more tactically varied AI without making them unfairly lethal.

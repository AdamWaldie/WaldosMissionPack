# Smart AI Pass

> **Use this page when:** you want non-player AI squads to fight, move and support each other more sensibly without adding an AI mod.

_Associated Files: `MissionConfig/aiConfig.sqf`; `MissionScripts/AiScripting/SmartAIPass/` (scheduler, eligibility, Zeus priority, group tick, profiles and every behaviour); `MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf` (AI Control and AI Orders dialogs); `initPlayerLocal.sqf` (Zeus watcher)_

The Smart AI Pass improves how AI squads behave. [Waldo's AI Tuning](Waldos-AI-Tweak) changes how
well they shoot and spot; this pass changes what they do. It covers every non-player AI group,
including Dynamic AO patrols and garrisons, and needs no mod beyond the pack's required CBA and ACE.

It is written from scratch for WMP. The design comes from an audit of several community AI mods
(Smart Combat V2, Digii AI, Scorpion's Advanced AI, PROTOCOL, Smart Merge, Smart Aircraft and Better
Static). Their good ideas were kept and their faults fixed:
- decisions use only what the engine already knows, with no extra detection that makes AI spot faster;
- nothing runs on player machines, and there are no per-shot broadcasts;
- there are no whole-world scans in fast loops;
- the leader is never ordered to walk away from his squad;
- squads' own waypoints always resume afterwards;
- mission-maker AI settings are never overwritten.

It is **off by default**, and every behaviour has its own switch.

**Zeus always comes first.** The moment a curator selects a squad (or one of its soldiers), gives
it any order, the pass steps back from that squad:
- move and attack waypoints;
- designating a target (a kill order);
- moving it;
- remote-controlling a soldier;
- ZEN AI actions such as suppressive fire, stance or behaviour;
- editing its attributes.

The squad is left alone for `Waldo_AIPass_ZeusHoldSeconds` (default 120 s) after the last Zeus
interaction. If Zeus gave it waypoints, it is left alone until it has finished them. The pass never
removes or reorders a Zeus waypoint, and Zeus waypoints also cancel any WMP garrison, defence or clear
order on that squad. Use **AI Orders** to keep a squad for Zeus permanently, or to hand it back.

## Enable the pass

1. Open `MissionConfig\aiConfig.sqf`.
2. Change `Waldo_AIPass_Enable` from `false` to `true`.
3. Look at the behaviour switches (`Waldo_AIPass_<Behaviour>_Enable`). The combat behaviours are on
   by default. Artillery, counter-battery, airborne reinforcement, surrender, grenade evasion and
   aircraft flares are off until you turn them on.

The server starts the pass and hands it to every headless client, including one that connects late.
Zeus can change every switch during play from **AI Control**.

## How a squad fights

Each squad moves through a small set of states. A squad only changes state when the situation
really changes, so it does not flicker between them.

| State | What the squad does |
|---|---|
| CALM | Its own orders and waypoints. |
| INVESTIGATE | The squad knows about an enemy it has not seen (reported to it, or heard firing) within 300 m. Within 150 m two riflemen check the spot while the rest watch it; a farther contact takes the whole squad. Up to 60 s. |
| CONTACT | Entered when an enemy was seen in the last 10 s. The squad switches to combat, reports the contact, may call for help, and uses the combat behaviours below. |
| SECURITY | Contact lost for 30 s: the squad holds and watches for 10 s. |
| SEARCH | Two riflemen check the last known enemy position. |
| REGROUP | The squad closes up, then returns to CALM with its previous behaviour, speed and waypoints. A squad that was SAFE before a real firefight comes back AWARE. |
| RETREAT | Morale broke, or a damaged vehicle is pulling back. The squad falls back under smoke, then regroups. |

A new sighting at any point sends the squad back to CONTACT. Squads you set to CARELESS are never
touched.

## Behaviours

| Behaviour | Switch (default) | What the AI do |
|---|---|---|
| Survivor regroup | `Waldo_AIPass_Regroup_Enable` (on) | Survivors of a nearly destroyed squad walk to the nearest friendly squad and join it. Snipers, sentries and other small teams are never merged. |
| Contact handling | `Waldo_AIPass_Contact_Enable` (on) | The state ladder above. Every combat behaviour needs it. |
| Post-contact search | `Waldo_AIPass_PostContact_Enable` (on) | Security hold, two-man search, regroup. |
| Investigation | `Waldo_AIPass_Investigate_Enable` (on) | The INVESTIGATE state above. |
| Flanking | `Waldo_AIPass_Flank_Enable` (on) | Up to half the squad swings wide and closes on the enemy's flank in short covered bounds, pausing to overwatch between bounds. While bounding they do not stop to trade fire; on the final approach and assault they engage normally. The leader, machine gunners and AT gunners stay as the base of fire. The flanking team then holds the ground it took until the squad catches up. |
| Final assault | `Waldo_AIPass_Assault_Enable` (on) | After a flank, if the enemy is within 80 m, one soldier throws a grenade (never near friendlies). The team then bounds to cover 12 m short of the enemy and rushes the position while the base of fire keeps suppressing. |
| Bounding advance | `Waldo_AIPass_Advance_Enable` (on) | A squad that has been in a firefight for 30 s and still has a waypoint to reach pushes a fire team up to three covered bounds towards it, instead of stalling. |
| Coordinated assault | `Waldo_AIPass_CoordinatedAssault_Enable` (on) | Once reinforcing squads reach their rally point, they assault the enemy from both sides while the squad in contact fires. |
| Street crossing | `Waldo_AIPass_StreetCrossing_Enable` (on) | A flanking element stops at the road edge, throws smoke and crosses in one bound. |
| Stance from cover | `Waldo_AIPass_Stance_Enable` (on) | Soldiers stand behind tall cover, kneel behind waist-high cover and go prone behind low cover. Stances you set yourself are left alone. |
| Ammo sharing | `Waldo_AIPass_AmmoShare_Enable` (on) | A soldier down to his last magazine gets one from a squad-mate within 10 m who has plenty. |
| Fire control | `Waldo_AIPass_FireControl_Enable` (on) | Soldiers deal with enemies within 20 m first and spread their fire across visible enemies. Machine gunners (and riflemen with ammunition to spare) suppress enemies that are known but hidden. Nobody is ordered to fire through friendlies or civilians. |
| Morale and retreat | `Waldo_AIPass_Morale_Enable` (on) | Morale is driven by casualties, suppression, a lost leader, being outnumbered, and armour the squad cannot fight. Braver soldiers hold longer. A broken squad falls back 200 m under smoke. |
| Surrender | `Waldo_AIPass_Surrender_Enable` (off) | The last one or two survivors of a broken, isolated squad drop their weapons and surrender. With ACE Captives loaded, players can take them prisoner. |
| Grenade evasion | `Waldo_AIPass_GrenadeEvasion_Enable` (off) | AI move away from a live grenade they can see. Test it in your setup first (see Limitations). |
| Anti-armour | `Waldo_AIPass_AntiArmour_Enable` (on) | The best launcher gunner engages known armour. He moves first if something is blocking his backblast. |
| Vehicle drills | `Waldo_AIPass_Vehicles_Enable` (on) | Infantry riding in the squad's vehicle get out under fire and get back in afterwards. A badly damaged vehicle, or an armed one that has lost its weapons, fires its smoke and, if the whole squad is mounted, withdraws. Unarmed vehicles are never treated as having lost their weapons. |
| Vehicle gunnery | `Waldo_AIPass_VehicleGunnery_Enable` (on) | Gunners engage anti-tank soldiers first, then armour, then everything else. Tanks and APCs back away from known AT teams to 250 m. |
| Contact reports | `Waldo_AIPass_ContactReports_Enable` (on) | Squads pass sighted enemies to nearby friendly squads. The range is 500 m with a working radio, or 35 m by voice. Radio jamming blocks the radio report. |
| Reinforcement | `Waldo_AIPass_Reinforce_Enable` (on) | Up to two idle squads within 600 m move up behind a squad in contact. They then resume their own waypoints. Squads with an AT gunner are preferred, and when armour appears one more squad with AT is called. Garrisons, defence lines, aircrews, static-gun crews and artillery never leave their posts to respond. Calling for help needs a radio. |
| Artillery support | `Waldo_AIPass_Artillery_Enable` (off) | A squad with a good fix on the enemy calls a fire mission from friendly AI artillery, using plain high-explosive shells (never mines, cluster or illumination rounds). The target must be at least 200 m from friendlies and civilians, and mobile guns relocate after firing. Jamming blocks the call. |
| Artillery smoke | `Waldo_AIPass_ArtillerySmoke_Enable` (on, needs Artillery support) | A retreating squad gets a smoke screen from friendly artillery that has smoke rounds. |
| Counter-battery | `Waldo_AIPass_CounterBattery_Enable` (off) | Friendly AI artillery answers enemy artillery, but only if its position is known (see below). |
| Airborne reinforcement | `Waldo_AIPass_Airborne_Enable` (off) | Paradropped AI squads from triggers, scripts or Zeus. With `Waldo_AIPass_Airborne_Auto`, a squad in contact calls one when no ground squad can help. |
| Aircraft flares | `Waldo_AIPass_AircraftFlares_Enable` (off) | WMP gunships and Dynamic AA fighters fire flares when a missile is launched at them. |
| Aircraft break-away | `Waldo_AIPass_AircraftBreak_Enable` (off) | The same aircraft jink sideways away from the launch, without changing their orbit or waypoints. |

## Behaviour profiles

The pass reads the same profile names as [Waldo's AI Tuning](Waldos-AI-Tweak) (MILITIA, LINE,
VETERAN, ELITE; LEGACY behaves like LINE). Skill profiles set how well AI shoot and spot, and the
pass never changes them. Behaviour profiles set how willing a squad is to fight smart:

| Profile | Flank | Assault | Breaks at | Retreats | Surrenders at |
|---|---|---|---|---|---|
| MILITIA | 30% | 20% | early | 1.5x further | 3 survivors |
| LINE | 50% | 40% | normal | normal | 2 survivors |
| VETERAN | 60% | 55% | late | 0.8x | 1 survivor |
| ELITE | 70% | 70% | very late | 0.7x | 1 survivor |

A squad uses, in order:
1. its own profile (`(group this) setVariable ["Waldo_AIPass_Profile", "ELITE", true];`);
2. its faction's entry in `Waldo_AIPass_FactionProfiles`;
3. the active AI Rebalance profile;
4. LINE.

Edit `Waldo_AIPass_ProfileBehaviour` in `aiConfig.sqf` to change the numbers.

### Survivor regroup in detail

- It only starts when someone dies; quiet missions cost nothing.
- The squad must be down to `Waldo_AIPass_Regroup_MaxRemnantSize` living members (default 2), all
  on foot. It must once have had at least `Waldo_AIPass_Regroup_MinimumPeakSize` members (default 3).
- The host is the nearest same-side infantry squad within `Waldo_AIPass_Regroup_SearchRadius`. The
  merged squad must stay within `Waldo_AIPass_Regroup_MaxGroupSize`.
- Survivors join once close to the host leader. If they get stuck or take too long, they join where
  they stand.

### Counter-battery modes

`Waldo_AIPass_CounterBattery_Mode` sets how an enemy battery can be located:
- `KNOWN` (default): only a battery a friendly squad has spotted.
- `RADAR`: also any enemy battery firing within `Waldo_AIPass_CounterBattery_RadarRange` of a radar
  you register:

```sqf
[this, west] call Waldo_fnc_AIPassRegisterRadar;   // in the radar object's init field
```

## Orders

Two orders are given to a specific squad from a script or from Zeus (**WMP AI & Combat > AI Orders**).

**Garrison** occupies the buildings around a point:
- roofed and upper positions are taken first;
- soldiers watch outward and duck when suppressed or hit;
- the garrison breaks and fights normally when it falls to half strength
  (`Waldo_AIPass_Garrison_BreakFraction`) or its morale breaks.

```sqf
[group this, getPosATL this, 40] call Waldo_fnc_AIPassGarrison;   // garrison within 40 m
[_group] call Waldo_fnc_AIPassGarrisonRelease;                    // let them move again
```

**Defend** forms a firing line across a facing direction:
- two thirds of the squad hold covered spots along the line, watching overlapping sectors;
- the rest wait in reserve 40 m behind;
- the reserve is committed once, to a gap when a third of the line has fallen, or to the point an
  enemy is closing on;
- the line breaks at half strength or when morale breaks.

```sqf
[group this, getMarkerPos "ridge", 45, 80] call Waldo_fnc_AIPassDefend;   // face 045, 80 m wide
[_group] call Waldo_fnc_AIPassDefendRelease;
```

**Clear building**: the leader holds outside while the rest work through every room. The order ends
when every room is checked or after four minutes.

```sqf
[group this, nearestBuilding this] call Waldo_fnc_AIPassClearBuilding;
```

**Dynamic AO garrisons:** set `Waldo_AIPass_Garrison_DynamicAO` to `true` to give Dynamic AO's
building garrisons the same handling (watching outward, ducking under fire, breaking at losses).

**Airborne reinforcement:** use a trigger set to "OPFOR detected by BLUFOR" (server only) with this
On Activation line:

```sqf
[thisTrigger, east] call Waldo_fnc_AIPassAirborneRequest;
```

An OPFOR transport from `Waldo_AIPass_Airborne_AircraftClasses` drops
`Waldo_AIPass_Airborne_JumperCount` paratroopers of `Waldo_AIPass_Airborne_JumperClasses` over the
trigger. Once landed, they search and destroy around it. Each side has
`Waldo_AIPass_Airborne_MaxDrops` drops per mission, at least `Waldo_AIPass_Airborne_Cooldown`
seconds apart. Set the aircraft and jumper classes to your factions' own units when you run mods.

## With LAMBS

LAMBS is optional; WMP is primary. When LAMBS Danger is loaded, `Waldo_AIPass_LambsMode` decides who
does what:

- `SPLIT` (default): LAMBS keeps what it is good at in contact:
  - moment-to-moment unit tactics, fire, anti-armour and vehicle handling;
  - sharing sightings.

  WMP keeps the state ladder, post-contact search, morale, retreat, surrender, reinforcement,
  artillery and airborne drops. Garrison and clear-building orders are handed to LAMBS Waypoints
  when it is loaded. A group you set to `lambs_danger_disableGroupAI` gets the full WMP pass.
- `WMP`: WMP runs everything and turns LAMBS group AI off for the squads it manages. LAMBS group AI
  is turned back on when the pass stops or releases the squad.

## Which AI are affected

Every AI group on the sides in `Waldo_AIPass_IncludedSides` (default `WEST`, `EAST`, `GUER`) may be
included, except:

- any group containing a living player;
- AI used by other WMP features:
  - Airborne Gunship;
  - Transport Services crews while their transport is in service. Once the transport is written off
    (destroyed, driver lost, immobile or too badly damaged) and the crew are on foot, the pass takes
    them over as an ordinary squad;
  - Paradrop aircraft, and AI jumpers until they land. Once every jumper in a group is on the ground,
    the pass takes them over. This covers Dynamic Paradrop's generated jumpers and your own AI riding
    a Quick Flight aircraft;
  - Dynamic AA and AI Convoy;
  - dialogue speakers;
  - drones;
- anything failing the shared AI filters `Waldo_AI_IncludedFactions`, `Waldo_AI_ExcludedFactions` or
  `Waldo_AI_ExcludedClasses`;
- anything you opt out yourself:

```sqf
this setVariable ["Waldo_AIPass_Exclude", true, true];            // one unit
(group this) setVariable ["Waldo_AIPass_Exclude", true, true];    // a whole group
```

`Waldo_AI_Exclude` still works too, and excludes the unit from every WMP AI change, including skill
profiles. While ENDEX or SafeStart is active the pass holds all behaviour and resumes afterwards.

## Settings

Every setting is listed with its default in
[Mission Configuration Files](Feature-Configuration-Files). The ones you are most likely to change:

| Setting | Default | Meaning |
|---|---|---|
| `Waldo_AIPass_Enable` | `false` | Master switch. `false` means no pass code runs anywhere. |
| `Waldo_AIPass_IncludedSides` | `["WEST", "EAST", "GUER"]` | Sides the pass may command. |
| `Waldo_AIPass_LambsMode` | `"SPLIT"` | Only matters with LAMBS loaded (see above). |
| `Waldo_AIPass_ZeusHoldSeconds` | `120` | How long the pass leaves a squad alone after Zeus touches it. |
| `Waldo_AIPass_FactionProfiles` | empty | Per-faction behaviour profile, for example OPF_F to ELITE. |
| `Waldo_AIPass_Morale_RetreatDistance` | `200` | How far a broken squad falls back. |
| `Waldo_AIPass_Reinforce_Radius` | `600` | How far away helping squads may be. |
| `Waldo_AIPass_TickBudgetMs` | `1` | Milliseconds of work allowed per scheduler tick. |
| `Waldo_AIPass_Debug` | `false` | Extra RPT lines for contact, flanks, morale and retreats. |

## Zeus control

- **WMP AI & Combat > AI Control** (formerly *AI Rebalance - Control*): skill profile, the Smart AI
  Pass master switch, every behaviour switch and the LAMBS mode. Changes reach every machine,
  including headless clients that join later.
- **WMP AI & Combat > AI Orders**: place it at a spot, pick a nearby AI group (a unit under the
  module is listed first), and choose an order:
  - garrison buildings here;
  - defend a line here (width and facing);
  - release a garrison or defence;
  - clear the building here;
  - airborne reinforcement here (side and number of jumpers). Zeus drops skip the cooldown but still
    count against the budget;
  - keep the group for Zeus (exclude it from the pass);
  - return it to the pass.

## Performance and network

- Runs only on the server and headless clients; player machines never run pass code.
- One scheduler per machine with a strict per-tick time budget. At least one job runs each tick, and
  the rest wait their turn in rotation. Steps are slowed when FPS is low.
- How often a squad is stepped depends on its distance to the nearest player: every 2 s in contact
  nearby, up to every 20 s far away. Squads more than 2.5 km from every player only update their
  state and morale.
- Uses only what the engine already knows about enemies, and adds no detection of its own.
- No broadcasts in loops, and no polling of living soldiers for survivor regroup. Contact reports,
  reinforcement and artillery stay within one machine.

## Limitations

- Not yet run in the engine. Test with the full audit mission before live use.
- A Zeus waypoint that cycles (a CYCLE patrol) keeps the squad Zeus's until you return it with AI
  Orders.
- Grenade evasion and aircraft flares are off by default:
  - grenade evasion depends on where the engine raises the `ProjectileCreated` event in multiplayer;
    if it is not raised where the AI live, the feature silently does nothing;
  - many aircraft already fire flares under AI control.
- Contact reports, reinforcement and artillery only work between squads owned by the same machine
  (the server, or one headless client).
- LAMBS can override move orders while its own danger logic is active. Stuck-move fallbacks and
  time limits keep every behaviour finite.
- If a squad moves to another machine mid-drill, the drill stops. The new owner starts afresh from
  what the engine knows.
- A garrison needs the pass running to be re-applied after a headless-client handover; the LAMBS
  hand-over does not.

## Remove or diagnose

Mission diagnostics include rows under area `ai`:
- `smart-ai-pass`: scheduler state, queued jobs, pause;
- `smart-ai-pass-regroup`: regroups and units joined;
- `smart-ai-pass-groups`: managed squads, squads in contact and retreating, garrisons, flanks,
  retreats, surrenders, reinforcements, grenade reactions;
- `smart-ai-pass-drills`: assaults, advances, investigations, coordinated assaults, magazines shared,
  defences;
- `smart-ai-pass-zeus`: squads held by Zeus, squads on Zeus waypoints, squads excluded;
- `smart-ai-pass-support`: artillery, radars, airborne drops, flares;
- `smart-ai-pass-lambs`: LAMBS detection and mode.

Counters are for the server; headless-client squads are counted on their own machine. RPT lines
are tagged `[WMP AI PASS]`. Set `Waldo_AIPass_Enable` to `false`, or untick **Smart AI Pass** in
Zeus, to remove it completely: every squad is handed back to its own orders.

## See also

- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [Dynamic AO Generation](Dynamic-AO-Generation)
- [Headless Client Support](Headless-Client-Support)
- [Radio Jamming](Radio-Jamming)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

# Smart AI Pass

> **Use this page when:** you want non-player AI squads to fight, move and support each other more sensibly without adding an AI mod.

_Associated Files: `MissionConfig/aiConfig.sqf`; `MissionScripts/AiScripting/SmartAIPass/` (scheduler, eligibility, Zeus priority, group tick, profiles and every behaviour); `MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf` (AI Control and AI Orders dialogs); `initPlayerLocal.sqf` (Zeus watcher)_

The Smart AI Pass improves how AI squads behave. [Waldo's AI Tuning](Waldos-AI-Tweak) changes how
well they shoot and spot; this pass changes what they do. It covers every non-player AI group,
including Dynamic AO patrols and garrisons, and needs no mod beyond the pack's required CBA and ACE.

WMP implements these behaviours as mission scripts. The reference review covered Smart Combat V2,
Digii AI, Scorpion's Advanced AI, PROTOCOL, Smart Merge, Smart Aircraft, Better Static and Better
Convoy. It adapted selected mechanisms without importing addon controllers or FSMs. Targeting uses
engine knowledge; owner-local workers issue AI commands. Restoration records preserve the values
WMP needs when releasing its own changes. These contracts still require in-engine acceptance.

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
order on that squad. Use **AI Orders** to keep a squad for Zeus permanently, or to hand it back. An
order given through **AI Orders** (garrison, defend, clear, parachute out) counts as handing the squad
to the pass: it clears the hold Zeus set by selecting the squad, and any earlier Zeus waypoints, so they
cannot refuse or cancel the order.

## Enable the pass

1. Open `MissionConfig\aiConfig.sqf`.
2. Change `Waldo_AIPass_Enable` from `false` to `true`.
3. Look at the behaviour switches (`Waldo_AIPass_<Behaviour>_Enable`). The combat behaviours are on
   by default. Artillery, counter-battery, airborne insertion, surrender, grenade evasion and
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
| Artillery support | `Waldo_AIPass_Artillery_Enable` (off) | Explicitly assigned spotters request spaced HE ranging rounds from friendly artillery, including guns on another owner. Corrections require observation and radio contact. Opening aim points avoid players; every shot checks friendlies and civilians. Mobile guns may relocate afterwards. |
| Artillery smoke | `Waldo_AIPass_ArtillerySmoke_Enable` (on, needs Artillery support) | A retreating squad gets a smoke screen from friendly artillery that has smoke rounds. |
| Counter-battery | `Waldo_AIPass_CounterBattery_Enable` (off) | Friendly AI artillery answers enemy artillery, but only if its position is known (see below). |
| Airborne insertion | `Waldo_AIPass_Airborne_Enable` (off) | AI squads riding in AI-flown helicopters or planes climb to jump altitude as they near an enemy they know about, then parachute out one at a time about 700 m away. Each soldier keeps his backpack. Once down they fight as a normal squad. Helicopters on an unload waypoint still land, and player-flown aircraft never trigger it. |
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
3. `Waldo_AIPass_BehaviourProfile`, the mission-wide choice (empty follows AI Rebalance);
4. the active AI Rebalance profile;
5. LINE.

Edit `Waldo_AIPass_ProfileBehaviour` in `aiConfig.sqf` to change the numbers.

## Difficulty and tuning

These settings set how hard the AI are without touching their skill values. Set them in
`aiConfig.sqf` for the start of the mission, and change any of them during play with **WMP AI & Combat
> AI Tuning** in Zeus. Changes reach the server and every headless client at once, including
headless clients that join later. Each squad uses them from its next step; nothing restarts.

| Setting | Default | Effect |
|---|---|---|
| `Waldo_AIPass_BehaviourProfile` | `""` | Tactics profile for every squad without its own or its faction's. Empty follows the AI Rebalance profile. |
| `Waldo_AIPass_Aggression` | `1` | Scales how often squads flank, assault, advance, investigate and join coordinated assaults. `0` never, `2` twice as often. |
| `Waldo_AIPass_Cohesion` | `1` | How much punishment a squad takes before it breaks. Above `1` they hold longer. |
| `Waldo_AIPass_ReactionSpeed` | `1` | How often squads re-assess. Above `1` they react faster and use more server time. |
| `Waldo_AIPass_EngageRange` | `800` | Known enemies within this range (m) are acted on. |
| `Waldo_AIPass_Flank_MaxRange` | `400` | Farther enemies are not flanked. |
| `Waldo_AIPass_Morale_RetreatDistance` | `200` | How far a broken squad falls back. |
| `Waldo_AIPass_ZeusHoldSeconds` | `120` | How long the pass leaves a squad alone after Zeus touches it. |
| `Waldo_AIPass_ContactReports_Radius` | `500` | Radio report range. |
| `Waldo_AIPass_Reinforce_Radius`, `_MaxResponders` | `600`, `2` | How far away, and how many, squads come to help. |
| `Waldo_AIPass_Artillery_Rounds`, `_MaxError`, `_Cooldown`, `_MinFriendlyDistance`, `_ShootAndScoot` | `3`, `50`, `120`, `200`, on | Squads' artillery support. |
| `Waldo_AIPass_Artillery_OpeningSafeDistance`, `_OpeningBuffer`, `_WarningInterval` | `200`, `100`, `20` | Opening aim exclusion and added margin in metres; warning pause after estimated impact in seconds. |
| `Waldo_AIPass_Artillery_DefaultRole` | `"BOTH"` | Missions a gun takes when it has no role of its own (see below). |
| `Waldo_AIPass_CounterBattery_Mode`, `_Rounds`, `_MaxError`, `_Delay`, `_Interval`, `_MinFriendlyDistance`, `_ShootAndScoot` | `KNOWN`, `4`, `100`, `20`, `60`, `200`, on | Counter-battery, set separately from support. |
| `Waldo_AIPass_Airborne_DeployDistance`, `_Altitude`, `_MinAltitude` | `700`, `250`, `120` | Airborne insertion. |

The behaviour switches (which behaviours run at all) stay in **AI Control**. From a trigger or
script:

```sqf
[createHashMapFromArray [["Waldo_AIPass_Aggression", 1.5], ["Waldo_AIPass_Cohesion", 0.8]]] call Waldo_fnc_AIPassTuning;
```

Only the settings above are accepted, and numbers are kept inside the same ranges as the Zeus
sliders.

### Artillery support and counter-battery

The two have separate switches (`Waldo_AIPass_Artillery_Enable`, `Waldo_AIPass_CounterBattery_Enable`)
and separate settings. Set roles on the server (or in an Eden init field, whose client calls are ignored). Each gun can also be limited to one job:

```sqf
[this, "COUNTER"] call Waldo_fnc_AIPassSetArtilleryRole;   // gun's init field: counter-battery only
[this, "SUPPORT"] call Waldo_fnc_AIPassSetArtilleryRole;   // squads' fire requests (and smoke) only
```

Guns without a role use `Waldo_AIPass_Artillery_DefaultRole`. In Zeus, **AI Orders** has the same
three choices for a group's guns. Counter-battery never fires when friendlies or civilians are within
`Waldo_AIPass_CounterBattery_MinFriendlyDistance` of the enemy gun.

Assign existing soldiers explicitly on the server, or select the soldier and use **AI Orders >
Assign artillery spotter**. The group selector lists assigned spotter names. Assignment persists
until removed; it neither spawns nor equips anyone.

```sqf
[spotter1, true] call Waldo_fnc_AIPassSetSpotter;
[spotter1, false] call Waldo_fnc_AIPassSetSpotter; // remove assignment
```

The soldier needs binoculars, a radio, a recent known enemy and a clear view. WMP radio jamming
blocks reports. The spotter watches the enemy and uses binoculars while reporting. An ordinary
radio-equipped squad member cannot substitute. Retreat smoke is a separate support utility.

HE starts with a deliberate 300 m offset, plus report error. At most eight aim candidates are
checked against one snapshot of living players. The first aim must be at least the configured
200 m safety distance plus 100 m buffer from each player. If none is safe and in range, the mission
ends. This protects aim selection, not the eventual blast: dispersion and player movement during
flight prevent an absolute impact guarantee.

The server issues one round and waits for the engine firing event, estimated flight time and a
20 s warning pause. A fresh observed report reduces the offset to 55% of its previous value, with
a 40 m floor. The spotter must see the target and previous aim area to correct. Losing the spotter,
visibility or radio leaves the current mission firing at its last report and correction quality;
it does not follow unseen movement. Radar-only missions keep their displaced aim quality unless
an assigned observer supplies corrections through a new observed mission.

Each shot rechecks role, eligibility, ammunition, range and friendly/civilian proximity on the gun
owner. Server mission tokens and actual firing events coordinate guns and spotters on different
owners. An unconfirmed firing command is quarantined without retry; an explicit owner rejection
ends it. Already issued engine orders and airborne shells cannot be recalled. Stop/restart is not
proof that an outstanding engine command has disappeared.

### Survivor regroup in detail

- It only starts when someone dies; quiet missions cost nothing.
- The squad must be down to `Waldo_AIPass_Regroup_MaxRemnantSize` living members (default 2), all
  on foot. It must once have had at least `Waldo_AIPass_Regroup_MinimumPeakSize` members (default 3).
- The host is the nearest same-side infantry squad within `Waldo_AIPass_Regroup_SearchRadius`. The
  merged squad must stay within `Waldo_AIPass_Regroup_MaxGroupSize`.
- Unconscious soldiers, protected service commands and explicit garrison/defend/clear orders prevent merging. Capacity is rechecked immediately before joining.
- Survivors join once close to the host leader. If they get stuck or take too long, they join where
  they stand.

### Counter-battery modes

`Waldo_AIPass_CounterBattery_Mode` sets how an enemy battery can be located:
- `KNOWN` (default): only a battery an explicitly assigned spotter can observe and report.
- `RADAR`: also any enemy battery firing within `Waldo_AIPass_CounterBattery_RadarRange` of a radar
  you register:

```sqf
[this, west] call Waldo_fnc_AIPassRegisterRadar;   // in the radar object's init field
```

## Orders

Orders are given to a specific squad from a script or from Zeus (**WMP AI & Combat > AI Orders**).

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

**Airborne insertion:** place an AI-crewed helicopter or plane with an AI squad in its cargo seats and
give the aircraft waypoints towards the enemy (not an unload waypoint). With
`Waldo_AIPass_Airborne_Enable` on, the aircraft climbs to `Waldo_AIPass_Airborne_Altitude` (250 m)
once the squad knows about an enemy within `Waldo_AIPass_Airborne_ApproachDistance` (2 km). Within
`Waldo_AIPass_Airborne_DeployDistance` (700 m) the squad jumps one soldier every
`Waldo_AIPass_Airborne_JumpInterval` second, never below `Waldo_AIPass_Airborne_MinAltitude` (120 m)
or over water. On the ground they carry on with their own waypoints, or search and destroy around
the enemy position if they have none. To drop a squad at a moment you choose, for example from a
trigger or the aircraft's waypoint On Activation:

```sqf
[group this] call Waldo_fnc_AIPassAirborneDrop;   // "this" is one of the passengers
```

This is separate from the player [Paradrop](Paradrop) feature. AI jumpers from Paradrop itself are
taken over once they land (see Exclusions).

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

Difficulty settings are listed under [Difficulty and tuning](#difficulty-and-tuning).

| Setting | Default | Meaning |
|---|---|---|
| `Waldo_AIPass_Enable` | `false` | Master switch. `false` means no pass code runs anywhere. |
| `Waldo_AIPass_IncludedSides` | `["WEST", "EAST", "GUER"]` | Sides the pass may command. |
| `Waldo_AIPass_LambsMode` | `"SPLIT"` | Only matters with LAMBS loaded (see above). |
| `Waldo_AIPass_FactionProfiles` | empty | Per-faction behaviour profile, for example OPF_F to ELITE. |
| `Waldo_AIPass_TickBudgetMs` | `1` | Milliseconds of work allowed per scheduler tick. |
| `Waldo_AIPass_Debug` | `false` | Extra RPT lines for contact, flanks, morale and retreats. |

## Zeus control

- **WMP AI & Combat > AI Control** (formerly *AI Rebalance - Control*): skill profile, the Smart AI
  Pass master switch, every behaviour switch and the LAMBS mode. Changes reach every machine,
  including headless clients that join later.
- **WMP AI & Combat > AI Tuning**: every difficulty and tuning setting in
  [Difficulty and tuning](#difficulty-and-tuning), opening on the live values. Applying takes effect
  on each squad's next step.
- **WMP AI & Combat > AI Orders**: place it at a spot, pick a nearby AI group (a unit under the
  module is listed first), and choose an order:
  - garrison buildings here;
  - defend a line here (width and facing);
  - release a garrison, defence or clear-building order;
  - clear the explicitly selected building (a missing target is rejected);
  - assign or remove the explicitly selected soldier as an artillery spotter;
  - parachute out now, for a squad riding as cargo in an AI-flown aircraft at least 120 m over land;
  - artillery role for the group's guns: support only, counter-battery only, or both;
  - keep the group for Zeus (exclude it from the pass);
  - return it to the pass.

Order success is reported after the current owner accepts it. Missing responses are reported as
uncertain, rather than presented as successful execution.

## Performance and network

- AI workers run on the server and headless clients; interface clients provide Zeus controls.
- One scheduler per machine with a soft budget checked between jobs. At least one due job runs
  each tick. A running job can exceed the budget, and scanning the queue costs more as it grows.
  The remaining jobs wait their turn in rotation. Steps are slowed when FPS is low.
- How often a squad is stepped depends on its distance to the nearest player: every 2 s in contact
  nearby, up to every 20 s far away. Squads more than 2.5 km from every player only update their
  state and morale.
- Uses only what the engine already knows about enemies, and adds no detection of its own.
- Restoration checkpoints broadcast only when their contents change. Clear-building progress and orders have durable replay state.
- Artillery uses cached guns/spotters, one observer request per round and at most eight opening aim candidates. Counter-battery observer jobs inspect at most four cached spotters per step.
- Contact reports and reinforcement remain owner-local; artillery has a server coordinator and owner-local execution.

## Limitations

- Not yet run in the engine. Test with the full audit mission before live use.
- A Zeus waypoint that cycles (a CYCLE patrol) keeps the squad Zeus's until you return it with AI
  Orders.
- Grenade evasion and aircraft flares are off by default:
  - grenade evasion depends on where the engine raises the `ProjectileCreated` event in multiplayer;
    if it is not raised where the AI live, the feature silently does nothing;
  - many aircraft already fire flares under AI control.
- Contact reports and reinforcement only work between squads owned by the same machine.
- LAMBS can override move orders while its own danger logic is active. Stuck-move fallbacks and
  time limits keep every behaviour finite.
- Ownership epochs retire stale jobs; changed restoration checkpoints and clear-building progress are public. The new owner restores and adopts the group. WMP and ACE headless transfers, including abrupt disconnects, still need in-engine verification.
- A garrison needs the pass running to be re-applied after a headless-client handover; the LAMBS
  hand-over does not.

## Review corrections

Zeus waypoint edits use the engine group/index event payload; waypoint deletion and selection use
the waypoint-array payload. Garrison, defence and clear-building orders now reject groups that fail
the shared eligibility gate, including player squads and crews owned by other WMP features. Repeated
garrison and defence placement invalidates older arrival jobs. Garrison release only restores PATH
when the pass disabled it.

Artillery rechecks the live battery role, feature switch, eligibility and nearby friendlies or
civilians at the dispersed aim point before firing. This check includes mounted occupants. A queued
counter-battery mission can therefore be cancelled by Zeus, exclusion or a live role/switch change.
The check does not predict where units will move while shells are in flight.

Stopping the pass clears pending startup, airborne and clear-building work and removes tracked
aircraft handlers. Parachute exit protection restores the soldier's prior damage setting on its
current owner. These changes have static regression coverage; their engine behaviour is unverified.

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
- `smart-ai-pass-tuning`: behaviour profile, aggression, cohesion, reaction speed, default battery
  role and counter-battery mode;
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

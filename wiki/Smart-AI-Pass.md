# WMP Cortex

Cortex functions use `Waldo_fnc_Cortex...`; their implementation is in `MissionScripts/AiScripting/Cortex/`. Older `Waldo_fnc_AIPass...` names remain compatibility aliases to the same implementation. Existing `Waldo_AIPass_...` configuration and state keys are retained for mission compatibility.

> **Use this page when:** you want non-player AI squads to fight, move and support each other more sensibly without adding an AI mod.

_Associated Files: `MissionConfig/aiConfig.sqf`; `MissionScripts/AiScripting/Cortex/` (scheduler, eligibility, Zeus priority, group tick, profiles and every behaviour); `MissionScripts/ZenModules/RuntimeControl/featureRuntimeZen.sqf` (settings and purpose-based order dialogs); `initPlayerLocal.sqf` (Zeus watcher)_

The Smart AI Pass improves how AI squads behave. [Waldo's AI Tuning](Waldos-AI-Tweak) changes how
well they shoot and spot; this pass changes what they do. It covers every non-player AI group,
including Dynamic AO patrols and garrisons, and needs no mod beyond the pack's required CBA and ACE.

WMP implements these behaviours as mission scripts. Targeting uses engine knowledge, and commands
run on the AI owner. Restoration records preserve the values WMP needs when releasing its changes.
These contracts still require in-engine acceptance.

The Cortex master switch is **on by default** in the shipped configuration. Individual behaviour switches remain independently configurable.

**Zeus control takes priority.** Plain selection is observation and does not cancel an active
behaviour. Waypoint and object edits, or opening attributes, mark the squad for owner-side release.
The intended takeover coverage includes:
- move and attack waypoints;
- designating a target (a kill order);
- moving it;
- remote-controlling a soldier;
- ZEN AI actions such as suppressive fire, stance or behaviour;
- editing its attributes.

The squad is left alone for `Waldo_AIPass_ZeusHoldSeconds` (default 120 s) after the last Zeus
interaction. If Zeus gave it waypoints, it is left alone until it has finished them. The pass never
removes or reorders a Zeus waypoint, and Zeus waypoints also cancel any WMP garrison, defence or clear
order on that squad. Use **Manage Group Control** to keep a squad for Zeus permanently, or to hand it back. An
order given through the purpose modules (garrison, defend, clear, parachute out) counts as handing the squad
to the pass: it clears the previous Zeus hold and waypoint-hold flag, so they
cannot refuse or cancel the order.

## Enable the pass

1. Open `MissionConfig\aiConfig.sqf`.
2. Cortex is enabled by default. Set `Waldo_AIPass_Enable` to `false` to disable it.
3. Look at the behaviour switches (`Waldo_AIPass_<Behaviour>_Enable`). The combat behaviours are on
   by default. Artillery, counter-battery, airborne insertion, surrender, grenade evasion and
   aircraft flares are off until you turn them on.

The server starts the pass and hands it to every headless client, including one that connects late.
Zeus can change every switch during play from **Cortex Control**.

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

A new sighting during CALM, INVESTIGATE, SECURITY, SEARCH or REGROUP sends the squad to CONTACT.
A squad already executing RETREAT continues its bounded withdrawal under contact and may still
surrender if its situation deteriorates. Squads you set to CARELESS are never touched.

### State handovers

| From | Trigger | To | What Cortex hands over or preserves |
|---|---|---|---|
| CALM | A physically visible enemy | CONTACT | Saves the group's original behaviour and speed before combat control begins. Existing authored movement is preserved unless a Cortex manoeuvre later acquires it. |
| CALM | A recent report, heard shot or known unseen enemy within range | INVESTIGATE | Acquires only the finite investigation movement. A new sighting interrupts it immediately. Completion, timeout or a disabled investigation switch restores the saved mission state. |
| CONTACT | No physical sighting for the configured delay and no active manoeuvre | SECURITY | Keeps the last known position and briefly watches it. An active flank, advance, coordinated assault or clear-through must finish or explicitly abort first. |
| SECURITY | The security hold ends | SEARCH or REGROUP | Sends a two-person search only when suitable riflemen and a last known position exist; otherwise it begins consolidation. |
| SEARCH | Enemy seen | CONTACT | Cancels the search movement and returns the searchers to the combat group without waiting for the search deadline. |
| SEARCH | Position reached, team lost or deadline reached | REGROUP | Releases the search task and recalls only separated, unreserved members. |
| CONTACT | Morale breaks and surrender is not selected | RETREAT | Releases garrison, defence or clearance ownership, selects a screened withdrawal avenue, uses smoke when available and measures physical net withdrawal. |
| RETREAT | At least 30 m net withdrawal, or the bounded deadline expires | REGROUP | Clears the withdrawal task. A timeout is reported as incomplete and still releases the group instead of holding it indefinitely. |
| REGROUP | Members are cohesive | CALM | Restores the saved mission behaviour, speed and waypoints. A new sighting interrupts consolidation and returns to CONTACT. |
| Any Cortex-owned state | Zeus or a newer scripted order takes priority | CALM / external control | Releases only Cortex-owned movement, holds and temporary settings. It does not inject a replacement waypoint or revive an older task. |
| INVESTIGATE, SEARCH or RETREAT | Group ownership moves to another machine | same semantic state | Publishes the remaining intent and original deadline. The new owner resumes it without resetting the timeout or passing through a false CALM state. |

Every transition publishes its reason, timestamp and previous/next phase in a bounded group ledger.
The manoeuvre controller has a separate bounded stage ledger for START, MOVE, PAUSE, HOLD and ENDED.
Its reasons distinguish ordinary bounds, assault commitment and position, grenade preparation,
clear-through, consolidation, interruption, failure and completion. Those stages may change while
the squad remains in CONTACT; they are sub-actions of combat, not competing squad states. Grenades,
smoke and covering fire support a movement stage but never gate its completion. A failed or
unavailable supporting action therefore cannot leave the squad waiting forever.

## Behaviours

| Behaviour | Switch (default) | What the AI do |
|---|---|---|
| Survivor regroup | `Waldo_AIPass_Regroup_Enable` (on) | Survivors of a nearly destroyed squad walk to the nearest friendly squad and join it. Snipers, sentries and other small teams are never merged. |
| Contact handling | `Waldo_AIPass_Contact_Enable` (on) | The state ladder above. Every combat behaviour needs it. |
| Post-contact search | `Waldo_AIPass_PostContact_Enable` (on) | Security hold, two-man search, regroup. |
| Investigation | `Waldo_AIPass_Investigate_Enable` (on) | The INVESTIGATE state above. |
| Flanking | `Waldo_AIPass_Flank_Enable` (on) | Up to half the squad swings wide and closes on the enemy's flank in short covered bounds, pausing to overwatch between bounds. Six fixed avenue shapes are compared once; routes crossing the squad's own base-of-fire lane or up to four nearby active supporting lanes are rejected, while terrain/solid screening is preferred over visual concealment. A friendly group must be in CONTACT or assigned a coordinated COVER role; target knowledge alone does not reserve a corridor. Movers may fire while the stationary element covers; movement ownership prevents independent pursuit from replacing their bound. The leader, machine gunners and AT gunners stay as the base of fire. The flanking team holds while the covering element moves forward to consolidate; this also applies when no final assault is selected. |
| Final assault | `Waldo_AIPass_Assault_Enable` (on) | After a completed flank or advance, an eligible nearby objective transitions into an approach 20 m short, an optional safe carried grenade, then a clear-through 20 m beyond the fixed objective. Cortex does not make a second random roll after the manoeuvre succeeds. The profile's assault percentage controls optional grenade preparation; the grenade supports the crossing but never gates movement. The queued throw rechecks ammunition, feature state, Zeus ownership and friendly safety, and the assault continues if it cannot be thrown. The covering element keeps supporting until consolidation. |
| Bounding advance | `Waldo_AIPass_Advance_Enable` (on) | A squad that has been in a firefight for the configured minimum (five seconds by default) advances in successive covered fire-team bounds instead of stalling. It follows an active MOVE, SAD or DESTROY objective; if that order has finished, fresh enemy knowledge can supply a finite contact objective without creating a persistent waypoint. Active HOLD, GUARD, SENTRY and other authored intent remain untouched. It compares a direct avenue with four bounded offsets once at operation start, then reuses the selected route. One element covers while the other moves, then the roles exchange. A completed attempt has a separate 20-second repeat delay; it no longer inherits the 90-second wide-flank delay. |
| Coordinated assault | `Waldo_AIPass_CoordinatedAssault_Enable` (on) | Nearby squads which accept a communicated contact can join immediately from their live position. Cortex does not assemble them at an intermediate rally point or wait for every responder. Up to two responders can advance at the same time on approach lanes at least 60 m apart. Every responder keeps one side of the supporting-fire axis, so its route cannot cross the base of fire. Each moving squad keeps its own alternating fire-team bounds while the original squad provides supporting fire. A casualty, failed bound or unsafe route retires only the affected responder; the other manoeuvre continues into assault, clear-through and consolidation. New combined bounds remain in live validation. |
| Street crossing | `Waldo_AIPass_StreetCrossing_Enable` (on) | A flanking element stops at the road edge, throws smoke and crosses in one bound. |
| Stance from cover | `Waldo_AIPass_Stance_Enable` (on) | A small rotating sample checks cover at low, middle and high height. Soldiers kneel when low cover blocks the body but leaves a firing lane, stand when taller cover still permits a high firing lane, and return to automatic stance when no useful firing position is found. Player- or Zeus-directed stances are left alone. |
| Ammo sharing | `Waldo_AIPass_AmmoShare_Enable` (on) | A soldier down to his last magazine gets one from a squad-mate within 10 m who has plenty. |
| Fire control | `Waldo_AIPass_FireControl_Enable` (on) | Soldiers deal with enemies within 20 m first and spread their fire across visible enemies. Machine gunners and riflemen with ammunition to spare alternate ordered suppression at lightly varied intervals. A short random delay stops separate squads firing in lockstep. Nobody is ordered to fire through friendlies or civilians. |
| Morale and retreat | `Waldo_AIPass_Morale_Enable` (on) | Morale is driven by casualties, suppression, a lost leader, being outnumbered, and armour the squad cannot fight. Braver soldiers hold longer. A broken squad selects from five bounded escape avenues, favours screened ground, then falls back 200 m under smoke. |
| Surrender | `Waldo_AIPass_Surrender_Enable` (on) | The last one or two survivors of a broken, isolated squad drop their weapons and surrender only when an enemy is within 60 m and no friendly squad is within 300 m. With ACE Captives loaded, players can take them prisoner. |
| Grenade evasion | `Waldo_AIPass_GrenadeEvasion_Enable` (on) | AI move away from a live grenade they can see under a short actor-level movement reservation. A soldier providing coordinated covering fire can leave the owned hold to evade; the support controller waits for that evasion instead of pulling the soldier straight back. Test it in your setup first (see Limitations). |
| Civilian danger reaction | `Waldo_AIPass_CivilianReaction_Enable` (on) | Unarmed civilians use `FiredNear` and `Hit` events to make one finite move away from danger. There is no civilian polling loop or persistent FSM. The response yields to Zeus, player control and Simple Civilian Behaviour. Radius, approximate escape distance and cooldown are separately configurable. |
| Anti-armour | `Waldo_AIPass_AntiArmour_Enable` (on) | The best launcher gunner engages known armour. He moves first if something is blocking his backblast. |
| Vehicle drills | `Waldo_AIPass_Vehicles_Enable` (on) | Eligible cargo infantry, including a separate passenger squad, get out on known contact and reboard after contact ends. A badly damaged vehicle, or an armed one that has lost its weapons, fires its smoke and, if the whole squad is mounted, withdraws. Unarmed vehicles are never treated as having lost their weapons. |
| Naval infantry landing | `Waldo_AIPass_NavalAssault_Enable` (on) | A boat crew that already knows a land target compares a bounded set of dry shore positions with adjacent shallow-water approach points, follows one finite native MOVE, stops for dismount, and releases its authored route. Separate passenger squads unload only their own cargo and receive one dry-ground egress; operating crew and gunners stay aboard. A combined crew/passenger group uses individual cargo egress so the boat is never ordered onto land. The operation does not wait for a full squad after casualties. PROTOCOL AI NAVY SEAL takes exclusive ownership when loaded. |
| Vehicle gunnery | `Waldo_AIPass_VehicleGunnery_Enable` (on) | Gunners engage anti-tank soldiers first, then armour, then everything else. Tanks and APCs back away from known AT teams to 250 m. |
| Contact reports | `Waldo_AIPass_ContactReports_Enable` (on) | Squads pass recent believed positions to nearby friendly squads for investigation, including squads on other owners. The range is 500 m through abstracted AI communications, or 35 m by voice. Radio jamming blocks the radio report. |
| Reinforcement | `Waldo_AIPass_Reinforce_Enable` (on) | Up to two idle infantry squads within 600 m move up behind a squad in contact. They then resume their own waypoints. A responder needs at least three combat-effective soldiers already on foot; vehicle crews and mounted passenger groups stay under their dedicated vehicle and transport controllers. Candidates are considered by distance; when armour appears, one additional slot requires a dismounted soldier with usable AT ammunition. Garrisons, defence lines, aircrews, static-gun crews and artillery never leave their posts to respond. Calling for help must pass WMP jamming checks. |
| Artillery support | `Waldo_AIPass_Artillery_Enable` (off) | Explicitly assigned spotters request finite HE ranging bursts from friendly artillery, including guns on another owner. Support corrections require observation and an unjammed report. Opening aim points avoid players; every shot checks friendlies and civilians. Mobile guns may relocate afterwards. |
| Artillery smoke | `Waldo_AIPass_ArtillerySmoke_Enable` (on, needs Artillery support) | A retreating squad requests a finite smoke screen from a same-side battery with smoke rounds. The server selects across owners; an inventory radio is not required, but jamming applies. Disabling requester smoke or parent artillery cancels remaining queued work. |
| Counter-battery | `Waldo_AIPass_CounterBattery_Enable` (off) | Acquires enemy firing locations, then fires finite ranging bursts. Radar reduces acquisition delay. |
| Airborne insertion | `Waldo_AIPass_Airborne_Enable` (off) | AI squads riding in AI-flown helicopters or planes climb to jump altitude as they near an enemy they know about, then parachute out one at a time about 700 m away. Each soldier keeps his backpack. Once down they fight as a normal squad. Helicopters on an unload waypoint still land, and player-flown aircraft never trigger it. |
| Aircraft flares | `Waldo_AIPass_AircraftFlares_Enable` (off) | WMP gunships and Dynamic AA fighters fire flares when a missile is launched at them. |
| Aircraft break-away | `Waldo_AIPass_AircraftBreak_Enable` (off) | The same aircraft jink sideways away from the launch, without changing their orbit or waypoints. The response is rejected below 30 m terrain clearance or when its projected one- or two-second path falls below that clearance. Lateral speed is bounded to 18 m/s; an aircraft already exceeding that lateral speed receives no additional impulse. |

Investigation and post-contact switches are live permissions. Turning either off while it owns an
active investigation, security hold, search or regroup immediately returns that group through the
normal CALM cleanup. Search actors rejoin and Cortex-owned movement and settings are released; the
group does not wait for the old phase timeout. CONTACT remains active because its individual
behaviours have separate switches and the contact state owns the safe transition back to the mission.

Every flank, advance and coordinated bound now publishes its owner-authored stage changes as a
bounded 32-entry group ledger. Each entry identifies the drill token, previous and next stage,
concrete trigger, route index and active fire team. `START`, `MOVE`, `PAUSE`, `HOLD` and `ENDED`
therefore describe observed controller changes rather than inferred waypoint state. Identical stage
writes are ignored. Zeus interruption, failure, casualty reinforcement, assault commitment,
grenade preparation, clear-through and normal completion remain distinct reasons, allowing the
audit and WMP diagnostics to tell a slow manoeuvre from a stalled or retired one without adding a
per-frame or per-unit monitor.

Aircraft reactions recheck owner locality, active/pause state, pilot health, explicit exclusions, included sides/factions and Zeus priority. Delayed flare bursts repeat these checks and carry an owner-local generation token. Handler replacement, locality migration and Cortex stop/restart advance or replace that token, so a countermeasure queued by an earlier run cannot fire under a later run. WMP gunship/Dynamic AA ownership is expected here; it does not grant an exemption from explicit compatibility exclusions. The live aircraft QA is partial and not yet accepted across native-AI, low-altitude and ownership variants.

## Behaviour and morale profiles

The pass reads the same profile names as [Waldo's AI Tuning](Waldos-AI-Tweak) (MILITIA, LINE,
VETERAN, ELITE; LEGACY behaves like LINE). Skill profiles set how well AI shoot and spot, and the
pass never changes them. Profiles tune morale, investigation and optional preparation details; they
do not assign a squad a fixed movement style. In live contact Cortex derives advance or flank from
the current objective, contact geometry, available actors and safe avenues, then tries the other
enabled manoeuvre immediately if the preferred action is not viable. Communicating nearby squads
join a coordinated action from their current positions without waiting for an assembly timer or
rally movement. Legacy `flankChance`, `advanceChance` and `coordinatedChance` keys remain accepted so
older mission configuration does not break, but they no longer select or veto movement.

Skill profiles also apply to vehicle and aircraft crews. Drivers, commanders and turret operators
receive the selected profile followed by `Waldo_AI_VehicleCrewAimMultiplier` (default `0.6`) on the
three aiming subskills; transported cargo retains the ordinary infantry profile. Without LAMBS
Turrets, WMP additionally applies `Waldo_AI_VehicleCrewDispersion` (default `3.5`) to ground crew and
`Waldo_AI_AirCrewDispersion` (default `4.25`) to aircraft crew as owner-local custom aim coefficients.
Seat and locality changes are detected by the same bounded worker, so a dismounted crew member
recovers the infantry coefficient. When LAMBS Turrets is installed, its config dispersion remains
authoritative and WMP omits only this additional coefficient. Crews belonging to a named Dynamic AA
system keep that system's authored skill and dispersion instead of receiving these generic reductions.

## Dynamic combined arms

Combined arms uses the same opportunity model as infantry coordination. A squad with a fresh visual
contact can publish one short-lived contact opportunity through the normal communications gate. The
configured contact-report radio radius limits normal selection; jamming reduces this to the configured
voice range rather than creating a separate communications model. The server selects at most two nearby armed ground-vehicle groups and one airborne armed aircraft. Momentary low speed does not make an otherwise valid aircraft disappear from the opportunity; the finite attack controller owns acceleration, progress checks and stalled-run cleanup. Each
asset accepts independently on its current owner; there is no platoon template, rally waypoint,
readiness counter or scheduled attack time. Infantry movement continues even when every supporting
asset refuses, is jammed, becomes unavailable or is taken by Zeus.

Each role carries an expiring token and records `DISPATCHED`, owner-local `APPLIED`, then server
`EXPIRED` evidence. If a vehicle or aircraft group migrates between the server and a headless client,
the new owner adopts the same still-live token once. Token matching prevents an old owner or earlier
contact from restarting the role. Expiry removes role ownership without changing the asset route.

A ground vehicle keeps its authored route and receives only the shared target, allowing the existing
gunnery and anti-tank standoff controllers to act. An aircraft keeps its existing route checkpoint and
may enter the existing finite ingress, attack and egress controller; route replacement cancels that
run. Qualified artillery spotters continue to request fire asynchronously through the existing safety,
warning-smoke and battery-availability checks. Contact sharing does not make infantry wait for rounds
to land. The opportunity scan runs at most once per observing squad every 18 to 28 seconds, selects at
most three assets and adds no per-frame or per-unit monitor.

The first additive visual audit covers natural infantry observation, immediate APC and aircraft roles,
no infantry assembly order, target transfer, actual ground fire and the aircraft attack controller.
Jamming, missing-arm, artillery, Zeus, headless-client and 50-group mixed-load variants still need fresh
in-engine acceptance.

Assault-grenade preparation and investigation remain inexpensive chances. Neither is a prerequisite
for movement or completion:

| Profile | Assault grenade | Investigation | Breaks at | Retreats | Surrenders at |
|---|---:|---:|---|---|---|
| MILITIA | 20% | 40% | early | 1.5x further | 3 survivors |
| LINE | 40% | 60% | normal | normal | 2 survivors |
| VETERAN | 55% | 75% | late | 0.8x | 1 survivor |
| ELITE | 70% | 85% | very late | 0.7x | 1 survivor |

A squad uses, in order:
1. its own profile (`(group this) setVariable ["Waldo_AIPass_Profile", "ELITE", true];`);
2. its faction's entry in `Waldo_AIPass_FactionProfiles`;
3. `Waldo_AIPass_BehaviourProfile`, the mission-wide choice (empty follows AI Rebalance);
4. the active AI Rebalance profile;
5. LINE.

Edit `Waldo_AIPass_ProfileBehaviour` in `aiConfig.sqf` to change the numbers.

### Vehicle crew and separate passenger squads

Each passenger group's owner handles its own eligible cargo units. A crew that sees a nearby enemy publishes a short-lived contact report for the passenger groups actually occupying its vehicle. The passenger owner validates that report, its vehicle and its seats before asking the vehicle owner for a bounded safe stop. The vehicle owner saves the previous forced-speed setting, brings the vehicle below 1 km/h, and acknowledges that it is ready before the passenger owner issues any exit command. Drivers, commanders and operating gunners remain aboard. The stop is cancelled and the saved speed restored when the passengers are out, the request expires, Cortex releases the group, or a newer controller takes priority. Only the group containing the effective vehicle commander may request vehicle withdrawal or gunnery.

On a normal return to CALM, recorded passengers attempt to reboard the same vehicle for up to 60 seconds. New contact, an explicit order or a disabled remount feature cancels boarding. A newer assignment to a different vehicle retires the old remount attempt; cancellation only unassigns the original vehicle. Group ownership migration retires the old engine command and continues only the still-valid passenger/vehicle intent against its original deadline, so repeated transfer cannot prolong boarding. Zeus and a newer assignment take priority. Disabling Cortex contact dismount does not disable native Arma AI bailouts. Missing seats, vehicle loss or a failed attempt must not teleport passengers. WMP feature-owned vehicles, including active convoys, remain under their dedicated controller.

Separate-group support is implemented in PR #151 and has static regression coverage. The crew report remains valid for 35 seconds so a far-tier passenger group cannot miss it on the normal 20-second scheduler cadence; this adds no per-frame worker. Physical dismount/remount and cross-owner operation still require rebuilt live acceptance. The audit retains native comparisons and both shared-group and separate-group layouts, adds stationary comparisons, and checks physical boarding into a replacement vehicle after another controller issues a new assignment. A native exit alone does not pass the Cortex-issued dismount check or become a Cortex-owned remount.

## Difficulty and tuning

These settings set how hard the AI are without touching their skill values. Set them in
`aiConfig.sqf` for the start of the mission, and change any of them during play with **WMP Cortex
> Cortex Control** in Zeus. Changes reach the server and every headless client at once, including
headless clients that join later. Each squad uses them from its next step; nothing restarts.

| Setting | Type | Default | Effect |
|---|---|---|
| `Waldo_AIPass_BehaviourProfile` | `""` | Tactics profile for every squad without its own or its faction's. Empty follows the AI Rebalance profile. |
| `Waldo_AIPass_Aggression` | `1.2` | Scales manoeuvre preference, coordinated participation, assault-grenade preparation and investigation. Any positive flank/advance mix starts a viable local tactic; `0` excludes proactive tactics. |
| `Waldo_AIPass_Cohesion` | `1` | How much punishment a squad takes before it breaks. Above `1` they hold longer. |
| `Waldo_AIPass_ReactionSpeed` | `1` | How often squads re-assess. Above `1` they react faster and use more server time. |
| `Waldo_AIPass_EngageRange` | `800` | Known enemies within this range (m) are acted on. |
| `Waldo_AIPass_Flank_MaxRange` | `400` | Farther enemies are not flanked. |
| `Waldo_AIPass_Morale_RetreatDistance` | `200` | How far a broken squad falls back. |
| `Waldo_AIPass_ZeusHoldSeconds` | `120` | How long the pass leaves a squad alone after Zeus touches it. |
| `Waldo_AIPass_ContactReports_Radius` | `500` | Radio report range. |
| `Waldo_Cortex_CombinedArms_AirRange` | `4000` | Radio-linked aircraft support opportunity range; ordinary squad reports keep their shorter radius. |
| `Waldo_AIPass_Reinforce_Radius`, `_MaxResponders` | `600`, `2` | How far away, and how many, squads come to help. |
| `Waldo_AIPass_Artillery_Rounds`, `_MaxError`, `_Cooldown`, `_MinFriendlyDistance`, `_ShootAndScoot` | `3`, `50`, `120`, `200`, on | Squads' artillery support. |
| `Waldo_AIPass_Artillery_OpeningSafeDistance`, `_OpeningBuffer`, `_WarningInterval` | `200`, `100`, `20` | Opening aim exclusion and added margin in metres; warning pause after estimated impact in seconds. |
| `Waldo_AIPass_Artillery_DefaultRole` | `"BOTH"` | Missions a gun takes when it has no role of its own (see below). |
| `Waldo_AIPass_CounterBattery_Rounds`, `_Delay`, `_RadarDelay`, `_Interval` | `4`, `60`, `20`, `60` | Rounds per burst, normal/radar acquisition delay, cooldown after completion (seconds). |
| `Waldo_AIPass_Artillery_Bursts`, `_RoundInterval`, `_LocationResetDistance` | `3`, `2`, `150` | HE burst cap; minimum spacing between rounds in seconds; reported relocation reset distance in metres. |
| `Waldo_AIPass_Airborne_DeployDistance`, `_Altitude`, `_MinAltitude` | `700`, `250`, `120` | Airborne insertion. |

The behaviour switches (which behaviours run at all) share the same pages in **Cortex Control**. From a trigger or
script:

```sqf
[createHashMapFromArray [["Waldo_AIPass_Aggression", 1.5], ["Waldo_AIPass_Cohesion", 0.8]]] call Waldo_fnc_CortexTuning;
```

Only the settings above are accepted, and numbers are kept inside the same ranges as the Zeus
sliders.

### Artillery support and counter-battery

The two have separate switches (`Waldo_AIPass_Artillery_Enable`, `Waldo_AIPass_CounterBattery_Enable`)
and separate settings. Set roles on the server (or in an Eden init field, whose client calls are ignored). Each gun can also be limited to one job:

```sqf
[this, "COUNTER"] call Waldo_fnc_CortexSetArtilleryRole;   // gun's init field: counter-battery only
[this, "SUPPORT"] call Waldo_fnc_CortexSetArtilleryRole;   // squads' fire requests (and smoke) only
```

Guns without a role use `Waldo_AIPass_Artillery_DefaultRole`. In Zeus, **Configure Artillery Battery** applies the selected role to the exact gun. Counter-battery never fires when friendlies or civilians are within
`Waldo_AIPass_CounterBattery_MinFriendlyDistance` of the enemy gun.

Assign existing soldiers explicitly on the server, or select the soldier and use **Assign Artillery Spotter**. The group selector lists assigned spotter names. Assignment persists
until removed; it neither spawns nor equips anyone.

```sqf
[spotter1, true] call Waldo_fnc_CortexSetSpotter;
[spotter1, false] call Waldo_fnc_CortexSetSpotter; // remove assignment
```

The soldier needs binoculars, recent target knowledge and a clear view. AI communications do not
check inventory radios. WMP jamming still blocks a report. Assignment remains explicit, and the
soldier watches the enemy and uses binoculars while reporting.

Before the first round of each lethal HE burst, Cortex spawns four red smoke shells in a 25 m ring around the reported target and waits ten seconds. Later rounds in that burst do not repeat the warning. This applies to lethal support and counter-battery missions. Non-lethal smoke missions do not create red warning smoke or incur its ten-second delay. The warning marks the reported target, while opening HE ranging rounds retain their deliberately offset aim. Smoke is removed after sixty seconds. The server owns the warning phase, so transferring the gun to a headless client does not restart it. Eligibility and firing safety are checked again after the warning; a warning does not guarantee that the burst will proceed. This new warning path still requires live acceptance.

Artillery fires finite bursts. Support defaults to three rounds per burst; counter-battery defaults
to four. HE missions have a default cap of three bursts, configurable from one to five. Smoke uses
one burst. Each round is still owner-checked and confirmed by an engine firing event. Inside a burst,
rounds use the same aim and a minimum two-second interval, subject to the weapon's reload speed.
After the last round, WMP waits for estimated flight time plus a 20-second warning pause before
preparing the next burst. The mission ends at its burst cap; it cannot refill itself indefinitely.
Cooldown starts when it ends. Further support needs a fresh request; counter-battery needs another
firing event after cooldown.

The opening HE burst uses a deliberate 300 m offset plus report error. At most eight aim candidates
are checked against one living-player snapshot, each needing 200 m safety distance plus a 100 m
buffer. All rounds in that burst use the accepted aim. No safe point ends the mission. This protects
aim selection, not guaranteed blast safety: dispersion and player movement still matter.

Support corrections require fresh observation of the target and prior aim area. Between bursts,
the offset reduces to 55%, with a 40 m floor. Lost observation, spotter or transmission freezes the
report and accuracy for the remaining finite bursts. A reported move of at least 150 m from the
ranging location resets the next burst to the opening offset and safety check. The burst cap is not
reset, so moving targets cannot prolong the same mission forever.

Counter-battery uses captured firing-event positions without requiring a spotter or radar. It waits
60 seconds to acquire a position, reduced to 20 seconds with live friendly radar coverage. It then
walks successive bursts closer to that recorded location. It never follows an unseen moving gun's
live position. A new firing event can reveal relocation and restart ranging at the new location.
Every new mission also begins with an offset burst.

Each shot rechecks role, eligibility, switches, ammunition, range and friendly/civilian proximity.
The server holds burst counts and coordinates guns/spotters across owners. Unknown firing outcomes
are quarantined without retry; explicit rejection ends the mission. Issued engine orders and shells
already in flight cannot be recalled.

### Survivor regroup in detail

- It only starts when someone dies; quiet missions cost nothing.
- The squad must be down to `Waldo_AIPass_Regroup_MaxRemnantSize` living members (default 2), all
  on foot. It must once have had at least `Waldo_AIPass_Regroup_MinimumPeakSize` members (default 3).
- The host is the nearest same-side infantry squad within `Waldo_AIPass_Regroup_SearchRadius`. The
  merged squad must stay within `Waldo_AIPass_Regroup_MaxGroupSize`.
- Unconscious soldiers, protected service commands and explicit garrison/defend/clear orders prevent merging. Capacity is rechecked immediately before joining.
- Survivors join only once close to the host leader. A stalled move gets one retry; a second stall or the travel deadline ends the attempt without merging distant units.

### Counter-battery setup

Enable counter-battery and give a suitable gun the COUNTER or BOTH role. Radar is optional.
Register an existing radar object for a supported side to shorten acquisition within the configured
8 km radar range. Registration does not enable counter-battery or change the object's faction.

```sqf
[radar1, west] call Waldo_fnc_CortexRegisterRadar;
[radar1, west, false] call Waldo_fnc_CortexRegisterRadar; // remove
```

The old KNOWN/RADAR mode and RequireRadio settings remain compatibility entries; they no longer
gate automatic acquisition or inspect AI inventory.

## Orders

Orders are given to a specific squad from a script or from Zeus (**WMP Cortex**, using the appropriate purpose module).

**Garrison** occupies the buildings around a point:
- roofed and upper positions are taken first;
- soldiers watch outward and duck when suppressed or hit;
- the garrison breaks and fights normally when it falls to half strength
  (`Waldo_AIPass_Garrison_BreakFraction`) or its morale breaks.

```sqf
[group this, getPosATL this, 40] call Waldo_fnc_CortexGarrison;   // garrison within 40 m
[_group] call Waldo_fnc_CortexGarrisonRelease;                    // let them move again
```

**Defend** forms a firing line across a facing direction:
- two thirds of the squad hold covered spots along the line, watching overlapping sectors;
- the rest wait in reserve 40 m behind;
- the reserve is committed once, to a gap when a third of the line has fallen, or to the point an
  enemy is closing on;
- the line breaks at half strength or when morale breaks.

```sqf
[group this, getMarkerPos "ridge", 45, 80] call Waldo_fnc_CortexDefend;   // face 045, 80 m wide
[_group] call Waldo_fnc_CortexDefendRelease;
```

**Clear building**: every available on-foot soldier, including the leader, can enter up to a bounded
eight-soldier capacity. Each committed soldier independently claims the nearest unclaimed room and
continues through further rooms. Extra soldiers form a casualty reserve. A reserve replaces a dead or
incapacitated worker; routine rotation does not interrupt a working clear. A blocked entrance is tried
through the building's other engine-defined entrances, and a blocked room returns to the shared queue
for another soldier. The order ends only after rooms have been physically visited or attempted, then
the clearing element exits before ordinary formation control resumes.

```sqf
[group this, nearestBuilding this] call Waldo_fnc_CortexClearBuilding;
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
[group this] call Waldo_fnc_CortexAirborneDrop;   // "this" is one of the passengers
```

The static chute setting, `WALDO_STATIC_STATICCHUTE`, must name a vehicle derived from `ParachuteBase`. Cortex falls back to `NonSteerable_Parachute_F` for an unavailable class or a different object type, including a parachute backpack. Soldiers keep their original backpacks.

This is separate from the player [Paradrop](Paradrop) feature. AI jumpers from Paradrop itself are
taken over once they land (see Exclusions).

## With LAMBS

All four LAMBS packages remain optional; Cortex never makes them mission dependencies. They have
different ownership implications:

| Package | Cortex treatment |
|---|---|
| [LAMBS_Danger.fsm](https://steamcommunity.com/sharedfiles/filedetails/?id=1858075458) | Active behaviour controller. Cortex uses the group-level LAMBS switch for explicit movement handover. |
| [LAMBS Waypoints](https://steamcommunity.com/sharedfiles/filedetails/?id=1858075458) | Its public garrison and CQB functions are the preferred backend for Cortex building orders whenever installed. |
| [LAMBS_Turrets](https://steamcommunity.com/sharedfiles/filedetails/?id=1862208264) | Config-only turret dispersion changes remain active in every mode. WMP retains its vehicle-crew skill multiplier but disables its additional owner-local aim coefficient while this addon is present, avoiding a stacked penalty. |
| [LAMBS_Suppression](https://steamcommunity.com/sharedfiles/filedetails/?id=1808238502) | Config-only AI suppression/stress changes remain active in every mode. |
| [LAMBS_RPG](https://steamcommunity.com/sharedfiles/filedetails/?id=1858070328) | Config-only launcher target and dispersion changes remain active in every mode. Cortex still applies its own live ammunition and backblast safety checks before an owned anti-armour shot. |

When LAMBS Danger is loaded, `Waldo_AIPass_LambsMode` decides who owns movement:

- `SPLIT` (default, shown as **Shared ownership**): LAMBS keeps what it is good at in contact:
  - moment-to-moment unit tactics, fire, anti-armour and vehicle handling;
  - sharing sightings.

  WMP keeps the state ladder, post-contact search, morale, retreat, surrender, reinforcement,
  artillery and airborne drops. When a responder accepts a Cortex reinforcement rally or coordinated
  assault, Cortex first checks LAMBS' own queued/running tactic, forced-movement and explicit-waypoint
  ownership markers. A busy LAMBS group is left alone and the responder request is rejected so another
  group can be selected. Once LAMBS is clear, a finite public lease sets
  `lambs_danger_disableGroupAI` for that responder only. Completion, rejection, expiry, locality
  migration, Zeus takeover and Cortex shutdown restore the exact value seen before the lease. The
  requester's base of fire stays under LAMBS. A group a mission maker has already set to
  `lambs_danger_disableGroupAI` retains that choice after Cortex releases it.
- `WMP` (shown as **Cortex only**): WMP runs everything and turns LAMBS group AI off for the squads it
  manages. LAMBS group AI is turned back on when the pass stops or releases the squad. The three
  config companions are unaffected.

`Waldo_AIPass_LambsMode` controls the Danger FSM ownership described above. It does not disable the
LAMBS Waypoints integration. In either mode, an installed LAMBS Waypoints supplies the primary
garrison and CQB implementation. Cortex records the semantic building intent and the spawned CQB
script handle, terminates it before a Zeus or replacement order, removes only task-owned waypoints
and state, and reconstructs the public task after a headless-client locality change. Per-call
`useLambs=false` remains available for an explicit script-only fallback test or mission override.

This handover was checked against the locally installed Workshop build of LAMBS 2.6.2.1. That build
sets `lambs_danger_isExecutingTactic` before scheduling its delayed flank or assault callback, so the
busy check covers both queued and already-running group tactics without a new polling loop. Its
Turrets, Suppression and RPG packages are config-only and remain active.

Cortex remains self-contained when LAMBS is absent. Its scheduler, movement leases, manoeuvre roles,
withdrawal, reinforcement, morale, vehicle, artillery and recovery controllers do not call LAMBS.
Its native building controller is also retained as the automatic fallback. The implementation adopts
useful architectural ideas rather than copying LAMBS code: explicit
ownership, short asynchronous tactical steps, separate move/cover roles, casualty eligibility and a
clean return to authored orders. Cortex does not claim script-level equivalents for LAMBS config/FSM
features that SQF cannot reproduce reliably. LAMBS CQB's forced-position recovery is deliberately not
adopted because Cortex must never teleport a stuck soldier.

Compatibility acceptance requires two fresh full-pack runs of the dedicated `lambs` focus: one
without optional LAMBS mods and one with `-IncludeLambs -HeadlessClients 2`. The first requires physical Cortex movement
and a sustained hold. The second also requires busy-group refusal, exact lease-baseline restoration
across a real HC adoption/release, and physical execution of a Zeus replacement order with no old-route resurrection. Static source
checks alone do not establish that either handover works in Arma.

WMP calls the installed LAMBS public interface; it does not bundle LAMBS source. LAMBS_Danger's
GPLv2 license includes an additional condition which forbids modified or derivative versions from
being uploaded to Steam Workshop. Keeping the FSM in its own optional mod also avoids a stale fork and
lets its engine-level Danger FSM continue to receive upstream fixes.

## Other AI mod compatibility

Cortex uses explicit ownership boundaries for the supplied AI and animation mods. Merely loading a
mod does not disable Cortex for ordinary infantry. The gate applies to the actor or group whose state
the other system actually owns.

| Package | Cortex treatment |
|---|---|
| [VCOM AI V3.4.0](https://steamcommunity.com/sharedfiles/filedetails/?id=721359761) | A finite Cortex movement lease saves VCOM's exact group `Vcm_Disable` value, pauses VCOM only for the accepted Cortex move, then restores that value on completion, expiry, Zeus takeover, locality handover or shutdown. Cortex refuses a lease while VCOM support or medic movement is active. It never changes VCOM skill, formation, flank or rescue settings. |
| [Improved Melee System 2](https://steamcommunity.com/sharedfiles/filedetails/?id=3510959070) | Actors carrying active IMS runtime markers or IMS animation state are excluded from Cortex movement, stance and combat commands. Loading IMS does not exclude ordinary rifle squads. The current implementation was derived from the locally available IMS generation and known IMS2 runtime markers; an installed IMS2 live arm remains required before acceptance. |
| [WebKnight Zombies and Creatures](https://steamcommunity.com/sharedfiles/filedetails/?id=2789152015) | Zombies and custom-skeleton actors are treated as WebKnight-owned. Cortex does not issue movement, stance, surrender, garrison or combat commands to them. |
| [WebKnight Droids](https://steamcommunity.com/sharedfiles/filedetails/?id=2567352444) | Droids identified by their runtime state, faction, movement config or WebKnight author metadata remain under their native controller. Ordinary soldiers in the same mission remain eligible. |
| [WBK Units LAMBS compatibility patch](https://steamcommunity.com/sharedfiles/filedetails/?id=3032643455) | The patch remains authoritative for the relationship between WebKnight actors and LAMBS. Cortex excludes those actors before requesting a LAMBS/VCOM lease, so it does not undo the patch or re-enable an incompatible FSM. |
| [Simple Civilian Behaviour](https://steamcommunity.com/sharedfiles/filedetails/?id=3529745801) | When its public flee function is present, the addon exclusively owns unarmed civilians and Cortex installs no civilian danger handlers. Without it, the optional WMP fallback supplies a lightweight event-driven flee response with the same master, radius, distance and cooldown controls used by Cortex. |
| [HBQ Advanced Driving AI](https://steamcommunity.com/sharedfiles/filedetails/?id=3812620045) | The locally installed 1.0.0 PBO was inspected. While WMP owns a convoy, it preserves and temporarily sets HBQ's public `HBQAD_Pause` and `HBQAD_PreventDisembark` variables so HBQ cannot issue competing steering, unstuck or crew-return actions. Final release restores both exact prior values, including an originally absent variable. HBQ remains authoritative for every vehicle outside a WMP convoy. WMP does not reproduce HBQ's teleport, repair, unflip, collision-damage suppression or forced navigable-area path. Its route-memory idea informed a smaller WMP watchdog which may only re-select the same unchanged final MOVE waypoint after premature completion; it never creates a route or bypasses an obstruction. |
| [PROTOCOL AI NAVY SEAL](https://steamcommunity.com/sharedfiles/filedetails/?id=3813369033) | The locally installed PBO was inspected. Its single runtime file starts two overlapping global loops which scan every group once per second, acquire any boat group near an enemy, repeatedly force dismount/movement and overwrite formation and combat state without Zeus, locality or release arbitration. When that patch is loaded, WMP yields naval control completely. Without it, the gated WMP naval landing adopts the useful high-level ideas through the existing Cortex group job: one bounded shore comparison, one finite native approach, separate crew/passenger ownership, dry-ground egress and casualty-tolerant continuation. No source, global scan, teleport, forced formation or endless controller was copied. Static acceptance is implemented; dependency-loaded and multi-owner physical acceptance remains queued. |

The compatibility gate is read-only: WMP does not clear external variables, terminate external
scripts, replace custom animations or imitate an externally owned actor. WMP Diagnostics reports
which integrations are loaded, finite VCOM leases, HBQ convoy handover, externally owned actors and active WMP civilian
responses. Source inspection and static tests establish the ownership contract; dependency-loaded
dedicated-server, headless-client, JIP and Zeus interruption runs remain required for behavioural
acceptance.

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
| `Waldo_AIPass_Enable` | `true` | Master switch. `false` means no pass code runs anywhere. |
| `Waldo_AIPass_IncludedSides` | `["WEST", "EAST", "GUER"]` | Sides the pass may command. |
| `Waldo_AIPass_LambsMode` | `"SPLIT"` | Only matters with LAMBS loaded (see above). |
| `Waldo_AIPass_FactionProfiles` | empty | Per-faction behaviour profile, for example OPF_F to ELITE. |
| `Waldo_AIPass_TickBudgetMs` | `1` | Milliseconds of work allowed per scheduler tick. |
| `Waldo_AIPass_Debug` | `false` | Extra RPT lines for contact, flanks, morale and retreats. |

## Zeus control

- **Cortex Control** combines switches and values on eight purpose pages: General and profiles; Contact and investigation; Movement and cover; Reports and reinforcement; Morale and survivors; Vehicles and convoys; Artillery and counter-battery; Airborne and aircraft. Each page opens on current values and submits named settings. The server validates them and sends one complete revision before changing local workers. Older revisions cannot roll back a later update.
- **Garrison Buildings** selects a nearby group and building-search radius.
- **Defend Position** selects a nearby group, line width and facing.
- **Clear Building** requires an explicitly selected building and a nearby group.
- **Parachute Passengers** selects the passenger group; an AI-flown aircraft must be at least 120 m over land.
- **Manage Group Control** releases a WMP garrison/defence/clear order, excludes a group for Zeus, or returns it to the pass. It does not remove separate per-feature exclusions or another controller's ownership flag.

Purpose modules list nearby groups, with the explicitly selected unit's group first. They show only the fields relevant to that purpose. All are under **WMP Cortex**.

- **Assign Artillery Spotter**: select an existing AI soldier, then assign or remove its spotter role. No automatic equipment or spawns.
- **Configure Artillery Battery**: select the exact artillery vehicle or mortar, including an empty gun, then choose support, counter-battery or both.
- **Configure Counter-battery Radar**: select an existing vehicle or prop, choose the supported side and register/update or remove it. Object faction and supported side are independent.
- **Create Convoy**: select a crewed AI land vehicle, then configure or stop its convoy.

For artillery setup: assign and equip a spotter with binoculars, set the battery role, then enable the Smart AI Pass
and artillery in **Cortex Control**. Tune warning/safety settings in **Cortex Control**. Radar acceleration also needs the counter-battery switch. Setup helpers preserve the current switches.

Order success is reported after the current owner accepts it. Missing responses are reported as
uncertain, rather than presented as successful execution.

## Independent behaviour controls

The Cortex master switch defaults on. Child switches only apply while their parent
feature is running. **WMP Cortex > Cortex Control** uses the same named settings as mission scripts;
the server validates changes and includes them in ordered settings replay for HCs and joining clients.
Convoy controls apply to explicitly configured convoys independently of the Smart AI master switch.

| Setting | Default | Effect |
| --- | --- | --- |
| `Waldo_AIPass_VehicleDismount_Enable` | `true` | Routine unloading during vehicle contact drills. |
| `Waldo_AIPass_VehicleRemount_Enable` | `true` | Reboard recorded passengers on a normal return to CALM. Stop and locality cleanup never board them. |
| `Waldo_AIPass_VehicleWithdraw_Enable` | `true` | Damaged vehicle smoke and withdrawal. |
| `Waldo_AIPass_NavalAssault_Enable` | `true` | Finite shallow-water approach, passenger dismount and dry-ground egress. PROTOCOL AI NAVY SEAL takes priority when loaded. |
| `Waldo_AIPass_CoverValidation_Enable` | `true` | Validate cover footprint, slope and blocked line of sight. |
| `Waldo_AIPass_Hearing_Enable` | `true` | Investigate nearby hostile gunfire reported by the engine to the squad leader. Reports are throttled and quantized to a 50 m area rather than revealing a target. Also requires investigation. |
| `Waldo_Convoy_MountedFire_Enable` | `true` | Direct operating weapon crews at known threats under their existing ROE. |
| `Waldo_Convoy_Cover_Enable` | `true` | Short passenger movement clear of vehicles after a halt, using cover during contact. |
| `Waldo_Convoy_ContactHalt_Enable` | `true` | Contact-driven halt requests under the existing push-through rule. |
| `Waldo_Convoy_Unload_Enable` | `true` | Routine passenger unloading at arrival, manual stop and ambush halt. |
| `Waldo_Convoy_AvoidInfantry_Enable` | `false` | Slow or stop for friendly infantry in the vehicle's immediate travel corridor. |
| `Waldo_Convoy_DrivingAssist_Enable` | `true` | Sample the road ahead every three seconds and damp speed changes before sharp curves, junctions and steep grades. Authored routes and real obstructions remain authoritative. |
| `Waldo_Convoy_RouteRecovery_Enable` | `true` | Re-select the same unchanged final MOVE waypoint after premature engine completion while the convoy remains well outside its completion radius. This never creates a route, teleports, repairs or defeats a roadblock. |

The existing vehicle gunnery switch also controls standoff manoeuvres. Other existing switches still
separate reinforcement, coordinated assault, contact reports, artillery, counter-battery, movement
drills, grenade evasion and aircraft reactions. These switches do not disable engine emergency bailouts.

Groups can veto automatic behaviours using full setting names. Set these variables publicly from the
server so every owner sees the same exclusions:

```sqf
_patrol setVariable ["Waldo_AIPass_DisabledFeatures", [
    "Waldo_AIPass_Flank_Enable",
    "Waldo_AIPass_VehicleGunnery_Enable",
    "Waldo_AIPass_ContactReports_Enable"
], true];
// Yield automatic Smart AI and convoy commands to another controller.
_patrol setVariable ["Waldo_AI_ExternalControl", true, true];
// Restore eligibility after the other controller has released the group.
_patrol setVariable ["Waldo_AI_ExternalControl", false, true];
```

`["ALL"]` excludes a group from automatic Smart AI and convoy commands. An exclusion can only remove
permission; it cannot turn on a globally disabled feature. Separate convoy passenger and weapon-crew
groups also apply their own unloading, cover and mounted-fire exclusions. Explicit garrison/defence
orders retain their existing release workflow for group-level exclusions. Turning the Cortex master
switch off releases defence, garrison and clear-building orders on their current owner, including
Cortex-owned movement restrictions. Turning it back on does not resume those cancelled orders.
Release an existing WMP order before handing that group to another controller. Cleanup may restore WMP-owned settings on the next worker step; give the new
controller its orders after that handover. Already fired shells and completed engine actions cannot
be undone by changing a switch.

## Shared capabilities and cooperation

Launcher capability is separate from a soldier's tactical role. A leader can provide AT capability,
and AA-only or empty launchers do not count as ready AT weapons. Config classification is cached;
compatible loaded and carried ammunition counts are read live. For unusual ammunition configs,
`Waldo_AIPass_AmmoCapabilityOverrides` is a mission-config HashMap from magazine classname to
`["AT"]`, `["AA"]`, both, or an empty array. It is included in settings replay.

Routine unloading requires a capable local AI passenger, a vehicle moving below 1 km/h, and dry ground
or a detected bridge deck. Driver, commander and operating weapon turrets remain aboard. Unconscious,
captive, surrendering, player-controlled and externally controlled soldiers do not receive these
orders. Remounting also requires a movable vehicle and a free cargo seat. Effective nearby allies for
surrender exclude unconscious, surrendered, captive and fleeing soldiers. ACE remains responsible for
medical treatment and prisoner interactions.

Convoy START adopts the seats of capable AI passengers already aboard, including passengers placed
by script without an assignment. It does not board troops standing outside. During travel, convoy
ownership excludes those passengers from general Cortex vehicle drills. Operating crew retain their
seats. Explicit stop, route arrival and pinned-contact halt use the passenger-only unloading path.

With `Waldo_Convoy_Cover_Enable` enabled, dismounted passengers receive a short move clear of the
vehicles after any halt. During contact it seeks cover away from the reported threat; without verified
cover it attempts a short dispersed position off the road. It performs at most two new searches per
convoy and owner every five seconds. The order expires after 45 seconds, or ends on resume, release,
external takeover or loss of eligibility. It preserves the passenger group's waypoints and adds no
permanent perimeter task. If no suitable point is found, normal AI retains control.

A travelling lead vehicle stalled short of an active MOVE waypoint retries its movement order after
ten seconds without progress. This does not skip waypoint conditions, advance the route or teleport
vehicles. Intentional spacing and pedestrian holds suppress the retry.

A contact report carries up to three recent believed positions through the server. Delivery processes
at most eight receiving groups every 0.5 seconds, expires after 15 seconds and rechecks eligibility,
range, jamming and feature gates. A receiver retains the first position for at most 30 seconds and
may investigate it. It gains no enemy-object reveal or artillery targeting from that report.

Reinforcement requests reserve helpers on the server before their owners receive movement orders.
There are at most 32 active requests, six responders per request and eight candidate checks per
request step. Each step runs no sooner than two seconds apart. A reservation lasts at most 300 seconds;
owner acknowledgement has a 15-second deadline. Owners wait up to five seconds for the matching state,
then recheck current eligibility, capability, explicit orders and feature switches. Ownership changes
redeliver the current reservation. Coordinated assault uses those same accepted reservations, avoiding
another owner-local search that could double-book helpers. While a squad is responding or assaulting,
new independent flank and bounding-advance drills cannot take its movement control. Release clears
that priority; emergency retreat and Zeus override retain their existing paths. Assault responders
receive a finite approach waypoint. Contact entry does not impose COMBAT on them; native combat
reactions remain available. Physical arrival is still under live validation and has failed recent QA.

Optional hearing uses one tracked `FiredNear` handler on an eligible AI leader. It records a position
rounded to a 50 m grid, at most once per ten seconds, with a 20-second expiry. Suppressed shots beyond
20 m are ignored. Its reach is limited by the engine event; it does not scan the battlefield for shots.
The handler is removed on disable, leader change, release of locality or stop. Investigation remains
subject to WMP eligibility and the selected LAMBS compatibility mode.

Cover selection examines at most ten nearby objects, uses a search radius capped at 25 m and checks
candidate ground and geometry. This does not prove that a position is reachable or safe. Optional
convoy infantry avoidance inspects a corridor capped at 30 m and at most 32 nearby soldiers; a more
crowded corridor requests a stop. It changes the existing speed request without adding a driving loop.

## Performance and network

- AI workers run on the server and headless clients; interface clients provide Zeus controls.
- One scheduler per machine with a soft budget checked between jobs. At least one due job runs
  each tick. A running job can exceed the budget, and scanning the queue costs more as it grows.
  The remaining jobs wait their turn in rotation. Steps are slowed when FPS is low.
- Flank, advance and coordinated-bound controllers publish a heartbeat. Standalone drills renew a
  90-second movement lease on every step. If a controller stays silent for 30 seconds, the group
  tick ends it through the normal restoration path, including PATH,
  AUTOCOMBAT, behaviour, ROE and speed. SafeStart and ENDEX give deferred jobs a 60-second grace
  after resumption. This prevents a missing job or an expired fixed lease from leaving a squad inert.
- How often a squad is stepped depends on its distance to the nearest player: every 2 s in contact
  nearby, up to every 20 s far away. A zero-mean variation of up to 0.35 s prevents groups repeatedly
  thinking and firing on the same frame without adding another job. Squads more than 2.5 km from every
  player only update their state and morale.
- Uses engine knowledge and expiring reported positions. Optional nearby-gunfire investigation adds a coarse sound report without revealing the shooter.
- Restoration checkpoints broadcast only when their contents change. Clear-building progress and orders have durable replay state.
- Artillery uses cached guns/spotters, one observer request per burst and at most eight opening aim candidates. Counter-battery uses firing-event snapshots; its legacy observer helper is not needed for automatic acquisition.
- Contact reports, reinforcement reservations and artillery have server coordination with current-owner execution. Reports contain positions; they do not reveal enemy objects.
- Tactical avenue selection runs once per operation on the group owner. It considers at most eight
  candidates with three geometry samples per leg, then reuses the chosen route through the bounds.
  It does not run per soldier or per scheduler tick. Ballistic screening and visual concealment are
  scored separately. This source bound supports, but does not yet prove, the accepted 50-group
  primary budget of at most 5% added median frame time and 10% added p95 frame time versus Cortex
  off. Prior 100-group runs remain historical saturation evidence and are not repeated by the routine audit.

## Limitations

- Not yet run in the engine. Test with the full audit mission before live use.
- A Zeus waypoint that cycles (a CYCLE patrol) keeps the squad Zeus's until you return it with AI
  Orders.
- Grenade evasion and aircraft flares are off by default:
  - grenade evasion depends on where the engine raises the `ProjectileCreated` event in multiplayer;
    if it is not raised where the AI live, the feature silently does nothing;
  - many aircraft already fire flares under AI control.
- Cross-owner reports and reinforcement are implemented but still require live WMP/ACE HC migration tests. A report can be dropped during ownership transfer; it never replays an old command to a new owner.
- LAMBS can override move orders while its own danger logic is active. Stuck-move fallbacks and
  time limits keep every behaviour finite.
- Ownership epochs retire stale jobs; changed restoration checkpoints and clear-building progress are public. The new owner restores and adopts the group. WMP and ACE headless transfers, including abrupt disconnects, still need in-engine verification.
- A garrison needs the pass running to be re-applied after a headless-client handover; the LAMBS
  hand-over does not.

## Review corrections

Zeus waypoint edits use the engine group/index event payload; waypoint deletion and attribute opening use
the waypoint-array payload. Selection-only handlers were removed after a live audit showed that inspecting
a retreating survivor cancelled its movement. Actual curator event coverage remains under live validation. Garrison, defence and clear-building orders now reject groups that fail
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
- `cortex`: scheduler state, queued jobs, pause;
- `cortex-drill-health-*`: active drill heartbeat age, watchdog threshold, movement lease and
  post-pause grace; an overdue controller is an error rather than a successful manoeuvre;
- `cortex-regroup`: regroups and units joined;
- `cortex-groups`: managed squads, squads in contact and retreating, garrisons, flanks,
  retreats, surrenders, reinforcements, grenade reactions;
- `cortex-drills`: assaults, advances, investigations, coordinated assaults, magazines shared,
  defences;
- `cortex-zeus`: squads held by Zeus, squads on Zeus waypoints, squads excluded;
- `cortex-support`: artillery, radars, airborne drops, flares;
- `cortex-tuning`: behaviour profile, aggression, cohesion, reaction speed, default battery
  role and counter-battery mode;
- `cortex-lambs`: LAMBS detection and mode.

Counters are for the server; headless-client squads are counted on their own machine. RPT lines
are tagged `[WMP CORTEX]`. Set `Waldo_AIPass_Enable` to `false`, or untick **Smart AI Pass** in
Zeus, to remove it completely: every squad is handed back to its own orders.

## Reinforcement readiness

A reinforcement waypoint uses a 10 m completion radius. Cortex records rally readiness only when at least three combat-effective members are present and every combat-effective member is within 45 m of the reserved rally position. A deleted or completed waypoint alone does not establish arrival. The reservation token must still match the current assignment.

During the coordinated assault move, Cortex temporarily disables autonomous individual attack orders so they do not compete with the assigned squad route. Normal weapon engagement remains available. The original attack-order setting is checkpointed for locality migration and restored when support expires, is revoked or is disabled.

The tighter rally movement, physical readiness check and attack-order control require a fresh coordinated-assault audit. Previous failures remain recorded; this change does not establish assault arrival or handover acceptance.

## See also

- [Waldo's AI Tuning](Waldos-AI-Tweak)
- [Dynamic AO Generation](Dynamic-AO-Generation)
- [Headless Client Support](Headless-Client-Support)
- [Radio Jamming](Radio-Jamming)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

## Cortex Control window

**WMP Cortex > Cortex Control** opens a dedicated modal window over Zeus. The left navigation groups settings by purpose; the right panel scrolls through switches, profiles and tuning with inline explanations. Existing mission variables and script functions retain their names for compatibility.

Edits remain pending across pages. **Apply changes** submits only changed settings through the existing curator-authorised server validation. **Cancel** or Escape discards pending edits. If this client has received a newer settings revision while the window was open, Apply asks the curator to reopen it rather than overwriting that revision. The window itself starts no AI workers and creates no polling loop.

The interface uses the shared WMP theme and notification-space reservation, releases its reservation on close, and reopens from current settings. Group orders and artillery/convoy setup remain separate purpose modules. This custom interface still requires in-engine layout, keyboard, Apply/Cancel and aspect-ratio validation; static checks alone do not establish usability.

### Post-contact consolidation

After security and search, eligible on-foot members receive orders to follow their leader. Cortex preserves the squad's existing waypoints and leaves explicit defence, garrison and building-clear orders in control. The gathering radius is 12 m plus 2 m per eligible member, capped at 30 m. Mounted, incapacitated and deliberately movement-disabled members are not pulled out of their existing roles.

`Waldo_Cortex_Consolidation` reports `[state, gathered, eligible, furthestDistance]` on the group. States are `CONSOLIDATING`, `COHESIVE`, `INCOMPLETE` or `CONTACT`. The existing 30-second regroup deadline releases automatic control without describing scattered units as gathered. A renewed sighting returns to contact. Zeus waypoint orders cancel Cortex's temporary tasks and release explicit holding orders through their cleanup functions.

Live acceptance is still pending for this change. The audit checks actual member spacing and subsequent travel to a Zeus-marked waypoint.

### Automatic lighting skill adjustment

Lighting defaults to **Automatic visibility** (`AUTO`). The profile applies its existing low-light multipliers when ambient light is at or below the darkness threshold (5 by default). Daylight restores the selected profile. `DAY` bypasses the extra darkness penalty; `NIGHT` preserves the legacy night-tier option. This is an ambient-light adjustment, not a complete visibility calculation for fog, walls or individual targets.

Equipped HMD items qualify for the NVG layer only when their configuration includes NVG vision. This detects capability without relying on mod-specific class names; it does not assume that a classname containing `NVG` provides night vision. It measures assigned capability rather than whether the unit has physically lowered the goggles. Flashlights receive no blanket skill bonus because that would grant awareness behind and beside the beam. The engine handles their illumination. The dedicated `lighting` audit compares actual forward-beam acquisition and fire against an equally distant rear target, plus owner-local reapplication after an HC transfer.

Each owner checks at most ten registered units per second and rewrites skills only on a lighting/equipment change. At 600 local AI, a complete refresh can take about 60 seconds. Locality adoption applies the profile immediately. Disabling skill adjustment removes the worker. Reapplication starts from the base profile, avoiding cumulative darkness penalties. These changes require fresh in-engine acceptance.


### Combined fire-team bounds (in live validation)

Reserved assault squads now receive explicit moving or covering roles from the server. One squad moves a 45–70 metre bound, scaled down for its remaining approach, while the other reserved squads cover. Inside the moving squad, one balanced fire team moves first, then covers the other as it closes. Roles rotate between squads after the physical bound completes. The last approach can enter the ordinary gated assault, grenade and clear-through sequence. An independent flank also brings its covering element forward when no final assault is selected.

This uses the existing per-group movement jobs, retry limits and feature restoration. The coordinator examines at most six reserved squads every two seconds and broadcasts roles only when they change. A failed bound yields the turn and waits eight seconds before retry; it is never counted as completed. A squad below four combat-effective dismounts is released rather than blocking the remaining manoeuvre. A missing owner response is bounded by the configured bound timeout plus a small delivery margin, capped at the existing three-minute safety limit. The combined assignment has a finite ten-minute limit for viable participants. Responders which cannot communicate or receive a safe approach are released when the attack starts. Zeus takeover, withdrawal, feature disable and lease expiry release owned movement restrictions. HC adoption restores old restrictions before consuming the current role.

These changes are not yet accepted in engine or at the 50-group primary performance target. Prior 100-group runs remain historical saturation evidence. The `coordinatedbounds` focus measures actual squad-role exchanges, movement with covering fire between squads, and movement with covering fire inside each squad. Tactical role labels explain intent; measured travel and shots establish behaviour. Earlier independent-squad overlap results do not prove coordinated overwatch.

Combat acceptance also requires readable pressure and counterplay: use observed or reported positions, preserve uncertainty, avoid simultaneous uncontrolled charges, let suppression and casualties disrupt movement, and honour player roadblocks. No recovery may teleport actors. These are acceptance requirements, not claims that every behaviour currently satisfies them.

### Movement tempo

`Waldo_AIPass_Flank_BoundPause` controls fire-team handovers, final advance holds, coordinated bound handovers, clearing and consolidation (default 2 seconds). A standalone flank uses twice that pause to establish its final position. The default bound length is 55 metres, keeping the exchange of movement and cover while avoiding a long chain of short, artificial stops. Tactical bound slots form a shallow line facing the threat even when the squad's ordinary travel formation is a wedge. These holds begin after physical arrival. Grenade clearance retains its separate minimum eight-second wait and projectile check; reducing tactical pauses cannot bypass it.

### On-demand diagnostic snapshots

AI diagnostics include every Cortex checkbox gate with its current/default value, up to 20 server-local group snapshots (eight members each), 20 fire missions, 20 convoys and 20 pending artillery relocations. Group rows show phase, drill/stage, bound, recovery count, Zeus hold, support role, actual speed, current command, PATH/MOVE and rules of engagement. Separate ownership rows expose pending remount passengers and assignment conflicts, INVESTIGATE/SEARCH transition deadlines and live gates, coordinated-support token agreement, and delayed artillery relocation purpose/deadline/gate state. Fire rows show confirmed rounds, remaining bursts and pending/uncertain state; convoy rows show owner, phase and halt reason. Total counts and sampling limits are explicit.

These are read-only snapshots requested through the existing diagnostics flow, with no new recurring controller. Enabled settings are labelled LOADED rather than proof of activity. Stationary covering units are not automatically called stalled. HC-private action and queue state is unavailable in this server report; adoption records and engine ownership do not prove HC behaviour. Live validation of the new rows is pending.

Stopping Cortex also invalidates every public delayed artillery-relocation token and clears attack-run flare phase/cooldown presentation state. Any already sleeping callback therefore fails its token check even if Cortex is restarted before the callback wakes. The stop-time vehicle scan is administrative and does not add per-frame overhead.

Each feature permission includes expected physical evidence, related tuning `[label, current, default]`, and known prerequisites. A selected child with a disabled prerequisite is UNCONFIGURED, not ACTIVE or an error. The report does not call the setting itself a trigger. Convoy permissions remain independent of the Cortex master. Group context includes phase/last-seen age, morale, search/reinforcement intent and recorded dismounted/withdrawn actors. Queue health reports locally due jobs, oldest due age, stale owner epochs, FPS and budget; a single overdue sample does not establish starvation. These report-only additions require fresh live acceptance.

Explicit defend, garrison and clear orders have separate bounded diagnostic rows, including group owner, public assignments, recorded clear result and actual member positions/distances. These rows also cover explicitly ordered groups outside automatic Cortex management. Unknown assignments use -1; arrival alone does not establish usable cover or a cleared interior.

Helicopter cruise-deceleration workers now carry an owner-local generation captured at scheduling. Ownership loss invalidates sleeping work; a rapid transfer back cannot revive it. Only the matching current owner clears correction state. This lifecycle correction has static regression coverage and still needs live migration acceptance. It does not resolve the excessive-climb result.


### Attack-run countermeasures (awaiting live acceptance)

`Waldo_Cortex_AttackRunFlares_Enable` defaults to true and independently enables approach/departure countermeasure requests for eligible AI planes and helicopters, including registered gunships and Dynamic AA aircraft. The owner samples aircraft motion once per second: approach requires an assigned hostile target within 1,500 m and closing movement; departure requires opening movement at least 100 m beyond the closest observed distance. Each leg requests two releases, one second apart. A 30-second cooldown prevents immediate repetition. Grounded aircraft, aircraft below 40 km/h, player pilots, drones, excluded groups and Zeus-held groups do not participate. No targets, waypoints, ammunition or velocity are injected. Missile-warning flares retain their separate setting.

Required live acceptance: moving plane and helicopter approach and departure, actual countermeasure Fired events and ammunition consumption, disabled comparison, empty ammunition, Zeus interruption, target loss and HC ownership transfer. These cases are not yet verified.

### Adaptive aircraft attacks (awaiting live acceptance)

`Waldo_Cortex_AirAttack_Enable` defaults to true. An eligible moving AI aircraft with a hostile assigned target receives one finite owner-local attack lease. The planner samples at most sixteen contacts already known to the pilot within 8 km for planes or 5 km for helicopters; it does not reveal or globally scan for enemies. It identifies observed AA from live launcher ammunition, inspects the aircraft's actual loaded magazines and retains one exact weapon, turret and magazine for the run. Surface patterns are weapon-specific: STRAFE uses a gun on a running nose-on pass; OFFSET and HOOK use fixed rockets on oblique and crossing runs; BOMB uses a higher fixed-wing roll-in and release; STANDOFF uses a guided missile on a long stable release leg; LATERAL keeps a helicopter's independent gun turret abeam of the target. A lateral pass is available only when a living crew member occupies that real turret. Fixed-forward and unarmed helicopters cannot receive it. An airborne hostile receives a longer lead, engage and break-away intercept using a loaded anti-air weapon.

Every release now requires the retained magazine to remain loaded, the target to be inside that weapon class's range envelope, the aircraft to be closing, the live weapon vector to align with the target and the engine to report a usable aim or lock. A manoeuvre label or elapsed timer cannot authorize a shot. Guided standoff abandons the pattern for 90 seconds when no firing solution develops, so another tactic may be chosen later. Planes continue through a successful release into a long accelerating exit rather than reversing into a low-energy loop. Observed AA moves offset geometry away from the threat sector; named Dynamic AA remains outside this general controller and retains its own effectiveness. Mission makers may set `Waldo_Cortex_AirAttackPattern` to `STRAFE`, `OFFSET`, `HOOK`, `BOMB`, `STANDOFF` or `LATERAL` for a finite authored run. An incompatible override is refused rather than silently substituting a different weapon or manoeuvre. This is an independent WMP implementation of general attack-planning principles: ingress, attack, egress, threat avoidance and re-attack decisions remain explicit rather than one endless movement order.

The AI skill profile also applies to operating vehicle and aircraft crew. Ordinary crew receive the configured final aiming multiplier and, when LAMBS Turrets is absent, the bounded owner-local aim coefficient. Crews attached to a named Dynamic AA system are exempt from both generic reductions so the system's own detection, fire gate, ammunition and authored effectiveness remain intact. LAMBS Turrets keeps its config-level dispersion and angular-error changes without WMP stacking another aim coefficient.

The controller flies physical ingress, attack and egress legs without creating or deleting waypoints. It requires actual non-countermeasure `Fired` events before leaving the attack phase. It requests approach and departure countermeasures with small random intervals, uses only onboard ammunition, monitors ground clearance and progress toward the active leg, then aborts and releases control after genuine non-progress. Target loss, locality migration, Cortex stop, feature disable or Zeus priority removes the temporary handler and speed limit. Zeus input wins immediately and Cortex does not restore an obsolete movement order. A successful run resumes toward the original waypoint only when that route remains unchanged.

Required live acceptance: a crewed armed helicopter and moving plane; gun, fixed-rocket, guided-missile and bomb delivery; a moving air-to-air target; low-threat and observed-AA pattern choice; physical target damage and destruction; visible approach/departure countermeasures with ammunition change; safe clearance; target loss; finite non-progress abort; Zeus replacement without resurrection; and HC ownership migration. The audit fails an unarmed or wrongly loaded fixture before observing its route. A fired round, accepted plan, waypoint or elapsed timer is not evidence of an effective attack. The saved audit fixtures are not yet evidence that these cases pass.


### Building clearance recovery and current acceptance

Clearance counts a room only after a soldier physically reaches its position. Each committed soldier now owns an independent movement lane and draws from the shared room queue; the former point/support pairing that left half the element outside has been removed. A soldier making progress is not failed merely because 25 seconds have elapsed. After 25 seconds without one metre of movement, Cortex retries that room. An exhausted room remains incomplete while other workers continue. Dead, mounted, non-local or transferred members release their room reservations, and uncommitted members reinforce casualties. Cleanup does not issue formation orders to members transferred to another group.

Building entry remains unresolved. Completed audit `20260930-134211` confirmed that engine pathability varies by building model: direct movement and forced replanning worked on two of four comparison models, while building-attached waypoints failed on all four. Production garrison and clear orders still failed physical arrival. The saved fixes now try every usable entrance, stop door polling from resetting the stuck timer, use a finite garrison deadline, and give every committed clearing soldier an independent lane. Additive fresh-group clearance cases cover 2, 6 and 12 soldiers and record physical room visits separately from accepted orders. These saved changes require a rebuilt live audit before CQB can be accepted.


The building audit markers identify engine building positions, not a verified room topology. Visiting every marker establishes traversal only; it does not establish successful combat clearance against defenders. Fresh two- and six-soldier cases in runtime `20260929-185445` each visited only one of four positions. Door interaction, later control protections and ordinary-waypoint handover additions were saved after that runtime launched and are not validated by it. Game validation resumed on 30 September in runtime `20260930-101931`; that run still records building-entry and clearance failures.


### Clearance changes awaiting the next live build

The current audit continues using its staged source. Subsequent saved changes include both soldiers in a two-person clearance team, preserve exhausted positions and retry budgets across owner migration, recover ended movement commands after six seconds without progress, and retain twenty-five seconds for active navigation. Formation is stopped once per worker rather than at every interior destination. Actual visits to other building positions count even when they are not the worker's assigned destination; an exhausted position is removed from that list only after a physical visit. None of these changes establishes reliable entry or combat clearance until a rebuilt audit verifies it.

The audit now observes the same eligible workers and ASL distance threshold as production, while retaining independent position observations and all previous failures. Building positions are navigation samples rather than a room topology. Hostile-room clearance, engagement and doorway coordination still require separate acceptance evidence.


### CQB validation, 30 September

Completed runtime `20260930-101931`: 54 recorded checks, 19 server findings, zero client findings and zero recorded SQF errors. Building navigation, clearance traversal and ordinary-waypoint handover failed across fresh 2/6/12-person groups. The door lock and opening checks passed; physical entry after opening failed. CQB remains unaccepted.

The next staged runtime, `20260930-104541`, includes small-team leader participation, a bounded entry element, fewer repeated STOP commands, faster recovery of ended commands, persistent retry/exhaustion checkpoints, physical incidental-visit accounting and movement reissue after door opening. Audit checks now additionally require successive-position travel and both two-person members participating. These are implementation candidates, not verified fixes. WMP diagnostics retains incomplete clearance results after controller cleanup.

Completed rebuilt runtime `20260930-111120` recorded 58 checks, 22 server findings, zero client findings and zero SQF errors. The unlocked-door physical-entry check passed. Continuous traversal and subsequent ordinary movement still failed for the two-worker controller across 2/6/12-person fixtures; garrison and independent path comparisons also retained failures. This is the preserved baseline for the CQB redesign.

The saved replacement forms up to three two-soldier clearing pairs while the leader and remaining members provide exterior security. It sorts building positions into a continuous route from the entrance, assigns balanced contiguous sectors, advances pairs immediately after observed visits and rotates an unresolved room to another pair. Physical progress renews the safety lease; scheduler delay alone does not consume a retry. Final retry and worker evidence remains available to WMP diagnostics after cleanup. This design is statically checked and still requires a rebuilt live run before acceptance.

Completed runtime `20260930-114413` recorded 58 checks, 14 server findings, zero client findings and zero SQF errors. Fresh 6- and 12-person groups physically visited every building position; the two-person group visited two of four. All sizes exposed an end-state fault: some clearing soldiers remained inside after Cortex restored formation control, so a following ordinary waypoint did not move the whole squad. The unlocked door opened but its pair failed to cross in the allowed time. These failures remain acceptance blockers.

The next saved revision alternates a point soldier and supporting partner instead of ordering both to the same path node. The supporting partner holds the preceding room or an offset entry position and the roles exchange after each physical visit. If a clearing soldier is killed or incapacitated, the existing building job fills that slot from uncommitted squad members; the leader is used only when no other reserve remains. The action now has a physical egress phase: clearing soldiers move through the doorway to an exterior release point before formation is restored, and an egress timeout makes the result incomplete. Garrison movement also retains a public pool of valid positions and gives a stalled soldier up to two free alternative assignments before recording failure. No recovery teleports a unit.

The additive building matrix now compares native direct movement, a building-attached waypoint and forced replanning on four small/large and single/multi-storey house models. Production clearance separately runs 2-, 6- and 12-person groups against progressively larger buildings. Results are reported per model and force size because an engine-invalid path on one model does not prove or excuse Cortex behaviour on another. This revision passes focused static contracts and SQF validation but requires a rebuilt live run.

Completed runtime `20260930-143339` recorded 25 server findings. The Cortex settings UI completed without a client finding. Native direct movement and replanning again reached the interior on comparison models 2 and 4, while models 1 and 3 failed all three engine movement comparisons. The unlocked-door case opened and physically crossed its threshold. Garrison, full clearance, casualty replacement and subsequent ordinary movement remained unaccepted. This run also caught repeated script errors in the staged clearance controller: an invalid entrance index could produce an empty movement target. Those errors invalidate the affected traversal results as evidence about the revised controller.

The saved correction now sends each worker directly to its claimed interior position first and uses at most four nearest entrances only after measured lack of progress. It validates an entrance before selecting it, applies the same rule after garrison reassignment, preserves live group behaviour and combat mode, and releases the leader from `doStop` on normal completion. Zeus replacement orders clear Cortex state without injecting a competing formation command. The audit observes leader movement when the leader is an assigned worker. These changes pass 140 focused operation checks and validation of 132 AI SQF files; they still require a rebuilt live run.

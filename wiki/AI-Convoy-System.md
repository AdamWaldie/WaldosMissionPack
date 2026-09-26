# AI Convoy System

> **Use this page when:** you need an AI land convoy that moves, responds to contact and unloads passengers at its destination.

_Associated Files: `MissionScripts/AiScripting/simpleAiConvoy.sqf`, `convoySync.sqf`, `convoyTick.sqf`, `convoyCrewLocal.sqf`, `convoyHaltServer.sqf`, `convoyReleaseLocal.sqf`_

WMP coordinates 2–20 AI-driven land vehicles using mission SQF and CBA on Arma 3 2.18 or newer. Registration and halt
state belong to the server. Driving, mounted fire and passenger orders execute on the owner of
the affected vehicle or soldier, including headless clients. Smart AI Pass does not need to be enabled.

## Setup and existing parameters

Put the drivers in one AI group, crew the vehicles, enable simulation and give the leader normal
waypoints. The leader's vehicle goes first. Cargo may belong to separate AI groups on other owners.
Player crews, static weapons and vehicles marked as owned by another WMP feature are rejected.
Use a final MOVE waypoint for automatic arrival unloading. GETOUT orders also affect operating
crew through the engine, so they are unsuitable when drivers and gunners must stay aboard.

```sqf
[convoyGroup] call Waldo_fnc_SimpleAiConvoy; // 30 km/h, 15 m, push through
[convoyGroup, 25, 25, false] call Waldo_fnc_SimpleAiConvoy; // stop on contact
[convoyGroup, 0] call Waldo_fnc_SimpleAiConvoy; // hold vehicles and dismount cargo
[convoyGroup, 30, 20, true] call Waldo_fnc_SimpleAiConvoy; // explicitly resume
[convoyGroup, 0, 15, true, true] call Waldo_fnc_SimpleAiConvoy; // release controller
```

## Parameters and return value

| Parameter | Type | Default | Meaning |
|---|---|---|---|
| Group | GROUP | `grpNull`, rejected | The vehicle-driver group. |
| Speed | NUMBER | 30 | Maximum km/h, clamped to 5–120. Zero or less holds and unloads. |
| Separation | NUMBER | 15 | Minimum centre spacing in metres, clamped to 10–100. Vehicle length can increase it. |
| Push through | BOOL | true | Continue through contact; halt after being pinned for 15 seconds. False halts on contact. |
| Release controller | BOOL | false | Remove registration and restore the recorded settings, without issuing a cargo unload. |

The optional sixth argument is an internal array of named `reason` and `threat` pairs (default `[]`)
used by the server halt helper. Mission makers normally use the five controls above.

The first four parameters remain the ordinary setup controls. The fifth provides explicit cleanup
now that stop means a persistent hold. On the server, calls return Boolean acceptance. A forwarded client/HC call returns dispatch acceptance
before the server result; inspect the registry or use Zeus feedback for confirmation.
An existing convoy can resume with one surviving vehicle. Terminating an old spawn handle does not stop the convoy. Server scripts, authorised Zeus requests
and the group's current headless owner may change registration.

## Contact drills and armed vehicles

With push-through enabled, vehicles continue along their route when they detect contact. Mounted
weapons engage known attackers within the permitted rules of engagement. Gunners use their existing
knowledge; the script does not reveal attackers or change hold-fire orders. Crew retain their seats,
and armed vehicles stay with the column while cargo vehicles manoeuvre.

Contact uses danger reported within the last 15 seconds from known threats within 800 m,
suppressed group members, or hostile vehicle hits within 15 seconds. Sightings alone and COMBAT
mode do not trigger a dismount. These checks run at most once every five seconds. During contact, the leader does not stop solely to close a stretched gap.

If a surviving vehicle makes less than 3 m of progress for 15 seconds during contact and moves
below 3 km/h, the group requests a halt. The server validates the current owner and registration
revision, then records the halt. With push-through disabled, contact requests this halt immediately.
A lone mobile survivor can continue. Losing all drivable vehicles also requests a halt.

A halt stops the vehicles and deploys cargo. Operating drivers, commanders and weapon-turret crew
receive no dismount order. Passenger firing positions count as cargo. Mounted weapons can continue
engaging while dismounted infantry use normal AI combat behaviour. WMP does not order an automatic
assault, pursue attackers with the escorts or select a new escape route. Those remain mission-maker
choices. Engine emergency bailouts from damaged vehicles are still possible.

The convoy stays held until Configure / resume is used. Cargo is not automatically re-embarked;
reboard passengers explicitly before resuming if they are to travel further. The hold restores the
group's original attack permission while keeping vehicle movement stopped.

## Arrival and passenger unloading

Automatic arrival requires the finite waypoint route to be complete, the leader near its last
waypoint, and all surviving vehicles stopped within the column's spacing tolerance for five seconds.
A traffic pause, intermediate waypoint, unfinished HOLD or CYCLE route does not count as arrival.
The Stop operation uses the same cargo-unloading path without waiting for route completion.

The server captures the passengers present at the halt. Each passenger owner waits until their
vehicle is below 1 km/h, checks that the unit still occupies a cargo or passenger firing seat, then
unassigns the vehicle and orders a normal dismount. Players, player-led cargo groups and
remote-controlled units are left to their operator. Unconscious passengers wait until capable;
there is no forced ejection or teleport. Repeated stop calls retain the same passenger snapshot.

## Mixed tracked and wheeled movement

Steering-compatible wheeled followers use bounded sections of the leader's sampled trail. Tracked
vehicles and vehicles without an enabled AI steering component receive native movement destinations
along that trail. They do not receive the wheeled path command. Native destinations refresh no more
than every five seconds; wheeled paths no more than every three seconds.

Column speed is capped by the configured maximum and 80% of the slowest surviving vehicle's declared
maximum speed. Vehicle dimensions set a minimum physical gap. Away from contact, the leader waits
when a gap exceeds three times its target spacing. Followers use gap and relative-speed corrections;
a 20-second stall invokes formation following with a ten-second path retry delay. Leader waypoints
remain intact. New travel orders clear the lead driver's previous hold.

These changes address incompatible path control and mixed-column pacing. Terrain, vehicle config,
engine pathfinding and damaged mobility still affect the result. Live mixed-vehicle acceptance is
outstanding; static checks cannot establish that a particular tank/truck combination drives correctly.

## Zeus, headless clients and cleanup

Use **WMP AI Control > Convoy - Create Moving Group** on an existing crewed AI land vehicle.
Its existing speed, spacing and push-through controls apply to both wheeled and tracked vehicles.
The operation selector offers Configure / resume, Stop and dismount cargo, and Release controller.
A missing target is rejected. Feedback confirms server acceptance; owners apply the effects.

The ordered registry carries the travel/halt phase, captured passengers and restoration values.
Server and headless workers process only locally owned objects. Passenger groups and turret crews
can therefore execute on a different owner from the driver group. A new owner rebuilds the local
route trail; a shared-server-time contact checkpoint preserves pinned-contact progress.

SafeStart, ENDEX, player entry and Zeus intervention suspend convoy commands. Resuming after a hold
requires explicit configuration. Release removes the registry entry and restores formation, attack
permission, forced speed and combat unloading. The group and vehicle ownership flags protect drivers and separate mounted cargo groups from
competing Smart AI orders. Separate cargo groups return to ordinary AI after their short ambush cover movement expires.

One round-robin worker runs per AI-owning machine. A convoy moves at most once per second, keeps at
most 128 local trail samples and sends at most ten points per wheeled path. Crew checks and changed
contact checkpoints run at most once every five seconds. Vehicle dimensions are cached on adoption.
More convoys reduce update frequency; delays are minimums and can grow under load.

## Contact response and passenger cover

Seeing an enemy alone does not trigger an ambush halt. Recent danger in AI knowledge,
suppression or a hostile hit on a registered vehicle provides contact evidence. Mounted weapon
crews prefer recently threatening known enemies while keeping their existing firing permissions.
The convoy keeps moving under the existing push-through setting; 15 seconds pinned in contact
requests a server-authorized halt. Disabling push-through retains immediate contact halts.

An ambush halt gives AI passengers one initial move towards nearby cover using the reported
threat position. When no suitable cover is found, a short dispersal position is attempted;
this fallback is not guaranteed protection. At most two passengers receive a new cover search
per convoy and owning machine every five seconds. The shared movement window expires 45 seconds
after the halt, and Smart AI yields during that window. Resume, release or operator intervention
clears these orders. Arrival and manual stops unload passengers without this cover movement.
A passenger observed outside the vehicle is not repeatedly unloaded after deliberately reboarding.

The server snapshot carries the halt reason, reported threat and expiry. Passenger destinations
are public for HC transfer; movement commands execute only on the passenger owner. Hit handlers
are tracked, installed on vehicle owners and removed on release. Hit broadcasts are limited to
one per vehicle every five seconds. Engine hit events can miss some damage, so they complement
knowledge and suppression rather than serving as a perfect attack sensor.

This remains an initial contact response. It does not select exit doors, guarantee safe cover,
plan a bypass around a blocked road, or coordinate an infantry assault. Live acceptance must
also test visible enemies without fire, hostile hits, cover expiry, deliberate reboarding and
HC transfers while passengers are leaving or moving to cover.

## Optional convoy behaviours

AI Tuning exposes independent switches for mounted targeting, passenger cover, contact halts and
routine unloading. They default on. Friendly-infantry avoidance is separately available and defaults
off. The [Smart AI control reference](Smart-AI-Pass#independent-behaviour-controls) lists the exact
setting names and per-group exclusions. Convoys do not require the Smart AI master switch.

The optional infantry check limits the existing speed request to walking pace or zero when friendly
soldiers occupy the immediate travel corridor. It checks at most 32 nearby soldiers within a corridor
capped at 30 m. It does not steer around them or guarantee collision avoidance.

Routine passenger unloading waits for a speed below 1 km/h and suitable ground or a detected bridge
deck. It skips unconscious, captive, surrendered and externally controlled passengers. Separate cargo
and turret groups can veto their own unloading, cover and mounted-fire behaviour. Setting
`Waldo_AI_ExternalControl` on the convoy group suspends its commands; release the convoy first for a
complete handover of restored vehicle settings.

## Limitations and acceptance checks

The full-pack audit console includes an opt-in mixed convoy at [600,500]: an armed MRAP, tracked APC
and truck with six passengers in a separate group. Its route ends at [900,600]. Add contact and
blockages through Zeus; transfer driver/cargo groups to HCs before repeating.

In-engine acceptance remains outstanding. Test tracked vehicles at the front, middle and rear of
mixed columns; bends, narrow roads, obstacles and different vehicle sizes; mobile and pinned contact;
hold-fire weapon crews; cargo and passenger firing seats; arrival, stop, resume and release; leader
loss; unconscious passengers; player/Zeus intervention; and WMP/ACE HC transfers during travel,
contact and dismount. Verify original settings after release and no duplicate or stale halt after resume.

## See also

- [Headless Client Support](Headless-Client-Support)
- [Smart AI Pass](Smart-AI-Pass)
- [WMP Zeus Modules](Waldos-Mission-Pack-Zeus-Modules)

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

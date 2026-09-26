# WMP AI follow-up assessment

Reviewed 26 September 2026 against PR #151 at `9917512`.

The seven supplied local packages contain 250 SQF files and one separate movement FSM.
All seven archives were inventoried and their configuration, initialization and relevant behaviour
paths inspected. This was targeted source review, not an exhaustive line-by-line audit or an engine
compatibility test. No third-party source was added to WMP and no runtime behaviour changed in this review.
The recommendations below describe independent mission-script work. Package identities, extracted
source and archive hashes remain in the temporary review material, outside the pack.

## Recommended implementation order

1. Correct capability classification and passenger safety checks.
2. Make contact reports and reinforcement requests work across AI owners.
3. Improve cover validation and add a bounded friendly-infantry driving check.
4. Add optional mechanized support and casualty assistance only after the above has engine evidence.

## Seven behaviour areas assessed

| Area | Useful WMP direction | Existing coverage and boundaries |
| --- | --- | --- |
| Mechanized infantry | Friendly-infantry movement corridor, water-aware unloading, cautious mounted support, finite boarding retries | Convoy already separates operating crew from cargo and holds after pinned contact. Preserve explicit convoy resume; automatic remount belongs to a separately selected mechanized behaviour. |
| Cover and concealment | Validate the soldier footprint, reserve positions, account for firing lanes and role, stop retrying failed positions, release cover when orders change | WMP already has bounded solid-cover selection and reservations. Improve this shared helper instead of adding another cover controller or movement FSM. |
| Combat awareness | Optional approximate gunfire investigation with suppressed-weapon awareness and expiring confidence | WMP already shares contact reports and investigates knowledge. Sound alone should create an uncertain area report, not reveal the shooter or authorize artillery. |
| Support coordination | Multiple capabilities per group, usable ammunition, duplicate-request suppression, expiring assignments and restoration | WMP already caps responders and restores patrols. Cross-owner coordination and accurate AT/AA capability are the main gaps. |
| Medical assistance | Reserve one helper per casualty, back off failed approaches, abandon unsafe rescue attempts, preserve current orders | Any treatment, dragging and consciousness handling must remain under ACE. Do not introduce a second damage or unconsciousness system. |
| Surrender and prisoners | Count combat-effective support, reevaluate a deteriorating situation, release temporary behaviour ownership deliberately | WMP already has morale-driven surrender through ACE Captives. Do not replace it with parallel captive actions, automatic liberation or broad surrender of neighbouring groups. |
| Artillery and air support | Cache ammunition capability, reject unsuitable assets, avoid repeatedly selecting failed targets, distinguish busy/rejected/unknown outcomes | WMP already has explicit spotters, finite bursts, ranging, safety checks and owner acknowledgements. Preserve those rules; CAS/VLS would be a separate optional subsystem. |

## Confirmed WMP source gaps

### Capability differs from tactical role

`MissionScripts/AiScripting/SmartAIPass/aiPassUnitRole.sqf` returns LEADER before inspecting a
launcher. Its launcher test returns AT without distinguishing anti-air ammunition from anti-armour
ammunition. `aiPassReinforce.sqf` and `aiPassMorale.sqf` use this role result as capability evidence.
Consequently a leader can carry usable AT without counting, while an AA-only soldier can count as AT.
The loaded-magazine presence test also does not establish a positive round count.

Add a separate read-only capability helper. Read weapon-compatible loaded and carried ammunition,
actual remaining rounds and unit fitness. Allow one soldier to have several capabilities. Cache
configuration facts; refresh inventory facts on a short expiry or equipment change. Recheck at dispatch.
Keep explicit overrides for unusual modded ammunition rather than relying on damage thresholds alone.

Acceptance: loaded empty launchers, spare compatible rounds, AA-only weapons, dual-purpose rounds,
leaders with launchers, incapacitated carriers, and inventory changes between selection and dispatch.

### AI ownership currently limits cooperation

`aiPassContactReport.sqf` only selects local receiving groups. `aiPassReinforce.sqf` only selects local
responders and counts local commitments. This supports running on HCs but means assignment to different
owners changes which squads can cooperate.

Use a small server request ledger with IDs, expiry and responder limits. Owners submit bounded reports
containing believed position, observation time and confidence. The server coordinates requests and sends
commands to current owners; owners revalidate eligibility, ammunition and locality before accepting.
A changed owner must acknowledge the current assignment revision. Do not replay stale combat reports to
JIP clients as fresh sightings. Preserve jamming, voice range, player exclusions and Zeus priority.

Acceptance: server-to-HC, HC-to-server, HC-to-HC, transfer mid-request, duplicate delivery, timeout,
disconnect, target-report expiry, jamming changes and original waypoint restoration.

### Passenger safety needs a shared contract

`aiPassVehicles.sqf` orders general Smart AI cargo out based on nearby known threats without checking
vehicle speed or water. `convoyCrewLocal.sqf` checks speed and consciousness but not whether dismounting
would place passengers in water. `aiPassRestoreCalm.sqf` reboards surviving local passengers without an
explicit ACE unconsciousness/life-state check. The general vehicle path is less guarded than the convoy.

Use a shared passenger eligibility check for current seat, consciousness, operator control, ownership,
vehicle motion and water/shore state. Keep emergency escape from a destroyed or burning vehicle separate
from routine unloading. Do not eject operating weapon crews during ordinary contact. Limit boarding
attempts and retain explicit convoy resumption; never silently change that agreed behaviour.

Acceptance: amphibious vehicles, shoreline stops, bridges, moving trucks, passenger firing seats,
unconscious/recovering passengers, destroyed transports and HC transfer during boarding.

## Further improvements worth making

### Vehicle movement around dismounts

Before a controlled vehicle moves, check a short swept corridor in its intended direction for nearby
friendly infantry. Use vehicle width and a bounded nearby set; slow or hold while occupied and resume
when clear. Cache the nearby set briefly and distinguish crossing pedestrians from persistent blockage.
This should integrate with convoy speed control rather than add competing doMove orders. It is an
avoidance aid, not a guarantee against engine collisions. Do not scan every soldier every frame.

### Better cover without a second controller

`aiPassFindCover.sqf` already limits candidate objects to ten, rejects water and reserved positions,
and tests obstruction from a believed threat. It does not explicitly validate slope, a full standing
footprint or the walking route. A blocked firing ray also cannot guarantee ballistic protection.

Add cheap slope/occupancy checks before a capped set of geometry probes. Score the surviving candidates
for the soldier's job: a supporting gunner needs a firing lane, while a moving rifleman needs a reachable
short bound. Cache failed searches too. Keep assignment expiry and release reasons so units do not
oscillate between positions or stay behind after new orders. Do not promise path reachability from a ray.

### Optional mechanized support

Armed transports could hold behind the dismounted infantry body and select a limited overwatch position,
while unarmed carriers remain farther back. This needs an explicit mechanized role, a command owner,
known threat positions and strict separation from convoy travel. Reuse the friendly-infantry corridor.
Do not automatically replace a mission route or send a convoy escort pursuing an attacker.

### Medical and prisoner work

Medical assistance is a larger feature, not a quick port. Start with an optional request/assignment
layer and validate ACE treatment and carrying APIs against the installed version. Patients and helpers
need a shared reservation, expiry, inventory checks, owner execution and cancellation on player action.
Never heal through setDamage, wake a casualty to play a carry animation, or consume fictional supplies.

For surrender, improve which nearby friendly groups count as effective support: a group of unconscious,
surrendered or fleeing soldiers should not automatically prevent surrender. Keep ACE Captives as the
interaction authority. Prisoner escort or recovery needs its own explicit design and player controls.

## Script-pack and performance boundaries

Mission SQF can read installed config classes, register controlled event handlers, use CBA scheduling,
and issue locality-correct commands. It cannot add the addon-defined ammunition/vehicle classes found
in these packages by copying their config.cpp into the mission. No engine FSM replacement is proposed;
the inspected cover movement FSM would be replaced by WMP's existing scheduled job system.

Do not carry over artificial projectile steering, automatic ammunition refill, spawned virtual aircraft,
perfect target reveals, whole-world scans on each accepted shot, or another always-on global AI loop.
These are design/performance conflicts, even where technically possible in SQF.

Every addition needs a server authority where shared state exists, current-owner execution, durable
assignment revisions, JIP replay only for current state, repeat-safe handler installation and complete
cleanup. WMP and ACE headless movement must work without pinning all new behaviour to the server.
Use the existing scheduler, bounded work per step, expiring reports and changed-state broadcasts.

## Review outcome

The immediate value is fixing capability, passenger safety and cross-owner cooperation, then improving
cover and vehicle/infantry separation. Broad CAS automation, medical replacement and another tactical
controller would add overlap and risk before these foundations are proven. The follow-up implementation now adds capability and passenger checks, cross-owner reports and reserved support, bounded cover checks, optional hearing and optional convoy infantry avoidance. Each behaviour uses existing settings transport or an independent child switch. In-engine acceptance remains outstanding. Mechanized overwatch, casualty assignment and prisoner recovery remain proposals; no additional medical controller or treatment override was added.

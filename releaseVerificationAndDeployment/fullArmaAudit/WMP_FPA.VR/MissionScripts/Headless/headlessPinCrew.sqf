/*
 * Author: WaldoTheWarfighter
 * Pins a crewed vehicle server-side against automatic headless-client migration. For real-time,
 * behaviour-sensitive WMP systems (Airborne Gunship, Paradrop flight routes, Dynamic AA, AI convoys)
 * an external headless rebalance racing WMP's own in-progress setup script - or simply moving a group
 * WMP expects to keep driving every frame - can corrupt that system's state. Confirmed live: ACE's
 * own ace_headless module (a required-mod feature, entirely separate from and uncoordinated with
 * WMP's native Waldo_fnc_Headless* system) can run a "Full Rebalance" that redistributes every
 * eligible group immediately with no settle-time grace period, unlike WMP's own native rebalance
 * (Waldo_Headless_MinGroupAgeSeconds). WMP's documented compatibility mechanisms (current-owner-
 * executes redispatch, per-unit Local event-handler adoption - see CLAUDE.md's Headless Client
 * Support section) are designed around WMP's own paced migration; they are not a guarantee against
 * every third-party mover's own timing, so these specific systems pin themselves out of automatic
 * migration by default rather than assume compatibility that has not been proven against ACE's own
 * module. A second, separate reason applies to Paradrop and Airborne Gunship specifically: both carry
 * mission-maker-configured setup - flight altitude/speed/direction and the scripted standby/green/red
 * waypoint route for Paradrop, turret profiles/orbit/service policy for Gunship - applied once to a
 * specific aircraft/group by their own registration script and never reapplied afterwards. A bare
 * setGroupOwner does not replay that setup, so migrating either mid-operation would not just desync a
 * watcher, it would silently drop the mission maker's own configured behaviour outright. Systems
 * without that one-shot configured-setup property (e.g. Dynamic AO, see below) don't share this
 * second reason, only the first.
 *
 * Sets both the convention WMP's own native headless system respects (Waldo_Headless_ExcludeGroup,
 * checked by Waldo_fnc_HeadlessRebalance) and ACE's own ace_headless module's blacklist
 * (acex_headless_blacklist, set on the vehicle - ACE excludes any group with units in a blacklisted
 * vehicle from its rebalance), so the pin holds regardless of which headless system a given mission
 * is actually using. Safe to call on a vehicle with no crew yet (only the vehicle flag is set; no
 * groups exist to pin) - useful when pinning must happen before createVehicleCrew runs.
 *
 * Locality and authority:
 * Server-only; a no-op on every other machine (safe to call unconditionally, e.g. from a spawned
 * worker that itself already runs server-only).
 *
 * Arguments:
 * 0: Vehicle <OBJECT> - the vehicle to pin; every current crew group is pinned too.
 *
 * Return Value:
 * Boolean - true when the vehicle was pinned (false on an invalid/null vehicle, or off-server).
 *
 * Example:
 * [_aircraft] call Waldo_fnc_HeadlessPinCrew;
 * Result: _aircraft and every current crew group are excluded from both WMP's native headless
 * rebalance and ACE's ace_headless module.
 *
 * Current callers: Waldo_fnc_GunshipRegister, Waldo_fnc_ParadropBuildFlightRoute,
 * Waldo_fnc_DynamicAACreate, Waldo_fnc_SimpleAiConvoy.
 */

params [["_vehicle", objNull, [objNull]]];
if !(isServer) exitWith {false};
if (isNull _vehicle) exitWith {false};

_vehicle setVariable ["acex_headless_blacklist", true, true];
private _groups = [];
{_groups pushBackUnique group _x} forEach (crew _vehicle);
{_x setVariable ["Waldo_Headless_ExcludeGroup", true, true]} forEach _groups;
true

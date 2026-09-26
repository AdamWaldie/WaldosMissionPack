/*
 * Author: WaldoTheWarfighter
 * Purpose: Keep one AI vehicle group in column formation with a speed cap and spacing. Based on
 * Tova's original convoy script, with WMP headless-crew pinning and mission-maker controls.
 * License: unlimited distribution and editing as per Tova's original.
 * Locality/authority: run once in scheduled execution on the server while it owns the group.
 * The worker calls locality-sensitive AI commands; client calls can produce conflicting loops.
 * Repeat/JIP: every spawn creates another five-second worker. Store and terminate its Script
 * handle when the route ends; do not start a duplicate for joining players.
 * Arguments:
 * 0: convoy group <GROUP> (required) - AI drivers and vehicles to control.
 * 1: speed <NUMBER> (default 30) - leader speed cap in km/h.
 * 2: separation <NUMBER> (default 15) - convoy spacing in metres.
 * 3: push through <BOOL> (default true) - prevent AI unloading on contact.
 * Return Value: SCRIPT handle from `spawn`; the function's own loop has no useful return.
 * Current callers: mission-maker server scripts, triggers and waypoint activation fields.
 * Example: convoyScript = [convoyGroup, 30, 15, true] spawn Waldo_fnc_SimpleAiConvoy;
 * Result: the server limits that convoy to the configured speed and spacing until terminated.
 * Cleanup: terminate convoyScript; restore the group's speed/unload/attack settings if changed.
 */
params ["_convoyGroup",["_convoySpeed",30],["_convoySeparation",15],["_pushThrough", true]];
// This script's own while loop below continuously drives the convoy every 5s and depends on the
// group staying local to wherever it's running - an external headless rebalance (WMP's own, or
// ACE's separate, uncoordinated ace_headless module) moving it mid-convoy would desynchronise that
// loop. Pin server-side by default; a no-op if called from a non-server machine, since headless
// migration is inherently server-only anyway. See headlessPinCrew.sqf for detail.
{[vehicle _x] call Waldo_fnc_HeadlessPinCrew;} forEach (units _convoyGroup);
if (_pushThrough) then {
    _convoyGroup enableAttack !(_pushThrough);
    {(vehicle _x) setUnloadInCombat [false, false];} forEach (units _convoyGroup);
};
_convoyGroup setFormation "COLUMN";
{
    (vehicle _x) limitSpeed _convoySpeed*1.15;
    (vehicle _x) setConvoySeparation _convoySeparation;
} forEach (units _convoyGroup);
(vehicle leader _convoyGroup) limitSpeed _convoySpeed;
while {sleep 5; !isNull _convoyGroup} do {
    {
        if ((speed vehicle _x < 5) && (_pushThrough || (behaviour _x != "COMBAT"))) then {
            (vehicle _x) doFollow (leader _convoyGroup);
        };
    } forEach (units _convoyGroup)-(crew (vehicle (leader _convoyGroup)))-allPlayers;
    {(vehicle _x) setConvoySeparation _convoySeparation;} forEach (units _convoyGroup);
};

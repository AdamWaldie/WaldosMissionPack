/*
 * Author: WaldoTheWarfighter
 * Hands AI that another WMP feature has finished with over to the Smart AI Pass: paratroopers once
 * they have landed, and transport crews once they are on foot beside a transport that is out of
 * service.
 *
 * Paradrop and Transport Services pin their AI to the server (Waldo_fnc_HeadlessPinCrew and
 * Waldo_ServerOwnedFeature), and neither feature ever releases them again, so without this they
 * would stand idle for the rest of the mission.
 * - Paratroopers: a group tagged Waldo_Paradrop_Jumped (set by the static-line and HALO jumps for AI
 *   jumpers, including mission-maker AI riding a Quick Flight aircraft and Dynamic Paradrop's
 *   generated jumpers) is released once every living member is out of the aircraft and parachute
 *   and on the ground.
 * - Transport crews: a group tagged Waldo_TransportService_Vehicle (set by Waldo_fnc_TransportRegister)
 *   is released once its transport is out of service, using the same test the transport monitor
 *   uses to write a transport off (destroyed, no living driver, can no longer move, or damaged beyond
 *   Waldo_Transport_MaxEffectiveDamage), and every living member is on foot. A crew still riding a
 *   working transport is never touched.
 * Release undoes only the feature's own pin: Waldo_fnc_HeadlessPinCrew recorded the values it
 * overwrote (Waldo_HeadlessPin_Prior) on the group and each soldier, and release puts exactly those
 * back. An exclusion the mission maker had set before the pin (Waldo_ServerOwnedFeature,
 * Waldo_Headless_ExcludeGroup or acex_headless_blacklist) therefore survives, and one set without a
 * pin record is never touched. Headless balancing may take the group only if nothing else pins it.
 * Each soldier is also unassigned from the vehicle so it no longer marks him as feature-owned.
 * Locality and authority: call where the group is local (the server for pinned groups).
 *
 * Arguments:
 * 0: group <GROUP>
 *
 * Return Value:
 * Boolean - true when the group was released
 *
 * Example:
 * [_group] call Waldo_fnc_AIPassReleaseFeatureCrew;
 * Result: landed paratroopers become an ordinary AI squad the pass manages.
 *
 * Current caller: Waldo_fnc_AIPassDiscover.
 */

params [["_group", grpNull, [grpNull]]];
if (isNull _group || {!local _group}) exitWith {false};
private _alive = (units _group) select {alive _x};
if (_alive isEqualTo [] || {_alive findIf {isPlayer _x} >= 0}) exitWith {false};
private _onFoot = _alive findIf {vehicle _x != _x} < 0;
if (!_onFoot) exitWith {false};

private _release = false;
private _kind = "landed paratroopers";
if (_group getVariable ["Waldo_Paradrop_Jumped", false]) then {
    _release = _alive findIf {!isTouchingGround _x && {((getPosATL _x) select 2) > 2}} < 0;
};
private _transport = _group getVariable ["Waldo_TransportService_Vehicle", objNull];
if (!_release && {!isNil {_group getVariable "Waldo_TransportService_Vehicle"}}) then {
    _kind = "transport crew";
    _release = isNull _transport || {!alive _transport} || {!canMove _transport}
        || {isNull driver _transport} || {!alive driver _transport}
        || {damage _transport >= (missionNamespace getVariable ["Waldo_Transport_MaxEffectiveDamage", 0.8])};
};
if (!_release) exitWith {false};

// Put back what the pin overwrote; leave anything the pin did not set.
private _restorePin = {
    params ["_target"];
    private _prior = _target getVariable ["Waldo_HeadlessPin_Prior", []];
    if !(_prior isEqualType [] && {_prior isNotEqualTo []}) exitWith {false};
    {
        _x params [["_variable", "", [""]], "_value"];
        if (_variable != "") then {
            if (count _x > 1) then {_target setVariable [_variable, _value, true]} else {_target setVariable [_variable, nil, true]};
        };
    } forEach _prior;
    _target setVariable ["Waldo_HeadlessPin_Prior", nil, true];
    true
};
private _restored = [_group] call _restorePin;
{_group setVariable [_x, nil, true]} forEach ["Waldo_Paradrop_Jumped", "Waldo_TransportService_Vehicle"];
{
    [_x] call _restorePin;
    if (local _x) then {unassignVehicle _x};
} forEach _alive;
missionNamespace setVariable ["Waldo_AIPass_FeatureCrewsReleased", (missionNamespace getVariable ["Waldo_AIPass_FeatureCrewsReleased", 0]) + 1];
diag_log format ["[WMP AI PASS] %1 released to the pass (%2 soldiers, %3, pin %4).", _group, count _alive, _kind, ["not recorded, left as is", "restored"] select _restored];
true

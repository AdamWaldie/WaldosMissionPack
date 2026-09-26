/*
 * Author: WaldoTheWarfighter
 * Executes exactly one checked shot on the current battery owner. The server observes the actual firing event.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>; 1: aim ATL <ARRAY>; 2: magazine <STRING>; 3: purpose <STRING>; 4: mode <STRING>; 5: token <STRING>.
 * Return Value: Boolean, firing command issued.
 * Current callers: ArtilleryMissionStep.
 * Example: [_gun, _aim, _mag, "SUPPORT", "HE", _token] remoteExecCall ["Waldo_fnc_AIPassArtilleryShot", owner _gun];
 */
params ["_battery", "_aim", "_magazine", "_purpose", "_mode", "_token"];
if (remoteExecutedOwner != 2) exitWith {false};
private _reject = {
    [_battery, _token] remoteExecCall ["Waldo_fnc_AIPassArtilleryRejected", 2];
    false
};
if (!local _battery || {!alive _battery} || {!alive gunner _battery}
    || {(_battery getVariable ["Waldo_AIPass_FireToken", ""]) != _token}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_AIPassIsPaused}
    || {!([group gunner _battery] call Waldo_fnc_AIPassIsEligible)}
    || {!([_battery, _purpose] call Waldo_fnc_AIPassArtilleryRole)}
    || {!([group gunner _battery, ["Waldo_AIPass_Artillery_Enable", "Waldo_AIPass_CounterBattery_Enable"] select (_purpose == "COUNTER"), false] call Waldo_fnc_AIPassFeatureEnabled)}) exitWith {call _reject};
private _minimum = if (_mode == "SMOKE") then {50} else {missionNamespace getVariable [["Waldo_AIPass_Artillery_MinFriendlyDistance", "Waldo_AIPass_CounterBattery_MinFriendlyDistance"] select (_purpose == "COUNTER"), 200]};
private _side = side group gunner _battery;
if ((_aim nearEntities [["CAManBase", "LandVehicle", "Air", "Ship"], _minimum]) findIf {
    private _entity = _x;
    alive _entity && {([_entity] + crew _entity) findIf {alive _x && {side _x == civilian || {_side getFriend (side _x) >= 0.6}}} >= 0}
} >= 0) exitWith {call _reject};
if (!(_magazine in getArtilleryAmmo [_battery]) || {(magazinesAllTurrets [_battery,true]) findIf {(_x select 0) == _magazine && {(_x select 2) > 0}} < 0} || {!(_aim inRangeOfArtillery [[_battery], _magazine])}
    || {_battery getArtilleryETA [_aim, _magazine] < 0}) exitWith {call _reject};
_battery doArtilleryFire [_aim, _magazine, 1];
true

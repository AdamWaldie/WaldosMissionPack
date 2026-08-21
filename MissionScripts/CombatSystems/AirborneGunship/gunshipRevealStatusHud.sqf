/*
 * Author: WaldoTheWarfighter
 * Reveals the off-station status panel (Waldo_fnc_GunshipStatusHud) for one gunship system on demand,
 * for a fixed duration - in response to the "View Off-Station Status" self-interaction. The panel is
 * never shown automatically by any per-frame loop; a controller who wants to know why their gunship
 * is off station explicitly asks for it, and it auto-hides either once the requested duration elapses
 * or as soon as the gunship returns to ON_STATION/CONTROLLED, whichever comes first.
 *
 * Locality and authority: runs only on the receiving interface client; reads only the already-
 * published Waldo_Gunship_PublicSystems array. Never mutates server state.
 *
 * Arguments:
 * 0: System id <STRING>
 * 1: Duration <NUMBER> - seconds the panel stays visible before auto-hiding (optional, default: 10)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["SPECTRE_1"] call Waldo_fnc_GunshipRevealStatusHud;
 *
 * Current callers: Waldo_fnc_GunshipSetupLocal (the "View Off-Station Status" self-interaction).
 */

params [["_id", "", [""]], ["_duration", 10, [0]]];
if !(hasInterface) exitWith {};

private _lookup = {
    params ["_id"];
    private _systems = missionNamespace getVariable ["Waldo_Gunship_PublicSystems", []];
    private _idx = _systems findIf {(_x select 0) == _id};
    if (_idx < 0) exitWith {[]};
    _systems select _idx
};

private _system = [_id] call _lookup;
if (_system isEqualTo []) exitWith {};
_system params [
    "", "", "", "_status", "", "", "", "_callsign", "", "",
    ["_serviceCompleteAt", -1], ["_serviceDuration", 0], ["_radius", 1500], ["_altitude", 700],
    ["_offStationReason", ""]
];

[true, _callsign, _status, _offStationReason, _serviceCompleteAt] call Waldo_fnc_GunshipStatusHud;

[_id, _duration, _lookup] spawn {
    params ["_id", "_duration", "_lookup"];
    private _deadline = diag_tickTime + _duration;
    waitUntil {
        sleep 1;
        private _system = [_id] call _lookup;
        private _stillOffStation = !(_system isEqualTo []) && {!((_system select 3) in ["ON_STATION", "CONTROLLED"])};
        diag_tickTime >= _deadline || {!_stillOffStation}
    };
    [false] call Waldo_fnc_GunshipStatusHud;
};

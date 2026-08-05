/*
 * Author: WaldoTheWarfighter, Val
 * Maintains registered transport markers and removes dead/deleted services from their typed pools.
 * It performs no movement planning and publishes availability booleans only when pool state changes.
 * Locality and authority: server-only registry cleanup and JIP availability publication.
 *
 * Arguments: None.
 * Return Value: Nothing; long-running server monitor.
 * Example: [] spawn Waldo_fnc_TransportMonitorServer;
 * Current caller: Waldo_fnc_TransportInitServer once per mission.
 */
if (!isServer) exitWith {};
while {missionNamespace getVariable ["Waldo_Transport_ServerStarted", false]} do {
    private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
    private _pools = missionNamespace getVariable ["Waldo_Transport_Pools", createHashMapFromArray [["HELICOPTER", []], ["GROUND", []]]];
    {
        private _id = _x;
        private _entry = _services get _id;
        private _vehicle = _entry getOrDefault ["vehicle", objNull];
        if (isNull _vehicle || {!alive _vehicle} || {isNull driver _vehicle} || {!alive driver _vehicle}) then {
            private _marker = _entry getOrDefault ["marker", ""];
            if (_marker != "") then {deleteMarker _marker};
            private _destinationMarker = _entry getOrDefault ["destinationMarker", ""];
            if (_destinationMarker != "") then {deleteMarker _destinationMarker};
            private _landingPad = _entry getOrDefault ["landingPad", objNull];
            if (!isNull _landingPad) then {deleteVehicle _landingPad};
            private _type = _entry getOrDefault ["type", "GROUND"];
            private _pool = _pools getOrDefault [_type, []];
            _pool = _pool - [_id];
            _pools set [_type, _pool];
            _services deleteAt _id;
        } else {
            private _marker = _entry getOrDefault ["marker", ""];
            if (_marker != "") then {_marker setMarkerPos getPosATL _vehicle; _marker setMarkerDir getDir _vehicle};
        };
    } forEach +(keys _services);
    missionNamespace setVariable ["Waldo_Transport_Services", _services];
    missionNamespace setVariable ["Waldo_Transport_Pools", _pools];
    missionNamespace setVariable ["Waldo_HeliTransport_Available", (_pools getOrDefault ["HELICOPTER", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0, true];
    missionNamespace setVariable ["Waldo_GroundTaxi_Available", (_pools getOrDefault ["GROUND", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0, true];
    sleep 2;
};

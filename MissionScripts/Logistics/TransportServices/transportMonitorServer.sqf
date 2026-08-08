/*
 * Author: WaldoTheWarfighter, Val
 * Maintains registered transport markers and removes dead/deleted services from their typed pools.
 * It performs no movement planning and publishes availability booleans only when pool state changes.
 * Besides tracking each vehicle's live position/facing, the marker's own text is kept in sync with
 * that service's current state (Available, Boarding, To Pickup, To Destination, RTB, Disembarking,
 * Manual Control, Stuck) - a marker that only ever shows the callsign gives no indication a transport
 * is already busy without opening the interaction menu on it. Also recovers a transport left under
 * manual control after its player pilot disconnects, dies or otherwise leaves the driver's seat, so a
 * squad leader elsewhere is never permanently locked out of a transport an absent player was flying.
 * Locality and authority: server-only registry cleanup and JIP availability publication.
 *
 * Arguments: None.
 * Return Value: Nothing; long-running server monitor.
 * Example: [] spawn Waldo_fnc_TransportMonitorServer;
 * Current caller: Waldo_fnc_TransportInitServer once per mission.
 */
if (!isServer) exitWith {};
private _stateLabels = createHashMapFromArray [
    ["AVAILABLE", "Available"], ["BOARDING", "Boarding"], ["DISEMBARKING", "Disembarking"],
    ["TO_PICKUP", "To Pickup"], ["TO_DESTINATION", "To Destination"], ["RTB", "RTB"], ["STUCK", "Stuck"],
    ["MANUAL", "Manual Control"]
];
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
            // A manual pilot who disconnects, dies or gets out leaves the driver's seat occupied by
            // something that is no longer a live human (a disconnected unit reverts to non-player).
            // Recover automatically so the transport is never permanently stranded away from AI
            // control just because its player pilot is gone - the marker/state text below will
            // reflect the recovered state on this same tick once _entry is refreshed.
            if ((_entry getOrDefault ["state", ""]) == "MANUAL" && {!isPlayer driver _vehicle}) then {
                [_vehicle, objNull] call Waldo_fnc_TransportReleaseManualServer;
                _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
                _entry = _services getOrDefault [_id, _entry];
            };
            private _protectionOwners = [owner _vehicle, groupOwner group driver _vehicle];
            if !(_entry getOrDefault ["protectionOwners", []] isEqualTo _protectionOwners) then {
                _entry = [_entry] call Waldo_fnc_TransportRefreshProtectionServer;
                _services set [_id, _entry];
            };
            private _marker = _entry getOrDefault ["marker", ""];
            if (_marker != "") then {
                _marker setMarkerPos getPosATL _vehicle;
                _marker setMarkerDir getDir _vehicle;
                private _state = _entry getOrDefault ["state", "AVAILABLE"];
                private _stateLabel = _stateLabels getOrDefault [_state, _state];
                private _markerText = format ["%1 - %2", _entry getOrDefault ["name", _id], _stateLabel];
                private _lastMarkerText = _entry getOrDefault ["markerText", ""];
                if (_markerText != _lastMarkerText) then {
                    _marker setMarkerText _markerText;
                    _entry set ["markerText", _markerText];
                };
            };
        };
    } forEach +(keys _services);
    missionNamespace setVariable ["Waldo_Transport_Services", _services];
    missionNamespace setVariable ["Waldo_Transport_Pools", _pools];
    missionNamespace setVariable ["Waldo_HeliTransport_Available", (_pools getOrDefault ["HELICOPTER", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0, true];
    missionNamespace setVariable ["Waldo_GroundTransport_Available", (_pools getOrDefault ["GROUND", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0, true];
    sleep 2;
};

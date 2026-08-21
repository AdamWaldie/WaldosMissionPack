/*
 * Author: WaldoTheWarfighter, Val
 * Maintains registered transport markers and removes dead/deleted/combat-ineffective services from
 * their typed pools - a vehicle destroyed, missing its driver, or damaged at or above
 * Waldo_Transport_MaxEffectiveDamage (default 0.8) is written off the same way; the damage case also
 * notifies every player on the service's allowedSides, since (unlike outright loss) that one is not
 * self-evident. It performs no movement planning and publishes availability booleans only when pool
 * state changes.
 * Besides tracking each vehicle's live position/facing, the marker's own text is kept in sync with
 * that service's current state (Available, Boarding, To Pickup, To Destination, RTB, Disembarking or
 * Stuck) - a marker that only ever shows the callsign gives no indication a transport is already busy
 * without opening the interaction menu on it.
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
    ["TO_PICKUP", "To Pickup"], ["TO_DESTINATION", "To Destination"], ["RTB", "RTB"], ["STUCK", "Stuck"]
];
// Last-broadcast availability state. These start unset so the first pass always publishes once;
// every pass after that only broadcasts a flag that actually flipped, matching this file's own
// documented "publishes availability booleans only when pool state changes" contract - the three
// setVariable calls below used to fire unconditionally every 2s for the whole mission (Transport
// Services is enabled by default), which is a real, continuous, per-client broadcast cost with a
// large connected player count even when no transport availability ever changed.
private _lastHeliAvailable = nil;
private _lastGroundAvailable = nil;
private _lastBoatAvailable = nil;
while {missionNamespace getVariable ["Waldo_Transport_ServerStarted", false]} do {
    private _services = missionNamespace getVariable ["Waldo_Transport_Services", createHashMap];
    private _pools = missionNamespace getVariable ["Waldo_Transport_Pools", createHashMapFromArray [["HELICOPTER", []], ["GROUND", []], ["BOAT", []]]];
    {
        private _id = _x;
        private _entry = _services get _id;
        private _vehicle = _entry getOrDefault ["vehicle", objNull];
        // A transport at or above this damage fraction is combat-ineffective even while technically
        // still "alive" - previously only outright destruction (or driver death) wrote a service off,
        // so a vehicle limping along at, say, 95% damage stayed in the pool looking fully available.
        private _maxEffectiveDamage = missionNamespace getVariable ["Waldo_Transport_MaxEffectiveDamage", 0.8];
        private _destroyed = isNull _vehicle || {!alive _vehicle};
        private _driverLost = !_destroyed && {isNull driver _vehicle || {!alive driver _vehicle}};
        private _tooDamaged = !_destroyed && !_driverLost && {damage _vehicle >= _maxEffectiveDamage};
        if (_destroyed || _driverLost || _tooDamaged) then {
            if (_tooDamaged) then {
                // Destroyed/driver-lost transports are self-evidently gone; a still-standing but
                // written-off vehicle is not, so this is the one case that needs telling anyone who
                // relies on it - otherwise a side just sees its transport quietly vanish from
                // availability with no explanation. Split into its own locally-called helper so this
                // recurring monitor loop stays free of remote execution itself.
                [
                    _entry getOrDefault ["name", _id],
                    _entry getOrDefault ["type", "GROUND"],
                    (_entry getOrDefault ["config", createHashMap]) getOrDefault ["allowedSides", []]
                ] call Waldo_fnc_TransportNotifyLoss;
            };
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
    private _heliAvailable = (_pools getOrDefault ["HELICOPTER", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0;
    private _groundAvailable = (_pools getOrDefault ["GROUND", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0;
    private _boatAvailable = (_pools getOrDefault ["BOAT", []]) findIf {(_services get _x) getOrDefault ["state", ""] == "AVAILABLE"} >= 0;
    if (isNil "_lastHeliAvailable" || {_heliAvailable != _lastHeliAvailable}) then {
        missionNamespace setVariable ["Waldo_HeliTransport_Available", _heliAvailable, true];
        _lastHeliAvailable = _heliAvailable;
    };
    if (isNil "_lastGroundAvailable" || {_groundAvailable != _lastGroundAvailable}) then {
        missionNamespace setVariable ["Waldo_GroundTransport_Available", _groundAvailable, true];
        _lastGroundAvailable = _groundAvailable;
    };
    if (isNil "_lastBoatAvailable" || {_boatAvailable != _lastBoatAvailable}) then {
        missionNamespace setVariable ["Waldo_BoatTransport_Available", _boatAvailable, true];
        _lastBoatAvailable = _boatAvailable;
    };
    sleep 2;
};

/*
 * Author: WaldoTheWarfighter
 * Runs the server-authoritative detector for one named Dynamic AA system.
 *
 * The zone is a horizontal map circle: aircraft are tested with distance2D, then independently
 * checked against the configured altitude floor and ceiling. Only hostile, crewed aircraft that pass
 * those checks are sent to the owner of each defence group. This prevents the engine's 3D distance
 * calculation from unintentionally shrinking the zone for high aircraft. The same approved object
 * list drives the owner-local Fired gate, so opening the site for one valid aircraft cannot permit
 * an independently acquired ground, low, high or out-of-zone target.
 *
 * Locality and authority:
 * Runs only on the server and updates the public Dynamic AA snapshot on transitions. AI commands are
 * delegated by Waldo_fnc_DynamicAASetGroupState to each group's current owner. The loop is removed by
 * deleting/deactivating its registry entry; only one loop is started per registered system.
 *
 * Arguments:
 * 0: id <STRING> - registered system id
 *
 * Return Value:
 * Nothing. The spawned loop exits when the system is removed, deactivated or loses required radar.
 *
 * Current callers:
 * Waldo_fnc_DynamicAACreate after the server has registered and published the complete system state.
 *
 * Example:
 * ["north_sector"] spawn Waldo_fnc_DynamicAADetectorLoop;
 * Result: the system stays closed except while hostile aircraft pass every current gate.
 */

params [["_id", "", [""]]];
if !(isServer) exitWith {};

while {true} do {
    private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
    if !(_id in (keys _registry)) exitWith {};
    private _state = _registry get _id;
    if !(_state getOrDefault ["active", false]) exitWith {};
    private _config = _state get "config";
    private _radars = _state getOrDefault ["radars", [_state getOrDefault ["radar", objNull]]];
    private _requiredRadars = ((_config getOrDefault ["requiredOperationalRadars", 1]) max 1) min (count _radars max 1);
    private _maximumRadarDamage = ((_config getOrDefault ["maximumOperationalRadarDamage", 0.8]) max 0) min 1;
    private _radarCondition = _config getOrDefault ["radarOperationalCondition", {true}];
    private _operationalRadars = _radars select {
        private _radar = _x;
        private _basicOperational = !isNull _radar
            && {alive _radar}
            && {simulationEnabled _radar}
            && {damage _radar < _maximumRadarDamage};
        if (_basicOperational) then {
            private _customOperational = [_radar, _state, _config] call _radarCondition;
            _customOperational isEqualType true && {_customOperational}
        } else {
            false
        }
    };
    if (count _operationalRadars < _requiredRadars) exitWith {
        diag_log format ["[WMP DYNAMIC AA] '%1' offline: operational radars %2/%3.", _id, count _operationalRadars, _requiredRadars];
        [_id, _config getOrDefault ["cleanupOnRadarLoss", false]] call Waldo_fnc_DynamicAADestroy;
    };

    private _centre = _config get "centre";
    private _radius = _config get "radius";
    private _minimumAltitude = _config get "minimumAltitude";
    private _maximumAltitude = _config getOrDefault ["maximumAltitude", 1e10];
    private _mode = toUpperANSI (_config getOrDefault ["altitudeMode", "AUTO"]);
    private _aaSide = _config get "side";
    // vehicles is intentional here. nearestObjects uses a 3D sphere, which would make a 2 km map
    // zone only about 1.7 km wide for an aircraft flying 1 km above it.
    private _aircraft = vehicles select {
        private _candidate = _x;
        private _position = getPosWorld _candidate;
        private _altitude = switch (_mode) do {
            case "ATL": {getPosATL _candidate select 2};
            case "ASL": {getPosASL _candidate select 2};
            default {
                if (surfaceIsWater _position) then {getPosASL _candidate select 2} else {getPosATL _candidate select 2}
            };
        };
        _candidate isKindOf "Air"
        && {alive _candidate}
        && {_candidate distance2D _centre <= _radius}
        && {_altitude >= _minimumAltitude}
        && {_altitude <= _maximumAltitude}
        && {{alive _x && {_aaSide getFriend (side group _x) < 0.6}} count crew _candidate > 0}
    };
    // The default must return a Boolean because select expects a Boolean predicate. An empty code
    // block returns nil and caused otherwise valid dedicated-server systems to detect nothing.
    private _detectionFilter = _config getOrDefault ["detectionFilter", {true}];
    if (_detectionFilter isEqualType {}) then {
        _aircraft = _aircraft select {
            private _accepted = [_x, _state, _config] call _detectionFilter;
            _accepted isEqualType true && {_accepted}
        };
    };
    private _rawDetected = count _aircraft > 0;
    private _wasDetected = _state getOrDefault ["detected", false];
    private _detected = _wasDetected;
    if (_rawDetected) then {
        _state set ["clearSince", -1];
        private _candidateSince = _state getOrDefault ["candidateSince", -1];
        if (_candidateSince < 0) then {_candidateSince = diag_tickTime; _state set ["candidateSince", _candidateSince]};
        _detected = diag_tickTime - _candidateSince >= (_config getOrDefault ["detectionDwell", 0]);
    } else {
        _state set ["candidateSince", -1];
        if (_wasDetected) then {
            private _clearSince = _state getOrDefault ["clearSince", -1];
            if (_clearSince < 0) then {_clearSince = diag_tickTime; _state set ["clearSince", _clearSince]};
            _detected = diag_tickTime - _clearSince < (_config getOrDefault ["clearDelay", 5]);
        } else {
            _detected = false;
        };
    };

    private _engagementAircraft = _aircraft select {_x distance2D _centre <= (_config getOrDefault ["engagementRadius", _radius])};
    private _engaged = _detected && {count _engagementAircraft > 0};
    private _wasEngaged = _state getOrDefault ["engaged", false];

    // Re-issue the gate on every pass, including while closed. Arma may reacquire a hostile from
    // ordinary visual knowledge after the transition that first closed the site; a one-shot close
    // therefore is not a durable safety boundary. This periodic authoritative close also follows
    // AI groups after locality migration without relying on a state transition to happen again.
    {
        [_x, _engaged, _engagementAircraft] call Waldo_fnc_DynamicAASetGroupState;
    } forEach (_state getOrDefault ["defenceGroups", []]);

    if (_engaged != _wasEngaged) then {
        if (_engaged && {_config getOrDefault ["rearmOnActivation", false]}) then {
            private _ammoFraction = ((_config getOrDefault ["initialAmmoFraction", 1]) max 0) min 1;
            {
                [_x, _ammoFraction] call Waldo_fnc_DynamicAASetVehicleAmmo;
            } forEach ((_state getOrDefault ["objects", []]) select {_x isKindOf "AllVehicles"});
        };
        _state set ["engaged", _engaged];
    };
    if (_detected != _wasDetected || {_engaged != _wasEngaged}) then {
        diag_log format [
            "[WMP DYNAMIC AA] '%1' transition: detected=%2 engaged=%3 eligible=%4 engagementEligible=%5.",
            _id, _detected, _engaged, count _aircraft, count _engagementAircraft
        ];
        _state set ["detected", _detected];
        _registry set [_id, _state];
        missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];
        [] call Waldo_fnc_DynamicAAPublishState;
        if (_detected != _wasDetected && {_config getOrDefault ["announce", true]}) then {
            [_id, _detected] call Waldo_fnc_DynamicAANotifyState;
        };
        private _stateCallback = _config getOrDefault ["onStateChanged", {}];
        if (_stateCallback isEqualType {}) then {
            [_id, _detected, _engaged, _aircraft, _state] call _stateCallback;
        };
    };

    _registry set [_id, _state];
    missionNamespace setVariable ["Waldo_DynamicAA_Registry", _registry];

    private _waves = _state getOrDefault ["fighterWaves", 0];
    private _maximumWaves = _config getOrDefault ["fighterMaximumWaves", 1];
    private _wavesAvailable = _maximumWaves < 0 || {_waves < (_maximumWaves max 1)};
    private _cooldownMet = diag_tickTime - (_state getOrDefault ["lastFighterScramble", -1e10]) >= (_config getOrDefault ["fighterCooldown", 600]);
    if (_engaged && {(_config getOrDefault ["fighterCount", 0]) > 0} && {_wavesAvailable} && {_cooldownMet}) then {
        [_id, _engagementAircraft] call Waldo_fnc_DynamicAASpawnFighters;
    };
    sleep ((_config getOrDefault ["detectionInterval", 1]) max 0.25);
};

/*
 * Author: WaldoTheWarfighter
 * Runs one named Dynamic AA detector and activates defences only for hostile aircraft above its floor.
 *
 * Arguments:
 * 0: id <STRING> - registered system id
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * ["north_sector"] spawn Waldo_fnc_DynamicAADetectorLoop;
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
        if (isNull _radar || {!alive _radar} || {damage _radar >= _maximumRadarDamage}) exitWith {false};
        private _customOperational = [_radar, _state, _config] call _radarCondition;
        !isNull _radar
        && {_customOperational isEqualType true}
        && {_customOperational}
    };
    if (count _operationalRadars < _requiredRadars) exitWith {
        diag_log format ["[WMP DYNAMIC AA] '%1' offline: operational radars %2/%3.", _id, count _operationalRadars, _requiredRadars];
        [_id, _config getOrDefault ["cleanupOnRadarLoss", false]] spawn Waldo_fnc_DynamicAADestroy;
    };

    private _centre = _config get "centre";
    private _radius = _config get "radius";
    private _minimumAltitude = _config get "minimumAltitude";
    private _maximumAltitude = _config getOrDefault ["maximumAltitude", 1e10];
    private _mode = toUpperANSI (_config getOrDefault ["altitudeMode", "AUTO"]);
    private _aaSide = _config get "side";
    private _aircraft = nearestObjects [_centre, ["Air"], _radius, true] select {
        private _candidate = _x;
        private _position = getPosWorld _candidate;
        private _altitude = switch (_mode) do {
            case "ATL": {getPosATL _candidate select 2};
            case "ASL": {getPosASL _candidate select 2};
            default {
                if (surfaceIsWater _position) then {getPosASL _candidate select 2} else {getPosATL _candidate select 2}
            };
        };
        alive _candidate
        && {_altitude >= _minimumAltitude}
        && {_altitude <= _maximumAltitude}
        && {{alive _x && {_aaSide getFriend (side group _x) < 0.6}} count crew _candidate > 0}
    };
    private _detectionFilter = _config getOrDefault ["detectionFilter", {}];
    if (_detectionFilter isEqualType {}) then {
        _aircraft = _aircraft select {[_x, _state, _config] call _detectionFilter};
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

    if (_engaged != _wasEngaged) then {
        {
            private _defenceGroup = _x;
            [_defenceGroup, _engaged, _engagementAircraft] call Waldo_fnc_DynamicAASetGroupState;
        } forEach (_state getOrDefault ["defenceGroups", []]);
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
    if (_detected && {_rawDetected} && {(_config getOrDefault ["fighterCount", 0]) > 0} && {_wavesAvailable} && {_cooldownMet}) then {
        [_id, _aircraft] call Waldo_fnc_DynamicAASpawnFighters;
    };
    sleep ((_config getOrDefault ["detectionInterval", 1]) max 0.25);
};

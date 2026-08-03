/*
 * Author: WaldoTheWarfighter
 * Collects readable map positions and submits one server-authoritative Dynamic AA configuration.
 *
 * Arguments:
 * 0-9: centre, id, detection/engagement values, side and faction/content profile
 * 10-14: asset mode and exact radar/static/mobile/fighter classnames
 * 15-19: altitude mode and radar/static/mobile/fighter counts
 * 20-25: marker, cleanup, announcement and shutdown-interaction settings
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * Called by Waldo_fnc_DynamicAAZen after its validated dialog completes.
 *
 * Current caller: Waldo_fnc_DynamicAAZen.
 */

params ["_centre", "_id", "_radius", "_altitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_side", "_faction", "_assetMode", "_radarClass", "_staticClass", "_mobileClass", "_fighterClass", "_altitudeMode", "_radarCount", "_staticCount", "_mobileCount", "_fighterCount", "_markers", "_cleanup", "_announce", ["_shutdownInteraction", false], ["_shutdownChallenge", "circuit"], ["_shutdownDifficulty", "standard"]];
if !(hasInterface) exitWith {};

private _selectPosition = {
    params ["_message"];
    missionNamespace setVariable ["Waldo_DynamicAA_MapSelection", []];
    cutText [_message, "PLAIN DOWN", 0.2];
    openMap true;
    onMapSingleClick "missionNamespace setVariable ['Waldo_DynamicAA_MapSelection', _pos]; onMapSingleClick ''; true";
    waitUntil {uiSleep 0.05; !visibleMap || {count (missionNamespace getVariable ["Waldo_DynamicAA_MapSelection", []]) > 0}};
    onMapSingleClick "";
    missionNamespace getVariable ["Waldo_DynamicAA_MapSelection", []]
};
private _collectPositions = {
    params ["_count", "_label"];
    private _positions = [];
    for "_index" from 1 to _count do {
        private _position = [format ["Select %1 %2 of %3. Close the map to cancel.", _label, _index, _count]] call _selectPosition;
        if (_position isEqualTo []) exitWith {};
        _positions pushBack _position;
    };
    _positions
};

private _radarPositions = [_radarCount, "radar position"] call _collectPositions;
if (count _radarPositions < _radarCount) exitWith {openMap false; cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};
private _staticPositions = [_staticCount, "static AA position"] call _collectPositions;
if (count _staticPositions < _staticCount) exitWith {openMap false; cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};
private _mobilePositions = [_mobileCount, "mobile AA position"] call _collectPositions;
if (count _mobilePositions < _mobileCount) exitWith {openMap false; cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};

openMap false;
private _config = createHashMapFromArray [
    ["id", _id], ["centre", _centre], ["radarPosition", _radarPositions select 0], ["radarPositions", _radarPositions],
    ["side", _side], ["faction", _faction], ["assetSelectionMode", _assetMode],
    ["radius", _radius], ["minimumAltitude", _altitude], ["maximumAltitude", _maximumAltitude],
    ["engagementRadius", _engagementRadius], ["detectionDwell", _dwell], ["clearDelay", _clearDelay], ["altitudeMode", _altitudeMode],
    ["staticPositions", _staticPositions], ["mobilePositions", _mobilePositions], ["fighterCount", _fighterCount],
    ["createMarkers", _markers], ["cleanupOnRadarLoss", _cleanup], ["announce", _announce],
    ["shutdownInteraction", _shutdownInteraction], ["shutdownChallenge", _shutdownChallenge], ["shutdownDifficulty", _shutdownDifficulty]
];
if (_assetMode == "EXACT") then {
    _config set ["radarClass", _radarClass];
    if (_staticCount > 0) then {_config set ["staticClass", _staticClass]};
    if (_mobileCount > 0) then {_config set ["mobileClass", _mobileClass]};
    if (_fighterCount > 0) then {_config set ["fighterClass", _fighterClass]};
};
[_config] remoteExecCall ["Waldo_fnc_DynamicAACreate", 2];
["DYNAMIC AA", "System submitted to the server for validation.", "INFO", "DYNAMIC_AA_SUBMIT"] call Waldo_fnc_FeatureNotifyLocal;

/*
 * Author: Waldo
 * Collects radar and response positions on the map, then submits one Dynamic AA configuration.
 *
 * Arguments:
 * 0: centre <ARRAY>
 * 1: id <STRING>
 * 2: radius <NUMBER>
 * 3: minimumAltitude <NUMBER>
 * 4: maximumAltitude <NUMBER>
 * 5: engagementRadius <NUMBER>
 * 6: detectionDwell <NUMBER>
 * 7: clearDelay <NUMBER>
 * 8: side <SIDE>
 * 9: faction/pool key <STRING> - blank uses side pool
 * 10: altitudeMode <STRING>
 * 11: staticCount <NUMBER>
 * 12: mobileCount <NUMBER>
 * 13: fighterCount <NUMBER>
 * 14: createMarkers <BOOLEAN>
 * 15: cleanupOnRadarLoss <BOOLEAN>
 * 16: announce <BOOLEAN>
 *
 * Return Value:
 * Nothing
 */

params ["_centre", "_id", "_radius", "_altitude", "_maximumAltitude", "_engagementRadius", "_dwell", "_clearDelay", "_side", "_faction", "_altitudeMode", "_staticCount", "_mobileCount", "_fighterCount", "_markers", "_cleanup", "_announce"];
if !(hasInterface) exitWith {};

private _selectPosition = {
    params ["_message"];
    missionNamespace setVariable ["Waldo_DynamicAA_MapSelection", []];
    cutText [_message, "PLAIN DOWN", 0.2];
    openMap true;
    onMapSingleClick "missionNamespace setVariable ['Waldo_DynamicAA_MapSelection', _pos]; onMapSingleClick ''; true";
    waitUntil {
        sleep 0.05;
        !visibleMap || {count (missionNamespace getVariable ["Waldo_DynamicAA_MapSelection", []]) > 0}
    };
    onMapSingleClick "";
    missionNamespace getVariable ["Waldo_DynamicAA_MapSelection", []]
};

private _radarPosition = ["Select the central radar position. Close the map to cancel."] call _selectPosition;
if (count _radarPosition == 0) exitWith {cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};
private _staticPositions = [];
for "_index" from 1 to _staticCount do {
    private _position = [format ["Select static AA site %1 of %2. Close the map to cancel.", _index, _staticCount]] call _selectPosition;
    if (count _position == 0) exitWith {};
    _staticPositions pushBack _position;
};
if (count _staticPositions < _staticCount) exitWith {cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};

private _mobilePositions = [];
for "_index" from 1 to _mobileCount do {
    private _position = [format ["Select mobile AA position %1 of %2. Close the map to cancel.", _index, _mobileCount]] call _selectPosition;
    if (count _position == 0) exitWith {};
    _mobilePositions pushBack _position;
};
if (count _mobilePositions < _mobileCount) exitWith {cutText ["Dynamic AA placement cancelled.", "PLAIN DOWN", 0.2]};

openMap false;
cutText ["Dynamic AA system submitted.", "PLAIN DOWN", 0.2];
private _config = createHashMapFromArray [
    ["id", _id], ["centre", _centre], ["radarPosition", _radarPosition], ["side", _side],
    ["faction", _faction],
    ["radius", _radius], ["minimumAltitude", _altitude], ["maximumAltitude", _maximumAltitude],
    ["engagementRadius", _engagementRadius], ["detectionDwell", _dwell], ["clearDelay", _clearDelay], ["altitudeMode", _altitudeMode],
    ["staticPositions", _staticPositions], ["mobilePositions", _mobilePositions],
    ["fighterCount", _fighterCount], ["createMarkers", _markers],
    ["cleanupOnRadarLoss", _cleanup], ["announce", _announce]
];
[_config] remoteExecCall ["Waldo_fnc_DynamicAACreate", 2];

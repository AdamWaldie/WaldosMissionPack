/*
 * Author: WaldoTheWarfighter
 * Handheld radio direction finding (RDF). Sweeps the jammer registry for active emitters within
 * detection range and reports the nearest one to the operator: a broad compass sector and a
 * deliberately vague distance band. Lets an EW team triangulate and
 * hunt a jammer by taking bearings from different spots. Purely a read-out - it changes nothing.
 * Exposed as an ACE self-interaction ("Scan for Radio Jammers") wired up in Waldo_fnc_JammingInit.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_JammerScan;
 */

if !(hasInterface) exitWith {};

private _registry = missionNamespace getVariable ["Waldo_Jamming_Registry", []];
private _range = (missionNamespace getVariable ["Waldo_Jamming_ScanRange", 3000]) max 0;

private _bestObj = objNull;
private _bestDist = 1e11;
{
    _x params ["_id", "_obj", "_radius", "_falloff", "_sides", "_bands", "_strength", "_active"];
    if (_active && {!isNull _obj}) then {
        private _d = player distance _obj;
        if (_d <= _range && {_d < _bestDist}) then {
            _bestDist = _d;
            _bestObj = _obj;
        };
    };
} forEach _registry;

if (isNull _bestObj) exitWith {
    ["RDF SCAN", "No jamming sources detected in range.", 4, "SUCCESS"] call Waldo_fnc_JammingNotice;
};

private _trueBearing = player getDir _bestObj;
private _sectorWidth = ((missionNamespace getVariable ["Waldo_Jamming_ScanBearingArc", 30]) max 5) min 180;
private _sectorCentre = (_sectorWidth * floor ((_trueBearing + (_sectorWidth / 2)) / _sectorWidth)) % 360;
private _bearingLow = round ((_sectorCentre - (_sectorWidth / 2) + 360) % 360);
private _bearingHigh = round ((_sectorCentre + (_sectorWidth / 2)) % 360);

// Express distance only relative to receiver range. No numerical bracket is exposed,
// and signal strength is omitted because aggregate interference may come from a different emitter.
private _fractions = missionNamespace getVariable ["Waldo_Jamming_ScanDistanceFractions", [0.2, 0.55]];
private _nearFraction = ((_fractions param [0, 0.2]) max 0.05) min 0.8;
private _farFraction = ((_fractions param [1, 0.55]) max _nearFraction) min 0.95;
private _distanceText = if (_bestDist <= (_range * _nearFraction)) then {
    "NEARBY"
} else {
    if (_bestDist <= (_range * _farFraction)) then {"DISTANT"} else {"VERY DISTANT"}
};

["RDF SCAN", format ["Bearing between %1 and %2 deg | Distance: %3", _bearingLow, _bearingHigh, _distanceText], 6, "INFO"] call Waldo_fnc_JammingNotice;

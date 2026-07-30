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
private _bestCoverage = 0;
private _receiverSide = side (group player);
private _receiverPos = getPosASL player;
private _useLos = missionNamespace getVariable ["Waldo_Jamming_LOS", true];
private _now = serverTime;
{
    _x params ["_id", "_obj", "_radius", "_falloff", "_sides", "_bands", "_strength", "_active", "_marker", ["_sector", []], ["_duty", []]];
    private _inActiveField = _active && {!isNull _obj} && {_strength > 0};
    if (_inActiveField && {!(_sides isEqualType "")} && {!(_receiverSide in _sides)}) then {_inActiveField = false};
    if (_inActiveField && {_duty isEqualType []} && {count _duty == 2}) then {
        private _onTime = _duty select 0;
        private _period = _onTime + (_duty select 1);
        if (_period > 0 && {(_now % _period) >= _onTime}) then {_inActiveField = false};
    };
    if (_inActiveField && {_sector isEqualType []} && {count _sector == 2} && {(_sector select 1) < 360}) then {
        private _difference = abs ((((_obj getDir player) - (_sector select 0)) + 540) % 360 - 180);
        if (_difference > ((_sector select 1) / 2)) then {_inActiveField = false};
    };
    private _coverage = ((_radius max 0) + (_falloff max 0)) min _range;
    if (_inActiveField) then {
        private _d = player distance _obj;
        if (_d > _coverage) then {_inActiveField = false};
        if (_inActiveField && {_useLos}) then {
            private _from = getPosASL _obj;
            _from set [2, (_from select 2) + 2];
            private _to = +_receiverPos;
            private _targetAgl = ASLToAGL _to;
            if ((_targetAgl select 2) < 1.5) then {_to set [2, (_to select 2) + 1.5]};
            if (terrainIntersectASL [_from, _to]) then {_inActiveField = false};
        };
        if (_inActiveField && {_d < _bestDist}) then {
            _bestDist = _d;
            _bestObj = _obj;
            _bestCoverage = _coverage;
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

// Express distance relative to this jammer's actual active footprint, not the much larger
// receiver scan cap. No numerical bracket or signal strength is exposed.
private _fractions = missionNamespace getVariable ["Waldo_Jamming_ScanDistanceFractions", [0.2, 0.55]];
private _nearFraction = ((_fractions param [0, 0.2]) max 0.05) min 0.8;
private _farFraction = ((_fractions param [1, 0.55]) max _nearFraction) min 0.95;
private _distanceText = if (_bestDist <= (_bestCoverage * _nearFraction)) then {
    "NEARBY"
} else {
    if (_bestDist <= (_bestCoverage * _farFraction)) then {"DISTANT"} else {"VERY DISTANT"}
};

["RDF SCAN", format ["Bearing between %1 and %2 deg | Distance: %3", _bearingLow, _bearingHigh, _distanceText], 6, "INFO"] call Waldo_fnc_JammingNotice;

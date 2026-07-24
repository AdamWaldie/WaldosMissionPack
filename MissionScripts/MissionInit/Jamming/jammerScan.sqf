/*
 * Author: Waldo
 * Handheld radio direction finding (RDF). Sweeps the jammer registry for active emitters within
 * detection range and reports the nearest one to the operator: a compass bearing to the signal
 * source, a coarse range estimate and a signal-strength read. Lets an EW team triangulate and
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
private _range = missionNamespace getVariable ["Waldo_Jamming_ScanRange", 3000];

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
    systemChat "RDF: no radio jamming sources detected in range.";
    private _none = parseText "<t color='#3a9c3a' size='1.2' align='center'>RDF SCAN</t><br /><t size='0.9' align='center'>No jamming sources in range</t><br />";
    [_none, 3] spawn Waldo_fnc_TimedHint;
};

private _bearing = round (player getDir _bestObj);
private _dist = _bestDist;

// Coarse range bucket so the read-out is a direction-finder, not a GPS fix.
private _rangeTxt = "far (>2 km)";
if (_dist <= 250) then { _rangeTxt = "very close (<250 m)"; }
else {
    if (_dist <= 750) then { _rangeTxt = "close (<750 m)"; }
    else {
        if (_dist <= 2000) then { _rangeTxt = "medium (<2 km)"; };
    };
};

// Strength: how hard it is hitting the operator right now.
private _factor = [getPosASL player, side player, -1] call Waldo_fnc_JammingFactor;
private _strTxt = "weak";
if (_factor >= 0.66) then { _strTxt = "STRONG"; }
else {
    if (_factor >= 0.2) then { _strTxt = "moderate"; };
};

systemChat format ["RDF: jamming source bearing %1 deg, %2, signal %3.", _bearing, _rangeTxt, _strTxt];
private _hint = parseText format [
    "<t color='#c8102e' size='1.2' align='center'>RDF SCAN</t><br /><t size='1.0' align='center'>Bearing %1 deg</t><br /><t size='0.9' align='center'>Range: %2</t><br /><t size='0.9' align='center'>Signal: %3</t><br />",
    _bearing, _rangeTxt, _strTxt
];
[_hint, 4] spawn Waldo_fnc_TimedHint;

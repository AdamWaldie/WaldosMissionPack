/* Remove an object from a typed economy runtime registry. */
params [["_object", objNull], ["_key", ""]];
if (!isServer || {_key == ""}) exitWith {false};

private _variable = format ["WaldoEcoCore_Runtime_%1", toUpper _key];
private _objects = +(missionNamespace getVariable [_variable, []]);
private _clean = _objects select {!isNull _x && {_x != _object}};
if ((count _clean) == (count _objects)) exitWith {false};
missionNamespace setVariable [_variable, _clean, true];
missionNamespace setVariable [
    "WaldoEcoCore_RuntimeRegistryRevision",
    (missionNamespace getVariable ["WaldoEcoCore_RuntimeRegistryRevision", 0]) + 1,
    true
];
true

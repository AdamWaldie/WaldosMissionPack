/*
 * Author: WaldoTheWarfighter
 * Purpose: Resolve cargo and FFV seat centres from model proxies and vehicle config without placing units.
 * Locality / Authority: Server-only, read-only lookup on the first physical mount for a vehicle class.
 * Repeat / JIP: Class results are cached on the server. Object points stay server-local;
 *   replicated seat locks are the client-visible result.
 *   Unknown or ambiguous proxies produce no lock; an explicit SeatPoints array overrides discovery.
 * Arguments: 0: carrier vehicle <OBJECT>.
 * Return Value: <ARRAY> verified [kind, seat key, model-space point] rows, or [] if unsupported.
 * Current caller: Waldo_fnc_PhysicalCargoSeatsServer when a vehicle has no explicit seat map.
 * Example: [_truck] call Waldo_fnc_PhysicalCargoDiscoverSeatsServer;
 */
params [["_vehicle", objNull, [objNull]]];
if (!isServer || {isNull _vehicle}) exitWith {[]};
if !(isNil {_vehicle getVariable "Waldo_PhysicalCargo_SeatPoints"}) exitWith {
    _vehicle getVariable ["Waldo_PhysicalCargo_SeatPoints", []]
};
private _class = typeOf _vehicle;
private _cache = missionNamespace getVariable ["Waldo_PhysicalCargo_SeatProxyCache", createHashMap];
private _cached = _cache getOrDefault [_class, objNull];
if (_cached isEqualType []) exitWith {
    _vehicle setVariable ["Waldo_PhysicalCargo_SeatPoints", +_cached];
    +_cached
};

// FireGeometry usually exposes crew proxies. ViewGeometry is a fallback for
// models that omit them there. Neither lookup creates objects or changes seats.
private _proxies = [];
{
    private _lod = _x;
    {
        private _parts = (toLowerANSI _x) splitString "\.";
        if (count _parts >= 2 && {(_parts select (count _parts - 2)) isEqualTo "cargo"}) then {
            private _suffix = _parts select (count _parts - 1);
            if (_suffix isNotEqualTo "" && {(_suffix splitString "0123456789") isEqualTo []}) then {
                private _proxyIndex = parseNumber _suffix;
                if (_proxyIndex > 0 && {(_proxies findIf {(_x select 0) isEqualTo _proxyIndex}) < 0}) then {
                    private _point = _vehicle selectionPosition [_x, _lod];
                    if (_point isEqualTypeArray [0, 0, 0] && {vectorMagnitude _point > 0.05}) then {
                        _proxies pushBack [_proxyIndex, _point];
                    };
                };
            };
        };
    } forEach (_vehicle selectionNames _lod);
} forEach ["FireGeometry", "ViewGeometry"];

private _cfg = configFile >> "CfgVehicles" >> _class;
private _bounds = boundingBoxReal _vehicle;
_bounds params ["_minimum", "_maximum"];
private _pointForProxy = {
    params ["_proxyIndex"];
    private _row = _proxies findIf {(_x select 0) isEqualTo _proxyIndex};
    if (_row < 0) exitWith {[]};
    private _point = (_proxies select _row) select 1;
    private _within = true;
    for "_axis" from 0 to 2 do {
        if ((_point select _axis) < ((_minimum select _axis) - 1)
            || {(_point select _axis) > ((_maximum select _axis) + 1)}) exitWith {
            _within = false;
        };
    };
    if (_within) then {_point} else {[]}
};

private _rows = fullCrew [_vehicle, "", true];
private _points = [];
private _turretProxyIndexes = [];
private _turretClaims = [];
{
    _x params ["_occupant", "_role", "_cargoIndex", "_path", "_personTurret"];
    if (_personTurret && {_path isNotEqualTo []}) then {
        private _cursor = _cfg;
        private _valid = true;
        {
            private _children = "true" configClasses (_cursor >> "Turrets");
            if (_x < 0 || {_x >= count _children}) exitWith {_valid = false};
            _cursor = _children select _x;
        } forEach _path;
        if (_valid && {getNumber (_cursor >> "isPersonTurret") > 0}) then {
            private _proxyType = toLowerANSI (getText (_cursor >> "proxyType"));
            private _proxyIndex = getNumber (_cursor >> "proxyIndex");
            if (_proxyIndex > 0 && {_proxyType in ["", "cpcargo"]}) then {
                _turretProxyIndexes pushBackUnique _proxyIndex;
                _turretClaims pushBack [_proxyIndex, _path];
            };
        };
    };
} forEach _rows;
{
    _x params ["_proxyIndex", "_path"];
    // Two turret paths claiming the same proxy cannot be assigned separately.
    if (({(_x select 0) isEqualTo _proxyIndex} count _turretClaims) isEqualTo 1) then {
        private _point = [_proxyIndex] call _pointForProxy;
        if (_point isEqualTypeArray [0, 0, 0]) then {
            _points pushBack ["TURRET", _path, _point];
        };
    };
} forEach _turretClaims;

private _cargoProxyIndexes = getArray (_cfg >> "cargoProxyIndexes");
{
    _x params ["_occupant", "_role", "_cargoIndex"];
    if ((toLowerANSI _role) isEqualTo "cargo" && {_cargoIndex >= 0}) then {
        private _proxyIndex = _cargoIndex + 1;
        if !(_proxyIndex in _turretProxyIndexes) then {
            if (_cargoProxyIndexes isEqualTo [] || {_proxyIndex in _cargoProxyIndexes}) then {
                private _point = [_proxyIndex] call _pointForProxy;
                if (_point isEqualTypeArray [0, 0, 0]) then {
                    _points pushBack ["CARGO", _cargoIndex, _point];
                };
            };
        };
    };
} forEach _rows;

_cache set [_class, _points];
missionNamespace setVariable ["Waldo_PhysicalCargo_SeatProxyCache", _cache];
_vehicle setVariable ["Waldo_PhysicalCargo_SeatPoints", +_points];
diag_log format ["[WMP PHYSICAL CARGO SEATS] %1: %2 of %3 cargo/FFV seats resolved from model proxies.",
    _class, count _points, {(_x select 1) isEqualTo "cargo" || {_x select 4}} count _rows];
_points

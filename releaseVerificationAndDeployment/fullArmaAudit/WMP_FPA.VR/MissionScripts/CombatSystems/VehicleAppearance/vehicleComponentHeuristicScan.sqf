/*
 * Author: WaldoTheWarfighter
 * Best-effort, zero-setup discovery of a vehicle's likely removable/hidable physical components (a
 * remote weapon station, a turret cupola, ...) for the ZEN "Vehicle Customisation - Editor" dialog's
 * Component tab. Replaces the retired persistent registration catalog
 * (Waldo_fnc_VehicleComponentCatalogRegister) entirely: rather than a mission maker manually typing
 * a label/selection name/turret path once per vehicle CLASS before Remove/Restore Component becomes
 * useful, this re-scans the actual placed vehicle every time the Editor opens - always accurate to
 * that live vehicle, no setup step, at the cost of being a heuristic rather than a guarantee.
 *
 * There is no engine config flag marking a model selection as "this is a removable component" - this
 * is a genuine, permanent gap (same one Waldo_fnc_VehicleComponentCatalogRegister's own header always
 * documented). This function narrows selectionNames down to plausible candidates two ways:
 *  1. Name filter: keep only selections whose lowercased name contains one of a fixed substring list
 *     (see _nameHints below) - a deliberately conservative, adjustable list. Widening it later
 *     without updating this comment and the wiki/CLAUDE.md documentation of it is a documentation
 *     debt, not just a code change.
 *  2. Turret correlation (best-effort, not guaranteed): if the vehicle has exactly one real turret
 *     path (excluding the horn-only and mount-less [-1] cases Waldo_fnc_VehicleWeaponLoadoutApply
 *     already refuses to touch), every candidate selection is paired with that one path - the common
 *     single-turret-vehicle case. Otherwise, each candidate is paired with whichever real turret's own
 *     Turrets-tree config class name shares a lowercased, punctuation-stripped substring of length >=4
 *     with the selection name; a candidate with no such match is reported with an empty turret path
 *     (cosmetic-only / no confident link). This is a coarse string heuristic, not a geometric one -
 *     memory-point proximity was considered and rejected, since most hidden-selection component
 *     meshes are not declared memory points, so a proximity check would silently fail to correlate on
 *     the majority of real vehicles.
 *
 * Every candidate's label bakes in an explicit "best-effort, verify visually" caveat - never present a
 * guess as fact, the same standard this codebase's other discovery helpers already hold to
 * (Waldo_fnc_VehicleWeaponLoadoutCatalogBuild, Waldo_fnc_ResolveVehicleClassPool). A mission maker or
 * curator should still glance at the vehicle before removing/hiding a selection this function offered.
 *
 * Arguments:
 * 0: Vehicle <OBJECT>
 *
 * Return Value:
 * Array of [selectionName <STRING>, likelyTurretPath <ARRAY, [] if none>, label <STRING>] - label
 * already carries the human-readable caveat text, ready to show directly in a picker list. Empty
 * array when the vehicle is invalid or has no candidate selections.
 *
 * Current callers: MissionScripts/CombatSystems/VehicleCustomization/vehicleCustomizationCollectComponentRow.sqf
 * (via the Editor's Component tab picker population).
 *
 * Example:
 * private _candidates = [cursorObject] call Waldo_fnc_VehicleComponentHeuristicScan;
 */

params [["_vehicle", objNull, [objNull]]];
if (isNull _vehicle || {!(_vehicle isKindOf "AllVehicles")} || {_vehicle isKindOf "Man"}) exitWith {[]};

private _nameHints = ["turret", "gun", "weapon", "mount", "hatch", "rws", "cannon", "hmg", "gmg"];
private _stripPunct = {
    private _clean = "";
    {
        private _char = toLower _x;
        if (_char in "abcdefghijklmnopqrstuvwxyz0123456789") then {_clean = _clean + _char;};
    } forEach (toArray toLower _this);
    _clean
};

private _selections = selectionNames _vehicle;
private _candidates = _selections select {
    private _lower = toLower _x;
    (_nameHints findIf {_lower find _x2 >= 0}) >= 0
};
if (count _candidates == 0) exitWith {[]};

// Real turret paths only - excludes horn-only turrets and a mount-less [-1] the same way
// Waldo_fnc_VehicleWeaponLoadoutApply itself refuses to touch them, so a heuristic link never points
// at a path that can't actually be armed/cleared anyway.
private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};
private _mainSlotHasMount = count (getArray (configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "weapons")) > 0;
private _realTurrets = ([[-1]] + (allTurrets [_vehicle, true])) select {
    private _path = _x;
    private _current = _vehicle weaponsTurret _path;
    private _isHornOnly = count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []};
    private _isMountless = _path isEqualTo [-1] && {!_mainSlotHasMount};
    !_isHornOnly && {!_isMountless}
};

// Build [turretPath, configName] pairs by walking the same "Turrets" config tree allTurrets itself
// walks, so a multi-turret vehicle's real path->component-name correlation is mechanically accurate
// (not guessed) even though the NAME<->SELECTION match below is still a heuristic.
private _turretConfigNames = [];
private _walkTurrets = {
    params ["_turretsClass", "_pathSoFar"];
    {
        if (isClass _x) then {
            private _path = _pathSoFar + [_forEachIndex];
            _turretConfigNames pushBack [_path, configName _x];
            [(_x >> "Turrets"), _path] call _walkTurrets;
        };
    } forEach ("true" configClasses _turretsClass);
};
[(configFile >> "CfgVehicles" >> (typeOf _vehicle) >> "Turrets"), []] call _walkTurrets;

private _result = [];
{
    private _selectionName = _x;
    private _cleanSelection = [_selectionName] call _stripPunct;
    private _linkedPath = [];
    if (count _realTurrets == 1) then {
        _linkedPath = _realTurrets select 0;
    } else {
        private _match = _turretConfigNames findIf {
            (_x select 0) in _realTurrets && {
                private _cleanConfig = [_x select 1] call _stripPunct;
                (_cleanSelection find _cleanConfig >= 0) || {_cleanConfig find _cleanSelection >= 0 && {count _cleanConfig >= 4}}
            }
        };
        if (_match >= 0) then {_linkedPath = (_turretConfigNames select _match) select 0;};
    };
    private _label = if (count _linkedPath > 0) then {
        format ["%1 (likely linked to Turret %2, best-effort - verify) [pack heuristic]", _selectionName, _linkedPath]
    } else {
        format ["%1 (no confident turret link - cosmetic only?) [pack heuristic]", _selectionName]
    };
    _result pushBack [_selectionName, _linkedPath, _label];
} forEach _candidates;

_result

/*
 * Author: WaldoTheWarfighter
 * Zeus module handler: edits the weapon/ammo loadout of the vehicle the module was placed directly
 * on - a turret weapon (add/replace/remove/clear) or an aircraft pylon (set/clear ordnance) - via
 * Waldo_fnc_VehicleWeaponLoadoutApply. Placement anywhere but directly on a real vehicle is rejected
 * with a notice, same convention as Waldo_fnc_ZenTracker. Both the turret and pylon option lists are
 * discovered live from the actual placed vehicle (allTurrets / getPylonMagazines /
 * TransportPylonsComponent), never hand-typed, so only choices that vehicle genuinely supports are
 * ever offered - matching the fresh-per-open list pattern Waldo_fnc_ZenJammerPlace and
 * Waldo_fnc_ZenHeadlessManualHandoff already use.
 *
 * "Copy Weapon From" is the same dynamic-discovery principle applied to the classname fields
 * themselves: it lists every distinct weapon+magazine pairing already mounted somewhere on this exact
 * vehicle (excluding the horn), so a curator can pick a real, known-working pairing on the fly instead
 * of typing one from memory - "Type manually" (the default) leaves the Weapon/Magazine/Count fields as
 * the only source, unchanged from before this control existed.
 *
 * "Export To Clipboard Instead Of Applying" builds the exact same row this dialog would otherwise
 * submit to the server, wraps it as a ready-to-paste `[this, [...]] call
 * Waldo_fnc_VehicleWeaponLoadoutApply;` line, and copies it via copyToClipboard - for permanently
 * baking a Zeus-configured setup into a unit's Eden init field rather than a one-off runtime change.
 * Nothing is applied to the placed vehicle when this is checked.
 *
 * A turret whose only weapon(s) are this vehicle's horn is labelled and never the dialog's default
 * selection, and every mutating turret action against it is refused with a notice rather than allowed
 * - the horn is an ordinary CfgWeapons entry to the engine but never a combat weapon a curator means.
 *
 * Arguments:
 * 0: modulePos <ARRAY> - position the curator placed the module
 * 1: objectPos <OBJECT> - the vehicle the module was dropped on
 *
 * Return Value:
 * Nothing - the dialog forwards an authorised loadout-change request to the server.
 *
 * Example:
 * [_modulePos, _objectPos] call Waldo_fnc_ZenVehicleWeaponLoadout;
 *
 * Current caller: the ZEN "Vehicle Weapon Loadout - Configure" module registered by
 * Waldo_fnc_ZenInitModules.
 */

if !(isClass (configFile >> "CfgPatches" >> "zen_main")) exitWith {};

params ["_modulePos", "_objectPos"];

// Man (soldiers/AI) also inherits from AllVehicles in Arma 3's own CfgVehicles tree, so it must be
// explicitly excluded here too - otherwise placing this directly on a person would pass the gate and
// open a dialog for turret/pylon options that make no sense for a unit.
if (isNull _objectPos || {!(_objectPos isKindOf "AllVehicles")} || {_objectPos isKindOf "Man"}) exitWith {
    ["VEHICLE WEAPON LOADOUT", "Place this module directly on the vehicle you want to edit.", "WARNING", "VEHWPN_ZEN", 8]
        call Waldo_fnc_FeatureNotifyLocal;
};

// A vehicle's horn is an ordinary CfgWeapons entry to the engine, but never a combat weapon a
// mission maker means when they pick "this vehicle's weapon" - flagged by display name (the engine
// has no other reliable "this is not a combat weapon" marker) so it is labelled clearly and never the
// dialog's default selection, and mutating actions against a horn-only turret are refused in the
// submit callback below rather than silently doing something a beginner didn't intend.
private _isHornWeapon = {
    toLower (getText (configFile >> "CfgWeapons" >> _this >> "displayName")) == "horn"
};

// LIST values are kept as STRINGs (str-encoded, decoded back with parseSimpleArray in the callback)
// rather than raw turret-path ARRAYs - every other LIST control in this codebase uses STRING or
// OBJECT values (Zen_jammerPlaceModule.sqf, Zen_headlessManualHandoffModule.sqf), so there is no
// precedent confirming ZEN's own LIST widget round-trips an ARRAY value correctly, while
// parseSimpleArray/str round-tripping a turret path is a documented, reliable engine mechanism.
private _turretPaths = [[-1]] + (allTurrets [_objectPos, true]);
private _turretPathKeys = _turretPaths apply {str _x};
private _turretIsHornOnly = _turretPaths apply {
    private _current = _objectPos weaponsTurret _x;
    count _current > 0 && {(_current select {!(_x call _isHornWeapon)}) isEqualTo []}
};
private _turretLabels = [];
{
    private _current = _objectPos weaponsTurret _x;
    private _currentText = if (count _current > 0) then {
        (_current apply {getText (configFile >> "CfgWeapons" >> _x >> "displayName")}) joinString ", "
    } else {"empty"};
    private _hornSuffix = if (_turretIsHornOnly select _forEachIndex) then {" (horn - not editable here)"} else {""};
    _turretLabels pushBack format ["Turret %1 - %2%3", _x, _currentText, _hornSuffix];
} forEach _turretPaths;
// Default to the first non-horn turret when one exists, rather than always index 0 - turret [-1] is
// a pure horn slot on plenty of vehicles, and opening straight onto it is the single most common way
// a beginner ends up confused about why "the weapon" won't change.
private _defaultTurretIndex = _turretIsHornOnly find false;
if (_defaultTurretIndex == -1) then {_defaultTurretIndex = 0;};

// "Copy Weapon From" collects every distinct (weapon, magazine, rounds/magazine, magazine quantity)
// combination already mounted anywhere on this exact vehicle (excluding the horn) so a curator can
// pick a real, known-working pairing instead of typing a classname from memory - dynamic,
// vehicle-specific, and always accurate for this vehicle's own weapons since it reads them directly
// off the live object, the same "never type what you can read off a real vehicle" principle
// Waldo_fnc_VehicleWeaponLoadoutCopy uses across vehicles. Index 0 is always "Type manually",
// preserving the existing typed-field workflow.
private _pickupKeys = ["MANUAL"];
private _pickupLabels = ["Type manually (use the fields below)"];
{
    private _path = _x;
    if !(_turretIsHornOnly select _forEachIndex) then {
        private _weapons = _objectPos weaponsTurret _path;
        private _rawMagazines = _objectPos magazinesTurret _path;
        private _magazines = _rawMagazines arrayIntersect _rawMagazines;
        {
            private _weaponClass = _x;
            private _compatible = _magazines select {_x in (compatibleMagazines _weaponClass)};
            private _magForPickup = if (count _compatible > 0) then {_compatible select 0} else {_magazines param [0, ""]};
            private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
            // Raw (non-deduplicated) occurrence count of this exact magazine class on this turret -
            // the real number of separate magazine instances currently mounted, matching what
            // addMagazineTurret would need to be called that many times to reproduce.
            private _magQuantity = ({_x == _magForPickup} count _rawMagazines) max 1;
            private _key = str [_weaponClass, _magForPickup, _magCount, _magQuantity];
            if !(_key in _pickupKeys) then {
                _pickupKeys pushBack _key;
                _pickupLabels pushBack format ["%1 + %2x %3 (from Turret %4)", _weaponClass, _magQuantity, if (_magForPickup == "") then {"no magazine"} else {_magForPickup}, _path];
            };
        } forEach _weapons;
    };
} forEach _turretPaths;

// Pylon LIST values are also kept as STRINGs (the pylon's 1-based index, printed) for the same
// reason as the turret keys above - no confirmed precedent for a NUMBER-valued LIST either.
private _pylonCount = count (getPylonMagazines _objectPos);
private _pylonValues = ["-1"];
private _pylonLabels = ["No pylons on this vehicle"];
if (_pylonCount > 0) then {
    private _pylonClasses = (configProperties [
        configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons",
        "isClass _x"
    ]) apply {configName _x};
    private _currentPylonMags = getPylonMagazines _objectPos;
    _pylonValues = [];
    _pylonLabels = [];
    for "_i" from 0 to (_pylonCount - 1) do {
        private _pylonName = if (_i < count _pylonClasses) then {
            getText (configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> (_pylonClasses select _i) >> "displayName")
        } else {""};
        if (_pylonName == "") then {_pylonName = format ["Pylon %1", _i + 1]};
        private _current = _currentPylonMags param [_i, ""];
        _pylonValues pushBack (str (_i + 1));
        _pylonLabels pushBack format ["%1 - %2", _pylonName, if (_current == "") then {"empty"} else {_current}];
    };
};

private _targetOptions = [["Turret weapon", "Add, replace, remove, or clear a turret's weapon/ammo."]];
if (_pylonCount > 0) then {
    _targetOptions pushBack ["Aircraft pylon", "Set or clear a hardpoint's ordnance."];
};

[
    "Vehicle Weapon Loadout",
    [
        ["TOOLBOX:WIDE", ["Loadout Target", "Whether this change applies to a turret weapon or an aircraft pylon."], [0, 1, count _targetOptions, _targetOptions]],
        ["LIST", ["Turret", "Which turret to change (used when target is Turret weapon)."], [_turretPathKeys, _turretLabels, _defaultTurretIndex, 6]],
        ["TOOLBOX:WIDE", ["Turret Action", "What to do to the selected turret."], [0, 1, 4, ["Add Weapon", "Replace Turret", "Remove Weapon", "Clear Turret"]]],
        ["LIST", ["Copy Weapon From", "Pick a weapon/magazine already mounted on this vehicle instead of typing one below. Overrides the two fields below when not 'Type manually'."], [_pickupKeys, _pickupLabels, 0, 6]],
        ["EDIT", ["Weapon Classname", "Exact CfgWeapons class to add/replace/remove, e.g. arifle_MX_F. Ignored for Clear, for pylons, and when Copy Weapon From picked something."], ""],
        ["EDIT", ["Magazine Classname", "Exact CfgMagazines class. For a pylon this is the ordnance/magazine itself. Ignored when Copy Weapon From picked something."], ""],
        ["SLIDER", ["Rounds Per Magazine", "Rounds loaded into EACH magazine instance - clamped to that magazine's own full capacity, same as a real magazine. Ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something."], [1, 200, 1, 0], false],
        ["SLIDER", ["Number Of Magazines", "How many separate magazine instances to add - the turret's real reserve ammo pool. Ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something."], [1, 50, 1, 0], false],
        ["LIST", ["Pylon", "Which hardpoint to change (used when target is Aircraft pylon)."], [_pylonValues, _pylonLabels, 0, 6]],
        ["TOOLBOX:WIDE", ["Pylon Action", "Set the pylon's ordnance, or clear it empty."], [0, 1, 2, ["Set Ordnance", "Clear Pylon"]]],
        ["CHECKBOX", ["Export To Clipboard Instead Of Applying", "Copy a ready-to-paste Waldo_fnc_VehicleWeaponLoadoutApply call for a unit's Eden init field, instead of applying it to this vehicle now."], false]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_targetIndex", "_turretPathKey", "_turretActionIndex", "_pickupKey", "_weaponClass", "_magazineClass", "_magazineCount", "_magazineQuantity", "_pylonIndexKey", "_pylonActionIndex", "_exportOnly"];
        _pos params ["_vehicle"];
        if (isNull _vehicle) exitWith {
            ["VEHICLE WEAPON LOADOUT", "That vehicle no longer exists.", "WARNING", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        };
        if (_pickupKey != "MANUAL") then {
            private _pickup = parseSimpleArray _pickupKey;
            if (_pickup isEqualType [] && {count _pickup == 4}) then {
                _pickup params ["_pickupWeapon", "_pickupMag", "_pickupCount", "_pickupQuantity"];
                _weaponClass = _pickupWeapon;
                _magazineClass = _pickupMag;
                _magazineCount = _pickupCount;
                _magazineQuantity = _pickupQuantity;
            };
        };
        private _row = [];
        if (_targetIndex == 0) then {
            private _action = ["ADD", "REPLACE", "REMOVE", "CLEAR"] param [_turretActionIndex, "ADD"];
            private _turretPath = parseSimpleArray _turretPathKey;
            if !(_turretPath isEqualType []) then { _turretPath = [-1]; };
            // Re-check horn-only status live against the vehicle rather than trusting the label text
            // captured when the dialog opened - the loadout may have changed since. A horn-only turret
            // is refused for every mutating action so a beginner can never edit it by mistake; picking
            // a different turret is the only way past this notice, matching "exclude it from our
            // operations" rather than silently letting a horn turret be replaced/cleared/removed.
            private _currentWeapons = _vehicle weaponsTurret _turretPath;
            private _isHornOnly = count _currentWeapons > 0 && {(_currentWeapons select {toLower (getText (configFile >> "CfgWeapons" >> _x >> "displayName")) != "horn"}) isEqualTo []};
            if (_isHornOnly) exitWith {
                ["VEHICLE WEAPON LOADOUT", format ["Turret %1 only carries this vehicle's horn - pick a different turret to edit its weapon loadout.", _turretPath], "WARNING", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
            };
            _row = ["TURRET", _turretPath, -1, _action, _weaponClass, _magazineClass, round _magazineCount, round _magazineQuantity];
        } else {
            private _action = ["SET", "CLEAR"] param [_pylonActionIndex, "SET"];
            private _pylonIndex = parseNumber _pylonIndexKey;
            _row = ["PYLON", [-1], _pylonIndex, _action, "", _magazineClass, 0];
        };
        diag_log format ["[WMP ZEN] invoked module=Vehicle Weapon Loadout curator=%1 vehicle=%2 row=%3 exportOnly=%4", name player, typeOf _vehicle, _row, _exportOnly];
        if (_exportOnly) then {
            private _pasteText = format ["[this, [%1]] call Waldo_fnc_VehicleWeaponLoadoutApply;", str _row];
            copyToClipboard _pasteText;
            diag_log format ["[WMP VEHWPN ZEN EXPORT] %1", _pasteText];
            ["VEHICLE WEAPON LOADOUT", "Copied to clipboard - paste into the target unit's Eden init field. Nothing was applied to this vehicle.", "SUCCESS", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
        } else {
            [_vehicle, [_row], player] remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutServer", 2];
        };
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

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
 * "Copy Weapon From" / "Copy Ordnance From" apply the same dynamic-discovery principle to the
 * classname fields themselves, from two sources: weapon/magazine pairings already mounted somewhere
 * on this exact vehicle (excluding the horn), and - when Waldo_fnc_VehicleWeaponLoadoutCatalogBuild's
 * background scan has finished - a pack-wide catalog of every turret weapon/pylon ordnance discovered
 * across the entire loaded modset, not just this one vehicle. That scan is real, non-trivial work on
 * a large modset (Waldo_fnc_ZenInitModules kicks it off in the background at mission start so it is
 * normally already cached by the time a curator opens this dialog); if it genuinely has not finished
 * yet, the pack-wide section is simply omitted with a note rather than blocking the dialog. Each pick
 * list caps its pack-wide section at a fixed count (below) and truncates long labels - a LIST control
 * with thousands of full-length entries is unusably slow to scroll and was the actual bug report this
 * addresses, not just a cosmetic one; the underlying catalog itself is not truncated, only what is
 * rendered into this one dialog.
 *
 * "Session Action" turns this from "apply exactly one change" into a small builder: "Apply Now" is
 * the original one-shot behaviour; "Queue This Action" stashes the row in a client-local, per-vehicle
 * queue (Waldo_ZenVehWpn_Queue, keyed by netId) and leaves the dialog free to be reopened for another
 * action on the same vehicle; "Apply All Queued" submits the whole queue plus this row in one call
 * (Waldo_fnc_VehicleWeaponLoadoutApply already accepts multiple rows per call, so this needs no
 * backend change) and clears it; "Export Queue To Clipboard" builds one ready-to-paste multi-row
 * Eden-init-field call from the queue plus this row without applying anything or clearing the queue;
 * "Clear Queue" drops any pending rows for this vehicle. The queue is interface-client-local only -
 * nothing is queued or applied server-side until Apply/Export is actually chosen.
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
 * Nothing - the dialog applies, queues, or exports a loadout-change request per the chosen session
 * action.
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

// Shared label-length guard: a LIST control with long, fully-spelled-out entries (a weapon plus a
// magazine plus a magazine count plus a source note easily runs past 70-80 characters) visibly
// overran its control in testing. This is a deliberately conservative estimate, not a measured pixel
// width - trimmed with a trailing ellipsis rather than guessed shorter, so nothing is silently cut
// without a visible sign it was cut.
private _maxLabelChars = 64;
private _truncateLabel = {
    params ["_text"];
    if (count _text > _maxLabelChars) then {(_text select [0, _maxLabelChars]) + "…"} else {_text};
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
    _turretLabels pushBack ([format ["Turret %1 - %2%3", _x, _currentText, _hornSuffix]] call _truncateLabel);
} forEach _turretPaths;
// Default to the first non-horn turret when one exists, rather than always index 0 - turret [-1] is
// a pure horn slot on plenty of vehicles, and opening straight onto it is the single most common way
// a beginner ends up confused about why "the weapon" won't change.
private _defaultTurretIndex = _turretIsHornOnly find false;
if (_defaultTurretIndex == -1) then {_defaultTurretIndex = 0;};

// Pack-wide catalog, if the background scan (kicked off at mission start by Waldo_fnc_ZenInitModules)
// has finished. Deliberately not built synchronously here - see the file header.
private _turretCatalog = missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_TurretCatalog", []];
private _pylonCatalog = missionNamespace getVariable ["Waldo_VehicleWeaponLoadout_PylonCatalog", []];
private _catalogDisplayCap = 150;

// "Copy Weapon From" collects every distinct (weapon, magazine, rounds/magazine, magazine quantity)
// combination already mounted anywhere on this exact vehicle (excluding the horn), then extends the
// list with the pack-wide turret catalog (capped and truncated, see above) so a curator is never
// limited to only what this one vehicle already happens to carry. Index 0 is always "Type manually",
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
                _pickupLabels pushBack ([format ["%1 + %2x %3 (from Turret %4)", _weaponClass, _magQuantity, if (_magForPickup == "") then {"no magazine"} else {_magForPickup}, _path]] call _truncateLabel);
            };
        } forEach _weapons;
    };
} forEach _turretPaths;
{
    _x params ["_weaponClass", "_displayName", "_catalogMagazines"];
    private _magForPickup = _catalogMagazines param [0, ""];
    private _magCount = if (_magForPickup == "") then {1} else {getNumber (configFile >> "CfgMagazines" >> _magForPickup >> "count")};
    private _key = str [_weaponClass, _magForPickup, _magCount, 1];
    if !(_key in _pickupKeys) then {
        _pickupKeys pushBack _key;
        _pickupLabels pushBack ([format ["%1 (%2) [pack-wide]", _displayName, _weaponClass]] call _truncateLabel);
    };
} forEach (_turretCatalog select [0, _catalogDisplayCap min (count _turretCatalog)]);
if (count _turretCatalog == 0) then {
    _pickupLabels set [0, "Type manually (catalog still building - reopen shortly)"];
};

// Pylon LIST values are also kept as STRINGs (the pylon's 1-based index, printed) for the same
// reason as the turret keys above - no confirmed precedent for a NUMBER-valued LIST either.
private _pylonCount = count (getPylonMagazines _objectPos);
private _pylonValues = ["-1"];
private _pylonLabels = ["No pylons on this vehicle"];
private _currentPylonMags = [];
if (_pylonCount > 0) then {
    private _pylonClasses = (configProperties [
        configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons",
        "isClass _x"
    ]) apply {configName _x};
    _currentPylonMags = getPylonMagazines _objectPos;
    _pylonValues = [];
    _pylonLabels = [];
    for "_i" from 0 to (_pylonCount - 1) do {
        private _pylonName = if (_i < count _pylonClasses) then {
            getText (configFile >> "CfgVehicles" >> (typeOf _objectPos) >> "Components" >> "TransportPylonsComponent" >> "Pylons" >> (_pylonClasses select _i) >> "displayName")
        } else {""};
        if (_pylonName == "") then {_pylonName = format ["Pylon %1", _i + 1]};
        private _current = _currentPylonMags param [_i, ""];
        _pylonValues pushBack (str (_i + 1));
        _pylonLabels pushBack ([format ["%1 - %2", _pylonName, if (_current == "") then {"empty"} else {_current}]] call _truncateLabel);
    };
};

// "Copy Ordnance From" mirrors "Copy Weapon From" for pylons: this vehicle's own currently-mounted
// ordnance first, then the pack-wide pylon catalog (capped and truncated).
private _ordnanceKeys = ["MANUAL"];
private _ordnanceLabels = ["Type manually (use the field below)"];
{
    if (_x != "" && {!(_x in _ordnanceKeys)}) then {
        _ordnanceKeys pushBack _x;
        _ordnanceLabels pushBack ([format ["%1 (currently mounted)", _x]] call _truncateLabel);
    };
} forEach _currentPylonMags;
{
    _x params ["_magazineClass", "_displayName"];
    if !(_magazineClass in _ordnanceKeys) then {
        _ordnanceKeys pushBack _magazineClass;
        _ordnanceLabels pushBack ([format ["%1 (%2) [pack-wide]", _displayName, _magazineClass]] call _truncateLabel);
    };
} forEach (_pylonCatalog select [0, _catalogDisplayCap min (count _pylonCatalog)]);
if (count _pylonCatalog == 0 && {count _currentPylonMags == 0}) then {
    _ordnanceLabels set [0, "Type manually (pack-wide catalog still building - reopen this module shortly)"];
};

private _targetOptions = [["Turret weapon", "Add, replace, remove, or clear a turret's weapon/ammo."]];
if (_pylonCount > 0) then {
    _targetOptions pushBack ["Aircraft pylon", "Set or clear a hardpoint's ordnance."];
};

private _sessionActions = ["Apply Now", "Queue This Action", "Apply All Queued", "Export Queue To Clipboard", "Clear Queue"];

[
    "Vehicle Weapon Loadout",
    [
        ["TOOLBOX:WIDE", ["Loadout Target", "Whether this change applies to a turret weapon or an aircraft pylon."], [0, 1, count _targetOptions, _targetOptions]],
        ["LIST", ["Turret", "Which turret to change (used when target is Turret weapon)."], [_turretPathKeys, _turretLabels, _defaultTurretIndex, 6]],
        ["TOOLBOX:WIDE", ["Turret Action", "What to do to the selected turret."], [0, 1, 4, ["Add Weapon", "Replace Turret", "Remove Weapon", "Clear Turret"]]],
        ["LIST", ["Copy Weapon From", "Pick a weapon/magazine already mounted on this vehicle, or from the pack-wide catalog, instead of typing one below. Overrides the two fields below when not 'Type manually'."], [_pickupKeys, _pickupLabels, 0, 6]],
        ["EDIT", ["Weapon Classname", "Exact CfgWeapons class to add/replace/remove, e.g. arifle_MX_F. Ignored for Clear, for pylons, and when Copy Weapon From picked something."], ""],
        ["EDIT", ["Magazine Classname", "Exact CfgMagazines class. For a pylon this is the ordnance/magazine itself. Ignored when Copy Weapon From/Copy Ordnance From picked something."], ""],
        ["SLIDER", ["Rounds Per Magazine", "Rounds loaded into EACH magazine instance - clamped to that magazine's own full capacity, same as a real magazine. Ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something."], [1, 200, 1, 0], false],
        ["SLIDER", ["Number Of Magazines", "How many separate magazine instances to add - the turret's real reserve ammo pool. Ignored for pylons, for Remove/Clear, and when Copy Weapon From picked something."], [1, 50, 1, 0], false],
        ["LIST", ["Pylon", "Which hardpoint to change (used when target is Aircraft pylon)."], [_pylonValues, _pylonLabels, 0, 6]],
        ["LIST", ["Copy Ordnance From", "Pick ordnance already on this vehicle, or from the pack-wide catalog, instead of typing the Magazine Classname field above. Only used for pylons."], [_ordnanceKeys, _ordnanceLabels, 0, 6]],
        ["TOOLBOX:WIDE", ["Pylon Action", "Set the pylon's ordnance, or clear it empty."], [0, 1, 2, ["Set Ordnance", "Clear Pylon"]]],
        ["LIST", ["Session Action", "Apply this one change now (default), stash it to add more before applying together, apply everything queued for this vehicle plus this row, export the queue plus this row as a ready-to-paste init-field call, or clear the queue."], [_sessionActions, _sessionActions, 0, 6]]
    ],
    {
        params ["_args", "_pos"];
        _args params ["_targetIndex", "_turretPathKey", "_turretActionIndex", "_pickupKey", "_weaponClass", "_magazineClass", "_magazineCount", "_magazineQuantity", "_pylonIndexKey", "_ordnanceKey", "_pylonActionIndex", "_sessionAction"];
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
        if (_ordnanceKey != "MANUAL") then {
            _magazineClass = _ordnanceKey;
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
        if (_row isEqualTo []) exitWith {};

        private _netId = str (netId _vehicle);
        private _queues = missionNamespace getVariable ["Waldo_ZenVehWpn_Queue", createHashMap];
        private _queue = _queues getOrDefault [_netId, []];

        diag_log format ["[WMP ZEN] invoked module=Vehicle Weapon Loadout curator=%1 vehicle=%2 row=%3 sessionAction=%4 queueDepth=%5", name player, typeOf _vehicle, _row, _sessionAction, count _queue];

        switch (_sessionAction) do {
            case "Queue This Action": {
                _queue pushBack _row;
                _queues set [_netId, _queue];
                missionNamespace setVariable ["Waldo_ZenVehWpn_Queue", _queues];
                ["VEHICLE WEAPON LOADOUT", format ["Row queued (%1 action(s) now pending for this vehicle). Reopen this module to add another, or choose Apply All Queued / Export Queue To Clipboard.", count _queue], "INFO", "VEHWPN_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
            };
            case "Apply All Queued": {
                private _allRows = _queue + [_row];
                _queues set [_netId, []];
                missionNamespace setVariable ["Waldo_ZenVehWpn_Queue", _queues];
                [_vehicle, _allRows, player] remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutServer", 2];
            };
            case "Export Queue To Clipboard": {
                private _allRows = _queue + [_row];
                private _rowLines = _allRows apply {format ["    %1", str _x]};
                private _pasteText = format ["[this, [%1%2%3]] call Waldo_fnc_VehicleWeaponLoadoutApply;", endl, _rowLines joinString ("," + endl), endl];
                copyToClipboard _pasteText;
                diag_log format ["[WMP VEHWPN ZEN EXPORT] %1", _pasteText];
                ["VEHICLE WEAPON LOADOUT", format ["Copied %1 row(s) to clipboard - paste into the target unit's Eden init field. Nothing was applied and the queue was kept.", count _allRows], "SUCCESS", "VEHWPN_ZEN", 8] call Waldo_fnc_FeatureNotifyLocal;
            };
            case "Clear Queue": {
                _queues set [_netId, []];
                missionNamespace setVariable ["Waldo_ZenVehWpn_Queue", _queues];
                ["VEHICLE WEAPON LOADOUT", "Queue cleared for this vehicle. This dialog's own current row was not applied.", "INFO", "VEHWPN_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal;
            };
            default {
                [_vehicle, [_row], player] remoteExecCall ["Waldo_fnc_ZenVehicleWeaponLoadoutServer", 2];
            };
        };
    },
    {},
    [_objectPos]
] call zen_dialog_fnc_create;

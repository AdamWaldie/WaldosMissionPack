/*
 * Author: WaldoTheWarfighter
 * Assembles one coherent, weapon-aware setUnitLoadout-shaped array from a flattened side pool
 * (Waldo_fnc_GetSideLoadoutArray / Waldo_fnc_MissionSQMLookup's 8-category output). Per-unit pairing
 * is lost during that scan - the pool is a deduplicated side-wide classname pool, not one placed
 * unit's own coherent kit - so this picks a random weapon per slot and filters magazines/attachments
 * to ones actually compatible with that weapon (via CfgWeapons config), rather than assuming any two
 * pool entries belong together. A weapon slot with no compatible magazine anywhere in the pool is
 * skipped entirely rather than left equipped-but-unloadable.
 *
 * KNOWN LIMITATION (documented, not a bug): singular equipment slots (map/compass/gps/watch/goggles/
 * hmd) cannot be reliably reconstructed - the source scan already merges those into one flat "items"
 * category with ordinary cargo items, so which classname was originally which slot is unrecoverable
 * here. Every entry in that category is instead distributed into uniform/vest cargo, so the item is
 * still usable equipment even though it will not appear pre-equipped in its dedicated UI slot.
 *
 * Arguments:
 * 0: side pool <ARRAY> - the exact 8-category shape Waldo_fnc_GetSideLoadoutArray returns.
 *
 * Return Value:
 * ARRAY - a setUnitLoadout-shaped loadout, or [] if the pool has no usable primary/handgun weapon and
 * no usable worn gear (nothing coherent could be assembled).
 *
 * Example:
 * private _loadout = [["West"] call Waldo_fnc_MissionSQMLookup] call Waldo_fnc_BuildAssembledSideLoadout;
 *
 * Current callers: Waldo_fnc_RespawnSeedSideBaseLoadout.
 */
params [["_pool", [], [[]]]];
if (count _pool < 8) exitWith {[]};

private _fnClean = {if ((_this select 0) isEqualTo ["EMPTY"]) then {[]} else {_this select 0}};
private _weaponsGear = [_pool select 0] call _fnClean;
private _magazines = [_pool select 1] call _fnClean;
private _launchers = [_pool select 2] call _fnClean;
private _launcherAmmo = [_pool select 3] call _fnClean;
private _wornGear = [_pool select 4] call _fnClean;
private _items = [_pool select 5] call _fnClean;
private _backpacks = [_pool select 6] call _fnClean;
private _attachmentsPool = [_pool select 7] call _fnClean;

// Bucket the merged weapon/gear pools by real CfgWeapons/CfgVehicles type via BIS_fnc_itemType - the
// vanilla, config-driven classifier for exactly this purpose - rather than guessing from the name.
private _primaryCandidates = [];
private _handgunCandidates = [];
private _binocularCandidates = [];
{
    private _classification = [_x] call BIS_fnc_itemType;
    _classification params [["_type", ""], ["_subType", ""]];
    switch (true) do {
        case (_subType == "Handgun"): {_handgunCandidates pushBack _x};
        case (_subType in ["Binocular", "Rangefinder"]): {_binocularCandidates pushBack _x};
        case (_type == "Weapon"): {_primaryCandidates pushBack _x};
        default {};
    };
} forEach _weaponsGear;

private _uniformCandidates = [];
private _vestCandidates = [];
private _headgearCandidates = [];
{
    private _classification = [_x] call BIS_fnc_itemType;
    _classification params [["_type", ""], ["_subType", ""]];
    switch (_subType) do {
        case "Uniform": {_uniformCandidates pushBack _x};
        case "Vest": {_vestCandidates pushBack _x};
        case "Headgear": {_headgearCandidates pushBack _x};
        default {};
    };
} forEach _wornGear;

// Returns [weaponClass, [compatibleMagsFromPool]] or ["", []] if no compatible magazine exists in
// the pool for any candidate weapon - a weapon nobody can reload is worse than no weapon at all.
private _fnPickWeaponWithMags = {
    params ["_candidates", "_magPool"];
    private _result = ["", []];
    private _shuffled = _candidates call BIS_fnc_arrayShuffle;
    {
        private _configMags = getArray (configFile >> "CfgWeapons" >> _x >> "magazines");
        private _configMagsLower = _configMags apply {toLower _x};
        private _compatible = _magPool select {toLower _x in _configMagsLower};
        if (count _compatible > 0) exitWith {_result = [_x, _compatible]};
    } forEach _shuffled;
    _result
};

private _primaryPick = [_primaryCandidates, _magazines] call _fnPickWeaponWithMags;
private _handgunPick = [_handgunCandidates, _magazines] call _fnPickWeaponWithMags;
private _launcherPick = [_launchers, _launcherAmmo] call _fnPickWeaponWithMags;
private _binocularPick = if (count _binocularCandidates > 0) then {[selectRandom _binocularCandidates, []]} else {["", []]};

if ((_primaryPick select 0) == "" && {(_handgunPick select 0) == ""} && {count _uniformCandidates == 0} && {count _vestCandidates == 0}) exitWith {
    diag_log "[WMP LOADOUT][SIDE_BASE_LOADOUT] No usable primary/handgun weapon (with a compatible magazine) or worn gear found in the side pool; assembly aborted.";
    []
};

// Best-effort attachment matching against the picked weapon's real config-declared compatible items
// per slot. Any slot with no match in the pool is left empty rather than guessed.
private _fnPickAttachments = {
    params ["_weaponClass", "_attachmentPool"];
    if (_weaponClass == "") exitWith {["", "", "", ""]};
    private _slots = ["MuzzleSlot", "PointerSlot", "CowsSlot", "UnderBarrelSlot"];
    private _picked = ["", "", "", ""];
    {
        private _slotConfig = configFile >> "CfgWeapons" >> _weaponClass >> "WeaponSlotsInfo" >> _x;
        if (isClass _slotConfig) then {
            private _compatibleLower = (getArray (_slotConfig >> "compatibleItems")) apply {toLower _x};
            private _match = _attachmentPool select {toLower _x in _compatibleLower};
            if (count _match > 0) then {_picked set [_forEachIndex, selectRandom _match]};
        };
    } forEach _slots;
    _picked
};

private _primaryAttachments = [_primaryPick select 0, _attachmentsPool] call _fnPickAttachments;
private _handgunAttachments = [_handgunPick select 0, _attachmentsPool] call _fnPickAttachments;

// Ungrouped items (map/compass/gps/watch/goggles/hmd merged with ordinary cargo items - see header)
// are split alternately into uniform/vest cargo so they remain real, usable equipment.
private _uniformCargo = [];
private _vestCargo = [];
{
    if (_forEachIndex % 2 == 0) then {_uniformCargo pushBack [_x, 1]} else {_vestCargo pushBack [_x, 1]};
} forEach _items;

private _pickedUniform = if (count _uniformCandidates > 0) then {selectRandom _uniformCandidates} else {""};
private _pickedVest = if (count _vestCandidates > 0) then {selectRandom _vestCandidates} else {""};
private _pickedBackpack = if (count _backpacks > 0) then {selectRandom _backpacks} else {""};
private _pickedHeadgear = if (count _headgearCandidates > 0) then {selectRandom _headgearCandidates} else {""};

[
    [_primaryPick select 0, _primaryPick select 1, _primaryAttachments],
    [_launcherPick select 0, _launcherPick select 1, ["", "", "", ""]],
    [_handgunPick select 0, _handgunPick select 1, _handgunAttachments],
    [_pickedUniform, _uniformCargo],
    [_pickedVest, _vestCargo],
    [_pickedBackpack, []],
    _pickedHeadgear,
    "",
    "",
    _binocularPick select 0,
    ["", "", "", "", ""],
    []
]

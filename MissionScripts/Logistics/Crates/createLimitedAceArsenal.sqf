/*
 * Author: WaldoTheWarfighter
 * Creates an ACE arsenal limited to equipment found in the mission's side-specific loadout pool.
 * Locality and authority: Scheduled helper called by the server's starter-crate setup after
 * mission scanning is ready. It waits for both readiness flags, then updates the target arsenal.
 * Repeat/JIP: Calling again adds the same pool to an existing arsenal or reinitialises the box;
 * ACE owns arsenal state for later joiners. Do not call once per client from an unguarded init.
 * Arguments: 0: target arsenal object <OBJECT>; 1: supply side <SIDE> (west);
 *   2: arsenal already exists <BOOL> (false).
 * Return Value: No supported value; spawn this scheduled helper for its arsenal side effect.
 * Current caller: Waldo_fnc_DoStarterCrate after the mission loadout scan.
 * Example: [this, west, false] spawn Waldo_fnc_CreateLimitedArsenal;
 * Result: The object offers only the equipment derived for the west-side mission pool.
 */
params["_target",["_crateSupplySide",west],["_preExisting",false]];

//Wait Until Init is completed & players ingame (Postinit hack)
waitUntil { missionNamespace getVariable ["WALDO_INIT_COMPLETE", false] };
//Double Security with ensuring mission.sqm sweep
waitUntil { missionNamespace getVariable ["Logi_MissionScanComplete", false] };

//Get the loadout pool for the requested side (defaults to west)
private _aceArsenalPool = [_crateSupplySide] call Waldo_fnc_GetSideLoadoutArray;

// Remove empty category sentinels before flattening the remaining equipment pool.
// Iterating the category values as though they were numeric indices made this path
// dependent on invalid `select` operands and could leave the box uninitialised.
_aceArsenalPool = _aceArsenalPool select {!(_x isEqualTo ["EMPTY"])};

_aceArsenalPool = [_aceArsenalPool] call Waldo_fnc_UniqueLoadoutArray;

// if pre-existing Ace Arsenal (user specified) add items to it, else add entirely new arsenal
if (_preExisting == true) then {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_addVirtualItems;
} else {
    [_target, _aceArsenalPool] call ace_arsenal_fnc_initBox;
};

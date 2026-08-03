/*
 * Author: WaldoTheWarfighter
 * Returns inventory-carried ACRE unique radio IDs in ACRE's own canonical order. ACRE's public
 * current-radio list can also contain racks and externally shared radios, so the result is filtered
 * against uniform, vest, backpack and assigned-item cargo. setupRadios uses the same underlying order
 * to define the first and second radio of one type, so WMP must not independently sort unique IDs.
 * ACRE creates new unique IDs after a filtered loadout restore; same-type occurrence is therefore the
 * persistent identity, not the transient ID.
 *
 * Arguments: None. The ACRE carried-radio API is local-player scoped.
 *
 * Return Value: ARRAY - ordered unique radio ID strings.
 *
 * Example: private _radios = [] call Waldo_fnc_ACRE2GetOrderedRadios;
 * Current callers: plan application and radio-state capture/restoration.
 */
if (!hasInterface || {isNull player} || {!(isClass (configFile >> "CfgPatches" >> "acre_main"))}) exitWith {[]};
private _inventory = [];
{
    if !(isNull _x) then {_inventory append ((getItemCargo _x) select 0)};
} forEach [uniformContainer player, vestContainer player, backpackContainer player];
_inventory append assignedItems player;
_inventory = _inventory apply {toLower _x};
([] call acre_api_fnc_getCurrentRadioList) select {toLower _x in _inventory}

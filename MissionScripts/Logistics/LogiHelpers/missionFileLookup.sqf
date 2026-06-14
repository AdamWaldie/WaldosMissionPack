/*
 * Author: Waldo
 * Scrapes mission.sqm for every playable unit on the chosen side and returns a
 * de-duplicated pool of their equipment, used to populate supply crates and the
 * limited ACE arsenals. Mission binarization must be disabled for the SQM to be readable.
 *
 * Arguments:
 * 0: Side <STRING> (Optional, default: "West") - "West" / "East" / "Independent" / "Civilian"
 *
 * Return Value:
 * Loadout pool <ARRAY> - 8 sub-arrays, each either classnames or ["EMPTY"]:
 *   0: Main weapons (primary, handgun, binoculars)
 *   1: Magazines (launcher ammo removed)
 *   2: Launchers
 *   3: Launcher ammo
 *   4: Worn gear (uniform, vest, headgear)
 *   5: Items (map/compass/radio/gps/goggles/hmd + uniform/vest/backpack cargo items)
 *   6: Backpacks
 *   7: Weapon attachments (optics, muzzle, flashlight, underbarrel)
 *
 * Example:
 * private _westPool = ["West"] call Waldo_fnc_MissionSQMLookup;
 */

params [["_sideChosen", "West"]];

// Output category accumulators (indices match the Return Value block above)
private _PweapAndSdArm   = [];  // 0 primary + handgun + binoculars
private _NormalMagazines = [];  // 1 magazines (launcher ammo removed at the end)
private _PLauncher       = [];  // 2 launchers
private _launchMagazines = [];  // 3 launcher ammo
private _playerGear      = [];  // 4 uniform / vest / headgear
private _inventoryItems  = [];  // 5 misc items + container cargo items
private _PBackpacks       = []; // 6 backpacks
private _attachments     = [];  // 7 weapon attachments

// Single-value inventory slots: [ path under <Inventory>, accumulator to push the classname into ].
// Arrays are references in SQF, so pushing through the captured accumulator fills the real array.
private _simpleSlots = [
    [["primaryWeapon", "name"], _PweapAndSdArm],
    [["handgun", "name"], _PweapAndSdArm],
    [["binocular", "name"], _PweapAndSdArm],
    [["secondaryWeapon", "name"], _PLauncher],
    [["primaryWeapon", "primaryMuzzleMag", "name"], _NormalMagazines],
    [["handgun", "primaryMuzzleMag", "name"], _NormalMagazines],
    [["secondaryWeapon", "primaryMuzzleMag", "name"], _launchMagazines],
    [["uniform", "typeName"], _playerGear],
    [["vest", "typeName"], _playerGear],
    [["backpack", "typeName"], _PBackpacks],
    [["headgear"], _playerGear],
    [["map"], _inventoryItems],
    [["compass"], _inventoryItems],
    [["radio"], _inventoryItems],   // TFAR radio slot (ACRE2 is unaffected by this read)
    [["gps"], _inventoryItems],
    [["goggles"], _inventoryItems],
    [["hmd"], _inventoryItems]
];

// Weapons that carry attachments, and the attachment slots read from each.
// (handgun has no underBarrel in the SQM; that read returns "" and is dropped by the cleanup.)
private _attachmentWeapons = ["primaryWeapon", "handgun", "secondaryWeapon"];
private _attachmentSlots   = ["optics", "muzzle", "flashlight", "underBarrel"];

// Containers whose MagazineCargo / ItemCargo children are harvested.
private _cargoContainers = ["uniform", "vest", "backpack"];

// Walk Entities (groups) -> Entities (units) two levels deep.
{
    private _firstItem = configName _x;
    {
        private _secondItem = configName _x;
        private _entity = missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities" >> _secondItem;
        private _attr   = _entity >> "Attributes";
        private _inv    = _attr >> "Inventory";

        private _isPlayer   = getNumber (_attr >> "isPlayer");
        private _isPlayable = getNumber (_attr >> "isPlayable");
        private _unitSide   = getText (_entity >> "side");

        if (_unitSide == _sideChosen && {_isPlayer == 1 || _isPlayable == 1}) then {
            // Flat single-value slots
            {
                _x params ["_path", "_target"];
                private _cfg = _inv;
                { _cfg = _cfg >> _x } forEach _path;
                _target pushBack (getText _cfg);
            } forEach _simpleSlots;

            // Weapon attachments
            {
                private _weaponSlot = _x;
                {
                    _attachments pushBack (getText (_inv >> _weaponSlot >> _x));
                } forEach _attachmentSlots;
            } forEach _attachmentWeapons;

            // Magazines and items stored inside the worn containers
            {
                private _container = _x;
                {
                    _NormalMagazines pushBack (getText (_inv >> _container >> "MagazineCargo" >> (configName _x) >> "name"));
                } forEach (configProperties [(_inv >> _container >> "MagazineCargo"), "isClass _x", true]);
                {
                    _inventoryItems pushBack (getText (_inv >> _container >> "ItemCargo" >> (configName _x) >> "name"));
                } forEach (configProperties [(_inv >> _container >> "ItemCargo"), "isClass _x", true]);
            } forEach _cargoContainers;
        };
    } forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities" >> _firstItem >> "Entities"), "isClass _x", true]);
} forEach (configProperties [(missionConfigFile >> "MissionSQM" >> "Mission" >> "Entities"), "isClass _x", true]);

// Assemble in the fixed output order, then flatten + de-duplicate each category.
private _masterArray = [_PweapAndSdArm, _NormalMagazines, _PLauncher, _launchMagazines, _playerGear, _inventoryItems, _PBackpacks, _attachments];
{
    _masterArray set [_forEachIndex, [_x] call Waldo_fnc_UniqueLoadoutArray];
} forEach _masterArray;

// Some mods register launcher ammo as normal magazines; remove the overlap so it is not doubled up.
_masterArray set [1, (_masterArray select 1) - (_masterArray select 3)];

// Mark any empty category with the EMPTY sentinel the crate / arsenal scripts expect.
{
    if (count _x == 0) then { _masterArray set [_forEachIndex, ["EMPTY"]]; };
} forEach _masterArray;

_masterArray

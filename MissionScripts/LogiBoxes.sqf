/*//    INFO TEXT    //// ==========================================================================================

This is called directly from the addactions applied to the quartermaster (see initQuartermaster.sqf).
It provides a means to automatically get & spawn ammo crates with correct Ammo, medical and ACE tracks/tyres.

You should not call this directly.
*/


params["","","","_parameterArray"];
_boxType = _parameterArray select 0;
_object = _parameterArray select 1;
_customAmmoBox = _parameterArray select 2;
systemchat str _boxType;
systemchat str _object;
systemchat str _customAmmoBox;
_position = getPos _object;
_medPos = [(_position select 0) -0.5, (_position select 1) -0.5, 0];
_ammoPos = [(_position select 0) +0.5, (_position select 1) +0.5, 0];
_otherPosLow = [(_position select 0) +1.5, (_position select 1) +1.5, 0];
_otherPos = [(_position select 0), (_position select 1), 1];
_allowedBoxes = ['ACE_medicalSupplyCrate_advanced', _customAmmoBox,'ACE_Wheel','ACE_Track'];
_radius = 20;
_exists = {typeof _x == _boxType} count (nearestObjects [_position, _allowedBoxes, _radius, false]) > 0;

if (_exists) exitWith {
    _quote = selectRandom [
        "You've got one right there!",
        "I just gave you one of those.",
        "Deploy that one first, then we'll talk about more",
        "You joking? Use that one first.",
        "They're not free you know!"
        ];
    ["Quartermaster", _quote] spawn BIS_fnc_showSubtitle;
};

_box = _boxType createVehicle _position;
clearItemCargoGlobal _box;
clearBackpackCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearWeaponCargoGlobal _box;

if (_boxType == _allowedBoxes select 0) then {
    _box setPos _medPos;
    _boxInventory = [["ACE_SpareBarrel","ACE_fieldDressing","ACE_packingBandage","ACE_elasticBandage","ACE_tourniquet","ACE_splint","ACE_morphine","ACE_adenosine","ACE_epinephrine","ACE_plasmaIV","ACE_plasmaIV_500","ACE_plasmaIV_250","ACE_salineIV","ACE_salineIV_500","ACE_salineIV_250","ACE_bloodIV","ACE_bloodIV_500","ACE_bloodIV_250","ACE_quikclot","ACE_personalAidKit","ACE_surgicalKit","ACE_bodyBag"],[1,25,25,50,15,15,15,15,15,7,7,7,7,7,7,7,7,7,20,3,2,5]];
    [_box, true, [0, 2, 1], 0, true] call ace_dragging_fnc_setCarryable;
    _quote = selectRandom [
        "Medical Box? Check. Here it is.",
        "Med Supplies, eh? Keep our boys alive out there!",
        "God, you're going through a lot of these, aren't you?",
        "Erm.. yeah. We have that in stock. Here.",
        "One Medical Crate, check.",
        "That one's on the house.",
        "You got your crate licence there mate?",
        "Come back if you need more, they haven't set up the limits yet!"
    ];
    ["Quartermaster", _quote] spawn BIS_fnc_showSubtitle;
    for '_i' from 1 to count (_boxInventory select 0) do {
        _box addItemCargoGlobal [_boxInventory select 0 select _i, _boxInventory select 1 select _i]
    };
};
if (_boxType == _allowedBoxes select 1) then {
    _box setPos _ammoPos;
    Private _CountablePlayers = allPlayers;
    private _ammoboxitems = [];
    {
        _ammoboxitems append magazines _x; 
    } forEach _CountablePlayers;
    _ammoboxitems = str _ammoboxitems splitString "[]," joinString ",";
    _ammoboxitems = parseSimpleArray ("[" + _ammoboxitems + "]");
    _ammoboxitems = _ammoboxitems arrayIntersect _ammoboxitems select {_x isEqualType "" && {_x != ""}};
    private _arrayLength = count _ammoboxitems; 
    private _ammoCountArray = [];
    {
        _randomInt = [20,50] call BIS_fnc_randomInt;
        _ammoCountArray append [_randomInt];
    } forEach _ammoboxitems;
    _boxInventory = [_ammoboxitems,_ammoCountArray];
    systemchat str _ammoboxitems;
    systemchat str _ammoCountArray;
    [_box, true, [0, 2, 1], 0, true] call ace_dragging_fnc_setCarryable;
    _quote = selectRandom [
        "One canister, ready to go.",
        "...48...49...50. Yep, it's all there.",
        "God, you're going through a lot of these, aren't you?",
        "Erm.. yeah. We have that in stock. Here.",
        "One Ammo Crate, check.",
        "That one's on the house.",
        "You got your crate licence there mate?",
        "Come back if you need more, they haven't set up the limits yet!",
        "Don't spend them all in one place!"
    ];
    ["Quartermaster", _quote] spawn BIS_fnc_showSubtitle;
    for '_i' from 1 to count (_boxInventory select 0) do {
        _box addMagazineCargoGlobal [_boxInventory select 0 select _i, _boxInventory select 1 select _i]
    };
};
if (_boxType == _allowedBoxes select 2 || _boxType == _allowedBoxes select 3) then {
    _box setPos _otherPosLow;
    _quote = selectRandom [
        "Had a breakdown out there, eh?",
        "Squeaky wheel gets the grease?",
        "One wheel, ready to go.",
        "Here y'are.",
        "Be more damn careful next time.",
        "Get the lads moving again out there."
    ];
    ["Quartermaster", _quote] spawn BIS_fnc_showSubtitle;
}
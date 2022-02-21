/*//    INFO TEXT    //// ==========================================================================================

This is called directly from the addactions applied to the quartermaster (see initQuartermaster.sqf).
It provides a means to automatically get & spawn ammo crates with correct Ammo, medical and ACE tracks/tyres.

You should not call this directly.
*/


params["","","","_parameterArray"];
_boxType = _parameterArray select 0;
_object = _parameterArray select 1;
_customAmmoBox = _parameterArray select 2;
_position = getPos _object;
_medPos = [(_position select 0) -0.5, (_position select 1) -0.5, 0];
_ammoPos = [(_position select 0) +0.5, (_position select 1) +0.5, 0];
_otherPosLow = [(_position select 0) +1.5, (_position select 1) +1.5, 0];
_otherPos = [(_position select 0), (_position select 1), 1];
_allowedBoxes = ['Box_NATO_Support_F','ACE_medicalSupplyCrate_advanced', _customAmmoBox,'ACE_Wheel','ACE_Track'];
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

// Non-Ace Enabled Medical box
if (_boxType == _allowedBoxes select 0) then {
    _box setPos _medPos;
    //Box as Medical Field Hospital with scalar of 1 (Note that it will not be treated as ACE box if ACE disabled
    [_box, 0, 1] call Waldo_fnc_MedicalCratePopulate;
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
    for '_i' from 0 to count (_boxInventory select 0) do {
        _box addItemCargoGlobal [_boxInventory select 0 select _i, _boxInventory select 1 select _i]
    };
};

//ACE Enabled Medical Box
if (_boxType == _allowedBoxes select 1) then {
    _box setPos _medPos;
    //Box as Medical Field Hospital with scalar of 1
    [_box, 1, 1] call Waldo_fnc_MedicalCratePopulate;
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
};

//Automated Resupply Box
if (_boxType == _allowedBoxes select 2) then {
    _box setPos _ammoPos;
    //Call supplybox population script with box and random scalar between 1 & 2
    [_box, [1,2] BIS_fnc_randomInt] call Waldo_fnc_SupplyCratePopulate;
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
};

    if (_boxType == _allowedBoxes select 3 || _boxType == _allowedBoxes select 4) then {
    _box setPos _otherPosLow;
    _quote = selectRandom [
        "Had a breakdown out there, eh?",
        "One spare part, ready to go.",
        "Here y'are.",
        "Be more damn careful next time.",
        "Get the lads moving again out there."
    ];
    ["Quartermaster", _quote] spawn BIS_fnc_showSubtitle;
};
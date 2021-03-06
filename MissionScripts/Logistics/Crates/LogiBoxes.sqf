/*/
This is called directly from the addactions applied to the quartermaster (see initQuartermaster.sqf).
It provides a means to automatically get & spawn ammo crates with correct Ammo, medical and ACE tracks/tyres.

You should not call this directly.

This expects a call from addaction format, so parameters are in the argument array of an addaction, hence the ignored params marked with "".

Params:
_BoxType - Selection of box | Potential Arguments: "Medical","Supply","Wheel","Track"
_Object - object upon which the spawn position is 
_side - the side you want the quartermaster to deploy supplies from. Options: West,East,Independent,Civilian
_customQMBox - a custom box classnam specific to this quartermaster (General changes should be made in initServer.sqf
*/


params["","","","_parameterArray"];
_parameterArray params["_boxType", "_object",["_side",west], ["_customQMBox",""], ["_aceMedicalCrate",false]];

// Get MMT defined box classes & if undefined attempt to get missionParameters.sqf definition, failing that, assign default
//First check if custom box selected, if untrue get mission space defined box for this class, if non-existant, select debug box type of class, if all of that fails, the world is ending and the debug above is selected
_supplyBoxClass = missionNamespace getVariable "Logi_SupplyBoxClass";
_medicalBoxClass = missionNamespace getVariable "Logi_MedicalBoxClass";
_boxToSpawn = "B_CargoNet_01_ammo_F";
if (_customQMBox != "") then {
    if (_boxType == "Medical") then {
        _boxToSpawn = _customQMBox;
    };
    if (_boxType == "Supply" || _boxType == "Ammo") then {
        _boxToSpawn = _customQMBox;       
    };
} else {
    if (isNil "_supplyBoxClass" && isNil "_medicalBoxClass") then
    {
        
        if (_boxType == "Medical") then {
            if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
            _boxToSpawn = "ACE_medicalSupplyCrate_advanced";
            } else {
                _boxToSpawn = "C_IDAP_supplyCrate_F";
            };
        };
        if (_boxType == "Supply" || _boxType == "Ammo") then {
            _boxToSpawn = "Box_NATO_Support_F";       
        };
    } else {
        if (_boxType == "Medical") then {
            _boxToSpawn = Logi_MedicalBoxClass;
        };
        if (_boxType == "Supply" || _boxType == "Ammo") then {
            _boxToSpawn = _supplyBoxClass;       
        };
    };
};
// Get Track & Wheel
if (_boxType == "Wheel") then {
    _boxToSpawn = "ACE_Wheel";
};
if (_boxType == "Track") then {
    _boxToSpawn = "ACE_Track";
};

// Object Position Definition
_position = getPos _object;
_medPos = [(_position select 0) -0.5, (_position select 1) -0.5, 0];
_ammoPos = [(_position select 0) +0.5, (_position select 1) +0.5, 0];
_otherPosLow = [(_position select 0) +1.5, (_position select 1) +1.5, 0];
_otherPos = [(_position select 0), (_position select 1), 1];

_radius = 5;
_exists = {typeof _x == _boxToSpawn} count (nearestObjects [_position, [_boxToSpawn], _radius, false]) > 0;

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

//Spawn box of class
_box = _boxToSpawn createVehicle _position;
clearItemCargoGlobal _box;
clearBackpackCargoGlobal _box;
clearMagazineCargoGlobal _box;
clearWeaponCargoGlobal _box;


// Medical boxes 
if (_boxType == "Medical") then {
    _box setPos _medPos;
    if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
        //Ace Medical is enabled so populate with ACE gear & Field Hospital
        [_box, true, 1] call Waldo_fnc_MedicalCratePopulate;
    } else {
        //Ace Medical is DISABLED so populate with vanilla gear & NO Field Hospital
        [_box, false, 1] call Waldo_fnc_MedicalCratePopulate;
    };
    [_box, 1] call ace_cargo_fnc_setSize;
    [_box, true] call ace_dragging_fnc_setDraggable;
    [_box, true] call ace_dragging_fnc_setCarryable;
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
};


// Resupply Box
if (_boxType == "Supply") then {
    _box setPos _ammoPos;
    //Call supplybox population script with box and random scalar between 1 & 2
    [_box, 1, _side, true] call Waldo_fnc_SupplyCratePopulate;
    [_box, 1] call ace_cargo_fnc_setSize;
    [_box, true] call ace_dragging_fnc_setDraggable;
    [_box, true] call ace_dragging_fnc_setCarryable;
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

// Ammo Only Box
if (_boxType == "Ammo") then {
    _box setPos _ammoPos;
    //Call supplybox population script with box and random scalar between 1 & 2
    [_box, 1, _side, false] call Waldo_fnc_SupplyCratePopulate;
    [_box, 1] call ace_cargo_fnc_setSize;
    [_box, true] call ace_dragging_fnc_setDraggable;
    [_box, true] call ace_dragging_fnc_setCarryable;
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


// ACE logistics stuff
if (_boxToSpawn == "ACE_Wheel" || _boxToSpawn == "ACE_Track") then {
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
/*
 * Author: Waldo
 * Logistics quartermaster spawner - spawns the requested ammo / medical / repair crate (with the
 * correct ACE ammo, medical items and tracks/tyres) beside the quartermaster vehicle. Called from
 * the ACE actions added by initQuartermaster.sqf; not intended to be called directly. Registered as
 * Waldo_fnc_LogisticsSpawner and invoked with addAction-style arguments.
 *
 * Arguments:
 * 0: _target <OBJECT> - the quartermaster the actions are attached to
 * 1: _player <OBJECT> - the player who triggered the action
 * 2: _boxType <STRING> - the requested crate type
 * 3: _offsetDegrees <NUMBER> - bearing around the vehicle for the spawn (0 front, 90 right, 180 rear, 270 left)
 * 4: _offsetDistance <NUMBER> - distance from the vehicle to spawn the crate
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * // added automatically by Waldo_fnc_SetupQuarterMaster
 */

params["_target","_player","_boxType",["_offsetDegrees",90],["_offsetDistance",2]];

_logiSide = side _player;

// Find area external to vehicle on vehicles right hand side
_vehiclePositionOffsetOnDirectionLogi = getDir _target + _offsetDegrees;

//Create Safezone & Mark with 
_knownSafePositionLogi = [_target, _offsetDistance, _vehiclePositionOffsetOnDirectionLogi] call BIS_fnc_relPos;

// Object Position Definition
_medPos = _knownSafePositionLogi getPos [2,(_vehiclePositionOffsetOnDirectionLogi + 40)]; 
_ammoPos = _knownSafePositionLogi getPos [2,(_vehiclePositionOffsetOnDirectionLogi - 40)]; 
_otherPosLow = _knownSafePositionLogi getPos [2.25,_vehiclePositionOffsetOnDirectionLogi];
_otherPosHigh = _knownSafePositionLogi getPos [1.60,_vehiclePositionOffsetOnDirectionLogi];

// Get MMT defined box classes & if undefined attempt to get initServer.sqf definition
_supplyBoxClass = missionNamespace getVariable "Logi_SupplyBoxClass";
_medicalBoxClass = missionNamespace getVariable "Logi_MedicalBoxClass";
_boxToSpawn = "B_supplyCrate_F";
if (isNil "_supplyBoxClass" && isNil "_medicalBoxClass") then
{
    
    if (_boxType == "Medical") then {
        if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
        _boxToSpawn = "ACE_medicalSupplyCrate_advanced";
        _medicalBoxClass = "ACE_medicalSupplyCrate_advanced";
        } else {
            _boxToSpawn = "C_IDAP_supplyCrate_F";
        };
    };
    if (_boxType == "Supply" || _boxType == "Ammo") then {
        _boxToSpawn = "B_supplyCrate_F"; 
        _supplyBoxClass = "B_supplyCrate_F";     
    };
} else {
    if (_boxType == "Medical") then {
        _boxToSpawn = Logi_MedicalBoxClass;
    };
    if (_boxType == "Supply" || _boxType == "Ammo") then {
        _boxToSpawn = _supplyBoxClass;       
    };
};
// Get Track & Wheel
if (_boxType == "Wheel") then {
    _boxToSpawn = "ACE_Wheel";
};
if (_boxType == "Track") then {
    _boxToSpawn = "ACE_Track";
};


_radius = 5;
_exists = {typeof _x == _boxToSpawn} count (nearestObjects [getposATL _target, [_boxToSpawn], _radius, false]) > 0;

if (_exists) exitWith {
    _quote = selectRandom [
        "QM: You've got one right there!",
        "QM: I just gave you one of those.",
        "QM: Deploy that one first, then we'll talk about more",
        "QM: You joking? Use that one first.",
        "QM: They're not free you know!"
        ];
    [_quote, _player] call Waldo_fnc_DynamicText;
};

//Spawn box of class
_box = _boxToSpawn createVehicle _knownSafePositionLogi;
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
    [_box, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    _quote = selectRandom [
        "QM: Medical Box? Check. Here it is.",
        "QM: Med Supplies, eh? Keep our boys alive out there!",
        "QM: God, you're going through a lot of these, aren't you?",
        "QM: Erm.. yeah. We have that in stock. Here.",
        "QM: One Medical Crate, check.",
        "QM: That one's on the house.",
        "QM: You got your crate licence there mate?",
        "QM: Come back if you need more, they haven't set up the limits yet!"
    ];
    [_quote, _player] call Waldo_fnc_DynamicText;
};


// Resupply Box
if (_boxType == "Supply") then {
    _box setPos _ammoPos;
    //Call supplybox population script with box and random scalar between 1 & 2
    [_box, 1, _logiSide, false, true] call Waldo_fnc_SupplyCratePopulate;
    [_box, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    _quote = selectRandom [
        "QM: One canister, ready to go.",
        "QM: ...48...49...50. Yep, it's all there.",
        "QM: God, you're going through a lot of these, aren't you?",
        "QM: Erm.. yeah. We have that in stock. Here.",
        "QM: One Ammo Crate, check.",
        "QM: That one's on the house.",
        "QM: You got your crate licence there mate?",
        "QM: Come back if you need more, they haven't set up the limits yet!",
        "QM: Don't spend them all in one place!"
    ];
    [_quote, _player] call Waldo_fnc_DynamicText;
};

// Ammo Only Box
if (_boxType == "Ammo") then {
    _box setPos _ammoPos;
    //Call supplybox population script with box and random scalar between 1 & 2
    [_box, 0.75, _logiSide, false, false] call Waldo_fnc_SupplyCratePopulate;
    [_box, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;
    _quote = selectRandom [
        "QM: One canister, ready to go.",
        "QM: ...48...49...50. Yep, it's all there.",
        "QM: God, you're going through a lot of these, aren't you?",
        "QM: Erm.. yeah. We have that in stock. Here.",
        "QM: One Ammo Crate, check.",
        "QM: That one's on the house.",
        "QM: You got your crate licence there mate?",
        "QM: Come back if you need more, they haven't set up the limits yet!",
        "QM: Don't spend them all in one place!"
    ];
    [_quote, _player] call Waldo_fnc_DynamicText;
};

// ACE logistics stuff
if (_boxToSpawn == "ACE_Wheel" || _boxToSpawn == "ACE_Track") then {
    if (_boxToSpawn == "ACE_Wheel") then {
        _box setPos _otherPosHigh;
    } else {
        _box setPos _otherPosLow;
    };
    _quote = selectRandom [
        "QM: Had a breakdown out there, eh?",
        "QM: One spare part, ready to go.",
        "QM: Here y'are.",
        "QM: Be more damn careful next time.",
        "QM: Get the lads moving again out there."
    ];
    [_quote, _player] call Waldo_fnc_DynamicText;
};

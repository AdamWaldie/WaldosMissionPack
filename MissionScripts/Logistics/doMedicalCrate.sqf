/*
This function populates an advanced medical crate, with the option to enable the box as a field hospital if desired.

Params:
_crate - object to populate (Passed from module where thee classname of the box is defined)
_isFacility - tickbox option to enable locational boost to medical skill
_scale - scalar value to multiply medical supplycompliment

Where the call is as follows:

[_crate, _fieldHopsital, _size] call Waldo_fnc_MedicalCratePopulate;

e.g.

[this, true, 1] call Waldo_fnc_MedicalCratePopulate;

Called via Zen Module as defined in Zen_medicalCrateModule.sqf

*/

params [
    ["_crate", objNull, [objNull]],
    ["_isFacility", true],
    ["_Scale", 1]
];

// add medical equipment
clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

//Verify ACE Medical Activation, then perform due dilligence
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    //Check if option selected for medical locational boost
    if (_isFacility) then {
        _crate setVariable ["ace_medical_isMedicalFacility", true, true];
        // Make addAction Topic
        _crate addAction ["<t color='#770000'>Field Hospital Enabled</t>", {}, [], 1.5, true, true, "", "true", 5];
    };
    //Add ACE Medical supplies   
   //Common Items
    _crate addItemCargoGlobal ["ACE_SpareBarrel",(_Scale * 4)];
    _crate addItemCargoGlobal ["ACE_EarPlugs",(_Scale * 25)];
    _crate addItemCargoGlobal ["ACE_bodyBag",(_Scale * 25)];

    //Bandages
    _crate addItemCargoGlobal ["ACE_fieldDressing",(_Scale * 50)];
    _crate addItemCargoGlobal ["ACE_packingBandage",(_Scale * 50)];
    _crate addItemCargoGlobal ["ACE_elasticBandage",(_Scale * 50)];
    _crate addItemCargoGlobal ["ACE_quikclot",(_Scale * 50)];

    //Blood Flow & Surgical
    _crate addItemCargoGlobal ["ACE_tourniquet",(_Scale * 25)];
    _crate addItemCargoGlobal ["ACE_splint", (_Scale * 20)];
    _crate addItemCargoGlobal ["ACE_personalAidKit",(_Scale * 15)];
    _crate addItemCargoGlobal ["ACE_surgicalKit",(_Scale * 10)];

    //Saline
    _crate addItemCargoGlobal ["ACE_salineIV",(_Scale * 30)];
    _crate addItemCargoGlobal ["ACE_salineIV_500",(_Scale * 40)];
    _crate addItemCargoGlobal ["ACE_salineIV_250",(_Scale * 50)];

    //Plasma
    _crate addItemCargoGlobal ["ACE_plasmaIV",(_Scale * 30)];
    _crate addItemCargoGlobal ["ACE_plasmaIV_500",(_Scale * 40)];
    _crate addItemCargoGlobal ["ACE_plasmaIV_250",(_Scale * 50)];
    
    //Blood
    _crate addItemCargoGlobal ["ACE_bloodIV",(_Scale * 30)];
    _crate addItemCargoGlobal ["ACE_bloodIV_500",(_Scale * 40)];
    _crate addItemCargoGlobal ["ACE_bloodIV_250",(_Scale * 50)];

    //Pain & Heart Rate
    _crate addItemCargoGlobal ["ACE_morphine",(_Scale * 25)];
    _crate addItemCargoGlobal ["ACE_epinephrine",(_Scale * 40)];
    _crate addItemCargoGlobal ["ACE_adenosine",(_Scale * 40)];
    
} else {
    //Add vanilla Medical
    _crate addItemCargoGlobal ["FirstAidKit",(_Scale * 40)];
    _crate addItemCargoGlobal ["Medikit",(_Scale * 5)];
};

// Change ace logistics size of crate
[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_crate, true] call ace_dragging_fnc_setCarryable;
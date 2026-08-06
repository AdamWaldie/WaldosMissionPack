/*
This function populates an advanced medical crate, with the option to enable the box as a field hospital if desired.
When enabled with ACE medical present, a "FIELD HOSPITAL" 3D marker is attached to the crate so players can see
which crate grants the locational treatment boost without opening its inventory or reading the mission briefing.

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
if (!isServer) exitWith {false};

// add medical equipment
clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

//Verify ACE Medical Activation, then perform due dilligence
if (isClass(configFile >> "CfgPatches" >> "ace_medical")) then {
    //Check if option selected for medical locational boost
    private _markerId = format ["WMP_FieldHospital_%1", netId _crate];
    if (_isFacility) then {
        _crate setVariable ["ace_medical_isMedicalFacility", true, true];
        // ACE medical already exposes the facility state to treatment logic, but that gives
        // players no visible reason to bring casualties to this specific crate over any other
        // one - a persistent 3D marker is the non-intrusive indicator (no addAction, so it
        // never pollutes the vanilla/ACE interaction menu the way a prior decorative action did).
        [_markerId, _crate, createHashMapFromArray [
            ["text", "FIELD HOSPITAL"],
            ["icon", "\z\ACE\addons\medical_gui\ui\cross.paa"],
            ["colour", [0.35, 0.85, 0.45, 0.95]],
            ["offset", [0, 0, 1.2]],
            ["distance", 40]
        ]] call Waldo_fnc_Create3DMarker;
        diag_log format ["[WMP LOGISTICS] ACE medical facility enabled crate=%1", netId _crate];
    } else {
        [_markerId] call Waldo_fnc_Remove3DMarker;
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
    _crate addItemCargoGlobal ["ACE_suture",(_Scale * 250)];

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
[_crate, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes;

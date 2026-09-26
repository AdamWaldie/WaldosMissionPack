/*
 * Author: WaldoTheWarfighter
 * Purpose: Populates a medical crate and optionally marks it as an ACE field hospital.
 * Locality / Authority: Server mutates global cargo; caller owns crate-handling registration.
 * Repeat / JIP: Rebuilds inventory on repeat; global contents and facility state replicate to JIP.
 * Arguments: crate <OBJECT>, field-hospital mode <BOOL> (true), scale <NUMBER> (1).
 * Return Value: No supported return value; use the crate's resulting inventory/facility state.
 * Current callers: starter crates, quartermaster and ZEN medical crate.
 * Example: [myCrate, true, 1] call Waldo_fnc_MedicalCratePopulate;
 * Result: The crate receives medical stock and, when requested, ACE medical-facility status.
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
    if (_isFacility) then {
        _crate setVariable ["ace_medical_isMedicalFacility", true, true];
        // ACE medical already exposes the facility state to treatment logic, but that gives
        // players no visible reason to bring casualties to this specific crate over any other
        // one - a simple informational interaction on the crate itself is the indicator, not a
        // persistent 3D marker floating in the world.
        [_crate, true] remoteExec ["Waldo_fnc_MedicalCrateFacilityActionLocal", 0, _crate];
        diag_log format ["[WMP LOGISTICS] ACE medical facility enabled crate=%1", netId _crate];
    } else {
        [_crate, false] remoteExec ["Waldo_fnc_MedicalCrateFacilityActionLocal", 0, _crate];
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

if !(_crate getVariable ["Waldo_Logistics_StarterCrate", false]) then {
    [_crate, "MEDICAL"] spawn Waldo_fnc_LogisticsRegisterSpawned;
};

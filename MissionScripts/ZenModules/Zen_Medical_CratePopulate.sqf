/*
This function populates an advanced medical crate, with the option to enable the box as a field hospital if desired.

Called via Zen Module ONLY.

*/

params [
    ["_crate", objNull, [objNull]],
    ["_isFacility", true],
    ["_Scale", 1]
];

if (_isFacility) then {
    _crate setVariable ["ace_medical_isMedicalFacility", true, true];
    // Make addAction Topic
    _crate addAction ["This Is A Field Hospital", {}, [], 1.5, true, true, "", "true", 5];
};

// add medical equipment
clearweaponcargoGlobal _crate;
clearmagazinecargoGlobal _crate;
clearitemcargoGlobal _crate;
clearbackpackcargoGlobal _crate;

_crate addItemCargoGlobal ["ACE_EarPlugs",(_quaScale * 25)];

_crate addItemCargoGlobal ["ACE_packingBandage",(_quaScale * 100)];
_crate addItemCargoGlobal ["ACE_elasticBandage",(_quaScale * 100)];
_crate addItemCargoGlobal ["ACE_quikclot",(_quaScale * 100)];

_crate addItemCargoGlobal ["ACE_personalAidKit",(_quaScale * 20)];
_crate addItemCargoGlobal ["ACE_splint", (_quaScale * 40)];

_crate addItemCargoGlobal ["ACE_salineIV",(_quaScale * 30)];
_crate addItemCargoGlobal ["ACE_salineIV_500",(_quaScale * 60)];

_crate addItemCargoGlobal ["ACE_morphine",(_quaScale * 25)];
_crate addItemCargoGlobal ["ACE_epinephrine",(_quaScale * 40)];
_crate addItemCargoGlobal ["ACE_adenosine",(_quaScale * 40)];

// Change ace logistics size of crate
[_crate, 1] call ace_cargo_fnc_setSize;
[_crate, true] call ace_dragging_fnc_setDraggable;
[_box, true] call ace_dragging_fnc_setCarryable;
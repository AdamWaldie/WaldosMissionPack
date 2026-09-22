/*
 * Author: WaldoTheWarfighter
 * Purpose: Registers the service/logistics test strip beside the four-player ACRE test.
 * Locality / Authority: Server only after release initServer.sqf; WMP owns client ACE/JIP state.
 * Repeat / JIP: Initial registration once; public WMP registries replay to joining clients.
 * Arguments: None. Return Value: Nothing.
 * Current caller: generated initServer.sqf post-hook.
 * Example: [] execVM "serviceLogisticsTestServer.sqf";
 */
if (!isServer) exitWith {};
waitUntil {sleep 0.1; missionNamespace getVariable ["Waldo_SharedFeatureConfigReady", false]};

clearWeaponCargoGlobal acre_loadout_crate;
clearMagazineCargoGlobal acre_loadout_crate;
clearItemCargoGlobal acre_loadout_crate;
clearBackpackCargoGlobal acre_loadout_crate;
acre_loadout_crate setVariable ["Waldo_ACRE_TestCrate", true, true];
[acre_loadout_crate] remoteExec ["Waldo_fnc_ZenAddLoadoutSaveAction", 0, acre_loadout_crate];

[test_base_hq, "TEST_BASE", "Main Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
[test_base_fob, "TEST_BASE", "Forward Base", ["SAVE", "HEAL", "SPECTATE", "TELEPORT"]] call Waldo_fnc_BaseServicesRegisterNode;
[test_quartermaster, 90, 5] call Waldo_fnc_SetupQuarterMaster;
[test_quartermaster, 90, 5] remoteExec ["Waldo_fnc_SetupQuarterMaster", 0, test_quartermaster];

{
    _x setPhysicsCollisionFlag true;
    _x enableSimulationGlobal true;
} forEach [test_transfer_source, test_transfer_target, test_cargo_crate, test_cargo_vehicle];
{[_x, -1, 1, true, true] call Waldo_fnc_SetCargoAttributes} forEach
    [test_transfer_source, test_transfer_target, test_cargo_crate];
[test_cargo_vehicle, 30, -1, false, false] call Waldo_fnc_SetCargoAttributes;

clearWeaponCargoGlobal test_transfer_source;
clearMagazineCargoGlobal test_transfer_source;
clearItemCargoGlobal test_transfer_source;
clearBackpackCargoGlobal test_transfer_source;
test_transfer_source addItemCargoGlobal ["ACE_fieldDressing", 8];
test_transfer_source addMagazineAmmoCargo ["30Rnd_65x39_caseless_mag", 3, 11];
test_transfer_source addBackpackCargoGlobal ["B_AssaultPack_mcamo", 1];
clearWeaponCargoGlobal test_transfer_target;
clearMagazineCargoGlobal test_transfer_target;
clearItemCargoGlobal test_transfer_target;
clearBackpackCargoGlobal test_transfer_target;
[test_transfer_source] call Waldo_fnc_SupplyTransfersRegister;
[test_transfer_target] call Waldo_fnc_SupplyTransfersRegister;
[test_cargo_vehicle] call Waldo_fnc_SupplyTransfersRegister;
[test_cargo_crate] call Waldo_fnc_PhysicalCargoRegister;

// Test fixture only: verify each seat with a temporary local occupant. Production
// missions should author measured seat points for their own vehicle classes.
private _seatGroup = createGroup [west, true];
private _seatProbe = _seatGroup createUnit ["B_Soldier_F", getPosATL test_cargo_vehicle, [], 0, "CAN_COLLIDE"];
private _seatPoints = [];
if (!isNull _seatProbe) then {
    _seatProbe allowDamage false;
    _seatProbe hideObjectGlobal true;
    _seatProbe disableAI "ALL";
    private _available = (fullCrew [test_cargo_vehicle, "", true]) select {
        (toLowerANSI (_x select 1) isEqualTo "cargo" && {(_x select 2) >= 0})
            || {(_x select 4) && {(_x select 3) isNotEqualTo []}}
    };
    {
        private _seat = _x;
        private _index = _seat select 2;
        private _path = _seat select 3;
        private _kind = if (toLowerANSI (_seat select 1) isEqualTo "cargo") then {"CARGO"} else {"TURRET"};
        if (_kind isEqualTo "CARGO") then {
            _seatProbe moveInCargo [test_cargo_vehicle, _index];
        } else {
            _seatProbe moveInTurret [test_cargo_vehicle, _path];
        };
        uiSleep 0.08;
        private _occupied = (fullCrew [test_cargo_vehicle, "", true]) findIf {
            (_x select 0) isEqualTo _seatProbe
                && {if (_kind isEqualTo "CARGO") then {(_x select 2) isEqualTo _index}
                    else {(_x select 3) isEqualTo _path}}
        };
        if (_occupied >= 0) then {
            _seatPoints pushBack [_kind, if (_kind isEqualTo "CARGO") then {_index} else {_path},
                test_cargo_vehicle worldToModel (ASLToAGL getPosWorld _seatProbe)];
        };
        moveOut _seatProbe;
        uiSleep 0.03;
    } forEach _available;
    deleteVehicle _seatProbe;
};
deleteGroup _seatGroup;
test_cargo_vehicle setVariable ["Waldo_PhysicalCargo_SeatPoints", _seatPoints, true];
diag_log format ["[WMP TEST SEATS] buggy=%1 measured=%2 points=%3",
    typeOf test_cargo_vehicle, count _seatPoints, _seatPoints];

diag_log format ["[WMP TEST SERVICE LOGISTICS READY] buggy=%1 source=%2 target=%3 cargo=%4",
    typeOf test_cargo_vehicle, typeOf test_transfer_source,
    typeOf test_transfer_target, typeOf test_cargo_crate];

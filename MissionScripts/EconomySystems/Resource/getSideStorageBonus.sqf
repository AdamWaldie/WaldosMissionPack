/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - getSideStorageBonus
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_getSideStorageBonus via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_sideKey", "_resourceType"];

    private _baseStorage = [_resourceType] call Waldo_fnc_EcoResource_getResourceBaseStorage;
    if (_baseStorage <= 0) exitWith {0};
    if (isNil "Waldo_fnc_EcoBuild_getSpawnedBuildings") exitWith {0};
    if (isNil "Waldo_fnc_EcoBuild_getBuildDefinition") exitWith {0};

    private _bonus = 0;
    {
        private _building = _x;
        if (isNull _building) then {continue;};
        if ((_building getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) isNotEqualTo _sideKey) then {continue;};
        if !(_building getVariable ["WaldoEcoBuild_Operational", true]) then {continue;};

        private _entry = [_building getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 17) then {continue;};

        {
            if ((_x param [0, ""]) isEqualTo _resourceType) then {
                _bonus = _bonus + (_x param [1, 0]);
            };
        } forEach (_entry param [17, []]);
    } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);

    _bonus

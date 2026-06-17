/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - getSideResearchSpeedBonusPercent
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_getSideResearchSpeedBonusPercent via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_sideKey", "NONE"]];

        if !(_sideKey in ["WEST", "EAST", "GUER"]) exitWith {0};

        private _bonus = 0;
        {
            if (isNull _x) then {continue;};
            if ((_x getVariable ["WaldoEcoBuild_BuildOwnerSideKey", "NONE"]) isNotEqualTo _sideKey) then {continue;};
            if !(_x getVariable ["WaldoEcoBuild_Operational", true]) then {continue;};
            if (_x getVariable ["WaldoEcoBuild_IsUpgrading", false]) then {continue;};

            private _entry = [_x getVariable ["WaldoEcoBuild_BuildDefinitionName", ""]] call Waldo_fnc_EcoBuild_getBuildDefinition;
            if ((count _entry) <= 0) then {continue;};
            _bonus = _bonus + (0 max (_entry param [12, 0]));
        } forEach (call Waldo_fnc_EcoBuild_getSpawnedBuildings);

        _bonus


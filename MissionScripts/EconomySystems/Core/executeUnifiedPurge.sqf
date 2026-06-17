/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - executeUnifiedPurge
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_executeUnifiedPurge via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [
        ["_configSpec", []],
        ["_valueSpec", []]
    ];

    if !([] call Waldo_fnc_EcoCore_canRunAuthority) exitWith {false};

    private _purgeResourcesConfig = _configSpec param [0, false];
    private _purgeBuildingsConfig = _configSpec param [1, false];
    private _purgeResearchConfig = _configSpec param [2, false];
    private _purgeBuyConfig = _configSpec param [3, false];

    private _purgeBuildingValues = _valueSpec param [0, false];
    private _purgeSideResources = _valueSpec param [1, false];
    private _purgeContainers = _valueSpec param [2, false];
    private _purgeGroundCommand = _valueSpec param [3, false];

    if (_purgeResourcesConfig || _purgeBuildingsConfig || _purgeResearchConfig || _purgeBuyConfig) then {
        [] call Waldo_fnc_EcoCore_clearPresetAssignments;
    };

    if (_purgeResourcesConfig) then {
        [] call Waldo_fnc_EcoCore_purgeResourceConfiguration;
    };
    if (_purgeBuildingsConfig) then {
        [] call Waldo_fnc_EcoCore_purgeBuildConfiguration;
    };
    if (_purgeResearchConfig) then {
        [] call Waldo_fnc_EcoCore_purgeResearchConfiguration;
    };
    if (_purgeBuyConfig) then {
        [] call Waldo_fnc_EcoCore_purgePurchaseConfiguration;
    };

    if (_purgeBuildingValues) then {
        [] call Waldo_fnc_EcoCore_purgeBuildingValues;
    };
    if (_purgeSideResources) then {
        [] call Waldo_fnc_EcoCore_purgeSideResourceValues;
    };
    if (_purgeContainers) then {
        [] call Waldo_fnc_EcoCore_purgeResourceContainers;
    };
    if (_purgeGroundCommand) then {
        [] call Waldo_fnc_EcoCore_purgeGroundCommandValues;
    };

    true

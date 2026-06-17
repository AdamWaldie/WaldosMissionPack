/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoCore system - collectKnownModuleImportPayloads
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoCore_collectKnownModuleImportPayloads via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params [["_value", []]];

    private _found = [];
    if !(_value isEqualType []) exitWith {_found};

    private _tag = _value param [0, ""];
    if (_tag in [
        "WaldoEcoResource_CONFIG_V1",
        "WaldoEcoResource_CONFIG_V2",
        "WaldoEcoResource_CONFIG_V3",
        "WaldoEcoResearch_RESEARCH_V1",
        "WaldoEcoBuild_BUILD_V1",
        "WaldoEcoBuild_BUILD_V2",
        "WaldoEcoBuild_BUILD_V3",
        "WaldoEcoBuy_PURCHASE_V1"
    ]) then {
        _found pushBack _value;
    };

    {
        if (_x isEqualType []) then {
            _found append ([_x] call Waldo_fnc_EcoCore_collectKnownModuleImportPayloads);
        };
    } forEach _value;

    _found

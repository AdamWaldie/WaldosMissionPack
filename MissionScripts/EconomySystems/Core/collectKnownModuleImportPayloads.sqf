/*
 * Author: Waldo
 * Collect known module import payloads.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _value <ARRAY> - value (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_value] call Waldo_fnc_EcoCore_collectKnownModuleImportPayloads;
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

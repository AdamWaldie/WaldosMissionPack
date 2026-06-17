/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoResource system - promptResourceCrateValue
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoResource_promptResourceCrateValue via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

    params ["_pos"];

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

    _disp setVariable ["WaldoEcoResource_TargetPos", _pos];

    private _bg = _disp ctrlCreate ["RscText", -1];
_bg ctrlSetPosition [0.4, 0.08, 0.49, 0.5];
_bg ctrlSetBackgroundColor [0, 0, 0, 0.8];
_bg ctrlCommit 0;

private _title = _disp ctrlCreate ["RscText", -1];
_title ctrlSetPosition [0.4, 0.09, 0.39, 0.03];
_title ctrlSetText "Create Resource Crate";
_title ctrlCommit 0;

private _resourcesLabel = _disp ctrlCreate ["RscText", -1];
_resourcesLabel ctrlSetPosition [0.4, 0.13, 0.39, 0.04];
_resourcesLabel ctrlSetText "Resources (one per line, e.g. Metal=2)";
_resourcesLabel ctrlCommit 0;

private _resourcesEdit = _disp ctrlCreate ["RscEditMulti", -1];
_resourcesEdit ctrlSetPosition [0.41, 0.18, 0.47, 0.33];
_resourcesEdit ctrlSetText "Resource=1";
_resourcesEdit ctrlCommit 0;

private _ok = _disp ctrlCreate ["RscButtonMenu", -1];
_ok ctrlSetPosition [0.55, 0.52, 0.16, 0.05];
_ok ctrlSetText "Create";
_ok ctrlCommit 0;

private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
_cancel ctrlSetPosition [0.72, 0.52, 0.16, 0.05];
_cancel ctrlSetText "Cancel";
_cancel ctrlCommit 0;

_disp setVariable ["WaldoEcoResource_ValuePromptBG", _bg];
_disp setVariable ["WaldoEcoResource_ValuePromptTitle", _title];
_disp setVariable ["WaldoEcoResource_ValuePromptResourcesLabel", _resourcesLabel];
_disp setVariable ["WaldoEcoResource_ValuePromptResourcesEdit", _resourcesEdit];
_disp setVariable ["WaldoEcoResource_ValuePromptOK", _ok];
_disp setVariable ["WaldoEcoResource_ValuePromptCancel", _cancel];

    {
        _x setVariable ["WaldoEcoResource_ZeusDisplay", _disp];
    } forEach [_ok, _cancel];

    _ok ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _pos = _disp getVariable ["WaldoEcoResource_TargetPos", [0, 0, 0]];
            private _resourcesCtrl = _disp getVariable ["WaldoEcoResource_ValuePromptResourcesEdit", controlNull];
            if (isNull _resourcesCtrl) exitWith {};
            private _rows = [ctrlText _resourcesCtrl] call Waldo_fnc_EcoResource_parseResourceRowsText;
            if ((count _rows) <= 0) exitWith {};

            [_pos, _rows] call Waldo_fnc_EcoResource_spawnResourceCrate;
            [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
        }
    ];

    _cancel ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_ctrl"];

            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
            };
        }
    ];

    [_disp, [_resourcesEdit], _resourcesEdit] call Waldo_fnc_EcoResource_setPromptInputTargets;

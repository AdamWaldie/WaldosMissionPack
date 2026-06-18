/*
 * Author: Waldo
 * Prompt resource zone.
 *
 * Part of the Waldos Economy Systems suite (Resource system).
 *
 * Arguments:
 * 0: _pos <ANY> - pos
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_pos] call Waldo_fnc_EcoResource_promptResourceZone;
 */

    params ["_pos"];

    if (!hasInterface) exitWith {};

    private _zeusDisp = call Waldo_fnc_EcoCore_getZeusDisplay;
    if (isNull _zeusDisp) exitWith {};

    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceCratePrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceSettingsPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceConfigPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    [_zeusDisp] call Waldo_fnc_EcoCommand_cleanupGroundCommandPrompt;
    [_zeusDisp] call Waldo_fnc_EcoResource_stopResourceCratePlacement;

    private _disp = call Waldo_fnc_EcoCore_createZeusPromptDisplay;
    if (isNull _disp) exitWith {};

    _disp setVariable ["WaldoEcoResource_ZoneTargetPos", _pos];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerIndex", 0];

        private _bg = _disp ctrlCreate ["RscText", -1];
    _bg ctrlSetPosition [0.40, 0.04, 0.55, 0.74];
    _bg ctrlSetBackgroundColor [0, 0, 0, 0.82];
    _bg ctrlCommit 0;

    private _title = _disp ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.44, 0.07, 0.47, 0.03];
    _title ctrlSetText "Create Resource Zone";
    _title ctrlCommit 0;

    private _nameLabel = _disp ctrlCreate ["RscText", -1];
    _nameLabel ctrlSetPosition [0.44, 0.12, 0.24, 0.03];
    _nameLabel ctrlSetText "Zone name";
    _nameLabel ctrlCommit 0;

    private _nameEdit = _disp ctrlCreate ["RscEdit", -1];
    _nameEdit ctrlSetPosition [0.44, 0.155, 0.47, 0.05];
    _nameEdit ctrlSetText "Resource Zone";
    _nameEdit ctrlCommit 0;

    private _sizeLabel = _disp ctrlCreate ["RscText", -1];
    _sizeLabel ctrlSetPosition [0.44, 0.22, 0.24, 0.03];
    _sizeLabel ctrlSetText "Radius (m)";
    _sizeLabel ctrlCommit 0;

    private _sizeEdit = _disp ctrlCreate ["RscEdit", -1];
    _sizeEdit ctrlSetPosition [0.44, 0.255, 0.20, 0.05];
    _sizeEdit ctrlSetText "50";
    _sizeEdit ctrlCommit 0;

    private _resourcesLabel = _disp ctrlCreate ["RscText", -1];
    _resourcesLabel ctrlSetPosition [0.44, 0.32, 0.47, 0.03];
    _resourcesLabel ctrlSetText "Resources per tick/deposit (Resource=5/1000)";
    _resourcesLabel ctrlCommit 0;

    private _resourcesEdit = _disp ctrlCreate ["RscEditMulti", -1];
    _resourcesEdit ctrlSetPosition [0.44, 0.355, 0.47, 0.14];
    _resourcesEdit ctrlSetText "Resource=5";
    _resourcesEdit ctrlCommit 0;

    private _ownerLabel = _disp ctrlCreate ["RscText", -1];
    _ownerLabel ctrlSetPosition [0.44, 0.52, 0.24, 0.03];
    _ownerLabel ctrlSetText "Initial owner";
    _ownerLabel ctrlCommit 0;

    private _ownerPrev = _disp ctrlCreate ["RscButtonMenu", -1];
    _ownerPrev ctrlSetPosition [0.44, 0.555, 0.06, 0.04];
    _ownerPrev ctrlSetText "<";
    _ownerPrev ctrlCommit 0;

    private _ownerValue = _disp ctrlCreate ["RscText", -1];
    _ownerValue ctrlSetPosition [0.52, 0.555, 0.31, 0.04];
    _ownerValue ctrlSetText "";
    _ownerValue ctrlCommit 0;

    private _ownerNext = _disp ctrlCreate ["RscButtonMenu", -1];
    _ownerNext ctrlSetPosition [0.85, 0.555, 0.06, 0.04];
    _ownerNext ctrlSetText ">";
    _ownerNext ctrlCommit 0;

    private _intervalLabel = _disp ctrlCreate ["RscText", -1];
    _intervalLabel ctrlSetPosition [0.44, 0.62, 0.24, 0.03];
    _intervalLabel ctrlSetText "Interval (sec)";
    _intervalLabel ctrlCommit 0;

    private _intervalEdit = _disp ctrlCreate ["RscEdit", -1];
    _intervalEdit ctrlSetPosition [0.44, 0.655, 0.20, 0.05];
    _intervalEdit ctrlSetText "60";
    _intervalEdit ctrlCommit 0;

    private _create = _disp ctrlCreate ["RscButtonMenu", -1];
    _create ctrlSetPosition [0.44, 0.715, 0.20, 0.05];
    _create ctrlSetText "Create";
    _create ctrlCommit 0;

    private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
    _cancel ctrlSetPosition [0.71, 0.715, 0.20, 0.05];
    _cancel ctrlSetText "Cancel";
    _cancel ctrlCommit 0;

    _disp setVariable ["WaldoEcoResource_ZoneBG", _bg];
    _disp setVariable ["WaldoEcoResource_ZoneTitle", _title];
    _disp setVariable ["WaldoEcoResource_ZoneNameLabel", _nameLabel];
    _disp setVariable ["WaldoEcoResource_ZoneNameEdit", _nameEdit];
    _disp setVariable ["WaldoEcoResource_ZoneSizeLabel", _sizeLabel];
    _disp setVariable ["WaldoEcoResource_ZoneSizeEdit", _sizeEdit];
    _disp setVariable ["WaldoEcoResource_ZoneResourcesLabel", _resourcesLabel];
    _disp setVariable ["WaldoEcoResource_ZoneResourcesEdit", _resourcesEdit];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerLabel", _ownerLabel];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerPrev", _ownerPrev];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerValue", _ownerValue];
    _disp setVariable ["WaldoEcoResource_ZoneOwnerNext", _ownerNext];
    _disp setVariable ["WaldoEcoResource_ZoneIntervalLabel", _intervalLabel];
    _disp setVariable ["WaldoEcoResource_ZoneIntervalEdit", _intervalEdit];
    _disp setVariable ["WaldoEcoResource_ZoneCreate", _create];
    _disp setVariable ["WaldoEcoResource_ZoneCancel", _cancel];
    {
        _x setVariable ["WaldoEcoResource_ZeusDisplay", _disp];
    } forEach [_ownerPrev, _ownerNext, _create, _cancel];

    _ownerPrev setVariable ["WaldoEcoResource_Delta", -1];
    _ownerNext setVariable ["WaldoEcoResource_Delta", 1];

    {
        _x ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};
            [_disp, _ctrl getVariable ["WaldoEcoResource_Delta", 0]] call Waldo_fnc_EcoResource_cycleResourceZoneOwner;
        }];
    } forEach [_ownerPrev, _ownerNext];

    _create ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
        if (isNull _disp) exitWith {};

        private _owners = ["NONE", "WEST", "EAST", "GUER"];

        private _ownerIndex = _disp getVariable ["WaldoEcoResource_ZoneOwnerIndex", 0];
        if (_ownerIndex < 0 || {_ownerIndex >= count _owners}) then {_ownerIndex = 0;};

        private _nameCtrl = _disp getVariable ["WaldoEcoResource_ZoneNameEdit", controlNull];
        private _sizeCtrl = _disp getVariable ["WaldoEcoResource_ZoneSizeEdit", controlNull];
        private _resourcesCtrl = _disp getVariable ["WaldoEcoResource_ZoneResourcesEdit", controlNull];
        private _intervalCtrl = _disp getVariable ["WaldoEcoResource_ZoneIntervalEdit", controlNull];
        if (isNull _nameCtrl || isNull _sizeCtrl || isNull _resourcesCtrl || isNull _intervalCtrl) exitWith {};

        private _pos = _disp getVariable ["WaldoEcoResource_ZoneTargetPos", [0, 0, 0]];
        private _name = ctrlText _nameCtrl;
        private _radius = floor (parseNumber (ctrlText _sizeCtrl));
        private _rows = [ctrlText _resourcesCtrl] call Waldo_fnc_EcoResource_parseZoneResourceRowsText;
        private _interval = floor (parseNumber (ctrlText _intervalCtrl));
        if ((count _rows) <= 0) exitWith {};

        [_pos, _name, _radius, _rows, _owners select _ownerIndex, _interval] call Waldo_fnc_EcoResource_createResourceZone;
        [_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
    }];

    _cancel ctrlAddEventHandler ["ButtonClick", {
        params ["_ctrl"];
        private _disp = _ctrl getVariable ["WaldoEcoResource_ZeusDisplay", displayNull];
        if (!isNull _disp) then {
            [_disp] call Waldo_fnc_EcoResource_cleanupResourceZonePrompt;
        };
    }];

    [_disp, [_nameEdit, _sizeEdit, _resourcesEdit, _intervalEdit], _nameEdit] call Waldo_fnc_EcoResource_setPromptInputTargets;
    [_disp] call Waldo_fnc_EcoResource_refreshResourceZonePrompt;

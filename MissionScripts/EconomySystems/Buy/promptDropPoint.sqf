/*
 * Author: Waldo
 * Prompt drop point.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _pos <ARRAY> - pos (optional, default: [0, 0, 0])
 * 1: _dir <SCALAR> - dir (optional, default: 0)
 *
 * Return Value:
 * Any - see function body
 *
 * Example:
 * [_pos, _dir] call Waldo_fnc_EcoBuy_promptDropPoint;
 */

        params [["_pos", [0, 0, 0]], ["_dir", 0]];

        if (!hasInterface) exitWith {};

        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};

        [_disp] call Waldo_fnc_EcoBuy_cleanupPurchaseConfigPrompt;
        [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;

                private _bg = _disp ctrlCreate ["RscText", -1];
        _bg ctrlSetPosition [0.34, 0.24, 0.34, 0.32];
        _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
        _bg ctrlCommit 0;

        private _title = _disp ctrlCreate ["RscText", -1];
        _title ctrlSetPosition [0.36, 0.26, 0.28, 0.03];
        _title ctrlSetText "Set Drop Point";
        _title ctrlCommit 0;

        private _typeLabel = _disp ctrlCreate ["RscText", -1];
        _typeLabel ctrlSetPosition [0.36, 0.31, 0.24, 0.025];
        _typeLabel ctrlSetText "Drop Point Type";
        _typeLabel ctrlCommit 0;

        private _typePrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _typePrev ctrlSetPosition [0.36, 0.35, 0.05, 0.05];
        _typePrev ctrlSetText "<";
        _typePrev ctrlCommit 0;

        private _typeValue = _disp ctrlCreate ["RscText", -1];
        _typeValue ctrlSetPosition [0.42, 0.35, 0.18, 0.05];
        _typeValue ctrlSetText "Ground";
        _typeValue ctrlCommit 0;

        private _typeNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _typeNext ctrlSetPosition [0.61, 0.35, 0.05, 0.05];
        _typeNext ctrlSetText ">";
        _typeNext ctrlCommit 0;

        private _sideLabel = _disp ctrlCreate ["RscText", -1];
        _sideLabel ctrlSetPosition [0.36, 0.42, 0.24, 0.025];
        _sideLabel ctrlSetText "Drop Point Side";
        _sideLabel ctrlCommit 0;

        private _sidePrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _sidePrev ctrlSetPosition [0.36, 0.46, 0.05, 0.05];
        _sidePrev ctrlSetText "<";
        _sidePrev ctrlCommit 0;

        private _sideValue = _disp ctrlCreate ["RscText", -1];
        _sideValue ctrlSetPosition [0.42, 0.46, 0.18, 0.05];
        _sideValue ctrlSetText "EVERYONE";
        _sideValue ctrlCommit 0;

        private _sideNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _sideNext ctrlSetPosition [0.61, 0.46, 0.05, 0.05];
        _sideNext ctrlSetText ">";
        _sideNext ctrlCommit 0;

        private _create = _disp ctrlCreate ["RscButtonMenu", -1];
        _create ctrlSetPosition [0.36, 0.53, 0.13, 0.05];
        _create ctrlSetText "Create";
        _create ctrlCommit 0;

        private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
        _cancel ctrlSetPosition [0.53, 0.53, 0.13, 0.05];
        _cancel ctrlSetText "Cancel";
        _cancel ctrlCommit 0;

        _disp setVariable ["WaldoEcoBuy_DropBG", _bg];
        _disp setVariable ["WaldoEcoBuy_DropTitle", _title];
        _disp setVariable ["WaldoEcoBuy_DropTypeLabel", _typeLabel];
        _disp setVariable ["WaldoEcoBuy_DropTypePrev", _typePrev];
        _disp setVariable ["WaldoEcoBuy_DropTypeValue", _typeValue];
        _disp setVariable ["WaldoEcoBuy_DropTypeNext", _typeNext];
        _disp setVariable ["WaldoEcoBuy_DropSideLabel", _sideLabel];
        _disp setVariable ["WaldoEcoBuy_DropSidePrev", _sidePrev];
        _disp setVariable ["WaldoEcoBuy_DropSideValue", _sideValue];
        _disp setVariable ["WaldoEcoBuy_DropSideNext", _sideNext];
        _disp setVariable ["WaldoEcoBuy_DropCreate", _create];
        _disp setVariable ["WaldoEcoBuy_DropCancel", _cancel];
        _disp setVariable ["WaldoEcoBuy_DropTargetPos", _pos];
        _disp setVariable ["WaldoEcoBuy_DropTargetDir", _dir];
        _disp setVariable ["WaldoEcoBuy_DropTypeIndex", 2];
        _disp setVariable ["WaldoEcoBuy_DropSideIndex", 0];
        {
            _x setVariable ["WaldoEcoBuy_ZeusDisplay", _disp];
        } forEach [_typePrev, _typeNext, _sidePrev, _sideNext, _create, _cancel];

        _typePrev setVariable ["WaldoEcoBuy_Delta", -1];
        _typeNext setVariable ["WaldoEcoBuy_Delta", 1];
        _sidePrev setVariable ["WaldoEcoBuy_Delta", -1];
        _sideNext setVariable ["WaldoEcoBuy_Delta", 1];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuy_Delta", 0]] call Waldo_fnc_EcoBuy_cycleDropPointType;
            }];
        } forEach [_typePrev, _typeNext];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuy_Delta", 0]] call Waldo_fnc_EcoBuy_cycleDropPointSide;
            }];
        } forEach [_sidePrev, _sideNext];

        _create ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _choices = call Waldo_fnc_EcoBuy_getDropPointTypeChoices;
            private _index = _disp getVariable ["WaldoEcoBuy_DropTypeIndex", 2];
            if (_index < 0 || {_index >= count _choices}) then {_index = 2;};
            private _sideChoices = call Waldo_fnc_EcoBuy_getDropPointSideChoices;
            private _sideIndex = _disp getVariable ["WaldoEcoBuy_DropSideIndex", 0];
            if (_sideIndex < 0 || {_sideIndex >= count _sideChoices}) then {_sideIndex = 0;};

            private _pos = _disp getVariable ["WaldoEcoBuy_DropTargetPos", [0, 0, 0]];
            private _dir = _disp getVariable ["WaldoEcoBuy_DropTargetDir", 0];
            [_pos, _choices select _index, _dir, _sideChoices select _sideIndex] call Waldo_fnc_EcoBuy_createDropPoint;
            [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;
        }];

        _cancel ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuy_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoBuy_cleanupDropPointPrompt;
            };
        }];

        [_disp] call Waldo_fnc_EcoBuy_refreshDropPointType;
        [_disp] call Waldo_fnc_EcoBuy_refreshDropPointSide;


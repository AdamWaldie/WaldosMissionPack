/*
 * Author: Waldo (adapted for WaldosMissionPack - Waldos Economy Systems)
 * EcoBuild system - promptSpawnBuilding
 *
 * Part of the Waldos Economy Systems suite (Resource / Research / Build / Buy
 * + Ground Command). Registered as Waldo_fnc_EcoBuild_promptSpawnBuilding via WaldosFunctions.sqf.
 *
 * Return Value:
 * Per original implementation.
 */

        params [["_pos", [0, 0, 0]]];

        if (!hasInterface) exitWith {};

        private _disp = call Waldo_fnc_EcoCore_getZeusDisplay;
        if (isNull _disp) exitWith {};

        [_disp] call Waldo_fnc_EcoBuild_cleanupBuildConfigPrompt;
        [_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;

                private _bg = _disp ctrlCreate ["RscText", -1];
        _bg ctrlSetPosition [0.33, 0.16, 0.36, 0.56];
        _bg ctrlSetBackgroundColor [0, 0, 0, 0.86];
        _bg ctrlCommit 0;

        private _title = _disp ctrlCreate ["RscText", -1];
        _title ctrlSetPosition [0.35, 0.18, 0.30, 0.03];
        _title ctrlSetText "Spawn Building";
        _title ctrlCommit 0;

        private _sideLabel = _disp ctrlCreate ["RscText", -1];
        _sideLabel ctrlSetPosition [0.35, 0.23, 0.24, 0.025];
        _sideLabel ctrlSetText "Building Owner";
        _sideLabel ctrlCommit 0;

        private _sidePrev = _disp ctrlCreate ["RscButtonMenu", -1];
        _sidePrev ctrlSetPosition [0.35, 0.27, 0.05, 0.05];
        _sidePrev ctrlSetText "<";
        _sidePrev ctrlCommit 0;

        private _sideValue = _disp ctrlCreate ["RscText", -1];
        _sideValue ctrlSetPosition [0.41, 0.27, 0.20, 0.05];
        _sideValue ctrlSetText "UNCLAIMED";
        _sideValue ctrlCommit 0;

        private _sideNext = _disp ctrlCreate ["RscButtonMenu", -1];
        _sideNext ctrlSetPosition [0.62, 0.27, 0.05, 0.05];
        _sideNext ctrlSetText ">";
        _sideNext ctrlCommit 0;

        private _listLabel = _disp ctrlCreate ["RscText", -1];
        _listLabel ctrlSetPosition [0.35, 0.35, 0.28, 0.025];
        _listLabel ctrlSetText "Configured Buildings";
        _listLabel ctrlCommit 0;

        private _list = _disp ctrlCreate ["RscListbox", -1];
        _list ctrlSetPosition [0.35, 0.39, 0.32, 0.24];
        _list ctrlCommit 0;

        private _spawn = _disp ctrlCreate ["RscButtonMenu", -1];
        _spawn ctrlSetPosition [0.35, 0.66, 0.14, 0.045];
        _spawn ctrlSetText "Spawn";
        _spawn ctrlCommit 0;

        private _cancel = _disp ctrlCreate ["RscButtonMenu", -1];
        _cancel ctrlSetPosition [0.53, 0.66, 0.14, 0.045];
        _cancel ctrlSetText "Cancel";
        _cancel ctrlCommit 0;

        _disp setVariable ["WaldoEcoBuild_SpawnBG", _bg];
        _disp setVariable ["WaldoEcoBuild_SpawnTitle", _title];
        _disp setVariable ["WaldoEcoBuild_SpawnSideLabel", _sideLabel];
        _disp setVariable ["WaldoEcoBuild_SpawnSidePrev", _sidePrev];
        _disp setVariable ["WaldoEcoBuild_SpawnSideValue", _sideValue];
        _disp setVariable ["WaldoEcoBuild_SpawnSideNext", _sideNext];
        _disp setVariable ["WaldoEcoBuild_SpawnListLabel", _listLabel];
        _disp setVariable ["WaldoEcoBuild_SpawnList", _list];
        _disp setVariable ["WaldoEcoBuild_SpawnAction", _spawn];
        _disp setVariable ["WaldoEcoBuild_SpawnCancel", _cancel];
        _disp setVariable ["WaldoEcoBuild_SpawnTargetPos", _pos];
        _disp setVariable ["WaldoEcoBuild_SpawnSideIndex", 0];
        _disp setVariable ["WaldoEcoBuild_SpawnSelectedIndex", 0];
        {
            _x setVariable ["WaldoEcoBuild_ZeusDisplay", _disp];
        } forEach [_sidePrev, _sideNext, _spawn, _cancel];

        _sidePrev setVariable ["WaldoEcoBuild_Delta", -1];
        _sideNext setVariable ["WaldoEcoBuild_Delta", 1];

        _list ctrlAddEventHandler ["LBSelChanged", {
            params ["_ctrl", "_index"];
            private _disp = ctrlParent _ctrl;
            _disp setVariable ["WaldoEcoBuild_SpawnSelectedIndex", _index];
        }];

        {
            _x ctrlAddEventHandler ["ButtonClick", {
                params ["_ctrl"];
                private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
                if (isNull _disp) exitWith {};
                [_disp, _ctrl getVariable ["WaldoEcoBuild_Delta", 0]] call Waldo_fnc_EcoBuild_cycleSpawnBuildingSide;
            }];
        } forEach [_sidePrev, _sideNext];

        _spawn ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (isNull _disp) exitWith {};

            private _catalog = call Waldo_fnc_EcoBuild_getValidBuildCatalog;
            if ((count _catalog) <= 0) exitWith {};

            private _selected = _disp getVariable ["WaldoEcoBuild_SpawnSelectedIndex", 0];
            if (_selected < 0 || {_selected >= count _catalog}) exitWith {};

            private _sideChoices = call Waldo_fnc_EcoBuild_getSpawnBuildingSideChoices;
            private _sideIndex = _disp getVariable ["WaldoEcoBuild_SpawnSideIndex", 0];
            if (_sideIndex < 0 || {_sideIndex >= count _sideChoices}) then {_sideIndex = 0;};

            private _entry = _catalog select _selected;
            private _pos = _disp getVariable ["WaldoEcoBuild_SpawnTargetPos", [0, 0, 0]];

            [_pos, _entry param [0, ""], _sideChoices select _sideIndex] call Waldo_fnc_EcoBuild_spawnConfiguredBuilding;
            [_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;
        }];

        _cancel ctrlAddEventHandler ["ButtonClick", {
            params ["_ctrl"];
            private _disp = _ctrl getVariable ["WaldoEcoBuild_ZeusDisplay", displayNull];
            if (!isNull _disp) then {
                [_disp] call Waldo_fnc_EcoBuild_cleanupSpawnBuildingPrompt;
            };
        }];

        [_disp] call Waldo_fnc_EcoBuild_refreshSpawnBuildingSide;
        [_disp] call Waldo_fnc_EcoBuild_populateSpawnBuildingList;


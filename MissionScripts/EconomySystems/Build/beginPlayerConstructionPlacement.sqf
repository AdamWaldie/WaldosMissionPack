/*
 * Author: Waldo
 * Begin player construction placement.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _source <OBJECT> - source (optional, default: objNull)
 * 1: _buildName <STRING> - build name (optional, default: "")
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_source, _buildName] call Waldo_fnc_EcoBuild_beginPlayerConstructionPlacement;
 */

        params [
            ["_source", objNull],
            ["_buildName", ""]
        ];

        if (!hasInterface || {isNull player}) exitWith {};
        if (isNull _source || {_buildName isEqualTo ""}) exitWith {};
        if (isNil "Waldo_fnc_EcoResource_getSideKeyFromSide") exitWith {};

        private _sideKey = [side group player] call Waldo_fnc_EcoResource_getSideKeyFromSide;
        private _entry = [_buildName] call Waldo_fnc_EcoBuild_getBuildDefinition;
        if ((count _entry) <= 0) exitWith {};

        private _status = [_sideKey, _entry] call Waldo_fnc_EcoBuild_getPlayerBuildStatus;
        if !(_status isEqualTo "build") exitWith {
            hintSilent "Construction unavailable for the selected building.";
        };

        [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;

        private _previewClass = [_entry] call Waldo_fnc_EcoBuild_getBuildSpawnClass;
        private _pos = [] call Waldo_fnc_EcoBuild_getPlayerConstructionAimPos;
        private _dir = getDir player;
        private _preview = createVehicleLocal [_previewClass, _pos, [], 0, "CAN_COLLIDE"];
        _preview setDir _dir;
        _preview setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
        _preview enableSimulation false;
        _preview allowDamage false;

        player setVariable ["WaldoEcoBuild_ConstructionPlacementActive", true];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewObject", _preview];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewBuildName", _buildName];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewSource", _source];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewPos", _pos];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewDir", _dir];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewDirOffset", 0];

        private _beginAction = player addAction [
            "Begin Construction",
            {
                private _buildName = player getVariable ["WaldoEcoBuild_ConstructionPreviewBuildName", ""];
                private _source = player getVariable ["WaldoEcoBuild_ConstructionPreviewSource", objNull];
                private _pos = player getVariable ["WaldoEcoBuild_ConstructionPreviewPos", getPosATL player];
                private _dir = player getVariable ["WaldoEcoBuild_ConstructionPreviewDir", getDir player];

                if (_buildName isNotEqualTo "") then {
                    [_pos, _dir, player, _buildName, _source] call Waldo_fnc_EcoBuild_startPlacedConstruction;
                };

                [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
                hintSilent "Construction order submitted.";
            },
            nil,
            1.6,
            true,
            true,
            "",
            "player getVariable ['WaldoEcoBuild_ConstructionPlacementActive', false]",
            8
        ];
        player setVariable ["WaldoEcoBuild_ConstructionBeginAction", _beginAction];

        private _cancelAction = player addAction [
            "Cancel Construction",
            {
                [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
                hintSilent "Construction placement cancelled.";
            },
            nil,
            1.5,
            true,
            true,
            "",
            "player getVariable ['WaldoEcoBuild_ConstructionPlacementActive', false]",
            8
        ];
        player setVariable ["WaldoEcoBuild_ConstructionCancelAction", _cancelAction];

        private _display = findDisplay 46;
        if (!isNull _display) then {
            private _keyEh = _display displayAddEventHandler ["KeyDown", {
                params ["_display", "_key"];
                if !(player getVariable ["WaldoEcoBuild_ConstructionPlacementActive", false]) exitWith {
                    false
                };

                if (_key isEqualTo 1) exitWith {
                    [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
                    hintSilent "Construction placement cancelled.";
                    true
                };

                if (_key isEqualTo 16 || {_key isEqualTo 18}) exitWith {
                    private _rotationStep = 15;
                    private _offset = player getVariable ["WaldoEcoBuild_ConstructionPreviewDirOffset", 0];
                    if (_key isEqualTo 16) then {
                        _offset = _offset - _rotationStep;
                    } else {
                        _offset = _offset + _rotationStep;
                    };

                    _offset = _offset % 360;
                    if (_offset < 0) then {
                        _offset = _offset + 360;
                    };

                    private _dir = ((getDir player) + _offset) % 360;
                    if (_dir < 0) then {
                        _dir = _dir + 360;
                    };

                    player setVariable ["WaldoEcoBuild_ConstructionPreviewDirOffset", _offset];
                    player setVariable ["WaldoEcoBuild_ConstructionPreviewDir", _dir];

                    private _preview = player getVariable ["WaldoEcoBuild_ConstructionPreviewObject", objNull];
                    if (!isNull _preview) then {
                        _preview setDir _dir;
                    };

                    true
                };

                false
            }];
            player setVariable ["WaldoEcoBuild_ConstructionPlacementDisplay", _display];
            player setVariable ["WaldoEcoBuild_ConstructionPlacementKeyEH", _keyEh];
        };

        [] spawn {
            while {
                hasInterface
                && {!isNull player}
                && {alive player}
                && {[] call Waldo_fnc_EcoCore_isModuleActive}
                && {player getVariable ["WaldoEcoBuild_ConstructionPlacementActive", false]}
            } do {
                private _preview = player getVariable ["WaldoEcoBuild_ConstructionPreviewObject", objNull];
                if (isNull _preview) exitWith {};

                private _pos = [] call Waldo_fnc_EcoBuild_getPlayerConstructionAimPos;
                private _dir = ((getDir player) + (player getVariable ["WaldoEcoBuild_ConstructionPreviewDirOffset", 0])) % 360;
                if (_dir < 0) then {
                    _dir = _dir + 360;
                };
                _preview setDir _dir;
                _preview setVehiclePosition [_pos, [], 0, "CAN_COLLIDE"];
                player setVariable ["WaldoEcoBuild_ConstructionPreviewPos", _pos];
                player setVariable ["WaldoEcoBuild_ConstructionPreviewDir", _dir];

                uiSleep 0.03;
            };

            if (player getVariable ["WaldoEcoBuild_ConstructionPlacementActive", false]) then {
                [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
            };
        };

        hintSilent "Construction placement active. Aim at the build site, press Q/E to rotate, then use Begin Construction. Press Escape or use Cancel Construction to abort.";


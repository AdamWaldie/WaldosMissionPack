/*
 * Author: Waldo
 * Cleanup construction placement local.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_EcoBuild_cleanupConstructionPlacementLocal;
 */

        if (!hasInterface || {isNull player}) exitWith {};

        player setVariable ["WaldoEcoBuild_ConstructionPlacementActive", false];

        private _preview = player getVariable ["WaldoEcoBuild_ConstructionPreviewObject", objNull];
        if (!isNull _preview) then {
            deleteVehicle _preview;
        };
        player setVariable ["WaldoEcoBuild_ConstructionPreviewObject", objNull];

        private _beginAction = player getVariable ["WaldoEcoBuild_ConstructionBeginAction", -1];
        if (_beginAction >= 0) then {
            player removeAction _beginAction;
        };
        player setVariable ["WaldoEcoBuild_ConstructionBeginAction", -1];

        private _cancelAction = player getVariable ["WaldoEcoBuild_ConstructionCancelAction", -1];
        if (_cancelAction >= 0) then {
            player removeAction _cancelAction;
        };
        player setVariable ["WaldoEcoBuild_ConstructionCancelAction", -1];

        private _display = player getVariable ["WaldoEcoBuild_ConstructionPlacementDisplay", displayNull];
        private _keyEh = player getVariable ["WaldoEcoBuild_ConstructionPlacementKeyEH", -1];
        if (!isNull _display && {_keyEh >= 0}) then {
            _display displayRemoveEventHandler ["KeyDown", _keyEh];
        };
        player setVariable ["WaldoEcoBuild_ConstructionPlacementDisplay", displayNull];
        player setVariable ["WaldoEcoBuild_ConstructionPlacementKeyEH", -1];

        player setVariable ["WaldoEcoBuild_ConstructionPreviewBuildName", ""];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewSource", objNull];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewPos", [0, 0, 0]];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewDir", 0];
        player setVariable ["WaldoEcoBuild_ConstructionPreviewDirOffset", 0];


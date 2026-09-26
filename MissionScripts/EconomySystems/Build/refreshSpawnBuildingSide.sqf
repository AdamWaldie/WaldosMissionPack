/*
 * Author: WaldoTheWarfighter
 * Redraws the building-spawn prompt's selected owner-side label.
 *
 * Part of the Waldos Economy Systems suite (Build system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - spawn prompt
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoBuild_refreshSpawnBuildingSide;
 * Locality/Authority: Curator interface client; presentation only.
 * Repeat/JIP Behaviour: Repeat-safe redraw; no JIP state.
 * Current Callers: Building-spawn prompt opening and side arrow controls.
 * Result: Label matches the selected side index.
 */

        params ["_disp"];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuild_getSpawnBuildingSideChoices;
        if ((count _choices) <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuild_SpawnSideIndex", 0];
        if (_index < 0) then {_index = (count _choices) - 1;};
        if (_index >= count _choices) then {_index = 0;};
        _disp setVariable ["WaldoEcoBuild_SpawnSideIndex", _index];

        private _valueCtrl = _disp getVariable ["WaldoEcoBuild_SpawnSideValue", controlNull];
        if (!isNull _valueCtrl) then {
            _valueCtrl ctrlSetText ([(_choices select _index)] call Waldo_fnc_EcoResource_getZoneOwnerLabel);
            _valueCtrl ctrlCommit 0;
        };


/*
 * Author: WaldoTheWarfighter
 * Moves the delivery-point prompt to the next or previous category.
 *
 * Part of the Waldos Economy Systems suite (Buy system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - prompt display (optional, default: displayNull)
 * 1: _delta <NUMBER> - selection step (optional, default: 0)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp, _delta] call Waldo_fnc_EcoBuy_cycleDropPointType;
 * Locality/Authority: Curator interface client; selection only.
 * Repeat/JIP Behaviour: Repeated calls advance the local choice; no JIP state.
 * Current Callers: Delivery-point prompt type arrows.
 * Result: The category preview reflects the newly selected choice.
 */

        params [["_disp", displayNull], ["_delta", 0]];

        if (isNull _disp) exitWith {};

        private _choices = call Waldo_fnc_EcoBuy_getDropPointTypeChoices;
        private _count = count _choices;
        if (_count <= 0) exitWith {};

        private _index = _disp getVariable ["WaldoEcoBuy_DropTypeIndex", 2];
        _index = (_index + _delta) mod _count;
        if (_index < 0) then {_index = _index + _count;};
        _disp setVariable ["WaldoEcoBuy_DropTypeIndex", _index];
        [_disp] call Waldo_fnc_EcoBuy_refreshDropPointType;


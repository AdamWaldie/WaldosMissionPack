/*
 * Author: WaldoTheWarfighter
 * Refreshes the curator prompt's command list and button state.
 *
 * Part of the Waldos Economy Systems suite (Ground Command system).
 *
 * Arguments:
 * 0: _disp <DISPLAY> - prompt display (optional, default: displayNull)
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_disp] call Waldo_fnc_EcoCommand_refreshGroundCommandPrompt;
 * Locality/Authority: Curator interface client only; reads command state without changing it.
 * Repeat/JIP Behaviour: Repeat-safe refresh of the same controls; no JIP UI state.
 * Current Callers: Ground Command prompt setup and Promote/Remove button callbacks.
 * Result: The list and available controls reflect current command membership.
 */

    params [["_disp", displayNull]];

    if (isNull _disp) exitWith {};

    private _list = _disp getVariable ["WaldoEcoCommand_PromptList", controlNull];
    private _promote = _disp getVariable ["WaldoEcoCommand_PromptPromote", controlNull];
    private _remove = _disp getVariable ["WaldoEcoCommand_PromptRemove", controlNull];
    if (isNull _list) exitWith {};

    lbClear _list;

    private _uids = if (isNil "Waldo_fnc_EcoCommand_getGroundCommandUIDs") then {[]} else {call Waldo_fnc_EcoCommand_getGroundCommandUIDs};
    {
        private _key = [_x] call Waldo_fnc_EcoCommand_getGroundCommandKey;
        if (_key isEqualTo "") then {continue;};

        private _label = name _x;
        private _index = _list lbAdd _label;
        _list lbSetData [_index, _key];

        if ((_uids find _key) >= 0) then {
            _list lbSetTextRight [_index, "GC"];
            _list lbSetColor [_index, [0.55, 1, 0.55, 1]];
        };
    } forEach allPlayers;

    private _selected = _disp getVariable ["WaldoEcoCommand_PromptSelectedIndex", 0];
    if (_selected < 0) then {_selected = 0;};
    if (_selected >= lbSize _list) then {_selected = (lbSize _list) - 1;};

    if (_selected >= 0) then {
        _disp setVariable ["WaldoEcoCommand_PromptSelectedIndex", _selected];
        _list lbSetCurSel _selected;
    };

    private _canAct = _selected >= 0 && {_selected < lbSize _list};
    if (!isNull _promote) then {
        _promote ctrlEnable _canAct;
        _promote ctrlCommit 0;
    };
    if (!isNull _remove) then {
        _remove ctrlEnable _canAct;
        _remove ctrlCommit 0;
    };

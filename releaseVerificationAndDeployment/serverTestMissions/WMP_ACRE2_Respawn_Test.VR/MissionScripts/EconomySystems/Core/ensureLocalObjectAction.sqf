/*
 * Author: WaldoTheWarfighter
 * Ensure local object action.
 *
 * Part of the Waldos Economy Systems suite (shared core system).
 *
 * Arguments:
 * 0: _object <OBJECT> - object (optional, default: objNull)
 * 1: _flagVar <STRING> - flag var (optional, default: "")
 * 2: _actionArgs <ARRAY> - action args (optional, default: [])
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [_object, _flagVar, _actionArgs] call Waldo_fnc_EcoCore_ensureLocalObjectAction;
 */

    params [
        ["_object", objNull],
        ["_flagVar", ""],
        ["_actionArgs", []]
    ];

    if (!hasInterface) exitWith {-1};
    if (isNull _object) exitWith {-1};
    if (_flagVar isEqualTo "") exitWith {-1};
    if !(_actionArgs isEqualType []) exitWith {-1};
    private _actionId = _object getVariable [format ["%1_Id", _flagVar], -1];
    private _aceAvailable = isClass (configFile >> "CfgPatches" >> "ace_interact_menu")
        && {!(isNil "ace_interact_menu_fnc_createAction")}
        && {!(isNil "ace_interact_menu_fnc_addActionToObject")};

    // Economy actions share one nested ACE category per object. The linked
    // vanilla route calls the same statement and may be disabled globally by
    // setting Waldo_Interactions_LinkVanillaWithACE to false.
    private _aceFlag = format ["%1_ACE", _flagVar];
    if (_aceAvailable && {!(_object getVariable [_aceFlag, false])}) then {
        if !(_object getVariable ["WaldoEcoCore_ACECategoryInstalled", false]) then {
            private _category = [
                "WaldoEco_Operations",
                "WMP Economy",
                "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa",
                {true},
                {true}
            ] call ace_interact_menu_fnc_createAction;
            private _categoryPath = [_object, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject;
            _object setVariable ["WaldoEcoCore_ACECategoryInstalled", true];
            _object setVariable ["WaldoEcoCore_ACECategoryPath", _categoryPath];
        };
        private _title = _actionArgs param [0, "Interact"];
        private _statement = _actionArgs param [1, {}];
        private _arguments = _actionArgs param [2, []];
        private _conditionText = _actionArgs param [7, "true"];
        private _distance = _actionArgs param [8, 5];
        private _conditionCode = compile _conditionText;
        private _aceAction = [
            format ["WaldoEco_%1", _flagVar],
            _title,
            "\a3\ui_f_oldman\data\IGUI\Cfg\holdactions\repair_ca.paa",
            {
                params ["_target", "_player", "_params"];
                _params params ["_statement", "_arguments"];
                _target setVariable ["WaldoEcoCore_LastLocalActionInvocation", [diag_tickTime, clientOwner, netId _player]];
                diag_log format ["[WMP ECO ACTION] invoked object=%1 actor=%2 clientOwner=%3", netId _target, name _player, clientOwner];
                [_target, _player, -1, _arguments] call _statement;
            },
            {
                params ["_target", "_player", "_params"];
                _params params ["_statement", "_arguments", "_conditionCode", "_distance"];
                (_player distance _target) <= _distance && {_player call _conditionCode}
            },
            {},
            [_statement, _arguments, _conditionCode, _distance],
            [0, 0, 0],
            _distance
        ] call ace_interact_menu_fnc_createAction;
        private _acePath = [_object, 0, ["ACE_MainActions", "WaldoEco_Operations"], _aceAction] call ace_interact_menu_fnc_addActionToObject;
        _object setVariable [_aceFlag, true];
        _object setVariable [format ["%1_ACEPath", _flagVar], _acePath];
        _object setVariable [format ["%1_ACEAction", _flagVar], _aceAction];
        diag_log format ["[WMP ECO ACTION] installed object=%1 flag=%2 path=%3 clientOwner=%4", netId _object, _flagVar, _acePath, clientOwner];
    };
    private _allowLinkedVanilla = missionNamespace getVariable ["Waldo_Interactions_LinkVanillaWithACE", true];
    if (!_aceAvailable || {_allowLinkedVanilla}) then {
        if !(_object getVariable [_flagVar, false]) then {
            _actionId = _object addAction _actionArgs;
            _object setVariable [_flagVar, true];
            _object setVariable [format ["%1_Id", _flagVar], _actionId];
        };
    } else {
        if (_actionId >= 0) then {_object removeAction _actionId;};
        _actionId = -1;
        _object setVariable [_flagVar, false];
        _object setVariable [format ["%1_Id", _flagVar], -1];
    };
    _actionId

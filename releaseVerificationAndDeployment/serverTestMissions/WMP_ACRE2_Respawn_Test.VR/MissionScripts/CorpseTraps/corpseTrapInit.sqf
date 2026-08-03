/*
 * Installs the optional ACE corpse-trap interaction and local inventory listener.
 * Safe to call more than once and on every machine.
 *
 * Return Value:
 * True when installed or intentionally skipped <BOOL>
 */
if (!hasInterface) exitWith {true};
if (missionNamespace getVariable ["Waldo_CorpseTrap_Installed", false]) exitWith {true};
if !(isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) exitWith {
    diag_log "[WMP CORPSE TRAPS] ACE interaction menu is unavailable; feature not installed.";
    false
};

missionNamespace setVariable ["Waldo_CorpseTrap_Installed", true];

private _insertChildren = {
    params ["_target", "_player"];
    private _children = [];

    {
        _x params ["_magazine", "_ammo", "_displayName", "_picture", "_count"];
        private _action = [
            format ["Waldo_CorpseTrap_Throwable_%1", _forEachIndex],
            format ["%1 (%2)", _displayName, _count],
            _picture,
            {
                params ["_target", "_player", "_actionParams"];
                [_target, _player, _actionParams] call Waldo_fnc_CorpseTrapPlant;
            },
            {
                params ["_target", "_player", "_actionParams"];
                _actionParams params ["_magazine"];
                !isNull _target
                    && {!alive _target}
                    && {alive _player}
                    && {_player distance _target <= 3}
                    && {_target getVariable ["Waldo_CorpseTrap_State", ""] == ""}
                    && {_magazine in magazines _player}
            },
            {},
            [_magazine, _ammo],
            "",
            3
        ] call ace_interact_menu_fnc_createAction;
        _children pushBack [_action, [], _target];
    } forEach ([_player] call Waldo_fnc_CorpseTrapGetThrowables);

    _children
};

private _action = [
    "Waldo_CorpseTrap_Rig",
    "Rig Corpse",
    "\a3\ui_f\data\IGUI\Cfg\holdactions\holdAction_connect_ca.paa",
    {},
    {
        params ["_target", "_player"];
        !isNull _target
            && {!alive _target}
            && {alive _player}
            && {_player distance _target <= 3}
            && {_target getVariable ["Waldo_CorpseTrap_State", ""] == ""}
            && {count ([_player] call Waldo_fnc_CorpseTrapGetThrowables) > 0}
    },
    _insertChildren,
    [],
    "pelvis",
    3,
    [false, false, true, false, false]
] call ace_interact_menu_fnc_createAction;

["CAManBase", 0, ["ACE_MainActions"], _action, true] call ace_interact_menu_fnc_addActionToClass;

[player] call Waldo_fnc_CorpseTrapInstallInventoryHandler;
["CAManBase", "Respawn", {
    params ["_unit"];
    if (_unit == player) then {
        [_unit] call Waldo_fnc_CorpseTrapInstallInventoryHandler;
    };
}] call CBA_fnc_addClassEventHandler;

true

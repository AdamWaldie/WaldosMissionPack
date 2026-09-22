/*
 * Author: WaldoTheWarfighter
 * Purpose: Reconciles ACE service actions against the server's complete object-network registry.
 * Locality / Authority: Interface-local only; all world mutations are requested from the server.
 * Repeat / JIP: Removes previously owned ACE paths and installs the current network once per client.
 * Arguments: None. Return Value: <BOOL> setup attempted.
 * Current callers: initPlayerLocal.sqf and Waldo_fnc_BaseServicesRegister broadcast.
 * Example: [] call Waldo_fnc_BaseServicesSetupLocal;
 */
params [["_snapshot", [], [[]]]];
if (!hasInterface || {!(missionNamespace getVariable ["Waldo_BaseServices_Enable", false])}) exitWith {false};
if (isRemoteExecuted && {remoteExecutedOwner isNotEqualTo 2}) exitWith {false};
if (!isRemoteExecuted && {!isServer}) then {
    [player] remoteExecCall ["Waldo_fnc_BaseServicesRequestStateServer", 2];
};
if (isNil "ace_interact_menu_fnc_createAction" || {isNil "ace_interact_menu_fnc_removeActionFromObject"}) exitWith {false};
{
    _x params ["_object", "_paths"];
    if (!isNull _object) then {
        {[_object, 0, _x] call ace_interact_menu_fnc_removeActionFromObject} forEach _paths;
    };
} forEach (missionNamespace getVariable ["Waldo_BaseServices_LocalPaths", []]);
private _installed = [];
private _registry = if (isRemoteExecuted) then {_snapshot} else {
    missionNamespace getVariable ["Waldo_BaseServices_Registry", []]
};
{
    _x params ["_groupId", "_rows"];
    {
        _x params ["_object", "_label", "_services", "_icon"];
        if (!isNull _object) then {
            private _paths = [];
            if ("SAVE" in _services) then {
                private _action = [format ["WMP_BASE_SAVE_%1", _forEachIndex], "Save respawn loadout", _icon,
                    {[_player, _target, "SAVE"] remoteExecCall ["Waldo_fnc_BaseServicesUseServer", 2]},
                    {alive _player && {_player distance _target < 6}}]
                    call ace_interact_menu_fnc_createAction;
                _paths pushBack ([_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject);
            };
            if ("HEAL" in _services && {!isNil "ace_medical_treatment_fnc_fullHeal"}) then {
                private _action = [format ["WMP_BASE_HEAL_%1", _forEachIndex], "Full heal", _icon,
                    {[_player, _target, "HEAL"] remoteExecCall ["Waldo_fnc_BaseServicesUseServer", 2]},
                    {alive _player && {_player distance _target < 6}}] call ace_interact_menu_fnc_createAction;
                _paths pushBack ([_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject);
            };
            if ("SPECTATE" in _services && {!isNil "ace_spectator_fnc_setSpectator"}) then {
                private _action = [format ["WMP_BASE_SPECTATE_%1", _forEachIndex], "Enter spectator", _icon,
                    {[_player, _target, "SPECTATE"] remoteExecCall ["Waldo_fnc_BaseServicesUseServer", 2]},
                    {alive _player && {_player distance _target < 6}}] call ace_interact_menu_fnc_createAction;
                _paths pushBack ([_object, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject);
            };
            if ("TELEPORT" in _services) then {
                private _category = ["WMP_BASE_DEST", "Move to...", _icon, {}, {true}] call ace_interact_menu_fnc_createAction;
                _paths pushBack ([_object, 0, ["ACE_MainActions"], _category] call ace_interact_menu_fnc_addActionToObject);
                private _origin = _object;
                {
                    _x params ["_destination", "_destLabel", "_destServices"];
                    if (_destination isNotEqualTo _origin && {"TELEPORT" in _destServices}) then {
                        private _action = [format ["WMP_BASE_DEST_%1", _forEachIndex], _destLabel, "",
                            {
                                params ["_target", "_player", "_args"];
                                _args params ["_groupId", "_destination"];
                                [_player, _target, _groupId, _destination] remoteExecCall ["Waldo_fnc_BaseServicesTeleportServer", 2];
                            }, {alive _player && {_player distance _target < 6}}, {}, [_groupId, _destination]]
                            call ace_interact_menu_fnc_createAction;
                        _paths pushBack ([_object, 0, ["ACE_MainActions", "WMP_BASE_DEST"], _action] call ace_interact_menu_fnc_addActionToObject);
                    };
                } forEach _rows;
            };
            _installed pushBack [_object, _paths];
        };
    } forEach _rows;
} forEach _registry;
missionNamespace setVariable ["Waldo_BaseServices_LocalPaths", _installed];
true

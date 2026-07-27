/*
 * Author: WaldoTheWarfighter
 * Adds the "Save Respawn Loadout" interaction to the given object on the local machine.
 * ACE and vanilla routes may coexist because the visible vanilla action is a
 * useful discoverability cue. Both routes call the same loadout function.
 * Called via remoteExec (including JIP) from Waldo_fnc_ZenLoadoutSaveModule.
 *
 * Arguments:
 * 0: target <OBJECT> - Object to receive the action
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [someBox] call Waldo_fnc_ZenAddLoadoutSaveAction;
 */

params ["_target"];

if (isNull _target) exitWith {};
if !(hasInterface) exitWith {};

// Prevent duplicate actions if the module is placed on the same object more than once.
// This variable is local because each machine tracks its own action state.
private _aceLoaded = isClass (configFile >> "CfgPatches" >> "ace_interact_menu");
private _aceReady = _aceLoaded
    && {!(isNil "ace_interact_menu_fnc_createAction")}
    && {!(isNil "ace_interact_menu_fnc_addActionToObject")}
    && {!(isNil "ace_common_fnc_canInteractWith")};

if (_aceLoaded && {!_aceReady}) then {
    if !(_target getVariable ["Waldo_LoadoutSaveActionPending", false]) then {
        _target setVariable ["Waldo_LoadoutSaveActionPending", true];
        [_target] spawn {
            params ["_target"];
            waitUntil {uiSleep 0.1; isNull _target || {!(isNil "ace_interact_menu_fnc_createAction")}};
            if (!isNull _target) then {
                _target setVariable ["Waldo_LoadoutSaveActionPending", false];
                [_target] call Waldo_fnc_ZenAddLoadoutSaveAction;
            };
        };
    };
    false
};

if (_aceReady && {!(_target getVariable ["Waldo_LoadoutSaveACEActionInstalled", false])}) then {
    private _action = [
        "Waldo_LoadoutSave", "Save Respawn Loadout",
        "\a3\missions_f_oldman\data\img\holdactions\holdAction_box_ca.paa",
        {[] call Waldo_fnc_SaveLoadout;},
        {params ["_target", "_player"]; alive _player && {_player distance _target < 6} && {[_player, _target, []] call ace_common_fnc_canInteractWith}}
    ] call ace_interact_menu_fnc_createAction;
    private _path = [_target, 0, ["ACE_MainActions"], _action] call ace_interact_menu_fnc_addActionToObject;
    _target setVariable ["Waldo_LoadoutSaveACEActionPath", _path];
    _target setVariable ["Waldo_LoadoutSaveACEActionInstalled", true];
};

if !(_target getVariable ["Waldo_LoadoutSaveVanillaActionInstalled", false]) then {
    private _id = _target addAction [
        "<t color='#00FF00'>Save Respawn Loadout</t>",
        {[] call Waldo_fnc_SaveLoadout;}, nil, 1.5, true, true, "",
        "alive _this && {_this distance _target < 6}", 6
    ];
    _target setVariable ["Waldo_LoadoutSaveVanillaActionId", _id];
    _target setVariable ["Waldo_LoadoutSaveVanillaActionInstalled", _id >= 0];
};

_target setVariable ["Waldo_LoadoutSaveActionAdded", true];
_target setVariable ["Waldo_LoadoutSaveInteractionMode", if (_aceReady) then {"ACE+VANILLA"} else {"VANILLA"}];
diag_log format ["[WMP LOADOUT] Save interaction installed target=%1 mode=%2 clientOwner=%3", netId _target, _target getVariable ["Waldo_LoadoutSaveInteractionMode", "NONE"], clientOwner];
true

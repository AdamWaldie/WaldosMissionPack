/*
 * Author: WaldoTheWarfighter
 * Purpose: Configure WMP convoy control on a selected, crewed AI land vehicle.
 * Locality/authority: curator opens the dialog locally; the server validates the request and controls AI.
 * Repeat/JIP: each placement replaces the group's worker; JIP clients register their own module.
 * Arguments: 0 module position <POSITION>; 1 selected object <OBJECT, default objNull>.
 * Return Value: Nothing.
 * Current callers: WMP AI & Combat ZEN palette registration.
 * Example: [_modulePos, _object] call Waldo_fnc_ZenConvoyModule;
 */
params ["_modulePos", ["_target", objNull]];
if (isClass (configFile >> "CfgPatches" >> "Waldo_AI_Tweaks_Main")) exitWith {};
if (isNull _target || {!(_target isKindOf "LandVehicle")} || {isNull driver _target} || {isPlayer driver _target}) exitWith {
    ["CONVOY NOT CONFIGURED", "Select a crewed AI land vehicle for convoy control.", 8, "FAILURE"] call Waldo_fnc_JammingNotice;
};
private _group = group driver _target;
if (isNull _group) exitWith {};
[
    "AI Convoy - Control",
    [
        ["SLIDER", ["Maximum speed (km/h)", "Speed cap for the lead vehicle."], [5, 120, 30, 0], false],
        ["SLIDER", ["Separation (m)", "Spacing requested between convoy vehicles."], [5, 100, 15, 0], false],
        ["CHECKBOX", ["Push through contact", "Keep the group moving without unloading on contact."], true]
    ],
    {
        params ["_values", "_group"];
        _values params ["_speed", "_separation", "_pushThrough"];
        [_group, round _speed, round _separation, _pushThrough, player] remoteExecCall ["Waldo_fnc_SimpleAiConvoy", 2];
    },
    {},
    _group
] call zen_dialog_fnc_create;

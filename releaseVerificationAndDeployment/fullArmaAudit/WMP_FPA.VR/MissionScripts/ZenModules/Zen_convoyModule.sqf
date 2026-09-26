/*
 * Author: WaldoTheWarfighter
 * Configures or stops the selected AI vehicle group's convoy. Never guesses the nearest vehicle.
 * Locality/authority: interface dialog, authenticated FeatureRuntimeApply server request.
 * Repeat/JIP: configuration replaces the existing registration; server registry replays to HCs.
 * Arguments: 0: module position <ARRAY>; 1: selected vehicle <OBJECT>, default objNull.
 * Return Value: Nothing.
 * Current callers: Zen_initModules convoy registration.
 * Example: [getPosATL truck1, truck1] call Waldo_fnc_ZenConvoyModule;
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target || {!(_target isKindOf "LandVehicle")} || {!alive driver _target}) exitWith {
    ["CONVOY", "Place the module on a crewed AI land vehicle.", "ERROR", "CONVOY"] call Waldo_fnc_FeatureNotifyLocal;
};
[
    "AI Convoy",
    [
        ["COMBO", ["Operation", "Configure replaces this group's settings. Stop restores recorded settings and releases follower paths."], [["START", "STOP"], ["Configure convoy", "Stop convoy"], 0]],
        ["SLIDER", ["Maximum speed (km/h)", "The lead slows for sharp bends and stretched spacing."], [5, 120, 30, 0]],
        ["SLIDER", ["Separation (m)", "Target spacing between vehicle centres; use larger gaps for long vehicles."], [10, 100, 15, 0]],
        ["CHECKBOX", ["Push through contact", "Continue driving in combat. When off, normal combat behaviour takes control."], true]
    ],
    {
        params ["_values", "_target"];
        _values params ["_operation", "_speed", "_separation", "_pushThrough"];
        ["AI_CONVOY", [["target", _target], ["operation", _operation], ["speed", round _speed], ["separation", round _separation], ["pushThrough", _pushThrough]]] call Waldo_fnc_FeatureRuntimeApply;
    }, {}, _target
] call zen_dialog_fnc_create;

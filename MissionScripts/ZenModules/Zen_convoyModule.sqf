/*
 * Author: WaldoTheWarfighter
 * Configures, holds/unloads or releases the selected AI vehicle group's convoy. Never guesses the nearest vehicle.
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
        ["COMBO", ["Operation", "Configure/resume applies travel settings. Stop holds vehicles and dismounts cargo. Release restores prior settings and removes control."], [["START", "STOP", "RELEASE"], ["Configure / resume convoy", "Stop and dismount cargo", "Release controller"], 0]],
        ["SLIDER", ["Maximum speed (km/h)", "The lead slows for sharp bends and stretched spacing."], [5, 120, 30, 0]],
        ["SLIDER", ["Separation (m)", "Minimum centre spacing; vehicle length can increase it. Mixed convoys pace for slower vehicles."], [10, 100, 15, 0]],
        ["CHECKBOX", ["Push through contact", "On: move through contact; stop and dismount cargo if pinned for 15 seconds. Off: stop and dismount cargo on contact. Weapon crew remain mounted."], true]
    ],
    {
        params ["_values", "_target"];
        _values params ["_operation", "_speed", "_separation", "_pushThrough"];
        ["AI_CONVOY", [["target", _target], ["operation", _operation], ["speed", round _speed], ["separation", round _separation], ["pushThrough", _pushThrough]]] call Waldo_fnc_FeatureRuntimeApply;
    }, {}, _target
] call zen_dialog_fnc_create;

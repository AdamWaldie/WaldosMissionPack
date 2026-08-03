/*
 * Author: WaldoTheWarfighter
 * Publishes network-safe Dynamic AA summaries for markers, ZEN removal, diagnostics, and JIP clients.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Array - published summaries
 *
 * Example:
 * [] call Waldo_fnc_DynamicAAPublishState;
 */

if !(isServer) exitWith {[]};
private _registry = missionNamespace getVariable ["Waldo_DynamicAA_Registry", createHashMap];
private _summaries = [];
{
    private _state = _registry get _x;
    private _config = _state get "config";
    _summaries pushBack [
        _x,
        _config get "centre",
        _config get "radius",
        _config get "minimumAltitude",
        _config get "side",
        _state getOrDefault ["active", false],
        _state getOrDefault ["detected", false],
        _state getOrDefault ["radar", objNull]
    ];
} forEach keys _registry;
missionNamespace setVariable ["Waldo_DynamicAA_PublicSystems", _summaries, true];
_summaries

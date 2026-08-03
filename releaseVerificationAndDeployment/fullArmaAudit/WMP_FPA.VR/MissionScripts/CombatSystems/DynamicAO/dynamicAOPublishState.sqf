/*
 * Author: WaldoTheWarfighter
 * Publishes a compact, JIP-safe list of active Dynamic AO systems.
 *
 * Object and group registries stay server-local; clients receive only identifiers, centres,
 * radii, sides, factions, anchors and display names needed by ZEN cleanup and diagnostics. Called after every
 * create, whole-AO cleanup and minefield cleanup operation.
 *
 * Arguments: None
 *
 * Return Value:
 * Array of public AO summaries
 *
 * Current callers: DynamicAOCreate, DynamicAODestroy and DynamicAODestroyMinefield.
 *
 * Example:
 * [] call Waldo_fnc_DynamicAOPublishState;
 */
if !(isServer) exitWith {[]};
private _registry = missionNamespace getVariable ["Waldo_DynamicAO_Registry", createHashMap];
private _summaries = [];
{
    private _state = _registry get _x;
    private _config = _state get "config";
    _summaries pushBack [
        _x, _config get "center", _config get "radius", _config get "side",
        _config get "faction", _state getOrDefault ["anchor", objNull], _config getOrDefault ["displayName", _x]
    ];
} forEach keys _registry;
missionNamespace setVariable ["Waldo_DynamicAO_PublicSystems", _summaries, true];
_summaries

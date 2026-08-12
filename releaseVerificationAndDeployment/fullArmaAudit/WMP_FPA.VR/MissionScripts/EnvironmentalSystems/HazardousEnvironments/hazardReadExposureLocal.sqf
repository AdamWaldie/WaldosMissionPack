/*
 * Author: WaldoTheWarfighter, Val
 * Reads a player's client-owned hazard exposure and reports it to the requesting player through
 * the WMP notification UI. When inspecting another player the call forwards to that target's owner,
 * because exposure intentionally remains local rather than being broadcast every evaluator tick.
 * Locality and authority: reads on the target owner's client and notifies only the requesting player.
 * A self-reading is submitted directly to the local UI. A reading of another network player is
 * relayed through Waldo_fnc_HazardNotifyRequesterServer so the server-only notification endpoint
 * does not reject a client-originated remote call. Readings are transient and are not replayed to
 * JIP clients. Every activation produces a result, including zero measurable exposure.
 *
 * Arguments:
 * 0: target <OBJECT> - player whose exposure is being read.
 * 1: requester <OBJECT> - player receiving the result (default player).
 *
 * Return Value: Boolean - true when handled or forwarded.
 *
 * Example:
 * [cursorTarget, player] call Waldo_fnc_HazardReadExposureLocal;
 * Result: the requester receives a formatted exposure reading without persistent network traffic.
 * Current callers: Hazard Equipment self and target ACE actions.
 */

params [["_target", objNull, [objNull]], ["_requester", player, [objNull]]];
if (isNull _target || {isNull _requester} || {!isPlayer _target}) exitWith {false};
if (remoteExecutedOwner > 2 && {owner _requester != remoteExecutedOwner}) exitWith {false};
if (!local _target) exitWith {
    [_target, _requester] remoteExecCall ["Waldo_fnc_HazardReadExposureLocal", owner _target];
    true
};
private _exposures = missionNamespace getVariable ["Waldo_Hazard_LocalExposure", createHashMap];
// Waldo_Hazard_LocalExposure is keyed by zone runtime key (Waldo_fnc_HazardTick tracks each zone's
// physical dose independently so decay/rate stays per-zone), not by hazard type - resolve each
// zone's configured type/label from the shared registry the same way the live status panel does
// instead of surfacing the raw generated zone key (e.g. "hazard_2_2026_8_10_17_39_45_167_1").
private _zones = missionNamespace getVariable ["Waldo_Hazard_Zones", []];
private _typeAggregates = createHashMap;
{
    _x params ["_key", "_area", "_profile"];
    private _value = _exposures getOrDefault [_key, 0];
    if (_value > 0) then {
        private _type = _profile getOrDefault ["type", _profile getOrDefault ["label", "HAZARD"]];
        private _label = _profile getOrDefault ["label", _type];
        private _entry = _typeAggregates getOrDefault [_type, [_label, 0]];
        _entry set [1, (_entry select 1) + _value];
        _typeAggregates set [_type, _entry];
    };
} forEach _zones;
// Labelled by the hazard TYPE itself (e.g. "RADIATION"), not any one contributing zone's own
// narrative `label` - see hazardTick.sqf's matching status-panel aggregation for why.
private _rows = [];
{
    (_typeAggregates get _x) params ["_label", "_sum"];
    _rows pushBack format ["%1: %2", _x, _sum toFixed 2];
} forEach ((keys _typeAggregates) call BIS_fnc_sortAlphabetically);
private _body = if (_rows isEqualTo []) then {
    format ["%1 has no measurable exposure.", name _target]
} else {
    format ["%1 — %2", name _target, _rows joinString " | "]
};
private _state = if (_rows isEqualTo []) then {"SUCCESS"} else {"WARNING"};
if (local _requester && {hasInterface}) then {
    ["HAZARD DOSIMETER", _body, _state, "HAZARD_DOSIMETER", 6] call Waldo_fnc_FeatureNotifyLocal;
} else {
    [_target, _requester, _body, _state] remoteExecCall ["Waldo_fnc_HazardNotifyRequesterServer", 2];
};
true

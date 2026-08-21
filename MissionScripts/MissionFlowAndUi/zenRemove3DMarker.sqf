/*
 * Author: WaldoTheWarfighter
 * Opens a beginner-friendly ZEN selector for removing a live WMP custom 3D marker. The closest
 * marker is preselected, while every entry shows its label, stable ID and distance.
 *
 * Locality and authority:
 * Curator-interface only. The selected ID is sent through Waldo_fnc_FeatureRuntimeApply, which
 * authenticates the curator and revalidates the live server registry before removal.
 *
 * Repeat/JIP behaviour:
 * The dialog reads the current public registry. Removal is repeat-safe and the resulting registry
 * is broadcast for connected and JIP clients. Marker anchor objects are never deleted.
 *
 * Arguments:
 * 0: module position <ARRAY>
 * 1: selected object <OBJECT> (default objNull; its attached markers sort first)
 * Return Value: Nothing.
 * Current caller: Remove Custom 3D Marker ZEN module.
 *
 * Example: [_modulePos, _objectPos] call Waldo_fnc_ZenRemove3DMarker;
 */
params [["_modulePos", [], [[]]], ["_objectPos", objNull, [objNull]]];
if (!hasInterface) exitWith {};
private _registry = +(missionNamespace getVariable ["Waldo_3DMarker_Registry", []]);
if (_registry isEqualTo []) exitWith {
    ["3D MARKER", "There are no active WMP custom 3D markers to remove.", "INFO", "ZEN_3D_MARKER_REMOVE", 6]
        call Waldo_fnc_FeatureNotifyLocal;
};

private _origin = if (isNull _objectPos) then {+_modulePos} else {getPosATL _objectPos};
private _rows = [];
{
    private _id = _x param [0, ""];
    private _anchor = _x param [1, [], [objNull, []]];
    private _text = _x param [8, ""];
    private _position = if (_anchor isEqualType objNull) then {
        if (isNull _anchor) then {+_origin} else {getPosATL _anchor}
    } else {
        [_anchor param [0, 0], _anchor param [1, 0], _anchor param [2, 0]]
    };
    private _distance = _origin distance2D _position;
    private _sortDistance = if (!isNull _objectPos && {_anchor isEqualType objNull} && {_anchor isEqualTo _objectPos}) then {-1} else {_distance};
    private _label = if (_text == "") then {_id} else {format ["%1 (%2)", _text, _id]};
    _rows pushBack [_sortDistance, _id, format ["%1 - %2 m", _label, round _distance]];
} forEach _registry;
_rows sort true;

[
    "Remove Custom 3D Marker",
    [[
        "COMBO",
        ["Marker to remove", "The closest marker is selected first. The anchor object or fixed position remains untouched."],
        [_rows apply {_x select 1}, _rows apply {_x select 2}, 0],
        false
    ]],
    {
        params ["_values"];
        _values params ["_id"];
        ["REMOVE_3D_MARKER", [_id]] call Waldo_fnc_FeatureRuntimeApply;
    },
    {},
    []
] call zen_dialog_fnc_create;

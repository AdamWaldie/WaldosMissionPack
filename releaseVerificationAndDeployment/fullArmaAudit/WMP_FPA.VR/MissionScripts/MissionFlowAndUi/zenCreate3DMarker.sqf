/*
 * Author: WaldoTheWarfighter
 * Opens a beginner-friendly ZEN dialog for creating one WMP 3D world marker. Curators choose a
 * named icon, colour and audience; no texture path or config classname is required. Dropping the
 * module on an object follows that object, while empty-ground placement creates a fixed marker.
 *
 * Locality and repeat/JIP behaviour:
 * Runs on the curator interface. The submitted marker is created by the server through
 * Waldo_fnc_Create3DMarker and its registry is broadcast for current clients and JIP. Reusing the
 * generated ID is not exposed, so repeated placements intentionally create separate markers.
 *
 * Arguments:
 * 0: module position <ARRAY>
 * 1: selected object <OBJECT> (default objNull)
 * Return Value: Nothing.
 * Current caller: Create Custom 3D Marker ZEN module.
 * Example: [_modulePos, _objectPos] call Waldo_fnc_ZenCreate3DMarker;
 */
params [["_modulePos", [], [[]]], ["_objectPos", objNull, [objNull]]];
if (!hasInterface) exitWith {};

private _icons = [
    ["Objective", "\a3\ui_f\data\map\markers\military\objective_CA.paa"],
    ["Information", "\a3\ui_f\data\map\markers\military\dot_CA.paa"],
    ["Warning", "\a3\ui_f\data\map\markers\military\warning_CA.paa"],
    ["Start point", "\a3\ui_f\data\map\markers\military\start_CA.paa"],
    ["End point", "\a3\ui_f\data\map\markers\military\end_CA.paa"],
    ["Infantry", "\a3\ui_f\data\map\vehicleicons\iconMan_ca.paa"],
    ["Vehicle", "\a3\ui_f\data\map\vehicleicons\iconCar_ca.paa"],
    ["Helicopter", "\a3\ui_f\data\map\vehicleicons\iconHelicopter_ca.paa"],
    ["Aircraft", "\a3\ui_f\data\map\vehicleicons\iconPlane_ca.paa"],
    ["Supply", "\a3\ui_f\data\map\vehicleicons\iconCrate_ca.paa"]
];
private _colours = [
    ["WMP blue", [0.49, 0.78, 1, 0.95]], ["White", [1, 1, 1, 0.95]],
    ["Green", [0.25, 0.9, 0.45, 0.95]], ["Amber", [1, 0.72, 0.18, 0.95]],
    ["Red", [0.95, 0.2, 0.2, 0.95]], ["Purple", [0.75, 0.45, 1, 0.95]]
];
private _sideValues = [["ALL"], [west], [east], [independent], [civilian]];
private _anchor = if (isNull _objectPos) then {+_modulePos} else {_objectPos};
[
    "Create Custom 3D Marker",
    [
        ["EDIT", ["Marker label", "Text displayed beside the icon."], ["POINT OF INTEREST"]],
        ["COMBO", ["Icon", "Choose a readable purpose; WMP supplies the correct image."], [_icons apply {_x select 1}, _icons apply {_x select 0}, 0]],
        ["COMBO", ["Colour", "Colour supplements the icon and text; it is never the only meaning."], [_colours apply {_x select 1}, _colours apply {_x select 0}, 0]],
        ["COMBO", ["Visible to", "Choose which player side can see this world marker."], [_sideValues, ["Everyone", "BLUFOR", "OPFOR", "Independent", "Civilian"], 0]],
        ["SLIDER", ["Height above anchor", "Vertical offset in metres. Use 2-3 m for an object or person."], [0, 20, if (isNull _objectPos) then {0} else {2.5}, 1]],
        ["SLIDER", ["Maximum view distance", "Players farther away than this cannot see the marker."], [10, 2000, 150, 0]],
        ["SLIDER", ["Icon size", "Width and height of the 3D icon."], [0.2, 3, 0.8, 1]]
    ],
    {
        params ["_values", "_anchor"];
        _values params ["_text", "_icon", "_colour", "_sides", "_height", "_distance", "_size"];
        private _id = format ["WMP3D_ZEUS_%1_%2", clientOwner, floor (diag_tickTime * 1000)];
        ["CREATE_3D_MARKER", [_id, _anchor, _text, _icon, _colour, _sides, _height, _distance, _size]]
            call Waldo_fnc_FeatureRuntimeApply;
    },
    {},
    _anchor
] call zen_dialog_fnc_create;

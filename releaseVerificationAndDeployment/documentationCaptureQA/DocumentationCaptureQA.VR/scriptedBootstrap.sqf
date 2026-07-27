/* Disposable documentation-capture bootstrap. Not shipped with the pack. */
private _root = missionNamespace getVariable ["Waldo_DocCapture_Root", ""];
if (_root == "") exitWith {diag_log "WMP DOC CAPTURE ERROR: bootstrap root missing";};
private _functions = call compile preprocessFileLineNumbers (_root + "functionBootstrap.sqf");
{
    _x params ["_name", "_path"];
    missionNamespace setVariable [_name, compile preprocessFileLineNumbers (_root + _path)];
} forEach _functions;
call compile preprocessFileLineNumbers (_root + "captureConfig.sqf");
private _cases = missionNamespace getVariable ["Waldo_DocCapture_Cases", []];
if ((count _cases) > 1) then {
    [] execVM (_root + "runCaptureBatch.sqf");
} else {
    [] execVM (_root + "runCaptureCase.sqf");
};

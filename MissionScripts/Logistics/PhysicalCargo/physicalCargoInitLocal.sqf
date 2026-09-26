/*
 * Author: WaldoTheWarfighter
 * Purpose: Installs the guarded ACE carry-release adapter without extra crate-menu actions.
 * Locality / Authority: Interface client only; mount requests are validated on the server.
 * Repeat / JIP: Idempotent installation; CBA listener survives respawn and an
 *   ordered server snapshot replays current mounts to every joining client.
 *
 * Arguments: None.
 * Return Value: BOOLEAN - true when the listener is installed or already present.
 * Current caller: initPlayerLocal.sqf after the shared logistics settings are ready.
 * Example: [] call Waldo_fnc_PhysicalCargoInitLocal;
 */
if (!hasInterface) exitWith {false};
if (missionNamespace getVariable ["Waldo_PhysicalCargo_LocalInstalled", false]) exitWith {true};
if (isNil "ace_common_fnc_addActionEventHandler" || {isNil "ace_common_fnc_removeActionEventHandler"}
    || {isNil "ace_dragging_fnc_dropObject_carry"} || {isNil "ace_interact_menu_fnc_createAction"}) exitWith {
    diag_log "[WMP PHYSICAL CARGO] ACE carry action API unavailable; native ACE release remains unchanged.";
    false
};

private _id = ["ace_dragging_startedCarry", {
    params ["_unit", "_cargo"];
    if (_unit isNotEqualTo player || {!local _unit} || {isNull _cargo}) exitWith {};
    private _savedMass = _cargo getVariable ["Waldo_PhysicalCargo_OriginalMass", 0];
    if (_savedMass > 0) then {
        _cargo setVariable ["ace_dragging_originalMass", _savedMass, true];
    };
    private _mounted = !isNull (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull]);
    if (!_mounted) then {
        _mounted = ((missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []])
            findIf {(_x select 0) isEqualTo _cargo}) >= 0;
    };
    if (_mounted) then {
        diag_log format ["[WMP PHYSICAL CARGO] ACE pickup requests mount clear: cargo=%1 owner=%2 vehicle=%3.",
            netId _cargo, owner _unit, netId (_cargo getVariable ["Waldo_PhysicalCargo_AttachedVehicle", objNull])];
        [_cargo, _unit] remoteExecCall ["Waldo_fnc_PhysicalCargoClearServer", 2];
    };
    if !(missionNamespace getVariable ["Waldo_PhysicalCargo_Enable", false]) exitWith {};
    if !([_cargo] call Waldo_fnc_PhysicalCargoIsEligible) exitWith {
        diag_log format ["[WMP PHYSICAL CARGO] %1 is not eligible; native ACE release remains.", typeOf _cargo];
    };

    private _aceID = _unit getVariable ["ace_dragging_releaseActionID", -1];
    if (_aceID < 0) exitWith {
        diag_log "[WMP PHYSICAL CARGO] ACE release action ID missing; native ACE release remains unchanged.";
    };

    // Install before removing ACE's callback so an unexpected registration failure never strands
    // the carrier. ACE's own drop function later removes whichever ID is stored in this variable.
    private _wmpID = [
        _unit, "DefaultAction",
        {!isNull ((_this select 1) getVariable ["ace_dragging_carriedObject", objNull])},
        {
            private _actor = _this select 1;
            [_actor, _actor getVariable ["ace_dragging_carriedObject", objNull]] call Waldo_fnc_PhysicalCargoReleaseLocal;
        }
    ] call ace_common_fnc_addActionEventHandler;
    if (_wmpID < 0) exitWith {
        diag_log "[WMP PHYSICAL CARGO] Could not register replacement release; native ACE release remains unchanged.";
    };
    [_unit, "DefaultAction", _aceID] call ace_common_fnc_removeActionEventHandler;
    _unit setVariable ["ace_dragging_releaseActionID", _wmpID];
}] call CBA_fnc_addEventHandler;

missionNamespace setVariable ["Waldo_PhysicalCargo_CarryEH", _id];
missionNamespace setVariable ["Waldo_PhysicalCargo_LocalInstalled", true];
if (isServer) then {
    [missionNamespace getVariable ["Waldo_PhysicalCargo_Mounts", []],
        missionNamespace getVariable ["Waldo_PhysicalCargo_MountRevision", 0]]
        call Waldo_fnc_PhysicalCargoReceiveStateLocal;
} else {
    [player] remoteExecCall ["Waldo_fnc_PhysicalCargoRequestStateServer", 2];
};
true

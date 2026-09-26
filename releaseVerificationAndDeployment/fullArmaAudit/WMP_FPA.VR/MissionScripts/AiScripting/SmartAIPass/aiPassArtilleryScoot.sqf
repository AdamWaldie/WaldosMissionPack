/*
 * Author: WaldoTheWarfighter
 * Moves a mobile battery after the last shell flight and warning interval have elapsed.
 * Locality/authority: documented guards enforce server coordination and owner-local execution.
 * Repeat/JIP: mission tokens reject stale work; server state survives HC migration, not restart.
 * Arguments: 0: battery <OBJECT>, default objNull.
 * Return Value: Nothing.
 * Current callers: ArtilleryMissionStep.
 * Example: [_gun] remoteExecCall ["Waldo_fnc_AIPassArtilleryScoot", owner _gun];
 */
params [["_battery", objNull, [objNull]]];
if (remoteExecutedOwner != 2 || {!local _battery} || {!canMove _battery} || {isNull driver _battery}
    || {!([group driver _battery] call Waldo_fnc_AIPassIsEligible)}
    || {!(missionNamespace getVariable ["Waldo_AIPass_Active", false])} || {[] call Waldo_fnc_AIPassIsPaused}) exitWith {};
private _spot = (getPosATL _battery) getPos [200 + random 150, random 360];
if (!surfaceIsWater _spot) then {[group driver _battery, _spot, 30] call Waldo_fnc_AIPassGroupMove};

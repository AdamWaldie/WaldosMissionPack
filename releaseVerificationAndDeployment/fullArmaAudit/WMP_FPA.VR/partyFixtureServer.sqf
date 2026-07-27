/*
 * Author: WaldoTheWarfighter / OpenAI
 * Creates and registers the real networked party table used by the full audit.
 *
 * Arguments: None
 * Return Value: Nothing
 * Example: [] execVM "partyFixtureServer.sqf";
 */
if (!isServer) exitWith {};
waitUntil {uiSleep 0.1; !isNil "Waldo_MG_fnc_markTableServer"};
private _table = missionNamespace getVariable ["qa_party_table_1", objNull];
if (isNull _table) then {
    _table = createVehicle ["Land_CampingTable_small_F", [-7, 28, 0], [], 0, "CAN_COLLIDE"];
    _table setDir 180;
};
[_table, "Full Audit", "QA-PARTY-TABLE"] call Waldo_MG_fnc_markTableServer;
missionNamespace setVariable ["Waldo_QA_PartyTable", _table, true];
diag_log format ["WMP FULL AUDIT FIXTURE: real party table %1 registered at %2", netId _table, getPosATL _table];

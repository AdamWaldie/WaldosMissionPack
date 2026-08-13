/*
 * Author: WaldoTheWarfighter
 * Enables or disables the curator-only Headless Client ownership overlay. Every AI group leader is
 * labelled in 3D with its real group owner: server, a named connected HC, another network owner, or
 * an ownership mismatch. Colour, icon and text are combined so colour is never the sole signal.
 *
 * Locality and repeat/JIP behaviour:
 * Runs only on curator interface clients. One Draw3D handler is stored and removed repeat-safely.
 * The renderer reads the server-published owner snapshot and HC registry every frame, so migrations
 * appear without rebuilding the overlay. It may install before curator assignment: drawing begins
 * automatically as soon as this player receives Zeus, avoiding the initial-assignment race.
 *
 * Arguments: 0 enabled <BOOL> (default current Waldo_Headless_Debug state).
 * Return Value: Boolean - resulting local overlay state.
 * Current callers: Waldo_fnc_HeadlessDebugToggle and ZEN initialization for JIP curators.
 * Example: [true] call Waldo_fnc_HeadlessDebugDisplayLocal;
 */
params [["_enabled", missionNamespace getVariable ["Waldo_Headless_Debug", false], [true]]];
if (!hasInterface) exitWith {false};
private _old = missionNamespace getVariable ["Waldo_Headless_DebugDrawHandler", -1];
if (_old >= 0) then {removeMissionEventHandler ["Draw3D", _old];};
missionNamespace setVariable ["Waldo_Headless_DebugDrawHandler", -1];
if (!_enabled) exitWith {
    systemChat "[WMP HEADLESS] Ownership overlay disabled.";
    false
};
private _handler = addMissionEventHandler ["Draw3D", {
    if (isNull getAssignedCuratorLogic player) exitWith {};
    private _clients = missionNamespace getVariable ["Waldo_Headless_Clients", []];
    private _managed = missionNamespace getVariable ["Waldo_Headless_ManagedGroups", []];
    private _owners = missionNamespace getVariable ["Waldo_Headless_GroupOwnerSnapshot", []];
    {
        private _group = _x;
        private _leader = leader _group;
        if (!isNull _leader && {!isPlayer _leader} && {side _group != sideLogic}) then {
            private _ownerIndex = _owners findIf {(_x param [0, grpNull]) isEqualTo _group};
            private _owner = if (_ownerIndex >= 0) then {(_owners select _ownerIndex) param [1, -1]} else {-1};
            private _clientIndex = _clients findIf {(_x param [0, -1]) == _owner};
            private _managedIndex = _managed findIf {(_x param [0, grpNull]) isEqualTo _group};
            private _expected = if (_managedIndex >= 0) then {(_managed select _managedIndex) param [1, -1]} else {-1};
            private _mismatch = _expected > 0 && {_expected != _owner};
            private _ownerLabel = if (_owner < 0) then {"OWNER PENDING"} else {if (_owner == 2) then {"SERVER"} else {
                if (_clientIndex >= 0) then {(_clients select _clientIndex) param [1, format ["HC %1", _owner]]} else {format ["OWNER %1", _owner]}
            }};
            private _stateLabel = if (_mismatch) then {format ["MISMATCH expected %1 / actual %2", _expected, _owner]} else {_ownerLabel};
            private _colour = if (_mismatch) then {[1, 0.12, 0.12, 0.95]} else {
                if (_owner == 2) then {[1, 0.62, 0.14, 0.9]} else {if (_clientIndex >= 0) then {[0.2, 0.65, 1, 0.9]} else {[1, 0.9, 0.2, 0.9]}}
            };
            private _position = (getPosASLVisual _leader) vectorAdd [0, 0, 2.2];
            drawIcon3D [
                "\a3\ui_f\data\map\vehicleicons\iconvirtual_ca.paa", _colour, _position,
                0.8, 0.8, 0, format ["%1 | %2 | %3 AI", groupId _group, _stateLabel, count units _group],
                2, 0.027, "RobotoCondensedBold", "center", true
            ];
        };
    } forEach allGroups;
}];
missionNamespace setVariable ["Waldo_Headless_DebugDrawHandler", _handler];
systemChat "[WMP HEADLESS] Ownership overlay enabled: orange=server, blue=HC, yellow=other, red=mismatch.";
true

/*
 * Author: WaldoTheWarfighter
 * Purpose: Establishes the paired-radio groups, respawn and curator before WMP's server init.
 * Locality / Authority: Server only, before the release initServer.sqf.
 * Repeat / JIP: Once at mission start; curator assignment follows player replacement.
 * Arguments: None. Return Value: Nothing.
 * Current caller: generated initServer.sqf pre-hook.
 * Example: call compile preprocessFileLineNumbers "serviceLogisticsTestPreServer.sqf";
 */
if (!isServer) exitWith {};
if !(isNil "acre_alpha_1") then {(group acre_alpha_1) setGroupIdGlobal ["ALPHA"]};
if !(isNil "acre_bravo_1") then {(group acre_bravo_1) setGroupIdGlobal ["BRAVO"]};
private _respawnMarker = createMarker ["respawn_west", [0, -8, 0]];
_respawnMarker setMarkerType "respawn_inf";
_respawnMarker setMarkerColor "ColorWEST";
_respawnMarker setMarkerText "WMP TEST RANGE";
private _curatorGroup = createGroup [sideLogic, true];
acre_test_curator = _curatorGroup createUnit ["ModuleCurator_F", [0, 0, 0], [], 0, "NONE"];
acre_test_curator setVariable ["Addons", 3, true];
acre_test_curator addCuratorAddons activatedAddons;
publicVariable "acre_test_curator";
[] spawn {
    while {true} do {
        private _testers = allPlayers select {!(_x isKindOf "HeadlessClient_F")};
        if (_testers isNotEqualTo []) then {
            private _tester = _testers select 0;
            private _assigned = getAssignedCuratorUnit acre_test_curator;
            if (_assigned != _tester) then {
                if (!isNull _assigned) then {unassignCurator acre_test_curator};
                _tester assignCurator acre_test_curator;
            };
            acre_test_curator addCuratorEditableObjects [allUnits + vehicles, true];
        };
        sleep 1;
    };
};

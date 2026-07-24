/*
 * Author: Waldo / OpenAI
 * Installs deterministic visual-preview actions for the three PR #32 party games.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] execVM "partyPreview.sqf";
 */
if (!hasInterface) exitWith {};
waitUntil {
    uiSleep 0.1;
    !isNull player
        && {!isNil "Waldo_MG_fnc_openDrawPokerLocal"}
        && {!isNil "Waldo_MG_fnc_openLiarsDiceLocal"}
        && {!isNil "Waldo_MG_fnc_openConnectFourLocal"}
};

Waldo_QA_fnc_openPartyPreview = {
    params [["_game", "drawpoker"]];
    call Waldo_MG_fnc_closeTableGameDisplaysLocal;
    private _table = missionNamespace getVariable ["Waldo_QA_PartyPreviewTable", objNull];
    if (isNull _table) then {
        _table = "Land_CampingTable_small_F" createVehicleLocal [0, 0, 0];
        _table hideObject true;
        missionNamespace setVariable ["Waldo_QA_PartyPreviewTable", _table];
    };
    {
        _table setVariable [_x, false];
    } forEach [
        "Waldo_MG_DrawPokerActive",
        "Waldo_MG_LiarsDiceActive",
        "Waldo_MG_ConnectFourActive"
    ];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING"];
    _table setVariable ["Waldo_MG_TableSelectedGame", _game];
    player setVariable ["Waldo_MG_SeatedTable", _table];

    switch _game do {
        case "drawpoker": {
            private _id = "QA-DRAW-POKER";
            _table setVariable ["Waldo_MG_DrawPokerActive", true];
            _table setVariable ["Waldo_MG_DrawPokerGameId", _id];
            _table setVariable ["Waldo_MG_DrawPokerEpoch", 4];
            _table setVariable ["Waldo_MG_DrawPokerRevision", 4];
            _table setVariable ["Waldo_MG_DrawPokerPlayers", [player, objNull, objNull]];
            _table setVariable ["Waldo_MG_DrawPokerPlayerNames", [profileName, "RAVEN 2", "SAPPER 3"]];
            _table setVariable ["Waldo_MG_DrawPokerPhase", "DRAW"];
            _table setVariable ["Waldo_MG_DrawPokerTurn", 0];
            _table setVariable ["Waldo_MG_DrawPokerDealer", 2];
            _table setVariable ["Waldo_MG_DrawPokerChips", [94, 87, 102]];
            _table setVariable ["Waldo_MG_DrawPokerStatuses", ["ACTIVE", "ACTIVE", "ALLIN"]];
            _table setVariable ["Waldo_MG_DrawPokerRoundContrib", [2, 2, 7]];
            _table setVariable ["Waldo_MG_DrawPokerTotalContrib", [3, 3, 8]];
            _table setVariable ["Waldo_MG_DrawPokerCurrentBet", 2];
            _table setVariable ["Waldo_MG_DrawPokerMinRaise", 2];
            _table setVariable ["Waldo_MG_DrawPokerHandNumber", 3];
            _table setVariable ["Waldo_MG_DrawPokerStatus", "DRAW PHASE: select zero to three cards. Zero is STAND PAT."];
            player setVariable ["Waldo_MG_DrawPokerPrivateHand", [_id, 4, [0, 12, 21, 35, 50]]];
            [_table] call Waldo_MG_fnc_openDrawPokerLocal;
        };
        case "liarsdice": {
            private _id = "QA-LIARS-DICE";
            _table setVariable ["Waldo_MG_LiarsDiceActive", true];
            _table setVariable ["Waldo_MG_LiarsDiceGameId", _id];
            _table setVariable ["Waldo_MG_LiarsDiceEpoch", 6];
            _table setVariable ["Waldo_MG_LiarsDiceRevision", 6];
            _table setVariable ["Waldo_MG_LiarsDicePlayers", [player, objNull, objNull]];
            _table setVariable ["Waldo_MG_LiarsDicePlayerNames", [profileName, "VIPER 2", "NOMAD 3"]];
            _table setVariable ["Waldo_MG_LiarsDiceCounts", [5, 4, 3]];
            _table setVariable ["Waldo_MG_LiarsDicePhase", "BIDDING"];
            _table setVariable ["Waldo_MG_LiarsDiceTurn", 0];
            _table setVariable ["Waldo_MG_LiarsDiceBid", [5, 4]];
            _table setVariable ["Waldo_MG_LiarsDiceStatus", "Your turn: raise the bid or challenge five FACE 4 dice."];
            _table setVariable ["Waldo_MG_LiarsDicePublicReveal", []];
            player setVariable ["Waldo_MG_LiarsDicePrivateDice", [_id, 6, [1, 2, 4, 4, 6]]];
            [_table] call Waldo_MG_fnc_openLiarsDiceLocal;
        };
        case "connectfour": {
            _table setVariable ["Waldo_MG_ConnectFourActive", true];
            _table setVariable ["Waldo_MG_ConnectFourGameId", "QA-CONNECT-FOUR"];
            _table setVariable ["Waldo_MG_ConnectFourEpoch", 9];
            _table setVariable ["Waldo_MG_ConnectFourRevision", 9];
            _table setVariable ["Waldo_MG_ConnectFourPlayers", [player, objNull]];
            _table setVariable ["Waldo_MG_ConnectFourPlayerNames", [profileName, "AMBER QA"]];
            _table setVariable ["Waldo_MG_ConnectFourScores", [1, 0]];
            _table setVariable ["Waldo_MG_ConnectFourTurn", 0];
            _table setVariable ["Waldo_MG_ConnectFourPhase", "PLAYING"];
            _table setVariable ["Waldo_MG_ConnectFourReady", [false, false]];
            _table setVariable ["Waldo_MG_ConnectFourBoard", [
                0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,
                0,0,0,0,0,0,0,
                0,0,0,2,0,0,0,
                0,0,1,1,2,0,0,
                0,1,2,1,2,0,0
            ]];
            _table setVariable ["Waldo_MG_ConnectFourStatus", "BLUE O to move. Select a column or press 1-7."];
            [_table] call Waldo_MG_fnc_openConnectFourLocal;
        };
    };
};

player addAction ["QA: Preview Five-Card Draw", { ["drawpoker"] call Waldo_QA_fnc_openPartyPreview; }, nil, 6, false, true, "", "true", 5];
player addAction ["QA: Preview Liar's Dice", { ["liarsdice"] call Waldo_QA_fnc_openPartyPreview; }, nil, 6, false, true, "", "true", 5];
player addAction ["QA: Preview Connect Four", { ["connectfour"] call Waldo_QA_fnc_openPartyPreview; }, nil, 6, false, true, "", "true", 5];
hint "Party-game previews ready. Use the action menu to open Five-Card Draw, Liar's Dice or Connect Four.";

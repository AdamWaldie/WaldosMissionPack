/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Liar's Dice
 * Server-authoritative elimination game. Private dice are owner-targeted and never
 * stored in the public table snapshot outside the timed challenge reveal.
 * Locality/authority: Server rules and dice are authoritative; controls are interface-local.
 * Repeat/JIP: Compiled once per role; named snapshots restore only audience-permitted state.
 * Arguments: None; include fragment.
 * Return Value: Nothing; defines runtime functions.
 * Current callers: Waldo_fnc_MiniGamesEnsureRuntime.
 * Example: [this] call Waldo_fnc_MiniGamesRegisterTable;
 */

Waldo_MG_fnc_liarsDicePublishServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable ["Waldo_MG_LiarsDiceRevision", (_table getVariable ["Waldo_MG_LiarsDiceRevision", 0]) + 1, true];
    _table setVariable ["Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1, true];
};

Waldo_MG_fnc_liarsDiceSendPrivateServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_LiarsDicePlayers", []];
    private _dice = _table getVariable ["Waldo_MG_LiarsDiceDiceServer", []];
    private _gameId = _table getVariable ["Waldo_MG_LiarsDiceGameId", ""];
    private _round = _table getVariable ["Waldo_MG_LiarsDiceRound", 0];
    {
        if (!isNull _x) then {
            _x setVariable ["Waldo_MG_LiarsDicePrivateDice", [_gameId, _round, +(_dice param [_forEachIndex, []])], owner _x];
        };
    } forEach _players;
};

Waldo_MG_fnc_liarsDiceRollRoundServer = {
    params [["_table", objNull], ["_starter", 0]];
    if (!isServer || {isNull _table}) exitWith {};
    private _counts = _table getVariable ["Waldo_MG_LiarsDiceCounts", []];
    private _dice = [];
    {
        private _hand = [];
        for "_die" from 1 to _x do {_hand pushBack (1 + floor random 6);};
        _dice pushBack _hand;
    } forEach _counts;
    private _next = _starter;
    for "_scan" from 0 to ((count _counts) - 1) do {
        private _candidate = (_starter + _scan) mod (count _counts);
        if ((_counts param [_candidate, 0]) > 0) exitWith {_next = _candidate;};
    };
    _table setVariable ["Waldo_MG_LiarsDiceDiceServer", _dice, false];
    _table setVariable ["Waldo_MG_LiarsDicePublicReveal", [], true];
    _table setVariable ["Waldo_MG_LiarsDiceBid", [0, 0], true];
    _table setVariable ["Waldo_MG_LiarsDiceBidder", -1, true];
    _table setVariable ["Waldo_MG_LiarsDiceTurn", _next, true];
    _table setVariable ["Waldo_MG_LiarsDicePhase", "BIDDING", true];
    _table setVariable ["Waldo_MG_LiarsDiceRevealUntil", -1, true];
    _table setVariable ["Waldo_MG_LiarsDiceEpoch", (_table getVariable ["Waldo_MG_LiarsDiceEpoch", 0]) + 1, true];
    private _names = _table getVariable ["Waldo_MG_LiarsDicePlayerNames", []];
    _table setVariable ["Waldo_MG_LiarsDiceStatus", format ["%1 opens the round. Set a legal quantity and face, then BID.", _names param [_next, "Player"]], true];
    [_table] call Waldo_MG_fnc_liarsDiceSendPrivateServer;
    [_table] call Waldo_MG_fnc_liarsDicePublishServer;
};

Waldo_MG_fnc_liarsDiceClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {_x setVariable ["Waldo_MG_LiarsDicePrivateDice", [], owner _x];};
    } forEach (_table getVariable ["Waldo_MG_LiarsDicePlayers", []]);
    _table setVariable ["Waldo_MG_LiarsDiceActive", false, true];
    _table setVariable ["Waldo_MG_LiarsDiceFinished", false, true];
    _table setVariable ["Waldo_MG_LiarsDiceGameId", "", true];
    _table setVariable ["Waldo_MG_LiarsDicePlayers", [], true];
    _table setVariable ["Waldo_MG_LiarsDicePlayerNames", [], true];
    _table setVariable ["Waldo_MG_LiarsDiceSeatIndices", [], true];
    _table setVariable ["Waldo_MG_LiarsDiceCounts", [], true];
    _table setVariable ["Waldo_MG_LiarsDiceDiceServer", [], false];
    _table setVariable ["Waldo_MG_LiarsDicePublicReveal", [], true];
    _table setVariable ["Waldo_MG_LiarsDiceBid", [0,0], true];
    _table setVariable ["Waldo_MG_LiarsDiceReady", [], true];
    [_table] call Waldo_MG_fnc_liarsDicePublishServer;
};

Waldo_MG_fnc_liarsDiceStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "liarsdice" || {(_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY"}) exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = []; private _indices = [];
    {if (!isNull _x) then {_players pushBack _x; _indices pushBack _forEachIndex;};} forEach _seats;
    if ((count _players) < 2 || {(count _players) > 4}) exitWith {false};
    private _counts = []; private _ready = [];
    {_counts pushBack Waldo_MG_CFG_LIARSDICE_STARTING_DICE; _ready pushBack false;} forEach _players;
    _table setVariable ["Waldo_MG_LiarsDiceActive", true, true];
    _table setVariable ["Waldo_MG_LiarsDiceFinished", false, true];
    _table setVariable ["Waldo_MG_LiarsDiceGameId", format ["Waldo_MG_LD_%1_%2", floor (serverTime * 10), floor random 1000000], true];
    _table setVariable ["Waldo_MG_LiarsDicePlayers", _players, true];
    _table setVariable ["Waldo_MG_LiarsDicePlayerNames", _players apply {name _x}, true];
    _table setVariable ["Waldo_MG_LiarsDiceSeatIndices", _indices, true];
    _table setVariable ["Waldo_MG_LiarsDiceCounts", _counts, true];
    _table setVariable ["Waldo_MG_LiarsDiceReady", _ready, true];
    _table setVariable ["Waldo_MG_LiarsDiceRound", 1, true];
    _table setVariable ["Waldo_MG_LiarsDiceEpoch", 0, true];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table, 0] call Waldo_MG_fnc_liarsDiceRollRoundServer;
    true
};

Waldo_MG_fnc_liarsDiceFinishForfeitServer = {
    params [["_table", objNull], ["_unit", objNull], ["_seat", -1]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_LiarsDiceActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_LiarsDicePlayers", []];
    private _role = if (!isNull _unit) then {_players find _unit} else {(_table getVariable ["Waldo_MG_LiarsDiceSeatIndices", []]) find _seat};
    if (_role < 0) exitWith {};
    [_table] call Waldo_MG_fnc_liarsDiceClearServer;
};

Waldo_MG_fnc_liarsDiceReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_LiarsDiceActive", false])}) exitWith {};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = _table getVariable ["Waldo_MG_LiarsDicePlayers", []];
    private _indices = _table getVariable ["Waldo_MG_LiarsDiceSeatIndices", []];
    {
        private _seat = _indices param [_forEachIndex, -1];
        if ((_table getVariable ["Waldo_MG_LiarsDiceCounts", []]) param [_forEachIndex, 0] > 0 && {isNull _x || {_seat < 0} || {_seats param [_seat, objNull] != _x} || {!alive _x}}) then {
            [_table, _x, _seat] call Waldo_MG_fnc_liarsDiceFinishForfeitServer;
        };
    } forEach _players;
};

Waldo_MG_fnc_liarsDiceProgressServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {(_table getVariable ["Waldo_MG_LiarsDicePhase", ""]) != "REVEAL"}) exitWith {};
    if (serverTime < (_table getVariable ["Waldo_MG_LiarsDiceRevealUntil", 1e10])) exitWith {};
    private _loser = _table getVariable ["Waldo_MG_LiarsDiceRoundLoser", -1];
    private _counts = _table getVariable ["Waldo_MG_LiarsDiceCounts", []];
    private _alive = []; {if (_x > 0) then {_alive pushBack _forEachIndex;};} forEach _counts;
    if ((count _alive) <= 1) then {
        private _winner = _alive param [0, -1];
        _table setVariable ["Waldo_MG_LiarsDiceFinished", true, true];
        _table setVariable ["Waldo_MG_LiarsDicePhase", "FINISHED", true];
        _table setVariable ["Waldo_MG_TablePhase", "FINISHED", true];
        _table setVariable ["Waldo_MG_LiarsDiceStatus", format ["%1 is the last player with dice and wins the match.", (_table getVariable ["Waldo_MG_LiarsDicePlayerNames", []]) param [_winner, "Player"]], true];
        [_table] call Waldo_MG_fnc_liarsDicePublishServer;
    } else {
        _table setVariable ["Waldo_MG_LiarsDiceRound", (_table getVariable ["Waldo_MG_LiarsDiceRound", 1]) + 1, true];
        [_table, _loser] call Waldo_MG_fnc_liarsDiceRollRoundServer;
    };
};

Waldo_MG_fnc_processLiarsDiceActionRequestServer = {
    params [["_unit", objNull], ["_request", []]];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 7) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _table = objectFromNetId (_request param [1, ""]);
    private _gameId = _request param [2, ""];
    private _epoch = _request param [3, -1];
    private _action = toUpper (_request param [4, ""]);
    private _quantity = round (_request param [5, 0]);
    private _face = round (_request param [6, 0]);
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])} || {!(_table getVariable ["Waldo_MG_LiarsDiceActive", false])}) exitWith {[_unit,_token,"Liar's Dice request rejected: stale table."] call Waldo_MG_fnc_resultServer;};
    if (_gameId != (_table getVariable ["Waldo_MG_LiarsDiceGameId", ""]) || {_epoch != (_table getVariable ["Waldo_MG_LiarsDiceEpoch", -2])}) exitWith {[_unit,_token,"The round changed; review the current bid."] call Waldo_MG_fnc_resultServer;};
    private _role = (_table getVariable ["Waldo_MG_LiarsDicePlayers", []]) find _unit;
    if (_role < 0) exitWith {[_unit,_token,"Spectators cannot act."] call Waldo_MG_fnc_resultServer;};
    private _phase = _table getVariable ["Waldo_MG_LiarsDicePhase", "BIDDING"];
    if (_action == "SYNC") exitWith {[_table] call Waldo_MG_fnc_liarsDiceSendPrivateServer;[_unit,_token,"Private dice synchronized."] call Waldo_MG_fnc_resultServer;};
    if (_action == "READY") exitWith {
        if (_phase != "FINISHED") exitWith {[_unit,_token,"The match is still active."] call Waldo_MG_fnc_resultServer;};
        private _ready = +(_table getVariable ["Waldo_MG_LiarsDiceReady", []]); _ready set [_role, true];
        _table setVariable ["Waldo_MG_LiarsDiceReady", _ready, true];
        private _all = true; {if (!(_ready param [_forEachIndex,false])) then {_all = false;};} forEach (_table getVariable ["Waldo_MG_LiarsDicePlayers", []]);
        if (_all) then {
            private _counts = []; {_counts pushBack Waldo_MG_CFG_LIARSDICE_STARTING_DICE;} forEach _ready;
            _table setVariable ["Waldo_MG_LiarsDiceCounts", _counts, true]; _table setVariable ["Waldo_MG_LiarsDiceReady", _ready apply {false}, true];
            _table setVariable ["Waldo_MG_LiarsDiceFinished", false, true]; _table setVariable ["Waldo_MG_LiarsDiceRound", 1, true]; _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
            [_table, 0] call Waldo_MG_fnc_liarsDiceRollRoundServer;
        } else {[_table] call Waldo_MG_fnc_liarsDicePublishServer;};
        [_unit,_token,"Ready state recorded."] call Waldo_MG_fnc_resultServer;
    };
    if ((_table getVariable ["Waldo_MG_LiarsDiceCounts", []]) param [_role,0] <= 0) exitWith {[_unit,_token,"Eliminated players cannot bid or challenge."] call Waldo_MG_fnc_resultServer;};
    if (_phase != "BIDDING" || {_role != (_table getVariable ["Waldo_MG_LiarsDiceTurn", -1])}) exitWith {[_unit,_token,"Wait for your turn."] call Waldo_MG_fnc_resultServer;};
    private _bid = _table getVariable ["Waldo_MG_LiarsDiceBid", [0,0]];
    if (_action == "BID") exitWith {
        private _total = 0; {_total = _total + _x;} forEach (_table getVariable ["Waldo_MG_LiarsDiceCounts", []]);
        private _legal = _quantity >= 1 && {_quantity <= _total} && {_face >= 2} && {_face <= 6} && {(_quantity > (_bid param [0,0])) || {_quantity == (_bid param [0,0]) && {_face > (_bid param [1,0])}}};
        if (!_legal) exitWith {[_unit,_token,"Illegal bid: increase quantity, or keep quantity and increase face (2-6)."] call Waldo_MG_fnc_resultServer;};
        private _counts = _table getVariable ["Waldo_MG_LiarsDiceCounts", []]; private _next = _role;
        for "_scan" from 1 to (count _counts) do {private _candidate = (_role + _scan) mod (count _counts); if ((_counts param [_candidate,0]) > 0 && {_next == _role}) then {_next = _candidate;};};
        _table setVariable ["Waldo_MG_LiarsDiceBid", [_quantity,_face], true]; _table setVariable ["Waldo_MG_LiarsDiceBidder", _role, true]; _table setVariable ["Waldo_MG_LiarsDiceTurn", _next, true];
        _table setVariable ["Waldo_MG_LiarsDiceStatus", format ["%1 bids %2 x face %3. %4 must raise or challenge.", name _unit, _quantity, _face, (_table getVariable ["Waldo_MG_LiarsDicePlayerNames", []]) param [_next,"Player"]], true];
        _table setVariable ["Waldo_MG_LiarsDiceEpoch", _epoch + 1, true]; [_table] call Waldo_MG_fnc_liarsDicePublishServer; [_unit,_token,"Bid accepted."] call Waldo_MG_fnc_resultServer;
    };
    if (_action != "CHALLENGE" || {(_bid param [0,0]) <= 0}) exitWith {[_unit,_token,"There is no valid bid to challenge."] call Waldo_MG_fnc_resultServer;};
    private _dice = _table getVariable ["Waldo_MG_LiarsDiceDiceServer", []]; private _matches = 0;
    {{if (_x == 1 || {_x == (_bid param [1,0])}) then {_matches = _matches + 1;};} forEach _x;} forEach _dice;
    private _bidder = _table getVariable ["Waldo_MG_LiarsDiceBidder", -1]; private _loser = if (_matches >= (_bid param [0,0])) then {_role} else {_bidder};
    private _counts = +(_table getVariable ["Waldo_MG_LiarsDiceCounts", []]); _counts set [_loser, ((_counts param [_loser,1]) - 1) max 0];
    _table setVariable ["Waldo_MG_LiarsDiceCounts", _counts, true]; _table setVariable ["Waldo_MG_LiarsDicePublicReveal", _dice, true]; _table setVariable ["Waldo_MG_LiarsDiceRoundLoser", _loser, true];
    _table setVariable ["Waldo_MG_LiarsDicePhase", "REVEAL", true]; _table setVariable ["Waldo_MG_LiarsDiceRevealUntil", serverTime + Waldo_MG_CFG_LIARSDICE_REVEAL_SECONDS, true];
    private _names = _table getVariable ["Waldo_MG_LiarsDicePlayerNames", []]; _table setVariable ["Waldo_MG_LiarsDiceStatus", format ["CHALLENGE: %1 matching dice (ones wild). %2 loses one die.", _matches, _names param [_loser,"Player"]], true];
    _table setVariable ["Waldo_MG_LiarsDiceEpoch", _epoch + 1, true]; [_table] call Waldo_MG_fnc_liarsDicePublishServer; [_unit,_token,"Challenge resolved; dice revealed."] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitLiarsDiceActionLocal = {
    params [["_table",objNull],["_action","BID"],["_quantity",0],["_face",0]];
    if (!hasInterface || {isNull _table}) exitWith {};
    private _token = ["LIARSDICE"] call Waldo_MG_fnc_makeToken;
    private _request = [_token,netId _table,_table getVariable ["Waldo_MG_LiarsDiceGameId",""],_table getVariable ["Waldo_MG_LiarsDiceEpoch",-1],_action,_quantity,_face];
    ["LIARSDICE", _table, _token, _request param [3,-1], _request] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_liarsDiceText = {
    params [["_dice",[]]];
    private _pip = ["","o","o o","o o o","o o / o o","o o / o / o o","o o / o o / o o"];
    private _parts = []; {_parts pushBack format ["[%1] %2", _x, _pip param [_x,""]];} forEach _dice;
    _parts joinString "    "
};

Waldo_MG_fnc_refreshLiarsDiceLocal = {
    disableSerialization; params [["_display",displayNull]]; if (isNull _display) exitWith {};
    private _table = _display getVariable ["Waldo_MG_LiarsDiceTable",objNull]; if (isNull _table) exitWith {_display closeDisplay 1;};
    private _revision = _table getVariable ["Waldo_MG_LiarsDiceRevision",0]; _display setVariable ["Waldo_MG_LiarsDiceLastRevision",_revision];
    private _role = (_table getVariable ["Waldo_MG_LiarsDicePlayers",[]]) find player; private _phase = _table getVariable ["Waldo_MG_LiarsDicePhase","BIDDING"]; private _turn = _table getVariable ["Waldo_MG_LiarsDiceTurn",-1];
    private _private = player getVariable ["Waldo_MG_LiarsDicePrivateDice",[]]; private _ownDice = if ((_private param [0,""]) == (_table getVariable ["Waldo_MG_LiarsDiceGameId",""])) then {_private param [2,[]]} else {[]};
    if (_role>=0 && {(count _ownDice)<((_table getVariable ["Waldo_MG_LiarsDiceCounts",[]]) param [_role,0])} && {(diag_tickTime-(_display getVariable ["Waldo_MG_LiarsDiceLastSync",-10]))>2.5}) then {_display setVariable ["Waldo_MG_LiarsDiceLastSync",diag_tickTime];[_table,"SYNC",0,0] call Waldo_MG_fnc_submitLiarsDiceActionLocal;};
    private _renderKey=[_revision,_private];if (_renderKey isEqualTo (_display getVariable ["Waldo_MG_LiarsDiceRenderKey",[]])) exitWith {};_display setVariable ["Waldo_MG_LiarsDiceRenderKey",_renderKey];
    private _hand = _display getVariable ["Waldo_MG_LiarsDiceHandCtrl",controlNull]; if (!isNull _hand) then {_hand ctrlSetText (if (_role >= 0) then {format ["YOUR DICE  %1", [_ownDice] call Waldo_MG_fnc_liarsDiceText]} else {"SPECTATOR - PRIVATE DICE HIDDEN"});};
    private _bid = _table getVariable ["Waldo_MG_LiarsDiceBid",[0,0]]; private _bidCtrl = _display getVariable ["Waldo_MG_LiarsDiceBidCtrl",controlNull]; if (!isNull _bidCtrl) then {_bidCtrl ctrlSetText (if ((_bid param [0,0]) > 0) then {format ["CURRENT BID   %1 x FACE %2",_bid select 0,_bid select 1]} else {"CURRENT BID   NONE"});};
    private _status = _display getVariable ["Waldo_MG_LiarsDiceStatusCtrl",controlNull]; if (!isNull _status) then {_status ctrlSetText (_table getVariable ["Waldo_MG_LiarsDiceStatus",""]);};
    private _roster = _display getVariable ["Waldo_MG_LiarsDiceRosterCtrl",controlNull]; if (!isNull _roster) then {private _lines=[]; private _names=_table getVariable ["Waldo_MG_LiarsDicePlayerNames",[]]; {private _tag=if (_x<=0) then {"ELIMINATED"} else {if (_forEachIndex==_turn && {_phase=="BIDDING"}) then {"ACTING"} else {"WAITING"}}; _lines pushBack format ["%1 | %2 DICE | %3",_names param [_forEachIndex,"Player"],_x,_tag];} forEach (_table getVariable ["Waldo_MG_LiarsDiceCounts",[]]); _roster ctrlSetStructuredText parseText (_lines joinString "<br/><br/>");};
    private _reveal = _display getVariable ["Waldo_MG_LiarsDiceRevealCtrl",controlNull]; if (!isNull _reveal) then {private _all=[]; {private _name=(_table getVariable ["Waldo_MG_LiarsDicePlayerNames",[]]) param [_forEachIndex,"Player"]; _all pushBack format ["%1: %2",_name,[_x] call Waldo_MG_fnc_liarsDiceText];} forEach (_table getVariable ["Waldo_MG_LiarsDicePublicReveal",[]]); _reveal ctrlSetStructuredText parseText (if (_phase=="REVEAL") then {_all joinString "<br/><br/>"} else {"Dice stay under their cups until a challenge."});};
    private _can = _role >= 0 && {_role == _turn} && {_phase == "BIDDING"}; { _x ctrlEnable _can; } forEach (_display getVariable ["Waldo_MG_LiarsDiceBidControls",[]]);
    private _challenge = _display getVariable ["Waldo_MG_LiarsDiceChallenge",controlNull]; if (!isNull _challenge) then {_challenge ctrlEnable (_can && {(_bid param [0,0]) > 0});};
    private _ready = _display getVariable ["Waldo_MG_LiarsDiceReady",controlNull]; if (!isNull _ready) then {_ready ctrlShow (_role>=0 && {_phase=="FINISHED"});};
};

Waldo_MG_fnc_openLiarsDiceLocal = {
    disableSerialization; params [["_table",objNull],["_spectating",false]];
    if (!hasInterface || {isNull _table} || {!([_table,_spectating] call Waldo_MG_fnc_isValidGameViewerLocal)} || {([_table] call Waldo_MG_fnc_getTableActiveGameId)!="liarsdice"}) exitWith {["No active Liar's Dice match is available."] call Waldo_MG_fnc_notifyLocal;};
    private _parent=findDisplay 46; if (isNull _parent) exitWith {}; call Waldo_MG_fnc_closeTableGameDisplaysLocal; private _display=_parent createDisplay "RscDisplayEmpty"; uiNamespace setVariable ["Waldo_MG_LiarsDiceDisplay",_display];
    _display setVariable ["Waldo_MG_TableGameDisplay",true]; _display setVariable ["Waldo_MG_LiarsDiceTable",_table]; _display setVariable ["Waldo_MG_SpectatorMode",_spectating]; _display setVariable ["Waldo_MG_LiarsDiceLastRevision",-1]; [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _bg=_display ctrlCreate ["RscText",-1]; _bg ctrlSetPosition [safezoneX,safezoneY,safezoneW,safezoneH]; _bg ctrlSetBackgroundColor [0.018,0.014,0.010,0.99]; _bg ctrlCommit 0;
    private _header=_display ctrlCreate ["RscText",-1]; _header ctrlSetPosition [safezoneX,safezoneY,safezoneW,0.08*safezoneH]; _header ctrlSetBackgroundColor [0.20,0.12,0.045,1]; _header ctrlSetText "  WALDOS MINI GAMES  /  LIAR'S DICE"; _header ctrlSetFontHeight (0.032*safezoneH); _header ctrlCommit 0;
    private _hand=_display ctrlCreate ["RscText",-1]; _hand ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.12*safezoneH,0.88*safezoneW,0.10*safezoneH]; _hand ctrlSetBackgroundColor [0.06,0.04,0.025,1]; _hand ctrlSetTextColor [1,0.86,0.58,1]; _hand ctrlSetFontHeight (0.029*safezoneH); _hand ctrlCommit 0;
    private _bid=_display ctrlCreate ["RscText",-1]; _bid ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.25*safezoneH,0.56*safezoneW,0.075*safezoneH]; _bid ctrlSetBackgroundColor [0.12,0.075,0.025,1]; _bid ctrlSetFontHeight (0.028*safezoneH); _bid ctrlCommit 0;
    private _quantity=_display ctrlCreate ["RscCombo",-1]; _quantity ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.35*safezoneH,0.20*safezoneW,0.052*safezoneH]; for "_q" from 1 to 20 do {_quantity lbAdd format ["QUANTITY %1",_q];}; _quantity lbSetCurSel 0; _quantity ctrlCommit 0;
    private _face=_display ctrlCreate ["RscCombo",-1]; _face ctrlSetPosition [safezoneX+0.28*safezoneW,safezoneY+0.35*safezoneH,0.16*safezoneW,0.052*safezoneH]; for "_f" from 2 to 6 do {_face lbAdd format ["FACE %1",_f];}; _face lbSetCurSel 0; _face ctrlCommit 0;
    private _bidButton=_display ctrlCreate ["RscButtonMenu",-1]; _bidButton ctrlSetPosition [safezoneX+0.46*safezoneW,safezoneY+0.35*safezoneH,0.16*safezoneW,0.052*safezoneH]; _bidButton ctrlSetText "PLACE BID"; _bidButton ctrlAddEventHandler ["ButtonClick",{params ["_c"];private _d=ctrlParent _c;private _q=_d getVariable ["Waldo_MG_LiarsDiceQuantity",controlNull];private _f=_d getVariable ["Waldo_MG_LiarsDiceFace",controlNull];[_d getVariable ["Waldo_MG_LiarsDiceTable",objNull],"BID",(lbCurSel _q)+1,(lbCurSel _f)+2] call Waldo_MG_fnc_submitLiarsDiceActionLocal;}]; _bidButton ctrlCommit 0;
    private _challenge=_display ctrlCreate ["RscButtonMenu",-1]; _challenge ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.425*safezoneH,0.56*safezoneW,0.055*safezoneH]; _challenge ctrlSetText "CHALLENGE THE BID"; _challenge ctrlAddEventHandler ["ButtonClick",{params ["_c"];private _d=ctrlParent _c;[_d getVariable ["Waldo_MG_LiarsDiceTable",objNull],"CHALLENGE",0,0] call Waldo_MG_fnc_submitLiarsDiceActionLocal;}]; _challenge ctrlCommit 0;
    private _reveal=_display ctrlCreate ["RscStructuredText",-1]; _reveal ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.51*safezoneH,0.56*safezoneW,0.20*safezoneH]; _reveal ctrlSetBackgroundColor [0.035,0.028,0.02,1]; _reveal ctrlCommit 0;
    private _roster=_display ctrlCreate ["RscStructuredText",-1]; _roster ctrlSetPosition [safezoneX+0.66*safezoneW,safezoneY+0.25*safezoneH,0.28*safezoneW,0.38*safezoneH]; _roster ctrlSetBackgroundColor [0.045,0.035,0.025,1]; _roster ctrlCommit 0;
    private _rules=_display ctrlCreate ["RscStructuredText",-1]; _rules ctrlSetPosition [safezoneX+0.66*safezoneW,safezoneY+0.65*safezoneH,0.28*safezoneW,0.16*safezoneH]; _rules ctrlSetStructuredText parseText "<t color='#E8C478'>PROCEDURE</t><br/>Raise quantity, or keep quantity and raise face 2-6.<br/>Ones are wild. Challenge when the bid is too high.<br/>The losing side removes one die."; _rules ctrlCommit 0;
    private _ready=_display ctrlCreate ["RscButtonMenu",-1]; _ready ctrlSetPosition [safezoneX+0.66*safezoneW,safezoneY+0.82*safezoneH,0.18*safezoneW,0.05*safezoneH]; _ready ctrlSetText "READY REMATCH"; _ready ctrlAddEventHandler ["ButtonClick",{params ["_c"];private _d=ctrlParent _c;[_d getVariable ["Waldo_MG_LiarsDiceTable",objNull],"READY",0,0] call Waldo_MG_fnc_submitLiarsDiceActionLocal;}]; _ready ctrlCommit 0;
    private _leave=_display ctrlCreate ["RscButtonMenu",-1]; _leave ctrlSetPosition [safezoneX+0.85*safezoneW,safezoneY+0.82*safezoneH,0.09*safezoneW,0.05*safezoneH]; _leave ctrlSetText "EXIT"; _leave ctrlAddEventHandler ["ButtonClick",{params ["_c"];[_c] call Waldo_MG_fnc_handleViewerExitButtonLocal;}]; _leave ctrlCommit 0;
    private _status=_display ctrlCreate ["RscText",-1]; _status ctrlSetPosition [safezoneX+0.06*safezoneW,safezoneY+0.86*safezoneH,0.56*safezoneW,0.065*safezoneH]; _status ctrlSetBackgroundColor [0.12,0.075,0.025,1]; _status ctrlSetFontHeight (0.018*safezoneH); _status ctrlCommit 0;
    _display setVariable ["Waldo_MG_LiarsDiceHandCtrl",_hand]; _display setVariable ["Waldo_MG_LiarsDiceBidCtrl",_bid]; _display setVariable ["Waldo_MG_LiarsDiceQuantity",_quantity]; _display setVariable ["Waldo_MG_LiarsDiceFace",_face]; _display setVariable ["Waldo_MG_LiarsDiceBidControls",[_quantity,_face,_bidButton]]; _display setVariable ["Waldo_MG_LiarsDiceChallenge",_challenge]; _display setVariable ["Waldo_MG_LiarsDiceRevealCtrl",_reveal]; _display setVariable ["Waldo_MG_LiarsDiceRosterCtrl",_roster]; _display setVariable ["Waldo_MG_LiarsDiceReady",_ready]; _display setVariable ["Waldo_MG_LiarsDiceStatusCtrl",_status];
    [_display] call Waldo_MG_fnc_refreshLiarsDiceLocal; [_display] spawn {disableSerialization;params ["_d"];while {!isNull _d} do {[_d] call Waldo_MG_fnc_refreshLiarsDiceLocal;uiSleep Waldo_MG_CFG_LIARSDICE_UI_TICK;};};
};

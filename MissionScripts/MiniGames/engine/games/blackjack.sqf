/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Blackjack
 * All Waldo_MG_fnc_* functions implementing the Blackjack mini game (server logic + local UI).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is maintained as part of the WMP party-game framework.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included lazily by Waldo_fnc_MiniGamesEnsureRuntime.
 * It is not a standalone CfgFunctions entry and is not called directly.
 * Locality/authority: Server rule helpers and interface presentation helpers execute only in their
 * matching lazily compiled role; headless clients do not compile this fragment.
 * Repeat/JIP: The versioned role runtime compiles it once per machine. Named state requests provide
 * JIP replay without transmitting executable code.
 * Arguments: None; include fragment.
 * Return Value: Nothing; defines runtime values/functions.
 * Current callers: Waldo_fnc_MiniGamesEnsureRuntime during first explicit table registration.
 * Example: [this] call Waldo_fnc_MiniGamesRegisterTable;
 */

Waldo_MG_fnc_blackjackCreateShoeServer = {
    private _source = [];
    for "_deck" from 1 to Waldo_MG_CFG_BLACKJACK_DECKS do {
        for "_card" from 0 to 51 do {
            _source pushBack _card;
        };
    };
    private _shoe = [];
    while {(count _source) > 0} do {
        private _pick = floor (random (count _source));
        _shoe pushBack (_source deleteAt _pick);
    };
    _shoe
};

Waldo_MG_fnc_blackjackHandValue = {
    params [["_handSource", []]];
    private _total = 0;
    private _softAces = 0;
    {
        private _rank = [_x] call Waldo_MG_fnc_pokerCardRank;
        if (_rank == 14) then {
            _total = _total + 11;
            _softAces = _softAces + 1;
        } else {
            _total = _total + (_rank min 10);
        };
    } forEach _handSource;
    while {_total > 21 && {_softAces > 0}} do {
        _total = _total - 10;
        _softAces = _softAces - 1;
    };
    [_total, _softAces > 0]
};

Waldo_MG_fnc_blackjackIsNatural = {
    params [["_hand", []]];
    (count _hand) == 2 && {(([_hand] call Waldo_MG_fnc_blackjackHandValue) param [0, 0]) == 21}
};

Waldo_MG_fnc_blackjackCreateEmptySnapshot = {
    params [
        ["_count", 0],
        ["_stacksSource", []]
    ];
    private _stacks = [];
    private _numbers = [];
    private _hands = [];
    private _statuses = [];
    private _actions = [];
    private _booleans = [];
    for "_role" from 0 to (_count - 1) do {
        _stacks pushBack (_stacksSource param [_role, Waldo_MG_CFG_BLACKJACK_STARTING_CHIPS]);
        _numbers pushBack 0;
        _hands pushBack [];
        _statuses pushBack "BETTING";
        _actions pushBack "Choose an even bet";
        _booleans pushBack false;
    };
    [
        "IDLE", 0, -1, _stacks, +_numbers, _hands, +_numbers, _statuses,
        _actions, [], 0, false, false, "Waiting for Blackjack.", +_numbers,
        _booleans, 0
    ]
};

Waldo_MG_fnc_blackjackPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table, "Waldo_MG_BlackjackRevision", (_table getVariable ["Waldo_MG_BlackjackRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
};

Waldo_MG_fnc_blackjackSetSnapshotServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table} || {(typeName _snapshot) != "ARRAY"}) exitWith {};
    _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _snapshot];
    [_table, "Waldo_MG_BlackjackSnapshot", _snapshot] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_blackjackPublishRevisionServer;
};

Waldo_MG_fnc_blackjackClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table, "Waldo_MG_BlackjackActive", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackGameId", ""] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackPlayers", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackPlayerNames", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackSeatIndices", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackEpoch", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackDealerNextAt", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_BlackjackShoeServer", []];
    _table setVariable ["Waldo_MG_BlackjackDealerHandServer", []];
    _table setVariable ["Waldo_MG_BlackjackSnapshotServer", [] call Waldo_MG_fnc_blackjackCreateEmptySnapshot];
    [_table, "Waldo_MG_BlackjackSnapshot", [] call Waldo_MG_fnc_blackjackCreateEmptySnapshot] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_blackjackPublishRevisionServer;
};

Waldo_MG_fnc_blackjackGetNextPlayingRole = {
    params [
        ["_after", -1],
        ["_statuses", []]
    ];
    private _count = count _statuses;
    if (_count <= 0) exitWith {-1};
    private _found = -1;
    for "_offset" from 1 to _count do {
        private _candidate = (_after + _offset) mod _count;
        if (_found < 0 && {(_statuses param [_candidate, "LEFT"]) == "PLAYING"}) then {
            _found = _candidate;
        };
    };
    _found
};

Waldo_MG_fnc_blackjackAllBetsReadyServer = {
    params [["_snapshot", []]];
    private _statuses = _snapshot param [7, []];
    private _eligible = 0;
    private _ready = 0;
    {
        if (_x in ["BETTING", "READY"]) then {
            _eligible = _eligible + 1;
            if (_x == "READY") then {_ready = _ready + 1;};
        };
    } forEach _statuses;
    _eligible > 0 && {_ready == _eligible}
};

Waldo_MG_fnc_blackjackAllNextReadyServer = {
    params [["_snapshot", []]];
    private _stacks = _snapshot param [3, []];
    private _statuses = _snapshot param [7, []];
    private _nextReady = _snapshot param [15, []];
    private _eligible = 0;
    private _ready = 0;
    for "_role" from 0 to ((count _statuses) - 1) do {
        if ((_statuses param [_role, "LEFT"]) != "LEFT" && {(_stacks param [_role, 0]) >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET}) then {
            _eligible = _eligible + 1;
            if (_nextReady param [_role, false]) then {_ready = _ready + 1;};
        };
    };
    _eligible > 0 && {_ready == _eligible}
};

Waldo_MG_fnc_blackjackPrepareBettingServer = {
    params [
        ["_table", objNull],
        ["_incrementRound", true]
    ];
    if (!isServer || {isNull _table}) exitWith {false};
    private _state = +(_table getVariable ["Waldo_MG_BlackjackSnapshotServer", []]);
    private _stacks = +(_state param [3, []]);
    private _oldStatuses = +(_state param [7, []]);
    private _count = count _stacks;
    private _bets = [];
    private _hands = [];
    private _totals = [];
    private _statuses = [];
    private _actions = [];
    private _results = [];
    private _nextReady = [];
    private _eligible = 0;
    for "_role" from 0 to (_count - 1) do {
        private _left = (_oldStatuses param [_role, "LEFT"]) == "LEFT";
        private _playable = !_left && {(_stacks param [_role, 0]) >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET};
        _bets pushBack 0;
        _hands pushBack [];
        _totals pushBack 0;
        _results pushBack 0;
        _nextReady pushBack false;
        if (_left) then {
            _statuses pushBack "LEFT";
            _actions pushBack "Left table";
        } else {
            if (_playable) then {
                _eligible = _eligible + 1;
                _statuses pushBack "BETTING";
                _actions pushBack "Choose an even bet";
            } else {
                _statuses pushBack "BROKE";
                _actions pushBack "No playable chips";
            };
        };
    };
    if (_eligible <= 0) exitWith {
        _state set [0, "SESSION_END"];
        _state set [2, -1];
        _state set [7, _statuses];
        _state set [8, _actions];
        _state set [13, "No seated player has enough chips for the minimum bet. The dealer wins the session."];
        _state set [15, _nextReady];
        [_table, "Waldo_MG_BlackjackFinished", true] call Waldo_MG_fnc_setPublicTableStateServer;
        _table setVariable ["Waldo_MG_TablePhase", "FINISHED",true];
        [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
        false
    };
    private _round = _state param [1, 0];
    if (_incrementRound) then {_round = _round + 1;};
    _state set [0, "BETTING"];
    _state set [1, _round];
    _state set [2, -1];
    _state set [4, _bets];
    _state set [5, _hands];
    _state set [6, _totals];
    _state set [7, _statuses];
    _state set [8, _actions];
    _state set [9, []];
    _state set [10, 0];
    _state set [11, false];
    _state set [12, false];
    _state set [13, format ["Round %1: every active player must place an even bet.", _round]];
    _state set [14, _results];
    _state set [15, _nextReady];
    _state set [16, count (_table getVariable ["Waldo_MG_BlackjackShoeServer", []])];
    _table setVariable ["Waldo_MG_BlackjackDealerHandServer", []];
    [_table, "Waldo_MG_BlackjackDealerNextAt", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackEpoch", (_table getVariable ["Waldo_MG_BlackjackEpoch", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
    true
};

Waldo_MG_fnc_blackjackStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "blackjack") exitWith {false};
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY") exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = [];
    private _names = [];
    private _seatIndices = [];
    for "_seat" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_seat, objNull];
        if (!isNull _unit) then {
            _players pushBack _unit;
            _names pushBack (name _unit);
            _seatIndices pushBack _seat;
        };
    };
    private _count = count _players;
    if (_count < 1 || {_count > 4}) exitWith {false};
    private _stacks = [];
    for "_role" from 0 to (_count - 1) do {
        _stacks pushBack Waldo_MG_CFG_BLACKJACK_STARTING_CHIPS;
    };
    private _state = [_count, _stacks] call Waldo_MG_fnc_blackjackCreateEmptySnapshot;
    _state set [0, "BETTING"];
    _state set [1, 1];
    _state set [13, "Round 1: every active player must place an even bet."];
    private _shoe = call Waldo_MG_fnc_blackjackCreateShoeServer;
    _state set [16, count _shoe];
    [_table, "Waldo_MG_BlackjackActive", true] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackGameId", format ["Waldo_MG_BLACKJACK_%1_%2", floor (serverTime * 10), floor (random 1000000)]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackPlayers", _players] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackPlayerNames", _names] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackSeatIndices", _seatIndices] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackEpoch", 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_BlackjackDealerNextAt", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_BlackjackShoeServer", _shoe];
    _table setVariable ["Waldo_MG_BlackjackDealerHandServer", []];
    _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _state];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING",true];
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
    true
};

Waldo_MG_fnc_blackjackSettleRoundServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _stacks = +(_state param [3, []]);
    private _bets = +(_state param [4, []]);
    private _hands = +(_state param [5, []]);
    private _totals = +(_state param [6, []]);
    private _statuses = +(_state param [7, []]);
    private _actions = +(_state param [8, []]);
    private _dealerHand = +(_table getVariable ["Waldo_MG_BlackjackDealerHandServer", []]);
    private _dealerValue = [_dealerHand] call Waldo_MG_fnc_blackjackHandValue;
    private _dealerTotal = _dealerValue param [0, 0];
    private _dealerSoft = _dealerValue param [1, false];
    private _dealerNatural = [_dealerHand] call Waldo_MG_fnc_blackjackIsNatural;
    private _dealerBust = _dealerTotal > 21;
    private _results = [];
    private _nextReady = [];
    private _playableRemaining = 0;
    for "_role" from 0 to ((count _statuses) - 1) do {
        private _status = _statuses param [_role, "LEFT"];
        private _bet = _bets param [_role, 0];
        private _result = 0;
        if (_status != "LEFT" && {_bet > 0}) then {
            private _hand = _hands param [_role, []];
            private _playerTotal = _totals param [_role, 0];
            private _natural = [_hand] call Waldo_MG_fnc_blackjackIsNatural;
            if (_status == "BUST") then {
                _statuses set [_role, "LOSE"];
                _actions set [_role, format ["Bust - lost %1", _bet]];
                _result = -_bet;
            } else {
                if (_natural) then {
                    if (_dealerNatural) then {
                        _stacks set [_role, (_stacks param [_role, 0]) + _bet];
                        _statuses set [_role, "PUSH"];
                        _actions set [_role, format ["Blackjack push - %1 returned", _bet]];
                    } else {
                        private _profit = (_bet * 3) / 2;
                        _stacks set [_role, (_stacks param [_role, 0]) + _bet + _profit];
                        _statuses set [_role, "BLACKJACK"];
                        _actions set [_role, format ["BLACKJACK +%1", _profit]];
                        _result = _profit;
                    };
                } else {
                    if (_dealerNatural) then {
                        _statuses set [_role, "LOSE"];
                        _actions set [_role, format ["Dealer Blackjack - lost %1", _bet]];
                        _result = -_bet;
                    } else {
                        if (_dealerBust || {_playerTotal > _dealerTotal}) then {
                            _stacks set [_role, (_stacks param [_role, 0]) + (2 * _bet)];
                            _statuses set [_role, "WIN"];
                            _actions set [_role, format ["Won +%1", _bet]];
                            _result = _bet;
                        } else {
                            if (_playerTotal == _dealerTotal) then {
                                _stacks set [_role, (_stacks param [_role, 0]) + _bet];
                                _statuses set [_role, "PUSH"];
                                _actions set [_role, format ["Push - %1 returned", _bet]];
                            } else {
                                _statuses set [_role, "LOSE"];
                                _actions set [_role, format ["Lost %1", _bet]];
                                _result = -_bet;
                            };
                        };
                    };
                };
            };
        };
        if (_status != "LEFT" && {(_stacks param [_role, 0]) >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET}) then {
            _playableRemaining = _playableRemaining + 1;
        };
        _results pushBack _result;
        _nextReady pushBack false;
    };
    private _dealerDescription = if (_dealerNatural) then {
        "Dealer has Blackjack."
    } else {
        if (_dealerBust) then {format ["Dealer busts on %1.", _dealerTotal]} else {format ["Dealer stands on %1%2.", if (_dealerSoft) then {"soft "} else {""}, _dealerTotal]}
    };
    private _phase = "ROUND_END";
    private _statusText = format ["%1 Round %2 settled. Ready up when you want another hand.", _dealerDescription, _state param [1, 1]];
    if (_playableRemaining <= 0) then {
        _phase = "SESSION_END";
        _statusText = format ["%1 No seated player can cover the minimum bet; the session is over.", _dealerDescription];
        [_table, "Waldo_MG_BlackjackFinished", true] call Waldo_MG_fnc_setPublicTableStateServer;
        _table setVariable ["Waldo_MG_TablePhase", "FINISHED",true];
    };
    _state set [0, _phase];
    _state set [2, -1];
    _state set [3, _stacks];
    _state set [7, _statuses];
    _state set [8, _actions];
    _state set [9, _dealerHand];
    _state set [10, _dealerTotal];
    _state set [11, _dealerSoft];
    _state set [12, false];
    _state set [13, _statusText];
    _state set [14, _results];
    _state set [15, _nextReady];
    _state set [16, count (_table getVariable ["Waldo_MG_BlackjackShoeServer", []])];
    [_table, "Waldo_MG_BlackjackDealerNextAt", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
};

Waldo_MG_fnc_blackjackBeginDealerServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _statuses = _state param [7, []];
    private _needsDealer = false;
    {
        if (_x == "STAND") then {_needsDealer = true;};
    } forEach _statuses;
    if (!_needsDealer) exitWith {
        [_table, _state] call Waldo_MG_fnc_blackjackSettleRoundServer;
    };
    private _dealerHand = +(_table getVariable ["Waldo_MG_BlackjackDealerHandServer", []]);
    private _dealerValue = [_dealerHand] call Waldo_MG_fnc_blackjackHandValue;
    _state set [0, "DEALER_TURN"];
    _state set [2, -1];
    _state set [9, _dealerHand];
    _state set [10, _dealerValue param [0, 0]];
    _state set [11, _dealerValue param [1, false]];
    _state set [12, false];
    _state set [13, format ["Dealer reveals %1 and will draw to 17.", _dealerValue param [0, 0]]];
    [_table, "Waldo_MG_BlackjackDealerNextAt", serverTime + Waldo_MG_CFG_BLACKJACK_DEALER_STEP_SECONDS] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
};

Waldo_MG_fnc_blackjackAdvanceAfterActionServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_afterRole", -1]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _statuses = _state param [7, []];
    private _next = [_afterRole, _statuses] call Waldo_MG_fnc_blackjackGetNextPlayingRole;
    if (_next >= 0) then {
        private _names = _table getVariable ["Waldo_MG_BlackjackPlayerNames", []];
        _state set [0, "PLAYER_TURNS"];
        _state set [2, _next];
        _state set [13, format ["%1 must Hit, Stand or Double.", _names param [_next, "Player"]]];
        [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
    } else {
        [_table, _state] call Waldo_MG_fnc_blackjackBeginDealerServer;
    };
};

Waldo_MG_fnc_blackjackDealServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    private _state = +(_table getVariable ["Waldo_MG_BlackjackSnapshotServer", []]);
    if ((_state param [0, ""]) != "BETTING") exitWith {false};
    private _statuses = +(_state param [7, []]);
    private _active = [];
    {
        _active pushBack (_x == "READY");
    } forEach _statuses;
    if (({_x} count _active) <= 0) exitWith {false};
    private _shoe = +(_table getVariable ["Waldo_MG_BlackjackShoeServer", []]);
    if ((count _shoe) < Waldo_MG_CFG_BLACKJACK_CUT_REMAINING) then {
        _shoe = call Waldo_MG_fnc_blackjackCreateShoeServer;
    };
    private _count = count _statuses;
    private _hands = [];
    private _totals = [];
    private _actions = [];
    private _oldActions = _state param [8, []];
    for "_role" from 0 to (_count - 1) do {
        _hands pushBack [];
        _totals pushBack 0;
        _actions pushBack (if (_active param [_role, false]) then {"Dealt in"} else {_oldActions param [_role, "Waiting"]});
    };
    private _dealerHand = [];
    for "_pass" from 1 to 2 do {
        for "_role" from 0 to (_count - 1) do {
            if (_active param [_role, false]) then {
                private _hand = +(_hands param [_role, []]);
                _hand pushBack (_shoe deleteAt ((count _shoe) - 1));
                _hands set [_role, _hand];
            };
        };
        _dealerHand pushBack (_shoe deleteAt ((count _shoe) - 1));
    };
    for "_role" from 0 to (_count - 1) do {
        if (_active param [_role, false]) then {
            private _hand = _hands param [_role, []];
            private _value = [_hand] call Waldo_MG_fnc_blackjackHandValue;
            _totals set [_role, _value param [0, 0]];
            if ([_hand] call Waldo_MG_fnc_blackjackIsNatural) then {
                _statuses set [_role, "BLACKJACK"];
                _actions set [_role, "Natural Blackjack"];
            } else {
                _statuses set [_role, "PLAYING"];
                _actions set [_role, format ["Playing on %1", _value param [0, 0]]];
            };
        };
    };
    private _dealerValue = [_dealerHand] call Waldo_MG_fnc_blackjackHandValue;
    private _dealerVisible = [_dealerHand param [0, -1], -2];
    _table setVariable ["Waldo_MG_BlackjackShoeServer", _shoe];
    _table setVariable ["Waldo_MG_BlackjackDealerHandServer", _dealerHand];
    _state set [0, "PLAYER_TURNS"];
    _state set [2, -1];
    _state set [5, _hands];
    _state set [6, _totals];
    _state set [7, _statuses];
    _state set [8, _actions];
    _state set [9, _dealerVisible];
    _state set [10, ([[_dealerHand param [0, -1]]] call Waldo_MG_fnc_blackjackHandValue) param [0, 0]];
    _state set [11, false];
    _state set [12, true];
    _state set [13, format ["Cards dealt. Dealer shows %1.", [_dealerHand param [0, -1]] call Waldo_MG_fnc_pokerCardName]];
    _state set [16, count _shoe];
    if ([_dealerHand] call Waldo_MG_fnc_blackjackIsNatural) exitWith {
        [_table, _state] call Waldo_MG_fnc_blackjackSettleRoundServer;
        true
    };
    private _first = [-1, _statuses] call Waldo_MG_fnc_blackjackGetNextPlayingRole;
    if (_first < 0) then {
        [_table, _state] call Waldo_MG_fnc_blackjackSettleRoundServer;
    } else {
        private _names = _table getVariable ["Waldo_MG_BlackjackPlayerNames", []];
        _state set [2, _first];
        _state set [13, format ["Cards dealt. %1 acts first; dealer shows %2.", _names param [_first, "Player"], [_dealerHand param [0, -1]] call Waldo_MG_fnc_pokerCardName]];
        [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
    };
    true
};

Waldo_MG_fnc_blackjackProgressServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_BlackjackActive", false])) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_BlackjackSnapshotServer", []]);
    if ((_state param [0, ""]) != "DEALER_TURN") exitWith {};
    if (serverTime < (_table getVariable ["Waldo_MG_BlackjackDealerNextAt", 0])) exitWith {};
    private _dealerHand = +(_table getVariable ["Waldo_MG_BlackjackDealerHandServer", []]);
    private _dealerValue = [_dealerHand] call Waldo_MG_fnc_blackjackHandValue;
    private _dealerTotal = _dealerValue param [0, 0];
    if (_dealerTotal >= 17) exitWith {
        [_table, _state] call Waldo_MG_fnc_blackjackSettleRoundServer;
    };
    private _shoe = +(_table getVariable ["Waldo_MG_BlackjackShoeServer", []]);
    if ((count _shoe) <= 0) then {
        _shoe = call Waldo_MG_fnc_blackjackCreateShoeServer;
    };
    private _card = _shoe deleteAt ((count _shoe) - 1);
    _dealerHand pushBack _card;
    _dealerValue = [_dealerHand] call Waldo_MG_fnc_blackjackHandValue;
    _dealerTotal = _dealerValue param [0, 0];
    _table setVariable ["Waldo_MG_BlackjackShoeServer", _shoe];
    _table setVariable ["Waldo_MG_BlackjackDealerHandServer", _dealerHand];
    _state set [9, _dealerHand];
    _state set [10, _dealerTotal];
    _state set [11, _dealerValue param [1, false]];
    _state set [12, false];
    _state set [13, format ["Dealer draws %1 and now has %2.", [_card] call Waldo_MG_fnc_pokerCardName, _dealerTotal]];
    _state set [16, count _shoe];
    [_table, "Waldo_MG_BlackjackDealerNextAt", serverTime + Waldo_MG_CFG_BLACKJACK_DEALER_STEP_SECONDS] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
};

Waldo_MG_fnc_blackjackResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_blackjackClearServer;
    [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
};

Waldo_MG_fnc_blackjackHandleDepartureServer = {
    params [
        ["_table", objNull],
        ["_unit", objNull],
        ["_seatIndex", -1]
    ];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_BlackjackActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_BlackjackPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_BlackjackSeatIndices", []];
    private _role = if (isNull _unit) then {-1} else {_players find _unit};
    if (_role < 0 && {_seatIndex >= 0}) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_BlackjackSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    private _actor = _state param [2, -1];
    private _stacks = +(_state param [3, []]);
    private _statuses = +(_state param [7, []]);
    private _actions = +(_state param [8, []]);
    if ((_statuses param [_role, "LEFT"]) == "LEFT") exitWith {};
    private _names = _table getVariable ["Waldo_MG_BlackjackPlayerNames", []];
    _stacks set [_role, 0];
    _statuses set [_role, "LEFT"];
    _actions set [_role, "Left table - wager and stack forfeited"];
    _state set [3, _stacks];
    _state set [7, _statuses];
    _state set [8, _actions];
    _state set [13, format ["%1 left the Blackjack session.", _names param [_role, "Player"]]];
    private _remaining = {_x != "LEFT"} count _statuses;
    if (_remaining <= 0) exitWith {
        [_table] call Waldo_MG_fnc_blackjackClearServer;
        [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY",true];
    };
    if (_phase == "PLAYER_TURNS" && {_actor == _role}) exitWith {
        [_table, _state, _role] call Waldo_MG_fnc_blackjackAdvanceAfterActionServer;
    };
    if (_phase == "DEALER_TURN" && {({ _x == "STAND" } count _statuses) <= 0}) exitWith {
        [_table, _state] call Waldo_MG_fnc_blackjackSettleRoundServer;
    };
    if (_phase == "BETTING" && {[_state] call Waldo_MG_fnc_blackjackAllBetsReadyServer}) exitWith {
        _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _state];
        [_table] call Waldo_MG_fnc_blackjackDealServer;
    };
    if (_phase == "ROUND_END" && {[_state] call Waldo_MG_fnc_blackjackAllNextReadyServer}) exitWith {
        _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _state];
        [_table, true] call Waldo_MG_fnc_blackjackPrepareBettingServer;
    };
    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
};

Waldo_MG_fnc_blackjackReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_BlackjackActive", false])) exitWith {};
    private _players = _table getVariable ["Waldo_MG_BlackjackPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_BlackjackSeatIndices", []];
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    for "_role" from 0 to ((count _players) - 1) do {
        private _unit = _players param [_role, objNull];
        private _seat = _seatIndices param [_role, -1];
        private _valid = !isNull _unit
            && {_seat >= 0}
            && {_seat < Waldo_MG_CFG_SEAT_COUNT}
            && {(_seats param [_seat, objNull]) == _unit}
            && {_unit in allPlayers}
            && {alive _unit}
            && {(lifeState _unit) != "INCAPACITATED"}
            && {(vehicle _unit) == _unit};
        if (!_valid) then {
            [_table, _unit, _seat] call Waldo_MG_fnc_blackjackHandleDepartureServer;
        };
    };
}; 
 

Waldo_MG_fnc_processBlackjackActionRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 7) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _gameId = _request param [2, ""];
    private _expectedEpoch = _request param [3, -1];
    private _expectedRevision = _request param [4, -1];
    private _action = _request param [5, ""];
    private _amount = _request param [6, 0];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _gameId) != "STRING"}
        || {(typeName _expectedEpoch) != "SCALAR"}
        || {(typeName _expectedRevision) != "SCALAR"}
        || {(typeName _action) != "STRING"}
        || {(typeName _amount) != "SCALAR"}
    ) exitWith {
        [_unit, _token, "Blackjack action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Blackjack action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_BlackjackActive", false])) exitWith {
        [_unit, _token, "There is no active Blackjack session at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId == "" || {_gameId != (_table getVariable ["Waldo_MG_BlackjackGameId", ""])}) exitWith {
        [_unit, _token, "That Blackjack session is no longer current."] call Waldo_MG_fnc_resultServer;
    };
    if (_expectedEpoch != (_table getVariable ["Waldo_MG_BlackjackEpoch", -1])) exitWith {
        [_unit, _token, "That Blackjack action belongs to an older round."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_BlackjackPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only assigned Blackjack players may use table actions."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_BlackjackSnapshotServer", []]);
    private _phase = _state param [0, "IDLE"];
    if (_action == "RESET") exitWith {
        if (_phase != "SESSION_END") then {
            [_unit, _token, "The Blackjack session must be finished before resetting the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_blackjackResetServer;
            [_unit, _token, "Blackjack cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    private _stacks = +(_state param [3, []]);
    private _bets = +(_state param [4, []]);
    private _hands = +(_state param [5, []]);
    private _totals = +(_state param [6, []]);
    private _statuses = +(_state param [7, []]);
    private _actions = +(_state param [8, []]);
    private _names = _table getVariable ["Waldo_MG_BlackjackPlayerNames", []];
    if (_action == "BET") exitWith {
        if (_phase != "BETTING" || {(_statuses param [_role, "LEFT"]) != "BETTING"}) then {
            [_unit, _token, "You cannot place another bet in this round."] call Waldo_MG_fnc_resultServer;
        } else {
            private _maximum = floor (_stacks param [_role, 0]);
            if ((_maximum mod 2) != 0) then {_maximum = _maximum - 1;};
            if (
                _amount != floor _amount
                || {_amount < Waldo_MG_CFG_BLACKJACK_MINIMUM_BET}
                || {(_amount mod 2) != 0}
                || {_amount > _maximum}
            ) then {
                [_unit, _token, format ["Choose an even bet from %1 to %2.", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET, _maximum]] call Waldo_MG_fnc_resultServer;
            } else {
                _stacks set [_role, (_stacks param [_role, 0]) - _amount];
                _bets set [_role, _amount];
                _statuses set [_role, "READY"];
                _actions set [_role, format ["Bet %1 - ready", _amount]];
                _state set [3, _stacks];
                _state set [4, _bets];
                _state set [7, _statuses];
                _state set [8, _actions];
                _state set [13, format ["%1 placed a bet. Waiting for every active player.", _names param [_role, "Player"]]];
                if ([_state] call Waldo_MG_fnc_blackjackAllBetsReadyServer) then {
                    _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _state];
                    [_table] call Waldo_MG_fnc_blackjackDealServer;
                } else {
                    [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
                };
                [_unit, _token, format ["Bet %1 accepted.", _amount]] call Waldo_MG_fnc_resultServer;
            };
        };
    };
    if (_action == "READY_NEXT") exitWith {
        if (_phase != "ROUND_END") then {
            [_unit, _token, "The current Blackjack round has not finished."] call Waldo_MG_fnc_resultServer;
        } else {
            private _nextReady = +(_state param [15, []]);
            if ((_stacks param [_role, 0]) < Waldo_MG_CFG_BLACKJACK_MINIMUM_BET) then {
                [_unit, _token, "You do not have enough chips for another minimum bet."] call Waldo_MG_fnc_resultServer;
            } else {
                if (_nextReady param [_role, false]) then {
                    [_unit, _token, "You are already ready for the next Blackjack round."] call Waldo_MG_fnc_resultServer;
                } else {
                    _nextReady set [_role, true];
                    _actions set [_role, "Ready for next round"];
                    _state set [8, _actions];
                    _state set [15, _nextReady];
                    _state set [13, format ["%1 is ready for the next round.", _names param [_role, "Player"]]];
                    if ([_state] call Waldo_MG_fnc_blackjackAllNextReadyServer) then {
                        _table setVariable ["Waldo_MG_BlackjackSnapshotServer", _state];
                        [_table, true] call Waldo_MG_fnc_blackjackPrepareBettingServer;
                    } else {
                        [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
                    };
                    [_unit, _token, "Ready for the next Blackjack round."] call Waldo_MG_fnc_resultServer;
                };
            };
        };
    };
    if (!(_action in ["HIT", "STAND", "DOUBLE"])) exitWith {
        [_unit, _token, "Unknown Blackjack action."] call Waldo_MG_fnc_resultServer;
    };
    if (_phase != "PLAYER_TURNS" || {(_state param [2, -1]) != _role} || {(_statuses param [_role, "LEFT"]) != "PLAYING"}) exitWith {
        [_unit, _token, "It is not your Blackjack turn."] call Waldo_MG_fnc_resultServer;
    };
    if (_expectedRevision != (_table getVariable ["Waldo_MG_BlackjackRevision", -1])) exitWith {
        [_unit, _token, "The Blackjack hand advanced before that action arrived."] call Waldo_MG_fnc_resultServer;
    };
    private _hand = +(_hands param [_role, []]);
    if (_action == "STAND") exitWith {
        _statuses set [_role, "STAND"];
        _actions set [_role, format ["Stands on %1", _totals param [_role, 0]]];
        _state set [7, _statuses];
        _state set [8, _actions];
        [_table, _state, _role] call Waldo_MG_fnc_blackjackAdvanceAfterActionServer;
        [_unit, _token, "You stand."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "DOUBLE" && {(count _hand) != 2 || {(_stacks param [_role, 0]) < (_bets param [_role, 0])}}) exitWith {
        [_unit, _token, "Double requires your original two cards and enough chips to match the bet."] call Waldo_MG_fnc_resultServer;
    };
    private _shoe = +(_table getVariable ["Waldo_MG_BlackjackShoeServer", []]);
    if ((count _shoe) <= 0) then {_shoe = call Waldo_MG_fnc_blackjackCreateShoeServer;};
    if (_action == "DOUBLE") then {
        private _extra = _bets param [_role, 0];
        _stacks set [_role, (_stacks param [_role, 0]) - _extra];
        _bets set [_role, _extra * 2];
    };
    private _card = _shoe deleteAt ((count _shoe) - 1);
    _hand pushBack _card;
    private _value = [_hand] call Waldo_MG_fnc_blackjackHandValue;
    private _total = _value param [0, 0];
    _hands set [_role, _hand];
    _totals set [_role, _total];
    _table setVariable ["Waldo_MG_BlackjackShoeServer", _shoe];
    _state set [3, _stacks];
    _state set [4, _bets];
    _state set [5, _hands];
    _state set [6, _totals];
    _state set [16, count _shoe];
    private _turnEnds = _action == "DOUBLE" || {_total >= 21};
    if (_total > 21) then {
        _statuses set [_role, "BUST"];
        _actions set [_role, format ["Bust on %1", _total]];
        _turnEnds = true;
    } else {
        if (_action == "DOUBLE") then {
            _statuses set [_role, "STAND"];
            _actions set [_role, format ["Doubled to %1; stands on %2", _bets param [_role, 0], _total]];
        } else {
            if (_total == 21) then {
                _statuses set [_role, "STAND"];
                _actions set [_role, "Hit to 21 - stands"];
            } else {
                _actions set [_role, format ["Hit %1; now %2", [_card] call Waldo_MG_fnc_pokerShortCardLocal, _total]];
            };
        };
    };
    _state set [7, _statuses];
    _state set [8, _actions];
    if (_turnEnds) then {
        [_table, _state, _role] call Waldo_MG_fnc_blackjackAdvanceAfterActionServer;
    } else {
        _state set [13, format ["%1 has %2 and may Hit or Stand.", _names param [_role, "Player"], _total]];
        [_table, _state] call Waldo_MG_fnc_blackjackSetSnapshotServer;
    };
    [_unit, _token, format ["%1 received: %2.", if (_action == "DOUBLE") then {"Double"} else {"Hit"}, [_card] call Waldo_MG_fnc_pokerCardName]] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitBlackjackActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""],
        ["_amount", 0]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {false};
    private _pending = missionNamespace getVariable ["Waldo_MG_BlackjackPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous Blackjack action..."] call Waldo_MG_fnc_notifyLocal;
        false
    };
    private _token = ["BLACKJACK_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_BlackjackPendingRequestLocal", [_token, diag_tickTime]];
    private _request = [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_BlackjackGameId", ""],
            _table getVariable ["Waldo_MG_BlackjackEpoch", -1],
            _table getVariable ["Waldo_MG_BlackjackRevision", -1],
            _action,
            floor _amount
    ];
    ["BLACKJACK", _table, _token, _request param [3, -1], _request] call Waldo_MG_fnc_submitRequestLocal;
    true
};

Waldo_MG_fnc_getBlackjackPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_BlackjackPlayers", []]) find player
};

Waldo_MG_fnc_blackjackDefocusLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _sink = _display getVariable ["Waldo_MG_BlackjackFocusSink", controlNull];
    if (!isNull _sink) then {ctrlSetFocus _sink;};
};

Waldo_MG_fnc_adjustBlackjackBetLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_blackjackDefocusLocal;
    private _target = _display getVariable ["Waldo_MG_BlackjackBetTarget", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET];
    private _delta = _control getVariable ["Waldo_MG_BlackjackBetDelta", 0];
    private _minimum = _display getVariable ["Waldo_MG_BlackjackBetMinimum", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET];
    private _maximum = _display getVariable ["Waldo_MG_BlackjackBetMaximum", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET];
    _target = (_minimum max (_target + _delta)) min _maximum;
    if ((_target mod 2) != 0) then {_target = _target - 1;};
    _display setVariable ["Waldo_MG_BlackjackBetTarget", _target max _minimum];
    [_display] call Waldo_MG_fnc_refreshBlackjackLocal;
};

Waldo_MG_fnc_submitBlackjackButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_blackjackDefocusLocal;
    private _table = _display getVariable ["Waldo_MG_BlackjackTable", objNull];
    private _action = _control getVariable ["Waldo_MG_BlackjackAction", ""];
    private _amount = if (_action == "BET") then {
        _display getVariable ["Waldo_MG_BlackjackBetTarget", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET]
    } else {
        0
    };
    [_table, _action, _amount] call Waldo_MG_fnc_submitBlackjackActionRequestLocal;
};

Waldo_MG_fnc_refreshBlackjackLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_BlackjackRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_BlackjackRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_BlackjackTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "blackjack"}
    ) exitWith {
        _display closeDisplay 1;
    };
    private _state = _table getVariable ["Waldo_MG_BlackjackSnapshot", []];
    if ((count _state) < 17) exitWith {
        _display setVariable ["Waldo_MG_BlackjackRefreshing", false];
    };
    private _phase = _state param [0, "IDLE"];
    private _round = _state param [1, 0];
    private _actor = _state param [2, -1];
    private _stacks = _state param [3, []];
    private _bets = _state param [4, []];
    private _hands = _state param [5, []];
    private _totals = _state param [6, []];
    private _statuses = _state param [7, []];
    private _actions = _state param [8, []];
    private _dealerVisible = _state param [9, []];
    private _dealerTotal = _state param [10, 0];
    private _dealerSoft = _state param [11, false];
    private _dealerHoleHidden = _state param [12, false];
    private _statusText = _state param [13, "Blackjack in progress."];
    private _results = _state param [14, []];
    private _nextReady = _state param [15, []];
    private _shoeCount = _state param [16, 0];
    private _names = _table getVariable ["Waldo_MG_BlackjackPlayerNames", []];
    private _role = if (_spectating) then {-1} else {[_table] call Waldo_MG_fnc_getBlackjackPlayerRoleLocal};
    private _epoch = _table getVariable ["Waldo_MG_BlackjackEpoch", 0];

    private _roundLabel = _display getVariable ["Waldo_MG_BlackjackRoundLabel", controlNull];
    private _shoeLabel = _display getVariable ["Waldo_MG_BlackjackShoeLabel", controlNull];
    private _dealerTotalLabel = _display getVariable ["Waldo_MG_BlackjackDealerTotalLabel", controlNull];
    private _statusLabel = _display getVariable ["Waldo_MG_BlackjackStatusLabel", controlNull];
    private _statusLabelTwo = _display getVariable ["Waldo_MG_BlackjackStatusLabelTwo", controlNull];
    if (!isNull _roundLabel) then {
        _roundLabel ctrlSetText format ["ROUND %1  /  %2", _round, _phase];
        _roundLabel ctrlCommit 0;
    };
    if (!isNull _shoeLabel) then {
        _shoeLabel ctrlSetText format ["SHOE  %1 CARDS", _shoeCount];
        _shoeLabel ctrlCommit 0;
    };
    if (!isNull _dealerTotalLabel) then {
        _dealerTotalLabel ctrlSetText (if ((count _dealerVisible) <= 0) then {
            "DEALER WAITING"
        } else {
            if (_dealerHoleHidden) then {format ["VISIBLE  %1", _dealerTotal]} else {format ["TOTAL  %1%2", _dealerTotal, if (_dealerSoft) then {"  SOFT"} else {""}]}
        });
        _dealerTotalLabel ctrlCommit 0;
    };
    private _lineOneWords = [];
    private _lineTwoWords = [];
    {
        private _candidate = (_lineOneWords + [_x]) joinString " ";
        if ((count _candidate) <= 100 || {(count _lineOneWords) == 0}) then {
            _lineOneWords pushBack _x;
        } else {
            _lineTwoWords pushBack _x;
        };
    } forEach (_statusText splitString " ");
    if (!isNull _statusLabel) then {
        _statusLabel ctrlSetText (_lineOneWords joinString " ");
        _statusLabel ctrlSetTooltip _statusText;
        _statusLabel ctrlCommit 0;
    };
    if (!isNull _statusLabelTwo) then {
        _statusLabelTwo ctrlSetText (_lineTwoWords joinString " ");
        _statusLabelTwo ctrlSetTooltip _statusText;
        _statusLabelTwo ctrlCommit 0;
    };

    private _dealerBundles = _display getVariable ["Waldo_MG_BlackjackDealerCards", []];
    for "_slot" from 0 to ((count _dealerBundles) - 1) do {
        [
            _dealerBundles param [_slot, []],
            if (_slot < (count _dealerVisible)) then {_dealerVisible param [_slot, -1]} else {-1}
        ] call Waldo_MG_fnc_renderPokerCardLocal;
    };
    private _dealerOverflow = _display getVariable ["Waldo_MG_BlackjackDealerOverflow", controlNull];
    if (!isNull _dealerOverflow) then {
        _dealerOverflow ctrlSetText (if ((count _dealerVisible) > Waldo_MG_CFG_BLACKJACK_CARD_SLOTS) then {format ["+%1 MORE", (count _dealerVisible) - Waldo_MG_CFG_BLACKJACK_CARD_SLOTS]} else {""});
        _dealerOverflow ctrlCommit 0;
    };

    private _playerRows = _display getVariable ["Waldo_MG_BlackjackPlayerRows", []];
    for "_row" from 0 to ((count _playerRows) - 1) do {
        private _bundle = _playerRows param [_row, []];
        private _background = _bundle param [0, controlNull];
        private _nameControl = _bundle param [1, controlNull];
        private _stackControl = _bundle param [2, controlNull];
        private _actionControl = _bundle param [3, controlNull];
        private _totalControl = _bundle param [4, controlNull];
        private _cardBundles = _bundle param [5, []];
        private _overflowControl = _bundle param [6, controlNull];
        private _exists = _row < (count _names);
        if (!isNull _background) then {
            _background ctrlShow _exists;
            _background ctrlSetBackgroundColor (if (_row == _actor && {_phase == "PLAYER_TURNS"}) then {
                [0.32, 0.22, 0.055, 0.98]
            } else {
                if (_row == _role) then {[0.035, 0.16, 0.27, 0.98]} else {[0.018, 0.050, 0.070, 0.96]}
            });
            _background ctrlCommit 0;
        };
        {
            if (!isNull _x) then {_x ctrlShow _exists;};
        } forEach [_nameControl, _stackControl, _actionControl, _totalControl, _overflowControl];
        private _hand = if (_exists) then {_hands param [_row, []]} else {[]};
        for "_slot" from 0 to ((count _cardBundles) - 1) do {
            private _cardBundle = _cardBundles param [_slot, []];
            {
                if (!isNull _x) then {_x ctrlShow _exists;};
            } forEach _cardBundle;
            [_cardBundle, if (_slot < (count _hand)) then {_hand param [_slot, -1]} else {-1}] call Waldo_MG_fnc_renderPokerCardLocal;
        };
        if (_exists) then {
            private _playerName = _names param [_row, "Player"];
            private _status = _statuses param [_row, "WAITING"];
            private _action = _actions param [_row, "Waiting"];
            private _result = _results param [_row, 0];
            if (!isNull _nameControl) then {
                _nameControl ctrlSetText format ["%1%2", _playerName, if (_row == _role) then {"  /  YOU"} else {""}];
                _nameControl ctrlSetTooltip _playerName;
            };
            if (!isNull _stackControl) then {
                _stackControl ctrlSetText format ["STACK %1  /  BET %2", _stacks param [_row, 0], _bets param [_row, 0]];
            };
            if (!isNull _actionControl) then {
                _actionControl ctrlSetText format ["%1  /  %2%3", _status, _action, if (_phase in ["ROUND_END", "SESSION_END"] && {_result != 0}) then {format ["  (%1%2)", if (_result > 0) then {"+"} else {""}, _result]} else {""}];
                _actionControl ctrlSetTooltip _action;
            };
            if (!isNull _totalControl) then {
                private _value = [_hand] call Waldo_MG_fnc_blackjackHandValue;
                _totalControl ctrlSetText (if ((count _hand) > 0) then {format ["TOTAL %1%2", _totals param [_row, _value param [0, 0]], if (_value param [1, false]) then {" S"} else {""}]} else {""});
            };
            if (!isNull _overflowControl) then {
                _overflowControl ctrlSetText (if ((count _hand) > Waldo_MG_CFG_BLACKJACK_CARD_SLOTS) then {format ["+%1", (count _hand) - Waldo_MG_CFG_BLACKJACK_CARD_SLOTS]} else {""});
            };
            {
                if (!isNull _x) then {_x ctrlCommit 0;};
            } forEach [_nameControl, _stackControl, _actionControl, _totalControl, _overflowControl];
        };
    };

    private _lastEpoch = _display getVariable ["Waldo_MG_BlackjackBetEpoch", -1];
    private _yourStack = if (_role >= 0) then {_stacks param [_role, 0]} else {0};
    private _maximum = floor _yourStack;
    if ((_maximum mod 2) != 0) then {_maximum = _maximum - 1;};
    private _minimum = Waldo_MG_CFG_BLACKJACK_MINIMUM_BET min (_maximum max Waldo_MG_CFG_BLACKJACK_MINIMUM_BET);
    private _target = _display getVariable ["Waldo_MG_BlackjackBetTarget", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET];
    if (_epoch != _lastEpoch) then {
        _target = Waldo_MG_CFG_BLACKJACK_MINIMUM_BET min _maximum;
        _display setVariable ["Waldo_MG_BlackjackBetEpoch", _epoch];
    };
    _target = (_minimum max _target) min (_maximum max _minimum);
    if ((_target mod 2) != 0) then {_target = _target - 1;};
    _display setVariable ["Waldo_MG_BlackjackBetTarget", _target];
    _display setVariable ["Waldo_MG_BlackjackBetMinimum", _minimum];
    _display setVariable ["Waldo_MG_BlackjackBetMaximum", _maximum];
    private _betLabel = _display getVariable ["Waldo_MG_BlackjackBetLabel", controlNull];
    private _betButton = _display getVariable ["Waldo_MG_BlackjackBetButton", controlNull];
    private _adjustButtons = _display getVariable ["Waldo_MG_BlackjackAdjustButtons", []];
    private _hitButton = _display getVariable ["Waldo_MG_BlackjackHitButton", controlNull];
    private _standButton = _display getVariable ["Waldo_MG_BlackjackStandButton", controlNull];
    private _doubleButton = _display getVariable ["Waldo_MG_BlackjackDoubleButton", controlNull];
    private _nextButton = _display getVariable ["Waldo_MG_BlackjackNextButton", controlNull];
    private _resetButton = _display getVariable ["Waldo_MG_BlackjackResetButton", controlNull];
    private _yourStatus = if (_role >= 0) then {_statuses param [_role, "OBSERVER"]} else {"OBSERVER"};
    private _canBet = !_spectating && {_phase == "BETTING"} && {_role >= 0} && {_yourStatus == "BETTING"} && {_maximum >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET};
    if (!isNull _betLabel) then {
        _betLabel ctrlShow (_phase == "BETTING" && {!_spectating});
        _betLabel ctrlSetText (if (_maximum >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET) then {
            format ["BET TARGET  %1   /   EVEN BETS %2-%3", _target, Waldo_MG_CFG_BLACKJACK_MINIMUM_BET, _maximum]
        } else {
            format ["NO PLAYABLE CHIPS   /   MINIMUM BET %1", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET]
        });
        _betLabel ctrlCommit 0;
    };
    if (!isNull _betButton) then {
        _betButton ctrlShow (_phase == "BETTING" && {!_spectating});
        _betButton ctrlEnable _canBet;
        _betButton ctrlSetText (if (_canBet) then {format ["Place Bet %1", _target]} else {"No Bet Available"});
        _betButton ctrlCommit 0;
    };
    {
        if (!isNull _x) then {
            _x ctrlShow (_phase == "BETTING" && {!_spectating});
            _x ctrlEnable _canBet;
            _x ctrlCommit 0;
        };
    } forEach _adjustButtons;
    private _yourTurn = !_spectating && {_phase == "PLAYER_TURNS"} && {_role == _actor} && {_yourStatus == "PLAYING"};
    if (!isNull _hitButton) then {_hitButton ctrlShow (_phase == "PLAYER_TURNS" && {!_spectating}); _hitButton ctrlEnable _yourTurn; _hitButton ctrlCommit 0;};
    if (!isNull _standButton) then {_standButton ctrlShow (_phase == "PLAYER_TURNS" && {!_spectating}); _standButton ctrlEnable _yourTurn; _standButton ctrlCommit 0;};
    if (!isNull _doubleButton) then {
        private _yourHand = if (_role >= 0) then {_hands param [_role, []]} else {[]};
        private _canDouble = _yourTurn && {(count _yourHand) == 2} && {_yourStack >= (_bets param [_role, 0])};
        _doubleButton ctrlShow (_phase == "PLAYER_TURNS" && {!_spectating});
        _doubleButton ctrlEnable _canDouble;
        _doubleButton ctrlSetText format ["Double %1", if (_role >= 0) then {_bets param [_role, 0]} else {0}];
        _doubleButton ctrlCommit 0;
    };
    if (!isNull _nextButton) then {
        private _alreadyReady = _role >= 0 && {_nextReady param [_role, false]};
        _nextButton ctrlShow (_phase == "ROUND_END" && {!_spectating});
        _nextButton ctrlEnable (!_spectating && {_phase == "ROUND_END"} && {_role >= 0} && {_yourStack >= Waldo_MG_CFG_BLACKJACK_MINIMUM_BET} && {!_alreadyReady});
        _nextButton ctrlSetText (if (_alreadyReady) then {"Ready - Waiting"} else {"Ready Next Round"});
        _nextButton ctrlCommit 0;
    };
    if (!isNull _resetButton) then {
        _resetButton ctrlShow (_phase == "SESSION_END" && {!_spectating});
        _resetButton ctrlEnable (!_spectating && {_phase == "SESSION_END"});
        _resetButton ctrlCommit 0;
    };
    _display setVariable ["Waldo_MG_BlackjackRefreshing", false];
};

Waldo_MG_fnc_openBlackjackLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "blackjack"}
    ) exitWith {
        ["No active Blackjack table is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {
        ["The Blackjack display is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    {
        if (!isNull _x) then {_x closeDisplay 1;};
    } forEach [
        uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_BlackjackDisplay", _display];
    _display setVariable ["Waldo_MG_BlackjackTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_BlackjackBetEpoch", -1];
    _display setVariable ["Waldo_MG_BlackjackBetTarget", Waldo_MG_CFG_BLACKJACK_MINIMUM_BET];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;

    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_BlackjackFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.005, 0.015, 1.17, 1.055];
    _background ctrlSetBackgroundColor [0.006, 0.018, 0.020, 0.988];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.005, 0.015, 1.17, 0.073];
    _topBar ctrlSetBackgroundColor [0.075, 0.25, 0.19, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.035, 0.026, 0.470, 0.048];
    _title ctrlSetText "PARTYGAMES  /  BLACKJACK";
    _title ctrlSetTextColor [0.88, 1, 0.91, 1];
    _title ctrlSetFontHeight 0.034;
    _title ctrlCommit 0;
    private _roundLabel = _display ctrlCreate ["RscText", -1];
    _roundLabel ctrlSetPosition [0.505, 0.029, 0.310, 0.040];
    _roundLabel ctrlSetTextColor [0.81, 0.92, 0.86, 1];
    _roundLabel ctrlSetFontHeight 0.022;
    _roundLabel ctrlCommit 0;
    private _shoeLabel = _display ctrlCreate ["RscText", -1];
    _shoeLabel ctrlSetPosition [0.805, 0.029, 0.175, 0.040];
    _shoeLabel ctrlSetTextColor [0.81, 0.92, 0.86, 1];
    _shoeLabel ctrlSetFontHeight 0.020;
    _shoeLabel ctrlCommit 0;
    private _exitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _exitButton ctrlSetPosition [0.985, 0.025, 0.165, 0.048];
    _exitButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _exitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    _exitButton ctrlCommit 0;

    private _dealerPanel = _display ctrlCreate ["RscText", -1];
    _dealerPanel ctrlSetPosition [0.025, 0.102, 1.13, 0.205];
    _dealerPanel ctrlSetBackgroundColor [0.016, 0.075, 0.066, 0.98];
    _dealerPanel ctrlCommit 0;
    private _dealerTitle = _display ctrlCreate ["RscText", -1];
    _dealerTitle ctrlSetPosition [0.050, 0.116, 0.180, 0.040];
    _dealerTitle ctrlSetText "DEALER";
    _dealerTitle ctrlSetTextColor [0.54, 0.95, 0.72, 1];
    _dealerTitle ctrlSetFontHeight 0.030;
    _dealerTitle ctrlCommit 0;
    private _dealerTotalLabel = _display ctrlCreate ["RscText", -1];
    _dealerTotalLabel ctrlSetPosition [0.050, 0.160, 0.180, 0.042];
    _dealerTotalLabel ctrlSetTextColor [0.88, 0.94, 0.90, 1];
    _dealerTotalLabel ctrlSetFontHeight 0.022;
    _dealerTotalLabel ctrlCommit 0;
    private _dealerRule = _display ctrlCreate ["RscText", -1];
    _dealerRule ctrlSetPosition [0.050, 0.207, 0.180, 0.054];
    _dealerRule ctrlSetText "STANDS ON ALL 17";
    _dealerRule ctrlSetTextColor [0.55, 0.67, 0.62, 1];
    _dealerRule ctrlSetFontHeight 0.017;
    _dealerRule ctrlCommit 0;
    private _dealerCards = [];
    for "_slot" from 0 to (Waldo_MG_CFG_BLACKJACK_CARD_SLOTS - 1) do {
        _dealerCards pushBack ([_display, 0.235 + (_slot * 0.092), 0.112, 0.105, 0.150, 1.35] call Waldo_MG_fnc_createPokerCardControlsLocal);
    };
    private _dealerOverflow = _display ctrlCreate ["RscText", -1];
    _dealerOverflow ctrlSetPosition [0.985, 0.166, 0.150, 0.040];
    _dealerOverflow ctrlSetTextColor [1, 0.78, 0.35, 1];
    _dealerOverflow ctrlSetFontHeight 0.019;
    _dealerOverflow ctrlCommit 0;
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition [0.050, 0.263, 1.070, 0.025];
    _statusLabel ctrlSetTextColor [0.91, 0.95, 0.92, 1];
    _statusLabel ctrlSetFontHeight 0.019;
    _statusLabel ctrlCommit 0;
    private _statusLabelTwo = _display ctrlCreate ["RscText", -1];
    _statusLabelTwo ctrlSetPosition [0.050, 0.286, 1.070, 0.019];
    _statusLabelTwo ctrlSetTextColor [0.67, 0.78, 0.72, 1];
    _statusLabelTwo ctrlSetFontHeight 0.017;
    _statusLabelTwo ctrlCommit 0;

    private _playerRows = [];
    for "_row" from 0 to 3 do {
        private _rowY = 0.318 + (_row * 0.137);
        private _rowBackground = _display ctrlCreate ["RscText", -1];
        _rowBackground ctrlSetPosition [0.025, _rowY, 1.13, 0.132];
        _rowBackground ctrlSetBackgroundColor [0.018, 0.050, 0.070, 0.96];
        _rowBackground ctrlCommit 0;
        private _nameControl = _display ctrlCreate ["RscText", -1];
        _nameControl ctrlSetPosition [0.040, _rowY + 0.005, 0.200, 0.049];
        _nameControl ctrlSetTextColor [0.72, 0.88, 1, 1];
        _nameControl ctrlSetFontHeight 0.0315;
        _nameControl ctrlCommit 0;
        private _stackControl = _display ctrlCreate ["RscText", -1];
        _stackControl ctrlSetPosition [0.040, _rowY + 0.069, 0.200, 0.040];
        _stackControl ctrlSetTextColor [0.72, 0.78, 0.82, 1];
        _stackControl ctrlSetFontHeight 0.0255;
        _stackControl ctrlCommit 0;
        private _cardBundles = [];
        for "_slot" from 0 to (Waldo_MG_CFG_BLACKJACK_CARD_SLOTS - 1) do {
            _cardBundles pushBack ([_display, 0.245 + (_slot * 0.073), _rowY + 0.002, 0.099, 0.128, 1.5] call Waldo_MG_fnc_createPokerCardControlsLocal);
        };
        private _overflowControl = _display ctrlCreate ["RscText", -1];
        _overflowControl ctrlSetPosition [0.858, _rowY + 0.045, 0.035, 0.040];
        _overflowControl ctrlSetTextColor [1, 0.78, 0.35, 1];
        _overflowControl ctrlSetFontHeight 0.018;
        _overflowControl ctrlCommit 0;
        private _totalControl = _display ctrlCreate ["RscText", -1];
        _totalControl ctrlSetPosition [0.895, _rowY + 0.005, 0.235, 0.049];
        _totalControl ctrlSetTextColor [0.91, 0.95, 0.98, 1];
        _totalControl ctrlSetFontHeight 0.0315;
        _totalControl ctrlCommit 0;
        private _actionControl = _display ctrlCreate ["RscText", -1];
        _actionControl ctrlSetPosition [0.895, _rowY + 0.068, 0.235, 0.050];
        _actionControl ctrlSetTextColor [0.67, 0.78, 0.84, 1];
        _actionControl ctrlSetFontHeight 0.024;
        _actionControl ctrlCommit 0;
        _playerRows pushBack [_rowBackground, _nameControl, _stackControl, _actionControl, _totalControl, _cardBundles, _overflowControl];
    };

    private _actionPanel = _display ctrlCreate ["RscText", -1];
    _actionPanel ctrlSetPosition [0.025, 0.875, 1.13, 0.175];
    _actionPanel ctrlSetBackgroundColor [0.012, 0.034, 0.040, 1];
    _actionPanel ctrlCommit 0;
    private _betLabel = _display ctrlCreate ["RscText", -1];
    _betLabel ctrlSetPosition [0.050, 0.888, 0.390, 0.038];
    _betLabel ctrlSetTextColor [0.96, 0.88, 0.60, 1];
    _betLabel ctrlSetFontHeight 0.021;
    _betLabel ctrlCommit 0;
    private _adjustButtons = [];
    {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [_x param [2, 0.1], 0.936, 0.100, 0.045];
        _button ctrlSetText (_x param [0, "ADJUST"]);
        _button setVariable ["Waldo_MG_BlackjackBetDelta", _x param [1, 0]];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_adjustBlackjackBetLocal;}];
        _button ctrlCommit 0;
        _adjustButtons pushBack _button;
    } forEach [
        ["-10", -10, 0.050],
        ["-2", -2, 0.160],
        ["+2", 2, 0.270],
        ["+10", 10, 0.380]
    ];
    private _betButton = _display ctrlCreate ["RscButtonMenu", -1];
    _betButton ctrlSetPosition [0.505, 0.892, 0.230, 0.089];
    _betButton ctrlSetText "Place Bet";
    _betButton ctrlSetBackgroundColor [0.12, 0.34, 0.20, 1];
    _betButton ctrlSetFontHeight 0.025;
    _betButton setVariable ["Waldo_MG_BlackjackAction", "BET"];
    _betButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _betButton ctrlCommit 0;
    private _hitButton = _display ctrlCreate ["RscButtonMenu", -1];
    _hitButton ctrlSetPosition [0.245, 0.900, 0.205, 0.075];
    _hitButton ctrlSetText "HIT";
    _hitButton ctrlSetFontHeight 0.026;
    _hitButton setVariable ["Waldo_MG_BlackjackAction", "HIT"];
    _hitButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _hitButton ctrlCommit 0;
    private _standButton = _display ctrlCreate ["RscButtonMenu", -1];
    _standButton ctrlSetPosition [0.470, 0.900, 0.205, 0.075];
    _standButton ctrlSetText "STAND";
    _standButton ctrlSetFontHeight 0.026;
    _standButton setVariable ["Waldo_MG_BlackjackAction", "STAND"];
    _standButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _standButton ctrlCommit 0;
    private _doubleButton = _display ctrlCreate ["RscButtonMenu", -1];
    _doubleButton ctrlSetPosition [0.695, 0.900, 0.235, 0.075];
    _doubleButton ctrlSetText "DOUBLE";
    _doubleButton ctrlSetFontHeight 0.026;
    _doubleButton setVariable ["Waldo_MG_BlackjackAction", "DOUBLE"];
    _doubleButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _doubleButton ctrlCommit 0;
    private _nextButton = _display ctrlCreate ["RscButtonMenu", -1];
    _nextButton ctrlSetPosition [0.385, 0.900, 0.310, 0.075];
    _nextButton ctrlSetText "Ready Next Round";
    _nextButton ctrlSetBackgroundColor [0.12, 0.34, 0.20, 1];
    _nextButton ctrlSetFontHeight 0.024;
    _nextButton setVariable ["Waldo_MG_BlackjackAction", "READY_NEXT"];
    _nextButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _nextButton ctrlCommit 0;
    private _resetButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resetButton ctrlSetPosition [0.385, 0.900, 0.310, 0.075];
    _resetButton ctrlSetText "Return to Lobby";
    _resetButton ctrlSetBackgroundColor [0.28, 0.17, 0.08, 1];
    _resetButton ctrlSetFontHeight 0.024;
    _resetButton setVariable ["Waldo_MG_BlackjackAction", "RESET"];
    _resetButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitBlackjackButtonLocal;}];
    _resetButton ctrlCommit 0;
    private _rulesLabel = _display ctrlCreate ["RscText", -1];
    _rulesLabel ctrlSetPosition [0.050, 0.995, 1.080, 0.042];
    _rulesLabel ctrlSetText "EVEN BETS  /  BLACKJACK PAYS 3:2  /  DEALER STANDS ON SOFT 17  /  HIT, STAND OR DOUBLE  /  NO SPLITS";
    _rulesLabel ctrlSetTextColor [0.56, 0.69, 0.64, 1];
    _rulesLabel ctrlSetFontHeight 0.019;
    _rulesLabel ctrlCommit 0;

    _display setVariable ["Waldo_MG_BlackjackRoundLabel", _roundLabel];
    _display setVariable ["Waldo_MG_BlackjackShoeLabel", _shoeLabel];
    _display setVariable ["Waldo_MG_BlackjackDealerTotalLabel", _dealerTotalLabel];
    _display setVariable ["Waldo_MG_BlackjackStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_BlackjackStatusLabelTwo", _statusLabelTwo];
    _display setVariable ["Waldo_MG_BlackjackDealerCards", _dealerCards];
    _display setVariable ["Waldo_MG_BlackjackDealerOverflow", _dealerOverflow];
    _display setVariable ["Waldo_MG_BlackjackPlayerRows", _playerRows];
    _display setVariable ["Waldo_MG_BlackjackBetLabel", _betLabel];
    _display setVariable ["Waldo_MG_BlackjackBetButton", _betButton];
    _display setVariable ["Waldo_MG_BlackjackAdjustButtons", _adjustButtons];
    _display setVariable ["Waldo_MG_BlackjackHitButton", _hitButton];
    _display setVariable ["Waldo_MG_BlackjackStandButton", _standButton];
    _display setVariable ["Waldo_MG_BlackjackDoubleButton", _doubleButton];
    _display setVariable ["Waldo_MG_BlackjackNextButton", _nextButton];
    _display setVariable ["Waldo_MG_BlackjackResetButton", _resetButton];
    [_display] call Waldo_MG_fnc_refreshBlackjackLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshBlackjackLocal;
            uiSleep Waldo_MG_CFG_BLACKJACK_UI_TICK;
        };
    };
}; 
 


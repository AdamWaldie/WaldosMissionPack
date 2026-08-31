/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Poker (No-Limit Hold'em)
 * All Waldo_MG_fnc_* functions implementing the Poker (No-Limit Hold'em) mini game (server logic + local UI).
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

Waldo_MG_fnc_pokerCardRank = {
    params [["_card", -1]];
    if (_card < 0 || {_card > 51}) exitWith {0};
    (floor (_card / 4)) + 2
};

Waldo_MG_fnc_pokerCardSuit = {
    params [["_card", -1]];
    if (_card < 0 || {_card > 51}) exitWith {-1};
    _card mod 4
};

Waldo_MG_fnc_pokerRankLabel = {
    params [["_rank", 0]];
    switch (_rank) do {
        case 14: {"A"};
        case 13: {"K"};
        case 12: {"Q"};
        case 11: {"J"};
        default {if (_rank >= 2 && {_rank <= 10}) then {str _rank} else {"?"}};
    }
};

Waldo_MG_fnc_pokerSuitLetter = {
    params [["_suit", -1]];
    switch (_suit) do {
        case 0: {"S"};
        case 1: {"C"};
        case 2: {"H"};
        case 3: {"D"};
        default {"?"};
    }
};

Waldo_MG_fnc_pokerSuitName = {
    params [["_suit", -1]];
    switch (_suit) do {
        case 0: {"Spades"};
        case 1: {"Clubs"};
        case 2: {"Hearts"};
        case 3: {"Diamonds"};
        default {"Unknown suit"};
    }
};

Waldo_MG_fnc_pokerSuitMarkerClass = {
    params [["_suit", -1]];
    switch (_suit) do {
        case 0: {"n_mortar"};
        case 1: {"u_installation"};
        case 2: {"b_med"};
        case 3: {"o_unknown"};
        default {""};
    }
};

Waldo_MG_fnc_pokerCardName = {
    params [["_card", -1]];
    if (_card < 0 || {_card > 51}) exitWith {"Unknown card"};
    format [
        "%1 of %2",
        [[_card] call Waldo_MG_fnc_pokerCardRank] call Waldo_MG_fnc_pokerRankLabel,
        [[_card] call Waldo_MG_fnc_pokerCardSuit] call Waldo_MG_fnc_pokerSuitName
    ]
};

Waldo_MG_fnc_pokerCreateShuffledDeckServer = {
    private _source = [];
    for "_card" from 0 to 51 do {
        _source pushBack _card;
    };
    private _deck = [];
    while {(count _source) > 0} do {
        private _pick = floor (random (count _source));
        _deck pushBack (_source deleteAt _pick);
    };
    _deck
};

Waldo_MG_fnc_pokerCompareScores = {
    params [
        ["_left", []],
        ["_right", []]
    ];
    private _comparison = 0;
    private _length = (count _left) max (count _right);
    if (_length > 0) then {
        for "_index" from 0 to (_length - 1) do {
            if (_comparison == 0) then {
                private _leftValue = _left param [_index, 0];
                private _rightValue = _right param [_index, 0];
                if (_leftValue > _rightValue) then {_comparison = 1;};
                if (_leftValue < _rightValue) then {_comparison = -1;};
            };
        };
    };
    _comparison
};

Waldo_MG_fnc_pokerEvaluateFive = {
    params [["_cardsSource", []]];
    if ((typeName _cardsSource) != "ARRAY" || {(count _cardsSource) != 5}) exitWith {
        [-1, 0, 0, 0, 0, 0]
    };
    private _cards = +_cardsSource;
    private _rankCounts = [];
    _rankCounts resize 15;
    for "_rank" from 0 to 14 do {_rankCounts set [_rank, 0];};
    private _firstSuit = [_cards param [0, -1]] call Waldo_MG_fnc_pokerCardSuit;
    private _flush = _firstSuit >= 0;
    {
        private _rank = [_x] call Waldo_MG_fnc_pokerCardRank;
        private _suit = [_x] call Waldo_MG_fnc_pokerCardSuit;
        if (_rank < 2 || {_rank > 14} || {_suit < 0}) then {
            _flush = false;
        } else {
            _rankCounts set [_rank, (_rankCounts param [_rank, 0]) + 1];
            if (_suit != _firstSuit) then {_flush = false;};
        };
    } forEach _cards;

    private _ranksDescending = [];
    private _four = 0;
    private _trips = [];
    private _pairs = [];
    private _singles = [];
    for "_rank" from 14 to 2 step -1 do {
        private _count = _rankCounts param [_rank, 0];
        if (_count > 0) then {_ranksDescending pushBack _rank;};
        if (_count == 4) then {_four = _rank;};
        if (_count == 3) then {_trips pushBack _rank;};
        if (_count == 2) then {_pairs pushBack _rank;};
        if (_count == 1) then {_singles pushBack _rank;};
    };

    private _straightHigh = 0;
    for "_high" from 14 to 5 step -1 do {
        if (
            _straightHigh == 0
            && {(_rankCounts param [_high, 0]) > 0}
            && {(_rankCounts param [_high - 1, 0]) > 0}
            && {(_rankCounts param [_high - 2, 0]) > 0}
            && {(_rankCounts param [_high - 3, 0]) > 0}
            && {(_rankCounts param [_high - 4, 0]) > 0}
        ) then {
            _straightHigh = _high;
        };
    };
    if (
        _straightHigh == 0
        && {(_rankCounts param [14, 0]) > 0}
        && {(_rankCounts param [5, 0]) > 0}
        && {(_rankCounts param [4, 0]) > 0}
        && {(_rankCounts param [3, 0]) > 0}
        && {(_rankCounts param [2, 0]) > 0}
    ) then {
        _straightHigh = 5;
    };

    if (_flush && {_straightHigh > 0}) exitWith {[8, _straightHigh, 0, 0, 0, 0]};
    if (_four > 0) exitWith {[7, _four, _singles param [0, 0], 0, 0, 0]};
    if ((count _trips) > 0 && {(count _pairs) > 0}) exitWith {
        [6, _trips param [0, 0], _pairs param [0, 0], 0, 0, 0]
    };
    if (_flush) exitWith {[
        5,
        _ranksDescending param [0, 0],
        _ranksDescending param [1, 0],
        _ranksDescending param [2, 0],
        _ranksDescending param [3, 0],
        _ranksDescending param [4, 0]
    ]};
    if (_straightHigh > 0) exitWith {[4, _straightHigh, 0, 0, 0, 0]};
    if ((count _trips) > 0) exitWith {[
        3,
        _trips param [0, 0],
        _singles param [0, 0],
        _singles param [1, 0],
        0,
        0
    ]};
    if ((count _pairs) >= 2) exitWith {[
        2,
        _pairs param [0, 0],
        _pairs param [1, 0],
        _singles param [0, 0],
        0,
        0
    ]};
    if ((count _pairs) == 1) exitWith {[
        1,
        _pairs param [0, 0],
        _singles param [0, 0],
        _singles param [1, 0],
        _singles param [2, 0],
        0
    ]};
    [
        0,
        _ranksDescending param [0, 0],
        _ranksDescending param [1, 0],
        _ranksDescending param [2, 0],
        _ranksDescending param [3, 0],
        _ranksDescending param [4, 0]
    ]
};

Waldo_MG_fnc_pokerHandCategoryName = {
    params [["_score", []]];
    switch (_score param [0, -1]) do {
        case 8: {"Straight Flush"};
        case 7: {"Four of a Kind"};
        case 6: {"Full House"};
        case 5: {"Flush"};
        case 4: {"Straight"};
        case 3: {"Three of a Kind"};
        case 2: {"Two Pair"};
        case 1: {"One Pair"};
        case 0: {"High Card"};
        default {"No Hand"};
    }
};

Waldo_MG_fnc_pokerEvaluateBest = {
    params [["_cardsSource", []]];
    if ((typeName _cardsSource) != "ARRAY" || {(count _cardsSource) < 5}) exitWith {
        [[-1, 0, 0, 0, 0, 0], [], "No Hand"]
    };
    private _cards = +_cardsSource;
    private _count = count _cards;
    private _bestScore = [-1, 0, 0, 0, 0, 0];
    private _bestFive = [];
    for "_a" from 0 to (_count - 5) do {
        for "_b" from (_a + 1) to (_count - 4) do {
            for "_c" from (_b + 1) to (_count - 3) do {
                for "_d" from (_c + 1) to (_count - 2) do {
                    for "_e" from (_d + 1) to (_count - 1) do {
                        private _five = [
                            _cards param [_a, -1],
                            _cards param [_b, -1],
                            _cards param [_c, -1],
                            _cards param [_d, -1],
                            _cards param [_e, -1]
                        ];
                        private _score = [_five] call Waldo_MG_fnc_pokerEvaluateFive;
                        if (([_score, _bestScore] call Waldo_MG_fnc_pokerCompareScores) > 0) then {
                            _bestScore = _score;
                            _bestFive = _five;
                        };
                    };
                };
            };
        };
    };
    [_bestScore, _bestFive, [_bestScore] call Waldo_MG_fnc_pokerHandCategoryName]
};

Waldo_MG_fnc_pokerGetNextIndex = {
    params [
        ["_start", -1],
        ["_eligible", []]
    ];
    private _count = count _eligible;
    if (_count <= 0) exitWith {-1};
    private _result = -1;
    for "_offset" from 1 to _count do {
        private _candidate = (_start + _offset) mod _count;
        if (_result < 0 && {_eligible param [_candidate, false]}) then {
            _result = _candidate;
        };
    };
    _result
};

Waldo_MG_fnc_pokerBuildSidePots = {
    params [
        ["_contributions", []],
        ["_statuses", []]
    ];
    private _levels = [];
    {
        if ((typeName _x) == "SCALAR" && {_x > 0}) then {
            _levels pushBackUnique (floor _x);
        };
    } forEach _contributions;
    _levels sort true;
    private _pots = [];
    private _previous = 0;
    {
        private _level = _x;
        private _contributors = [];
        private _eligible = [];
        for "_role" from 0 to ((count _contributions) - 1) do {
            if ((_contributions param [_role, 0]) >= _level) then {
                _contributors pushBack _role;
                if (!((_statuses param [_role, "LEFT"]) in ["FOLDED", "LEFT"])) then {
                    _eligible pushBack _role;
                };
            };
        };
        private _amount = (_level - _previous) * (count _contributors);
        if (_amount > 0) then {
            _pots pushBack [_amount, _eligible, _contributors];
        };
        _previous = _level;
    } forEach _levels;
    _pots
}; 
 

Waldo_MG_fnc_pokerCreateEmptySnapshot = {
    params [
        ["_count", 0],
        ["_chipsSource", []]
    ];
    private _chips = [];
    private _numbers = [];
    private _statuses = [];
    private _actions = [];
    private _revealed = [];
    private _booleans = [];
    private _lastActed = [];
    private _choices = [];
    if (_count > 0) then {
        for "_role" from 0 to (_count - 1) do {
            _chips pushBack (_chipsSource param [_role, Waldo_MG_CFG_POKER_STARTING_CHIPS]);
            _numbers pushBack 0;
            _statuses pushBack "BUSTED";
            _actions pushBack "Waiting";
            _revealed pushBack [];
            _booleans pushBack false;
            _lastActed pushBack -1;
            _choices pushBack -1;
        };
    };
    [
        "IDLE", 0, -1, -1, -1, -1,
        _chips, +_numbers, +_numbers, _statuses, _actions, [], 0, 0,
        Waldo_MG_CFG_POKER_BIG_BLIND, [], "Waiting for Poker.", _revealed,
        +_booleans, +_booleans, _lastActed, [], false, _choices
    ]
};

Waldo_MG_fnc_pokerPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    _table setVariable [
        "Waldo_MG_PokerRevision",
        (_table getVariable ["Waldo_MG_PokerRevision", 0]) + 1,
        true
    ];
    _table setVariable [
        "Waldo_MG_TableRevision",
        (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1,
        true
    ];
};

Waldo_MG_fnc_pokerSetSnapshotServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table} || {(typeName _snapshot) != "ARRAY"}) exitWith {};
    _table setVariable ["Waldo_MG_PokerSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_PokerSnapshot", _snapshot, true];
    [_table] call Waldo_MG_fnc_pokerPublishRevisionServer;
};

Waldo_MG_fnc_pokerSendPrivateHandServer = {
    params [
        ["_table", objNull],
        ["_role", -1]
    ];
    if (!isServer || {isNull _table} || {_role < 0}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_PokerPlayers", []];
    private _recipient = _players param [_role, objNull];
    if (isNull _recipient) exitWith {};
    private _snapshot = _table getVariable ["Waldo_MG_PokerSnapshotServer", []];
    private _handNumber = _snapshot param [1, 0];
    private _hands = _table getVariable ["Waldo_MG_PokerHandsServer", []];
    private _cards = +(_hands param [_role, []]);
    private _payload = [
        _table getVariable ["Waldo_MG_PokerGameId", ""],
        _handNumber,
        _cards
    ];
    _recipient setVariable ["Waldo_MG_PokerPrivateHand", _payload, owner _recipient];
};

Waldo_MG_fnc_pokerClearPrivateHandsServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    {
        if (!isNull _x) then {
            _x setVariable ["Waldo_MG_PokerPrivateHand", [], owner _x];
        };
    } forEach (_table getVariable ["Waldo_MG_PokerPlayers", []]);
    _table setVariable ["Waldo_MG_PokerHandsServer", []];
    _table setVariable ["Waldo_MG_PokerDeckServer", []];
};

Waldo_MG_fnc_pokerClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_pokerClearPrivateHandsServer;
    _table setVariable ["Waldo_MG_PokerActive", false, true];
    _table setVariable ["Waldo_MG_PokerFinished", false, true];
    _table setVariable ["Waldo_MG_PokerGameId", "", true];
    _table setVariable ["Waldo_MG_PokerPlayers", [], true];
    _table setVariable ["Waldo_MG_PokerPlayerNames", [], true];
    _table setVariable ["Waldo_MG_PokerSeatIndices", [], true];
    private _snapshot = [0, []] call Waldo_MG_fnc_pokerCreateEmptySnapshot;
    _table setVariable ["Waldo_MG_PokerSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_PokerSnapshot", _snapshot, true];
    [_table] call Waldo_MG_fnc_pokerPublishRevisionServer;
};

Waldo_MG_fnc_pokerCountSurvivorsServer = {
    params [["_snapshot", []]];
    private _chips = _snapshot param [6, []];
    private _statuses = _snapshot param [9, []];
    private _count = 0;
    for "_role" from 0 to ((count _chips) - 1) do {
        if ((_chips param [_role, 0]) > 0 && {(_statuses param [_role, "LEFT"]) != "LEFT"}) then {
            _count = _count + 1;
        };
    };
    _count
};

Waldo_MG_fnc_pokerCompleteHandServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _chips = +(_state param [6, []]);
    private _statuses = +(_state param [9, []]);
    private _count = count _chips;
    for "_role" from 0 to (_count - 1) do {
        if ((_statuses param [_role, "LEFT"]) != "LEFT" && {(_chips param [_role, 0]) <= 0}) then {
            _statuses set [_role, "BUSTED"];
        };
    };
    private _revealed = [];
    private _ready = [];
    private _pending = [];
    private _choices = [];
    for "_role" from 0 to (_count - 1) do {
        _revealed pushBack [];
        _ready pushBack false;
        _pending pushBack false;
        _choices pushBack -1;
    };
    _state set [9, _statuses];
    _state set [17, _revealed];
    _state set [18, _ready];
    _state set [19, _pending];
    _state set [23, _choices];
    _state set [5, -1];
    private _finished = ([_state] call Waldo_MG_fnc_pokerCountSurvivorsServer) <= 1;
    _state set [0, if (_finished) then {"MATCH_END"} else {"HAND_END"}];
    _table setVariable ["Waldo_MG_PokerFinished", _finished, true];
    _table setVariable ["Waldo_MG_TablePhase", if (_finished) then {"FINISHED"} else {"PLAYING"}, true];
    if (_finished) then {
        private _survivor = -1;
        for "_role" from 0 to (_count - 1) do {
            if ((_chips param [_role, 0]) > 0 && {(_statuses param [_role, "LEFT"]) != "LEFT"}) then {
                _survivor = _role;
            };
        };
        if (_survivor >= 0) then {
            private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
            _state set [16, format [
                "%1 wins the Poker table with %2 chips. Reveal cards or reset to the lobby.",
                _names param [_survivor, "Survivor"],
                _chips param [_survivor, 0]
            ]];
        };
    };
    [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
};

Waldo_MG_fnc_pokerAwardUncontestedServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []],
        ["_winner", -1]
    ];
    if (!isServer || {isNull _table} || {_winner < 0}) exitWith {};
    private _state = +_snapshot;
    private _chips = +(_state param [6, []]);
    private _pot = _state param [12, 0];
    _chips set [_winner, (_chips param [_winner, 0]) + _pot];
    private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
    private _winnerName = _names param [_winner, "Winner"];
    _state set [6, _chips];
    _state set [15, [_winner]];
    _state set [21, [[_winner, _pot, "Uncontested pot", 0]]];
    _state set [16, format [
        "%1 wins %2 chips uncontested. Reveal the bluff, or stay mysterious and ready for the next hand.",
        _winnerName,
        _pot
    ]];
    [_table, _state] call Waldo_MG_fnc_pokerCompleteHandServer;
};

Waldo_MG_fnc_pokerResolveShowdownServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _chips = +(_state param [6, []]);
    private _contributions = +(_state param [8, []]);
    private _statuses = +(_state param [9, []]);
    private _community = +(_state param [11, []]);
    private _dealer = _state param [2, -1];
    private _hands = _table getVariable ["Waldo_MG_PokerHandsServer", []];
    private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
    private _count = count _chips;
    private _scores = [];
    private _labels = [];
    for "_role" from 0 to (_count - 1) do {
        if ((_statuses param [_role, "LEFT"]) in ["FOLDED", "LEFT"]) then {
            _scores pushBack [-1, 0, 0, 0, 0, 0];
            _labels pushBack "Folded";
        } else {
            private _evaluation = [(_hands param [_role, []]) + _community] call Waldo_MG_fnc_pokerEvaluateBest;
            _scores pushBack (_evaluation param [0, [-1, 0, 0, 0, 0, 0]]);
            _labels pushBack (_evaluation param [2, "No Hand"]);
        };
    };

    private _awardTotals = [];
    for "_role" from 0 to (_count - 1) do {_awardTotals pushBack 0;};
    private _awards = [];
    private _winners = [];
    private _summaryParts = [];
    private _pots = [_contributions, _statuses] call Waldo_MG_fnc_pokerBuildSidePots;
    for "_potIndex" from 0 to ((count _pots) - 1) do {
        private _potData = _pots param [_potIndex, [0, [], []]];
        private _amount = _potData param [0, 0];
        private _eligible = +(_potData param [1, []]);
        private _contributors = +(_potData param [2, []]);
        if ((count _eligible) <= 0) then {
            for "_role" from 0 to (_count - 1) do {
                if ((_statuses param [_role, "LEFT"]) in ["ACTIVE", "ALL_IN"]) then {
                    _eligible pushBack _role;
                };
            };
            if ((count _eligible) <= 0 && {(count _contributors) == 1}) then {
                _eligible = [_contributors param [0, -1]];
            };
        };
        if ((count _eligible) > 0 && {_amount > 0}) then {
            private _potWinners = [];
            private _bestScore = [-1, 0, 0, 0, 0, 0];
            {
                private _score = _scores param [_x, [-1, 0, 0, 0, 0, 0]];
                private _comparison = [_score, _bestScore] call Waldo_MG_fnc_pokerCompareScores;
                if (_comparison > 0) then {
                    _bestScore = _score;
                    _potWinners = [_x];
                } else {
                    if (_comparison == 0) then {_potWinners pushBack _x;};
                };
            } forEach _eligible;
            private _share = floor (_amount / (count _potWinners));
            private _remainder = _amount mod (count _potWinners);
            private _potAwardTotals = [];
            for "_role" from 0 to (_count - 1) do {_potAwardTotals pushBack 0;};
            {
                _awardTotals set [_x, (_awardTotals param [_x, 0]) + _share];
                _potAwardTotals set [_x, (_potAwardTotals param [_x, 0]) + _share];
            } forEach _potWinners;
            if (_remainder > 0) then {
                private _winnerFlags = [];
                for "_role" from 0 to (_count - 1) do {
                    _winnerFlags pushBack (_role in _potWinners);
                };
                private _cursor = _dealer;
                while {_remainder > 0} do {
                    _cursor = [_cursor, _winnerFlags] call Waldo_MG_fnc_pokerGetNextIndex;
                    if (_cursor < 0) then {
                        _remainder = 0;
                    } else {
                        _awardTotals set [_cursor, (_awardTotals param [_cursor, 0]) + 1];
                        _potAwardTotals set [_cursor, (_potAwardTotals param [_cursor, 0]) + 1];
                        _remainder = _remainder - 1;
                    };
                };
            };
            private _label = [_bestScore] call Waldo_MG_fnc_pokerHandCategoryName;
            {
                _winners pushBackUnique _x;
                _awards pushBack [_x, _potAwardTotals param [_x, 0], _label, _potIndex];
            } forEach _potWinners;
        };
    };
    for "_role" from 0 to (_count - 1) do {
        private _amount = _awardTotals param [_role, 0];
        if (_amount > 0) then {
            _chips set [_role, (_chips param [_role, 0]) + _amount];
            private _label = _labels param [_role, "Poker hand"];
            _summaryParts pushBack format ["%1 +%2 (%3)", _names param [_role, "Player"], _amount, _label];
        };
    };
    _state set [6, _chips];
    _state set [15, _winners];
    _state set [21, _awards];
    _state set [16, format [
        "SHOWDOWN: %1. Reveal your cards or keep them hidden, then ready for the next hand.",
        _summaryParts joinString " | "
    ]];
    [_table, _state] call Waldo_MG_fnc_pokerCompleteHandServer;
};

Waldo_MG_fnc_pokerAdvanceStreetServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    private _state = +_snapshot;
    if (!isServer || {isNull _table}) exitWith {_state};
    private _phase = _state param [0, "PREFLOP"];
    private _deck = +(_table getVariable ["Waldo_MG_PokerDeckServer", []]);
    private _community = +(_state param [11, []]);
    private _nextPhase = "RIVER";
    private _drawCount = 1;
    if (_phase == "PREFLOP") then {_nextPhase = "FLOP"; _drawCount = 3;};
    if (_phase == "FLOP") then {_nextPhase = "TURN"; _drawCount = 1;};
    if (_phase == "TURN") then {_nextPhase = "RIVER"; _drawCount = 1;};
    if ((count _deck) > 0) then {_deck deleteAt 0;};
    for "_draw" from 1 to _drawCount do {
        if ((count _deck) > 0) then {_community pushBack (_deck deleteAt 0);};
    };
    _table setVariable ["Waldo_MG_PokerDeckServer", _deck];
    private _statuses = +(_state param [9, []]);
    private _count = count _statuses;
    private _bets = [];
    private _pending = [];
    private _lastActed = [];
    for "_role" from 0 to (_count - 1) do {
        _bets pushBack 0;
        _pending pushBack ((_statuses param [_role, "LEFT"]) == "ACTIVE");
        _lastActed pushBack -1;
    };
    private _dealer = _state param [2, -1];
    private _first = [_dealer, _pending] call Waldo_MG_fnc_pokerGetNextIndex;
    _state set [0, _nextPhase];
    _state set [5, _first];
    _state set [7, _bets];
    _state set [11, _community];
    _state set [13, 0];
    _state set [14, Waldo_MG_CFG_POKER_BIG_BLIND];
    _state set [19, _pending];
    _state set [20, _lastActed];
    _state set [22, false];
    _state set [16, format ["%1 dealt. Betting begins left of the dealer.", _nextPhase]];
    _state
};

Waldo_MG_fnc_pokerProgressServer = {
    params [
        ["_table", objNull],
        ["_snapshot", []]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    private _state = +_snapshot;
    private _settled = false;
    private _guard = 0;
    while {!_settled && {_guard < 10}} do {
        _guard = _guard + 1;
        private _statuses = +(_state param [9, []]);
        private _pending = +(_state param [19, []]);
        private _bets = +(_state param [7, []]);
        private _currentBet = _state param [13, 0];
        private _contenders = [];
        private _actionable = [];
        private _pendingRoles = [];
        for "_role" from 0 to ((count _statuses) - 1) do {
            private _status = _statuses param [_role, "LEFT"];
            if (_status in ["ACTIVE", "ALL_IN"]) then {_contenders pushBack _role;};
            if (_status == "ACTIVE") then {
                _actionable pushBack _role;
                if (_pending param [_role, false]) then {_pendingRoles pushBack _role;};
            };
        };
        if ((count _contenders) <= 1) then {
            [_table, _state, _contenders param [0, -1]] call Waldo_MG_fnc_pokerAwardUncontestedServer;
            _settled = true;
        } else {
            if ((count _pendingRoles) > 0) then {
                if ((count _actionable) <= 1) then {
                    private _only = _actionable param [0, -1];
                    if (_only < 0 || {(_bets param [_only, 0]) >= _currentBet}) then {
                        if (_only >= 0) then {_pending set [_only, false];};
                        _state set [19, _pending];
                    } else {
                        private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
                        _state set [5, _only];
                        _state set [16, format ["%1 must answer the all-in wager.", _names param [_only, "Player"]]];
                        [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
                        _settled = true;
                    };
                } else {
                    private _turn = _state param [5, -1];
                    if (!(_turn in _pendingRoles)) then {
                        private _flags = [];
                        for "_role" from 0 to ((count _statuses) - 1) do {
                            _flags pushBack (_role in _pendingRoles);
                        };
                        _turn = [_turn, _flags] call Waldo_MG_fnc_pokerGetNextIndex;
                    };
                    private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
                    _state set [5, _turn];
                    _state set [16, format ["%1 to act on the %2.", _names param [_turn, "Player"], _state param [0, "street"]]];
                    [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
                    _settled = true;
                };
            } else {
                if ((_state param [0, "RIVER"]) == "RIVER") then {
                    [_table, _state] call Waldo_MG_fnc_pokerResolveShowdownServer;
                    _settled = true;
                } else {
                    _state = [_table, _state] call Waldo_MG_fnc_pokerAdvanceStreetServer;
                };
            };
        };
    };
};

Waldo_MG_fnc_pokerStartHandServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    private _previous = _table getVariable ["Waldo_MG_PokerSnapshotServer", []];
    private _chips = +(_previous param [6, []]);
    private _players = _table getVariable ["Waldo_MG_PokerPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_PokerSeatIndices", []];
    private _tableSeats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _count = count _players;
    private _eligible = [];
    private _statuses = [];
    for "_role" from 0 to (_count - 1) do {
        private _unit = _players param [_role, objNull];
        private _seatIndex = _seatIndices param [_role, -1];
        private _present = !isNull _unit
            && {_seatIndex >= 0}
            && {(_tableSeats param [_seatIndex, objNull]) == _unit};
        private _canPlay = _present && {(_chips param [_role, 0]) > 0};
        _eligible pushBack _canPlay;
        _statuses pushBack (if (!_present) then {"LEFT"} else {if (_canPlay) then {"ACTIVE"} else {"BUSTED"}});
    };
    private _survivors = {_x} count _eligible;
    if (_survivors < 2) exitWith {false};

    private _previousDealer = _previous param [2, -1];
    private _previousBigBlind = _previous param [4, -1];
    private _dealer = [_previousDealer, _eligible] call Waldo_MG_fnc_pokerGetNextIndex;
    private _smallBlind = if (_survivors == 2) then {_dealer} else {[_dealer, _eligible] call Waldo_MG_fnc_pokerGetNextIndex};
    private _bigBlind = [_smallBlind, _eligible] call Waldo_MG_fnc_pokerGetNextIndex; 
 
    if (
        _survivors == 2
        && {_bigBlind == _previousBigBlind}
        && {_eligible param [_previousBigBlind, false]}
    ) then {
        _dealer = _previousBigBlind;
        _smallBlind = _dealer;
        _bigBlind = [_smallBlind, _eligible] call Waldo_MG_fnc_pokerGetNextIndex;
    };
    private _handNumber = (_previous param [1, 0]) + 1;
    private _deck = call Waldo_MG_fnc_pokerCreateShuffledDeckServer;
    private _hands = [];
    private _bets = [];
    private _contributions = [];
    private _actions = [];
    private _revealed = [];
    private _ready = [];
    private _pending = [];
    private _lastActed = [];
    private _choices = [];
    for "_role" from 0 to (_count - 1) do {
        _hands pushBack [];
        _bets pushBack 0;
        _contributions pushBack 0;
        _actions pushBack (if (_eligible param [_role, false]) then {"Dealt in"} else {_statuses param [_role, "BUSTED"]});
        _revealed pushBack [];
        _ready pushBack false;
        _pending pushBack (_eligible param [_role, false]);
        _lastActed pushBack -1;
        _choices pushBack -1;
    };
    private _dealCursor = _dealer;
    for "_pass" from 1 to 2 do {
        for "_dealt" from 1 to _survivors do {
            _dealCursor = [_dealCursor, _eligible] call Waldo_MG_fnc_pokerGetNextIndex;
            private _hand = +(_hands param [_dealCursor, []]);
            _hand pushBack (_deck deleteAt 0);
            _hands set [_dealCursor, _hand];
        };
    };
    private _postBlind = {
        params ["_role", "_blind", "_label"];
        private _posted = (_chips param [_role, 0]) min _blind;
        _chips set [_role, (_chips param [_role, 0]) - _posted];
        _bets set [_role, _posted];
        _contributions set [_role, _posted];
        _actions set [_role, format ["%1 %2", _label, _posted]];
        if ((_chips param [_role, 0]) <= 0) then {
            _statuses set [_role, "ALL_IN"];
            _pending set [_role, false];
            _actions set [_role, format ["%1 %2 - ALL IN", _label, _posted]];
        };
    };
    [_smallBlind, Waldo_MG_CFG_POKER_SMALL_BLIND, "Small blind"] call _postBlind;
    [_bigBlind, Waldo_MG_CFG_POKER_BIG_BLIND, "Big blind"] call _postBlind;
    private _pot = 0;
    {_pot = _pot + _x;} forEach _contributions;
    private _firstActor = [_bigBlind, _pending] call Waldo_MG_fnc_pokerGetNextIndex;
    private _state = [
        "PREFLOP", _handNumber, _dealer, _smallBlind, _bigBlind, _firstActor,
        _chips, _bets, _contributions, _statuses, _actions, [], _pot,
        Waldo_MG_CFG_POKER_BIG_BLIND, Waldo_MG_CFG_POKER_BIG_BLIND, [],
        "Hole cards dealt. Action begins left of the big blind.",
        _revealed, _ready, _pending, _lastActed, [], true, _choices
    ];
    _table setVariable ["Waldo_MG_PokerDeckServer", _deck];
    _table setVariable ["Waldo_MG_PokerHandsServer", _hands];
    _table setVariable ["Waldo_MG_PokerSnapshotServer", _state];
    for "_role" from 0 to (_count - 1) do {
        [_table, _role] call Waldo_MG_fnc_pokerSendPrivateHandServer;
    };
    [_table, _state] call Waldo_MG_fnc_pokerProgressServer;
    true
};

Waldo_MG_fnc_pokerStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "poker") exitWith {false};
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
    if (_count < 2 || {_count > 4}) exitWith {false};
    private _chips = [];
    for "_role" from 0 to (_count - 1) do {_chips pushBack Waldo_MG_CFG_POKER_STARTING_CHIPS;};
    private _snapshot = [_count, _chips] call Waldo_MG_fnc_pokerCreateEmptySnapshot;
    _snapshot set [0, "DEALING"];
    _table setVariable ["Waldo_MG_PokerActive", true, true];
    _table setVariable ["Waldo_MG_PokerFinished", false, true];
    _table setVariable [
        "Waldo_MG_PokerGameId",
        format ["Waldo_MG_POKER_%1_%2", floor (serverTime * 10), floor (random 1000000)],
        true
    ];
    _table setVariable ["Waldo_MG_PokerPlayers", _players, true];
    _table setVariable ["Waldo_MG_PokerPlayerNames", _names, true];
    _table setVariable ["Waldo_MG_PokerSeatIndices", _seatIndices, true];
    _table setVariable ["Waldo_MG_PokerSnapshotServer", _snapshot];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING", true];
    [_table] call Waldo_MG_fnc_pokerStartHandServer
};

Waldo_MG_fnc_pokerHandleDepartureServer = {
    params [
        ["_table", objNull],
        ["_unit", objNull],
        ["_seatIndex", -1]
    ];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_PokerActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_PokerPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_PokerSeatIndices", []];
    private _role = if (isNull _unit) then {-1} else {_players find _unit};
    if (_role < 0 && {_seatIndex >= 0}) then {_role = _seatIndices find _seatIndex;};
    if (_role < 0) exitWith {};
    private _state = +(_table getVariable ["Waldo_MG_PokerSnapshotServer", []]);
    private _statuses = +(_state param [9, []]);
    if ((_statuses param [_role, "LEFT"]) == "LEFT") exitWith {};
    private _chips = +(_state param [6, []]);
    private _pending = +(_state param [19, []]);
    private _actions = +(_state param [10, []]);
    private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
    _chips set [_role, 0];
    _statuses set [_role, "LEFT"];
    _pending set [_role, false];
    _actions set [_role, "Left table - folded"];
    _state set [6, _chips];
    _state set [9, _statuses];
    _state set [10, _actions];
    _state set [19, _pending];
    _state set [16, format ["%1 left Poker and forfeited the remaining stack.", _names param [_role, "Player"]]];
    if (!isNull (_players param [_role, objNull])) then {
        private _departing = _players param [_role, objNull];
        _departing setVariable ["Waldo_MG_PokerPrivateHand", [], owner _departing];
    };
    private _present = 0;
    {if (_x != "LEFT") then {_present = _present + 1;};} forEach _statuses;
    if (_present <= 0) exitWith {
        [_table] call Waldo_MG_fnc_pokerClearServer;
        _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
        _table setVariable ["Waldo_MG_TablePhase", "LOBBY", true];
    };
    if ((_state param [0, "HAND_END"]) in ["PREFLOP", "FLOP", "TURN", "RIVER"]) then {
        [_table, _state] call Waldo_MG_fnc_pokerProgressServer;
    } else {
        if (([_state] call Waldo_MG_fnc_pokerCountSurvivorsServer) <= 1) then {
            [_table, _state] call Waldo_MG_fnc_pokerCompleteHandServer;
        } else {
            private _ready = _state param [18, []];
            private _allReady = (_state param [0, ""]) == "HAND_END";
            for "_other" from 0 to ((count _chips) - 1) do {
                if (
                    (_chips param [_other, 0]) > 0
                    && {(_statuses param [_other, "LEFT"]) != "LEFT"}
                    && {!(_ready param [_other, false])}
                ) then {
                    _allReady = false;
                };
            };
            if (_allReady) then {
                _table setVariable ["Waldo_MG_PokerSnapshotServer", _state];
                [_table] call Waldo_MG_fnc_pokerStartHandServer;
            } else {
                [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
            };
        };
    };
};

Waldo_MG_fnc_pokerReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table} || {!(_table getVariable ["Waldo_MG_PokerActive", false])}) exitWith {};
    private _players = _table getVariable ["Waldo_MG_PokerPlayers", []];
    private _seatIndices = _table getVariable ["Waldo_MG_PokerSeatIndices", []];
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
            [_table, _unit, _seat] call Waldo_MG_fnc_pokerHandleDepartureServer;
        };
    };
};

Waldo_MG_fnc_pokerResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_pokerClearServer;
    _table setVariable ["Waldo_MG_TableReady", [false, false, false, false], true];
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
}; 
 

Waldo_MG_fnc_processPokerActionRequestServer = {
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
    private _handNumber = _request param [3, -1];
    private _expectedRevision = _request param [4, -1];
    private _action = _request param [5, ""];
    private _amount = _request param [6, 0];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _gameId) != "STRING"}
        || {(typeName _handNumber) != "SCALAR"}
        || {(typeName _expectedRevision) != "SCALAR"}
        || {(typeName _action) != "STRING"}
        || {(typeName _amount) != "SCALAR"}
    ) exitWith {
        [_unit, _token, "Poker action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    if (
        _handNumber != (floor _handNumber)
        || {_expectedRevision != (floor _expectedRevision)}
        || {_amount != (floor _amount)}
    ) exitWith {
        [_unit, _token, "Poker action rejected: chip and revision values must be whole numbers."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Poker action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_PokerActive", false])) exitWith {
        [_unit, _token, "There is no active Poker match at this table."] call Waldo_MG_fnc_resultServer;
    };
    if (_gameId != (_table getVariable ["Waldo_MG_PokerGameId", ""])) exitWith {
        [_unit, _token, "That Poker session has already changed."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_PokerPlayers", []];
    private _role = _players find _unit;
    if (_role < 0) exitWith {
        [_unit, _token, "Only assigned Poker players may use this table."] call Waldo_MG_fnc_resultServer;
    };
    private _state = +(_table getVariable ["Waldo_MG_PokerSnapshotServer", []]);
    if (_handNumber != (_state param [1, -2])) exitWith {
        [_unit, _token, "That Poker hand has already changed."] call Waldo_MG_fnc_resultServer;
    };

    if (_action == "SYNC_HAND") exitWith {
        [_table, _role] call Waldo_MG_fnc_pokerSendPrivateHandServer;
        [_unit, _token, "Your private hand was synchronized."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "RESET") exitWith {
        if (!(_table getVariable ["Waldo_MG_PokerFinished", false])) then {
            [_unit, _token, "The Poker match must finish before returning to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_pokerResetServer;
            [_unit, _token, "Poker cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };

    private _phase = _state param [0, "IDLE"];
    if (_action in ["REVEAL", "MUCK"]) exitWith {
        if (!(_phase in ["HAND_END", "MATCH_END"])) then {
            [_unit, _token, "Cards may only be revealed after the hand is settled."] call Waldo_MG_fnc_resultServer;
        } else {
            private _choices = +(_state param [23, []]);
            private _revealed = +(_state param [17, []]);
            if (_action == "REVEAL") then {
                private _hands = _table getVariable ["Waldo_MG_PokerHandsServer", []];
                _revealed set [_role, +(_hands param [_role, []])];
                _choices set [_role, 1];
            } else {
                if ((count (_revealed param [_role, []])) <= 0) then {
                    _choices set [_role, 0];
                };
            };
            _state set [17, _revealed];
            _state set [23, _choices];
            [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
            [_unit, _token, if (_action == "REVEAL") then {
                "Your cards are now visible to the table."
            } else {
                "Your cards remain hidden."
            }] call Waldo_MG_fnc_resultServer;
        };
    };

    if (_action == "NEXT_HAND") exitWith {
        if (_phase != "HAND_END" || {_table getVariable ["Waldo_MG_PokerFinished", false]}) then {
            [_unit, _token, "The next hand is not available right now."] call Waldo_MG_fnc_resultServer;
        } else {
            private _chips = +(_state param [6, []]);
            private _statuses = +(_state param [9, []]);
            if ((_chips param [_role, 0]) <= 0 || {(_statuses param [_role, "LEFT"]) == "LEFT"}) then {
                [_unit, _token, "Only players with chips may ready for the next hand."] call Waldo_MG_fnc_resultServer;
            } else {
                private _ready = +(_state param [18, []]);
                private _choices = +(_state param [23, []]);
                _ready set [_role, true];
                if ((_choices param [_role, -1]) < 0) then {_choices set [_role, 0];};
                _state set [18, _ready];
                _state set [23, _choices];
                private _allReady = true;
                for "_other" from 0 to ((count _chips) - 1) do {
                    if (
                        (_chips param [_other, 0]) > 0
                        && {(_statuses param [_other, "LEFT"]) != "LEFT"}
                        && {!(_ready param [_other, false])}
                    ) then {
                        _allReady = false;
                    };
                };
                if (_allReady) then {
                    _table setVariable ["Waldo_MG_PokerSnapshotServer", _state];
                    if ([_table] call Waldo_MG_fnc_pokerStartHandServer) then {
                        [_unit, _token, "Everyone is ready. The next Poker hand has begun."] call Waldo_MG_fnc_resultServer;
                    } else {
                        [_unit, _token, "The next Poker hand could not start because too few players remain."] call Waldo_MG_fnc_resultServer;
                    };
                } else {
                    [_table, _state] call Waldo_MG_fnc_pokerSetSnapshotServer;
                    [_unit, _token, "Ready for the next hand. Waiting for the other chip holders."] call Waldo_MG_fnc_resultServer;
                };
            };
        };
    };

    if (!(_phase in ["PREFLOP", "FLOP", "TURN", "RIVER"])) exitWith {
        [_unit, _token, "Betting is not active right now."] call Waldo_MG_fnc_resultServer;
    };
    if (!alive _unit || {(lifeState _unit) == "INCAPACITATED"}) exitWith {
        [_unit, _token, "You cannot act at the Poker table in your current state."] call Waldo_MG_fnc_resultServer;
    };
    private _revision = _table getVariable ["Waldo_MG_PokerRevision", 0];
    if (_expectedRevision != _revision) exitWith {
        [_unit, _token, "The Poker table changed before that action arrived. Please act again."] call Waldo_MG_fnc_resultServer;
    };
    if ((_state param [5, -1]) != _role) exitWith {
        [_unit, _token, "It is another player's turn."] call Waldo_MG_fnc_resultServer;
    };
    private _statuses = +(_state param [9, []]);
    if ((_statuses param [_role, "LEFT"]) != "ACTIVE") exitWith {
        [_unit, _token, "Your hand is no longer able to bet."] call Waldo_MG_fnc_resultServer;
    };
    private _pending = +(_state param [19, []]);
    if (!(_pending param [_role, false])) exitWith {
        [_unit, _token, "Your action for this betting round is already complete."] call Waldo_MG_fnc_resultServer;
    };

    private _chips = +(_state param [6, []]);
    private _bets = +(_state param [7, []]);
    private _contributions = +(_state param [8, []]);
    private _actions = +(_state param [10, []]);
    private _lastActed = +(_state param [20, []]);
    private _currentBet = _state param [13, 0];
    private _lastFullRaise = _state param [14, Waldo_MG_CFG_POKER_BIG_BLIND];
    private _fullBetEstablished = _state param [22, false];
    private _stack = _chips param [_role, 0];
    private _streetBet = _bets param [_role, 0];
    private _toCall = 0 max (_currentBet - _streetBet);
    private _message = "Poker action accepted.";
    private _valid = true;
    private _handledBet = false;

    if (_action == "FOLD") then {
        _statuses set [_role, "FOLDED"];
        _pending set [_role, false];
        _lastActed set [_role, _currentBet];
        _actions set [_role, "Fold"];
        _message = "Hand folded.";
        _handledBet = true;
    };

    if (_action == "CHECK_CALL") then {
        private _paid = _stack min _toCall;
        _chips set [_role, _stack - _paid];
        _bets set [_role, _streetBet + _paid];
        _contributions set [_role, (_contributions param [_role, 0]) + _paid];
        _pending set [_role, false];
        _lastActed set [_role, _currentBet];
        if (_toCall <= 0) then {
            _actions set [_role, "Check"];
            _message = "Checked.";
        } else {
            if (_paid < _toCall || {(_chips param [_role, 0]) <= 0}) then {
                _statuses set [_role, "ALL_IN"];
                _actions set [_role, format ["All in for %1", _bets param [_role, 0]]];
                _message = "Called all in.";
            } else {
                _actions set [_role, format ["Called %1", _paid]];
                _message = format ["Called %1 chips.", _paid];
            };
        };
        _handledBet = true;
    };

    if (_action == "ALL_IN") then {
        _amount = _streetBet + _stack;
        if (_amount <= _currentBet) then {
            private _paid = _stack;
            _chips set [_role, 0];
            _bets set [_role, _streetBet + _paid];
            _contributions set [_role, (_contributions param [_role, 0]) + _paid];
            _statuses set [_role, "ALL_IN"];
            _pending set [_role, false];
            _lastActed set [_role, _currentBet];
            _actions set [_role, format ["All in for %1", _bets param [_role, 0]]];
            _message = "All-in call accepted.";
            _handledBet = true;
        } else {
            _action = "BET_TO";
        };
    };

    if (_action == "BET_TO") then {
        private _totalAvailable = _streetBet + _stack;
        private _actedAt = _lastActed param [_role, -1];
        private _reopenIncrement = if (_fullBetEstablished) then {
            _lastFullRaise
        } else {
            Waldo_MG_CFG_POKER_BIG_BLIND
        };
        private _canRaise = _actedAt < 0
            || {(_currentBet - _actedAt) >= _reopenIncrement};
        private _minimumTarget = if (!_fullBetEstablished) then {
            Waldo_MG_CFG_POKER_BIG_BLIND
        } else {
            _currentBet + _lastFullRaise
        };
        if (!_canRaise) then {
            _valid = false;
            _message = "A short all-in did not reopen your right to raise; call or fold.";
        };
        if (_amount <= _currentBet) then {
            _valid = false;
            _message = "Raise-to must exceed the current bet.";
        };
        if (_amount > _totalAvailable) then {
            _valid = false;
            _message = "That raise exceeds your available stack.";
        };
        if (_amount < _minimumTarget && {_amount != _totalAvailable}) then {
            _valid = false;
            _message = format ["Minimum legal raise-to is %1, unless you are all in.", _minimumTarget];
        };
        if (_valid) then {
            private _paid = _amount - _streetBet;
            private _increase = _amount - _currentBet;
            private _wasFullEstablished = _fullBetEstablished;
            private _fullRaise = if (!_wasFullEstablished) then {
                _amount >= Waldo_MG_CFG_POKER_BIG_BLIND
            } else {
                _increase >= _lastFullRaise
            };
            _chips set [_role, _stack - _paid];
            _bets set [_role, _amount];
            _contributions set [_role, (_contributions param [_role, 0]) + _paid];
            _currentBet = _amount;
            if ((_chips param [_role, 0]) <= 0) then {
                _statuses set [_role, "ALL_IN"];
                _actions set [_role, format ["Raised all in to %1", _amount]];
                _message = format ["All-in raise to %1 accepted.", _amount];
            } else {
                _actions set [_role, format ["Raised to %1", _amount]];
                _message = format ["Raised to %1 chips.", _amount];
            };
            if (_fullRaise) then {
                if (!_wasFullEstablished) then {
                    _lastFullRaise = _amount;
                    _fullBetEstablished = true;
                } else {
                    _lastFullRaise = _increase;
                };
                for "_other" from 0 to ((count _statuses) - 1) do {
                    if (_other != _role && {(_statuses param [_other, "LEFT"]) == "ACTIVE"}) then {
                        _pending set [_other, true];
                    };
                };
            } else {
                for "_other" from 0 to ((count _statuses) - 1) do {
                    if (
                        _other != _role
                        && {(_statuses param [_other, "LEFT"]) == "ACTIVE"}
                        && {(_bets param [_other, 0]) < _currentBet}
                    ) then {
                        _pending set [_other, true];
                    };
                };
            };
            _pending set [_role, false];
            _lastActed set [_role, _currentBet];
            _handledBet = true;
        };
    };

    if (!_handledBet || {!_valid}) exitWith {
        [_unit, _token, if (_valid) then {"Unknown Poker betting action."} else {_message}] call Waldo_MG_fnc_resultServer;
    };
    private _pot = 0;
    {_pot = _pot + _x;} forEach _contributions;
    _state set [5, _role];
    _state set [6, _chips];
    _state set [7, _bets];
    _state set [8, _contributions];
    _state set [9, _statuses];
    _state set [10, _actions];
    _state set [12, _pot];
    _state set [13, _currentBet];
    _state set [14, _lastFullRaise];
    _state set [19, _pending];
    _state set [20, _lastActed];
    _state set [22, _fullBetEstablished];
    [_table, _state] call Waldo_MG_fnc_pokerProgressServer;
    [_unit, _token, _message] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitPokerActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""],
        ["_amount", 0]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {};
    private _pending = missionNamespace getVariable ["Waldo_MG_PokerPendingRequestLocal", []];
    if ((count _pending) >= 2 && {(diag_tickTime - (_pending param [1, -10])) < 1.5}) exitWith {
        ["Waiting for the table host to answer your previous Poker action..."] call Waldo_MG_fnc_notifyLocal;
    };
    private _snapshot = _table getVariable ["Waldo_MG_PokerSnapshot", []];
    private _token = ["POKER_ACTION"] call Waldo_MG_fnc_makeToken;
    missionNamespace setVariable ["Waldo_MG_PokerPendingRequestLocal", [_token, diag_tickTime]];
    private _request = [
            _token,
            netId _table,
            _table getVariable ["Waldo_MG_PokerGameId", ""],
            _snapshot param [1, -1],
            _table getVariable ["Waldo_MG_PokerRevision", -1],
            _action,
            floor _amount
    ];
    ["POKER", _table, _token, _request param [3, -1], _request] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_getPokerPlayerRoleLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {-1};
    (_table getVariable ["Waldo_MG_PokerPlayers", []]) find player
};

Waldo_MG_fnc_pokerGetMarkerTextureLocal = {
    params [["_suit", -1]];
    private _markerClass = [_suit] call Waldo_MG_fnc_pokerSuitMarkerClass;
    if (_markerClass == "") exitWith {""};
    private _config = configFile >> "CfgMarkers" >> _markerClass;
    private _texture = getText (_config >> "icon");
    if (_texture == "") then {_texture = getText (_config >> "texture");};
    _texture
};

Waldo_MG_fnc_pokerShortCardLocal = {
    params [["_card", -1]];
    if (_card < 0 || {_card > 51}) exitWith {"??"};
    format [
        "%1%2",
        [[_card] call Waldo_MG_fnc_pokerCardRank] call Waldo_MG_fnc_pokerRankLabel,
        [[_card] call Waldo_MG_fnc_pokerCardSuit] call Waldo_MG_fnc_pokerSuitLetter
    ]
};

Waldo_MG_fnc_createPokerCardControlsLocal = {
    disableSerialization;
    params [
        ["_display", displayNull],
        ["_x", 0],
        ["_y", 0],
        ["_width", 0.12],
        ["_height", 0.20],
        ["_contentScale", 1]
    ];
    if (isNull _display) exitWith {[]};
    _contentScale = (0.75 max _contentScale) min 1.5;
    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [_x, _y, _width, _height];
    _background ctrlSetBackgroundColor [0.93, 0.91, 0.82, 1];
    _background ctrlCommit 0;
    private _rankTop = _display ctrlCreate ["RscText", -1];
    if (_contentScale > 1) then {
        _rankTop ctrlSetPosition [_x + (_width * 0.48), _y + 0.002, _width * 0.48, _height * 0.38];
    } else {
        _rankTop ctrlSetPosition [_x + _width - 0.060, _y + 0.004, 0.052, 0.040];
    };
    _rankTop ctrlSetFontHeight (0.027 * _contentScale);
    _rankTop ctrlCommit 0;
    private _rankBottom = _display ctrlCreate ["RscText", -1];
    if (_contentScale > 1) then {
        _rankBottom ctrlSetPosition [_x + (_width * 0.04), _y + (_height * 0.62), _width * 0.48, _height * 0.36];
    } else {
        _rankBottom ctrlSetPosition [_x + 0.008, _y + _height - 0.046, 0.052, 0.040];
    };
    _rankBottom ctrlSetFontHeight (0.027 * _contentScale);
    _rankBottom ctrlCommit 0;
    private _marker = _display ctrlCreate ["RscPictureKeepAspect", -1];
    _marker ctrlSetPosition [_x + (_width * 0.18), _y + (_height * 0.22), _width * 0.64, _height * 0.54];
    _marker ctrlEnable false;
    _marker ctrlCommit 0;
    private _back = _display ctrlCreate ["RscText", -1];
    _back ctrlSetPosition [_x + (_width * 0.08), _y + (_height * 0.33), _width * 0.84, _height * 0.34];
    _back ctrlSetText "WMP";
    _back ctrlSetTextColor [0.64, 0.82, 0.96, 1];
    _back ctrlSetFontHeight (0.026 * _contentScale);
    _back ctrlCommit 0;
    [_background, _rankTop, _rankBottom, _marker, _back]
};

Waldo_MG_fnc_renderPokerCardLocal = {
    disableSerialization;
    params [
        ["_bundle", []],
        ["_card", -1]
    ];
    if ((count _bundle) < 5) exitWith {};
    private _background = _bundle param [0, controlNull];
    private _rankTop = _bundle param [1, controlNull];
    private _rankBottom = _bundle param [2, controlNull];
    private _marker = _bundle param [3, controlNull];
    private _back = _bundle param [4, controlNull];
    if (isNull _background) exitWith {};
    private _front = _card >= 0 && {_card <= 51};
    private _cardBack = _card == -2;
    {
        if (!isNull _x) then {_x ctrlShow _front;};
    } forEach [_rankTop, _rankBottom];
    if (!isNull _marker) then {_marker ctrlShow _front;};
    if (!isNull _back) then {_back ctrlShow _cardBack;};
    private _oldCard = _background getVariable ["Waldo_MG_PokerRenderedCard", -99];
    if (_oldCard == _card) exitWith {};
    _background setVariable ["Waldo_MG_PokerRenderedCard", _card];
    if (_front) then {
        private _rank = [_card] call Waldo_MG_fnc_pokerCardRank;
        private _suit = [_card] call Waldo_MG_fnc_pokerCardSuit;
        private _rankText = [_rank] call Waldo_MG_fnc_pokerRankLabel;
        private _colour = if (_suit in [2, 3]) then {[0.78, 0.10, 0.09, 1]} else {[0.06, 0.20, 0.36, 1]};
        _background ctrlSetBackgroundColor [0.94, 0.92, 0.84, 1];
        _background ctrlSetTooltip ([_card] call Waldo_MG_fnc_pokerCardName);
        if (!isNull _rankTop) then {_rankTop ctrlSetText _rankText; _rankTop ctrlSetTextColor _colour;};
        if (!isNull _rankBottom) then {_rankBottom ctrlSetText _rankText; _rankBottom ctrlSetTextColor _colour;};
        if (!isNull _marker) then {
            _marker ctrlSetText ([_suit] call Waldo_MG_fnc_pokerGetMarkerTextureLocal);
            _marker ctrlSetTextColor _colour;
        };
    } else {
        _background ctrlSetTooltip "";
        _background ctrlSetBackgroundColor (if (_cardBack) then {[0.035, 0.16, 0.28, 1]} else {[0.04, 0.055, 0.07, 0.75]});
    };
    {
        if (!isNull _x) then {_x ctrlCommit 0;};
    } forEach _bundle;
};

Waldo_MG_fnc_pokerDefocusLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    private _sink = _display getVariable ["Waldo_MG_PokerFocusSink", controlNull];
    if (!isNull _sink) then {ctrlSetFocus _sink;};
};

Waldo_MG_fnc_adjustPokerRaiseLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_pokerDefocusLocal;
    private _target = _display getVariable ["Waldo_MG_PokerRaiseTarget", 0];
    private _delta = _control getVariable ["Waldo_MG_PokerRaiseDelta", 0];
    private _minimum = _display getVariable ["Waldo_MG_PokerRaiseMinimum", 0];
    private _maximum = _display getVariable ["Waldo_MG_PokerRaiseMaximum", 0];
    _target = (_minimum max (_target + _delta)) min _maximum;
    _display setVariable ["Waldo_MG_PokerRaiseTarget", _target];
    [_display] call Waldo_MG_fnc_refreshPokerLocal;
};

Waldo_MG_fnc_submitPokerButtonLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    [_display] call Waldo_MG_fnc_pokerDefocusLocal;
    private _table = _display getVariable ["Waldo_MG_PokerTable", objNull];
    private _action = _control getVariable ["Waldo_MG_PokerAction", ""];
    private _amount = if (_action == "BET_TO") then {
        _display getVariable ["Waldo_MG_PokerRaiseTarget", 0]
    } else {
        0
    };
    [_table, _action, _amount] call Waldo_MG_fnc_submitPokerActionRequestLocal;
};

Waldo_MG_fnc_refreshPokerLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_PokerRefreshing", false]}) exitWith {};
    _display setVariable ["Waldo_MG_PokerRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_PokerTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)) exitWith {
        _display setVariable ["Waldo_MG_PokerRefreshing", false];
        _display closeDisplay 1;
    };
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "poker") exitWith {
        _display setVariable ["Waldo_MG_PokerRefreshing", false];
        if (_spectating) then {
            [true] call Waldo_MG_fnc_exitSpectatorLocal;
        } else {
            _display closeDisplay 1;
            [_table] spawn {
                params ["_lobbyTable"];
                uiSleep 0.1;
                if (!isNull _lobbyTable && {_lobbyTable == (player getVariable ["Waldo_MG_SeatedTable", objNull])}) then {
                    [_lobbyTable] call Waldo_MG_fnc_openLobbyLocal;
                };
            };
        };
    };
    private _state = _table getVariable ["Waldo_MG_PokerSnapshot", []];
    private _phase = _state param [0, "IDLE"];
    private _handNumber = _state param [1, 0];
    private _dealer = _state param [2, -1];
    private _smallBlind = _state param [3, -1];
    private _bigBlind = _state param [4, -1];
    private _turn = _state param [5, -1];
    private _chips = _state param [6, []];
    private _bets = _state param [7, []];
    private _totalContributions = _state param [8, []];
    private _statuses = _state param [9, []];
    private _actions = _state param [10, []];
    private _community = _state param [11, []];
    private _pot = _state param [12, 0];
    private _currentBet = _state param [13, 0];
    private _lastFullRaise = _state param [14, Waldo_MG_CFG_POKER_BIG_BLIND];
    private _revealed = _state param [17, []];
    private _nextReady = _state param [18, []];
    private _pending = _state param [19, []];
    private _lastActed = _state param [20, []];
    private _fullBetEstablished = _state param [22, false];
    private _choices = _state param [23, []];
    private _role = [_table] call Waldo_MG_fnc_getPokerPlayerRoleLocal;
    private _names = _table getVariable ["Waldo_MG_PokerPlayerNames", []];
    private _revision = _table getVariable ["Waldo_MG_PokerRevision", 0];
    private _betting = _phase in ["PREFLOP", "FLOP", "TURN", "RIVER"];
    private _handEnded = _phase in ["HAND_END", "MATCH_END"];

    private _potLabel = _display getVariable ["Waldo_MG_PokerPotLabel", controlNull];
    private _streetLabel = _display getVariable ["Waldo_MG_PokerStreetLabel", controlNull];
    private _statusLabel = _display getVariable ["Waldo_MG_PokerStatusLabel", controlNull];
    if (!isNull _potLabel) then {
        private _potBreakdown = [_totalContributions, _statuses] call Waldo_MG_fnc_pokerBuildSidePots;
        private _potParts = [];
        { _potParts pushBack format ["%1 %2", if (_forEachIndex == 0) then {"MAIN"} else {format ["SIDE %1", _forEachIndex]}, _x param [0, 0]]; } forEach _potBreakdown;
        _potLabel ctrlSetText (if ((count _potParts) > 0) then {_potParts joinString "  |  "} else {format ["POT  %1", _pot]});
        _potLabel ctrlSetTooltip format ["Total pot: %1 chips. Main and side pots reflect committed contributions.", _pot];
        _potLabel ctrlCommit 0;
    };
    if (!isNull _streetLabel) then {
        _streetLabel ctrlSetText format ["HAND %1  /  %2  /  TABLE BET %3", _handNumber, _phase, _currentBet];
        _streetLabel ctrlCommit 0;
    };
    private _statusLabelTwo = _display getVariable ["Waldo_MG_PokerStatusLabelTwo", controlNull];
    private _statusText = _state param [16, "Poker in progress."];
    if (_statusText != (_display getVariable ["Waldo_MG_PokerRenderedStatus", ""])) then {
        private _lineOneWords = [];
        private _lineTwoWords = [];
        {
            private _candidate = (_lineOneWords + [_x]) joinString " ";
            if ((count _candidate) <= 88 || {(count _lineOneWords) == 0}) then {
                _lineOneWords pushBack _x;
            } else {
                _lineTwoWords pushBack _x;
            };
        } forEach (_statusText splitString " ");
        private _lineOne = _lineOneWords joinString " ";
        private _lineTwo = _lineTwoWords joinString " ";
        if (!isNull _statusLabel) then {
            _statusLabel ctrlSetText _lineOne;
            _statusLabel ctrlSetTooltip _statusText;
            _statusLabel ctrlCommit 0;
        };
        if (!isNull _statusLabelTwo) then {
            _statusLabelTwo ctrlSetText _lineTwo;
            _statusLabelTwo ctrlSetTooltip _statusText;
            _statusLabelTwo ctrlCommit 0;
        };
        _display setVariable ["Waldo_MG_PokerRenderedStatus", _statusText];
    };

    private _playerRows = _display getVariable ["Waldo_MG_PokerPlayerRows", []];
    for "_row" from 0 to ((count _playerRows) - 1) do {
        private _bundle = _playerRows param [_row, []];
        private _rowBackground = _bundle param [0, controlNull];
        private _nameControl = _bundle param [1, controlNull];
        private _stackControl = _bundle param [2, controlNull];
        private _actionControl = _bundle param [3, controlNull];
        private _dealerBadge = _bundle param [4, controlNull];
        private _smallBadge = _bundle param [5, controlNull];
        private _bigBadge = _bundle param [6, controlNull];
        private _rowExists = _row < (count _names);
        if (!isNull _rowBackground) then {
            _rowBackground ctrlShow _rowExists;
            _rowBackground ctrlSetBackgroundColor (if (_row == _turn && {_betting}) then {
                [0.34, 0.24, 0.07, 0.98]
            } else {
                if (_row == _role) then {[0.04, 0.18, 0.29, 0.98]} else {[0.025, 0.055, 0.075, 0.96]}
            });
        };
        if (_rowExists) then {
            private _playerName = _names param [_row, "Player"];
            if (!isNull _nameControl) then {
                _nameControl ctrlSetText _playerName;
                _nameControl ctrlSetTooltip _playerName;
            };
            if (!isNull _stackControl) then {
                private _stackText = format [
                    "%1 CHIPS   %2",
                    _chips param [_row, 0],
                    _statuses param [_row, "WAITING"]
                ];
                _stackControl ctrlSetText _stackText;
                _stackControl ctrlSetTooltip _stackText;
            };
            private _shown = _revealed param [_row, []];
            private _shownText = if ((count _shown) >= 2) then {
                format ["   SHOWS %1 %2", [_shown param [0, -1]] call Waldo_MG_fnc_pokerShortCardLocal, [_shown param [1, -1]] call Waldo_MG_fnc_pokerShortCardLocal]
            } else {
                if ((_choices param [_row, -1]) == 0) then {"   MUCKED"} else {""}
            };
            if (!isNull _actionControl) then {
                private _actionText = format [
                    "BET %1 | %2%3",
                    _bets param [_row, 0],
                    _actions param [_row, "Waiting"],
                    _shownText
                ];
                _actionControl ctrlSetText _actionText;
                _actionControl ctrlSetTooltip _actionText;
            };
        };
        if (!isNull _dealerBadge) then {_dealerBadge ctrlShow (_rowExists && {_row == _dealer});};
        if (!isNull _smallBadge) then {_smallBadge ctrlShow (_rowExists && {_row == _smallBlind});};
        if (!isNull _bigBadge) then {_bigBadge ctrlShow (_rowExists && {_row == _bigBlind});};
        {if (!isNull _x) then {_x ctrlCommit 0;};} forEach _bundle;
    };

    private _communityBundles = _display getVariable ["Waldo_MG_PokerCommunityCards", []];
    for "_index" from 0 to ((count _communityBundles) - 1) do {
        [
            _communityBundles param [_index, []],
            if (_index < (count _community)) then {_community param [_index, -1]} else {-2}
        ] call Waldo_MG_fnc_renderPokerCardLocal;
    };

    private _privatePayload = if (_spectating) then {[]} else {player getVariable ["Waldo_MG_PokerPrivateHand", []]};
    private _privateCards = [];
    if (
        (_privatePayload param [0, ""]) == (_table getVariable ["Waldo_MG_PokerGameId", ""])
        && {(_privatePayload param [1, -1]) == _handNumber}
    ) then {
        _privateCards = +(_privatePayload param [2, []]);
    };
    private _holeBundles = _display getVariable ["Waldo_MG_PokerHoleCards", []];
    for "_index" from 0 to ((count _holeBundles) - 1) do {
        [_holeBundles param [_index, []], if (_index < (count _privateCards)) then {_privateCards param [_index, -1]} else {if (_spectating) then {-1} else {-2}}] call Waldo_MG_fnc_renderPokerCardLocal;
    };
    if ((count _privateCards) < 2 && {_betting} && {_role >= 0} && {(_statuses param [_role, "LEFT"]) in ["ACTIVE", "ALL_IN", "FOLDED"]}) then {
        private _lastSync = _display getVariable ["Waldo_MG_PokerLastHandSync", -10];
        if ((diag_tickTime - _lastSync) > 2.5) then {
            _display setVariable ["Waldo_MG_PokerLastHandSync", diag_tickTime];
            [_table, "SYNC_HAND", 0] call Waldo_MG_fnc_submitPokerActionRequestLocal;
        };
    };
    private _handLabel = _display getVariable ["Waldo_MG_PokerHandLabel", controlNull];
    private _handTitle = _display getVariable ["Waldo_MG_PokerHandTitle", controlNull];
    if (!isNull _handTitle) then {
        _handTitle ctrlSetText (if (_spectating) then {"SPECTATOR VIEW"} else {"YOUR PRIVATE HAND"});
        _handTitle ctrlCommit 0;
    };
    if (!isNull _handLabel) then {
        private _handText = if (_spectating) then {
            "SPECTATOR VIEW: PRIVATE HANDS REMAIN HIDDEN"
        } else {
            if ((count _privateCards) < 2) then {
            "Waiting for secure deal..."
            } else {
                if ((count _community) >= 3) then {
                    private _evaluationKey = str (_privateCards + _community);
                    private _evaluationLabel = _display getVariable ["Waldo_MG_PokerEvaluationLabel", ""];
                    if (_evaluationKey != (_display getVariable ["Waldo_MG_PokerEvaluationKey", ""])) then {
                        private _evaluation = [_privateCards + _community] call Waldo_MG_fnc_pokerEvaluateBest;
                        _evaluationLabel = _evaluation param [2, "High Card"];
                        _display setVariable ["Waldo_MG_PokerEvaluationKey", _evaluationKey];
                        _display setVariable ["Waldo_MG_PokerEvaluationLabel", _evaluationLabel];
                    };
                    format ["YOUR BEST HAND: %1", _evaluationLabel]
                } else {
                    format ["YOUR HAND: %1  %2", [_privateCards param [0, -1]] call Waldo_MG_fnc_pokerShortCardLocal, [_privateCards param [1, -1]] call Waldo_MG_fnc_pokerShortCardLocal]
                }
            }
        };
        _handLabel ctrlSetText _handText;
        _handLabel ctrlCommit 0;
    };

    private _foldButton = _display getVariable ["Waldo_MG_PokerFoldButton", controlNull];
    private _callButton = _display getVariable ["Waldo_MG_PokerCallButton", controlNull];
    private _allInButton = _display getVariable ["Waldo_MG_PokerAllInButton", controlNull];
    private _raiseButton = _display getVariable ["Waldo_MG_PokerRaiseButton", controlNull];
    private _raiseLabel = _display getVariable ["Waldo_MG_PokerRaiseLabel", controlNull];
    private _raiseTargetLabel = _display getVariable ["Waldo_MG_PokerRaiseTargetLabel", controlNull];
    private _adjustButtons = _display getVariable ["Waldo_MG_PokerAdjustButtons", []];
    private _revealButton = _display getVariable ["Waldo_MG_PokerRevealButton", controlNull];
    private _muckButton = _display getVariable ["Waldo_MG_PokerMuckButton", controlNull];
    private _nextButton = _display getVariable ["Waldo_MG_PokerNextButton", controlNull];
    private _yourStatus = if (_role >= 0) then {_statuses param [_role, "OBSERVER"]} else {"OBSERVER"};
    private _yourStack = if (_role >= 0) then {_chips param [_role, 0]} else {0};
    private _yourBet = if (_role >= 0) then {_bets param [_role, 0]} else {0};
    private _toCall = 0 max (_currentBet - _yourBet);
    private _yourTurn = _betting && {_role == _turn} && {_yourStatus == "ACTIVE"} && {_pending param [_role, false]};
    private _actedAt = if (_role >= 0) then {_lastActed param [_role, -1]} else {-1};
    private _reopenIncrement = if (_fullBetEstablished) then {_lastFullRaise} else {Waldo_MG_CFG_POKER_BIG_BLIND};
    private _canRaise = _actedAt < 0 || {(_currentBet - _actedAt) >= _reopenIncrement};
    private _minimumRaise = if (!_fullBetEstablished) then {Waldo_MG_CFG_POKER_BIG_BLIND} else {_currentBet + _lastFullRaise};
    private _maximumRaise = _yourBet + _yourStack;
    private _canFullRaise = _yourTurn && {_canRaise} && {_maximumRaise >= _minimumRaise} && {_maximumRaise > _currentBet};
    private _raiseTarget = _display getVariable ["Waldo_MG_PokerRaiseTarget", _minimumRaise];
    if ((_display getVariable ["Waldo_MG_PokerRaiseRevision", -1]) != _revision) then {
        _raiseTarget = _minimumRaise min _maximumRaise;
        _display setVariable ["Waldo_MG_PokerRaiseRevision", _revision];
    };
    _raiseTarget = (_minimumRaise max _raiseTarget) min _maximumRaise;
    _display setVariable ["Waldo_MG_PokerRaiseTarget", _raiseTarget];
    _display setVariable ["Waldo_MG_PokerRaiseMinimum", _minimumRaise];
    _display setVariable ["Waldo_MG_PokerRaiseMaximum", _maximumRaise];
    private _waitReason = if (_spectating) then {"Spectators are read-only."} else {if (!_betting) then {"Betting is closed."} else {if (!_yourTurn) then {"Wait for the acting player."} else {"Available."}}};
    if (!isNull _foldButton) then {_foldButton ctrlShow (_betting && {!_spectating}); _foldButton ctrlEnable (!_spectating && {_yourTurn}); _foldButton ctrlSetTooltip _waitReason;};
    if (!isNull _callButton) then {
        _callButton ctrlShow (_betting && {!_spectating});
        _callButton ctrlEnable (!_spectating && {_yourTurn});
        _callButton ctrlSetText (if (_toCall <= 0) then {"Check"} else {format ["Call %1", _yourStack min _toCall]});
        _callButton ctrlSetTooltip _waitReason;
    };
    if (!isNull _allInButton) then {
        private _allInLegal = _yourTurn && {_yourStack > 0} && {(_maximumRaise <= _currentBet) || {_canRaise}};
        _allInButton ctrlShow (_betting && {!_spectating});
        _allInButton ctrlEnable (!_spectating && {_allInLegal});
        _allInButton ctrlSetText format ["All In %1", _yourStack];
        _allInButton ctrlSetTooltip (if (_allInLegal) then {"Commit your entire remaining stack."} else {_waitReason});
    };
    if (!isNull _raiseButton) then {
        _raiseButton ctrlShow (_betting && {!_spectating});
        _raiseButton ctrlEnable (!_spectating && {_canFullRaise});
        _raiseButton ctrlSetText format ["Raise %1", _raiseTarget];
        _raiseButton ctrlSetTooltip (if (_canFullRaise) then {format ["Raise the street total to %1.", _raiseTarget]} else {if (!_canRaise) then {"A short all-in did not reopen raising."} else {_waitReason}});
    };
    if (!isNull _raiseLabel) then {
        _raiseLabel ctrlShow (_betting && {!_spectating});
        _raiseLabel ctrlSetText format ["TO CALL %1   MINIMUM RAISE-TO %2   STACK %3", _toCall, _minimumRaise, _yourStack];
    };
    if (!isNull _raiseTargetLabel) then {
        _raiseTargetLabel ctrlShow (_betting && {!_spectating});
        _raiseTargetLabel ctrlSetText format ["RAISE-TO TARGET: %1", _raiseTarget];
        _raiseTargetLabel ctrlSetTooltip format ["The raise button will set your total street bet to %1 chips.", _raiseTarget];
    };
    {if (!isNull _x) then {_x ctrlShow (_betting && {!_spectating}); _x ctrlEnable (!_spectating && {_canFullRaise});};} forEach _adjustButtons;
    private _alreadyRevealed = _role >= 0 && {(count (_revealed param [_role, []])) >= 2};
    if (!isNull _revealButton) then {
        _revealButton ctrlShow (_handEnded && {!_spectating});
        _revealButton ctrlEnable (!_spectating && {_handEnded} && {!_alreadyRevealed} && {(count _privateCards) >= 2});
        _revealButton ctrlSetText (if (_alreadyRevealed) then {"Cards Revealed"} else {"Reveal Cards"});
    };
    if (!isNull _muckButton) then {
        _muckButton ctrlShow (_handEnded && {!_spectating});
        _muckButton ctrlEnable (!_spectating && {_handEnded} && {!_alreadyRevealed});
        _muckButton ctrlSetText (if (_role >= 0 && {(_choices param [_role, -1]) == 0}) then {"Kept Hidden"} else {"Keep Hidden"});
    };
    if (!isNull _nextButton) then {
        _nextButton ctrlShow (_handEnded && {!_spectating});
        if (_phase == "MATCH_END") then {
            _nextButton ctrlSetText "Reset to Lobby";
            _nextButton setVariable ["Waldo_MG_PokerAction", "RESET"];
            _nextButton ctrlEnable !_spectating;
        } else {
            _nextButton ctrlSetText (if (_role >= 0 && {_nextReady param [_role, false]}) then {"Ready - Waiting"} else {"Ready Next Hand"});
            _nextButton setVariable ["Waldo_MG_PokerAction", "NEXT_HAND"];
            _nextButton ctrlEnable (!_spectating && {_yourStack > 0} && {_role >= 0} && {!(_nextReady param [_role, false])});
        };
    };
    {
        if (!isNull _x) then {_x ctrlCommit 0;};
    } forEach ([_foldButton, _callButton, _allInButton, _raiseButton, _raiseLabel, _raiseTargetLabel, _revealButton, _muckButton, _nextButton] + _adjustButtons);
    _display setVariable ["Waldo_MG_PokerRefreshing", false];
};

Waldo_MG_fnc_scalePokerDisplayLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display || {_display getVariable ["Waldo_MG_PokerScaleApplied", false]}) exitWith {};
    private _scale = Waldo_MG_CFG_POKER_UI_SCALE max 0.5;
    private _center = Waldo_MG_CFG_POKER_UI_CENTER;
    private _centerX = _center param [0, 0.590];
    private _centerY = _center param [1, 0.5425];
    {
        private _position = ctrlPosition _x;
        private _oldX = _position param [0, -10];
        private _oldY = _position param [1, -10];
        if (_oldX > -5 && {_oldY > -5}) then {
            _x ctrlSetPosition [
                _centerX + ((_oldX - _centerX) * _scale),
                _centerY + ((_oldY - _centerY) * _scale),
                _position param [2, 0],
                _position param [3, 0]
            ];
            _x ctrlSetScale _scale;
            _x ctrlCommit 0;
        };
    } forEach (allControls _display);
    _display setVariable ["Waldo_MG_PokerScaleApplied", true];
};

Waldo_MG_fnc_openPokerLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "poker"}
    ) exitWith {["No active Poker match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;};
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {["The Poker display is unavailable."] call Waldo_MG_fnc_notifyLocal;};
    {
        if (!isNull _x) then {_x closeDisplay 1;};
    } forEach [
        uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_DrawPokerDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_LiarsDiceDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_ConnectFourDisplay", displayNull],
        uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull]
    ];
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_PokerDisplay", _display];
    _display setVariable ["Waldo_MG_TableGameDisplay", true];
    _display setVariable ["Waldo_MG_PokerTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_PokerRaiseTarget", Waldo_MG_CFG_POKER_BIG_BLIND * 2];
    _display setVariable ["Waldo_MG_PokerLastHandSync", -10];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal;
    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.005, 0.015, 1.17, 1.055];
    _background ctrlSetBackgroundColor [0.008, 0.017, 0.022, 0.985];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.005, 0.015, 1.17, 0.075];
    _topBar ctrlSetBackgroundColor [0.04, 0.25, 0.20, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.035, 0.026, 0.55, 0.052];
    _title ctrlSetText (if (_spectating) then {"PARTYGAMES  /  POKER SPECTATOR"} else {"PARTYGAMES  /  TEXAS HOLD'EM"});
    _title ctrlSetTextColor [0.87, 0.98, 0.91, 1];
    _title ctrlSetFontHeight 0.037;
    _title ctrlCommit 0;
    private _leaveButton = _display ctrlCreate ["RscButtonMenu", -1];
    _leaveButton ctrlSetPosition [0.990, 0.030, 0.150, 0.042];
    _leaveButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _leaveButton ctrlCommit 0;

    private _rosterFrame = _display ctrlCreate ["RscText", -1];
    _rosterFrame ctrlSetPosition [0.025, 0.110, 0.290, 0.615];
    _rosterFrame ctrlSetBackgroundColor [0.015, 0.035, 0.045, 0.98];
    _rosterFrame ctrlCommit 0;
    private _rosterTitle = _display ctrlCreate ["RscText", -1];
    _rosterTitle ctrlSetPosition [0.045, 0.122, 0.250, 0.035];
    _rosterTitle ctrlSetText "PLAYERS / ACTIONS";
    _rosterTitle ctrlSetTextColor [0.64, 0.86, 0.75, 1];
    _rosterTitle ctrlSetFontHeight 0.027;
    _rosterTitle ctrlCommit 0;
    private _playerRows = [];
    for "_row" from 0 to 3 do {
        private _y = 0.168 + (_row * 0.133);
        private _rowBackground = _display ctrlCreate ["RscText", -1];
        _rowBackground ctrlSetPosition [0.040, _y, 0.260, 0.120];
        _rowBackground ctrlCommit 0;
        private _nameControl = _display ctrlCreate ["RscText", -1];
        _nameControl ctrlSetPosition [0.052, _y + 0.008, 0.120, 0.032];
        _nameControl ctrlSetTextColor [0.90, 0.96, 1, 1];
        _nameControl ctrlSetFontHeight 0.028;
        _nameControl ctrlCommit 0;
        private _stackControl = _display ctrlCreate ["RscText", -1];
        _stackControl ctrlSetPosition [0.052, _y + 0.043, 0.235, 0.028];
        _stackControl ctrlSetTextColor [0.67, 0.78, 0.83, 1];
        _stackControl ctrlSetFontHeight 0.022;
        _stackControl ctrlCommit 0;
        private _actionControl = _display ctrlCreate ["RscText", -1];
        _actionControl ctrlSetPosition [0.052, _y + 0.078, 0.235, 0.030];
        _actionControl ctrlSetTextColor [0.96, 0.77, 0.34, 1];
        _actionControl ctrlSetFontHeight 0.022;
        _actionControl ctrlCommit 0;
        private _dealerBadge = _display ctrlCreate ["RscText", -1];
        _dealerBadge ctrlSetPosition [0.178, _y + 0.008, 0.030, 0.026];
        _dealerBadge ctrlSetText "D";
        _dealerBadge ctrlSetBackgroundColor [0.62, 0.45, 0.08, 1];
        _dealerBadge ctrlSetFontHeight 0.021;
        _dealerBadge ctrlCommit 0;
        private _smallBadge = _display ctrlCreate ["RscText", -1];
        _smallBadge ctrlSetPosition [0.212, _y + 0.008, 0.038, 0.026];
        _smallBadge ctrlSetText "SB";
        _smallBadge ctrlSetBackgroundColor [0.04, 0.28, 0.48, 1];
        _smallBadge ctrlSetTextColor [0.78, 0.92, 1, 1];
        _smallBadge ctrlSetTooltip "Small Blind";
        _smallBadge ctrlSetFontHeight 0.018;
        _smallBadge ctrlCommit 0;
        private _bigBadge = _display ctrlCreate ["RscText", -1];
        _bigBadge ctrlSetPosition [0.254, _y + 0.008, 0.038, 0.026];
        _bigBadge ctrlSetText "BB";
        _bigBadge ctrlSetBackgroundColor [0.50, 0.10, 0.07, 1];
        _bigBadge ctrlSetTextColor [1, 0.86, 0.80, 1];
        _bigBadge ctrlSetTooltip "Big Blind";
        _bigBadge ctrlSetFontHeight 0.018;
        _bigBadge ctrlCommit 0;
        _playerRows pushBack [_rowBackground, _nameControl, _stackControl, _actionControl, _dealerBadge, _smallBadge, _bigBadge];
    };
    _display setVariable ["Waldo_MG_PokerPlayerRows", _playerRows];

    private _tableFrame = _display ctrlCreate ["RscText", -1];
    _tableFrame ctrlSetPosition [0.335, 0.110, 0.820, 0.615];
    _tableFrame ctrlSetBackgroundColor [0.025, 0.12, 0.095, 0.98];
    _tableFrame ctrlCommit 0;
    private _potLabel = _display ctrlCreate ["RscText", -1];
    _potLabel ctrlSetPosition [0.365, 0.128, 0.300, 0.052];
    _potLabel ctrlSetTextColor [1, 0.82, 0.28, 1];
    _potLabel ctrlSetFontHeight 0.036;
    _potLabel ctrlCommit 0;
    private _streetLabel = _display ctrlCreate ["RscText", -1];
    _streetLabel ctrlSetPosition [0.700, 0.138, 0.420, 0.038];
    _streetLabel ctrlSetTextColor [0.70, 0.86, 0.78, 1];
    _streetLabel ctrlSetFontHeight 0.019;
    _streetLabel ctrlCommit 0;
    private _communityBundles = [];
    for "_index" from 0 to 4 do {
        _communityBundles pushBack ([_display, 0.370 + (_index * 0.150), 0.210, 0.132, 0.245] call Waldo_MG_fnc_createPokerCardControlsLocal);
    };
    _display setVariable ["Waldo_MG_PokerCommunityCards", _communityBundles];
    {
        private _boardLabel = _display ctrlCreate ["RscText", -1];
        _boardLabel ctrlSetPosition [_x param [1, 0.370], 0.472, _x param [2, 0.132], 0.030];
        _boardLabel ctrlSetText (_x param [0, "STREET"]);
        _boardLabel ctrlSetTextColor [0.48, 0.68, 0.60, 1];
        _boardLabel ctrlSetFontHeight 0.015;
        _boardLabel ctrlCommit 0;
    } forEach [
        ["FLOP", 0.370, 0.432],
        ["TURN", 0.820, 0.132],
        ["RIVER", 0.970, 0.132]
    ];
    private _statusLabel = _display ctrlCreate ["RscText", -1];
    _statusLabel ctrlSetPosition [0.365, 0.535, 0.755, 0.055];
    _statusLabel ctrlSetBackgroundColor [0.012, 0.055, 0.045, 0.94];
    _statusLabel ctrlSetTextColor [0.90, 0.95, 0.91, 1];
    _statusLabel ctrlSetFontHeight 0.020;
    _statusLabel ctrlCommit 0;
    private _statusLabelTwo = _display ctrlCreate ["RscText", -1];
    _statusLabelTwo ctrlSetPosition [0.365, 0.592, 0.755, 0.055];
    _statusLabelTwo ctrlSetBackgroundColor [0.012, 0.055, 0.045, 0.94];
    _statusLabelTwo ctrlSetTextColor [0.76, 0.87, 0.80, 1];
    _statusLabelTwo ctrlSetFontHeight 0.018;
    _statusLabelTwo ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerPotLabel", _potLabel];
    _display setVariable ["Waldo_MG_PokerStreetLabel", _streetLabel];
    _display setVariable ["Waldo_MG_PokerStatusLabel", _statusLabel];
    _display setVariable ["Waldo_MG_PokerStatusLabelTwo", _statusLabelTwo];

    private _handFrame = _display ctrlCreate ["RscText", -1];
    _handFrame ctrlSetPosition [0.025, 0.745, 0.500, 0.295];
    _handFrame ctrlSetBackgroundColor [0.018, 0.045, 0.065, 0.98];
    _handFrame ctrlCommit 0;
    private _handTitle = _display ctrlCreate ["RscText", -1];
    _handTitle ctrlSetPosition [0.045, 0.758, 0.180, 0.035];
    _handTitle ctrlSetText "YOUR PRIVATE HAND";
    _handTitle ctrlSetTextColor [0.60, 0.82, 0.96, 1];
    _handTitle ctrlSetFontHeight 0.019;
    _handTitle ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerHandTitle", _handTitle];
    private _holeCards = [
        [_display, 0.055, 0.805, 0.145, 0.195] call Waldo_MG_fnc_createPokerCardControlsLocal,
        [_display, 0.220, 0.805, 0.145, 0.195] call Waldo_MG_fnc_createPokerCardControlsLocal
    ];
    _display setVariable ["Waldo_MG_PokerHoleCards", _holeCards];
    private _handLabel = _display ctrlCreate ["RscText", -1];
    _handLabel ctrlSetPosition [0.055, 1.005, 0.450, 0.027];
    _handLabel ctrlSetTextColor [0.86, 0.92, 0.96, 1];
    _handLabel ctrlSetFontHeight 0.016;
    _handLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerHandLabel", _handLabel];

    private _actionFrame = _display ctrlCreate ["RscText", -1];
    _actionFrame ctrlSetPosition [0.545, 0.745, 0.610, 0.295];
    _actionFrame ctrlSetBackgroundColor [0.025, 0.050, 0.060, 0.98];
    _actionFrame ctrlCommit 0;
    private _raiseLabel = _display ctrlCreate ["RscText", -1];
    _raiseLabel ctrlSetPosition [0.565, 0.760, 0.570, 0.035];
    _raiseLabel ctrlSetTextColor [0.72, 0.84, 0.88, 1];
    _raiseLabel ctrlSetFontHeight 0.018;
    _raiseLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerRaiseLabel", _raiseLabel];
    private _buttonData = [
        ["Waldo_MG_PokerFoldButton", "Fold", "FOLD", 0.565, 0.807, 0.130],
        ["Waldo_MG_PokerCallButton", "Check / Call", "CHECK_CALL", 0.705, 0.807, 0.150],
        ["Waldo_MG_PokerAllInButton", "All In", "ALL_IN", 0.865, 0.807, 0.130],
        ["Waldo_MG_PokerRaiseButton", "Raise To", "BET_TO", 1.005, 0.807, 0.130]
    ];
    {
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [_x param [3, 0], _x param [4, 0], _x param [5, 0.13], 0.042];
        _button ctrlSetText (_x param [1, "Action"]);
        _button setVariable ["Waldo_MG_PokerAction", _x param [2, ""]];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitPokerButtonLocal;}];
        _button ctrlCommit 0;
        _display setVariable [_x param [0, ""], _button];
    } forEach _buttonData;
    private _adjustButtons = [];
    private _adjustData = [[-10, "-10"], [-1, "-1"], [1, "+1"], [10, "+10"]];
    for "_index" from 0 to 3 do {
        private _data = _adjustData param [_index, [0, "0"]];
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [0.565 + (_index * 0.080), 0.862, 0.070, 0.038];
        _button ctrlSetText (_data param [1, "0"]);
        _button setVariable ["Waldo_MG_PokerRaiseDelta", _data param [0, 0]];
        _button ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_adjustPokerRaiseLocal;}];
        _button ctrlCommit 0;
        _adjustButtons pushBack _button;
    };
    _display setVariable ["Waldo_MG_PokerAdjustButtons", _adjustButtons];
    private _raiseTargetLabel = _display ctrlCreate ["RscText", -1];
    _raiseTargetLabel ctrlSetPosition [0.895, 0.857, 0.240, 0.048];
    _raiseTargetLabel ctrlSetBackgroundColor [0.42, 0.28, 0.035, 0.98];
    _raiseTargetLabel ctrlSetTextColor [1, 0.88, 0.46, 1];
    _raiseTargetLabel ctrlSetFontHeight 0.022;
    _raiseTargetLabel ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerRaiseTargetLabel", _raiseTargetLabel];
    private _revealButton = _display ctrlCreate ["RscButtonMenu", -1];
    _revealButton ctrlSetPosition [0.565, 0.922, 0.170, 0.043];
    _revealButton setVariable ["Waldo_MG_PokerAction", "REVEAL"];
    _revealButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitPokerButtonLocal;}];
    _revealButton ctrlCommit 0;
    private _muckButton = _display ctrlCreate ["RscButtonMenu", -1];
    _muckButton ctrlSetPosition [0.745, 0.922, 0.170, 0.043];
    _muckButton setVariable ["Waldo_MG_PokerAction", "MUCK"];
    _muckButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitPokerButtonLocal;}];
    _muckButton ctrlCommit 0;
    private _nextButton = _display ctrlCreate ["RscButtonMenu", -1];
    _nextButton ctrlSetPosition [0.925, 0.922, 0.210, 0.043];
    _nextButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_submitPokerButtonLocal;}];
    _nextButton ctrlCommit 0;
    _display setVariable ["Waldo_MG_PokerRevealButton", _revealButton];
    _display setVariable ["Waldo_MG_PokerMuckButton", _muckButton];
    _display setVariable ["Waldo_MG_PokerNextButton", _nextButton];

    _leaveButton ctrlAddEventHandler ["ButtonClick", {params ["_control"]; [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;}];
    [_display] call Waldo_MG_fnc_scalePokerDisplayLocal;
    [_display] call Waldo_MG_fnc_refreshPokerLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshPokerLocal;
            uiSleep Waldo_MG_CFG_POKER_UI_TICK;
        };
    };
}; 
 


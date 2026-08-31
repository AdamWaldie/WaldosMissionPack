/*
 * Author: WaldoTheWarfighter
 * Waldos Mini Games - Chess
 * All Waldo_MG_fnc_* functions implementing the Chess mini game (server logic + local UI).
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

Waldo_MG_fnc_chessNormalizeBoard = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _board = [];
    _board resize 64;
    for "_index" from 0 to 63 do {
        private _piece = _source param [_index, 0];
        if ((typeName _piece) != "SCALAR" || {(abs _piece) > 6}) then {
            _piece = 0;
        };
        _board set [_index, _piece];
    };
    _board
};

Waldo_MG_fnc_chessNormalizeCastlingRights = {
    params [["_source", []]];
    if ((typeName _source) != "ARRAY") then {
        _source = [];
    };
    private _rights = [false, false, false, false];
    for "_index" from 0 to 3 do {
        private _value = _source param [_index, false];
        if ((typeName _value) == "BOOL") then {
            _rights set [_index, _value];
        };
    };
    _rights
};

Waldo_MG_fnc_chessCreateBoard = {
    private _board = [];
    _board resize 64;
    for "_index" from 0 to 63 do {
        _board set [_index, 0];
    };
    private _backRank = [4, 2, 3, 5, 6, 3, 2, 4];
    for "_column" from 0 to 7 do {
        _board set [_column, -(_backRank param [_column, 0])];
        _board set [8 + _column, -1];
        _board set [48 + _column, 1];
        _board set [56 + _column, _backRank param [_column, 0]];
    };
    _board
};

Waldo_MG_fnc_chessPieceSide = {
    params [["_piece", 0]];
    if (_piece > 0) exitWith {1};
    if (_piece < 0) exitWith {-1};
    0
};

Waldo_MG_fnc_chessSideName = {
    params [["_side", 0]];
    if (_side > 0) exitWith {"NATO White"};
    if (_side < 0) exitWith {"CSAT Black"};
    "Neither side"
};

Waldo_MG_fnc_chessPieceName = {
    params [["_piece", 0]];
    switch (abs _piece) do {
        case 1: {"Pawn"};
        case 2: {"Knight"};
        case 3: {"Bishop"};
        case 4: {"Rook"};
        case 5: {"Queen"};
        case 6: {"King"};
        default {"Empty square"};
    }
};

Waldo_MG_fnc_chessGetMarkerClass = {
    params [["_piece", 0]];
    private _prefix = if (_piece > 0) then {"b"} else {"o"};
    private _suffix = switch (abs _piece) do {
        case 1: {"inf"};
        case 2: {"air"};
        case 3: {"art"};
        case 4: {"armor"};
        case 5: {"plane"};
        case 6: {"maint"};
        default {""};
    };
    if (_suffix == "") exitWith {""};
    format ["%1_%2", _prefix, _suffix]
};

Waldo_MG_fnc_chessFindKing = {
    params [
        ["_source", []],
        ["_side", 0]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    _board find (6 * _side)
};

Waldo_MG_fnc_chessIsSquareAttacked = {
    params [
        ["_source", []],
        ["_target", -1],
        ["_attackingSide", 0]
    ];
    if (_target < 0 || {_target > 63} || {_attackingSide == 0}) exitWith {false};
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _targetRow = floor (_target / 8);
    private _targetColumn = _target mod 8;
    private _attacked = false;
    for "_from" from 0 to 63 do {
        if (!_attacked) then {
            private _piece = _board param [_from, 0];
            if (([_piece] call Waldo_MG_fnc_chessPieceSide) == _attackingSide) then {
                private _type = abs _piece;
                private _row = floor (_from / 8);
                private _column = _from mod 8;
                if (_type == 1) then {
                    private _direction = if (_attackingSide > 0) then {-1} else {1};
                    if (_targetRow == (_row + _direction) && {(abs (_targetColumn - _column)) == 1}) then {
                        _attacked = true;
                    };
                };
                if (_type == 2) then {
                    private _rowDelta = abs (_targetRow - _row);
                    private _columnDelta = abs (_targetColumn - _column);
                    if ((_rowDelta == 2 && {_columnDelta == 1}) || {_rowDelta == 1 && {_columnDelta == 2}}) then {
                        _attacked = true;
                    };
                };
                if (_type == 6) then {
                    if ((abs (_targetRow - _row)) <= 1 && {(abs (_targetColumn - _column)) <= 1}) then {
                        _attacked = true;
                    };
                };
                if (!_attacked && {_type in [3, 4, 5]}) then {
                    private _directions = switch (_type) do {
                        case 3: {[[-1, -1], [-1, 1], [1, -1], [1, 1]]};
                        case 4: {[[-1, 0], [1, 0], [0, -1], [0, 1]]};
                        default {[[-1, -1], [-1, 1], [1, -1], [1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]]};
                    };
                    {
                        if (!_attacked) then {
                            private _scanRow = _row + (_x param [0, 0]);
                            private _scanColumn = _column + (_x param [1, 0]);
                            private _blocked = false;
                            while {
                                !_blocked
                                && {_scanRow >= 0} && {_scanRow <= 7}
                                && {_scanColumn >= 0} && {_scanColumn <= 7}
                            } do {
                                private _scanIndex = (_scanRow * 8) + _scanColumn;
                                if (_scanIndex == _target) then {
                                    _attacked = true;
                                    _blocked = true;
                                } else {
                                    if ((_board param [_scanIndex, 0]) != 0) then {
                                        _blocked = true;
                                    } else {
                                        _scanRow = _scanRow + (_x param [0, 0]);
                                        _scanColumn = _scanColumn + (_x param [1, 0]);
                                    };
                                };
                            };
                        };
                    } forEach _directions;
                };
            };
        };
    };
    _attacked
};

Waldo_MG_fnc_chessIsKingInCheck = {
    params [
        ["_source", []],
        ["_side", 0]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _king = [_board, _side] call Waldo_MG_fnc_chessFindKing;
    if (_king < 0) exitWith {true};
    [_board, _king, -_side] call Waldo_MG_fnc_chessIsSquareAttacked
};

Waldo_MG_fnc_chessGetPseudoMoves = {
    params [
        ["_source", []],
        ["_side", 0],
        ["_from", -1],
        ["_rightsSource", []],
        ["_enPassant", -1]
    ];
    if (_from < 0 || {_from > 63} || {_side == 0}) exitWith {[]};
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _rights = [_rightsSource] call Waldo_MG_fnc_chessNormalizeCastlingRights;
    private _piece = _board param [_from, 0];
    if (([_piece] call Waldo_MG_fnc_chessPieceSide) != _side) exitWith {[]};
    private _type = abs _piece;
    private _row = floor (_from / 8);
    private _column = _from mod 8;
    private _moves = [];

    if (_type == 1) then {
        private _direction = if (_side > 0) then {-1} else {1};
        private _startRow = if (_side > 0) then {6} else {1};
        private _promotionRow = if (_side > 0) then {0} else {7};
        private _oneRow = _row + _direction;
        if (_oneRow >= 0 && {_oneRow <= 7}) then {
            private _oneIndex = (_oneRow * 8) + _column;
            if ((_board param [_oneIndex, 0]) == 0) then {
                _moves pushBack [_oneIndex, if (_oneRow == _promotionRow) then {"PROMOTION"} else {""}];
                private _twoRow = _row + (2 * _direction);
                if (_row == _startRow && {_twoRow >= 0} && {_twoRow <= 7}) then {
                    private _twoIndex = (_twoRow * 8) + _column;
                    if ((_board param [_twoIndex, 0]) == 0) then {
                        _moves pushBack [_twoIndex, "PAWN_DOUBLE"];
                    };
                };
            };
            {
                private _captureColumn = _column + _x;
                if (_captureColumn >= 0 && {_captureColumn <= 7}) then {
                    private _captureIndex = (_oneRow * 8) + _captureColumn;
                    private _targetPiece = _board param [_captureIndex, 0];
                    if (([_targetPiece] call Waldo_MG_fnc_chessPieceSide) == (-_side) && {(abs _targetPiece) != 6}) then {
                        _moves pushBack [_captureIndex, if (_oneRow == _promotionRow) then {"PROMOTION"} else {""}];
                    } else {
                        if (_captureIndex == _enPassant && {_targetPiece == 0}) then {
                            private _capturedPawnIndex = _captureIndex - (8 * _direction);
                            if ((_board param [_capturedPawnIndex, 0]) == (-_side)) then {
                                _moves pushBack [_captureIndex, "EN_PASSANT"];
                            };
                        };
                    };
                };
            } forEach [-1, 1];
        };
    };

    if (_type == 2) then {
        {
            private _targetRow = _row + (_x param [0, 0]);
            private _targetColumn = _column + (_x param [1, 0]);
            if (_targetRow >= 0 && {_targetRow <= 7} && {_targetColumn >= 0} && {_targetColumn <= 7}) then {
                private _targetIndex = (_targetRow * 8) + _targetColumn;
                private _targetPiece = _board param [_targetIndex, 0];
                if (([_targetPiece] call Waldo_MG_fnc_chessPieceSide) != _side && {(abs _targetPiece) != 6}) then {
                    _moves pushBack [_targetIndex, ""];
                };
            };
        } forEach [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
    };

    if (_type in [3, 4, 5]) then {
        private _directions = switch (_type) do {
            case 3: {[[-1, -1], [-1, 1], [1, -1], [1, 1]]};
            case 4: {[[-1, 0], [1, 0], [0, -1], [0, 1]]};
            default {[[-1, -1], [-1, 1], [1, -1], [1, 1], [-1, 0], [1, 0], [0, -1], [0, 1]]};
        };
        {
            private _targetRow = _row + (_x param [0, 0]);
            private _targetColumn = _column + (_x param [1, 0]);
            private _blocked = false;
            while {
                !_blocked
                && {_targetRow >= 0} && {_targetRow <= 7}
                && {_targetColumn >= 0} && {_targetColumn <= 7}
            } do {
                private _targetIndex = (_targetRow * 8) + _targetColumn;
                private _targetPiece = _board param [_targetIndex, 0];
                private _targetSide = [_targetPiece] call Waldo_MG_fnc_chessPieceSide;
                if (_targetSide == _side) then {
                    _blocked = true;
                } else {
                    if ((abs _targetPiece) != 6) then {
                        _moves pushBack [_targetIndex, ""];
                    };
                    if (_targetSide == (-_side)) then {
                        _blocked = true;
                    } else {
                        _targetRow = _targetRow + (_x param [0, 0]);
                        _targetColumn = _targetColumn + (_x param [1, 0]);
                    };
                };
            };
        } forEach _directions;
    };

    if (_type == 6) then {
        for "_rowOffset" from -1 to 1 do {
            for "_columnOffset" from -1 to 1 do {
                if (_rowOffset != 0 || {_columnOffset != 0}) then {
                    private _targetRow = _row + _rowOffset;
                    private _targetColumn = _column + _columnOffset;
                    if (_targetRow >= 0 && {_targetRow <= 7} && {_targetColumn >= 0} && {_targetColumn <= 7}) then {
                        private _targetIndex = (_targetRow * 8) + _targetColumn;
                        private _targetPiece = _board param [_targetIndex, 0];
                        if (([_targetPiece] call Waldo_MG_fnc_chessPieceSide) != _side && {(abs _targetPiece) != 6}) then {
                            _moves pushBack [_targetIndex, ""];
                        };
                    };
                };
            };
        };
        private _kingStart = if (_side > 0) then {60} else {4};
        private _rookKingStart = if (_side > 0) then {63} else {7};
        private _rookQueenStart = if (_side > 0) then {56} else {0};
        private _kingRightIndex = if (_side > 0) then {0} else {2};
        private _queenRightIndex = if (_side > 0) then {1} else {3};
        if (_from == _kingStart && {!([_board, _side] call Waldo_MG_fnc_chessIsKingInCheck)}) then {
            if (
                (_rights param [_kingRightIndex, false])
                && {(_board param [_rookKingStart, 0]) == (4 * _side)}
                && {(_board param [_kingStart + 1, 0]) == 0}
                && {(_board param [_kingStart + 2, 0]) == 0}
                && {!([_board, _kingStart + 1, -_side] call Waldo_MG_fnc_chessIsSquareAttacked)}
                && {!([_board, _kingStart + 2, -_side] call Waldo_MG_fnc_chessIsSquareAttacked)}
            ) then {
                _moves pushBack [_kingStart + 2, "CASTLE_K"];
            };
            if (
                (_rights param [_queenRightIndex, false])
                && {(_board param [_rookQueenStart, 0]) == (4 * _side)}
                && {(_board param [_kingStart - 1, 0]) == 0}
                && {(_board param [_kingStart - 2, 0]) == 0}
                && {(_board param [_kingStart - 3, 0]) == 0}
                && {!([_board, _kingStart - 1, -_side] call Waldo_MG_fnc_chessIsSquareAttacked)}
                && {!([_board, _kingStart - 2, -_side] call Waldo_MG_fnc_chessIsSquareAttacked)}
            ) then {
                _moves pushBack [_kingStart - 2, "CASTLE_Q"];
            };
        };
    };
    _moves
};

Waldo_MG_fnc_chessApplyBoardMove = {
    params [
        ["_source", []],
        ["_side", 0],
        ["_from", -1],
        ["_to", -1],
        ["_special", ""],
        ["_promotionType", 5]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    if (_from < 0 || {_from > 63} || {_to < 0} || {_to > 63}) exitWith {_board};
    private _piece = _board param [_from, 0];
    _board set [_from, 0];
    if (_special == "EN_PASSANT") then {
        private _direction = if (_side > 0) then {-1} else {1};
        _board set [_to - (8 * _direction), 0];
    };
    if (_special == "CASTLE_K") then {
        private _rookFrom = if (_side > 0) then {63} else {7};
        _board set [_rookFrom, 0];
        _board set [_to - 1, 4 * _side];
    };
    if (_special == "CASTLE_Q") then {
        private _rookFrom = if (_side > 0) then {56} else {0};
        _board set [_rookFrom, 0];
        _board set [_to + 1, 4 * _side];
    };
    if (_special == "PROMOTION") then {
        if (!(_promotionType in [2, 3, 4, 5])) then {
            _promotionType = 5;
        };
        _piece = _promotionType * _side;
    };
    _board set [_to, _piece];
    _board
};

Waldo_MG_fnc_chessGetLegalMoves = {
    params [
        ["_source", []],
        ["_side", 0],
        ["_from", -1],
        ["_rightsSource", []],
        ["_enPassant", -1]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _moves = [];
    {
        private _to = _x param [0, -1];
        private _special = _x param [1, ""];
        private _testBoard = [_board, _side, _from, _to, _special, 5] call Waldo_MG_fnc_chessApplyBoardMove;
        if (!([_testBoard, _side] call Waldo_MG_fnc_chessIsKingInCheck)) then {
            _moves pushBack [_to, _special];
        };
    } forEach ([_board, _side, _from, _rightsSource, _enPassant] call Waldo_MG_fnc_chessGetPseudoMoves);
    _moves
};

Waldo_MG_fnc_chessSideHasLegalMove = {
    params [
        ["_source", []],
        ["_side", 0],
        ["_rightsSource", []],
        ["_enPassant", -1]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _found = false;
    for "_index" from 0 to 63 do {
        if (
            !_found
            && {([_board param [_index, 0]] call Waldo_MG_fnc_chessPieceSide) == _side}
            && {(count ([_board, _side, _index, _rightsSource, _enPassant] call Waldo_MG_fnc_chessGetLegalMoves)) > 0}
        ) then {
            _found = true;
        };
    };
    _found
};

Waldo_MG_fnc_chessPositionKey = {
    params [
        ["_source", []],
        ["_turn", 1],
        ["_rightsSource", []],
        ["_enPassant", -1]
    ];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _rights = [_rightsSource] call Waldo_MG_fnc_chessNormalizeCastlingRights;
    private _effectiveEnPassant = -1;
    if (_enPassant >= 0 && {_enPassant <= 63}) then {
        private _targetRow = floor (_enPassant / 8);
        private _targetColumn = _enPassant mod 8;
        private _direction = if (_turn > 0) then {-1} else {1};
        private _pawnRow = _targetRow - _direction;
        {
            private _pawnColumn = _targetColumn + _x;
            if (_pawnRow >= 0 && {_pawnRow <= 7} && {_pawnColumn >= 0} && {_pawnColumn <= 7}) then {
                if ((_board param [(_pawnRow * 8) + _pawnColumn, 0]) == _turn) then {
                    _effectiveEnPassant = _enPassant;
                };
            };
        } forEach [-1, 1];
    };
    str [_board, _turn, _rights, _effectiveEnPassant]
};

Waldo_MG_fnc_chessIsInsufficientMaterial = {
    params [["_source", []]];
    private _board = [_source] call Waldo_MG_fnc_chessNormalizeBoard;
    private _minorPieces = [];
    private _majorOrPawn = false;
    for "_index" from 0 to 63 do {
        private _type = abs (_board param [_index, 0]);
        if (_type in [1, 4, 5]) then {
            _majorOrPawn = true;
        };
        if (_type in [2, 3]) then {
            _minorPieces pushBack [_type, _index];
        };
    };
    if (_majorOrPawn) exitWith {false};
    if ((count _minorPieces) <= 1) exitWith {true};
    private _bishopsOnly = true;
    private _bishopSquareColor = -1;
    {
        if ((_x param [0, 0]) != 3) then {
            _bishopsOnly = false;
        } else {
            private _index = _x param [1, -1];
            private _color = ((floor (_index / 8)) + (_index mod 8)) mod 2;
            if (_bishopSquareColor < 0) then {
                _bishopSquareColor = _color;
            } else {
                if (_color != _bishopSquareColor) then {
                    _bishopsOnly = false;
                };
            };
        };
    } forEach _minorPieces;
    _bishopsOnly
}; 
 

Waldo_MG_fnc_chessPublishRevisionServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table, "Waldo_MG_ChessRevision", (_table getVariable ["Waldo_MG_ChessRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_TableRevision", (_table getVariable ["Waldo_MG_TableRevision", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
};

Waldo_MG_fnc_chessClearServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table, "Waldo_MG_ChessActive", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessGameId", ""] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessPlayers", [objNull, objNull]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessPlayerNames", ["NATO White", "CSAT Black"]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessSeatIndices", [-1, -1]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessBoard", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessTurn", 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCastlingRights", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessEnPassant", -1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessHalfmoveClock", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessFullmoveNumber", 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessWinner", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessResult", ""] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessMoveNumber", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessLastMove", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessStatus", "Waiting for a Chess match."] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessDrawOfferSide", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimThreefold", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimFifty", false] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_ChessPositionHistoryServer", []];
    [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
};

Waldo_MG_fnc_chessStartServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {false};
    if ([_table] call Waldo_MG_fnc_isTableGameActive) exitWith {false};
    if ((_table getVariable ["Waldo_MG_TableSelectedGame", ""]) != "chess") exitWith {false};
    if ((_table getVariable ["Waldo_MG_TablePhase", "LOBBY"]) != "READY") exitWith {false};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = [];
    private _seatIndices = [];
    for "_index" from 0 to (Waldo_MG_CFG_SEAT_COUNT - 1) do {
        private _unit = _seats param [_index, objNull];
        if (!isNull _unit) then {
            _players pushBack _unit;
            _seatIndices pushBack _index;
        };
    };
    if ((count _players) != 2) exitWith {false};
    private _white = _players param [0, objNull];
    private _black = _players param [1, objNull];
    if (isNull _white || {isNull _black}) exitWith {false};
    private _board = call Waldo_MG_fnc_chessCreateBoard;
    private _rights = [true, true, true, true];
    [_table, "Waldo_MG_ChessActive", true] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessFinished", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessGameId", format ["Waldo_MG_CHESS_%1_%2", floor (serverTime * 10), floor (random 1000000)]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessPlayers", [_white, _black]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessPlayerNames", [name _white, name _black]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessSeatIndices", _seatIndices] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessBoard", _board] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessTurn", 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCastlingRights", _rights] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessEnPassant", -1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessHalfmoveClock", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessFullmoveNumber", 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessWinner", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessResult", ""] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessMoveNumber", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessLastMove", []] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessStatus", format ["%1 has the first move as NATO White.", name _white]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessDrawOfferSide", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimThreefold", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimFifty", false] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable [
        "Waldo_MG_ChessPositionHistoryServer",
        [[_board, 1, _rights, -1] call Waldo_MG_fnc_chessPositionKey]
    ];
    _table setVariable ["Waldo_MG_TablePhase", "PLAYING",true];
    [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
    true
};

Waldo_MG_fnc_chessFinishServer = {
    params [
        ["_table", objNull],
        ["_winner", 0],
        ["_result", "DRAW"],
        ["_status", "Chess match finished."]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_ChessActive", false])) exitWith {};
    [_table, "Waldo_MG_ChessFinished", true] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessWinner", _winner] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessResult", _result] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessStatus", _status] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessDrawOfferSide", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimThreefold", false] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCanClaimFifty", false] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_TablePhase", "FINISHED",true];
    [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
};

Waldo_MG_fnc_chessFinishForfeitServer = {
    params [
        ["_table", objNull],
        ["_departingUnit", objNull],
        ["_departingSeat", -1]
    ];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_ChessActive", false])) exitWith {};
    if (_table getVariable ["Waldo_MG_ChessFinished", false]) exitWith {};
    private _players = _table getVariable ["Waldo_MG_ChessPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_ChessSeatIndices", [-1, -1]];
    private _names = _table getVariable ["Waldo_MG_ChessPlayerNames", ["NATO White", "CSAT Black"]];
    private _roleIndex = -1;
    if (!isNull _departingUnit) then {
        _roleIndex = _players find _departingUnit;
    };
    if (_roleIndex < 0 && {_departingSeat >= 0}) then {
        _roleIndex = _seatIndices find _departingSeat;
    };
    if (_roleIndex < 0) exitWith {};
    private _loserSide = if (_roleIndex == 0) then {1} else {-1};
    private _winner = -_loserSide;
    private _winnerName = _names param [if (_winner > 0) then {0} else {1}, "Opponent"];
    private _loserName = _names param [_roleIndex, "Opponent"];
    [_table, _winner, "FORFEIT", format ["%1 wins by forfeit after %2 left the table.", _winnerName, _loserName]] call Waldo_MG_fnc_chessFinishServer;
};

Waldo_MG_fnc_chessReconcilePlayersServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    if (!(_table getVariable ["Waldo_MG_ChessActive", false])) exitWith {};
    private _seats = [(_table getVariable ["Waldo_MG_TableSeats", []])] call Waldo_MG_fnc_normalizeSeats;
    private _players = _table getVariable ["Waldo_MG_ChessPlayers", [objNull, objNull]];
    private _seatIndices = _table getVariable ["Waldo_MG_ChessSeatIndices", [-1, -1]];
    private _valid = [false, false];
    for "_role" from 0 to 1 do {
        private _unit = _players param [_role, objNull];
        private _seatIndex = _seatIndices param [_role, -1];
        private _isValid = !isNull _unit
            && {_seatIndex >= 0}
            && {_seatIndex < Waldo_MG_CFG_SEAT_COUNT}
            && {(_seats param [_seatIndex, objNull]) == _unit}
            && {_unit in allPlayers}
            && {alive _unit}
            && {(lifeState _unit) != "INCAPACITATED"};
        _valid set [_role, _isValid];
    };
    if (!(_table getVariable ["Waldo_MG_ChessFinished", false])) then {
        if (!(_valid param [0, false]) && {!(_valid param [1, false])}) then {
            [_table] call Waldo_MG_fnc_chessClearServer;
            [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
            _table setVariable ["Waldo_MG_TablePhase", "LOBBY",true];
        } else {
            if (!(_valid param [0, false])) then {
                [_table, objNull, _seatIndices param [0, -1]] call Waldo_MG_fnc_chessFinishForfeitServer;
            } else {
                if (!(_valid param [1, false])) then {
                    [_table, objNull, _seatIndices param [1, -1]] call Waldo_MG_fnc_chessFinishForfeitServer;
                };
            };
        };
    } else {
        if (!(_valid param [0, false]) && {!(_valid param [1, false])}) then {
            [_table] call Waldo_MG_fnc_chessClearServer;
            [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
            _table setVariable ["Waldo_MG_TablePhase", "LOBBY",true];
        };
    };
};

Waldo_MG_fnc_chessResetServer = {
    params [["_table", objNull]];
    if (!isServer || {isNull _table}) exitWith {};
    [_table] call Waldo_MG_fnc_chessClearServer;
    [_table, "Waldo_MG_TableReady", [false, false, false, false]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table] call Waldo_MG_fnc_refreshTableConsensusServer;
}; 
 

Waldo_MG_fnc_processChessMoveRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 6) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _from = _request param [2, -1];
    private _to = _request param [3, -1];
    private _promotionType = _request param [4, 0];
    private _expectedRevision = _request param [5, -1];
    if (
        (typeName _tableNetId) != "STRING"
        || {(typeName _from) != "SCALAR"}
        || {(typeName _to) != "SCALAR"}
        || {(typeName _promotionType) != "SCALAR"}
        || {(typeName _expectedRevision) != "SCALAR"}
    ) exitWith {
        [_unit, _token, "Chess move rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    if (
        _from != (floor _from)
        || {_to != (floor _to)}
        || {_promotionType != (floor _promotionType)}
        || {_expectedRevision != (floor _expectedRevision)}
    ) exitWith {
        [_unit, _token, "Chess move rejected: board coordinates must be whole numbers."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Chess move rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!alive _unit || {(lifeState _unit) == "INCAPACITATED"}) exitWith {
        [_unit, _token, "Chess move rejected: you cannot play in your current state."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_ChessActive", false]) || {_table getVariable ["Waldo_MG_ChessFinished", false]}) exitWith {
        [_unit, _token, "That Chess match is not accepting moves."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_ChessPlayers", [objNull, objNull]];
    private _roleIndex = _players find _unit;
    if (_roleIndex < 0) exitWith {
        [_unit, _token, "Only the two assigned Chess players may move pieces."] call Waldo_MG_fnc_resultServer;
    };
    private _side = if (_roleIndex == 0) then {1} else {-1};
    private _turn = _table getVariable ["Waldo_MG_ChessTurn", 1];
    if (_side != _turn) exitWith {
        [_unit, _token, "It is the other player's turn."] call Waldo_MG_fnc_resultServer;
    };
    private _revision = _table getVariable ["Waldo_MG_ChessRevision", 0];
    if (_expectedRevision != _revision) exitWith {
        [_unit, _token, "The Chess board changed before that move arrived. Please select again."] call Waldo_MG_fnc_resultServer;
    };
    if (_from < 0 || {_from > 63} || {_to < 0} || {_to > 63}) exitWith {
        [_unit, _token, "Chess move rejected: square outside the board."] call Waldo_MG_fnc_resultServer;
    };
    private _board = [(_table getVariable ["Waldo_MG_ChessBoard", []])] call Waldo_MG_fnc_chessNormalizeBoard;
    private _rights = [(_table getVariable ["Waldo_MG_ChessCastlingRights", []])] call Waldo_MG_fnc_chessNormalizeCastlingRights;
    private _enPassant = _table getVariable ["Waldo_MG_ChessEnPassant", -1];
    private _legalMoves = [_board, _side, _from, _rights, _enPassant] call Waldo_MG_fnc_chessGetLegalMoves;
    private _special = "INVALID";
    {
        if ((_x param [0, -1]) == _to) exitWith {
            _special = _x param [1, ""];
        };
    } forEach _legalMoves;
    if (_special == "INVALID") exitWith {
        [_unit, _token, "That move is illegal or would leave your king in check."] call Waldo_MG_fnc_resultServer;
    };
    if (_special == "PROMOTION" && {!(_promotionType in [2, 3, 4, 5])}) exitWith {
        [_unit, _token, "Choose a Knight, Bishop, Rook, or Queen for promotion."] call Waldo_MG_fnc_resultServer;
    };

    private _movingPiece = _board param [_from, 0];
    private _capturedPiece = _board param [_to, 0];
    private _captureIndex = _to;
    if (_special == "EN_PASSANT") then {
        private _direction = if (_side > 0) then {-1} else {1};
        _captureIndex = _to - (8 * _direction);
        _capturedPiece = _board param [_captureIndex, 0];
    };
    private _newBoard = [_board, _side, _from, _to, _special, _promotionType] call Waldo_MG_fnc_chessApplyBoardMove;

    if ((abs _movingPiece) == 6) then {
        if (_side > 0) then {
            _rights set [0, false];
            _rights set [1, false];
        } else {
            _rights set [2, false];
            _rights set [3, false];
        };
    };
    if (_movingPiece == 4 && {_from == 63}) then {_rights set [0, false];};
    if (_movingPiece == 4 && {_from == 56}) then {_rights set [1, false];};
    if (_movingPiece == -4 && {_from == 7}) then {_rights set [2, false];};
    if (_movingPiece == -4 && {_from == 0}) then {_rights set [3, false];};
    if (_capturedPiece == 4 && {_captureIndex == 63}) then {_rights set [0, false];};
    if (_capturedPiece == 4 && {_captureIndex == 56}) then {_rights set [1, false];};
    if (_capturedPiece == -4 && {_captureIndex == 7}) then {_rights set [2, false];};
    if (_capturedPiece == -4 && {_captureIndex == 0}) then {_rights set [3, false];};

    private _newEnPassant = -1;
    if (_special == "PAWN_DOUBLE") then {
        _newEnPassant = floor ((_from + _to) / 2);
    };
    private _halfmoveClock = _table getVariable ["Waldo_MG_ChessHalfmoveClock", 0];
    if ((abs _movingPiece) == 1 || {_capturedPiece != 0}) then {
        _halfmoveClock = 0;
    } else {
        _halfmoveClock = _halfmoveClock + 1;
    };
    private _fullmoveNumber = _table getVariable ["Waldo_MG_ChessFullmoveNumber", 1];
    if (_side < 0) then {
        _fullmoveNumber = _fullmoveNumber + 1;
    };
    _turn = -_side;

    private _history = _table getVariable ["Waldo_MG_ChessPositionHistoryServer", []];
    if ((typeName _history) != "ARRAY") then {
        _history = [];
    } else {
        _history = +_history;
    };
    private _positionKey = [_newBoard, _turn, _rights, _newEnPassant] call Waldo_MG_fnc_chessPositionKey;
    _history pushBack _positionKey;
    while {(count _history) > 512} do {
        _history deleteAt 0;
    };
    private _repetitionCount = 0;
    {
        if (_x == _positionKey) then {
            _repetitionCount = _repetitionCount + 1;
        };
    } forEach _history;
    private _canClaimThreefold = _repetitionCount >= 3;
    private _canClaimFifty = _halfmoveClock >= 100;

    private _nextInCheck = [_newBoard, _turn] call Waldo_MG_fnc_chessIsKingInCheck;
    private _nextHasMove = [_newBoard, _turn, _rights, _newEnPassant] call Waldo_MG_fnc_chessSideHasLegalMove;
    private _winner = 0;
    private _result = "";
    private _status = "";
    private _names = _table getVariable ["Waldo_MG_ChessPlayerNames", ["NATO White", "CSAT Black"]];
    private _nextName = _names param [if (_turn > 0) then {0} else {1}, "Opponent"];
    if (!_nextHasMove) then {
        if (_nextInCheck) then {
            _winner = _side;
            _result = "CHECKMATE";
            _status = format ["CHECKMATE. %1 wins for %2.", name _unit, [_side] call Waldo_MG_fnc_chessSideName];
        } else {
            _result = "STALEMATE";
            _status = "STALEMATE. The match is drawn.";
        };
    };
    if (_result == "" && {[_newBoard] call Waldo_MG_fnc_chessIsInsufficientMaterial}) then {
        _result = "INSUFFICIENT_MATERIAL";
        _status = "DRAW. No mating material remains.";
    };
    if (_result == "" && {_repetitionCount >= 5}) then {
        _result = "FIVEFOLD_REPETITION";
        _status = "DRAW. The position repeated five times.";
    };
    if (_result == "" && {_halfmoveClock >= 150}) then {
        _result = "SEVENTY_FIVE_MOVE_RULE";
        _status = "DRAW. Seventy-five moves passed without a pawn move or capture.";
    };
    if (_result == "") then {
        _status = format ["%1 to move as %2.", _nextName, [_turn] call Waldo_MG_fnc_chessSideName];
        if (_nextInCheck) then {
            _status = format ["CHECK. %1", _status];
        };
        if (_special in ["CASTLE_K", "CASTLE_Q"]) then {
            _status = format ["Castling complete. %1", _status];
        };
        if (_special == "PROMOTION") then {
            _status = format ["Pawn promoted to %1. %2", [_promotionType] call Waldo_MG_fnc_chessPieceName, _status];
        };
    };

    [_table, "Waldo_MG_ChessBoard", _newBoard] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessTurn", _turn] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessCastlingRights", _rights] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessEnPassant", _newEnPassant] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessHalfmoveClock", _halfmoveClock] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessFullmoveNumber", _fullmoveNumber] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessMoveNumber", (_table getVariable ["Waldo_MG_ChessMoveNumber", 0]) + 1] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessLastMove", [_from, _to, _special, _promotionType, _capturedPiece]] call Waldo_MG_fnc_setPublicTableStateServer;
    [_table, "Waldo_MG_ChessDrawOfferSide", 0] call Waldo_MG_fnc_setPublicTableStateServer;
    _table setVariable ["Waldo_MG_ChessPositionHistoryServer", _history];
    if (_result != "") then {
        [_table, _winner, _result, _status] call Waldo_MG_fnc_chessFinishServer;
    } else {
        [_table, "Waldo_MG_ChessCanClaimThreefold", _canClaimThreefold] call Waldo_MG_fnc_setPublicTableStateServer;
        [_table, "Waldo_MG_ChessCanClaimFifty", _canClaimFifty] call Waldo_MG_fnc_setPublicTableStateServer;
        [_table, "Waldo_MG_ChessStatus", _status] call Waldo_MG_fnc_setPublicTableStateServer;
        _table setVariable ["Waldo_MG_TablePhase", "PLAYING",true];
        [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
    };
    [_unit, _token, if (_result == "CHECKMATE") then {
        "Move accepted. Checkmate."
    } else {
        if (_result != "") then {"Move accepted. The Chess match is drawn."} else {"Chess move accepted."}
    }] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_processChessActionRequestServer = {
    params [
        ["_unit", objNull],
        ["_request", []]
    ];
    if (!isServer || {isNull _unit}) exitWith {};
    if ((count _request) < 3) exitWith {};
    private _token = _request param [0, ""];
    if (!([_token] call Waldo_MG_fnc_rememberHandledTokenServer)) exitWith {};
    private _tableNetId = _request param [1, ""];
    private _action = _request param [2, ""];
    if ((typeName _tableNetId) != "STRING" || {(typeName _action) != "STRING"}) exitWith {
        [_unit, _token, "Chess action rejected: malformed request data."] call Waldo_MG_fnc_resultServer;
    };
    private _table = objectFromNetId _tableNetId;
    if (isNull _table || {_table != (_unit getVariable ["Waldo_MG_SeatedTable", objNull])}) exitWith {
        [_unit, _token, "Chess action rejected: you are no longer seated at that table."] call Waldo_MG_fnc_resultServer;
    };
    if (!(_table getVariable ["Waldo_MG_ChessActive", false])) exitWith {
        [_unit, _token, "There is no active Chess match at this table."] call Waldo_MG_fnc_resultServer;
    };
    private _players = _table getVariable ["Waldo_MG_ChessPlayers", [objNull, objNull]];
    private _roleIndex = _players find _unit;
    if (_roleIndex < 0) exitWith {
        [_unit, _token, "Only assigned Chess players may use match actions."] call Waldo_MG_fnc_resultServer;
    };
    private _side = if (_roleIndex == 0) then {1} else {-1};
    private _names = _table getVariable ["Waldo_MG_ChessPlayerNames", ["NATO White", "CSAT Black"]];
    private _finished = _table getVariable ["Waldo_MG_ChessFinished", false];
    if (_action == "RESET") exitWith {
        if (!_finished) then {
            [_unit, _token, "Finish the Chess match before resetting to the lobby."] call Waldo_MG_fnc_resultServer;
        } else {
            [_table] call Waldo_MG_fnc_chessResetServer;
            [_unit, _token, "Chess cleared. The table has returned to its lobby."] call Waldo_MG_fnc_resultServer;
        };
    };
    if (_finished) exitWith {
        [_unit, _token, "That Chess match has already finished."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "RESIGN") exitWith {
        private _winner = -_side;
        private _winnerName = _names param [if (_winner > 0) then {0} else {1}, "Opponent"];
        [_table, _winner, "RESIGNATION", format ["%1 wins after %2 resigned.", _winnerName, name _unit]] call Waldo_MG_fnc_chessFinishServer;
        [_unit, _token, "You resigned the Chess match."] call Waldo_MG_fnc_resultServer;
    };
    if (_action == "CLAIM_DRAW") exitWith {
        if ((_table getVariable ["Waldo_MG_ChessTurn", 1]) != _side) then {
            [_unit, _token, "Only the player whose turn it is may claim a draw."] call Waldo_MG_fnc_resultServer;
        } else {
            private _threefold = _table getVariable ["Waldo_MG_ChessCanClaimThreefold", false];
            private _fifty = _table getVariable ["Waldo_MG_ChessCanClaimFifty", false];
            if (!_threefold && {!_fifty}) then {
                [_unit, _token, "No threefold-repetition or fifty-move draw is currently claimable."] call Waldo_MG_fnc_resultServer;
            } else {
                private _result = if (_threefold) then {"THREEFOLD_REPETITION"} else {"FIFTY_MOVE_RULE"};
                private _status = if (_threefold) then {
                    format ["DRAW claimed by %1: threefold repetition.", name _unit]
                } else {
                    format ["DRAW claimed by %1: fifty-move rule.", name _unit]
                };
                [_table, 0, _result, _status] call Waldo_MG_fnc_chessFinishServer;
                [_unit, _token, "Draw claim accepted."] call Waldo_MG_fnc_resultServer;
            };
        };
    };
    if (_action == "DRAW_OFFER") exitWith {
        private _offerSide = _table getVariable ["Waldo_MG_ChessDrawOfferSide", 0];
        if (_offerSide == 0) then {
            [_table, "Waldo_MG_ChessDrawOfferSide", _side] call Waldo_MG_fnc_setPublicTableStateServer;
            [_table, "Waldo_MG_ChessStatus", format ["%1 offered a draw. The opponent may accept.", name _unit]] call Waldo_MG_fnc_setPublicTableStateServer;
            [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
            [_unit, _token, "Draw offered. Making a move withdraws it automatically."] call Waldo_MG_fnc_resultServer;
        } else {
            if (_offerSide == _side) then {
                [_table, "Waldo_MG_ChessDrawOfferSide", 0] call Waldo_MG_fnc_setPublicTableStateServer;
                [_table, "Waldo_MG_ChessStatus", format ["%1 withdrew the draw offer.", name _unit]] call Waldo_MG_fnc_setPublicTableStateServer;
                [_table] call Waldo_MG_fnc_chessPublishRevisionServer;
                [_unit, _token, "Draw offer withdrawn."] call Waldo_MG_fnc_resultServer;
            } else {
                [_table, 0, "DRAW_AGREEMENT", format ["DRAW by agreement between %1 and %2.", _names param [0, "White"], _names param [1, "Black"]]] call Waldo_MG_fnc_chessFinishServer;
                [_unit, _token, "Draw offer accepted."] call Waldo_MG_fnc_resultServer;
            };
        };
    };
    [_unit, _token, "Unknown Chess match action."] call Waldo_MG_fnc_resultServer;
};

Waldo_MG_fnc_submitChessMoveRequestLocal = {
    params [
        ["_table", objNull],
        ["_from", -1],
        ["_to", -1],
        ["_promotionType", 0],
        ["_revision", -1]
    ];
    if (!hasInterface || {isNull player} || {isNull _table}) exitWith {};
    private _token = ["CHESS_MOVE"] call Waldo_MG_fnc_makeToken;
    ["CHESS_MOVE", _table, _token, _revision, [_token, netId _table, _from, _to, _promotionType, _revision]] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_submitChessActionRequestLocal = {
    params [
        ["_table", objNull],
        ["_action", ""]
    ];
    if (!hasInterface || {isNull player} || {isNull _table} || {_action == ""}) exitWith {};
    private _token = ["CHESS_ACTION"] call Waldo_MG_fnc_makeToken;
    ["CHESS_ACTION", _table, _token, _table getVariable ["Waldo_MG_ChessRevision", -1], [_token, netId _table, _action]] call Waldo_MG_fnc_submitRequestLocal;
};

Waldo_MG_fnc_getChessPlayerSideLocal = {
    params [["_table", objNull]];
    if (isNull _table || {isNull player}) exitWith {0};
    private _players = _table getVariable ["Waldo_MG_ChessPlayers", [objNull, objNull]];
    private _roleIndex = _players find player;
    if (_roleIndex == 0) exitWith {1};
    if (_roleIndex == 1) exitWith {-1};
    0
};

Waldo_MG_fnc_chessGetSquareName = {
    params [["_index", -1]];
    if (_index < 0 || {_index > 63}) exitWith {"?"};
    private _files = ["a", "b", "c", "d", "e", "f", "g", "h"];
    private _row = floor (_index / 8);
    private _column = _index mod 8;
    format ["%1%2", _files param [_column, "?"], 8 - _row]
};

Waldo_MG_fnc_chessGetMarkerTextureLocal = {
    params [["_piece", 0]];
    private _markerClass = [_piece] call Waldo_MG_fnc_chessGetMarkerClass;
    if (_markerClass == "") exitWith {""};
    private _config = configFile >> "CfgMarkers" >> _markerClass;
    private _texture = getText (_config >> "icon");
    if (_texture == "") then {
        _texture = getText (_config >> "texture");
    };
    _texture
};

Waldo_MG_fnc_selectChessPromotionLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _focusSink = _display getVariable ["Waldo_MG_ChessFocusSink", controlNull];
    if (!isNull _focusSink) then {
        ctrlSetFocus _focusSink;
    };
    private _table = _display getVariable ["Waldo_MG_ChessTable", objNull];
    private _pending = _display getVariable ["Waldo_MG_ChessPromotionPending", []];
    private _promotionType = _control getVariable ["Waldo_MG_ChessPromotionType", 0];
    if (isNull _table || {(count _pending) < 3} || {!(_promotionType in [2, 3, 4, 5])}) exitWith {};
    private _from = _pending param [0, -1];
    private _to = _pending param [1, -1];
    private _revision = _pending param [2, -1];
    _display setVariable ["Waldo_MG_ChessPromotionPending", []];
    _display setVariable ["Waldo_MG_ChessMovePending", true];
    _display setVariable ["Waldo_MG_ChessSelectedFrom", -1];
    [_table, _from, _to, _promotionType, _revision] call Waldo_MG_fnc_submitChessMoveRequestLocal;
    [_display] call Waldo_MG_fnc_refreshChessLocal;
};

Waldo_MG_fnc_handleChessSquareClickLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _focusSink = _display getVariable ["Waldo_MG_ChessFocusSink", controlNull];
    if (!isNull _focusSink) then {
        ctrlSetFocus _focusSink;
    };
    private _table = _display getVariable ["Waldo_MG_ChessTable", objNull];
    private _index = _control getVariable ["Waldo_MG_ChessSquareIndex", -1];
    if (isNull _table || {_index < 0} || {_index > 63}) exitWith {};
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "chess") exitWith {
        ["That Chess match is no longer active."] call Waldo_MG_fnc_notifyLocal;
    };
    if (_table getVariable ["Waldo_MG_ChessFinished", false]) exitWith {
        ["The match is finished. Reset it to return to the lobby."] call Waldo_MG_fnc_notifyLocal;
    };
    private _side = [_table] call Waldo_MG_fnc_getChessPlayerSideLocal;
    if (_side == 0) exitWith {
        ["Only the two assigned players may move these pieces."] call Waldo_MG_fnc_notifyLocal;
    };
    if ((_table getVariable ["Waldo_MG_ChessTurn", 1]) != _side) exitWith {
        ["It is the other player's turn."] call Waldo_MG_fnc_notifyLocal;
    };
    if (_display getVariable ["Waldo_MG_ChessMovePending", false]) exitWith {
        ["Waiting for the table host to confirm your move..."] call Waldo_MG_fnc_notifyLocal;
    };
    if ((count (_display getVariable ["Waldo_MG_ChessPromotionPending", []])) > 0) then {
        _display setVariable ["Waldo_MG_ChessPromotionPending", []];
    };
    private _revision = _table getVariable ["Waldo_MG_ChessRevision", 0];
    private _board = [(_table getVariable ["Waldo_MG_ChessBoard", []])] call Waldo_MG_fnc_chessNormalizeBoard;
    private _rights = [(_table getVariable ["Waldo_MG_ChessCastlingRights", []])] call Waldo_MG_fnc_chessNormalizeCastlingRights;
    private _enPassant = _table getVariable ["Waldo_MG_ChessEnPassant", -1];
    private _selected = _display getVariable ["Waldo_MG_ChessSelectedFrom", -1];
    private _pieceSide = [_board param [_index, 0]] call Waldo_MG_fnc_chessPieceSide;
    if (_pieceSide == _side) exitWith {
        private _moves = [_board, _side, _index, _rights, _enPassant] call Waldo_MG_fnc_chessGetLegalMoves;
        if ((count _moves) <= 0) then {
            ["That piece has no legal move in the current position."] call Waldo_MG_fnc_notifyLocal;
        } else {
            _display setVariable ["Waldo_MG_ChessSelectedFrom", _index];
            [_display] call Waldo_MG_fnc_refreshChessLocal;
        };
    };
    if (_selected < 0) exitWith {
        ["Select one of your pieces first."] call Waldo_MG_fnc_notifyLocal;
    };
    private _legalMoves = [_board, _side, _selected, _rights, _enPassant] call Waldo_MG_fnc_chessGetLegalMoves;
    private _special = "INVALID";
    {
        if ((_x param [0, -1]) == _index) exitWith {
            _special = _x param [1, ""];
        };
    } forEach _legalMoves;
    if (_special == "INVALID") exitWith {
        ["Choose one of the highlighted legal destinations."] call Waldo_MG_fnc_notifyLocal;
    };
    if (_special == "PROMOTION") exitWith {
        _display setVariable ["Waldo_MG_ChessPromotionPending", [_selected, _index, _revision]];
        [_display] call Waldo_MG_fnc_refreshChessLocal;
        ["Choose the unit type for this pawn's promotion."] call Waldo_MG_fnc_notifyLocal;
    };
    _display setVariable ["Waldo_MG_ChessMovePending", true];
    _display setVariable ["Waldo_MG_ChessSelectedFrom", -1];
    [_table, _selected, _index, 0, _revision] call Waldo_MG_fnc_submitChessMoveRequestLocal;
};

Waldo_MG_fnc_handleChessResignLocal = {
    disableSerialization;
    params [["_control", controlNull]];
    if (isNull _control) exitWith {};
    private _display = ctrlParent _control;
    if (isNull _display) exitWith {};
    private _table = _display getVariable ["Waldo_MG_ChessTable", objNull];
    if (isNull _table) exitWith {};
    private _armedUntil = _display getVariable ["Waldo_MG_ChessResignArmedUntil", -1];
    if (diag_tickTime <= _armedUntil) then {
        _display setVariable ["Waldo_MG_ChessResignArmedUntil", -1];
        [_table, "RESIGN"] call Waldo_MG_fnc_submitChessActionRequestLocal;
    } else {
        _display setVariable ["Waldo_MG_ChessResignArmedUntil", diag_tickTime + 3];
        ["Press Resign again within three seconds to confirm."] call Waldo_MG_fnc_notifyLocal;
    };
};

Waldo_MG_fnc_refreshChessLocal = {
    disableSerialization;
    params [["_display", displayNull]];
    if (isNull _display) exitWith {};
    if (_display getVariable ["Waldo_MG_ChessRefreshing", false]) exitWith {};
    _display setVariable ["Waldo_MG_ChessRefreshing", true];
    private _table = _display getVariable ["Waldo_MG_ChessTable", objNull];
    private _spectating = _display getVariable ["Waldo_MG_SpectatorMode", false];
    if (!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)) exitWith {
        _display closeDisplay 1;
    };
    if (([_table] call Waldo_MG_fnc_getTableActiveGameId) != "chess") exitWith {
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

    private _side = [_table] call Waldo_MG_fnc_getChessPlayerSideLocal;
    private _board = [(_table getVariable ["Waldo_MG_ChessBoard", []])] call Waldo_MG_fnc_chessNormalizeBoard;
    private _turn = _table getVariable ["Waldo_MG_ChessTurn", 1];
    private _rights = [(_table getVariable ["Waldo_MG_ChessCastlingRights", []])] call Waldo_MG_fnc_chessNormalizeCastlingRights;
    private _enPassant = _table getVariable ["Waldo_MG_ChessEnPassant", -1];
    private _finished = _table getVariable ["Waldo_MG_ChessFinished", false];
    private _winner = _table getVariable ["Waldo_MG_ChessWinner", 0];
    private _revision = _table getVariable ["Waldo_MG_ChessRevision", 0];
    private _lastRevision = _display getVariable ["Waldo_MG_ChessLastRevision", -1];
    private _selected = _display getVariable ["Waldo_MG_ChessSelectedFrom", -1];
    if (_revision != _lastRevision) then {
        _display setVariable ["Waldo_MG_ChessMovePending", false];
        _display setVariable ["Waldo_MG_ChessPromotionPending", []];
        if (_selected >= 0 && {([_board param [_selected, 0]] call Waldo_MG_fnc_chessPieceSide) != _side}) then {
            _selected = -1;
        };
        _display setVariable ["Waldo_MG_ChessSelectedFrom", _selected];
        private _checkedKing = -1;
        if (!_finished && {[_board, _turn] call Waldo_MG_fnc_chessIsKingInCheck}) then {
            _checkedKing = [_board, _turn] call Waldo_MG_fnc_chessFindKing;
        };
        _display setVariable ["Waldo_MG_ChessCheckedKing", _checkedKing];
        _display setVariable ["Waldo_MG_ChessLegalCacheRevision", -1];
        _display setVariable ["Waldo_MG_ChessLastRevision", _revision];
    };
    private _legalMoves = [];
    if (_selected >= 0 && {_turn == _side} && {!_finished}) then {
        private _cacheRevision = _display getVariable ["Waldo_MG_ChessLegalCacheRevision", -1];
        private _cacheSelected = _display getVariable ["Waldo_MG_ChessLegalCacheSelected", -1];
        if (_cacheRevision != _revision || {_cacheSelected != _selected}) then {
            _legalMoves = [_board, _side, _selected, _rights, _enPassant] call Waldo_MG_fnc_chessGetLegalMoves;
            _display setVariable ["Waldo_MG_ChessLegalCache", _legalMoves];
            _display setVariable ["Waldo_MG_ChessLegalCacheRevision", _revision];
            _display setVariable ["Waldo_MG_ChessLegalCacheSelected", _selected];
        } else {
            _legalMoves = _display getVariable ["Waldo_MG_ChessLegalCache", []];
        };
    } else {
        _display setVariable ["Waldo_MG_ChessLegalCache", []];
        _display setVariable ["Waldo_MG_ChessLegalCacheSelected", -1];
    };
    private _legalDestinations = [];
    {
        _legalDestinations pushBack (_x param [0, -1]);
    } forEach _legalMoves;
    private _lastMove = _table getVariable ["Waldo_MG_ChessLastMove", []];
    private _lastFrom = _lastMove param [0, -1];
    private _lastTo = _lastMove param [1, -1];
    private _checkedKing = _display getVariable ["Waldo_MG_ChessCheckedKing", -1];
    private _squareControls = _display getVariable ["Waldo_MG_ChessSquareControls", []];
    private _pieceControls = _display getVariable ["Waldo_MG_ChessPieceControls", []];
    private _selectionPulse = 0.5 + (0.5 * sin (diag_tickTime * 120));
    for "_controlIndex" from 0 to ((count _squareControls) - 1) do {
        private _control = _squareControls param [_controlIndex, controlNull];
        private _picture = _pieceControls param [_controlIndex, controlNull];
        if (!isNull _control) then {
            private _index = _control getVariable ["Waldo_MG_ChessSquareIndex", -1];
            private _row = floor (_index / 8);
            private _column = _index mod 8;
            private _dark = ((_row + _column) mod 2) == 1;
            private _background = if (_dark) then {[0.13, 0.17, 0.20, 1]} else {[0.76, 0.75, 0.67, 1]};
            if (_index == _lastFrom || {_index == _lastTo}) then {
                _background = [0.22, 0.34, 0.43, 1];
            };
            if (_index == _checkedKing) then {
                _background = [0.72, 0.08, 0.08, 1];
            };
            if (_index == _selected) then {
                _background = [
                    0.78 + (0.06 * _selectionPulse),
                    0.55 + (0.05 * _selectionPulse),
                    0.12 + (0.02 * _selectionPulse),
                    1
                ];
            };
            if (_index in _legalDestinations) then {
                _background = if ((_board param [_index, 0]) == 0) then {
                    [0.16, 0.55, 0.28, 1]
                } else {
                    [0.64, 0.20, 0.16, 1]
                };
            };
            _control ctrlSetBackgroundColor _background;
            private _piece = _board param [_index, 0];
            private _squareName = [_index] call Waldo_MG_fnc_chessGetSquareName;
            private _specialText = "";
            {
                if ((_x param [0, -1]) == _index) exitWith {
                    private _special = _x param [1, ""];
                    _specialText = switch (_special) do {
                        case "CASTLE_K": {" - castle king-side"};
                        case "CASTLE_Q": {" - castle queen-side"};
                        case "EN_PASSANT": {" - en passant"};
                        case "PROMOTION": {" - promotion"};
                        default {" - legal destination"};
                    };
                };
            } forEach _legalMoves;
            _control ctrlSetTooltip (if (_piece == 0) then {
                format ["%1%2", _squareName, _specialText]
            } else {
                format [
                    "%1: %2 %3%4",
                    _squareName,
                    [[_piece] call Waldo_MG_fnc_chessPieceSide] call Waldo_MG_fnc_chessSideName,
                    [_piece] call Waldo_MG_fnc_chessPieceName,
                    _specialText
                ]
            });
            _control ctrlCommit 0;
            if (!isNull _picture) then {
                private _renderedPiece = _picture getVariable ["Waldo_MG_ChessRenderedPiece", 99];
                if (_renderedPiece != _piece) then {
                    if (_piece == 0) then {
                        _picture ctrlShow false;
                    } else {
                        _picture ctrlSetText ([_piece] call Waldo_MG_fnc_chessGetMarkerTextureLocal);
                        _picture ctrlSetTextColor (if (_piece > 0) then {
                            [0.18, 0.62, 1, 1]
                        } else {
                            [1, 0.18, 0.14, 1]
                        });
                        _picture ctrlShow true;
                    };
                    _picture setVariable ["Waldo_MG_ChessRenderedPiece", _piece];
                    _picture ctrlCommit 0;
                };
            };
        };
    };

    private _names = _table getVariable ["Waldo_MG_ChessPlayerNames", ["NATO White", "CSAT Black"]];
    private _whiteName = _names param [0, "NATO White"];
    private _blackName = _names param [1, "CSAT Black"];
    private _whiteLabel = _display getVariable ["Waldo_MG_ChessWhiteLabel", controlNull];
    private _blackLabel = _display getVariable ["Waldo_MG_ChessBlackLabel", controlNull];
    private _turnLabel = _display getVariable ["Waldo_MG_ChessTurnLabel", controlNull];
    private _statusOne = _display getVariable ["Waldo_MG_ChessStatusOne", controlNull];
    private _statusTwo = _display getVariable ["Waldo_MG_ChessStatusTwo", controlNull];
    private _drawButton = _display getVariable ["Waldo_MG_ChessDrawButton", controlNull];
    private _claimButton = _display getVariable ["Waldo_MG_ChessClaimButton", controlNull];
    private _resignButton = _display getVariable ["Waldo_MG_ChessResignButton", controlNull];
    if (!isNull _whiteLabel) then {
        _whiteLabel ctrlSetText format ["NATO WHITE  %1", _whiteName];
        _whiteLabel ctrlCommit 0;
    };
    if (!isNull _blackLabel) then {
        _blackLabel ctrlSetText format ["CSAT BLACK  %1", _blackName];
        _blackLabel ctrlCommit 0;
    };
    if (!isNull _turnLabel) then {
        _turnLabel ctrlSetText (if (_finished) then {
            if (_winner == 0) then {"RESULT: DRAW"} else {format ["WINNER: %1", [_winner] call Waldo_MG_fnc_chessSideName]}
        } else {
            format ["TURN: %1", [_turn] call Waldo_MG_fnc_chessSideName]
        });
        _turnLabel ctrlSetTextColor (if (_finished) then {
            [0.98, 0.80, 0.22, 1]
        } else {
            if (_turn > 0) then {[0.22, 0.66, 1, 1]} else {[1, 0.28, 0.22, 1]}
        });
        _turnLabel ctrlCommit 0;
    };
    if (!isNull _statusOne) then {
        _statusOne ctrlSetText (_table getVariable ["Waldo_MG_ChessStatus", "Chess in progress."]);
        _statusOne ctrlCommit 0;
    };
    if (!isNull _statusTwo) then {
        private _yourRole = if (_side == 0) then {"Observer"} else {[_side] call Waldo_MG_fnc_chessSideName};
        private _claimText = if ((_table getVariable ["Waldo_MG_ChessCanClaimThreefold", false]) || {_table getVariable ["Waldo_MG_ChessCanClaimFifty", false]}) then {
            "  DRAW CLAIM AVAILABLE"
        } else {
            ""
        };
        _statusTwo ctrlSetText format [
            "You: %1   Full move %2   Halfmove clock %3%4",
            _yourRole,
            _table getVariable ["Waldo_MG_ChessFullmoveNumber", 1],
            _table getVariable ["Waldo_MG_ChessHalfmoveClock", 0],
            _claimText
        ];
        _statusTwo ctrlCommit 0;
    };
    private _offerSide = _table getVariable ["Waldo_MG_ChessDrawOfferSide", 0];
    if (!isNull _drawButton) then {
        _drawButton ctrlShow !_spectating;
        if (_finished) then {
            _drawButton ctrlSetText "Reset to Lobby";
            _drawButton ctrlEnable !_spectating;
        } else {
            _drawButton ctrlSetText (if (_offerSide == 0) then {
                "Offer Draw"
            } else {
                if (_offerSide == _side) then {"Withdraw Draw"} else {"Accept Draw"}
            });
            _drawButton ctrlEnable (_side != 0);
        };
        _drawButton ctrlCommit 0;
    };
    if (!isNull _claimButton) then {
        private _canClaim = !_finished
            && {!_spectating}
            && {_side == _turn}
            && {(_table getVariable ["Waldo_MG_ChessCanClaimThreefold", false]) || {_table getVariable ["Waldo_MG_ChessCanClaimFifty", false]}};
        _claimButton ctrlSetText (if (_canClaim) then {"Claim Draw"} else {"No Draw Claim"});
        _claimButton ctrlEnable _canClaim;
        _claimButton ctrlShow (!_spectating && {!_finished});
        _claimButton ctrlCommit 0;
    };
    if (!isNull _resignButton) then {
        private _armed = diag_tickTime <= (_display getVariable ["Waldo_MG_ChessResignArmedUntil", -1]);
        _resignButton ctrlSetText (if (_armed) then {"Confirm Resign"} else {"Resign"});
        _resignButton ctrlEnable (!_spectating && {!_finished} && {_side != 0});
        _resignButton ctrlShow (!_spectating && {!_finished});
        _resignButton ctrlCommit 0;
    };
    private _promotionPending = _display getVariable ["Waldo_MG_ChessPromotionPending", []];
    private _promotionControls = _display getVariable ["Waldo_MG_ChessPromotionControls", []];
    private _showPromotion = !_spectating && {(count _promotionPending) >= 3} && {!_finished};
    {
        if (!isNull _x) then {
            _x ctrlShow _showPromotion;
        };
    } forEach _promotionControls;
    _display setVariable ["Waldo_MG_ChessRefreshing", false];
};

Waldo_MG_fnc_openChessLocal = {
    disableSerialization;
    params [
        ["_table", objNull],
        ["_spectating", false]
    ];
    if (!hasInterface || {isNull player}) exitWith {};
    if (
        isNull _table
        || {!([_table, _spectating] call Waldo_MG_fnc_isValidGameViewerLocal)}
        || {([_table] call Waldo_MG_fnc_getTableActiveGameId) != "chess"}
    ) exitWith {
        ["No active Chess match is available to this viewer."] call Waldo_MG_fnc_notifyLocal;
    };
    private _parent = findDisplay 46;
    if (isNull _parent) exitWith {
        ["The Chess display is unavailable."] call Waldo_MG_fnc_notifyLocal;
    };
    private _lobby = uiNamespace getVariable ["Waldo_MG_LobbyDisplay", displayNull];
    if (!isNull _lobby) then {_lobby closeDisplay 1;};
    private _checkers = uiNamespace getVariable ["Waldo_MG_CheckersDisplay", displayNull];
    if (!isNull _checkers) then {_checkers closeDisplay 1;};
    private _battleship = uiNamespace getVariable ["Waldo_MG_BattleshipDisplay", displayNull];
    if (!isNull _battleship) then {_battleship closeDisplay 1;};
    private _whosWho = uiNamespace getVariable ["Waldo_MG_WhosWhoDisplay", displayNull];
    if (!isNull _whosWho) then {_whosWho closeDisplay 1;};
    private _shotgun = uiNamespace getVariable ["Waldo_MG_ShotgunDisplay", displayNull];
    if (!isNull _shotgun) then {_shotgun closeDisplay 1;};
    private _rps = uiNamespace getVariable ["Waldo_MG_RPSDisplay", displayNull];
    if (!isNull _rps) then {_rps closeDisplay 1;};
    private _blackjack = uiNamespace getVariable ["Waldo_MG_BlackjackDisplay", displayNull];
    if (!isNull _blackjack) then {_blackjack closeDisplay 1;};
    private _existing = uiNamespace getVariable ["Waldo_MG_ChessDisplay", displayNull];
    if (!isNull _existing) then {_existing closeDisplay 1;};
    private _poker = uiNamespace getVariable ["Waldo_MG_PokerDisplay", displayNull];
    if (!isNull _poker) then {_poker closeDisplay 1;};
    private _uno = uiNamespace getVariable ["Waldo_MG_UNODisplay", displayNull];
    if (!isNull _uno) then {_uno closeDisplay 1;};
    private _display = _parent createDisplay "RscDisplayEmpty";
    if (isNull _display) exitWith {};
    uiNamespace setVariable ["Waldo_MG_ChessDisplay", _display];
    _display setVariable ["Waldo_MG_ChessTable", _table];
    _display setVariable ["Waldo_MG_SpectatorMode", _spectating];
    _display setVariable ["Waldo_MG_ChessLastRevision", -1];
    _display setVariable ["Waldo_MG_ChessSelectedFrom", -1];
    _display setVariable ["Waldo_MG_ChessMovePending", false];
    _display setVariable ["Waldo_MG_ChessPromotionPending", []];
    _display setVariable ["Waldo_MG_ChessResignArmedUntil", -1];
    [_display] call Waldo_MG_fnc_installEscapeGuardLocal; 
 
    private _focusSink = _display ctrlCreate ["RscButton", -1];
    _focusSink ctrlSetPosition [-10, -10, 0.001, 0.001];
    _focusSink ctrlSetText "";
    _focusSink ctrlCommit 0;
    _display setVariable ["Waldo_MG_ChessFocusSink", _focusSink];
    ctrlSetFocus _focusSink;

    private _background = _display ctrlCreate ["RscText", -1];
    _background ctrlSetPosition [0.005, 0.015, 1.17, 1.055];
    _background ctrlSetBackgroundColor [0.010, 0.014, 0.022, 0.98];
    _background ctrlCommit 0;
    private _topBar = _display ctrlCreate ["RscText", -1];
    _topBar ctrlSetPosition [0.005, 0.015, 1.17, 0.075];
    _topBar ctrlSetBackgroundColor [0.10, 0.18, 0.27, 1];
    _topBar ctrlCommit 0;
    private _title = _display ctrlCreate ["RscText", -1];
    _title ctrlSetPosition [0.035, 0.026, 0.55, 0.052];
    _title ctrlSetText "PARTYGAMES  /  CHESS";
    _title ctrlSetTextColor [0.84, 0.94, 1, 1];
    _title ctrlSetFontHeight 0.038;
    _title ctrlCommit 0;
    private _subtitle = _display ctrlCreate ["RscText", -1];
    _subtitle ctrlSetPosition [0.55, 0.035, 0.58, 0.038];
    _subtitle ctrlSetText (if (_spectating) then {"SPECTATOR VIEW  /  NATO White moves first"} else {"NATO White moves first  /  marker-icon command board"});
    _subtitle ctrlSetTextColor [0.70, 0.84, 0.94, 1];
    _subtitle ctrlSetFontHeight 0.021;
    _subtitle ctrlCommit 0;

    private _boardFrame = _display ctrlCreate ["RscText", -1];
    _boardFrame ctrlSetPosition [0.030, 0.115, 0.836, 0.836];
    _boardFrame ctrlSetBackgroundColor [0.26, 0.28, 0.31, 1];
    _boardFrame ctrlCommit 0;
    private _side = [_table] call Waldo_MG_fnc_getChessPlayerSideLocal;
    private _squareControls = [];
    private _pieceControls = [];
    for "_visualRow" from 0 to 7 do {
        for "_visualColumn" from 0 to 7 do {
            private _logicalRow = if (_side < 0) then {7 - _visualRow} else {_visualRow};
            private _logicalColumn = if (_side < 0) then {7 - _visualColumn} else {_visualColumn};
            private _index = (_logicalRow * 8) + _logicalColumn;
            private _squareX = 0.034 + (_visualColumn * 0.1035);
            private _squareY = 0.119 + (_visualRow * 0.1035);
            private _square = _display ctrlCreate ["RscButton", -1];
            _square ctrlSetPosition [_squareX, _squareY, 0.1015, 0.1015];
            _square ctrlSetText "";
            _square setVariable ["Waldo_MG_ChessSquareIndex", _index];
            _square ctrlAddEventHandler [
                "ButtonClick",
                {
                    params ["_control"];
                    [_control] call Waldo_MG_fnc_handleChessSquareClickLocal;
                }
            ];
            _square ctrlCommit 0;
            _squareControls pushBack _square;
            private _picture = _display ctrlCreate ["RscPictureKeepAspect", -1];
            _picture ctrlSetPosition [_squareX + 0.010, _squareY + 0.010, 0.0815, 0.0815];
            _picture ctrlEnable false;
            _picture ctrlShow false;
            _picture ctrlCommit 0;
            _pieceControls pushBack _picture;
        };
    };
    _display setVariable ["Waldo_MG_ChessSquareControls", _squareControls];
    _display setVariable ["Waldo_MG_ChessPieceControls", _pieceControls];

    private _panel = _display ctrlCreate ["RscText", -1];
    _panel ctrlSetPosition [0.895, 0.115, 0.245, 0.836];
    _panel ctrlSetBackgroundColor [0.025, 0.040, 0.060, 0.98];
    _panel ctrlCommit 0;
    private _whiteLabel = _display ctrlCreate ["RscText", -1];
    _whiteLabel ctrlSetPosition [0.915, 0.140, 0.205, 0.052];
    _whiteLabel ctrlSetTextColor [0.20, 0.62, 1, 1];
    _whiteLabel ctrlSetFontHeight 0.022;
    _whiteLabel ctrlCommit 0;
    private _versus = _display ctrlCreate ["RscText", -1];
    _versus ctrlSetPosition [0.915, 0.195, 0.205, 0.030];
    _versus ctrlSetText "VERSUS";
    _versus ctrlSetTextColor [0.62, 0.68, 0.74, 1];
    _versus ctrlSetFontHeight 0.017;
    _versus ctrlCommit 0;
    private _blackLabel = _display ctrlCreate ["RscText", -1];
    _blackLabel ctrlSetPosition [0.915, 0.230, 0.205, 0.052];
    _blackLabel ctrlSetTextColor [1, 0.28, 0.22, 1];
    _blackLabel ctrlSetFontHeight 0.022;
    _blackLabel ctrlCommit 0;
    private _turnLabel = _display ctrlCreate ["RscText", -1];
    _turnLabel ctrlSetPosition [0.915, 0.305, 0.205, 0.055];
    _turnLabel ctrlSetFontHeight 0.025;
    _turnLabel ctrlCommit 0;
    private _legendTitle = _display ctrlCreate ["RscText", -1];
    _legendTitle ctrlSetPosition [0.915, 0.385, 0.205, 0.035];
    _legendTitle ctrlSetText "COMMAND SYMBOLS";
    _legendTitle ctrlSetTextColor [0.80, 0.84, 0.88, 1];
    _legendTitle ctrlSetFontHeight 0.019;
    _legendTitle ctrlCommit 0;
    private _legendOne = _display ctrlCreate ["RscText", -1];
    _legendOne ctrlSetPosition [0.915, 0.430, 0.205, 0.032];
    _legendOne ctrlSetText "INF Pawn   /   ARMOR Rook";
    _legendOne ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _legendOne ctrlSetFontHeight 0.016;
    _legendOne ctrlCommit 0;
    private _legendTwo = _display ctrlCreate ["RscText", -1];
    _legendTwo ctrlSetPosition [0.915, 0.468, 0.205, 0.032];
    _legendTwo ctrlSetText "HELI Knight  /   ARTY Bishop";
    _legendTwo ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _legendTwo ctrlSetFontHeight 0.016;
    _legendTwo ctrlCommit 0;
    private _legendThree = _display ctrlCreate ["RscText", -1];
    _legendThree ctrlSetPosition [0.915, 0.506, 0.205, 0.032];
    _legendThree ctrlSetText "PLANE Queen / MAINT King";
    _legendThree ctrlSetTextColor [0.68, 0.74, 0.80, 1];
    _legendThree ctrlSetFontHeight 0.016;
    _legendThree ctrlCommit 0;
    private _ruleOne = _display ctrlCreate ["RscText", -1];
    _ruleOne ctrlSetPosition [0.915, 0.558, 0.205, 0.030];
    _ruleOne ctrlSetText "Green move / Red capture";
    _ruleOne ctrlSetTextColor [0.60, 0.78, 0.68, 1];
    _ruleOne ctrlSetFontHeight 0.016;
    _ruleOne ctrlCommit 0;
    private _ruleTwo = _display ctrlCreate ["RscText", -1];
    _ruleTwo ctrlSetPosition [0.915, 0.592, 0.205, 0.030];
    _ruleTwo ctrlSetText "Checked king: red square";
    _ruleTwo ctrlSetTextColor [0.86, 0.58, 0.58, 1];
    _ruleTwo ctrlSetFontHeight 0.016;
    _ruleTwo ctrlCommit 0;
    private _ruleThree = _display ctrlCreate ["RscText", -1];
    _ruleThree ctrlSetPosition [0.915, 0.626, 0.205, 0.030];
    _ruleThree ctrlSetText (if (_spectating) then {"Read-only spectator board"} else {"Leave Table: forfeit"});
    _ruleThree ctrlSetTextColor [0.92, 0.63, 0.36, 1];
    _ruleThree ctrlSetFontHeight 0.016;
    _ruleThree ctrlCommit 0;

    private _promotionLabel = _display ctrlCreate ["RscText", -1];
    _promotionLabel ctrlSetPosition [0.915, 0.675, 0.205, 0.035];
    _promotionLabel ctrlSetText "CHOOSE PROMOTION";
    _promotionLabel ctrlSetTextColor [0.98, 0.80, 0.22, 1];
    _promotionLabel ctrlSetFontHeight 0.018;
    _promotionLabel ctrlCommit 0;
    private _promotionControls = [_promotionLabel];
    private _promotionData = [[5, "Queen"], [4, "Rook"], [3, "Bishop"], [2, "Knight"]];
    for "_promotionIndex" from 0 to 3 do {
        private _promotion = _promotionData param [_promotionIndex, [5, "Queen"]];
        private _button = _display ctrlCreate ["RscButtonMenu", -1];
        _button ctrlSetPosition [
            0.915 + ((_promotionIndex mod 2) * 0.105),
            0.715 + ((floor (_promotionIndex / 2)) * 0.045),
            0.098,
            0.038
        ];
        _button ctrlSetText (_promotion param [1, "Queen"]);
        _button setVariable ["Waldo_MG_ChessPromotionType", _promotion param [0, 5]];
        _button ctrlAddEventHandler [
            "ButtonClick",
            {
                params ["_control"];
                [_control] call Waldo_MG_fnc_selectChessPromotionLocal;
            }
        ];
        _button ctrlCommit 0;
        _promotionControls pushBack _button;
    };
    {
        _x ctrlShow false;
    } forEach _promotionControls;
    _display setVariable ["Waldo_MG_ChessPromotionControls", _promotionControls];

    private _drawButton = _display ctrlCreate ["RscButtonMenu", -1];
    _drawButton ctrlSetPosition [0.915, 0.805, 0.205, 0.040];
    _drawButton ctrlCommit 0;
    private _claimButton = _display ctrlCreate ["RscButtonMenu", -1];
    _claimButton ctrlSetPosition [0.915, 0.852, 0.205, 0.040];
    _claimButton ctrlCommit 0;
    private _resignButton = _display ctrlCreate ["RscButtonMenu", -1];
    _resignButton ctrlSetPosition [0.915, 0.899, 0.205, 0.040];
    _resignButton ctrlCommit 0;

    private _statusBackground = _display ctrlCreate ["RscText", -1];
    _statusBackground ctrlSetPosition [0.030, 0.972, 1.110, 0.070];
    _statusBackground ctrlSetBackgroundColor [0.035, 0.055, 0.075, 1];
    _statusBackground ctrlCommit 0;
    private _statusOne = _display ctrlCreate ["RscText", -1];
    _statusOne ctrlSetPosition [0.050, 0.978, 0.70, 0.030];
    _statusOne ctrlSetTextColor [0.90, 0.94, 1, 1];
    _statusOne ctrlSetFontHeight 0.018;
    _statusOne ctrlCommit 0;
    private _statusTwo = _display ctrlCreate ["RscText", -1];
    _statusTwo ctrlSetPosition [0.050, 1.008, 0.70, 0.026];
    _statusTwo ctrlSetTextColor [0.62, 0.78, 0.90, 1];
    _statusTwo ctrlSetFontHeight 0.015;
    _statusTwo ctrlCommit 0;
    private _leaveButton = _display ctrlCreate ["RscButtonMenu", -1];
    _leaveButton ctrlSetPosition [0.915, 0.982, 0.210, 0.050];
    _leaveButton ctrlSetText (if (_spectating) then {"Exit Spectate"} else {"Leave Table"});
    _leaveButton ctrlCommit 0;

    _display setVariable ["Waldo_MG_ChessWhiteLabel", _whiteLabel];
    _display setVariable ["Waldo_MG_ChessBlackLabel", _blackLabel];
    _display setVariable ["Waldo_MG_ChessTurnLabel", _turnLabel];
    _display setVariable ["Waldo_MG_ChessStatusOne", _statusOne];
    _display setVariable ["Waldo_MG_ChessStatusTwo", _statusTwo];
    _display setVariable ["Waldo_MG_ChessDrawButton", _drawButton];
    _display setVariable ["Waldo_MG_ChessClaimButton", _claimButton];
    _display setVariable ["Waldo_MG_ChessResignButton", _resignButton];
    _drawButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            private _display = ctrlParent _control;
            private _table = _display getVariable ["Waldo_MG_ChessTable", objNull];
            private _action = if (!isNull _table && {_table getVariable ["Waldo_MG_ChessFinished", false]}) then {"RESET"} else {"DRAW_OFFER"};
            [_table, _action] call Waldo_MG_fnc_submitChessActionRequestLocal;
        }
    ];
    _claimButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            private _display = ctrlParent _control;
            [(_display getVariable ["Waldo_MG_ChessTable", objNull]), "CLAIM_DRAW"] call Waldo_MG_fnc_submitChessActionRequestLocal;
        }
    ];
    _resignButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            [_control] call Waldo_MG_fnc_handleChessResignLocal;
        }
    ];
    _leaveButton ctrlAddEventHandler [
        "ButtonClick",
        {
            params ["_control"];
            [_control] call Waldo_MG_fnc_handleViewerExitButtonLocal;
        }
    ];
    [_display] call Waldo_MG_fnc_refreshChessLocal;
    [_display] spawn {
        disableSerialization;
        params ["_activeDisplay"];
        while {!isNull _activeDisplay} do {
            [_activeDisplay] call Waldo_MG_fnc_refreshChessLocal;
            uiSleep Waldo_MG_CFG_CHESS_UI_TICK;
        };
    };
}; 
 


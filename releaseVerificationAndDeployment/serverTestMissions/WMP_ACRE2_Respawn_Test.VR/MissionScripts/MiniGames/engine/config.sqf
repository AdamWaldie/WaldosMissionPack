/*
 * Waldos Mini Games - engine configuration
 * Game catalog (Waldo_MG_Games) and all tuning constants (Waldo_MG_CFG_*).
 *
 * Original engine: "Party Games Scripted" by |LorD|[Habilidade]Deus Ex.
 * Ported into WaldosMissionPack and rebranded to the Waldo_MG_ namespace; game
 * logic is preserved from the original composition. Do not claim original authorship.
 *
 * This file is an engine fragment: it defines a group of Waldo_MG_fnc_* runtime
 * functions and is #included by Waldo_fnc_MiniGamesInit (miniGamesInit.sqf).
 * It is not a standalone CfgFunctions entry and is not called directly.
 */

Waldo_MG_Games = [
    [
        "battleship",
        "Battleship",
        [
            "Deploy a hidden fleet, call coordinates and trade shots.",
            "Find and sink all five opposing ships before yours disappear."
        ],
        2,
        2,
        [
            "Playable: private 10x10 fleets, placement previews and rotation.",
            "Alternating shots, misses, hits, sunk ships and safe spectators."
        ]
    ],
    [
        "whoswho",
        "Who's Who: Vehicles",
        [
            "Ask questions aloud and eliminate vehicle suspects.",
            "Guess the opponent's hidden vehicle before they find yours."
        ],
        2,
        2,
        [
            "Playable: 48 vanilla vehicle previews and private targets.",
            "Local red-X notes, alternating turns, guesses and spectators."
        ]
    ],
    [
        "shotgun",
        "Shotgun Roulette",
        [
            "Read the shell ledger, use items and choose where to aim.",
            "Last player with lives remaining wins the table."
        ],
        2,
        4,
        [
            "Playable: hidden chamber, self-shots, targeting and six items.",
            "Three lives each; empty loads preserve lives and carried items."
        ]
    ],
    [
        "blackjack",
        "Blackjack",
        [
            "Challenge the automated dealer without passing 21.",
            "Playable alone or with up to three fellow gamblers."
        ],
        1,
        4,
        [
            "Playable: even bets, Hit, Stand, Double and 3:2 Blackjack.",
            "Dealer stands on soft 17; no splits, insurance or surrender."
        ]
    ],
    [
        "poker",
        "Texas Hold'em",
        [
            "Read the table and manage the pot.",
            "Conceal good hands; bluff responsibly."
        ],
        2,
        4,
        [
            "Playable no-limit Hold'em with blinds, side pots and all-ins.",
            "Start with 100 chips; survive the table to win."
        ]
    ],
    [
        "drawpoker",
        "Five-Card Draw",
        [
            "Ante, bet, exchange up to three cards, then bet again.",
            "Stand pat or improve your private hand before showdown."
        ],
        2,
        4,
        [
            "Server-authoritative no-limit betting, all-ins and side pots.",
            "Start with 100 chips; private cards are never sent to spectators."
        ]
    ],
    [
        "liarsdice",
        "Liar's Dice",
        [
            "Raise the table bid or challenge the previous player.",
            "Ones are wild; the last player with dice wins."
        ],
        2,
        4,
        [
            "Five private dice each; bids use faces two through six.",
            "Dice show both pips and numerals during the public reveal."
        ]
    ],
    [
        "chess",
        "Chess",
        [
            "A two-player strategy duel.",
            "Plan ahead while Zeus plans the mission."
        ],
        2,
        2,
        [
            "Playable: check, castling, en passant and promotion.",
            "Marker-icon armies turn the table into a command board."
        ]
    ],
    [
        "checkers",
        "Checkers",
        [
            "A quick duel of diagonals and captures.",
            "Reach the far side and earn a king."
        ],
        2,
        2,
        [
            "Playable: compulsory captures and chained jumps.",
            "Blue moves first; reach the far rank to earn a king."
        ]
    ],
    [
        "connectfour",
        "Connect Four",
        [
            "Drop discs into the seven-column grid.",
            "Connect four horizontally, vertically or diagonally."
        ],
        2,
        2,
        [
            "Playable with mouse or number keys 1-7.",
            "Blue O and Amber X play first to two board wins."
        ]
    ],
    [
        "rps",
        "Rock Paper Scissors",
        [
            "Lock a choice, then face the reveal together.",
            "A quick two-player contest with no hidden arithmetic."
        ],
        2,
        2,
        [
            "Playable: simultaneous hidden choices and a reveal countdown.",
            "First to two round wins takes the best-of-three match; draws replay."
        ]
    ],
    [
        "uno",
        "UNO",
        [
            "Shed cards quickly with two to four players.",
            "Ideal for short, preventable arguments."
        ],
        2,
        4,
        [
            "Playable: paged private hands, stacking and draw chains.",
            "Call UNO before one card remains, or risk a callout."
        ]
    ]
];

Waldo_MG_CFG_TABLE_CLASSES = [
    "Land_CampingTable_F",
    "Land_CampingTable_small_F",
    "Land_CampingTable_small_white_F",
    "Land_TablePlastic_01_F"
];
Waldo_MG_CFG_SEAT_COUNT = 4;
Waldo_MG_CFG_SEAT_OFFSETS = [
    [0, -1.05, 0],
    [0, 1.05, 0],
    [-1.35, 0, 0],
    [1.35, 0, 0]
];
Waldo_MG_CFG_SEAT_EXIT_OFFSETS = [
    [0, -1.85, 0],
    [0, 1.85, 0],
    [-2.05, 0, 0],
    [2.05, 0, 0]
];
Waldo_MG_CFG_SEAT_DIRECTIONS = [0, 180, 90, 270];
Waldo_MG_CFG_SEATED_ANIMATION = "HubSittingChairA_idle1";
Waldo_MG_CFG_ACTION_RANGE = 4.5;
Waldo_MG_CFG_PERSONAL_ACTION_RANGE = 2;
Waldo_MG_CFG_REQUEST_RANGE = 6;
Waldo_MG_CFG_AUTHORITY_TICK = 0.5;
Waldo_MG_CFG_CLIENT_TICK = 0.5;
Waldo_MG_CFG_DISCOVERY_TICK = 10;
Waldo_MG_CFG_MAINTENANCE_TICK = 10;
Waldo_MG_CFG_CHECKERS_UI_TICK = 0.15;
Waldo_MG_CFG_CONNECTFOUR_UI_TICK = 0.10;
Waldo_MG_CFG_CONNECTFOUR_COLUMNS = 7;
Waldo_MG_CFG_CONNECTFOUR_ROWS = 6;
Waldo_MG_CFG_CONNECTFOUR_WINS_REQUIRED = 2;
Waldo_MG_CFG_DRAWPOKER_UI_TICK = 0.15;
Waldo_MG_CFG_DRAWPOKER_STARTING_CHIPS = 100;
Waldo_MG_CFG_DRAWPOKER_ANTE = 1;
Waldo_MG_CFG_DRAWPOKER_MAX_DISCARDS = 3;
Waldo_MG_CFG_LIARSDICE_UI_TICK = 0.15;
Waldo_MG_CFG_LIARSDICE_STARTING_DICE = 5;
Waldo_MG_CFG_LIARSDICE_REVEAL_SECONDS = 2.5;
Waldo_MG_CFG_RPS_UI_TICK = 0.10;
Waldo_MG_CFG_RPS_COUNTDOWN_SECONDS = 3;
Waldo_MG_CFG_RPS_REVEAL_SECONDS = 3.5;
Waldo_MG_CFG_SHOTGUN_UI_TICK = 0.10;
Waldo_MG_CFG_SHOTGUN_STARTING_LIVES = 3;
Waldo_MG_CFG_SHOTGUN_MAX_LIVES = 5;
Waldo_MG_CFG_SHOTGUN_MIN_SHELLS = 2;
Waldo_MG_CFG_SHOTGUN_MAX_SHELLS = 8;
Waldo_MG_CFG_SHOTGUN_ITEMS_PER_LOAD = 2;
Waldo_MG_CFG_SHOTGUN_INVENTORY_LIMIT = 4;
Waldo_MG_CFG_SHOTGUN_REVEAL_SECONDS = 1.6;
Waldo_MG_CFG_SHOTGUN_LOAD_REVEAL_SECONDS = 4.0;
Waldo_MG_CFG_SHOTGUN_UI_SCALE = 1.18;
Waldo_MG_CFG_SHOTGUN_UI_CENTER = [0.590, 0.5425];
Waldo_MG_CFG_WHOSWHO_UI_TICK = 0.15;
Waldo_MG_CFG_WHOSWHO_PER_FACTION = 12;
Waldo_MG_CFG_BLACKJACK_UI_TICK = 0.15;
Waldo_MG_CFG_BLACKJACK_STARTING_CHIPS = 100;
Waldo_MG_CFG_BLACKJACK_MINIMUM_BET = 2;
Waldo_MG_CFG_BLACKJACK_DECKS = 6;
Waldo_MG_CFG_BLACKJACK_CUT_REMAINING = 52;
Waldo_MG_CFG_BLACKJACK_DEALER_STEP_SECONDS = 1;
Waldo_MG_CFG_BLACKJACK_CARD_SLOTS = 8;
Waldo_MG_CFG_CHESS_UI_TICK = 0.15;
Waldo_MG_CFG_POKER_UI_TICK = 0.15;
Waldo_MG_CFG_POKER_STARTING_CHIPS = 100;
Waldo_MG_CFG_POKER_SMALL_BLIND = 1;
Waldo_MG_CFG_POKER_BIG_BLIND = 2;
Waldo_MG_CFG_POKER_UI_SCALE = 1.25;
Waldo_MG_CFG_POKER_UI_CENTER = [0.590, 0.5425];
Waldo_MG_CFG_UNO_UI_TICK = 0.15;
Waldo_MG_CFG_UNO_HAND_PAGE_SIZE = 10;
Waldo_MG_CFG_UNO_STARTING_CARDS = 7;
Waldo_MG_CFG_UNO_CALLOUT_PENALTY = 2;
Waldo_MG_CFG_BATTLESHIP_UI_TICK = 0.15;
Waldo_MG_CFG_BATTLESHIP_GRID_SIZE = 10;
Waldo_MG_CFG_BATTLESHIP_BUTTON_FONT = 0.054;
Waldo_MG_CFG_BATTLESHIP_SHIPS = [
    ["Carrier", 5],
    ["Battleship", 4],
    ["Cruiser", 3],
    ["Submarine", 3],
    ["Destroyer", 2]
];

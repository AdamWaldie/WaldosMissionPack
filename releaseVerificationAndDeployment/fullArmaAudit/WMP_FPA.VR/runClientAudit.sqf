private _suite = missionNamespace getVariable ["Waldo_QA_Suite", "all"];
["client/runtime", {
    ["client/runtime", hasInterface && {!isNull player}, [clientOwner, profileName]] call Waldo_QA_fnc_assert;
}] call Waldo_QA_fnc_case;

if (_suite in ["all", "core"]) then {
    ["core/loading/version-artwork", {
        private _version = missionNamespace getVariable ["Waldo_QA_ExpectedVersion", ""];
        private _screen = "Pictures\loading.jpg";
        ["core/loading/version-artwork", _version != "" && {fileExists _screen}, [_version, _screen]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "interactions"]) then {
    ["interactions/catalogue/ten-procedures", {
        missionNamespace setVariable ["Waldo_MG_ChallengeRegistry", []];
        {
            _x params ["_id", "_opener"];
            [_id, _opener, _id] call Waldo_fnc_MiniGameRegisterChallenge;
        } forEach [
            ["wirecut", Waldo_fnc_MiniGameWireCut], ["minesweeper", Waldo_fnc_MiniGameMinesweeper],
            ["keypad", Waldo_fnc_MiniGameKeypad], ["lockpick", Waldo_fnc_MiniGameLockpick],
            ["circuit", Waldo_fnc_MiniGameCircuit], ["repair", Waldo_fnc_MiniGameRepair],
            ["radiotune", Waldo_fnc_MiniGameRadioTune], ["pressure", Waldo_fnc_MiniGamePressure],
            ["sequence", Waldo_fnc_MiniGameSequence], ["commandinput", Waldo_fnc_MiniGameCommandInput]
        ];
        private _registered = (missionNamespace getVariable ["Waldo_MG_ChallengeRegistry", []]) apply {_x select 0};
        ["interactions/catalogue/ten-procedures", count _registered == 10, _registered] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

private _passed = call Waldo_QA_fnc_complete;
player setVariable ["Waldo_QA_ClientComplete", [_passed, missionNamespace getVariable ["Waldo_QA_LocalResults", []]], true];

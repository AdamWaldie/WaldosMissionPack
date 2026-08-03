/*
 * Author: WaldoTheWarfighter
 * Runs the disposable interaction-equipment QA client. Interactive and Active modes expose real
 * gallery/display controls; Automated mode drives every procedure through its production input
 * functions, validates briefing and active geometry, records outcomes and ends with END1/LOSER.
 *
 * Arguments: None.
 * Return Value: Nothing.
 *
 * Example: engine entry point; do not call directly.
 * Current caller: the generated WMP_Interaction_UI_QA.VR mission.
 */
waitUntil {!isNull player && {!isNull (findDisplay 46)}};
private _mode = toUpper (missionNamespace getVariable ["Waldo_MG_QA_Mode", "INTERACTIVE"]);
private _qaChallenge = toLower (missionNamespace getVariable ["Waldo_MG_QA_Challenge", "wirecut"]);
private _qaDifficulty = toLower (missionNamespace getVariable ["Waldo_MG_QA_Difficulty", "standard"]);
private _allDifficulties = missionNamespace getVariable ["Waldo_MG_QA_AllDifficulties", false];
private _difficultyNames = ["easy", "standard", "hard", "expert"];
private _challengeIds = ["wirecut", "minesweeper", "keypad", "lockpick", "circuit", "repair", "radiotune", "pressure", "sequence", "commandinput"];
if !(_qaDifficulty in _difficultyNames) then {_qaDifficulty = "standard";};
private _entries = [];
{
    private _challengeId = _x;
    if (_allDifficulties) then {
        {
            _entries pushBack [_challengeId, _x, [_challengeId, _x] call Waldo_fnc_MiniGameEquipmentDifficultyConfig];
        } forEach _difficultyNames;
    } else {
        _entries pushBack [_challengeId, _qaDifficulty, [_challengeId, _qaDifficulty] call Waldo_fnc_MiniGameEquipmentDifficultyConfig];
    };
} forEach _challengeIds;

if (_mode in ["INTERACTIVE", "ACTIVE"]) exitWith {
    player addAction ["Open Field Equipment Gallery", {
        [] call Waldo_fnc_MiniGameEquipmentGallery;
    }];
    player addAction ["Validate Active Equipment Display", {
        private _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
        private _findings = [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
        systemChat format ["Interaction UI: %1 finding(s); details written to RPT.", count _findings];
    }];
    hint format ["WMP INTERACTION UI QA\n\nChallenge: %1\nDifficulty: %2\n\nUse the action menu to open the gallery or validate the active display.", toUpper _qaChallenge, toUpper _qaDifficulty];
    uiSleep 0.5;
    if (_mode == "INTERACTIVE") then {
        [_qaChallenge, "BRIEFING"] call Waldo_fnc_MiniGameEquipmentGallery;
    } else {
        private _entryIndex = _entries findIf {(_x select 0) == _qaChallenge && {(_x select 1) == _qaDifficulty}};
        if (_entryIndex < 0) then {_entryIndex = _entries findIf {(_x select 0) == _qaChallenge};};
        private _config = if (_entryIndex >= 0) then {+((_entries select _entryIndex) select 2)} else {[]};
        [_qaChallenge, _config, {}, {}] call Waldo_fnc_MiniGameChallenge;
    };
    waitUntil {uiSleep 0.01; !isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])};
    private _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
    if (_mode == "ACTIVE") then {
        private _begin = _display getVariable ["Waldo_IMG_BriefingBegin", controlNull];
        if (!isNull _begin) then {
            [_begin] call (_display getVariable ["Waldo_IMG_BriefingActivate", {}]);
        };
        uiSleep 0.2;
    };
    diag_log format [
        "WMP INTERACTION UI QA GEOMETRY: safe=%1 bounds=%2 content=%3",
        [safeZoneX, safeZoneY, safeZoneW, safeZoneH],
        _display getVariable ["Waldo_IMG_Bounds", []],
        _display getVariable ["Waldo_MG_UI_Content", []]
    ];
    // Keep external captures clear of the QA hint overlay.
    uiSleep 0.2;
    hintSilent "";
};

private _exerciseProcedure = {
    params ["_challengeId", "_display"];
    switch (_challengeId) do {
        case "wirecut": {
            [_display, _display getVariable ["Waldo_MG_WC_Correct", -1]] call (_display getVariable ["Waldo_MG_WC_Select", {}]);
            [_display] call (_display getVariable ["Waldo_MG_WC_ProbeSelected", {}]);
            [_display] call (_display getVariable ["Waldo_MG_WC_CutSelected", {}]);
        };
        case "minesweeper": {
            [_display, 0] call (_display getVariable ["Waldo_MG_MS_Reveal", {}]);
            waitUntil {uiSleep 0.01; !(_display getVariable ["Waldo_MG_MS_Revealing", false])};
            private _mines = _display getVariable ["Waldo_MG_MS_Mines", []];
            private _cellCount = count (_display getVariable ["Waldo_MG_MS_Buttons", []]);
            for "_index" from 0 to (_cellCount - 1) do {
                if !(_index in _mines) then {
                    waitUntil {uiSleep 0.01; !(_display getVariable ["Waldo_MG_MS_Revealing", false])};
                    if (!(_display getVariable ["Waldo_MG_UI_Done", false])) then {
                        [_display, _index] call (_display getVariable ["Waldo_MG_MS_Reveal", {}]);
                    };
                };
            };
        };
        case "keypad": {
            {[_display, _x] call (_display getVariable ["Waldo_MG_KP_Action", {}]);} forEach (_display getVariable ["Waldo_MG_KP_Code", []]);
            [_display, -1] call (_display getVariable ["Waldo_MG_KP_Action", {}]);
        };
        case "lockpick": {
            private _pinCount = _display getVariable ["Waldo_MG_LP_Pins", 1];
            for "_index" from 1 to _pinCount do {
                private _target = _display getVariable ["Waldo_MG_LP_TensionTarget", 0.5];
                private _tolerance = _display getVariable ["Waldo_MG_LP_TensionTolerance", 0.1];
                while {abs ((_display getVariable ["Waldo_MG_LP_Tension", 0.5]) - _target) > (_tolerance * 0.75)} do {
                    private _current = _display getVariable ["Waldo_MG_LP_Tension", 0.5];
                    [_display, (if (_current < _target) then {0.05} else {-0.05})] call (_display getVariable ["Waldo_MG_LP_AdjustTension", {}]);
                    uiSleep 0.01;
                };
                waitUntil {
                    uiSleep 0.01;
                    private _sweep = _display getVariable ["Waldo_MG_LP_Sweep", 0];
                    private _start = _display getVariable ["Waldo_MG_LP_ZoneStart", 0];
                    private _width = _display getVariable ["Waldo_MG_LP_ZoneWidth", 0.16];
                    _sweep >= (_start + (_width * 0.2)) && {_sweep <= (_start + (_width * 0.8))}
                };
                [_display] call (_display getVariable ["Waldo_MG_LP_SetPin", {}]);
            };
        };
        case "circuit": {
            private _left = _display getVariable ["Waldo_MG_CR_LeftBtns", []];
            private _right = _display getVariable ["Waldo_MG_CR_RightBtns", []];
            for "_identity" from 0 to ((count _left) - 1) do {
                [_left select _identity] call (_display getVariable ["Waldo_MG_CR_Select", {}]);
                private _rightIndex = _right findIf {(_x getVariable ["Waldo_MG_CR_IdentityIndex", -1]) == _identity};
                if (_rightIndex >= 0) then {[_right select _rightIndex] call (_display getVariable ["Waldo_MG_CR_Select", {}]);};
            };
        };
        case "repair": {
            private _targets = _display getVariable ["Waldo_MG_RP_Targets", []];
            {
                [_display, _forEachIndex] call (_display getVariable ["Waldo_MG_RP_SelectBolt", {}]);
                private _current = _display getVariable ["Waldo_MG_RP_Setting", 30];
                [_display, _x - _current] call (_display getVariable ["Waldo_MG_RP_Adjust", {}]);
                [_display] call (_display getVariable ["Waldo_MG_RP_Apply", {}]);
            } forEach _targets;
        };
        case "radiotune": {
            private _channels = _display getVariable ["Waldo_MG_RT_Channels", 1];
            for "_channel" from 1 to _channels do {
                private _target = _display getVariable ["Waldo_MG_RT_Target", 0.5];
                private _tolerance = _display getVariable ["Waldo_MG_RT_Tolerance", 0.05];
                while {abs ((_display getVariable ["Waldo_MG_RT_Value", 0.5]) - _target) > (_tolerance * 0.5)} do {
                    private _current = _display getVariable ["Waldo_MG_RT_Value", 0.5];
                    [_display, (if (_current < _target) then {0.01} else {-0.01})] call (_display getVariable ["Waldo_MG_RT_Adjust", {}]);
                    uiSleep 0.01;
                };
                waitUntil {uiSleep 0.02; (_display getVariable ["Waldo_MG_UI_Done", false]) || {(_display getVariable ["Waldo_MG_RT_Channel", 1]) > _channel}};
            };
        };
        case "pressure": {
            // Solve through the same coupled adjustment function used by mouse and keyboard input.
            private _targets = _display getVariable ["Waldo_MG_PR_Targets", []];
            private _band = _display getVariable ["Waldo_MG_PR_Band", 0.1];
            for "_iteration" from 0 to 399 do {
                private _values = _display getVariable ["Waldo_MG_PR_Values", []];
                private _allSafe = true;
                private _bestIndex = 0;
                private _bestGradient = 0;
                for "_index" from 0 to ((count _values) - 1) do {
                    private _error = (_targets select _index) - (_values select _index);
                    if (abs _error > (_band * 0.75)) then {_allSafe = false;};
                    private _gradient = _error;
                    if (_index > 0) then {_gradient = _gradient - (0.18 * ((_targets select (_index - 1)) - (_values select (_index - 1))));};
                    if (_index < ((count _values) - 1)) then {_gradient = _gradient - (0.18 * ((_targets select (_index + 1)) - (_values select (_index + 1))));};
                    if (abs _gradient > abs _bestGradient) then {_bestGradient = _gradient; _bestIndex = _index;};
                };
                if (_allSafe) exitWith {};
                private _delta = ((_bestGradient * 0.5) max -0.04) min 0.04;
                [_display, _bestIndex, _delta] call (_display getVariable ["Waldo_MG_PR_Adjust", {}]);
                uiSleep 0.005;
            };
        };
        case "sequence": {
            private _replayExercised = false;
            while {!(_display getVariable ["Waldo_MG_UI_Done", false])} do {
                waitUntil {uiSleep 0.02; (_display getVariable ["Waldo_MG_UI_Done", false]) || {_display getVariable ["Waldo_MG_SQ_AcceptInput", false]}};
                if (!(_display getVariable ["Waldo_MG_UI_Done", false])) then {
                    if (!_replayExercised) then {
                        [_display] call (_display getVariable ["Waldo_MG_SQ_Replay", {}]);
                        _replayExercised = true;
                        waitUntil {
                            uiSleep 0.02;
                            (_display getVariable ["Waldo_MG_UI_Done", false]) ||
                            {_display getVariable ["Waldo_MG_SQ_AcceptInput", false]}
                        };
                    };
                    {[_display, _x] call (_display getVariable ["Waldo_MG_SQ_Activate", {}]); uiSleep 0.02;} forEach +(_display getVariable ["Waldo_MG_SQ_Sequence", []]);
                };
            };
        };
        case "commandinput": {
            while {!(_display getVariable ["Waldo_MG_UI_Done", false])} do {
                waitUntil {
                    uiSleep 0.02;
                    (_display getVariable ["Waldo_MG_UI_Done", false]) ||
                    {_display getVariable ["Waldo_MG_CI_AcceptInput", false]}
                };
                if (!(_display getVariable ["Waldo_MG_UI_Done", false])) then {
                    while {
                        !(_display getVariable ["Waldo_MG_UI_Done", false]) &&
                        {_display getVariable ["Waldo_MG_CI_AcceptInput", false]}
                    } do {
                        private _packet = _display getVariable ["Waldo_MG_CI_Packet", []];
                        private _inputIndex = _display getVariable ["Waldo_MG_CI_InputIndex", 0];
                        if (_inputIndex < count _packet) then {
                            [_display, _packet select _inputIndex] call (_display getVariable ["Waldo_MG_CI_Activate", {}]);
                        };
                        uiSleep 0.02;
                    };
                };
            };
        };
    };
};

[_entries, _exerciseProcedure] spawn {
    params ["_entries", "_exerciseProcedure"];
    private _allFindings = [];
    {
        _x params ["_challengeId", "_difficulty", "_config"];
        private _caseId = format ["%1/%2", _challengeId, _difficulty];
        diag_log format ["WMP INTERACTION UI QA CASE: %1 config=%2", _caseId, _config];
        missionNamespace setVariable ["Waldo_MG_QA_Resolved", false];
        missionNamespace setVariable ["Waldo_MG_QA_Result", false];
        missionNamespace setVariable ["Waldo_MG_QA_Outcome", []];
        private _opened = [
            _challengeId,
            _config,
            {missionNamespace setVariable ["Waldo_MG_QA_Outcome", _this]; missionNamespace setVariable ["Waldo_MG_QA_Result", true]; missionNamespace setVariable ["Waldo_MG_QA_Resolved", true];},
            {missionNamespace setVariable ["Waldo_MG_QA_Outcome", _this]; missionNamespace setVariable ["Waldo_MG_QA_Result", false]; missionNamespace setVariable ["Waldo_MG_QA_Resolved", true];}
        ] call Waldo_fnc_MiniGameChallenge;
        if (!_opened) then {
            _allFindings pushBack [_caseId, "ERROR", "OPEN_FAILED"];
        } else {
            waitUntil {
                uiSleep 0.01;
                !isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])
            };
            private _display = uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull];
            private _briefingFindings = [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
            {_allFindings pushBack [_caseId, "BRIEFING", _x];} forEach _briefingFindings;
            private _begin = _display getVariable ["Waldo_IMG_BriefingBegin", controlNull];
            if (isNull _begin) then {
                _allFindings pushBack [_caseId, "ERROR", "BEGIN_CONTROL_MISSING"];
            } else {
                [_begin] call (_display getVariable ["Waldo_IMG_BriefingActivate", {}]);
                uiSleep 0.2;
                if !(_display getVariable ["Waldo_IMG_Started", false]) then {
                    _allFindings pushBack [_caseId, "ERROR", "ACTIVATION_TRANSITION_FAILED"];
                };
                private _activeFindings = [_display, true] call Waldo_fnc_MiniGameEquipmentValidateDisplay;
                {_allFindings pushBack [_caseId, "ACTIVE", _x];} forEach _activeFindings;
                private _mechanicsWorker = [_challengeId, _display, _exerciseProcedure] spawn {
                    params ["_challengeId", "_display", "_exerciseProcedure"];
                    [_challengeId, _display] call _exerciseProcedure;
                };
                _display setVariable ["Waldo_MG_QA_MechanicsWorker", _mechanicsWorker];
            };
            private _deadline = time + 60;
            waitUntil {uiSleep 0.02; missionNamespace getVariable ["Waldo_MG_QA_Resolved", false] || {time > _deadline}};
            if !(missionNamespace getVariable ["Waldo_MG_QA_Resolved", false]) then {
                _allFindings pushBack [_caseId, "MECHANICS", "RESOLUTION_TIMEOUT"];
                terminate (_display getVariable ["Waldo_MG_QA_MechanicsWorker", scriptNull]);
                if (!isNull _display && {!(_display getVariable ["Waldo_MG_UI_Done", false])}) then {
                    [_display, false, "[X] QA MECHANICS TIMEOUT"] call (_display getVariable ["Waldo_MG_UI_Finish", {}]);
                };
            } else {
                if !(missionNamespace getVariable ["Waldo_MG_QA_Result", false]) then {
                    _allFindings pushBack [_caseId, "MECHANICS", "EXPECTED_SUCCESS_GOT_FAILURE"];
                    diag_log format ["WMP INTERACTION UI QA FAILURE OUTCOME: %1 %2", _caseId, missionNamespace getVariable ["Waldo_MG_QA_Outcome", []]];
                };
            };
        };
        // A successful procedure deliberately leaves its result face visible briefly.
        // Wait for the real cleanup path before opening the next case so the production
        // single-display guard is tested rather than bypassed.
        private _cleanupDeadline = time + 10;
        waitUntil {
            uiSleep 0.02;
            isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])
            || {time > _cleanupDeadline}
        };
        if !(isNull (uiNamespace getVariable ["Waldo_MG_ActiveChallengeDisplay", displayNull])) then {
            _allFindings pushBack [_caseId, "CLEANUP", "DISPLAY_CLOSE_TIMEOUT"];
        };
        uiSleep 0.1;
    } forEach _entries;
    diag_log format ["WMP INTERACTION UI QA COMPLETE: %1 finding(s) %2", count _allFindings, _allFindings];
    uiSleep 0.25;
    if (count _allFindings == 0) then {endMission "END1";} else {endMission "LOSER";};
};

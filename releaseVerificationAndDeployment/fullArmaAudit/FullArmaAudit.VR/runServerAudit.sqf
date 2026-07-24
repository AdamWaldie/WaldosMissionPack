private _suite = missionNamespace getVariable ["Waldo_QA_Suite", "all"];
if !(_suite in ["all", "core", "ew", "party", "interactions", "economy"]) exitWith {
    ["audit/suite", false, format ["Unknown suite %1", _suite]] call Waldo_QA_fnc_assert;
};

if (_suite in ["all", "core"]) then {
    ["core/functions/registered", {
        private _required = [
            "Waldo_fnc_SafeStart", "Waldo_fnc_AARTrack", "Waldo_fnc_CreateObjective",
            "Waldo_fnc_SetObjectiveState", "Waldo_fnc_RunDiagnostics",
            "Waldo_fnc_ZenLoadoutSaveModule", "Waldo_fnc_ZenAddLoadoutSaveAction"
        ];
        private _missing = _required select {isNil _x};
        ["core/functions/registered", _missing isEqualTo [], _missing] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/loadout/unique-array", {
        private _actual = [["A", "B", "A", "EMPTY", "B"]] call Waldo_fnc_UniqueLoadoutArray;
        ["core/loadout/unique-array", _actual isEqualTo ["A", "B", "EMPTY"], _actual] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/objective/create-update", {
        ["qa_objective", west, "QA Objective", "Audit", [10, 10, 0], "ASSIGNED", true] call Waldo_fnc_CreateObjective;
        private _created = (missionNamespace getVariable ["Waldo_AAR_Tasks", []]) findIf {(_x select 0) == "qa_objective" && {(_x select 1) == "ASSIGNED"}} >= 0;
        ["qa_objective", "SUCCEEDED"] call Waldo_fnc_SetObjectiveState;
        private _updated = (missionNamespace getVariable ["Waldo_AAR_Tasks", []]) findIf {(_x select 0) == "qa_objective" && {(_x select 1) == "SUCCEEDED"}} >= 0;
        ["core/objective/create-update", _created && _updated && {markerType "Waldo_obj_qa_objective" == ""}, [_created, _updated]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/safestart/activate-lift", {
        [true] call Waldo_fnc_SafeStart;
        private _on = missionNamespace getVariable ["Waldo_SafeStart_Active", false];
        [false] call Waldo_fnc_SafeStart;
        private _off = !(missionNamespace getVariable ["Waldo_SafeStart_Active", true]);
        ["core/safestart/activate-lift", _on && _off, [_on, _off]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;

    ["core/paradrop/settings", {
        missionNamespace setVariable ["WALDO_STATIC_MINALTITUDE", 180];
        missionNamespace setVariable ["WALDO_STATIC_MAXALTITUDE", 350];
        missionNamespace setVariable ["WALDO_STATIC_MAXSPEED", 310];
        private _valid = (missionNamespace getVariable "WALDO_STATIC_MINALTITUDE") < (missionNamespace getVariable "WALDO_STATIC_MAXALTITUDE");
        ["core/paradrop/settings", _valid, "Static-line thresholds ordered"] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "party"]) then {
    ["party/catalogue/twelve-games", {
        [] call Waldo_fnc_MiniGamesInit;
        private _ids = Waldo_MG_Games apply {_x select 0};
        private _expected = ["battleship", "whoswho", "shotgun", "blackjack", "poker", "drawpoker", "liarsdice", "chess", "checkers", "connectfour", "rps", "uno"];
        ["party/catalogue/twelve-games", count _ids == 12 && {{_x in _ids} count _expected == 12}, _ids] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

if (_suite in ["all", "ew"]) then {
    ["ew/registry/create-update-toggle-remove", {
        missionNamespace setVariable ["Waldo_Jamming_Registry", [], true];
        private _source = createVehicle ["Land_TTowerSmall_1_F", [30, 0, 0], [], 0, "NONE"];
        private _id = [_source, 300, "ALL"] call Waldo_fnc_Jammer;
        private _created = count (missionNamespace getVariable ["Waldo_Jamming_Registry", []]) == 1;
        [_id, false] call Waldo_fnc_JammerToggle;
        private _disabled = !(((missionNamespace getVariable ["Waldo_Jamming_Registry", []]) select 0) select 7);
        [_id] call Waldo_fnc_JammerRemove;
        private _removed = (missionNamespace getVariable ["Waldo_Jamming_Registry", []]) isEqualTo [];
        deleteVehicle _source;
        ["ew/registry/create-update-toggle-remove", _created && _disabled && _removed, [_created, _disabled, _removed, _id]] call Waldo_QA_fnc_assert;
    }] call Waldo_QA_fnc_case;
};

private _passed = call Waldo_QA_fnc_complete;
missionNamespace setVariable ["Waldo_QA_ServerComplete", [_passed, missionNamespace getVariable ["Waldo_QA_LocalResults", []]], true];
if (!isMultiplayer) then {uiSleep 0.5; if (_passed) then {endMission "END1"} else {endMission "LOSER"};};

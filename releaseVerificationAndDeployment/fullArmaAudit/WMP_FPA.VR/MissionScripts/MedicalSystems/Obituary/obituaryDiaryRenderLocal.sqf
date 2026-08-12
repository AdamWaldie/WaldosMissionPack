/*
 * Author: WaldoTheWarfighter
 * Client-local poll loop that keeps an Obituary index plus one diary record per player name in
 * sync with the broadcast Waldo_Obituary_Entries/Version state. This bounds diary-record growth by
 * the number of distinct player names rather than deaths, then combines names beyond 240 into one
 * overflow page so Arma's 256-record diary ceiling cannot be consumed by this feature. Uses the same remove-then-recreate idiom
 * proven by Waldo_fnc_ACRE2BuildCEOI/Waldo_fnc_ACRE2BuildBabelDiary,
 * including surviving Arma replacing the player object on respawn (diary record handles and
 * ownership are tracked locally and recreated under the new player object when it changes).
 * Locality and authority: one instance per client (guarded by Waldo_Obituary_RenderRunning); all
 * state it reads is broadcast/server-authoritative, everything it writes (diary record handle and
 * owner) is local-only, exactly like Waldo_ACRE2_CEOIRecord/Waldo_ACRE2_DiarySubjectOwner.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * [] call Waldo_fnc_ObituaryDiaryRenderLocal;
 * Result: every player's Journal shows an index and one readable death-history page per player.
 * Current caller: Waldo_fnc_ObituaryInit.
 */

if !(hasInterface) exitWith {};
if (missionNamespace getVariable ["Waldo_Obituary_RenderRunning", false]) exitWith {};
missionNamespace setVariable ["Waldo_Obituary_RenderRunning", true];

[] spawn {
    private _lastVersion = -1;

    while {true} do {
        private _version = missionNamespace getVariable ["Waldo_Obituary_Version", 0];
        private _recordOwner = missionNamespace getVariable ["Waldo_Obituary_RecordOwner", objNull];
        private _ownerChanged = _recordOwner != player;

        if (_version > 0 && {_version != _lastVersion || _ownerChanged}) then {
            private _entries = missionNamespace getVariable ["Waldo_Obituary_Entries", []];

            // Diary content remains visible when Arma replaces the player object on respawn.
            // Remove the known record from the current diary first; also ask the previous owner
            // while it still exists - mirrors Waldo_fnc_ACRE2BuildCEOI exactly.
            private _oldRecords = missionNamespace getVariable ["Waldo_Obituary_Records", []];
            private _legacyRecord = missionNamespace getVariable ["Waldo_Obituary_Record", -1];
            if !(isNull _recordOwner) then {
                {
                    player removeDiaryRecord ["Obituary", _x];
                    if (_recordOwner != player) then {_recordOwner removeDiaryRecord ["Obituary", _x]};
                } forEach _oldRecords;
                if (_legacyRecord >= 0) then {
                    player removeDiaryRecord ["Obituary", _legacyRecord];
                    if (_recordOwner != player) then {_recordOwner removeDiaryRecord ["Obituary", _legacyRecord]};
                };
            };

            if ((missionNamespace getVariable ["Waldo_Obituary_DiarySubjectOwner", objNull]) != player) then {
                player createDiarySubject ["Obituary", "Obituary"];
                missionNamespace setVariable ["Waldo_Obituary_DiarySubjectOwner", player];
            };

            private _records = [];
            private _grouped = createHashMap;
            {
                private _entry = _x;
                if (_entry isEqualType "") then {
                    private _legacy = _grouped getOrDefault ["Legacy reports", []];
                    _legacy pushBack ["Unknown", "Unknown", _entry];
                    _grouped set ["Legacy reports", _legacy];
                } else {
                    _entry params ["_entryId", "_victimName", "_assessmentTime", "_assessor", "_timeOfDeath", "_causeText", "_markerName", "_gridRef", "_formatted"];
                    private _deaths = _grouped getOrDefault [_victimName, []];
                    _deaths pushBack [_timeOfDeath, _causeText, _formatted];
                    _grouped set [_victimName, _deaths];
                };
            } forEach _entries;
            private _indexLines = [];
            private _names = keys _grouped;
            _names sort true;
            private _individualPageLimit = 240;
            private _pageNames = _names select [0, _individualPageLimit min count _names];
            {
                private _patient = _x;
                private _deaths = _grouped get _patient;
                private _sections = [];
                {
                    _x params ["_deathTime", "_cause", "_body"];
                    _sections pushBack format ["<t color='#106bb5' size='1.15'>DEATH %1 OF %2</t><br/>%3", _forEachIndex + 1, count _deaths, _body];
                } forEach _deaths;
                _indexLines pushBack format ["%1. %2 - %3 confirmed death%4", _forEachIndex + 1, _patient, count _deaths, if (count _deaths == 1) then {""} else {"s"}];
                _records pushBack (player createDiaryRecord ["Obituary", [format ["%1 (%2)", _patient, count _deaths], _sections joinString "<br/><br/><hr/><br/><br/>"]]);
            } forEach _pageNames;
            if (count _names > _individualPageLimit) then {
                private _overflowNames = _names select [_individualPageLimit];
                private _overflowSections = [];
                {
                    private _patient = _x;
                    private _deaths = _grouped get _patient;
                    _overflowSections pushBack format ["<t color='#106bb5' size='1.15'>%1 - %2 confirmed death%3</t>", _patient, count _deaths, if (count _deaths == 1) then {""} else {"s"}];
                    {
                        _x params ["_deathTime", "_cause", "_body"];
                        _overflowSections pushBack format ["DEATH %1 OF %2<br/>%3", _forEachIndex + 1, count _deaths, _body];
                    } forEach _deaths;
                } forEach _overflowNames;
                _indexLines pushBack format ["Additional personnel - %1 names combined on one overflow page", count _overflowNames];
                _records pushBack (player createDiaryRecord ["Obituary", [format ["Additional Personnel (%1)", count _overflowNames], _overflowSections joinString "<br/><br/><hr/><br/><br/>"]]);
            };
            private _indexText = if (_indexLines isEqualTo []) then {"No deaths have been formally pronounced."} else {_indexLines joinString "<br/>"};
            _records pushBack (player createDiaryRecord ["Obituary", ["Confirmed Deaths - Index", _indexText]]);
            missionNamespace setVariable ["Waldo_Obituary_Records", _records];
            missionNamespace setVariable ["Waldo_Obituary_RecordOwner", player];
            _lastVersion = _version;
        };

        sleep (missionNamespace getVariable ["Waldo_Obituary_DiaryPollInterval", 3]);
    };
};

/*
 * Author: WaldoTheWarfighter
 * Client-local poll loop that keeps exactly ONE "Obituary" diary record in sync with the broadcast
 * Waldo_Obituary_Text/Version state - the fix for the reference script's bug of stacking a new
 * diary record on every pronounce. Uses the same remove-then-recreate idiom already proven in this
 * codebase by Waldo_fnc_ACRE2BuildCEOI/Waldo_fnc_ACRE2BuildBabelDiary for exactly this problem,
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
 * Result: every player's Journal shows one "Obituary" record with the current full report text.
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
            private _text = missionNamespace getVariable ["Waldo_Obituary_Text", ""];

            // Diary content remains visible when Arma replaces the player object on respawn.
            // Remove the known record from the current diary first; also ask the previous owner
            // while it still exists - mirrors Waldo_fnc_ACRE2BuildCEOI exactly.
            private _oldRecord = missionNamespace getVariable ["Waldo_Obituary_Record", -1];
            if !(isNull _recordOwner) then {
                player removeDiaryRecord ["Obituary", _oldRecord];
                if (_recordOwner != player) then {_recordOwner removeDiaryRecord ["Obituary", _oldRecord]};
            };

            if ((missionNamespace getVariable ["Waldo_Obituary_DiarySubjectOwner", objNull]) != player) then {
                player createDiarySubject ["Obituary", "Obituary"];
                missionNamespace setVariable ["Waldo_Obituary_DiarySubjectOwner", player];
            };

            private _record = player createDiaryRecord ["Obituary", ["Confirmed Deaths", _text]];
            missionNamespace setVariable ["Waldo_Obituary_Record", _record];
            missionNamespace setVariable ["Waldo_Obituary_RecordOwner", player];
            _lastVersion = _version;
        };

        sleep (missionNamespace getVariable ["Waldo_Obituary_DiaryPollInterval", 3]);
    };
};

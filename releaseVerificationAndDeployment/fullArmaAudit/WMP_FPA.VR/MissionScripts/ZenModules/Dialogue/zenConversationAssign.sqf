/*
 * Author: WaldoTheWarfighter
 * Lets a curator assign an already registered Advanced Conversation by friendly ID. It requests a
 * fresh authoritative catalogue before opening the selector instead of trusting public-variable
 * arrival order.
 * Locality/authority: curator client; server authenticates the catalogue and assignment requests.
 * Repeat/JIP behaviour: tokened request/reply works for JIP and late registrations; assignment
 * replaces the selected speaker/group snapshot entry.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: Nothing.
 * Current caller: ZEN "Conversation: Assign". Example: place directly on an NPC.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (isNull _target || {!(_target isKindOf "CAManBase")}) exitWith {["CONVERSATION", "Place this module directly on an NPC.", "WARNING", "CONVERSATION_ZEN", 6] call Waldo_fnc_FeatureNotifyLocal};
private _token = format ["ASSIGN_%1_%2", clientOwner, floor (diag_tickTime * 1000)];
missionNamespace setVariable ["Waldo_Conversation_PendingCatalogToken", _token];
missionNamespace setVariable ["Waldo_Conversation_CatalogResponse", []];
[player, _token] remoteExecCall ["Waldo_fnc_ZenConversationCatalogServer", 2];
[_target, _token] spawn {
    params ["_target", "_token"];
    private _deadline = diag_tickTime + 8;
    waitUntil {
        uiSleep 0.05;
        private _response = missionNamespace getVariable ["Waldo_Conversation_CatalogResponse", []];
        (count _response == 3 && {_response param [0, ""] == _token}) || {diag_tickTime >= _deadline}
    };
    if (_token != missionNamespace getVariable ["Waldo_Conversation_PendingCatalogToken", ""]) exitWith {};
    private _response = missionNamespace getVariable ["Waldo_Conversation_CatalogResponse", []];
    if (count _response != 3) exitWith {["CONVERSATION", "The server did not return the conversation catalogue.", "WARNING", "CONVERSATION_ZEN", 7] call Waldo_fnc_FeatureNotifyLocal};
    private _ids = +(_response param [2, []]);
    if (count _ids == 0) exitWith {["CONVERSATION", "No named conversations are registered on the server.", "WARNING", "CONVERSATION_ZEN", 7] call Waldo_fnc_FeatureNotifyLocal};
    [
        "Assign Named Conversation",
        [
            ["COMBO", ["Conversation", "Select a server-registered conversation."], [_ids, _ids, 0], false],
            ["CHECKBOX", ["Apply to entire group", "Assign this conversation to every NPC in the group."], false, false],
            ["CHECKBOX", ["Remove after completion", "Make the assigned conversation one-shot."], false, false]
        ],
        {
            params ["_args", "_saved"];
            _args params ["_id", "_group", "_once"];
            _saved params ["_target"];
            private _values = [["conversationId", _id], ["applyToGroup", _group], ["removeAfterUse", _once]];
            ["ADVANCED_ASSIGN", _target, _values, player] remoteExecCall ["Waldo_fnc_ZenDialogueServer", 2]
        },
        {}, [_target]
    ] call zen_dialog_fnc_create;
};

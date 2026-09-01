/*
 * Author: WaldoTheWarfighter
 * ZEN module handler for the code-free branching Conversation Author. Placement anywhere opens
 * author-only mode; placement on a living NPC retains that target for optional direct assignment.
 * Locality/authority: curator interface only; author submissions route to the authenticated server.
 * Repeat/JIP behaviour: reopening restores mission-session drafts and replaces the prior modal editor.
 * Arguments: module position ARRAY, selected object OBJECT. Return Value: DISPLAY or displayNull.
 * Current caller: ZEN "Conversation: Author".
 * Submission path: the opened editor calls Waldo_fnc_ZenConversationAuthorServer, which validates
 * and delegates safe registration to Waldo_fnc_ConversationCreateData.
 * Example: place in empty space to author for later assignment, or directly on an NPC to apply.
 */
params ["_modulePos", ["_target", objNull, [objNull]]];
if (!isNull _target && {!(_target isKindOf "CAManBase")}) then {
    ["CONVERSATION", "The selected object is not an NPC; opening author-only mode.", "WARNING", "CONVERSATION_AUTHOR", 6] call Waldo_fnc_FeatureNotifyLocal;
    _target = objNull;
};
[_target] call Waldo_fnc_ConversationAuthorOpenLocal

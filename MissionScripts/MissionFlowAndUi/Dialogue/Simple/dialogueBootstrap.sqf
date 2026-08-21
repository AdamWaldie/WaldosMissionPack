/*
 * Author: WaldoTheWarfighter
 * Self-bootstraps the dialogue registries and requests the current action snapshot on each player
 * client. This keeps dialogue out of mission init event scripts while remaining JIP-safe.
 * Locality/authority: server creates authoritative registries; interface clients request state.
 * Repeat/JIP behaviour: guarded on every machine; each JIP client receives one ordered snapshot.
 * Arguments: None. Return Value: BOOL. Current caller: CfgFunctions postInit.
 * Example: automatic; mission makers do not call this function.
 */
if (isServer) then {
    if (isNil {missionNamespace getVariable "Waldo_Dialogue_Registry"}) then {
        missionNamespace setVariable ["Waldo_Dialogue_Registry", createHashMap];
    };
    if (isNil {missionNamespace getVariable "Waldo_Conversation_Definitions"}) then {
        missionNamespace setVariable ["Waldo_Conversation_Definitions", createHashMap];
    };
    if (isNil {missionNamespace getVariable "Waldo_Dialogue_StateVersion"}) then {
        missionNamespace setVariable ["Waldo_Dialogue_StateVersion", 0];
    };
    if (isNil {missionNamespace getVariable "Waldo_Dialogue_Archetypes"}) then {
        private _defaults = createHashMapFromArray [
            ["CIVILIAN", ["Hello.", "Can I help you?", "Stay safe out there.", "I have not seen anything unusual."]],
            ["CIVILIAN_FRIENDLY", ["Good to see you.", "Let me know if you need directions.", "Take care of yourself."]],
            ["CIVILIAN_WARY", ["What do you want?", "I do not want any trouble.", "Please keep your distance."]]
        ];
        missionNamespace setVariable ["Waldo_Dialogue_Archetypes", _defaults];
    };
    private _publicIds = keys (missionNamespace getVariable ["Waldo_Dialogue_Archetypes", createHashMap]);
    _publicIds append [
        "DORNOW_CIVILIAN", "DORNOW_GUARD", "DORNOW_SHOPKEEPER", "DORNOW_FARMER",
        "MODERN_CIVILIAN", "MODERN_CIVILIAN_FRIENDLY", "MODERN_CIVILIAN_WARY",
        "MODERN_CIVILIAN_DISPLACED", "MODERN_SHOPKEEPER", "MODERN_RURAL_RESIDENT",
        "MODERN_AID_WORKER", "MODERN_LOCAL_OFFICIAL"
    ];
    missionNamespace setVariable ["Waldo_Dialogue_PublicArchetypeIds", _publicIds arrayIntersect _publicIds, true];
};
if (hasInterface) then {
    [] spawn {
        private _deadline = diag_tickTime + 30;
        waitUntil {uiSleep 0.1; !isNull player || {diag_tickTime >= _deadline}};
        if (!isNull player) then {
            if (isClass (configFile >> "CfgPatches" >> "ace_interact_menu")) then {
                private _aceDeadline = diag_tickTime + 30;
                waitUntil {uiSleep 0.1; !isNil "ace_interact_menu_fnc_createAction" || {diag_tickTime >= _aceDeadline}};
            };
            [player] remoteExecCall ["Waldo_fnc_DialogueRequestStateServer", 2];
        };
    };
};
true

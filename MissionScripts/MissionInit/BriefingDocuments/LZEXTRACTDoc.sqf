/*
 * Author: Waldo
 * Adds the LZ extraction brief checklist to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_LZEXTRACT;
 */

player createDiaryRecord["Checklists",
    ["HELO EXTRACTION CHECKLISTS",
        "
<font color='#addde6' size='20'>                       EXTRACTION CHECKLISTS<br/>
-----------------------------------------------------------------</font><br/><br/>
<font color='#addde6'>ADMIN CHECKLIST</font><br/><br/>
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\extract-admin-checklist.paa' width='367' height='293'/><br/><br/>
<font color='#addde6'>EXTRACT CHECKLIST</font><br/><br/>
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\extract-extract-checklist.paa' width='367' height='264'/>
        "
    ]
];
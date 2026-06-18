/*
 * Author: Waldo
 * Adds the Landing Zone (LZ) specifications checklist to the player's map diary.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * Nothing
 *
 * Example:
 * call Waldo_fnc_LZSPECS;
 */

player createDiaryRecord["Checklists",
    ["LZ/PZ SPECIFICATIONS",
        "
<font color='#addde6' size='20'>                        LZ / PZ SPECIFICATIONS<br/>
-----------------------------------------------------------------</font><br/><br/>
<font color='#addde6'>LANDING POINT SPECIFICATIONS</font><br/><br/>
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\LPSIZES.paa' width='367' height='166'/><br/><br/>
<font color='#addde6'>LZ / PZ TYPES</font><br/><br/>
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\LZTYPES.paa' width='367' height='338'/><br/><br/>
<font color='#addde6'>LZ / PZ MARKINGS</font><br/><br/>
<img image='MissionScripts\MissionInit\BriefingDocuments\BriefImages\LZ-MAP-MARKINGS.paa' width='367' height='245'/>
        "
    ]
];
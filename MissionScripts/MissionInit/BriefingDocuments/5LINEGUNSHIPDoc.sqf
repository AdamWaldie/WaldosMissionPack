/*
 * Author: WaldoTheWarfighter
 * Adds a readable five-line gunship support brief to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_FIVELINEGUNSHIP;
 */

player createDiaryRecord ["Support Calls", ["5-Line Gunship Support", "
<font color='#addde6' size='20'>5-LINE GUNSHIP SUPPORT</font><br/>
<font color='#a9a9a9'>Rotary-wing close air support quick reference</font><br/><br/>
<font color='#addde6' size='16'>1. WARNING ORDER</font><br/>
Identify the observer and aircraft.<br/>
<font color='#d8f2f7'>Example:</font> 'Aircraft callsign, this is observer callsign: CCA mission, over.'<br/>
Aircraft replies: 'Ready to copy.'<br/><br/>
<font color='#addde6' size='16'>2. OBSERVER POSITION</font><br/>
• Observer grid or latitude/longitude: 'My position ...'<br/>
• Position description, when needed.<br/>
• Observer mark: 'Marked by ...'<br/><br/>
<font color='#addde6' size='16'>3. TARGET LOCATION</font><br/>
• Grid, latitude/longitude, or bearing and distance from observer.<br/>
• Target elevation, preferably feet above mean sea level. Always state the unit.<br/><br/>
<font color='#addde6' size='16'>4. TARGET DESCRIPTION</font><br/>
• Target type, number and activity: 'Target is ...'<br/>
• Target mark: 'Marked by ...'<br/><br/>
<font color='#addde6' size='16'>5. REMARKS</font><br/>
• Weapon requested: 'Engage with ...'<br/>
• Attack heading in degrees.<br/>
• Nearest friendly or civilian position. If appropriate: 'I am nearest friendly troops.'<br/>
• State 'Cleared danger close' when authorised.<br/>
• Restrictions and threats.<br/>
• Control: 'At my command' or a time on target.<br/><br/>
<font color='#f0c674'>Finish by requesting a full read-back.</font>
"]];

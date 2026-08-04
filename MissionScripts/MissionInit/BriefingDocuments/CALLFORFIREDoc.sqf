/*
 * Author: WaldoTheWarfighter
 * Adds the call-for-fire sequence and radio notes to the player's map diary.
 * This client-only function is called by Waldo_fnc_AddDocs during player setup.
 *
 * Arguments: None
 * Return Value: Nothing
 *
 * Example:
 * call Waldo_fnc_CALLFORFIRE;
 */

player createDiaryRecord ["Support Calls", ["Call for Fire", "
<font color='#addde6' size='20'>CALL FOR FIRE</font><br/><br/>
<font color='#d8f2f7'>1. INITIATION</font><br/>
'You, this is me. Request fire mission, over.'<br/><br/>
<font color='#d8f2f7'>2. WARNING ORDER</font><br/>
Choose <font color='#f0c674'>Adjust Fire</font> to walk rounds onto target, or <font color='#f0c674'>Fire for Effect</font> to engage directly. In Arma, use <font color='#f0c674'>GRID</font> as the target-location method.<br/><br/>
<font color='#d8f2f7'>3. TARGET LOCATION</font><br/>
• Grid: minimum eight figures; ten figures reduce positional error.<br/>
• Altitude in metres. Say 'altitude', not 'elevation.'<br/>
• Direction from observer to target, expressed in mils.<br/><br/>
<font color='#d8f2f7'>4. TARGET DESCRIPTION</font><br/>
Use size, activity, location and type. Describe area shape and radius, length or width where useful.<br/><br/>
<font color='#d8f2f7'>5. METHOD OF ENGAGEMENT</font><br/>
Request ammunition type and number of rounds. Declare <font color='#f0c674'>DANGER CLOSE</font> when applicable. Omit this section if fire direction control should choose the engagement.<br/><br/>
<font color='#d8f2f7'>6. FIRE AND CONTROL</font><br/>
• <font color='#f0c674'>When ready</font> — fire immediately; this is the default.<br/>
• <font color='#f0c674'>At my command</font> — wait for the observer's order.<br/>
• <font color='#f0c674'>Time on target</font> — rounds impact at the stated time.<br/>
• <font color='#f0c674'>Cannot observe</font> — no adjustment will be provided.<br/>
• <font color='#f0c674'>Repeat</font> — repeat the last mission with the same ammunition and guns.<br/><br/>
<font color='#addde6'>RADIO NOTES</font><br/>
Most indirect fire is danger close within 300 metres. After contact is established, callsigns may be omitted until the mission ends. Adjustments are relative to the direction supplied. Use the mission designator when repeating a specific mission.
"]];

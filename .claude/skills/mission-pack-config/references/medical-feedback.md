# Patient treatment feedback

Local ACE treatment start/completion/interruption notifications using the
WMP notification UI. "Automatic" pattern once enabled; requires ACE
medical. ACE emits these events locally to the treating unit, so the
feature securely forwards patient feedback to the patient's own owning
machine — self-treatment stays local.

## Config (`MissionConfig\interfaceConfig.sqf` — player local)

```sqf
["Waldo_TreatmentFeedback_Enable", false],
["Waldo_TreatmentFeedback_ShowStart", true], ["Waldo_TreatmentFeedback_ShowSuccess", true], ["Waldo_TreatmentFeedback_ShowFailure", true],
["Waldo_TreatmentFeedback_NotifyPatient", true],   // patient sees their own copy
["Waldo_TreatmentFeedback_NotifyMedic", false],    // giver also sees a copy
["Waldo_TreatmentFeedback_ShowMedicName", true], ["Waldo_TreatmentFeedback_ShowBodyPart", true],
["Waldo_TreatmentFeedback_StartTitle", "TREATMENT STARTED"],
["Waldo_TreatmentFeedback_SuccessTitle", "TREATMENT COMPLETE"],
["Waldo_TreatmentFeedback_FailureTitle", "TREATMENT FAILED"],
["Waldo_TreatmentFeedback_Duration", 3],            // seconds after the event, not the treatment action duration
["Waldo_TreatmentFeedback_TreatmentNames", createHashMap],  // treatment classname -> display-name overrides
["Waldo_TreatmentFeedback_BodyPartNames", createHashMapFromArray [ /* ACE body-part ID -> label */ ]]
```

## Start/stop

```sqf
[] call Waldo_fnc_TreatmentFeedbackInit;
[] call Waldo_fnc_TreatmentFeedbackStop;
```

Call these on interface clients after changing the player-local settings.
Intentionally **no ZEN module**.

## Gotchas

- Treatment cards replace one another in a dedicated padded bottom-centre
  region — they never consume the general notification stacks.
- Success is heard on **both** `ace_treatmentSucceded` (ACE's current typo'd
  spelling) and `ace_treatmentSucceeded` (the corrected spelling), so the
  feature keeps working unchanged whichever one a given mission's ACE build
  actually fires — don't remove either registration.

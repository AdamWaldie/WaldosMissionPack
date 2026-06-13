_Associated Files: MissionScripts\MissionInit\BriefingDocuments\_

As of WMP v4.7.0 the pack provides an extensive set of in-game documentation, quick-reference templates, and checklists accessible from the player's map screen briefing tab. All documents are automatically populated by `Waldo_fnc_AddDocs`, which is called from `init.sqf`.

---

## What Is Provided

### Radio Reports
| Document | Function |
|---|---|
| SITREP (Situation Report) | `Waldo_fnc_SITREP` |
| SPOTREP (Spot Report) | `Waldo_fnc_SPOTREP` |
| LACE/ACE Report | `Waldo_fnc_ACEREP` |
| Helicopter Pickup Request | `Waldo_fnc_ROTARYPICKUPREQUEST` |
| LZ Briefing | `Waldo_fnc_LZBRIEF` |

### Support Calls
| Document | Function |
|---|---|
| 5-Line Special Operations Gunship Call | `Waldo_fnc_FIVELINEGUNSHIP` |
| 9-Line CAS/ECAS Request | `Waldo_fnc_NINELINE` |
| IDF Call For Fire | `Waldo_fnc_CALLFORFIRE` |
| CAS Check-In Template | `Waldo_fnc_CASCHECKIN` |

### Checklists
| Document | Function |
|---|---|
| Squad Preparation Checklist | `Waldo_fnc_SQUADPREDOC` |
| Fireteam Preparation Checklist | `Waldo_fnc_FIRETEAMPREPDOC` |
| Fire Commands Reminder | `Waldo_fnc_FIRECOMMANDS` |
| Jump Master Checklist | `Waldo_fnc_JUMPMASTER` |
| LZ Specifications | `Waldo_fnc_LZSPECS` |
| LZ Insert Checklist | `Waldo_fnc_LZINSERT` |
| LZ Extract Checklist | `Waldo_fnc_LZEXTRACT` |

### General Information
| Document | Function |
|---|---|
| General Mission & Player Info | `Waldo_fnc_GENINFO` |

---

## Setup

Documents are loaded automatically. The call in `init.sqf` looks like this:

```sqf
call Waldo_fnc_AddDocs;
```

All documents are added to the player's **map screen briefing diary** (the `Diary` tab when opening the map). Each document is a separate entry.

---

## Enabling or Disabling Individual Documents

All individual document functions are called from `AddDocs.sqf`. To remove a document from the briefing, open `MissionScripts\MissionInit\BriefingDocuments\AddDocs.sqf` and comment out the corresponding function call.

For example, to remove the SITREP template:

```sqf
// [] call Waldo_fnc_SITREP;   // commented out — no longer shown to players
```

---

## Adding Custom Briefing Documents

To add a custom briefing document, create a new `.sqf` file in `BriefingDocuments\` using the existing files as a template. Each file uses `player createDiaryRecord` to add a titled entry to the map diary. Then call your new function from `AddDocs.sqf`.

Example of the basic pattern:

```sqf
player createDiaryRecord ["Diary", ["My Document Title", "Content goes here.<br/>More text on next line."]];
```

Documents support HTML-style tags for formatting: `<br/>` for line breaks, `<b>` for bold, `<u>` for underline, and image references via `<img image='path\to\image.paa'/>`.

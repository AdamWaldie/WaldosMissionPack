# Improved AI Helicopter Landings

> **Use this page when:** migrating a mission that previously enabled WMP's improved AI landing controller.

> **Migration notice:** AI landing control moved to the standalone [Waldos AI Tweaks](https://github.com/AdamWaldie/WaldosAITweaks) mod. WMP transport and paradrop retain their mission workflows and use native engine flight commands.

Existing missions should remove WMP-specific calls for this feature and configure the addon instead.

| Previous WMP interface | Type | Current status |
| --- | --- | --- |
| Improved landing setting or script call | Removed controller | WMP transport uses native `land "LAND"`; use Waldos AI Tweaks for enhanced landing control. |

<!-- WMP-WIKI-NAV -->
---
[Wiki home](Home) · [Quickstart](Quickstart-Guide) · [Feature index](Feature-Tutorials)

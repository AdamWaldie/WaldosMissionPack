# Cortex performance acceptance

The target is at least 100 AI groups without significant added cost versus the same mission with Cortex disabled. This remains unverified.

## Workloads

- Measure 25, 50, 100 and 150 groups, with six real AI per group; record actual unit and group counts. The primary target therefore includes 600 AI, not 100 single-soldier groups.
- Use idle, ordinary patrol and sustained contact workloads. Preserve the same composition, placement, route geometry, visibility, skill, feature configuration and ownership for paired runs.
- Use fresh actors for each arm; warm up before sampling. Run OFF/ON/ON/OFF to expose order and warm-up effects, with at least three repeats before acceptance.
- Exercise server ownership, WMP HC distribution and ACE HC distribution separately. Record all owners and hardware. Local server/client/HC processes sharing one machine do not establish dedicated-host capacity.
- Include near and far groups, mixed distances, and feature combinations. Passing by disabling the features under test is not acceptance.

## Measurements

Record median, p95 and p99 frame times separately on the server and each HC; client rendering is a separate result. Also record maximum job duration, scheduler overrun, overdue-job age, discovery time, network state publication rate and physical response latency. Capture settings, counts and ownership alongside the results. Fewer ticks or frozen AI cannot count as a performance improvement.

The user-confirmed overhead budget is no more than 5% median and 10% p95 added frame time, with no stalled AI jobs at 100 or more groups. Report absolute milliseconds as well as percentages. Do not call this an achieved guarantee or silently loosen it after a failure.

## Current evidence and implementation constraints

The existing twelve-group scheduler fixture demonstrates cheap queued movement and retirement only. Its actors have one soldier each and are excluded from normal Cortex discovery. It does not benchmark a hundred active Cortex groups.

The scheduler has a soft budget between jobs. One running job can exceed that budget, and queue traversal still scales with the queue length. Large jobs and repeated group/world scans therefore need measured limits; the configured millisecond budget alone is not proof of bounded frame cost.

The server patrol pilot is implemented in `runPerformance.sqf`, available through `-CortexFocus performance`. It creates 100 six-soldier groups for each OFF/ON/ON/OFF arm, warms up, then samples 60 seconds of server frame times. Every group must physically move; enabled arms require all 100 groups to remain managed and eligible. It checks baseline drift, the agreed median/p95 limits and a separate overdue-job bound. The first server pilot, runtime-20260927-085848, completed its performance stages with all 13 checks passing: OFF samples were 21 ms median / 24 ms p95; ON samples were 21/25 and 21/24 ms. Every group moved and all enabled groups remained managed and eligible. Maximum observed job overdue age was 6.511 seconds. This is one patrol run, not acceptance for contact latency, repeated trials, other scales or HC workloads.

The remaining scale matrix, repeated trials, contact workloads and per-owner collection remain to be implemented and run. Keep existing physical behaviour tests and add performance coverage alongside them.

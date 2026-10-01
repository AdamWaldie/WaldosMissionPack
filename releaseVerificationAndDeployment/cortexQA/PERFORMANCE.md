# Cortex performance acceptance

The primary target is 50 AI groups without significant added cost versus the same mission with Cortex disabled. The earlier 100-group workload saturated the local multi-process Arma host before a valid comparison and remains an exploratory stress point.

## Workloads

- Measure 25 and 50 groups with six real AI per infantry group; retain 100 and 150 as exploratory stress points. Record actual unit and group counts.
- Run both a 50-squad infantry matrix and a 50-group mixed matrix containing infantry, ground vehicles, helicopters and jets.
- Use idle, ordinary patrol and sustained contact workloads. Preserve the same composition, placement, route geometry, visibility, skill, feature configuration and ownership for paired runs.
- Use fresh actors for each arm; warm up before sampling. Run OFF/ON/ON/OFF to expose order and warm-up effects, with at least three repeats before acceptance.
- Exercise server ownership, WMP HC distribution and ACE HC distribution separately. Record all owners and hardware. Local server/client/HC processes sharing one machine do not establish dedicated-host capacity.
- Include near and far groups, mixed distances, and feature combinations. Passing by disabling the features under test is not acceptance.

## Measurements

Record median, p95 and p99 frame times separately on the server and each HC; client rendering is a separate result. Also record maximum job duration, scheduler overrun, overdue-job age, discovery time, network state publication rate and physical response latency. Capture settings, counts and ownership alongside the results. Fewer ticks or frozen AI cannot count as a performance improvement.

The user-confirmed overhead budget is no more than 5% median and 10% p95 added frame time, with no stalled AI jobs at the 50-group primary target. Report absolute milliseconds as well as percentages. Do not call this an achieved guarantee or silently loosen it after a failure.

## Current evidence and implementation constraints

The existing twelve-group scheduler fixture demonstrates cheap queued movement and retirement only. Its actors have one soldier each and are excluded from normal Cortex discovery. It does not benchmark a hundred active Cortex groups.

The scheduler has a soft budget between jobs. One running job can exceed that budget. While every queued job is waiting, the scheduler uses a cached earliest deadline and returns without traversing the queue; WMP diagnostics compares that cache with the real earliest queued job and reports a consistency error if the cache could delay work. Due work now gets an opportunity every frame. This removes the earlier four-heavy-jobs-per-second ceiling while preserving the idle fast path and per-frame budget. Due-job processing still traverses the queue, so large jobs and repeated group/world scans need measured limits; the configured millisecond budget and idle fast path are not proof of bounded frame cost.

The server patrol pilot is implemented in `runPerformance.sqf`, available through `-CortexFocus performance`. It creates 100 six-soldier groups for each OFF/ON/ON/OFF arm, warms up, then samples 60 seconds of server frame times. Every group must physically move; enabled arms require all 100 groups to remain managed and eligible. It checks baseline drift, the agreed median/p95 limits and a separate overdue-job bound. The first server pilot, runtime-20260927-085848, completed its performance stages with all 13 checks passing: OFF samples were 21 ms median / 24 ms p95; ON samples were 21/25 and 21/24 ms. Every group moved and all enabled groups remained managed and eligible. Maximum observed job overdue age was 6.511 seconds. This is one patrol run, not acceptance for contact latency, repeated trials, other scales or HC workloads.

The distributed contact arm is implemented in `runPerformanceContact.sqf` and selected with
`-CortexFocus performancecontact -HeadlessClients 2`. It uses matched OFF/ON/ON/OFF arms with 50
six-soldier manoeuvre groups divided across the server and both WMP headless owners. Thirteen
interleaved groups receive real, stationary, invulnerable contacts while 37 execute matched movement.
Every arm must retain its measured owner load, move at least 45 groups, consume live rifle ammunition
in at least eight contact groups and bring at least ten contact groups into a physical response.
`-CortexFocus performancemixed -HeadlessClients 2` applies the same comparison to 30 infantry squads,
ten ground vehicles, six helicopters and four jets; ten infantry squads receive real contacts.
The sampler reports median, p95 and p99 frame time plus
maximum overdue-job age for the server, both HCs and the rendered client. Each enabled arm is compared
with the two matched disabled baselines using the confirmed 5% median and 10% p95 budgets.

Runtime `runtime-20261001-111812` deliberately failed closed. Its original 100-simultaneous-contact
fixture fell from a user-observed 14 FPS to 8 FPS, so none of its arms met the 90 moving / 60 firing
comparability gate. Native arms moved 63 and 68 groups and fired 40 and 44; Cortex arms moved 61 and
53 and fired 48 and 35. Cortex arms also exposed 5.7-13.0 seconds of overdue work while native arms
reported zero. The run is evidence of both fixture saturation and a scheduler throughput defect; it
is not a performance-budget pass. The controlled-contact fixture and per-frame scheduler require a
fresh paired run without LAMBS (vanilla versus Cortex) and with LAMBS (LAMBS versus SPLIT mode).

Runtime `runtime-20261001-114026` completed the first controlled-contact OFF/ON/ON/OFF matrix at
3840x2160. The scheduler correction reduced maximum overdue work from 5.7-13.0 seconds to 0-2.235
seconds. Native server samples were 23/30 and 23/30 ms median/p95; Cortex samples were 31/44 and
34/46 ms, so the observed server overhead remains outside the agreed budget. Both HCs stayed much
closer: native 20-21/26-28 ms and Cortex 22/29-30 ms. The run did not reach comparability because the
fixture created movement waypoints before its 20-second warm-up and then measured only subsequent
travel, while its firing count inspected squad leaders rather than all six soldiers. The saved audit
now starts owner-local work only after baselines are captured and records the first real FiredMan
event from any group member. A fresh run is required; no percentage pass is claimed from this matrix.

Runtime `runtime-20261001-115539` exercised the corrected physical workload: 99 of 100 groups moved,
18 of 25 contact groups produced real fire and the first observed response took 29.552 seconds. One
headless client then suffered an Arma engine access violation during the first arm, migrating its 33
groups back to the server and invalidating the comparison. The audit now paces initial ownership
transfers, verifies both expected headless clients before and after every arm, and refuses to publish
a matrix unless all four arms finish with their original owners alive.

Runtime `runtime-20261001-120528` completed all four arms but found a softer owner failure. Headless
client 2 remained connected while its simulation stopped advancing after the first simultaneous
activation burst. Its sampler never returned, its 33 groups did not move, and the later arms reached
only 65-67 moving groups. No native/Cortex comparison is valid from this run. The rebuilt fixture
now staggers owner-local path requests across frames, publishes an owner heartbeat, fails a
connected-but-unresponsive owner explicitly and cancels the remaining arms after that loss.

The 25/50/150 scale points, ACE HC distribution, repeated hardware runs and publication-rate
measurement remain outstanding. Keep existing physical behaviour tests and add performance coverage
alongside them.

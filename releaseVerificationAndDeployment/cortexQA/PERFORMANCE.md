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

The scheduler has a soft budget between jobs. One running job can exceed that budget. While every queued job is waiting, the scheduler now uses a cached earliest deadline and returns without traversing the queue; WMP diagnostics compares that cache with the real earliest queued job and reports a consistency error if the cache could delay work. Due-job processing still traverses the queue, so large jobs and repeated group/world scans need measured limits; the configured millisecond budget and idle fast path are not proof of bounded frame cost.

The server patrol pilot is implemented in `runPerformance.sqf`, available through `-CortexFocus performance`. It creates 100 six-soldier groups for each OFF/ON/ON/OFF arm, warms up, then samples 60 seconds of server frame times. Every group must physically move; enabled arms require all 100 groups to remain managed and eligible. It checks baseline drift, the agreed median/p95 limits and a separate overdue-job bound. The first server pilot, runtime-20260927-085848, completed its performance stages with all 13 checks passing: OFF samples were 21 ms median / 24 ms p95; ON samples were 21/25 and 21/24 ms. Every group moved and all enabled groups remained managed and eligible. Maximum observed job overdue age was 6.511 seconds. This is one patrol run, not acceptance for contact latency, repeated trials, other scales or HC workloads.

The distributed contact arm is implemented in `runPerformanceContact.sqf` and selected with
`-CortexFocus performancecontact -HeadlessClients 2`. It uses matched OFF/ON/ON/OFF arms with 100
six-soldier manoeuvre groups divided across the server and both WMP headless owners. Real, stationary,
invulnerable opponents produce sustained contact without casualty drift. Every arm must retain at
least 33 groups and 198 living subject soldiers on each owner, move at least 90 groups, consume live
rifle ammunition in at least 60 groups and bring at least 90 groups into a physical response. The
owner-local sampler reports median, p95 and p99 frame time plus maximum overdue-job age. Each enabled
arm is compared with the two matched disabled baselines using the confirmed 5% median and 10% p95
budgets. This arm is saved and statically checked but has not yet run in Arma.

The 25/50/150 scale points, ACE HC distribution, repeated hardware runs and publication-rate
measurement remain outstanding. Keep existing physical behaviour tests and add performance coverage
alongside them.

#!/usr/bin/env node
// Generates seeds/001_initial_data.sql: project Fibi (teams Nexo, Vertex) and
// project AI (team Nexus),
// sprints S37–S42 with realistic issues, status history, blockers and defects.
// Output is deterministic (seeded RNG), so re-running produces the same file.
// Usage: node scripts/generate-seed.js

import { writeFileSync } from 'node:fs';

// ---------- deterministic helpers ----------
let seed = 20260923;
const rand = () => ((seed = (seed * 1664525 + 1013904223) % 2 ** 32) / 2 ** 32);
const chance = (p) => rand() < p;
const pick = (arr) => arr[Math.floor(rand() * arr.length)];
const between = (min, max) => min + rand() * (max - min);
const intBetween = (min, max) => Math.floor(between(min, max + 1));
let uuidCounter = 0;
const uuid = () => {
  const n = (++uuidCounter).toString(16).padStart(12, '0');
  return `00000000-0000-4000-8000-${n}`;
};
const q = (v) => (v === null || v === undefined ? 'NULL' : typeof v === 'string' ? `'${v.replace(/'/g, "''")}'` : String(v));
const ts = (d) => (d ? `'${d.toISOString()}'` : 'NULL');
const day = (d) => `'${d.toISOString().slice(0, 10)}'`;
const addDays = (d, n) => new Date(d.getTime() + n * 86400000);

// Working days of a sprint: 11 weekdays starting on a Monday.
function workingDays(start) {
  const days = [];
  for (let d = new Date(start); days.length < 11; d = addDays(d, 1)) {
    if (d.getUTCDay() !== 0 && d.getUTCDay() !== 6) days.push(new Date(d));
  }
  return days;
}
// Timestamp within a working day (09:00–18:00 UTC).
const atWorkHour = (d) => new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 9) + between(0, 9) * 3600000);

// ---------- reference data ----------
const projects = [
  { id: uuid(), key: 'FIBI', name: 'Fibi', description: 'Fibi delivery programme', releases: [['R2.3', '2026-08-14'], ['R2.4', '2026-09-25']] },
  { id: uuid(), key: 'AI', name: 'AI', description: 'AI programme', releases: [['R1.1', '2026-10-30']] },
];
const projectByKey = Object.fromEntries(projects.map((p) => [p.key, p]));
const issueCounters = Object.fromEntries(projects.map((p) => [p.key, 100]));

const teamDefs = [
  { project: 'FIBI', name: 'Nexo',   capacity: 47, unplanned: 0.09, completion: 0.91 },
  { project: 'FIBI', name: 'Vertex', capacity: 38, unplanned: 0.05, completion: 0.94 },
  // Nexus is new: a single sprint that is still active and ends today
  { project: 'AI',   name: 'Nexus',  capacity: 55, unplanned: 0.12, completion: 0.86, sprintNames: ['S1'], lastStart: '2026-09-09', activeLast: true },
];

const firstNames = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Morgan', 'Casey', 'Riley', 'Jamie', 'Avery', 'Quinn', 'Drew', 'Parker', 'Reese', 'Skyler', 'Rowan'];
const users = [{ id: uuid(), name: 'Demo Admin', email: 'admin@example.com', role: 'admin' }];
const teams = teamDefs.map((t, ti) => {
  const members = firstNames.slice(ti * 5, ti * 5 + 5).map((fn, i) => ({
    id: uuid(),
    name: `${fn} Demo`,
    email: `${fn.toLowerCase()}.${t.name.toLowerCase()}@example.com`,
    role: i === 0 ? 'scrum_master' : 'member',
  }));
  users.push(...members);
  return { ...t, project: projectByKey[t.project], id: uuid(), members, wipLimit: 5 };
});

// Two releases per project: sprints S37–S39 go to the first, S40–S42 to the second
const releases = projects.flatMap((p) =>
  p.releases.map(([name, target]) => ({ id: uuid(), project: p.id, projectKey: p.key, name, target }))
);
const releasesFor = (projectKey) => releases.filter((r) => r.projectKey === projectKey);

// Default history: S37–S42, where S42 has just finished (Mon 7 Sep – Mon 21 Sep 2026).
// A team can override this with its own sprintNames / lastStart / activeLast.
const sprintNames = ['S37', 'S38', 'S39', 'S40', 'S41', 'S42'];
const lastStart = new Date('2026-09-07T00:00:00Z');
// "Now" for an active sprint: nothing in it happens after this moment.
const asOf = new Date('2026-09-23T09:00:00Z');

const titles = {
  story: ['Account overview page', 'Payment confirmation flow', 'Search by reference', 'Export statement to PDF', 'Notification preferences',
    'Two-factor enrolment', 'Beneficiary management', 'Dashboard filters', 'Session timeout warning', 'Onboarding checklist',
    'Audit log viewer', 'Role-based menu', 'Bulk upload validation', 'Transaction history paging', 'Profile photo upload'],
  task: ['Upgrade API gateway', 'Add DB index for reports', 'Configure alerting', 'Refactor auth middleware', 'Update CI pipeline', 'Load test checkout API'],
  bug: ['Date shows in UTC', 'Totals rounding error', 'Filter resets on refresh', 'Broken link in footer', 'Slow report query'],
  spike: ['Evaluate charting library', 'Investigate SSO provider'],
};
const pointsScale = [1, 2, 2, 3, 3, 3, 5, 5, 5, 8];

const issues = [];
const sprintIssues = [];
const history = [];
const blocked = [];
const defects = [];
const sprints = [];

function newIssue(team, sprintDays) {
  const type = pick(['story', 'story', 'story', 'story', 'task', 'task', 'bug', 'spike']);
  const points = type === 'spike' ? 2 : type === 'bug' ? pick([1, 2, 3]) : pick(pointsScale);
  const issue = {
    id: uuid(),
    key: `${team.project.key}-${++issueCounters[team.project.key]}`,
    project: team.project.id,
    title: pick(titles[type]),
    type,
    points,
    assignee: pick(team.members).id,
    status: 'todo',
    startedAt: null,
    completedAt: null,
    dor: chance(0.94),
    ac: chance(0.91),
    dod: false,
    reviewed: false,
    tests: false,
    automated: false,
    createdAt: addDays(sprintDays[0], -intBetween(3, 20)),
  };
  issues.push(issue);
  return issue;
}

// Move an issue through the workflow, recording status history.
function progress(issue, from, finishBy, complete) {
  const flow = ['todo', 'in_progress', 'in_review', 'in_test', 'done'];
  let t = new Date(Math.max(from.getTime(), (issue.startedAt || from).getTime()));
  if (!issue.startedAt) {
    issue.startedAt = t;
    history.push({ issue: issue.id, from: 'todo', to: 'in_progress', at: t });
  }
  const targetIdx = complete ? 4 : intBetween(1, 3);
  let idx = flow.indexOf(issue.status === 'todo' ? 'in_progress' : issue.status);
  const cycleDays = Math.min(between(0.8, 3.2) + (issue.points >= 8 ? 1.5 : 0), 8);
  const step = (cycleDays * 86400000) / Math.max(targetIdx - idx, 1);
  while (idx < targetIdx) {
    t = new Date(Math.min(t.getTime() + step, finishBy.getTime()));
    history.push({ issue: issue.id, from: flow[idx], to: flow[idx + 1], at: t });
    idx++;
  }
  issue.status = flow[targetIdx];
  if (complete) {
    issue.completedAt = t;
    issue.dod = true;
    issue.reviewed = chance(0.96);
    issue.tests = chance(0.88);
    issue.automated = chance(0.76);
  }
}

for (const team of teams) {
  let carryOver = [];
  const names = team.sprintNames || sprintNames;
  const teamLastStart = team.lastStart ? new Date(`${team.lastStart}T00:00:00Z`) : lastStart;
  names.forEach((name, si) => {
    const start = addDays(teamLastStart, -14 * (names.length - 1 - si));
    const days = workingDays(start);
    const end = days[days.length - 1];
    const isActive = Boolean(team.activeLast) && si === names.length - 1;
    // Work in an active sprint can only have happened up to "now"
    const endOfSprint = isActive ? asOf : new Date(end.getTime() + 18 * 3600000);
    const sprint = {
      id: uuid(), team: team.id, name,
      release: releasesFor(team.project.key)[si < 3 ? 0 : 1].id,
      goal: `${team.name} ${name}: ${pick(['stabilise payments', 'ship onboarding', 'reporting improvements', 'performance hardening', 'release readiness'])}`,
      start: days[0], end,
      status: isActive ? 'active' : 'completed',
    };
    sprints.push(sprint);

    // Committed scope = carried-over items + new items up to ~capacity
    const capacity = Math.round(team.capacity * between(0.92, 1.1));
    const committed = [...carryOver];
    let committedPts = committed.reduce((s, i) => s + i.points, 0);
    while (committedPts < capacity) {
      const issue = newIssue(team, days);
      committed.push(issue);
      committedPts += issue.points;
    }
    committed.forEach((issue) => sprintIssues.push({ sprint: sprint.id, issue, commitment: 'committed', points: issue.points, addedAt: atWorkHour(days[0]) }));

    // Unplanned work added mid-sprint
    const added = [];
    const unplannedTarget = Math.round(committedPts * team.unplanned * between(0.7, 1.3));
    let addedPts = 0;
    while (addedPts < unplannedTarget) {
      const issue = newIssue(team, days);
      issue.createdAt = atWorkHour(days[intBetween(1, 7)]);
      added.push(issue);
      addedPts += issue.points;
      sprintIssues.push({ sprint: sprint.id, issue, commitment: 'added', points: issue.points, addedAt: issue.createdAt });
    }

    // Outcomes: large items spill more often; each sprint varies a little
    carryOver = [];
    const sprintFactor = between(-0.05, 0.03);
    for (const si2 of sprintIssues.filter((x) => x.sprint === sprint.id)) {
      const done = chance(team.completion + sprintFactor - (si2.issue.points >= 8 ? 0.08 : 0));
      const from = si2.commitment === 'added' ? si2.addedAt : atWorkHour(days[intBetween(0, 7)]);
      const finishBy = endOfSprint;
      progress(si2.issue, from, finishBy, done);
      // In an active sprint unfinished work has no outcome yet (it has not spilled over)
      si2.outcome = done ? 'completed' : isActive ? null : 'spillover';
      if (!done) carryOver.push(si2.issue);

      // Some items get blocked during the sprint
      if (chance(0.12)) {
        const bStart = new Date(Math.min(Math.max(si2.issue.startedAt.getTime(), days[1].getTime()) + between(0, 3) * 86400000, endOfSprint.getTime() - 7200000));
        const bLen = between(0.3, 3.5);
        blocked.push({
          issue: si2.issue.id,
          reason: pick(['Waiting on vendor API access', 'Environment unavailable', 'Awaiting design sign-off', 'Dependency on core team release']),
          external: chance(0.6),
          start: bStart,
          end: si === names.length - 1 && chance(0.4) ? null : new Date(Math.min(bStart.getTime() + bLen * 86400000, endOfSprint.getTime())),
        });
      }
    }

    // Defects raised during the sprint
    const defectCount = intBetween(10, 18);
    const sprintStories = sprintIssues.filter((x) => x.sprint === sprint.id).map((x) => x.issue);
    for (let d = 0; d < defectCount; d++) {
      const created = new Date(Math.min(atWorkHour(pick(days)).getTime(), endOfSprint.getTime() - 3600000));
      const r = rand();
      const foundIn = r < 0.03 ? 'prod' : r < 0.07 ? 'uat' : r < 0.55 ? 'qa' : 'dev';
      const closed = chance(0.8) ? new Date(Math.min(created.getTime() + between(0.2, 4) * 86400000, endOfSprint.getTime())) : null;
      defects.push({
        id: uuid(), project: team.project.id, sprint: sprint.id, issue: pick(sprintStories).id,
        title: `${pick(['Validation', 'Layout', 'Calculation', 'Permission', 'Timeout'])} issue in ${pick(titles.story).toLowerCase()}`,
        severity: pick(['low', 'medium', 'medium', 'high', foundIn === 'prod' ? 'critical' : 'medium']),
        foundIn, created, closed,
      });
    }
  });
}

// ---------- SQL output ----------
const out = [];
const insert = (table, cols, rows) => {
  if (!rows.length) return;
  out.push(`INSERT INTO ${table} (${cols.join(', ')}) VALUES\n  ${rows.map((r) => `(${r.join(', ')})`).join(',\n  ')};\n`);
};

out.push('-- Generated by scripts/generate-seed.js. Do not edit by hand.\n');
out.push('-- Team names are real; people are demo users.\n');
out.push('BEGIN;\n');
insert('users', ['id', 'name', 'email', 'role'], users.map((u) => [q(u.id), q(u.name), q(u.email), q(u.role)]));
insert('projects', ['id', 'key', 'name', 'description'], projects.map((p) => [q(p.id), q(p.key), q(p.name), q(p.description)]));
insert('teams', ['id', 'project_id', 'name', 'wip_limit'], teams.map((t) => [q(t.id), q(t.project.id), q(t.name), t.wipLimit]));
insert('team_members', ['team_id', 'user_id'], teams.flatMap((t) => t.members.map((m) => [q(t.id), q(m.id)])));
insert('releases', ['id', 'project_id', 'name', 'target_date'], releases.map((r) => [q(r.id), q(r.project), q(r.name), q(r.target)]));
insert('sprints', ['id', 'team_id', 'release_id', 'name', 'goal', 'start_date', 'end_date', 'status'],
  sprints.map((s) => [q(s.id), q(s.team), q(s.release), q(s.name), q(s.goal), day(s.start), day(s.end), q(s.status)]));
insert('issues', ['id', 'project_id', 'issue_key', 'title', 'type', 'story_points', 'assignee_id', 'status', 'started_at', 'completed_at',
  'dor_met', 'dod_met', 'has_acceptance_criteria', 'code_reviewed', 'tests_complete', 'automated', 'created_at'],
  issues.map((i) => [q(i.id), q(i.project), q(i.key), q(i.title), q(i.type), i.points, q(i.assignee), q(i.status), ts(i.startedAt), ts(i.completedAt),
    i.dor, i.dod, i.ac, i.reviewed, i.tests, i.automated, ts(i.createdAt)]));
insert('sprint_issues', ['sprint_id', 'issue_id', 'commitment', 'outcome', 'points', 'added_at'],
  sprintIssues.map((s) => [q(s.sprint), q(s.issue.id), q(s.commitment), q(s.outcome), s.points, ts(s.addedAt)]));
insert('issue_status_history', ['issue_id', 'from_status', 'to_status', 'changed_at'],
  history.map((h) => [q(h.issue), q(h.from), q(h.to), ts(h.at)]));
insert('blocked_periods', ['issue_id', 'reason', 'external', 'started_at', 'ended_at'],
  blocked.map((b) => [q(b.issue), q(b.reason), b.external, ts(b.start), ts(b.end)]));
insert('defects', ['id', 'project_id', 'sprint_id', 'issue_id', 'title', 'severity', 'found_in', 'created_at', 'closed_at'],
  defects.map((d) => [q(d.id), q(d.project), q(d.sprint), q(d.issue), q(d.title), q(d.severity), q(d.foundIn), ts(d.created), ts(d.closed)]));
insert('metric_targets', ['project_id', 'metric', 'operator', 'value'], [
  ['predictability', '>=', 80], ['completion', '>=', 80], ['spillover', '<=', 10], ['unplanned', '<=', 10],
  ['defect_escape', '<=', 5], ['blocked_items', '<=', 3], ['dod_compliance', '>=', 100],
].flatMap(([m, op, v]) => projects.map((p) => [q(p.id), q(m), q(op), v])));
out.push('COMMIT;\n');

const file = new URL('../seeds/001_initial_data.sql', import.meta.url);
writeFileSync(file, out.join('\n'));
console.log(`Wrote ${file.pathname}: ${users.length} users, ${teams.length} teams, ${sprints.length} sprints, ${issues.length} issues, ${defects.length} defects, ${blocked.length} blocked periods`);

'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { buildDemoData, summarize, weekdayOf, SHIFTS, PREFIX } = require('./popular_demo.cjs');

// Quinta, 12/11/2026, 15:00 (horário local).
const now = new Date(2026, 10, 12, 15, 0);
const { people, writes } = buildDemoData({ now });
const docs = new Map(writes.map(({ path, data }) => [path, data]));
const byPrefix = (prefix) => writes.filter(({ path }) => path.startsWith(prefix));
const usersOfType = (type) =>
  writes.filter(({ path, data }) => /^users\/[^/]+$/.test(path) && data.type === type);

test('volume médio: 1 admin, 4 professores, 30 alunos e 2 unidades', () => {
  assert.equal(usersOfType('admin').length, 1);
  assert.equal(usersOfType('instructor').length, 4);
  assert.equal(usersOfType('user').length, 30);
  assert.equal(summarize(writes).units, 2);
  assert.equal(people.length, 35);
});

test('contas pedidas para a demonstração existem com nome e e-mail certos', () => {
  const find = (email) => people.find((person) => person.email === email);
  assert.deepEqual(
    [find('admin@demo.com'), find('prof@demo.com'), find('aluno@demo.com')].map(
      (person) => [person.name, person.type],
    ),
    [
      ['Admin Demonstração', 'admin'],
      ['Professor Demonstração', 'instructor'],
      ['Aluno Demonstração', 'user'],
    ],
  );
  const student = docs.get(`users/${find('aluno@demo.com').uid}`);
  assert.equal(student.responsable, find('prof@demo.com').uid);
});

test('todo ID e e-mail é único e todo documento raiz começa com demo-', () => {
  assert.equal(new Set(people.map((p) => p.email)).size, people.length);
  assert.equal(new Set(people.map((p) => p.uid)).size, people.length);
  assert.equal(new Set(writes.map((w) => w.path)).size, writes.length);
  for (const { path } of writes) {
    assert.ok(path.split('/')[1].startsWith(PREFIX), path);
  }
  for (const person of people) assert.ok(person.uid.startsWith(PREFIX));
});

test('nenhuma senha vai para os documentos', () => {
  assert.doesNotMatch(JSON.stringify(writes), /password|senha/i);
});

test('vínculos apontam para professores, unidades e treinos que existem', () => {
  const teachers = new Set(usersOfType('instructor').map(({ path }) => path.split('/')[1]));
  const units = new Set(byPrefix('units/').map(({ path }) => path.split('/')[1]));
  for (const { data } of usersOfType('user')) {
    assert.ok(teachers.has(data.responsable));
    assert.ok(units.has(data.unitId));
    assert.ok(['onSite', 'remote'].includes(data.modality));
  }
  for (const { path, data } of writes.filter((w) => w.path.includes('/trainingPlans/'))) {
    const routineIds = new Set(data.routines.map((r) => r.id));
    assert.equal(Object.keys(data.weeklySchedule).length, 7, path);
    for (const routineId of Object.values(data.weeklySchedule)) {
      if (routineId) assert.ok(routineIds.has(routineId), path);
    }
    const state = docs.get(path.replace(/trainingPlans\/.+$/, 'trainingState/current'));
    assert.equal(state.activePlanId, data.id);
    assert.equal(state.instructorId, data.instructorId);
  }
});

test('alunos remotos têm treino em casa e não têm ficha presencial', () => {
  const remote = usersOfType('user').filter(({ data }) => data.modality === 'remote');
  assert.ok(remote.length > 0);
  for (const { path } of remote) {
    assert.ok(docs.has(`${path}/homeWorkouts/current`));
    assert.ok(!byPrefix(`${path}/trainingPlans/`).length);
  }
});

test('sessões são finalizadas no passado e têm ao menos uma série feita', () => {
  const sessions = writes.filter(({ path }) => path.includes('/trainingSessions/'));
  assert.ok(sessions.length > 300);
  for (const { data } of sessions) {
    assert.equal(data.status, 'finished');
    assert.ok(new Date(data.finishedAt) < now);
    assert.ok(new Date(data.startedAt) < new Date(data.finishedAt));
    assert.ok(data.exercises.some((e) => e.sets.some((s) => s.completed)));
  }
});

test('há alunos ativos, em risco (10+ dias) e inativos (30+ dias)', () => {
  const lastByStudent = new Map();
  for (const { path, data } of writes.filter((w) => w.path.includes('/trainingSessions/'))) {
    const student = path.split('/')[1];
    const finished = new Date(data.finishedAt);
    if (!lastByStudent.has(student) || lastByStudent.get(student) < finished) {
      lastByStudent.set(student, finished);
    }
  }
  const idle = [...lastByStudent.values()].map((date) => (now - date) / 86400000);
  assert.ok(idle.some((days) => days < 3));
  assert.ok(idle.some((days) => days >= 10 && days < 30));
  assert.ok(idle.some((days) => days >= 30));
});

test('o Aluno Demonstração tem treino hoje ainda não feito e avaliações', () => {
  const uid = people.find((p) => p.email === 'aluno@demo.com').uid;
  const plan = docs.get(`users/${uid}/trainingPlans/${PREFIX}ficha-1`);
  assert.ok(plan.weeklySchedule[weekdayOf(now)]);
  const today = writes.filter(
    ({ path, data }) =>
      path.startsWith(`users/${uid}/trainingSessions/`) &&
      new Date(data.finishedAt).toDateString() === now.toDateString(),
  );
  assert.equal(today.length, 0);
  assert.equal(byPrefix(`users/${uid}/evaluations/`).length, 3);
});

test('a escala não sobrepõe turnos do mesmo professor no mesmo dia', () => {
  const minutes = (time) => Number(time.slice(0, 2)) * 60 + Number(time.slice(3));
  for (const [i, a] of SHIFTS.entries()) {
    for (const b of SHIFTS.slice(i + 1)) {
      if (a[0] !== b[0] || a[2] !== b[2]) continue;
      const overlap = minutes(a[3]) < minutes(b[4]) && minutes(b[3]) < minutes(a[4]);
      assert.ok(!overlap, `${a} x ${b}`);
    }
  }
});

test('a mesma semente gera os mesmos dados', () => {
  const again = buildDemoData({ now });
  assert.deepEqual(again.writes, writes);
});

test('usa o ID do catálogo quando o exercício existe nele', () => {
  const { writes: linked } = buildDemoData({
    now,
    catalog: { 'leg press': { id: 'repdb-leg-press', imageUrl: 'https://example.org/leg.webp' } },
  });
  const items = linked
    .filter(({ path }) => path.includes('/trainingPlans/'))
    .flatMap(({ data }) => data.routines.flatMap((r) => r.exercises))
    .filter((e) => e.name === 'Leg Press');
  assert.ok(items.length > 0);
  for (const item of items) {
    assert.equal(item.catalogExerciseId, 'repdb-leg-press');
    assert.equal(item.imageUrl, 'https://example.org/leg.webp');
  }
});

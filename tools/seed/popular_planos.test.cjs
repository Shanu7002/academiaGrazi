'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const { buildPlanData, addMonthsClamped, PLANS } = require('./popular_planos.cjs');

// Segunda, 16/11/2026, 21:00 (horário local).
const now = new Date(2026, 10, 16, 21, 0);
const today = new Date(2026, 10, 16);
const students = [
  ...Array.from({ length: 29 }, (_, i) => ({
    id: `demo-aluno-${String(i + 1).padStart(2, '0')}`,
    remote: [5, 11, 16, 21, 25, 28].includes(i + 1),
  })),
  { id: 'demo-aluno-demonstracao', remote: false },
];
const { plans, memberships } = buildPlanData({ now, students, adminId: 'demo-admin' });
const parse = (value) => {
  const [y, m, d] = value.split('-').map(Number);
  return new Date(y, m - 1, d);
};

/** Mesma regra do app: vencida em aberto antes de hoje; vence em breve até 10 dias (BusinessRules.membershipFeeDueSoonDays). */
function standing({ startDate, durationMonths, payments }) {
  const start = parse(startDate);
  const paid = new Set(payments.map((p) => p.installment));
  const soon = new Date(2026, 10, 26);
  let overdue = 0;
  let nextOpen = null;
  for (let i = 0; i < durationMonths; i++) {
    const due = addMonthsClamped(start, i);
    if (paid.has(i + 1)) continue;
    if (due < today) overdue++;
    else if (!nextOpen) nextOpen = due;
  }
  const end = new Date(addMonthsClamped(start, durationMonths).getTime() - 86400000);
  if (overdue > 0) return `overdue${overdue}`;
  if (nextOpen && nextOpen <= soon) return 'dueSoon';
  if (!nextOpen && today > end) return 'ended';
  return 'upToDate';
}

test('catálogo variado com um plano fora do catálogo', () => {
  assert.equal(plans.length, PLANS.length);
  assert.deepEqual(plans.filter((p) => !p.data.active).map((p) => p.key), ['pilates']);
  assert.ok(plans.every((p) => Number.isInteger(p.data.monthlyPriceCents) && p.data.monthlyPriceCents > 0));
});

test('cada aluno fica na situação planejada pela regra do app', () => {
  for (const m of memberships) {
    const expected = m.situation === 'new' ? 'upToDate' : m.situation;
    assert.equal(standing(m.data), expected, `${m.data.studentId} (${m.situation})`);
  }
});

test('há alunos em todas as situações e alguns sem plano', () => {
  const situations = new Set(memberships.map((m) => m.situation));
  for (const s of ['upToDate', 'dueSoon', 'overdue1', 'overdue2', 'new', 'ended']) {
    assert.ok(situations.has(s), s);
  }
  assert.ok(memberships.length < students.length);
});

test('remotos recebem o plano de treino em casa; ninguém recebe plano fora do catálogo', () => {
  const remote = new Set(students.filter((s) => s.remote).map((s) => s.id));
  for (const m of memberships) {
    assert.notEqual(m.data.planId, 'demo-plano-pilates');
    if (remote.has(m.data.studentId) && m.situation !== 'ended') {
      assert.equal(m.data.planId, 'demo-plano-remoto');
    }
  }
});

test('documentos seguem o formato das regras', () => {
  for (const m of memberships) {
    const d = m.data;
    assert.match(d.startDate, /^\d{4}-\d{2}-\d{2}$/);
    assert.equal(d.status, 'active');
    assert.ok(d.payments.length <= d.durationMonths);
    for (const p of d.payments) {
      assert.match(p.paidOn, /^\d{4}-\d{2}-\d{2}$/);
      assert.ok(parse(p.paidOn) <= today, 'pagamento no futuro');
      assert.ok(['pix', 'cash', 'card', 'transfer'].includes(p.method));
    }
  }
});

test('aluno@demo.com fica em dia, para não ser bloqueado', () => {
  const demo = memberships.find((m) => m.data.studentId === 'demo-aluno-demonstracao');
  assert.equal(standing(demo.data), 'upToDate');
});

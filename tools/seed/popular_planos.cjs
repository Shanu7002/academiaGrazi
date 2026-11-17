/**
 * Popula o Firestore DEV com planos e mensalidades FICTICIOS, no mesmo
 * formato que o app grava (`membershipPlans` e `memberships`, AGENTS.md §5.3).
 *
 * APAGA todos os planos do catalogo e todos os planos dos alunos que
 * existirem, cria um catalogo variado e atribui um plano a quase todos os
 * alunos (`users` com type 'user'), com situacoes diferentes: em dia, vence
 * em breve, em atraso, novo, encerrado e sem plano. Os em atraso (8 e 20 dias)
 * ficam com o app bloqueado; aluno@demo.com fica sempre em dia.
 *
 *   node popular_planos.cjs           simula e mostra o resumo
 *   node popular_planos.cjs --apply   apaga e grava
 *
 * Nao cria contas nem mexe em outras colecoes. Credencial: a mesma conta de
 * servico do `popular_demo.cjs` (GOOGLE_APPLICATION_CREDENTIALS).
 */
'use strict';

const PROJECT_ID = 'academia-grazi-dev-ab105';
const PREFIX = 'demo-';

// [chave, nome, valor em centavos, meses, modalidades, ativo]
const PLANS = [
  ['mensal', 'Plano Mensal Musculação', 14990, 1, 'Musculação', true],
  ['trimestral', 'Plano Conexão Trimestral', 13490, 3, 'Musculação + Funcional', true],
  ['semestral', 'Plano Conexão Semestral', 11990, 6, 'Musculação + Pilates', true],
  ['anual', 'Plano Movimento Anual', 9990, 12, 'Musculação + Pilates + Aulas coletivas', true],
  ['remoto', 'Plano Treino em Casa', 7990, 6, 'Treino em casa pelo app', true],
  // Fora do catalogo: mostra a retirada na tela de planos.
  ['pilates', 'Plano Pilates Avulso', 18990, 1, 'Pilates', false],
];

// Ordem em que as situacoes sao distribuidas entre os alunos.
const SITUATIONS = [
  'upToDate', 'overdue1', 'dueSoon', 'upToDate', 'overdue2', 'new',
  'upToDate', 'ended', 'dueSoon', 'none', 'upToDate', 'overdue1',
];

const DEMO_STUDENT_ID = `${PREFIX}aluno-demonstracao`;

const METHODS = ['pix', 'pix', 'pix', 'card', 'cash', 'transfer'];

const pad = (value) => String(value).padStart(2, '0');
const dateOnly = (date) =>
  `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
const dayOf = (date, days = 0) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);

/** Igual ao `addMonthsClamped` do app (membership_schedule.dart). */
function addMonthsClamped(date, months) {
  const first = new Date(date.getFullYear(), date.getMonth() + months, 1);
  const lastDay = new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate();
  return new Date(first.getFullYear(), first.getMonth(), Math.min(date.getDate(), lastDay));
}

/**
 * Para cada situacao: em que dia a mensalidade "atual" vence (relativo a
 * hoje), quantas mensalidades em aberto antes dela e quantos meses ja
 * passaram desde o inicio.
 */
function shapeOf(situation, monthsAgo) {
  switch (situation) {
    case 'upToDate': // proxima vence daqui a 12 dias, tudo pago antes
      return { anchorDays: 12, monthsAgo: Math.max(monthsAgo, 1), unpaidPast: 0 };
    case 'dueSoon': // proxima vence daqui a 3 dias
      return { anchorDays: 3, monthsAgo, unpaidPast: 0 };
    case 'overdue1': // venceu ha 8 dias
      return { anchorDays: -8, monthsAgo, unpaidPast: 1 };
    case 'overdue2': // venceu ha 20 dias e a anterior tambem esta em aberto
      return { anchorDays: -20, monthsAgo: Math.max(monthsAgo, 1), unpaidPast: 2 };
    case 'new': // comecou hoje e pagou a primeira
      return { anchorDays: 0, monthsAgo: 0, unpaidPast: 0, payToday: true };
    default:
      return null;
  }
}

/**
 * Monta os documentos. `students`: [{ id, remote }] em ordem estavel;
 * `adminId`: quem "registrou" as atribuicoes e pagamentos.
 */
function buildPlanData({ now, students, adminId }) {
  const today = dayOf(now);
  const createdAt = new Date(now.getTime() - 120 * 24 * 60 * 60 * 1000).toISOString();
  const plans = PLANS.map(([key, name, monthlyPriceCents, durationMonths, modalities, active]) => ({
    id: `${PREFIX}plano-${key}`,
    key,
    data: { name, monthlyPriceCents, durationMonths, modalities, active, createdAt },
  }));
  const planByKey = Object.fromEntries(plans.map((plan) => [plan.key, plan]));
  const onSitePlans = ['mensal', 'trimestral', 'semestral', 'anual'];

  const memberships = [];
  students.forEach((student, index) => {
    // A conta aluno@demo.com fica sempre em dia: e a usada para testar
    // os treinos, e atraso alem da tolerancia bloqueia o app.
    const situation =
      student.id === DEMO_STUDENT_ID ? 'upToDate' : SITUATIONS[index % SITUATIONS.length];
    if (situation === 'none') return;

    let plan;
    let start;
    let paidCount;
    if (situation === 'ended') {
      // Trimestral que acabou ha cerca de 2 meses, tudo pago.
      plan = planByKey.trimestral;
      start = addMonthsClamped(dayOf(today, -15), -5);
      paidCount = 3;
    } else {
      const monthsAgo = index % 5; // 0 a 4 meses de plano
      const shape = shapeOf(situation, monthsAgo);
      const candidates = student.remote ? ['remoto'] : onSitePlans;
      // Precisa de mensalidades suficientes para a situacao.
      const fitting = candidates.filter(
        (key) => planByKey[key].data.durationMonths > shape.monthsAgo,
      );
      plan = planByKey[fitting[index % fitting.length]];
      const anchor = dayOf(today, shape.anchorDays);
      start = addMonthsClamped(anchor, -shape.monthsAgo);
      // Mensalidades vencidas ate hoje (inclusive a ancora, se ja passou).
      let due = 0;
      for (let i = 0; i < plan.data.durationMonths; i++) {
        if (addMonthsClamped(start, i) < today) due++;
      }
      paidCount = shape.payToday ? 1 : Math.max(0, due - shape.unpaidPast);
    }

    const payments = [];
    for (let i = 0; i < paidCount; i++) {
      const dueDate = addMonthsClamped(start, i);
      // Paga no vencimento ou ate 3 dias depois, nunca no futuro.
      let paidOn = dayOf(dueDate, (index + i) % 4);
      if (paidOn > today) paidOn = today;
      payments.push({
        installment: i + 1,
        paidOn: dateOnly(paidOn),
        method: METHODS[(index + i) % METHODS.length],
        amountCents: plan.data.monthlyPriceCents,
        recordedBy: adminId,
        recordedAt: new Date(paidOn.getFullYear(), paidOn.getMonth(), paidOn.getDate(), 12).toISOString(),
      });
    }

    memberships.push({
      id: `${PREFIX}matricula-${student.id}`,
      situation,
      data: {
        studentId: student.id,
        planId: plan.id,
        planName: plan.data.name,
        modalities: plan.data.modalities,
        monthlyPriceCents: plan.data.monthlyPriceCents,
        durationMonths: plan.data.durationMonths,
        startDate: dateOnly(start),
        status: 'active',
        payments,
        createdAt: new Date(start.getFullYear(), start.getMonth(), start.getDate(), 12).toISOString(),
        createdBy: adminId,
      },
    });
  });

  return { plans, memberships };
}

async function main() {
  const apply = process.argv.includes('--apply');
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error('Defina GOOGLE_APPLICATION_CREDENTIALS com um JSON de conta de serviço LOCAL. Nunca envie essa chave no chat ou para o Git.');
  }
  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT_ID });
  const db = admin.firestore();

  const [usersSnap, plansSnap, membershipsSnap] = await Promise.all([
    db.collection('users').where('type', 'in', ['user', 'admin']).get(),
    db.collection('membershipPlans').get(),
    db.collection('memberships').get(),
  ]);
  const students = usersSnap.docs
    .filter((doc) => doc.data().type === 'user')
    .map((doc) => ({ id: doc.id, remote: doc.data().modality === 'remote' }))
    .sort((a, b) => a.id.localeCompare(b.id));
  const admins = usersSnap.docs.filter((doc) => doc.data().type === 'admin');
  const adminDoc = admins.find((doc) => doc.id.startsWith(PREFIX)) ?? admins[0];
  if (!adminDoc) throw new Error('Nenhum admin encontrado em users.');

  const { plans, memberships } = buildPlanData({ now: new Date(), students, adminId: adminDoc.id });
  const bySituation = {};
  for (const m of memberships) bySituation[m.situation] = (bySituation[m.situation] ?? 0) + 1;
  bySituation.none = students.length - memberships.length;
  // overdue1 (8 dias) e overdue2 (20 dias) passam da tolerancia de 5 dias.
  const blocked = memberships.filter((m) => m.situation.startsWith('overdue')).length;

  console.log(`Projeto: ${PROJECT_ID}`);
  console.log(`Serão apagados: ${plansSnap.size} planos do catálogo e ${membershipsSnap.size} planos de alunos.`);
  console.log(`Serão criados: ${plans.length} planos e ${memberships.length} planos de alunos (de ${students.length} alunos).`);
  console.table(bySituation);
  console.log(`Alunos que ficarão com o app bloqueado (atraso > 5 dias): ${blocked}`);

  if (!apply) {
    console.log('SIMULAÇÃO CONCLUÍDA. Nada foi enviado ao Firebase. Use --apply para gravar.');
    return;
  }

  const writer = db.bulkWriter();
  for (const doc of [...plansSnap.docs, ...membershipsSnap.docs]) writer.delete(doc.ref);
  await writer.flush();
  for (const plan of plans) writer.set(db.collection('membershipPlans').doc(plan.id), plan.data);
  for (const m of memberships) writer.set(db.collection('memberships').doc(m.id), m.data);
  await writer.close();
  console.log('CONCLUÍDO.');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { buildPlanData, addMonthsClamped, PLANS };

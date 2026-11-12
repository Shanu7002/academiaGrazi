/**
 * Popula o Firestore DEV com dados FICTICIOS de demonstracao, no mesmo
 * formato que o app grava (ver AGENTS.md §5 e os models em lib/models/).
 *
 * Executado SOMENTE na maquina do proprietario, com credencial local.
 * Nenhuma senha ou credencial fica neste arquivo: a senha das contas de
 * demonstracao vem da variavel de ambiente SENHA_DEMO.
 *
 *   node popular_demo.cjs                 simula e mostra o resumo
 *   node popular_demo.cjs --apply         grava (substitui os dados demo-*)
 *   node popular_demo.cjs --limpar        simula a limpeza
 *   node popular_demo.cjs --limpar --apply  apaga tudo o que e demo-*
 *
 * Todo documento e conta criados aqui tem ID com o prefixo `demo-`. Nao ha
 * campo de marcacao porque as regras usam `hasOnly` nas edicoes do app.
 */
'use strict';

const PROJECT_ID = 'academia-grazi-dev-ab105';
const PREFIX = 'demo-';
const DAY_MS = 24 * 60 * 60 * 1000;
const HISTORY_WEEKS = 8;

// ── Utilitarios deterministicos ──────────────────────────────────────────

/** Gerador pseudoaleatorio com semente: a mesma semente gera os mesmos dados. */
function createRandom(seed) {
  let state = seed >>> 0;
  const next = () => {
    state = (state + 0x6d2b79f5) >>> 0;
    let t = state;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  return {
    next,
    int: (min, max) => min + Math.floor(next() * (max - min + 1)),
    pick: (list) => list[Math.floor(next() * list.length)],
    chance: (probability) => next() < probability,
  };
}

/** Igual ao `ExerciseCatalogService.normalizeSearch` do app. */
function normalize(text) {
  return text
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/\s+/g, ' ');
}

function slug(text) {
  return normalize(text).replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}

const pad = (value) => String(value).padStart(2, '0');
const round1 = (value) => Math.round(value * 10) / 10;
const roundHalf = (value) => Math.round(value * 2) / 2;

/** Meia-noite local de [date] somada de [days] dias de calendario. */
function dayOf(date, days = 0) {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);
}

/** 1 = segunda ... 7 = domingo, como o DateTime.weekday do Dart. */
const weekdayOf = (date) => ((date.getDay() + 6) % 7) + 1;

// ── Catalogo usado nas fichas ────────────────────────────────────────────

/** Exercicios das fichas. `load` e a carga base (kg) para mulheres; null = peso do corpo. */
const EXERCISES = {
  agachamento: { name: 'Agachamento Livre', group: 'Pernas', load: 20, tip: 'Pés na largura dos ombros, desça com o tronco firme e joelhos alinhados com os pés.' },
  legPress: { name: 'Leg Press', group: 'Pernas', load: 60, tip: 'Lombar apoiada no encosto; desça até 90 graus sem tirar o quadril do banco.' },
  extensora: { name: 'Cadeira Extensora', group: 'Pernas', load: 25, tip: 'Estenda os joelhos sem travar e controle a volta.' },
  flexora: { name: 'Mesa Flexora', group: 'Pernas', load: 20, tip: 'Quadril colado no banco; flexione os joelhos sem arquear a lombar.' },
  elevacaoPelvica: { name: 'Elevação Pélvica', group: 'Glúteos', load: 30, tip: 'Suba o quadril contraindo os glúteos e segure um segundo no topo.' },
  goblet: { name: 'Agachamento Goblet', group: 'Pernas', load: 10, tip: 'Segure o halter junto ao peito e mantenha o tronco ereto.' },
  avanco: { name: 'Avanço', group: 'Pernas', load: 6, tip: 'Passo largo, joelho de trás em direção ao chão, tronco reto.' },
  supino: { name: 'Supino Reto com Barra', group: 'Peito', load: 15, tip: 'Escápulas encaixadas no banco; desça a barra até a linha do peito.' },
  supinoInclinado: { name: 'Supino Inclinado com Halteres', group: 'Peito', load: 8, tip: 'Banco a 30 graus; empurre os halteres para cima sem bater um no outro.' },
  supinoHalteres: { name: 'Supino Reto com Halteres', group: 'Peito', load: 8, tip: 'Cotovelos a 45 graus do tronco, desça com controle.' },
  desenvolvimento: { name: 'Desenvolvimento de Ombros', group: 'Ombros', load: 6, tip: 'Empurre os halteres acima da cabeça sem arquear as costas.' },
  elevacaoLateral: { name: 'Elevação Lateral', group: 'Ombros', load: 3, tip: 'Eleve os braços até a altura dos ombros, cotovelos levemente flexionados.' },
  triceps: { name: 'Tríceps na Polia', group: 'Tríceps', load: 12, tip: 'Cotovelos fixos ao lado do corpo; estenda até o fim do movimento.' },
  puxada: { name: 'Puxada Frontal', group: 'Costas', load: 25, tip: 'Puxe a barra até o peito levando os cotovelos para baixo.' },
  remadaBaixa: { name: 'Remada Baixa', group: 'Costas', load: 25, tip: 'Peito aberto; puxe o triângulo até o abdômen aproximando as escápulas.' },
  remadaUnilateral: { name: 'Remada Unilateral', group: 'Costas', load: 8, tip: 'Apoie joelho e mão no banco e puxe o halter até o quadril.' },
  rosca: { name: 'Rosca Direta', group: 'Bíceps', load: 8, tip: 'Cotovelos parados; suba a barra sem balançar o tronco.' },
  roscaMartelo: { name: 'Rosca Martelo', group: 'Bíceps', load: 5, tip: 'Pegada neutra, suba os halteres alternando os braços.' },
  facePull: { name: 'Face Pull', group: 'Ombros', load: 8, tip: 'Puxe a corda em direção ao rosto, abrindo os cotovelos.' },
  prancha: { name: 'Prancha', group: 'Abdômen', load: null, tip: 'Corpo alinhado da cabeça aos pés; contraia o abdômen e respire.' },
  pranchaLateral: { name: 'Prancha Lateral', group: 'Abdômen', load: null, tip: 'Apoio no antebraço, quadril alto e alinhado.' },
  abdominal: { name: 'Abdominal Crunch', group: 'Abdômen', load: null, tip: 'Tire as escápulas do chão sem puxar o pescoço.' },
  ponte: { name: 'Ponte de Glúteos', group: 'Glúteos', load: null, tip: 'Deitado, pés apoiados; eleve o quadril e desça devagar.' },
  flexao: { name: 'Flexão de Braços', group: 'Peito', load: null, tip: 'Mãos na largura dos ombros; se precisar, apoie os joelhos.' },
};

/** Rotinas por objetivo: [letra, nome, foco, [chave, series, reps, descanso]]. */
const PROGRAMS = {
  hypertrophy: [
    ['A', 'Treino A', 'Pernas e glúteos', [['agachamento', 4, 10, 90], ['legPress', 4, 12, 90], ['extensora', 3, 12, 60], ['flexora', 3, 12, 60], ['elevacaoPelvica', 3, 12, 60]]],
    ['B', 'Treino B', 'Peito, ombros e tríceps', [['supino', 4, 10, 90], ['supinoInclinado', 3, 12, 60], ['desenvolvimento', 3, 10, 60], ['elevacaoLateral', 3, 15, 45], ['triceps', 3, 12, 45]]],
    ['C', 'Treino C', 'Costas e bíceps', [['puxada', 4, 10, 90], ['remadaBaixa', 3, 12, 60], ['remadaUnilateral', 3, 10, 60], ['rosca', 3, 12, 45], ['roscaMartelo', 3, 12, 45]]],
  ],
  conditioning: [
    ['A', 'Treino A', 'Corpo inteiro', [['goblet', 3, 15, 45], ['supinoHalteres', 3, 12, 45], ['remadaBaixa', 3, 12, 45], ['avanco', 3, 12, 45], ['prancha', 3, 30, 30]]],
    ['B', 'Treino B', 'Inferiores e core', [['legPress', 3, 15, 60], ['elevacaoPelvica', 3, 15, 45], ['flexora', 3, 12, 45], ['abdominal', 3, 20, 30], ['pranchaLateral', 3, 20, 30]]],
  ],
  mobility: [
    ['A', 'Treino A', 'Mobilidade e core', [['ponte', 3, 15, 45], ['prancha', 3, 30, 30], ['pranchaLateral', 3, 20, 30], ['facePull', 3, 15, 45], ['goblet', 3, 12, 60]]],
    ['B', 'Treino B', 'Estabilidade e postura', [['avanco', 3, 10, 60], ['remadaUnilateral', 3, 12, 45], ['elevacaoLateral', 3, 12, 45], ['abdominal', 3, 15, 30]]],
  ],
  home: [
    ['A', 'Casa A', 'Corpo inteiro sem equipamento', [['agachamento', 3, 15, 45], ['flexao', 3, 10, 45], ['ponte', 3, 15, 45], ['avanco', 3, 12, 45], ['prancha', 3, 30, 30]]],
    ['B', 'Casa B', 'Core e mobilidade', [['abdominal', 3, 20, 30], ['pranchaLateral', 3, 20, 30], ['ponte', 3, 20, 30], ['prancha', 3, 40, 30]]],
  ],
};

const PROGRAM_BY_GOAL = {
  muscleGain: 'hypertrophy',
  strengthening: 'hypertrophy',
  weightLoss: 'conditioning',
  conditioning: 'conditioning',
  mobility: 'mobility',
};

const PLAN_NAME_BY_GOAL = {
  muscleGain: 'Hipertrofia — Ciclo 1',
  strengthening: 'Fortalecimento — Ciclo 1',
  weightLoss: 'Emagrecimento — Ciclo 1',
  conditioning: 'Condicionamento — Ciclo 1',
  mobility: 'Mobilidade — Ciclo 1',
};

/** Dias de treino de cada programa, por quantidade de rotinas. */
const SCHEDULES = {
  3: { 1: 'A', 2: null, 3: 'B', 4: null, 5: 'C', 6: null, 7: null },
  2: { 1: 'A', 2: null, 3: 'B', 4: null, 5: 'A', 6: null, 7: null },
  // Vitrine: o Aluno Demonstração treina de segunda a sábado.
  showcase: { 1: 'A', 2: 'B', 3: 'C', 4: 'A', 5: 'B', 6: 'C', 7: null },
};

// ── Pessoas ficticias ────────────────────────────────────────────────────

const ADMIN = { key: 'admin', name: 'Admin Demonstração', email: 'admin@demo.com' };

const TEACHERS = [
  { key: 'prof-demonstracao', name: 'Professor Demonstração', email: 'prof@demo.com', specialty: 'Musculação e hipertrofia', capacity: 30 },
  { key: 'prof-rafael-lima', name: 'Rafael Lima', specialty: 'Funcional e condicionamento', capacity: 25 },
  { key: 'prof-juliana-rocha', name: 'Juliana Rocha', specialty: 'Mobilidade e pilates', capacity: 20 },
  { key: 'prof-bruno-alves', name: 'Bruno Alves', specialty: 'Emagrecimento e treino em casa', capacity: 30 },
];

/** [nome, genero]. O primeiro e a vitrine da demonstracao. */
const STUDENTS = [
  ['Aluno Demonstração', 'undisclosed'],
  ['Ana Beatriz Souza', 'female'], ['Mariana Costa', 'female'],
  ['Fernanda Oliveira', 'female'], ['Camila Santos', 'female'],
  ['Patrícia Gomes', 'female'], ['Luciana Ferreira', 'female'],
  ['Beatriz Ramos', 'female'], ['Larissa Martins', 'female'],
  ['Gabriela Nunes', 'female'], ['Renata Barbosa', 'female'],
  ['Tatiane Carvalho', 'female'], ['Vanessa Ribeiro', 'female'],
  ['Aline Pereira', 'female'], ['Débora Castro', 'female'],
  ['Simone Araújo', 'female'], ['Priscila Teixeira', 'female'],
  ['Helena Moreira', 'female'], ['Carolina Dias', 'female'],
  ['Marcos Vieira', 'male'], ['Lucas Monteiro', 'male'],
  ['Pedro Henrique Lopes', 'male'], ['Thiago Rezende', 'male'],
  ['Felipe Cardoso', 'male'], ['André Nascimento', 'male'],
  ['Rodrigo Pinto', 'male'], ['Gustavo Batista', 'male'],
  ['Sam Oliveira', 'undisclosed'], ['Alex Duarte', 'undisclosed'],
  ['Joana Prado', 'female'],
];

/**
 * Perfil de frequencia de cada aluno (mesma ordem de STUDENTS), para os
 * paineis terem ativos, irregulares, em risco (P1, 10 dias) e inativos
 * (P2, 30 dias), alem de alunos novos.
 */
const PROFILES = [
  'showcase',
  'active', 'active', 'active', 'active', 'active', 'active', 'active',
  'active', 'active', 'active', 'active', 'active', 'active',
  'irregular', 'irregular', 'irregular', 'irregular', 'irregular', 'irregular',
  'risk', 'risk', 'risk', 'risk',
  'inactive', 'inactive', 'inactive',
  'new', 'new', 'newWithoutPlan',
];

/** Indices dos alunos que treinam em casa (modalidade remota). */
const REMOTE = new Set([5, 11, 16, 21, 25, 28]);

const GOALS = ['muscleGain', 'weightLoss', 'conditioning', 'strengthening', 'mobility'];
const CONDITIONS = ['Coluna/Lombar', 'Joelho', 'Ombro', 'Hipertensão'];
const RELATIONSHIPS = ['Cônjuge / Parceiro(a)', 'Pai / Mãe', 'Irmão / Irmã', 'Filho(a)', 'Amigo(a) Próximo(a)'];
const CONTACT_NAMES = ['Maria', 'José', 'Cláudia', 'Paulo', 'Sônia', 'Ricardo', 'Rita', 'Carlos'];

const UNITS = [
  { key: 'unidade-centro', name: 'Bloco Centro', address: 'Rua das Palmeiras, 120 — Centro' },
  { key: 'unidade-jardim', name: 'Bloco Jardim', address: 'Avenida das Acácias, 845 — Jardim América' },
];

/** Escala: [professor, unidade, dia, inicio, fim]. Sem sobreposicao por professor. */
const SHIFTS = [
  [0, 0, 1, '07:00', '12:00'], [0, 0, 3, '07:00', '12:00'], [0, 0, 5, '07:00', '12:00'],
  [0, 1, 2, '14:00', '20:00'], [0, 1, 4, '14:00', '20:00'],
  [1, 0, 1, '14:00', '21:00'], [1, 0, 3, '14:00', '21:00'], [1, 0, 5, '14:00', '21:00'],
  [1, 0, 6, '08:00', '12:00'],
  [2, 0, 2, '07:00', '13:00'], [2, 0, 4, '07:00', '13:00'],
  [2, 1, 1, '15:00', '21:00'], [2, 1, 3, '15:00', '21:00'],
  [3, 1, 1, '06:00', '11:00'], [3, 1, 2, '06:00', '11:00'], [3, 1, 3, '06:00', '11:00'],
  [3, 1, 4, '06:00', '11:00'], [3, 1, 5, '06:00', '11:00'],
];

/** Grade de aulas: [nome, unidade, professor, dia, inicio, duracao, vagas]. */
const CLASSES = [
  ['Pilates', 0, 2, 2, '08:00', 50, 12], ['Funcional', 0, 1, 1, '18:30', 50, 20],
  ['Spinning', 0, 1, 2, '19:00', 45, 18], ['Yoga', 0, 2, 4, '08:00', 60, 15],
  ['HIIT', 0, 1, 5, '18:30', 40, 20], ['Alongamento', 0, 1, 6, '09:00', 45, 20],
  ['Pilates', 0, 2, 4, '12:00', 50, 12],
  ['Funcional', 1, 3, 1, '07:00', 50, 20], ['Pilates', 1, 2, 3, '18:00', 50, 12],
  ['Spinning', 1, 3, 3, '07:30', 45, 18], ['Dança', 1, 2, 1, '19:30', 50, 25],
  ['Yoga', 1, 2, 2, '18:00', 60, 15], ['HIIT', 1, 3, 6, '10:00', 40, 20],
];

function emailOf(name) {
  const parts = normalize(name).split(' ');
  return `${parts[0]}.${parts[parts.length - 1]}@demo.com`;
}

// ── Montagem dos dados ───────────────────────────────────────────────────

/**
 * Monta todos os documentos e contas de demonstracao.
 *
 * @param {object} options
 * @param {Date} options.now  relogio local de referencia
 * @param {Record<string, object>} [options.catalog]  exercicios do
 *   `exerciseCatalog` por nome normalizado ({ id, imageUrl })
 * @param {number} [options.seed]
 * @returns {{ people: object[], writes: {path: string, data: object}[] }}
 */
function buildDemoData({ now, catalog = {}, seed = 2026 }) {
  const random = createRandom(seed);
  const iso = (date) => date.toISOString();
  const people = [];
  const writes = [];
  const put = (path, data) => writes.push({ path, data });
  const today = dayOf(now);

  const exercise = (key) => {
    const base = EXERCISES[key];
    const found = catalog[normalize(base.name)];
    return {
      catalogExerciseId: found?.id ?? `${PREFIX}exercicio-${slug(base.name)}`,
      name: base.name,
      muscleGroup: base.group,
      instructions: base.tip,
      imageUrl: found?.imageUrl || null,
      load: base.load,
    };
  };

  const routinesOf = (programKey, loadFactor) =>
    PROGRAMS[programKey].map(([letter, name, focus, items]) => {
      const exercises = items.map(([key, sets, repetitions, restSeconds], index) => {
        const item = exercise(key);
        return {
          id: `item-${index + 1}`,
          catalogExerciseId: item.catalogExerciseId,
          name: item.name,
          muscleGroup: item.muscleGroup,
          instructions: item.instructions,
          imageUrl: item.imageUrl,
          sets,
          repetitions,
          restSeconds,
          technique: 'Tradicional',
          targetLoadKg: item.load == null ? null : roundHalf(item.load * loadFactor),
        };
      });
      // P5: Σ(séries × (reps × 4 s + descanso)) + 5 min de aquecimento.
      const seconds = exercises.reduce(
        (total, e) => total + e.sets * (e.repetitions * 4 + e.restSeconds),
        0,
      );
      return {
        id: `${PREFIX}treino-${letter.toLowerCase()}`,
        letter,
        name,
        focus,
        warmupInstructions: '5 minutos de bicicleta ou esteira em ritmo leve.',
        imageUrl: null,
        estimatedMinutes: Math.round(seconds / 60) + 5,
        exercises,
      };
    });

  // Admin
  const adminId = `${PREFIX}${ADMIN.key}`;
  const createdBase = dayOf(today, -200);
  people.push({ uid: adminId, email: ADMIN.email, name: ADMIN.name, type: 'admin' });
  put(`users/${adminId}`, {
    name: ADMIN.name,
    email: ADMIN.email,
    type: 'admin',
    createdAt: iso(createdBase),
    responsable: null,
    onboardingCompleted: true,
  });

  // Unidades, escala e aulas
  const unitIds = UNITS.map((unit) => `${PREFIX}${unit.key}`);
  UNITS.forEach((unit, index) =>
    put(`units/${unitIds[index]}`, {
      name: unit.name,
      address: unit.address,
      active: true,
      createdAt: iso(createdBase),
    }),
  );

  const teacherIds = TEACHERS.map((teacher) => `${PREFIX}${teacher.key}`);
  TEACHERS.forEach((teacher, index) => {
    const email = teacher.email ?? emailOf(teacher.name);
    people.push({ uid: teacherIds[index], email, name: teacher.name, type: 'instructor' });
    put(`users/${teacherIds[index]}`, {
      name: teacher.name,
      email,
      type: 'instructor',
      createdAt: iso(dayOf(createdBase, 5 + index)),
      responsable: adminId,
      onboardingCompleted: true,
      specialty: teacher.specialty,
      studentCapacity: teacher.capacity,
    });
  });

  SHIFTS.forEach(([teacher, unit, weekday, startTime, endTime], index) =>
    put(`instructorShifts/${PREFIX}turno-${pad(index + 1)}`, {
      instructorId: teacherIds[teacher],
      unitId: unitIds[unit],
      weekday,
      startTime,
      endTime,
      createdAt: iso(createdBase),
    }),
  );

  CLASSES.forEach(([name, unit, teacher, weekday, startTime, durationMinutes, capacity], index) =>
    put(`gym_classes/${PREFIX}aula-${pad(index + 1)}`, {
      name,
      unitId: unitIds[unit],
      instructorId: teacherIds[teacher],
      weekday,
      startTime,
      durationMinutes,
      capacity,
      active: true,
      createdAt: iso(createdBase),
    }),
  );

  // Alunos
  let sessionCount = 0;
  STUDENTS.forEach(([name, gender], index) => {
    const studentId = index === 0 ? `${PREFIX}aluno-demonstracao` : `${PREFIX}aluno-${pad(index)}`;
    const email = index === 0 ? 'aluno@demo.com' : emailOf(name);
    const profile = PROFILES[index];
    const remote = REMOTE.has(index);
    const teacherIndex = index === 0 ? 0 : remote ? 3 : index % TEACHERS.length;
    const teacherId = teacherIds[teacherIndex];
    const unitIndex = index === 0 ? 0 : index % UNITS.length;
    const goal = index === 0 ? 'muscleGain' : remote ? 'weightLoss' : random.pick(GOALS);
    const male = gender === 'male';
    const age = random.int(19, 62);
    const heightCm = male ? random.int(168, 190) : random.int(152, 176);
    const startWeight = round1((heightCm / 100) ** 2 * random.int(21, 30));
    const isNew = profile === 'new' || profile === 'newWithoutPlan';
    const createdAt = isNew ? dayOf(today, -random.int(2, 9)) : dayOf(today, -random.int(70, 180));
    const hasConditions = random.chance(0.35);

    people.push({ uid: studentId, email, name, type: 'user' });
    put(`users/${studentId}`, {
      name,
      email,
      type: 'user',
      createdAt: iso(createdAt),
      responsable: teacherId,
      registrationProfile: {
        measurements: { age, heightCm, weightKg: startWeight },
        gender,
        primaryGoal: goal,
        health: {
          conditions: hasConditions ? [random.pick(CONDITIONS)] : ['Nenhuma dor'],
          notes: hasConditions ? 'Liberado pelo médico para treinar com acompanhamento.' : '',
          restrictions: random.chance(0.15) ? ['Asma/Bronquite'] : ['Não possuo'],
        },
        emergencyContact: {
          name: `${random.pick(CONTACT_NAMES)} ${name.split(' ').pop()}`,
          relationship: random.pick(RELATIONSHIPS),
          phone: `(11) 9${random.int(1000, 9999)}-${random.int(1000, 9999)}`,
        },
      },
      onboardingCompleted: true,
      termsAcceptedAt: iso(createdAt),
      unitId: unitIds[unitIndex],
      modality: remote ? 'remote' : 'onSite',
    });

    const studentPath = `users/${studentId}`;
    const loadFactor = (male ? 1.6 : 1) * (0.8 + random.next() * 0.5);

    // Ficha presencial (publicada) ou treino em casa (remotos).
    let plan = null;
    if (profile !== 'newWithoutPlan') {
      const programKey = remote ? 'home' : PROGRAM_BY_GOAL[goal];
      const routines = routinesOf(programKey, loadFactor);
      const schedule =
        index === 0 ? SCHEDULES.showcase : SCHEDULES[routines.length];
      const routineByLetter = Object.fromEntries(routines.map((r) => [r.letter, r]));
      const weeklySchedule = Object.fromEntries(
        Object.entries(schedule).map(([day, letter]) => [
          day,
          letter ? routineByLetter[letter].id : null,
        ]),
      );
      const publishedAt = isNew ? createdAt : dayOf(today, -HISTORY_WEEKS * 7 - 3);
      if (remote) {
        plan = { id: 'home', version: 1, routines, weeklySchedule };
        put(`${studentPath}/homeWorkouts/current`, {
          schemaVersion: 1,
          studentId,
          instructorId: teacherId,
          status: 'published',
          version: 1,
          routines,
          updatedAt: publishedAt,
        });
      } else {
        plan = { id: `${PREFIX}ficha-1`, version: 1, routines, weeklySchedule };
        put(`${studentPath}/trainingPlans/${plan.id}`, {
          schemaVersion: 1,
          id: plan.id,
          studentId,
          instructorId: teacherId,
          name: PLAN_NAME_BY_GOAL[goal],
          version: 1,
          status: 'published',
          routines,
          weeklySchedule,
          createdAt: publishedAt,
          updatedAt: publishedAt,
          publishedAt,
        });
        put(`${studentPath}/trainingState/current`, {
          activePlanId: plan.id,
          instructorId: teacherId,
          updatedAt: publishedAt,
        });
      }
    }

    // Sessoes finalizadas: fonte de presenca, sequencia e inatividade.
    if (plan) {
      const attendance = {
        showcase: 0.92, active: 0.8, irregular: 0.4, risk: 0.65, inactive: 0.6, new: 0.75,
      }[profile];
      const lastDay = {
        showcase: -1, // hoje fica livre para a demonstracao do "Iniciar treino"
        active: 0,
        irregular: 0,
        risk: -random.int(12, 24),
        inactive: -random.int(35, 50),
        new: 0,
      }[profile];
      const firstDay = isNew
        ? Math.round((createdAt - today) / DAY_MS) + 1
        : -HISTORY_WEEKS * 7;
      const preferredHour = random.int(6, 20);

      for (let offset = firstDay; offset <= lastDay; offset++) {
        const day = dayOf(today, offset);
        const routineId = plan.weeklySchedule[weekdayOf(day)];
        if (!routineId || !random.chance(attendance)) continue;
        const routine = plan.routines.find((r) => r.id === routineId);
        const startedAt = new Date(day);
        startedAt.setHours(preferredHour, random.int(0, 50));
        const finishedAt = new Date(
          startedAt.getTime() + (routine.estimatedMinutes + random.int(-8, 12)) * 60000,
        );
        if (finishedAt >= now) continue;
        // Progressao de carga ao longo das semanas.
        const progress = 1 + ((offset - firstDay) / (HISTORY_WEEKS * 7)) * 0.15;
        sessionCount++;
        const sessionId = `${PREFIX}sessao-${String(sessionCount).padStart(4, '0')}`;
        put(`${studentPath}/trainingSessions/${sessionId}`, {
          schemaVersion: 1,
          id: sessionId,
          studentId,
          instructorId: teacherId,
          planId: plan.id,
          planVersion: plan.version,
          routineId: routine.id,
          routineName: routine.name,
          status: 'finished',
          startedAt: iso(startedAt),
          finishedAt: iso(finishedAt),
          warmupDone: random.chance(0.85),
          exercises: routine.exercises.map((item) => ({
            itemId: item.id,
            catalogExerciseId: item.catalogExerciseId,
            name: item.name,
            muscleGroup: item.muscleGroup,
            instructions: item.instructions,
            imageUrl: item.imageUrl,
            repetitions: item.repetitions,
            restSeconds: item.restSeconds,
            technique: item.technique,
            suggestedLoadKg: item.targetLoadKg,
            sets: Array.from({ length: item.sets }, (_, setIndex) => ({
              number: setIndex + 1,
              // A ultima serie as vezes fica para tras; a primeira sempre e feita.
              completed: setIndex === 0 || setIndex < item.sets - 1 || random.chance(0.8),
              loadKg:
                item.targetLoadKg == null
                  ? null
                  : roundHalf(item.targetLoadKg * progress),
            })),
          })),
        });
      }
    }

    // Avaliacoes fisicas (dados de saude ficticios).
    if (!isNew) {
      const count = index === 0 ? 3 : random.int(2, 3);
      const trend = { weightLoss: -2.2, muscleGain: 0.8, strengthening: 0.4, conditioning: -1, mobility: -0.3 }[goal];
      let weight = startWeight;
      const sex = gender === 'male' ? 'male' : 'female';
      const fold = sex === 'male' ? 14 : 20;
      for (let n = 0; n < count; n++) {
        const daysAgo = [130, 70, 12][3 - count + n];
        const date = dayOf(today, -daysAgo);
        date.setHours(9, 0);
        const shrink = goal === 'weightLoss' || goal === 'conditioning' ? n * 1.5 : n * 0.6;
        const skin = (factor) => round1(Math.max(4, fold * factor - shrink + random.next() * 2));
        put(`${studentPath}/evaluations/${PREFIX}avaliacao-${n + 1}`, {
          date,
          instructorId: teacherId,
          sex,
          age,
          weightKg: round1(weight),
          heightCm,
          skinfolds: {
            chest: skin(0.8),
            midaxillary: skin(0.9),
            triceps: skin(1.1),
            subscapular: skin(1),
            abdominal: skin(1.3),
            suprailiac: skin(1.1),
            thigh: skin(1.2),
          },
        });
        weight += trend + (random.next() - 0.5);
      }
    }
  });

  return { people, writes };
}

/** Contagem por colecao, para o resumo da simulacao. */
function summarize(writes) {
  const counts = {};
  for (const { path } of writes) {
    const segments = path.split('/');
    const collection = segments[segments.length - 2];
    counts[collection] = (counts[collection] ?? 0) + 1;
  }
  return counts;
}

// ── Execucao ─────────────────────────────────────────────────────────────

const DEMO_COLLECTIONS = ['users', 'units', 'instructorShifts', 'gym_classes'];

/** Documentos raiz com ID `demo-*` (as subcolecoes vao junto no recursiveDelete). */
async function findDemoDocs(db, admin) {
  const refs = [];
  for (const name of DEMO_COLLECTIONS) {
    const snapshot = await db
      .collection(name)
      .where(admin.firestore.FieldPath.documentId(), '>=', PREFIX)
      .where(admin.firestore.FieldPath.documentId(), '<', `${PREFIX}`)
      .get();
    refs.push(...snapshot.docs.map((doc) => doc.ref));
  }
  return refs;
}

async function loadCatalog(db) {
  const catalog = {};
  for (const base of Object.values(EXERCISES)) {
    const key = normalize(base.name);
    const snapshot = await db
      .collection('exerciseCatalog')
      .where('nameNormalized', '==', key)
      .limit(1)
      .get();
    if (!snapshot.empty) {
      const doc = snapshot.docs[0];
      catalog[key] = { id: doc.id, imageUrl: doc.data().imageUrl || null };
    }
  }
  return catalog;
}

async function main() {
  const args = process.argv.slice(2);
  const apply = args.includes('--apply');
  const clean = args.includes('--limpar');
  const projectArg = args.find((value) => value.startsWith('--project='));
  const project = projectArg?.split('=')[1] ?? PROJECT_ID;
  if (project !== PROJECT_ID) {
    throw new Error(`Operação bloqueada: permitido apenas ${PROJECT_ID}.`);
  }

  if (!apply) {
    const { people, writes } = buildDemoData({ now: new Date() });
    console.log(`Projeto: ${project}`);
    if (clean) {
      console.log('SIMULAÇÃO DA LIMPEZA: apagaria os documentos e contas com ID demo-*.');
      console.log(`Contas de demonstração conhecidas: ${people.length}`);
    } else {
      console.log(`Contas de login: ${people.length}`);
      console.table(people.map(({ name, email, type }) => ({ name, email, type })));
      console.table(summarize(writes));
    }
    console.log('SIMULAÇÃO CONCLUÍDA. Nada foi enviado ao Firebase.');
    return;
  }

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error('Defina GOOGLE_APPLICATION_CREDENTIALS com um JSON de conta de serviço LOCAL. Nunca envie essa chave no chat ou para o Git.');
  }
  const password = process.env.SENHA_DEMO ?? '';
  if (!clean && password.length < 6) {
    throw new Error('Defina SENHA_DEMO com a senha das contas de demonstração (mínimo de 6 caracteres).');
  }

  const admin = require('firebase-admin');
  admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: project });
  const db = admin.firestore();
  const auth = admin.auth();

  const catalog = clean ? {} : await loadCatalog(db);
  const { people, writes } = buildDemoData({ now: new Date(), catalog });

  // Nunca sobrescreve uma conta real: e-mail em uso por outro UID para tudo.
  if (!clean) {
    const conflicts = [];
    for (const person of people) {
      try {
        const existing = await auth.getUserByEmail(person.email);
        if (existing.uid !== person.uid) conflicts.push(`${person.email} (UID ${existing.uid})`);
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
    }
    if (conflicts.length > 0) {
      throw new Error(
        'Estes e-mails já pertencem a contas que não são de demonstração. ' +
          `Apague-as no Console (Authentication) e rode de novo:\n  ${conflicts.join('\n  ')}`,
      );
    }
  }

  // Remove o que houver de demo-* para recomeçar limpo (inclui subcoleções).
  const old = await findDemoDocs(db, admin);
  for (const ref of old) await db.recursiveDelete(ref);
  console.log(`Documentos demo-* removidos: ${old.length}`);

  if (clean) {
    let removed = 0;
    for (const person of people) {
      try {
        await auth.deleteUser(person.uid);
        removed++;
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
    }
    console.log(`Contas de demonstração removidas: ${removed}`);
    console.log('LIMPEZA CONCLUÍDA.');
    return;
  }

  for (const person of people) {
    const data = { email: person.email, password, displayName: person.name };
    try {
      await auth.updateUser(person.uid, data);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
      await auth.createUser({ uid: person.uid, ...data });
    }
  }
  console.log(`Contas de login prontas: ${people.length}`);

  const writer = db.bulkWriter();
  for (const { path, data } of writes) writer.set(db.doc(path), data);
  await writer.close();
  console.table(summarize(writes));
  console.log(`Exercícios ligados ao catálogo: ${Object.keys(catalog).length}/${Object.keys(EXERCISES).length}`);
  console.log('CONCLUÍDO. Entre com admin@demo.com, prof@demo.com ou aluno@demo.com.');
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}

module.exports = { buildDemoData, normalize, summarize, weekdayOf, SHIFTS, PREFIX };

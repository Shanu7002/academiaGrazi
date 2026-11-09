/**
 * Importacao idempotente, executada SOMENTE na maquina do proprietario.
 * Nenhuma credencial ou imagem da fonte e incluida neste pacote.
 * Fonte: https://exercise-dataset.com/exercises.json (RepDB free tier).
 * Licenca: https://github.com/RepDB/exercise-dataset/blob/main/LICENSE-DATA.md
 */
'use strict';

const SOURCE_URL = 'https://exercise-dataset.com/exercises.json';
const PROJECT_ID = 'academia-grazi-dev-ab105';
const apply = process.argv.includes('--apply');
const projectArg = process.argv.find((value) => value.startsWith('--project='));
const project = projectArg?.split('=')[1] ?? PROJECT_ID;
const namesPt = {
  'barbell-bench-press': 'Supino Reto com Barra',
  'bench-press': 'Supino Reto',
  'dumbbell-bench-press': 'Supino Reto com Halteres',
  'incline-bench-press': 'Supino Inclinado',
  'incline-dumbbell-press': 'Supino Inclinado com Halteres',
  'dumbbell-fly': 'Crucifixo com Halteres',
  'cable-fly': 'Crucifixo na Polia',
  'push-up': 'Flexao de Bracos',
  'barbell-squat': 'Agachamento Livre',
  'back-squat': 'Agachamento Livre',
  'goblet-squat': 'Agachamento Goblet',
  'front-squat': 'Agachamento Frontal',
  'bulgarian-split-squat': 'Agachamento Bulgaro',
  'leg-press': 'Leg Press',
  'leg-extension': 'Cadeira Extensora',
  'leg-curl': 'Mesa Flexora',
  'romanian-deadlift': 'Stiff / Terra Romeno',
  'deadlift': 'Levantamento Terra',
  'hip-thrust': 'Elevacao Pelvica',
  'glute-bridge': 'Ponte de Gluteos',
  'walking-lunge': 'Avanco Caminhando',
  'lunge': 'Avanco',
  'lat-pulldown': 'Puxada Frontal',
  'seated-cable-row': 'Remada Baixa',
  'barbell-row': 'Remada Curvada',
  'one-arm-dumbbell-row': 'Remada Unilateral',
  'pull-up': 'Barra Fixa',
  'chin-up': 'Barra Fixa Supinada',
  'face-pull': 'Face Pull',
  'lateral-raise': 'Elevacao Lateral',
  'front-raise': 'Elevacao Frontal',
  'shoulder-press': 'Desenvolvimento de Ombros',
  'overhead-press': 'Desenvolvimento Militar',
  'arnold-press': 'Desenvolvimento Arnold',
  'shrug': 'Encolhimento de Ombros',
  'barbell-curl': 'Rosca Direta',
  'dumbbell-curl': 'Rosca com Halteres',
  'hammer-curl': 'Rosca Martelo',
  'preacher-curl': 'Rosca Scott',
  'triceps-pushdown': 'Triceps na Polia',
  'triceps-dip': 'Mergulho para Triceps',
  'skull-crusher': 'Triceps Testa',
  'plank': 'Prancha',
  'side-plank': 'Prancha Lateral',
  'crunch': 'Abdominal Crunch',
  'sit-up': 'Abdominal Tradicional',
  'russian-twist': 'Rotacao Russa',
  'mountain-climber': 'Escalador',
  'jumping-jack': 'Polichinelo',
  'jump-rope': 'Pular Corda',
  'burpee': 'Burpee',
  'calf-raise': 'Elevacao de Panturrilhas',
  'standing-calf-raise': 'Panturrilha em Pe',
  'seated-calf-raise': 'Panturrilha Sentado',
};
const groups = {
  chest: 'Peito', back: 'Costas', shoulders: 'Ombros', arms: 'Bracos',
  upper_arms: 'Bracos', forearms: 'Antebracos', upper_legs: 'Pernas',
  lower_legs: 'Panturrilhas', legs: 'Pernas', glutes: 'Gluteos',
  hips: 'Quadril', core: 'Abdomen', abs: 'Abdomen', abdominal: 'Abdomen',
  cardio: 'Cardio', full_body: 'Corpo inteiro', neck: 'Pescoco',
};
function normalize(str) {
  return String(str ?? '').normalize('NFD').replace(/[\u0300-\u036f]/g, '')
    .trim().replace(/\s+/g, ' ').toLowerCase();
}
function httpsImage(path) {
  return (typeof path === 'string' && path.startsWith('images/flat/'))
    ? `https://exercise-dataset.com/${path}` : '';
}
function transform(ex) {
  const pictures = ex.images?.flat ?? {};
  const name = namesPt[ex.id] ?? ex.name_en;
  const group = groups[ex.body_part] ?? ex.body_part?.replaceAll('_', ' ') ?? 'Geral';
  return {
    name,
    nameNormalized: normalize(name),
    nameEnglish: ex.name_en ?? '',
    muscleGroup: group,
    instructions: Array.isArray(ex.instructions_en)
      ? ex.instructions_en.join('\n') : '',
    imageUrl: httpsImage(pictures.start ?? pictures.main ?? pictures.peak),
    imageUrlPeak: httpsImage(pictures.peak),
    source: 'repdb-free',
    sourceId: ex.id,
    licenseUrl: 'https://github.com/RepDB/exercise-dataset/blob/main/LICENSE-DATA.md',
    sourceUrl: `https://exercise-dataset.com/exercise/${encodeURIComponent(ex.id)}/`,
    difficulty: ex.difficulty ?? '',
    equipment: ex.equipment ?? '',
    primaryMuscles: ex.primary_muscles ?? [],
  };
}
/**
 * Reimportar a base pode atualizar fotos/metadados, mas nunca desfazer
 * nomes revisados editorialmente (v6) ou uma traducao registrada.
 * O nome PT-BR pode existir sem instructions PT-BR: preservar em separado.
 */
function prepareWriteData(incoming, saved) {
  const data = { ...incoming };
  const editorialName = [
    'editorial_pending_review', 'editorial_approved', 'reviewed',
  ].includes(saved?.nameReviewStatus);
  if (saved?.language === 'pt-BR' || editorialName) {
    delete data.name;
    delete data.nameNormalized;
  }
  if (saved?.language === 'pt-BR') {
    delete data.instructions;
  }
  return data;
}

async function main() {
  if (project !== PROJECT_ID) {
    throw new Error(`Operacao bloqueada: permitido apenas ${PROJECT_ID}.`);
  }
  const response = await fetch(SOURCE_URL, { signal: AbortSignal.timeout(30000) });
  if (!response.ok) throw new Error(`Falha no download: HTTP ${response.status}`);
  const source = await response.json();
  if (!Array.isArray(source.exercises) || source.exercises.length < 200) {
    throw new Error('Base incompleta. Nada foi gravado.');
  }
  const entries = source.exercises.map((ex) => ({
    id: `repdb-${ex.id}`,
    data: transform(ex),
  }));
  const withImages = entries.filter((e) => e.data.imageUrl).length;
  console.log(`Projeto: ${project}`);
  console.log(`Fonte: ${SOURCE_URL}`);
  console.log(`Exercicios: ${entries.length} | com ilustracao: ${withImages}`);
  console.log(`Exemplo: ${entries.find((e) => e.data.imageUrl)?.data.name}`);
  if (!apply) {
    console.log('SIMULACAO CONCLUIDA. Nenhum dado foi enviado ao Firebase.');
    console.log('Para gravar: npm run importar:dev (apos configurar credenciais locais).');
    return;
  }
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error('Defina GOOGLE_APPLICATION_CREDENTIALS com um JSON de conta de servico LOCAL. Nunca envie essa chave no chat ou para o Git.');
  }
  const admin = require('firebase-admin');
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: project,
  });
  const db = admin.firestore();
  // Firestore batch: 250 escritas por lote, merge = reexecutavel.
  let imported = 0;
  for (let offset = 0; offset < entries.length; offset += 250) {
    const batch = db.batch();
    const chunk = entries.slice(offset, offset + 250);
    const refs = chunk.map((entry) => db.collection('exerciseCatalog').doc(entry.id));
    const existing = await db.getAll(...refs);
    for (const [index, entry] of chunk.entries()) {
      const data = prepareWriteData(entry.data, existing[index].data());
      batch.set(refs[index], {
        ...data,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();
    imported += chunk.length;
    console.log(`Gravados: ${imported}/${entries.length}`);
  }
  console.log(`CONCLUIDO: ${imported} exercicios no Firestore DEV.`);
  console.log('LICENCA: incluir credito visivel RepDB (repdb.co) no app.');
}
if (require.main === module) {
  main().catch((error) => { console.error(error.message); process.exitCode = 1; });
}

// Permite executar testes de regressao sem realizar rede nem conectar Firebase.
module.exports = { prepareWriteData, transform };

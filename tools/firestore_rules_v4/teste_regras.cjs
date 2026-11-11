// Testa APENAS o emulador (projeto demo-grazi-local). Nao usa Firebase real.
const fs = require('node:fs');
const assert = require('node:assert/strict');
const { initializeTestEnvironment, assertFails, assertSucceeds } = require('@firebase/rules-unit-testing');
const {
  doc, collection, collectionGroup, query, where, getDoc, getDocs,
  setDoc, updateDoc, deleteDoc, writeBatch, serverTimestamp
} = require('firebase/firestore');

async function main() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('ABORTADO: emulador Firestore ausente; nunca rode estes testes contra a nuvem.');
  }
  const env = await initializeTestEnvironment({
    projectId: 'demo-grazi-local',
    firestore: { rules: fs.readFileSync(require('node:path').resolve(__dirname, '..', '..', 'firestore.rules'), 'utf8') },
  });
  let passed = 0;
  const test = async (name, action) => {
    await action();
    passed += 1;
    console.log(`OK ${passed}: ${name}`);
  };
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async ctx => {
      const db = ctx.firestore();
      await Promise.all([
        setDoc(doc(db, 'users/prof1'), {name:'Prof 1',email:'prof1@test.com.br', type:'instructor'}),
        setDoc(doc(db, 'users/prof2'), {name:'Prof 2',email:'prof2@test.com.br', type:'instructor'}),
        setDoc(doc(db, 'users/aluno1'), {name:'Aluno 1',email:'aluno1@test.com.br',type:'user',responsable:'prof1'}),
        setDoc(doc(db, 'users/aluno2'), {name:'Aluno 2',email:'aluno2@test.com.br',type:'user',responsable:'prof2'}),
        setDoc(doc(db, 'users/admin1'), {name:'Admin',email:'admin@test.com.br',type:'admin'}),
        setDoc(doc(db, 'gym_classes/aula1'), {name:'Pilates'}),
        setDoc(doc(db, 'instructorCodes/1234'), {active:true,instructorId:'prof1',instructorName:'Prof 1',createdAt:serverTimestamp(),expiresAtMillis:Date.now()+600000}),
      ]);
    });
    const d = uid => env.authenticatedContext(uid).firestore();
    const prof1=d('prof1'), prof2=d('prof2'), aluno1=d('aluno1'), aluno2=d('aluno2'), admin=d('admin1'), anon=env.unauthenticatedContext().firestore();
    const user=(db,id)=>doc(db,'users',id);
    const plan=(db,id='ficha1')=>doc(db,'users','aluno1','trainingPlans',id);
    const state=db=>doc(db,'users','aluno1','trainingState','current');
    const session=(db,id='sessao1')=>doc(db,'users','aluno1','trainingSessions',id);
    const draft=(id='ficha1')=>({ schemaVersion:1, id, studentId:'aluno1', instructorId:'prof1',name:'Treino A',version:1,status:'draft',routines:[],weeklySchedule:{},createdAt:serverTimestamp(),updatedAt:serverTimestamp() });
    const exercise=[{id:'supino',sets:[{weight:20,completed:false}]}];

    await test('professor vinculado le o aluno',()=>assertSucceeds(getDoc(user(prof1,'aluno1'))));
    await test('professor alheio nao le o aluno',()=>assertFails(getDoc(user(prof2,'aluno1'))));
    await test('aluno le seu professor',()=>assertSucceeds(getDoc(user(aluno1,'prof1'))));
    await test('aluno nao le outro aluno',()=>assertFails(getDoc(user(aluno1,'aluno2'))));
    await test('nao autenticado nao le usuarios',()=>assertFails(getDoc(user(anon,'aluno1'))));
    await test('admin pode ler aluno',()=>assertSucceeds(getDoc(user(admin,'aluno1'))));
    await test('professor lista apenas seus alunos por responsable',()=>assertSucceeds(getDocs(query(collection(prof1,'users'),where('responsable','==','prof1')))));
    await test('professor nao pode listar toda a colecao users',()=>assertFails(getDocs(collection(prof1,'users'))));
    await test('aluno edita proprio nome',()=>assertSucceeds(updateDoc(user(aluno1,'aluno1'),{name:'Aluno de teste'})));
    await test('aluno nao promove a admin',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{type:'admin'})));
    await test('aluno nao troca de professor por conta propria',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{responsable:'prof2'})));
    await test('aluno nao altera email arbitrariamente',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{email:'outro@test.com.br'})));
    await test('aluno nao cria propria conta como admin',()=>assertFails(setDoc(user(d('novoAdmin'),'novoAdmin'),{name:'Novo Admin',type:'admin',responsable:'prof1'})));
    await test('autocadastro de aluno com instrutor valido e permitido',()=>assertSucceeds(setDoc(user(d('novoAluno'),'novoAluno'),{name:'Novo Aluno',email:'novo@test.com.br',type:'user',responsable:'prof1'})));
    await test('aluno nao pode editar perfil do professor',()=>assertFails(updateDoc(user(aluno1,'prof1'),{name:'Hack'})));
    // GB-003: createdAt imutavel; unidade/modalidade e especialidade/capacidade.
    await test('aluno nao altera o proprio createdAt',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{createdAt:'2020-01-01T00:00:00.000Z'})));
    await test('aluno nao define a propria modalidade',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{modality:'remote'})));
    await test('professor responsavel define unidade e modalidade do aluno',()=>assertSucceeds(updateDoc(user(prof1,'aluno1'),{unitId:'unidade1',modality:'remote'})));
    await test('professor alheio nao define modalidade do aluno',()=>assertFails(updateDoc(user(prof2,'aluno1'),{modality:'onSite'})));
    await test('modalidade invalida e recusada',()=>assertFails(updateDoc(user(prof1,'aluno1'),{modality:'hibrido'})));
    await test('professor nao altera outros campos do aluno junto com a modalidade',()=>assertFails(updateDoc(user(prof1,'aluno1'),{modality:'onSite',name:'Outro'})));
    await test('admin define modalidade do aluno',()=>assertSucceeds(updateDoc(user(admin,'aluno1'),{modality:'onSite'})));
    await test('admin define especialidade e capacidade do professor',()=>assertSucceeds(updateDoc(user(admin,'prof1'),{specialty:'Musculacao',studentCapacity:30})));
    await test('professor nao define a propria capacidade',()=>assertFails(updateDoc(user(prof1,'prof1'),{studentCapacity:100})));
    await test('capacidade zero e recusada',()=>assertFails(updateDoc(user(admin,'prof1'),{studentCapacity:0})));
    await test('especialidade nao e definida em aluno',()=>assertFails(updateDoc(user(admin,'aluno1'),{specialty:'Musculacao'})));
    await test('aula pode ser lida apos login',()=>assertSucceeds(getDoc(doc(aluno1,'gym_classes/aula1'))));
    await test('aluno nao pode editar aula',()=>assertFails(updateDoc(doc(aluno1,'gym_classes/aula1'),{name:'Outra'})));
    await test('codigo publico conhecido pode ser consultado',()=>assertSucceeds(getDoc(doc(anon,'instructorCodes/1234'))));
    await test('codigos de convite nao podem ser listados',()=>assertFails(getDocs(collection(anon,'instructorCodes'))));
    await test('professor pode emitir codigo valido',()=>assertSucceeds(setDoc(doc(prof1,'instructorCodes/5678'),{instructorId:'prof1',instructorName:'Prof 1',active:true,createdAt:serverTimestamp(),expiresAtMillis:Date.now()+600000})));
    await test('aluno nao pode emitir codigo para professor',()=>assertFails(setDoc(doc(aluno1,'instructorCodes/5555'),{instructorId:'prof1',instructorName:'Prof 1',active:true,createdAt:serverTimestamp(),expiresAtMillis:Date.now()+600000})));
    // Renovacao do codigo no perfil do professor (mesma transacao do app).
    const renovarCodigo=(db,instructorId,code)=>{
      const batch=writeBatch(db);
      batch.update(user(db,instructorId),{registrationCode:code,registrationCodeExpiresAt:new Date(Date.now()+900000).toISOString()});
      batch.set(doc(db,'instructorCodes',code),{instructorId,instructorName:'Prof',active:true,createdAt:new Date().toISOString(),expiresAtMillis:Date.now()+900000});
      return batch.commit();
    };
    await test('professor renova o proprio codigo de convite',()=>assertSucceeds(renovarCodigo(prof1,'prof1','4321')));
    await test('admin renova o codigo de convite do professor',()=>assertSucceeds(renovarCodigo(admin,'prof2','8765')));
    await test('professor nao grava codigo sem emiti-lo',()=>assertFails(updateDoc(user(prof1,'prof1'),{registrationCode:'9999',registrationCodeExpiresAt:new Date().toISOString()})));
    await test('professor nao grava no perfil codigo de outro professor',()=>assertFails(updateDoc(user(prof1,'prof1'),{registrationCode:'8765',registrationCodeExpiresAt:new Date().toISOString()})));
    await test('professor nao renova codigo de outro professor',()=>assertFails(renovarCodigo(prof1,'prof2','2468')));
    await test('aluno nao grava codigo de convite no proprio perfil',()=>assertFails(updateDoc(user(aluno1,'aluno1'),{registrationCode:'1234',registrationCodeExpiresAt:new Date().toISOString()})));
    await test('professor nao altera o tipo junto com o codigo',()=>assertFails(updateDoc(user(prof1,'prof1'),{registrationCode:'4321',type:'admin'})));

    // GB-080: consulta de grupo das sessoes, so para o admin.
    const sessoesFinalizadas=db=>getDocs(query(collectionGroup(db,'trainingSessions'),where('status','==','finished'),where('finishedAt','>=','2026-01-01T00:00:00.000Z')));
    await test('admin consulta as sessoes de todos os alunos',()=>assertSucceeds(sessoesFinalizadas(admin)));
    await test('professor nao consulta sessoes de todos os alunos',()=>assertFails(sessoesFinalizadas(prof1)));
    await test('aluno nao consulta sessoes de todos os alunos',()=>assertFails(sessoesFinalizadas(aluno1)));

    // GB-040: unidades e escala. Qualquer autenticado le; so o admin grava.
    const unidade=(extra={})=>({name:'Bloco A',active:true,createdAt:'2026-11-11T12:00:00.000Z',...extra});
    const turno=(extra={})=>({instructorId:'prof1',unitId:'blocoA',weekday:1,startTime:'07:00',endTime:'11:00',createdAt:'2026-11-11T12:00:00.000Z',...extra});
    await test('admin cria unidade',()=>assertSucceeds(setDoc(doc(admin,'units/blocoA'),unidade({address:'Rua 1'}))));
    await test('aluno le unidades',()=>assertSucceeds(getDoc(doc(aluno1,'units/blocoA'))));
    await test('nao autenticado nao le unidades',()=>assertFails(getDoc(doc(anon,'units/blocoA'))));
    await test('professor nao cria unidade',()=>assertFails(setDoc(doc(prof1,'units/blocoB'),unidade())));
    await test('unidade com campo desconhecido e recusada',()=>assertFails(setDoc(doc(admin,'units/blocoC'),unidade({lotacao:30}))));
    await test('admin desativa unidade',()=>assertSucceeds(updateDoc(doc(admin,'units/blocoA'),{active:false})));
    await test('admin nao reescreve createdAt da unidade',()=>assertFails(updateDoc(doc(admin,'units/blocoA'),{createdAt:'2020-01-01T00:00:00.000Z'})));
    await test('unidade nao e apagada, nem pelo admin',()=>assertFails(deleteDoc(doc(admin,'units/blocoA'))));
    await test('admin cria turno da escala',()=>assertSucceeds(setDoc(doc(admin,'instructorShifts/t1'),turno())));
    await test('professor le a escala',()=>assertSucceeds(getDoc(doc(prof1,'instructorShifts/t1'))));
    await test('aluno le a escala',()=>assertSucceeds(getDoc(doc(aluno1,'instructorShifts/t1'))));
    await test('professor nao cria o proprio turno',()=>assertFails(setDoc(doc(prof1,'instructorShifts/t2'),turno())));
    await test('turno em unidade inexistente e recusado',()=>assertFails(setDoc(doc(admin,'instructorShifts/t3'),turno({unitId:'naoExiste'}))));
    await test('turno para quem nao e professor e recusado',()=>assertFails(setDoc(doc(admin,'instructorShifts/t4'),turno({instructorId:'aluno1'}))));
    await test('turno com inicio depois do fim e recusado',()=>assertFails(setDoc(doc(admin,'instructorShifts/t5'),turno({startTime:'12:00'}))));
    await test('turno com dia da semana invalido e recusado',()=>assertFails(setDoc(doc(admin,'instructorShifts/t6'),turno({weekday:8}))));
    await test('turno com horario fora do formato e recusado',()=>assertFails(setDoc(doc(admin,'instructorShifts/t7'),turno({endTime:'24:00'}))));
    await test('professor nao apaga turno',()=>assertFails(deleteDoc(doc(prof1,'instructorShifts/t1'))));
    await test('admin apaga turno',()=>assertSucceeds(deleteDoc(doc(admin,'instructorShifts/t1'))));

    await test('professor vinculado cria rascunho',()=>assertSucceeds(setDoc(plan(prof1),draft())));
    await test('professor alheio nao cria rascunho',()=>assertFails(setDoc(plan(prof2,'outra'),draft('outra'))));
    await test('aluno nao cria ficha por conta propria',()=>assertFails(setDoc(plan(aluno1,'aluno-criou'),draft('aluno-criou'))));
    await test('professor consulta rascunho',()=>assertSucceeds(getDoc(plan(prof1))));
    await test('aluno nao consegue consultar rascunho',()=>assertFails(getDoc(plan(aluno1))));
    await test('aluno pode pesquisar fichas publicadas, sem acessar rascunhos',()=>assertSucceeds(getDocs(query(collection(aluno1,'users/aluno1/trainingPlans'),where('status','==','published')))));
    await test('aluno nao pode consultar todas as fichas sem filtro',()=>assertFails(getDocs(collection(aluno1,'users/aluno1/trainingPlans'))));
    await test('professor vinculado pode atualizar versao do rascunho',()=>assertSucceeds(updateDoc(plan(prof1),{name:'Treino A atualizado',version:2,updatedAt:serverTimestamp()})));
    await test('professor nao pode publicar sem transacao com trainingState',()=>assertFails(updateDoc(plan(prof1),{status:'published',publishedAt:serverTimestamp(),updatedAt:serverTimestamp()})));
    await test('professor publica ficha e ponteiro current na mesma transacao',async()=>{
      const batch=writeBatch(prof1);
      batch.update(plan(prof1),{status:'published',routines:[{id:'A'}],weeklySchedule:{monday:'A'},publishedAt:serverTimestamp(),updatedAt:serverTimestamp()});
      // Em publicacao, alterar routines/weeklySchedule NAO e permitido pela regra.
      // Por isso esse primeiro batch somente verifica que essa operacao seria negada.
      await assertFails(batch.commit());
      // Primeiro atualiza rascunho com a estrutura final, incrementando a versao.
      await assertSucceeds(updateDoc(plan(prof1),{routines:[{id:'A',name:'Treino A',exercises:[{id:'supino'}]}],weeklySchedule:{monday:'A'},version:3,updatedAt:serverTimestamp()}));
      const publish=writeBatch(prof1);
      publish.update(plan(prof1),{status:'published',publishedAt:serverTimestamp(),updatedAt:serverTimestamp()});
      publish.set(state(prof1),{activePlanId:'ficha1',instructorId:'prof1',updatedAt:serverTimestamp()});
      await assertSucceeds(publish.commit());
    });
    await test('aluno pode ler ficha publicada',()=>assertSucceeds(getDoc(plan(aluno1))));
    await test('aluno pode ler ponteiro current',()=>assertSucceeds(getDoc(state(aluno1))));
    await test('professor alheio nao pode ler ficha',()=>assertFails(getDoc(plan(prof2))));
    await test('aluno nao pode substituir ficha publicada',()=>assertFails(updateDoc(plan(aluno1),{name:'Tentativa'})));
    await test('professor nao pode mudar ficha publicada',()=>assertFails(updateDoc(plan(prof1),{name:'Mudanca depois de publicada'})));

    await test('aluno inicia sessao de treino publicada',()=>assertSucceeds(setDoc(session(aluno1),{
      schemaVersion:1,id:'sessao1',studentId:'aluno1',instructorId:'prof1',planId:'ficha1',planVersion:3,routineId:'A',routineName:'Treino A',status:'inProgress',startedAt:new Date().toISOString(),warmupDone:false,exercises:exercise,createdAt:serverTimestamp(),updatedAt:serverTimestamp()
    })));
    await test('professor vinculado acompanha sessao',()=>assertSucceeds(getDoc(session(prof1))));
    await test('professor alheio nao pode ler sessao',()=>assertFails(getDoc(session(prof2))));
    await test('aluno finaliza sessao',()=>assertSucceeds(updateDoc(session(aluno1),{status:'finished',warmupDone:true,finishedAt:new Date().toISOString(),exercises:[{id:'supino',sets:[{weight:20,completed:true}]}],updatedAt:serverTimestamp()})));
    await test('aluno nao reabre sessao finalizada',()=>assertFails(updateDoc(session(aluno1),{status:'inProgress',updatedAt:serverTimestamp()})));
    await test('professor nao altera sessao do aluno',()=>assertFails(updateDoc(session(prof1),{warmupDone:false,updatedAt:serverTimestamp()})));
    await test('aluno nao edita sessao de outro aluno',()=>assertFails(updateDoc(doc(aluno2,'users/aluno1/trainingSessions/sessao1'),{warmupDone:false,updatedAt:serverTimestamp()})));
    // Testes adicionais da biblioteca de exercicios e treinos reutilizaveis.
    const exerciseCatalog = (db, id) => doc(db, 'exerciseCatalog', id);
    const newManualExercise = () => ({
      name: 'Remada Curvada', nameNormalized: 'remada curvada',
      muscleGroup: 'Costas', instructions: 'Coluna neutra', imageUrl: '',
      source: 'manual', createdBy: 'prof1',
      createdAt: serverTimestamp(), updatedAt: serverTimestamp(),
    });
    await test('professor cadastra exercicio na biblioteca', () =>
      assertSucceeds(setDoc(exerciseCatalog(prof1, 'manual1'), newManualExercise())));
    await test('aluno nao pode cadastrar exercicio na biblioteca', () =>
      assertFails(setDoc(exerciseCatalog(aluno1, 'manual2'), newManualExercise())));
    await test('aluno autenticado pode consultar biblioteca', () =>
      assertSucceeds(getDoc(exerciseCatalog(aluno1, 'manual1'))));
    await test('nao autenticado nao consulta biblioteca', () =>
      assertFails(getDoc(exerciseCatalog(anon, 'manual1'))));
    await test('outro professor nao altera exercicio manual alheio', () =>
      assertFails(updateDoc(exerciseCatalog(prof2, 'manual1'), {
        imageUrl: 'https://example.org/pic.jpg', updatedAt: serverTimestamp(),
      })));
    await test('professor altera foto de seu exercicio', () =>
      assertSucceeds(updateDoc(exerciseCatalog(prof1, 'manual1'), {
        imageUrl: 'https://example.org/pic.jpg', updatedAt: serverTimestamp(),
      })));
    const templateRef = (db, owner) =>
      doc(db, 'users', owner, 'routineTemplates', 'aluno1_treino-a');
    const templateData = () => ({
      teacherId: 'prof1', studentId: 'aluno1', name: 'Treino A',
      nameNormalized: 'treino a',
      routine: {id:'treino-a', letter:'A', name:'Treino A',
        imageUrl:'https://example.org/treino.jpg', exercises:[]},
      updatedAt: serverTimestamp(),
    });
    await test('professor cria modelo reutilizavel privado', () =>
      assertSucceeds(setDoc(templateRef(prof1, 'prof1'), templateData())));
    await test('professor le seu modelo reutilizavel', () =>
      assertSucceeds(getDoc(templateRef(prof1, 'prof1'))));
    await test('outro professor nao le modelo alheio', () =>
      assertFails(getDoc(templateRef(prof2, 'prof1'))));
    await test('aluno nao le modelos privados do professor', () =>
      assertFails(getDoc(templateRef(aluno1, 'prof1'))));
    // Remocao da atribuicao atual. As fichas historicas continuam imutaveis.
    await test('professor cria montagem para excluir depois', () =>
      assertSucceeds(setDoc(plan(prof1, 'rascunho-remocao'), draft('rascunho-remocao'))));
    await test('outro professor nao exclui montagem', () =>
      assertFails(deleteDoc(plan(prof2, 'rascunho-remocao'))));
    await test('aluno nao exclui montagem', () =>
      assertFails(deleteDoc(plan(aluno1, 'rascunho-remocao'))));
    await test('professor vinculado exclui montagem nao publicada', () =>
      assertSucceeds(deleteDoc(plan(prof1, 'rascunho-remocao'))));
    await test('aluno nao exclui a ficha ativa', () =>
      assertFails(deleteDoc(state(aluno1))));
    await test('professor nao vinculado nao exclui ficha ativa', () =>
      assertFails(deleteDoc(state(prof2))));
    await test('professor vinculado exclui atribuicao ativa', () =>
      assertSucceeds(deleteDoc(state(prof1))));
    await test('ficha historica publicada continua consultavel', () =>
      assertSucceeds(getDoc(plan(prof1))));
    await test('aluno nao inicia sessao depois da exclusao da ficha', () =>
      assertFails(setDoc(session(aluno1, 'apos-exclusao'), {
        schemaVersion:1,id:'apos-exclusao',studentId:'aluno1',instructorId:'prof1',planId:'ficha1',planVersion:3,
        routineId:'A',routineName:'Treino A',status:'inProgress',startedAt:new Date().toISOString(),
        warmupDone:false,exercises:exercise,createdAt:serverTimestamp(),updatedAt:serverTimestamp()
      })));
    console.log(`\nSUCESSO: ${passed} verificacoes concluídas (somente no emulador).`);
  } finally {
    await env.cleanup();
  }
}
main().catch(error=>{console.error('FALHA NOS TESTES DE REGRAS:',error);process.exitCode=1;});

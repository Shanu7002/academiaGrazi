// Somente emulador local; a ID demo-grazi-local nao tem Firebase real.
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertFails, assertSucceeds } =
  require('@firebase/rules-unit-testing');
const { doc, getDoc, getDocs, collection, setDoc, updateDoc,
  deleteDoc, serverTimestamp } = require('firebase/firestore');

async function run() {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    throw new Error('ABORTADO: FIRESTORE_EMULATOR_HOST ausente.');
  }
  const env = await initializeTestEnvironment({
    projectId: 'demo-grazi-local',
    firestore: {rules: fs.readFileSync(path.resolve(__dirname,'..','..','firestore.rules'),'utf8')},
  });
  let ok=0;
  async function test(label, action) {await action(); ok++; console.log(`OK CASA ${ok}: ${label}`);}
  try {
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async context => {
      const db=context.firestore();
      await setDoc(doc(db,'users/prof1'),{name:'Prof 1',type:'instructor'});
      await setDoc(doc(db,'users/prof2'),{name:'Prof 2',type:'instructor'});
      await setDoc(doc(db,'users/aluno1'),{name:'Aluno 1',type:'user',responsable:'prof1'});
      await setDoc(doc(db,'users/aluno2'),{name:'Aluno 2',type:'user',responsable:'prof2'});
    });
    const db=(uid)=>env.authenticatedContext(uid).firestore();
    const p1=db('prof1'),p2=db('prof2'),student=db('aluno1'),other=db('aluno2'),
      guest=env.unauthenticatedContext().firestore();
    const home=(d)=>doc(d,'users/aluno1/homeWorkouts/current');
    const payload=(version)=>({schemaVersion:1,studentId:'aluno1',instructorId:'prof1',
      status:'published',version,routines:[{id:'casa-a',letter:'A',name:'Casa A',
        focus:'Mobilidade',warmupInstructions:'Caminhada leve',estimatedMinutes:20,
        exercises:[{id:'item1',catalogExerciseId:'manual-x',name:'Agachamento',
          muscleGroup:'Pernas',instructions:'Mantenha o tronco alinhado.',sets:3,
          repetitions:10,restSeconds:60,technique:'Tradicional'}]}],updatedAt:serverTimestamp()});
    await test('sem cadastro nao ha documento',async()=>{
      const got=await getDoc(home(student));
      if(got.exists()) throw new Error('Prescricao apareceu sem professor publicar');
    });
    await test('professor vinculado publica',()=>assertSucceeds(setDoc(home(p1),payload(1))));
    await test('aluno consulta treino em casa',()=>assertSucceeds(getDoc(home(student))));
    await test('professor vinculado consulta',()=>assertSucceeds(getDoc(home(p1))));
    await test('outro professor nao consulta',()=>assertFails(getDoc(home(p2))));
    await test('outro aluno nao consulta',()=>assertFails(getDoc(home(other))));
    await test('nao autenticado nao consulta',()=>assertFails(getDoc(home(guest))));
    await test('nao pode listar toda a subcolecao',()=>assertFails(getDocs(collection(student,'users/aluno1/homeWorkouts'))));
    await test('aluno nao edita treino em casa',()=>assertFails(updateDoc(home(student),{version:2,updatedAt:serverTimestamp()})));
    await test('professor alheio nao edita',()=>assertFails(updateDoc(home(p2),{version:2,updatedAt:serverTimestamp()})));
    await test('professor nao repete versao',()=>assertFails(updateDoc(home(p1),{routines:payload(1).routines,updatedAt:serverTimestamp()})));
    await test('professor atualiza com versao sequencial',()=>assertSucceeds(updateDoc(home(p1),{version:2,updatedAt:serverTimestamp()})));
    const session=(d,id)=>doc(d,`users/aluno1/trainingSessions/${id}`);
    const sessionPayload=(id,version)=>({schemaVersion:1,id,studentId:'aluno1',instructorId:'prof1',
      planId:'home',planVersion:version,routineId:'casa-a',routineName:'Casa A',
      status:'inProgress',startedAt:new Date().toISOString(),warmupDone:false,
      exercises:[{itemId:'item1',sets:[{number:1,completed:false,loadKg:null}]}],
      createdAt:serverTimestamp(),updatedAt:serverTimestamp()});
    await test('aluno nao inicia versao obsoleta',()=>assertFails(setDoc(session(student,'antiga'),sessionPayload('antiga',1))));
    await test('aluno inicia em casa sem ficha presencial',()=>assertSucceeds(setDoc(session(student,'casa1'),sessionPayload('casa1',2))));
    await test('professor vinculado acompanha execucao',()=>assertSucceeds(getDoc(session(p1,'casa1'))));
    await test('outro aluno nao cria sessao',()=>assertFails(setDoc(session(other,'invasao'),sessionPayload('invasao',2))));
    await test('aluno nao retira prescricao',()=>assertFails(deleteDoc(home(student))));
    await test('professor retira prescricao de casa',()=>assertSucceeds(deleteDoc(home(p1))));
    await test('nao inicia mais depois de retirar',()=>assertFails(setDoc(session(student,'apos'),sessionPayload('apos',2))));
    await test('historico existente continua acessivel',()=>assertSucceeds(getDoc(session(student,'casa1'))));
    console.log(`SUCESSO CASA: ${ok} verificacoes no emulador.`);
  } finally {await env.cleanup();}
}
run().catch(err=>{console.error('FALHA CASA',err);process.exitCode=1;});

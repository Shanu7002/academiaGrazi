# AGENTS.md — Especificação para agentes de IA e desenvolvedores

> Arquivo de referência único do projeto **Academia Grazi Braz**. Qualquer agente (Claude Code, Copilot, Cursor, Codex…) ou pessoa que for gerar código **deve ler este arquivo antes de começar** e seguir o que está aqui.
> Se algo aqui estiver desatualizado em relação ao código, **corrija este arquivo no mesmo PR**.
> Backlog e decisões de produto: [`docs/BACKLOG.md`](docs/BACKLOG.md).

---

## 1. Produto

Aplicativo mobile (Flutter) da Academia Grazi Braz, **em português do Brasil**, com três perfis:

| Perfil | `UserType` | Faz o quê |
|---|---|---|
| Administrador | `admin` | Visão da operação, gestão dos alunos (professor responsável e modalidade), redistribuição de alunos entre professores (automática, proporcional à capacidade, ou manual), equipe (carga dos professores), cadastro de professores, unidades e escala, grade de aulas, biblioteca de exercícios, ocorrências |
| Professor | `instructor` | Painel com unidade atual/próxima e pendências, lista de alunos, montagem e prescrição de treinos, avaliações físicas |
| Aluno | `user` | Treino em destaque, execução do treino com registro de carga, evolução e avaliações, perfil e ficha de saúde |

O aluno se cadastra sozinho usando o **código de convite do professor** (4 dígitos, renovado a cada 15 min). O vínculo aluno → professor é o campo `users.responsable`.

### 1.1 Escopo

**Dentro:** RF01–RF14 e RNF01–RNF02 (ver `docs/BACKLOG.md`).

**Fora desta versão: não implemente, mesmo que pareça útil:**
- Pagamentos, mensalidade, planos, finanças, vendas digitais.
- Reserva de aulas e controle de lotação (a grade de aulas é **somente leitura**).
- Mensagens/chat entre professor e aluno.
- **Vídeos de exercício** (upload e player). O campo `exercises.videoUrl` existe, mas fica sempre `null`. Onde o protótipo mostra vídeo, exiba a imagem do exercício.
- Push notification (FCM). As notificações são **somente a lista interna no app**.
- Inteligência artificial: o card "Sugestão com IA" fica **desabilitado** com o selo "Recurso futuro".

### 1.2 Glossário de domínio

| Termo na UI | Significado | No código/banco |
|---|---|---|
| Bloco / Unidade | Unidade física da academia | `units` |
| Escala / Turno | Professor X está na unidade Y no dia D, das HH:mm às HH:mm | `instructorShifts` |
| Bloco atual / próximo | Turno da escala em que o professor está agora / o próximo | `currentAndNextShift()` |
| Ficha / Treino | Treino prescrito a um aluno (A, B, C…) | `workouts` |
| Ciclo | Conjunto de fichas com a mesma validade | `workouts.cycleName` |
| Modelo de treino | Ficha reutilizável do professor | `workoutTemplates` |
| Sessão | Uma execução de uma ficha pelo aluno | `workoutSessions` |
| Presença | Aluno com sessão **finalizada** no dia | derivado de `workoutSessions` |
| Risco de evasão / Inativo | Dias sem sessão finalizada ≥ limite | `lib/config/business_rules.dart` |
| Avaliação física | Agendada pelo professor e depois registrada (peso, gordura, massa magra, observações) | `assessments` |
| Modalidade do aluno | Presencial ou remoto (treino em casa), definida pelo professor/admin | `users.modality` |
| Ocorrência | Problema operacional registrado (ex.: equipamento quebrado) | `occurrences` |

---

## 2. Stack e comandos

- Flutter (Dart `^3.7.2`), Material 3, `google_fonts`, `flutter_svg`, `fl_chart`, `mask_text_input_formatter`, `image_picker`, `shared_preferences`.
- Firebase: Auth (e-mail/senha) e Cloud Firestore. Projeto: `academia-grazi-dev-ab105`.
- Imagens: Cloudinary com preset unsigned (`lib/config/cloudinary_config.dart`). Nenhum segredo vai no app.
- Injeção de dependência: `get_it` (`lib/locator.dart`).
- Testes: `flutter_test`, `mockito` + `build_runner`, `fake_cloud_firestore`.
- CI: GitHub Actions (`.github/workflows/CI.yml`) roda testes com cobertura e SonarCloud; `model_changelogs.yml` exige o changelog dos models.

```bash
make setup                                              # ativa os git hooks (.githooks): commit-msg e pre-push
make run                                                # flutter run com as variáveis do Cloudinary
dart run build_runner build --delete-conflicting-outputs   # gera os *.mocks.dart
flutter test                                            # o mesmo que o pre-push e o CI rodam
flutter analyze                                         # precisa ficar sem warnings
firebase deploy --only firestore                        # publica regras/índices (só com aprovação do time)
```

> Não adicione dependências novas sem citar no PR o motivo e a alternativa descartada. Não use pacotes de vídeo nesta versão.

---

## 3. Arquitetura

```
lib/
  main.dart                 # Firebase.initializeApp + setupLocator + AuthWrapper
  locator.dart              # registro de TODOS os services/controllers (lazy singletons)
  firebase_options.dart     # gerado pelo FlutterFire (não editar à mão)
  auth/permissions.dart     # regras de permissão no app (espelham firestore.rules)
  config/                   # configuração e constantes (cloudinary, business_rules)
  models/<dominio>/         # <nome>_model.dart + <nome>_model_changelog.xml
  service/<dominio>/        # acesso ao Firestore/HTTP. Única camada que conhece o banco
  controller/<dominio>/     # orquestra fluxos (Auth + services), valida e devolve enums de resultado
  theme/                    # AppColors, AppTheme. Única fonte de cores
  view/
    auth_wrapper.dart       # decide a área pelo UserType
    tab_router.dart         # MainShell: abas do aluno e do admin
    components/             # widgets compartilhados (CustomAppBar, AppBottomNavigation, UserAvatar…)
    admin/ teacher/ user/   # telas por perfil
      widgets/              # widgets da área
      ui_models/ ui_data/   # contratos de dados da UI (independentes do Firebase)
      mappers/              # Model → UiData (criar quando integrar)
```

### 3.1 Regras de camada (obrigatórias)

1. **View nunca acessa `FirebaseFirestore`, `FirebaseAuth.instance` nem `http` diretamente.** Ela obtém services e controllers por `locator<T>()`. (`FirebaseAuth` vindo do locator é aceito para ler `currentUser`.)
2. **Service** recebe as dependências opcionais no construtor para teste e marca o construtor com `coverage:ignore`:
   ```dart
   class ExerciseService {
     final FirebaseFirestore _db;
     // coverage:ignore-start
     ExerciseService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;
     // coverage:ignore-end
   }
   ```
3. **Controller** devolve enums ou objetos de resultado (ver `InstructorRegistrationResult`, `SelfRegistrationResult`); não lança exceção para a view. A view traduz o enum em mensagem pt-BR.
4. **Regra de negócio calculada** (status do aluno, turno atual, duração estimada, sequência, pendência de avaliação) fica em **funções puras** dentro de `service/<dominio>/`, recebendo `now` como parâmetro, para poder ser testada sem relógio.
5. Telas grandes recebem um **UiData imutável** (padrão de `AlunoTreinosUiData`, `MontagemTreinoProfessorUiData`). A integração cria um *mapper* Model → UiData e um widget carregador (`StreamBuilder`/`FutureBuilder`) que monta a tela com dados reais. Isso mantém os testes de widget simples.
6. Todo service ou controller novo é registrado em `lib/locator.dart` como `registerLazySingleton`.
7. **Não existem dados mockados em `lib/`.** Exemplo para teste fica em `test/fixtures/`. A pasta `lib/**/mocks/` está sendo eliminada (GB-125); não crie arquivos novos nela.

> Legado conhecido: `TeacherUserSearcher` e `UpdateDataController` ficam em `controller/`, mas acessam o Firestore como services, e `PreferencesService` fica em `view/`. Não copie esse padrão; mova-os se for alterar esses arquivos.

---

## 4. Convenções de código

| Item | Regra |
|---|---|
| Idioma do código | **Inglês** em models, services, controllers, campos do Firestore e valores de enum. Views legadas em português (`aluno_*`, `professor_*`) **não são renomeadas**; arquivos novos usam inglês. |
| Idioma da UI | **pt-BR** em todo texto visível, inclusive erros e SnackBars. Nunca mostre exceção crua nem texto em inglês ao usuário. |
| Arquivos | `snake_case.dart`; views terminam em `_view.dart`; models em `_model.dart` (o CI depende disso). |
| Keys de widget para teste | `Key('snake_case_em_portugues')`, ex.: `Key('botao_iniciar_treino')`, `Key('campo_busca_aluno')`. Prefixo pelo tipo: `botao_`, `campo_`, `card_`, `aba_`/`<perfil>_tab_`. |
| Números mágicos de negócio | Proibidos nas telas. Use `lib/config/business_rules.dart`. |
| Cores | Somente `AppColors.*`. Nada de `Color(0x…)` fora de `lib/theme/`. Use `withValues(alpha:)`, não `withOpacity`. |
| Tamanho de fonte | Somente `AppFontSize.*` (`lib/theme/app_font_size.dart`). Nada de `fontSize: 14` com número solto. |
| Log | `debugPrint` ou `dart:developer log`. Nunca `print`. |
| Formatação | `dart format` (largura 80, `analysis_options.yaml`). `flutter analyze` sem warnings. |
| Datas | Ver §5.1. |
| Estado | `StatefulWidget` + `setState` e `StreamBuilder`/`FutureBuilder`. Não introduza Provider/Riverpod/Bloc sem decisão do time. |
| Assíncrono em `State` | Sempre cheque `if (!mounted) return;` depois de `await` antes de usar `context`/`setState`. |
| Estados de tela | Toda tela com dados remotos trata **carregando, vazio, erro (com "Tentar novamente") e sucesso**. |

---

## 5. Modelo de dados (Firestore)

### 5.1 Convenções

- Nomes de campo em `camelCase` inglês; enums gravados como `enum.name` (`'weightLoss'`, `'onSite'`).
- **Datas**: string ISO-8601 em **UTC** (`date.toUtc().toIso8601String()`). Comparação lexicográfica funciona em consultas de intervalo. Datas sem hora (validade): `'YYYY-MM-DD'`. Quando uma **regra de segurança** precisar comparar com `request.time`, grave também `<campo>Millis` (int), como em `instructorCodes.expiresAtMillis`.
- `createdAt` é gravado **uma única vez**, na criação. Nunca use `toJson()` de um model para atualizar um documento existente se o `toJson` gerar `createdAt`; use `update({...})` só com os campos alterados.
- Dados exibidos em listas podem ser **desnormalizados** (ex.: nome e imagem do exercício dentro da ficha), para evitar N leituras.
- Exclusão lógica: `active: false` ou `status: 'archived'`. Não apague documentos referenciados.
- Toda consulta com mais de um `where`/`orderBy` exige um índice em `firestore.indexes.json`, no mesmo PR.

### 5.2 Changelog de model (obrigatório)

Ao criar ou alterar qualquer `*_model.dart`, crie ou atualize o arquivo irmão `*_model_changelog.xml` **adicionando** um novo bloco `<model>` (nunca edite blocos antigos). Mudança que quebra compatibilidade → versão inteira (`2.0`); campo opcional novo → decimal (`1.5`). Guia completo: `lib/models/changelogExample.md`. O workflow `model_changelogs.yml` reprova o PR que não fizer isso.

### 5.3 Coleções

Legenda: ✅ existe · 🆕 planejada (schema de referência; quem implementar segue este formato e atualiza esta seção se precisar mudar).

**✅ `users/{uid}`**: `UserModel` (`lib/models/users/user_model.dart`)
```
name: string
email: string
type: 'admin' | 'instructor' | 'user'
createdAt: string ISO UTC        # gravado só na criação (UserModel.createdAt); nunca reescrito
responsable?: string            # aluno → uid do professor; professor → uid do admin que o cadastrou
photoUrl?: string               # Cloudinary
# aluno
registrationProfile?: { measurements{age,heightCm,weightKg}, gender?: 'male'|'female'|'undisclosed', primaryGoal, health{conditions[],restrictions[],notes}, emergencyContact{name,relationship,phone} }
onboardingCompleted: bool
termsAcceptedAt?: string ISO
unitId?: string                 # aluno; bloco definido pelo admin nos detalhes do aluno (GB-043) ou pelo professor responsável
modality?: 'onSite' | 'remote'  # aluno; definido pelo professor responsável ou admin (GB-003)
# professor
registrationCode?: string       # 4 dígitos
registrationCodeExpiresAt?: string ISO UTC
specialty?: string              # professor; só o admin altera (GB-003), tela no GB-085
studentCapacity?: int           # professor; só o admin altera (GB-003); padrão 30 quando ausente (GB-085)
```

**✅ `instructorCodes/{code}`**: `{ instructorId, instructorName, active, createdAt, expiresAtMillis }`. Leitura pública apenas por `get`.

**✅ `units/{unitId}`**: `UnitModel` (`lib/models/units/unit_model.dart`), `UnitService`. `{ name, address?, active, createdAt }`. Nunca apagada: desative com `active: false`.

**✅ `instructorShifts/{id}`**: `InstructorShiftModel` (`lib/models/units/instructor_shift_model.dart`), `InstructorShiftService`. `{ instructorId, unitId, weekday: 1..7 (DateTime.weekday, 1 = segunda), startTime: 'HH:mm', endTime: 'HH:mm', createdAt }`. Horário local da academia; `startTime < endTime` (o turno não vira a meia-noite). Turno atual/próximo: `currentAndNextShift(shifts, now)` em `lib/service/units/shift_schedule.dart`. Turnos do mesmo professor não se sobrepõem no mesmo dia (encostar pode): `findOverlappingShift`, conferido no diálogo e no `InstructorShiftService.addShift`. O admin monta a escala na seção "Escala" dos detalhes do professor.

**🆕 `exercises/{id}`**
```
name, muscleGroup, instructions: string
imageUrl?: string               # Cloudinary
videoUrl?: string               # RESERVADO — sempre null nesta versão
active: bool
createdBy: uid
createdAt, updatedAt: string ISO
```

**🆕 `workouts/{id}`**: ficha prescrita
```
studentId, instructorId: uid
cycleName: string               # ex.: "Ciclo 3 — Hipertrofia"
letter: string                  # 'A', 'B'…
name, focus: string
level: 'beginner' | 'intermediate' | 'advanced'
modality: 'onSite' | 'home'
isComplementary: bool           # treinos complementares de "Treinar em casa"
status: 'active' | 'archived'
validUntil: 'YYYY-MM-DD'
estimatedMinutes: int
warmup?: { name, summary }
exercises: [ {
  exerciseId, name, imageUrl?,  # name/imageUrl desnormalizados
  order: int, sets: int,
  reps?: int, durationSeconds?: int,   # um dos dois (ex.: prancha 30 s)
  restSeconds: int,
  technique: 'Tradicional' | 'Rest-pause' | 'Drop-set' | 'Bi-set' | 'Super-set',
  suggestedLoadKg?: double, notes?: string
} ]
createdAt, updatedAt: string ISO
```

**🆕 `workoutTemplates/{id}`**: `{ instructorId, name, focus, level, exercises[] (mesmo formato), createdAt }`

**🆕 `workoutSessions/{id}`**: execução. **É a fonte de presença, inatividade, sequência e pico de movimento.**
```
studentId, instructorId, workoutId: string
workoutName: string
unitId?: string
status: 'inProgress' | 'finished'
startedAt: string ISO UTC
finishedAt?: string ISO UTC
warmupDone: bool
exercises: [ { exerciseId, done: bool, sets: [ { loadKg?: double, done: bool } ] } ]
```

**🆕 `assessments/{id}`**: avaliação física (dado de saúde)
```
studentId, instructorId: uid
type: 'onSite' | 'online'
status: 'scheduled' | 'done' | 'cancelled'
scheduledAt: string ISO UTC
performedAt?: string ISO UTC
weightKg?, bodyFatPercent?, leanMassKg?: double
notes?: string                  # observação profissional
createdAt: string ISO
```
Pendente = `scheduled` com data futura · vencida = `scheduled` com `scheduledAt` no passado.

**🆕 `notifications/{id}`**: `{ recipientId, senderId, type: 'workoutAssigned'|'assessmentScheduled'|'assessmentRecorded'|'instructorNotice', title, body, relatedId?, read: bool, createdAt }`

**🆕 `occurrences/{id}`**: `{ title, description, unitId?, severity: 'warning'|'info', status: 'open'|'resolved', reportedBy, reportedByName, createdAt, resolvedAt?, resolvedBy? }`

**✅ `gym_classes/{id}`**: `GymClassModel` (`lib/models/units/gym_class_model.dart`), `GymClassService`; cadastro pelo admin em `GymClassesView`. Grade de aulas, somente leitura para o aluno, sem reserva e sem lotação. `{ name, unitId, instructorId?, weekday, startTime: 'HH:mm', durationMinutes, capacity? (informativo), active, createdAt }`. Nunca apagada: retire da grade com `active: false`.

---

## 6. Segurança e permissões (RNF01)

As regras do Firestore (`firestore.rules`) são a **barreira real**; checagens na UI (`lib/auth/permissions.dart`) são conveniência. **Todo PR que cria uma coleção ou consulta nova atualiza `firestore.rules` no mesmo PR.** Regra padrão: **negar**.

| Recurso | Aluno | Professor | Admin |
|---|---|---|---|
| Próprio `users` | lê; altera só `name`, `photoUrl`, `registrationProfile.health`, `registrationProfile.emergencyContact` | lê; altera os mesmos campos + renova o próprio código | lê/altera |
| `users` de outros | lê só o do seu professor (nome/foto) | lê os alunos com `responsable == uid`; altera `unitId`/`modality` deles | lê todos; cria professores; altera `specialty`, `studentCapacity`, `unitId`, `modality` |
| Campos `type`, `createdAt` | ❌ nunca | ❌ nunca | só na criação |
| Campo `responsable` (vínculo aluno → professor) | ❌ nunca | ❌ nunca | define na criação do professor; troca o professor do aluno, sempre para um professor válido |
| `exercises` | lê | lê, cria, edita os que criou | tudo |
| `workouts` | lê os próprios | CRUD dos seus alunos | lê |
| `workoutTemplates` | ❌ | CRUD dos próprios | lê |
| `workoutSessions` | cria/edita as próprias `inProgress`; finalizada é imutável | lê dos seus alunos | lê |
| `assessments` | lê as próprias | CRUD dos seus alunos | lê |
| `units`, `instructorShifts`, `gym_classes` | lê | lê | CRUD |
| `notifications` | lê as próprias; altera só `read` | lê as próprias; cria para seus alunos | lê as próprias; cria para qualquer um |
| `occurrences` | ❌ | cria; lê as que criou | tudo |

**Troca de professor responsável:** a sessão de treino registra o professor autor da ficha ativa, não o responsável atual. Depois de uma troca, o aluno segue treinando a ficha vigente até o novo professor publicar outra, e o novo responsável pode substituir ou retirar a ficha ativa e o treino em casa deixados pelo anterior.

**Dados de saúde** (`registrationProfile.health`, `assessments`) e **contato de emergência** são sensíveis (LGPD): nunca exiba para outro aluno, nunca grave em log, nunca envie para serviço externo.

`AuthWrapper` só abre a área de admin para `UserType.admin` explícito. Perfil desconhecido ou ausente = sem acesso.

---

## 7. Interface (RNF02)

- O layout segue o **protótipo final**. Na dúvida sobre uma tela, pergunte ao time; não invente fluxo.
- Largura máxima de 430 px centralizada (padrão de `MainShell`/`ProfessorAreaView`).
- **Marca**: toda tela segue o manual de marca (§7.1). Cores só por `AppColors`, fonte só Barlow Condensed, tema em `AppTheme`.
- **Cabeçalho**: sempre `CustomAppBar` (avatar do usuário + título + sino). Telas raiz de aba usam `showBackButton: false`.
- **Navegação inferior**: `AppBottomNavigation`. Abas finais por perfil:
  - Aluno: Início · Treinos · Evolução · Perfil
  - Professor: Início · Treinos (montagem) · Evolução (avaliações) · Perfil; a lista de alunos abre pelo Início
  - Admin: Início · Alunos · Equipe · Perfil (a aba Alunos lista todos, filtra remotos e troca professor e modalidade)
- Foto de usuário: `UserAvatar` (usa miniatura do Cloudinary).
- Recursos fora do escopo **não aparecem** na UI. Exceção: o card de IA desabilitado com "Recurso futuro".
- Nenhum botão sem ação (`onPressed: () {}`). Se a função ainda não existe, o botão não aparece.


### 7.1 Manual de marca (obrigatório em toda tela e texto)

Manual completo: [`docs/MANUAL_DE_MARCA.md`](docs/MANUAL_DE_MARCA.md). Em conflito com preferências genéricas de design, o manual prevalece. Abaixo, as regras já traduzidas para o app.

**Identidade.** Nome **GRAZI BRAZ** (sempre em caixa alta no logo), tagline *conexão e movimento*, descritor *Treino personalizado*. Verbos da marca: **CONECTAR** (vínculo, empatia) e **MOVIMENTAR** (bem-estar, disciplina, propósito).

**Tom de voz.**
- Próximo, humano, motivador e acolhedor; nada de "academia hardcore".
- Frases curtas e claras, em segunda pessoa ("você", "sua energia de treino"). Perguntas para engajar são bem-vindas.
- Humor leve só em opções e enquetes. Temas: disciplina, propósito, constância, bem-estar, comunidade, saúde.
- pt-BR; frases de impacto em inglês só pontualmente.
- Mensagens de erro e estados vazios também seguem o tom: dizem o que aconteceu e o que fazer, sem culpar o usuário. Textos legais (termos, LGPD) não são reescritos.

**Tipografia.** Fonte única **Barlow Condensed** (`GoogleFonts.barlowCondensed`; o `AppTheme` já define o padrão). Não use Inter, Anton nem outra família.
- Títulos: SemiBold/Bold, **CAIXA ALTA**, tracking levemente aberto (`letterSpacing` ~0,6–1).
- Subtítulo e tagline: *itálico*, Light/Regular, caixa baixa ou de título.
- Corpo: Regular, tracking levemente aberto (~0,2).
- Números de métrica: Barlow Condensed Bold, grande.
- **Tamanhos: escala única `AppFontSize`** (nunca número solto em `fontSize`). Escolha pelo papel do texto, não pelo espaço disponível; se não couber, ajuste o layout (`Expanded`, `Wrap`, `maxLines`/`ellipsis`), não a fonte.

| Token | px | Uso |
|---|---|---|
| `caption` | 13 | rótulos pequenos, sobretítulos em caixa alta, selos (mínimo do app) |
| `small` | 15 | legendas, texto secundário |
| `body` | 17 | texto corrido, nomes em listas, campos, botões |
| `subtitle` | 20 | título de cartão ou item de destaque |
| `title` | 24 | título de seção |
| `headline` | 30 | título da página |
| `display` | 44 | números grandes de métrica |
- Título de seção no padrão `PALAVRA EM CAIXA ALTA / Complemento em itálico` (ex.: `EVOLUÇÃO / Suas medidas`).
- Destaque no corpo: a palavra-chave em CAIXA ALTA e/ou negrito na cor de impacto.

**Cores** (`lib/theme/app_colors.dart`; nunca `Color(0x…)` fora de `lib/theme/`):

| Papel | Cor | Token |
|---|---|---|
| Impacto: CTA principal, número/palavra em destaque | Laranja `#E37747` | `AppColors.accent` (`onAccent` = branco por cima) |
| Institucional: logo, títulos, ícones, fundos de marca | Verde `#02594F` | `AppColors.primary` / `textPrimary` |
| Ponto de luz: brilho, detalhes | Amarelo `#F2BE48` | `AppColors.highlight` |
| Atenção e respiro: perguntas ao aluno, avisos | Azul `#2A327B` | `AppColors.info` (com moderação) |
| Texto corrido | Cinza `#707070` | `AppColors.textBody` |
| Fundo | Off-white `#EBE8E6`, cartões brancos | `AppColors.background` / `surface` |

Predominância: laranja > verde > amarelo > azul. Superfícies e bordas usam nuances claras dessas cores (tokens `*Surface`, `*Border`).

**Ajustes de leitura (decisão do time, valem sobre o manual):**
- Cinza `#707070` só sobre cartões **brancos**. Legendas que ficam sobre o fundo off-white usam `textSecondary` (`#5C5C5C`).
- Amarelo nunca como texto sobre fundo claro (contraste 1,7:1): só sobre o verde ou como detalhe gráfico.
- Laranja como **texto** só em tamanho grande ou negrito (títulos, números, botões). Texto pequeno em alerta laranja usa `accentText`.
- Branco sobre laranja (contraste 3:1): só em negrito ou ≥ 18 px, como nos botões do tema.
- Erro e ação destrutiva usam `AppColors.danger` (vermelho), única cor fora da paleta, para não se confundir com o laranja dos CTAs.

**Componentes.**
- Botão principal: `FilledButton`/`ElevatedButton` do tema (laranja, texto branco em negrito).
- Secundário: `OutlinedButton` (contorno verde). Terciário: `TextButton` verde.
- Um CTA laranja por bloco de tela; o resto em verde.
- Avisos (`SnackBar`) em verde. Diálogos com título em Barlow Condensed verde.

**Gradiente, símbolo e logo.**
- O gradiente da marca (laranja, amarelo, azul e verde, desfocado e com grão) vale para capas, faixas laterais e destaques. Use os assets prontos (`assets/linhaGradiente.png`, `assets/welcometela/faixa_gradiente.png`); não recrie gradientes "parecidos".
- Símbolo: flor de 8 pétalas (`assets/welcometela/flor.png`, `flor_contorno.svg`, `petala_0..7.svg`). Pode ser usado grande e recortado na borda ou como marca d'água em linha branca ou verde.
- Logo só nas versões aprovadas (horizontal, vertical, empilhada, reduzida) e numa cor única da paleta, de preferência verde, ou branco sobre verde/laranja/gradiente. Assets: `logoLogin.png`, `logoGraziBranca.png`, `ICONE.svg`. Não distorcer, girar, recolorir em várias cores, trocar a fonte nem aplicar sem contraste.

**Ícones.** Estilo linha (outline), traço uniforme, cantos levemente arredondados, sem preenchimento, em verde `#02594F`. No Material, prefira as variantes `_outlined`/`_rounded`.

**Fotografia.**
- Pessoas reais treinando ou em momentos de conexão, com diversidade de corpos e foco em mulheres ativas.
- Luz natural, cores quentes, leve grão.
- Nada de estúdio frio, pose artificial ou estética bodybuilding.

**Layout.**
- Muito respiro e composição limpa.
- Títulos grandes em caixa alta; texto pequeno alinhado à esquerda.
- Navegação e "sobretítulos" discretos em caixa alta e tamanho pequeno.

**Checklist de marca** (entra na DoD, §10):
- [ ] Só Barlow Condensed, com tamanhos da escala `AppFontSize`
- [ ] Só cores da paleta via `AppColors` (+ cinza de texto e off-white), com os ajustes de leitura acima
- [ ] Laranja no destaque principal; verde institucional; azul com moderação
- [ ] Títulos em caixa alta; subtítulo/tagline em itálico
- [ ] Logo e símbolo só nas versões aprovadas, em cor única
- [ ] Texto claro, curto, humano e motivador (inclusive erros e estados vazios)
- [ ] Espaço em branco suficiente
---

## 8. Testes

- Toda lógica nova em service/controller/função pura tem teste unitário em `test/` espelhando o caminho de `lib/` (ex.: `lib/service/workouts/workout_service.dart` → `test/service/workouts/workout_service_test.dart`).
- Services com Firestore: `FakeFirebaseFirestore` (ver `test/service/admin/admin_dashboard_test.dart`).
- Controllers e views com dependências: `@GenerateMocks([...])` do mockito + `build_runner`; o `*.mocks.dart` é versionado ao lado do teste.
- Views: teste de widget dos fluxos principais, localizando por `Key`. Registre os mocks no `locator` no `setUp` e chame `locator.reset()` no `tearDown`.
- Funções de tempo recebem `now`/`clock` injetável. Nunca dependa de `DateTime.now()` dentro do teste.
- Nomes de teste em pt-BR descrevendo o comportamento: `test('conta somente alunos e os novos dos últimos 30 dias', ...)`.
- `flutter test` precisa passar antes do push (o hook `pre-push` bloqueia).

---

## 9. Git e PR

- **Fluxo**: `master` ← `sprint-N` ← branches de card. Abra a branch a partir da sprint atual: `feat/GB-031-sessao-de-treino`, `fix/GB-001-regras-users`.
- **Commits**: Conventional Commits, validado pelo hook `commit-msg`: `feat|fix|docs|refactor|test|chore|perf|build|ci|revert(escopo opcional): resumo`. Ex.: `feat(treinos): grava sessão ao finalizar treino (GB-032)`.
- **PR**: título no mesmo formato e com o ID do card. Descrição: o que mudou, como testar, prints das telas alteradas, coleções/regras/índices tocados.
- Um card por PR. Não misture refatoração ampla com funcionalidade.
- Não faça `firebase deploy` de regras sem aprovação; descreva no PR o que muda nas regras.

---

## 10. Definição de Pronto (DoD)

Um card só está pronto quando:

- [ ] Critérios de aceite do card em `docs/BACKLOG.md` atendidos.
- [ ] Sem dados mockados ou textos fixos de exemplo em `lib/` para a funcionalidade entregue.
- [ ] Estados de carregando, vazio e erro tratados; textos em pt-BR.
- [ ] Checklist de marca (§7.1) atendido.
- [ ] `firestore.rules` e `firestore.indexes.json` atualizados quando houver coleção ou consulta nova.
- [ ] Model novo ou alterado com `*_model_changelog.xml` atualizado.
- [ ] Testes novos passando; `flutter test` e `flutter analyze` limpos.
- [ ] Service/controller registrado no `locator`.
- [ ] Este `AGENTS.md` atualizado se o schema, as regras ou as convenções mudaram.

---

## 11. Como pedir uma tarefa a um agente de IA

Use este modelo no prompt. Ele força o agente a ler o contexto certo e a não extrapolar o escopo:

```text
Leia AGENTS.md e o card GB-XXX em docs/BACKLOG.md antes de começar.
Tarefa: implementar o card GB-XXX — <título>.
Restrições:
- Siga as camadas da seção 3 e o schema da seção 5 do AGENTS.md (não invente campos; se precisar mudar o schema, me pergunte e atualize o AGENTS.md).
- Não implemente nada listado como fora do escopo (seção 1.1).
- Atualize firestore.rules/índices e o changelog do model quando aplicável.
- Escreva os testes descritos na seção 8.
Antes de codar, liste os arquivos que vai criar/alterar e qualquer dúvida de regra de negócio.
Ao terminar, rode `flutter analyze` e `flutter test` e me mostre o resultado e o checklist da DoD (seção 10).
```

Para o agente: **se a regra de negócio não estiver neste arquivo nem no card, pergunte em vez de presumir.** As pendências abertas estão em `docs/BACKLOG.md` → "Pendências de definição".

---

## 12. Armadilhas conhecidas

- `IndexedStack` mantém as 4 abas montadas: `initState` de todas roda no login. Uma tela que carrega uma vez (`.first` de stream) não se atualiza sozinha. Prefira `StreamBuilder`.
- O cadastro de professor usa um **app Firebase secundário** (`instructorRegistration`) para não deslogar o admin. Não troque por `FirebaseAuth.instance`.
- O código de convite não tem backend de renovação: ele é renovado sob demanda em uma transação (`RegisterInstructorService._issueCode`). Não crie timers que gravem no banco.
- `CustomAppBar` assina o documento do usuário logado para a foto; em teste isolado ele exibe o ícone padrão se os services não estiverem no `locator`.
- O seletor "Presencial / Treino em casa" da tela de login é **apenas visual** (troca o fundo). A modalidade real do aluno é `users.modality`.

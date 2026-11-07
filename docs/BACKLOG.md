# Backlog — Academia Grazi Braz (a partir da sprint-6)

> Levantamento feito sobre a branch `sprint-6` (commit `8117a5d`, 06/11/2026), cruzando o código com os requisitos RF01–RF14 / RNF01–RNF02.
> As regras de negócio confirmadas e o padrão técnico estão em [`AGENTS.md`](../AGENTS.md). **Todo card deste backlog segue a Definição de Pronto de lá.**

## Como ler este documento

- **ID**: `GB-NNN`. Use como prefixo no título do card do Jira e no nome da branch (`feat/GB-031-sessao-de-treino`).
- **Tipo**: `História` (entrega funcional), `Tarefa` (técnica), `Bug`.
- **Prioridade**: `Crítica` > `Alta` > `Média` > `Baixa`.
- **Tamanho**: `P` (≤ 1 dia), `M` (2–3 dias), `G` (4+ dias; considere quebrar).
- **Depende de**: cards que precisam estar prontos antes.
- **Remove mock**: qual dado falso o card elimina. Todo mock de `lib/` precisa ser removido por algum card (ver GB-125).

O arquivo `docs/backlog-jira.csv` é gerado a partir deste documento para importação no Jira.

---

## Situação atual (resumo do diagnóstico)

| Área | Situação | Observação |
|---|---|---|
| Login, recuperação de senha, perfis | ✅ Real (Firebase Auth + `users`) | Fallback inseguro para admin (GB-002) |
| Autocadastro do aluno com código do professor | ✅ Real | Código de 4 dígitos, renova a cada 15 min |
| Cadastro de professor pelo admin | ✅ Real | Sem especialidade nem capacidade |
| Perfil (foto, ficha de saúde, contato de emergência) | ✅ Real | Plano/mensalidade, bloco e "Prof. Marcos" fixos |
| Home do admin | 🟡 Parcial | Só "alunos ativos" é real; o resto é `AdminHomeMockData` |
| Equipe / detalhes do professor | 🟡 Parcial | Capacidade 30, cargo e avaliações pendentes vêm de `AdminTeamMockData` |
| Dashboard do professor | 🟡 Parcial | Só a contagem de alunos é real; nome, bloco, presenças e prioridades são fixos |
| Lista de alunos do professor | 🔴 Mock e sem rota | `ListaAlunosView` não é aberta por nenhuma tela |
| Montagem de treino | 🟡 UI pronta | Catálogo fixo no código; "Salvar modelo" e "Atribuir" não gravam |
| Treinos / execução / detalhe do exercício (aluno) | 🔴 Mock | Tudo vem de `TreinosMockData`; nada é persistido |
| Evolução (aluno) | 🔴 Mock | Valores fixos; botões de período sem ação |
| Evolução (professor) | 🔴 Placeholder | "Tela em desenvolvimento" |
| Home do aluno | 🔴 Mock | Todos os botões com `onPressed: () {}` |
| Aba Treinos do admin | 🔴 Errada | Mostra a tela de treinos do aluno com mock |
| Notificações | 🔴 Inexistente | Sino sem ação em todas as telas |
| Unidades (blocos), aulas, avaliações, sessões | 🔴 Inexistente no banco | — |
| Regras do Firestore | 🔴 Falha grave | O usuário pode alterar o próprio `type` para `admin` (GB-001) |

### Decisões registradas nesta revisão

| Tema | Decisão |
|---|---|
| Bloco de atendimento | **Bloco = unidade da academia.** O professor tem uma **escala** (unidade + dia + horário); o painel mostra a unidade atual e a próxima. O aluno pertence a uma unidade. |
| Vídeos dos exercícios | **Fora desta entrega, por escolha do time.** O exercício mostra imagem + orientações; o campo `videoUrl` fica previsto no modelo, mas sem player nem upload. |
| Ativo / inativo / presença | Calculados a partir das **sessões de treino finalizadas** pelo aluno no app. |
| Notificações | **Lista interna no app** (Firestore). Sem push/FCM. |
| Avaliações físicas | O **professor agenda** (data e tipo) e depois **registra** os resultados. Pendente = agendada e não realizada; vencida = data passou sem registro. |
| Aba Treinos do admin | Vira a **Biblioteca de exercícios** (criar, editar, desativar). |
| Alertas operacionais | **Ocorrências registradas** (professor/admin) + **alertas automáticos** calculados. |
| Aulas | **Mantidas como grade somente leitura** cadastrada pelo admin. Sem reserva e sem alerta de lotação. |
| Modalidade do aluno (presencial/remoto) | Definida **pelo professor ou admin**. O seletor do login continua apenas visual. |
| Capacidade e especialidade | **Campos por professor**, definidos pelo admin. |
| Treinar em casa | **Mantido** (aba/ficha "Treinar em casa", treinos complementares, card "Remotos"). Sem vídeo, pela decisão acima. |
| **Sai** do app | Card "Plano e Mensalidade", atalho "Finanças", botão "Mensagem", "Redistribuir alunos". |
| IA | Continua como card desabilitado "Recurso futuro" (restrição 7). Nenhuma tarefa. |

### Pendências de definição (confirmar com o time antes de implementar o card)

Cada item traz uma **proposta padrão**. Se ninguém se opuser até o início do card, vale a proposta. Os valores ficam como constantes nomeadas em `lib/config/business_rules.dart` (ver GB-004).

| # | Pergunta | Proposta padrão | Afeta |
|---|---|---|---|
| P1 | Quantos dias sem treino caracterizam "risco de evasão"? | 10 dias | GB-053, GB-071 |
| P2 | Quantos dias sem treino caracterizam "inativo"? | 30 dias (o admin já exibe "30D+") | GB-053, GB-080 |
| P3 | Regra da "sequência" (streak) na home do aluno | Semanas consecutivas com pelo menos 1 treino finalizado | GB-091 |
| P4 | Com quantos dias de antecedência a avaliação vira prioridade "vence em X dias"? | 3 dias | GB-064, GB-072 |
| P5 | Fórmula da duração estimada e do volume na montagem | Duração = Σ(séries × (reps × 4 s + descanso)) + 5 min de aquecimento. Volume: ≤ 12 séries Leve, ≤ 20 Médio, > 20 Intenso | GB-025 |
| P6 | Limiar do alerta automático de inativos no admin | > 10% dos alunos ativos | GB-083 |
| P7 | O toggle "Lembrete diário de treino" do perfil não dispara nada (não há push). Remover ou manter? | Remover o toggle | GB-123 |
| P8 | O aluno pode ter mais de uma ficha ativa (A/B/C)? | Sim: o "ciclo" agrupa várias fichas (A, B, C) com a mesma validade | GB-020 |

---

## Ordem sugerida (fases)

1. **Fase 0, fundação e segurança:** GB-001 a GB-005, GB-120, GB-121
2. **Fase 1, exercícios e treinos:** E2, E3, E4 (núcleo do app: o aluno recebe e executa treino)
3. **Fase 2, unidades, alunos e avaliações:** E5, E6, E7
4. **Fase 3, painéis:** E8, E9, E10 (dependem de sessões e avaliações)
5. **Fase 4, aulas, notificações e acabamento:** E11, E12, E13

---

## E1 · Fundação, segurança e dívida técnica (RNF01)

### GB-001 · Bloquear alteração de campos sensíveis pelo próprio usuário nas regras do Firestore
- **Tipo:** Bug
- **Prioridade:** Crítica
- **Tamanho:** M
- **Requisito:** RNF01
- **Perfil:** Todos
- **Depende de:** —
- **Descrição:** Em `firestore.rules`, `match /users/{userId}` tem `allow read, write: if request.auth.uid == userId`. Com isso, qualquer aluno ou professor consegue gravar `type: 'admin'` no próprio documento, trocar `responsable` ou `registrationCode`. Separe `create` e `update`. No `create`, o próprio usuário só pode criar com `type == 'user'`, e o professor só é criado pelo admin (regra já existe). No `update`, o próprio usuário só pode alterar `photoUrl`, `registrationProfile.health`, `registrationProfile.emergencyContact` e `name`. Bloqueie `delete`.
- **Critérios de aceite:**
  - Um aluno autenticado não consegue alterar `type`, `responsable`, `registrationCode`, `registrationCodeExpiresAt` nem `createdAt` do próprio documento (testado no Rules Playground ou no emulador).
  - Autocadastro, edição de saúde/contato e troca de foto continuam funcionando.
  - A renovação do código de convite pelo próprio professor continua funcionando (`RegisterInstructorService._issueCode`).
- **Arquivos:** `firestore.rules`

### GB-002 · AuthWrapper: negar acesso quando o perfil não for reconhecido
- **Tipo:** Bug
- **Prioridade:** Crítica
- **Tamanho:** P
- **Requisito:** RF01, RNF01
- **Perfil:** Todos
- **Depende de:** —
- **Descrição:** Em `lib/view/auth_wrapper.dart`, qualquer valor que não seja `user` nem `instructor` (inclusive `null`) abre `MainShell(isAdmin: true)`. Além disso, `RegisterUserService.getUserRole` faz `user!` e quebra quando o documento não existe. Abra o shell de admin só para `UserType.admin` explícito. Documento inexistente ou erro mostra uma tela em pt-BR ("Não foi possível carregar seu perfil") com o botão "Sair". Corrija a assinatura `Future<UserType>?` para `Future<UserType?>`.
- **Critérios de aceite:**
  - Usuário autenticado sem documento em `users` não vê nenhuma área do app e consegue sair.
  - Teste de widget cobrindo admin, professor, aluno, documento inexistente e erro.
- **Arquivos:** `lib/view/auth_wrapper.dart`, `lib/service/users/register_user.dart`

### GB-003 · UserModel: novos campos e correção do createdAt
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF03, RF04, RF05
- **Perfil:** Todos
- **Depende de:** GB-001
- **Descrição:** `UserModel.toJson()` grava `createdAt: DateTime.now()` toda vez que é serializado, e `fromJson` não lê `createdAt`. Isso sobrescreve a data de cadastro em qualquer escrita futura com `toJson`. Faça `createdAt` virar um campo do modelo, gravado só na criação. `fromJson` converte `responsable` nulo em `''`; mantenha `null`. Adicione os campos opcionais previstos no `AGENTS.md`: `unitId` e `modality` (aluno); `specialty` e `studentCapacity` (professor). Atualize `user_model_changelog.xml` (versão 1.5) e corrija o histórico (a versão 1.1 está duplicada, e as versões 1.2/1.3 dizem "8 caracteres", mas o código tem 4 dígitos).
- **Critérios de aceite:**
  - `createdAt` não muda depois de uma edição de perfil.
  - Testes de `toJson`/`fromJson` para os campos novos e para documentos antigos sem esses campos.
  - Regras: só o admin altera `specialty`/`studentCapacity`; o professor responsável e o admin alteram `unitId`/`modality` do aluno.
- **Arquivos:** `lib/models/users/user_model.dart`, `lib/models/users/user_model_changelog.xml`, `firestore.rules`

### GB-004 · Criar arquivo de regras de negócio e índices do Firestore
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RNF01
- **Perfil:** —
- **Depende de:** —
- **Descrição:** Crie `lib/config/business_rules.dart` com as constantes nomeadas das pendências P1–P6 (`riskDaysWithoutTraining`, `inactiveDaysWithoutTraining`, `assessmentDueSoonDays` etc.), para que telas e services não espalhem números mágicos. Crie `firestore.indexes.json` e registre-o em `firebase.json`; cada card que adicionar uma consulta composta acrescenta o índice ali.
- **Critérios de aceite:**
  - Constantes documentadas com o número da pendência (P1, P2…).
  - `firebase deploy --only firestore` publica regras e índices.
- **Arquivos:** `lib/config/business_rules.dart`, `firestore.indexes.json`, `firebase.json`

### GB-005 · Limpeza de dívida técnica geral
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RNF02
- **Perfil:** —
- **Depende de:** —
- **Descrição:** Remova os `print` de `aluno_profile_view.dart` (logout); use `debugPrint`/`log`. Remova `RegisterUserService.getResponsableData`, duplicado de `getUserById`. Em `CustomAppBar`, o parâmetro `backgroundColor` (padrão `Colors.blue`) é ignorado: use-o ou remova-o. Troque `withOpacity` (deprecated) por `withValues(alpha:)`. Rode `flutter analyze` e zere os avisos.
- **Critérios de aceite:**
  - `flutter analyze` sem warnings.
  - Nenhum `print(` em `lib/`.
- **Arquivos:** `lib/view/user/aluno_profile_view.dart`, `lib/service/users/register_user.dart`, `lib/view/components/app_bar.dart`, views com `withOpacity`

---

## E2 · Biblioteca de exercícios (RF07)

### GB-010 · Modelo e service de exercícios
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF07
- **Perfil:** Admin, Professor
- **Depende de:** GB-004
- **Descrição:** Crie `lib/models/exercises/exercise_model.dart` (+ `exercise_model_changelog.xml`) com o schema da coleção `exercises` do `AGENTS.md` (nome, grupo muscular, orientações, `imageUrl`, `videoUrl` reservado e nulo, `active`, `createdBy`, `createdAt`). Crie `ExerciseService` com `streamActive()`, `search(texto, grupo)`, `create`, `update` e `deactivate` (não apaga, marca `active: false`). Registre-o no `locator`. Regras: leitura por qualquer autenticado; criação por admin e professor; edição/desativação pelo admin ou pelo criador.
- **Critérios de aceite:**
  - Testes do service com `fake_cloud_firestore`.
  - Exercício desativado some da busca, mas continua aparecendo em treinos já atribuídos.
- **Arquivos:** `lib/models/exercises/`, `lib/service/exercises/`, `lib/locator.dart`, `firestore.rules`

### GB-011 · Upload da imagem do exercício no Cloudinary
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF07
- **Perfil:** Admin, Professor
- **Depende de:** GB-010
- **Descrição:** Hoje a imagem escolhida em `CadastrarExercicioDialog` fica só em memória (`imagemBytes`). Generalize `ProfilePhotoService` em um `CloudinaryUploadService` (parâmetro de pasta/prefixo do `public_id`), ou crie um service irmão, e grave o `secure_url` em `exercises.imageUrl`. Remova o aviso "A imagem ficará apenas nesta sessão".
- **Critérios de aceite:**
  - A imagem cadastrada aparece depois de reiniciar o app.
  - Teste do upload com `http.Client` mockado (no padrão de `profile_photo_test.dart`).
- **Arquivos:** `lib/service/users/profile_photo.dart`, `lib/view/teacher/widgets/cadastrar_exercicio_dialog.dart`

### GB-012 · Tela Biblioteca de exercícios (aba Treinos do admin)
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF07
- **Perfil:** Admin
- **Depende de:** GB-010, GB-011
- **Remove mock:** `AlunoTreinosView(data: TreinosMockData.alunoTreinos)` na aba do admin (`tab_router.dart`)
- **Descrição:** Crie `lib/view/admin/exercise_library_view.dart` e use-a na aba 1 do `MainShell` quando `isAdmin`. A tela lista os exercícios com busca por nome, filtro por grupo muscular, criação, edição (nome, grupo, orientações, imagem) e desativação/reativação. Renomeie o rótulo da aba do admin para "Exercícios".
- **Critérios de aceite:**
  - O admin não vê mais nenhuma tela de aluno.
  - Estados de carregando, vazio e erro.
  - Teste de widget da busca e do filtro.
- **Arquivos:** `lib/view/tab_router.dart`, `lib/view/components/app_bottom_navigation.dart`, `lib/view/admin/`

### GB-013 · Catálogo inicial de exercícios
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF07
- **Perfil:** Admin
- **Depende de:** GB-012
- **Descrição:** Cadastre pela própria biblioteca (ou por um script de seed documentado em `docs/`) os exercícios usados hoje nos mocks: agachamento, leg press, extensora, supino, puxada, remada, rosca, panturrilha etc. Assim a montagem não começa vazia.
- **Critérios de aceite:**
  - O ambiente `academia-grazi-dev` tem pelo menos 20 exercícios ativos com grupo muscular e orientações.

### GB-014 · Consulta de detalhes do exercício (sem vídeo)
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF07
- **Perfil:** Professor, Aluno
- **Depende de:** GB-010
- **Descrição:** Crie um componente compartilhado (`lib/view/components/exercise_details_sheet.dart`) com imagem, grupo muscular e orientações. Use-o ao tocar no exercício na montagem e no bloco de vídeo do `AlunoExercicioDetalheView`. Como os vídeos ficaram fora desta entrega, troque o player falso (botão play sem ação e "tempoVideo") pela imagem do exercício, com o selo "Vídeo em breve".
- **Critérios de aceite:**
  - Nenhum botão de play sem ação no app.
  - A decisão de não ter vídeo está citada no `AGENTS.md` (seção Escopo).
- **Arquivos:** `lib/view/user/aluno_exercicio_detalhe_view.dart`, `lib/view/teacher/widgets/imagem_exercicio.dart`

---

## E3 · Montagem e prescrição de treinos (RF08, RF09)

### GB-020 · Modelo e service de treinos (fichas prescritas)
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** G
- **Requisito:** RF08, RF09
- **Perfil:** Professor, Aluno
- **Depende de:** GB-010
- **Descrição:** Crie `WorkoutModel` (+ changelog) conforme a coleção `workouts` do `AGENTS.md`: aluno, professor, ciclo, letra, nome, foco, nível, modalidade (`onSite`/`home`), validade, aquecimento e a lista ordenada de exercícios (`exerciseId`, nome e imagem desnormalizados, séries, reps, descanso, técnica, carga sugerida, observação). Crie `WorkoutService` com `streamActiveForStudent`, `listByInstructor`, `assign`, `update` e `archive`. Regras: o professor grava apenas para alunos cujo `responsable` é ele; o aluno lê só os próprios; o admin lê todos.
- **Critérios de aceite:**
  - Testes do service com `fake_cloud_firestore`.
  - Índice composto (`studentId`, `status`) em `firestore.indexes.json`.
- **Arquivos:** `lib/models/workouts/`, `lib/service/workouts/`, `firestore.rules`

### GB-021 · Montagem: usar o catálogo real e persistir o exercício manual
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF08
- **Perfil:** Professor
- **Depende de:** GB-010, GB-011
- **Remove mock:** catálogo fixo (`c1`…`c4`) em `ProfessorMontagemTreinoView._fetchData` e o arquivo `lib/view/teacher/mocks/montagem_treino_mock_data.dart`
- **Descrição:** Troque o catálogo fixo pelo `ExerciseService`. Hoje a busca sem texto mostra só 2 sugestões (`base.take(2)`); mantenha isso ou crie "ver todos". "Adicionar Exercício Manual" passa a criar o exercício na coleção `exercises` (com `createdBy` = professor) antes de adicioná-lo à série.
- **Critérios de aceite:**
  - Um exercício criado na montagem aparece na biblioteca do admin.
  - Testes de widget atualizados (`cadastrar_exercicio_dialog_test.dart`).
- **Arquivos:** `lib/view/teacher/professor_montagem_treino_view.dart`

### GB-022 · Montagem: campos de prescrição (foco, nível, modalidade, validade, aquecimento)
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF09
- **Perfil:** Professor
- **Depende de:** GB-020
- **Descrição:** O RF09 exige foco, nível e professor responsável na ficha, e a tela do aluno mostra validade, aquecimento e estratégia. Adicione esses campos na montagem: foco (texto curto), nível (Iniciante/Intermediário/Avançado), modalidade da ficha (Presencial/Treinar em casa), validade (data), aquecimento (nome + resumo) e carga sugerida por exercício.
- **Critérios de aceite:**
  - Validação: não atribui sem nome, foco, nível e validade.
  - O resumo de conferência exibe todos os campos.

### GB-023 · Montagem: atribuir treino ao aluno e editar a ficha existente
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF08, RF09
- **Perfil:** Professor
- **Depende de:** GB-020, GB-022
- **Descrição:** "Atribuir ao aluno" hoje abre um diálogo que diz "Nenhum treino será salvo". Faça o botão gravar a ficha via `WorkoutService.assign` depois do resumo de conferência (RF08, "consultar resumo antes de salvar"). Ao selecionar um aluno que já tem ficha com a mesma letra, carregue-a para edição em vez de começar vazia. Permita arquivar a ficha.
- **Critérios de aceite:**
  - O aluno vê a ficha na aba Treinos logo após a atribuição.
  - A edição mantém o `id` da ficha (não duplica).
  - Mensagens de sucesso e erro em pt-BR.

### GB-024 · Montagem: salvar e carregar modelos de treino
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF08
- **Perfil:** Professor
- **Depende de:** GB-020
- **Descrição:** "Salvar como modelo" hoje só mostra um SnackBar. Grave na coleção `workoutTemplates` (do professor) e crie a ação "Carregar modelo" na montagem, que preenche a série com os exercícios do modelo.
- **Critérios de aceite:**
  - O professor só vê os próprios modelos.
  - Aplicar um modelo não altera o modelo original.

### GB-025 · Montagem: calcular duração estimada e volume
- **Tipo:** Tarefa
- **Prioridade:** Baixa
- **Tamanho:** P
- **Requisito:** RF08
- **Perfil:** Professor
- **Depende de:** GB-004
- **Remove mock:** `duracaoEstimadaMinutos: 45` e `volume: 'Médio'` fixos
- **Descrição:** Calcule em uma função pura (em `lib/service/workouts/workout_metrics.dart`), seguindo a pendência P5, e atualize ao editar a série. Grave o valor na ficha (`estimatedMinutes`). Ele é usado na tela do aluno.
- **Critérios de aceite:**
  - Testes unitários da função.

---

## E4 · Execução do treino pelo aluno (RF09, RF10, RF11)

### GB-030 · Aba Treinos do aluno com fichas reais
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** G
- **Requisito:** RF09
- **Perfil:** Aluno
- **Depende de:** GB-020, GB-023
- **Remove mock:** `TreinosMockData.alunoTreinos` em `tab_router.dart`
- **Descrição:** Mantenha a `AlunoTreinosView` recebendo `AlunoTreinosUiData` (o contrato de UI está bom). Crie um mapper `WorkoutModel → AlunoTreinosUiData` em `lib/view/user/mappers/` e um widget carregador que escuta `streamActiveForStudent`. O seletor "Ficha presencial / Treinar em casa" filtra pela modalidade da ficha. Ciclo, validade, professor e "última atualização" vêm dos dados. Frequência e duração média ficam como "—" até GB-031.
- **Critérios de aceite:**
  - Estados de carregando, sem ficha ("Seu professor ainda não montou seu treino"), erro.
  - Testes do mapper.
- **Arquivos:** `lib/view/tab_router.dart`, `lib/view/user/aluno_treinos_view.dart`

### GB-031 · Modelo e service de sessões de treino
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF10, RF11
- **Perfil:** Aluno
- **Depende de:** GB-020
- **Descrição:** Crie `WorkoutSessionModel` (+ changelog) conforme a coleção `workoutSessions` do `AGENTS.md` (aluno, professor, ficha, unidade, início, fim, status, exercícios com séries `{carga, concluída}`). `WorkoutSessionService`: `start`, `updateProgress`, `finish`, `lastSessionForStudent`, `sessionsBetween`. **É a fonte de presença, inatividade, sequência e horários de pico**; grave `startedAt`/`finishedAt` em ISO-8601 UTC (convenção de datas do `AGENTS.md`). Regras: o aluno cria/edita as próprias sessões em andamento; sessão finalizada fica imutável; o professor responsável e o admin leem.
- **Critérios de aceite:**
  - Testes com `fake_cloud_firestore`.
  - Índices (`studentId`, `finishedAt`) e (`instructorId`, `finishedAt`).

### GB-032 · Execução: iniciar, acompanhar e finalizar o treino
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF10
- **Perfil:** Aluno
- **Depende de:** GB-030, GB-031
- **Descrição:** Em `AlunoTreinoDiaView`, "Iniciar treino" cria a sessão. O aquecimento e os exercícios marcados como concluídos são gravados. "Finalizar treino" fecha a sessão com confirmação. Ao reabrir o app com uma sessão em andamento, ofereça "Continuar treino". O botão sem ação no cabeçalho (`onPressed: () {}`, linha ~251) recebe uma função ou sai.
- **Critérios de aceite:**
  - Fechar o app no meio do treino não perde o progresso.
  - A sessão finalizada aparece para o professor (GB-051).

### GB-033 · Registro de carga por série
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF11
- **Perfil:** Aluno
- **Depende de:** GB-032
- **Descrição:** Em `AlunoExercicioDetalheView`, a carga digitada por série e o status "concluída" passam a ser salvos na sessão. A carga inicial de cada série é a última registrada pelo aluno nesse exercício (ou a carga sugerida da ficha). Hoje a view interpreta `series: "4x10"` e `carga: "40Kg"` como texto; com o modelo real, use campos numéricos (`sets`, `reps`, `suggestedLoadKg`) e ajuste o `ExercicioTreinoUi`.
- **Critérios de aceite:**
  - Testes de widget atualizados (`aluno_exercicio_detalhe_view_test.dart`) sem depender de `TreinosMockData`.

### GB-034 · Status das fichas e histórico de ciclos
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF09, RF10
- **Perfil:** Aluno
- **Depende de:** GB-031
- **Descrição:** Calcule `recomendado` / `concluído` / `programado` de cada ficha a partir das sessões (ex.: recomendada = a ficha do ciclo feita há mais tempo). Implemente "Refazer treino" e "Ver fichas e ciclos anteriores" (hoje com `onPressed: () {}`), listando as fichas arquivadas. Preencha frequência e duração média com as sessões.
- **Critérios de aceite:**
  - Nenhum botão sem ação em `aluno_treinos_view.dart`.

---

## E5 · Unidades (blocos) e escala (RF03)

### GB-040 · Modelos e services de unidades e escala
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF03
- **Perfil:** Admin
- **Depende de:** GB-004
- **Descrição:** Crie `UnitModel` (coleção `units`) e `InstructorShiftModel` (coleção `instructorShifts`: professor, unidade, dia da semana, início, fim), ambos com changelog, mais os services. Crie uma função pura `currentAndNextShift(shifts, now)` que devolve o turno atual e o próximo (inclusive virando a semana). Regras: o admin escreve; qualquer autenticado lê.
- **Critérios de aceite:**
  - Testes da função de turno atual/próximo (dentro do turno, entre turnos, domingo → segunda, sem escala).

### GB-041 · Tela de unidades (atalho "Blocos" do admin)
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF03
- **Perfil:** Admin
- **Depende de:** GB-040
- **Descrição:** O atalho "Blocos" da home do admin hoje mostra "estará disponível em breve". Ligue-o a uma tela de unidades com listagem, criação, edição e desativação. Avalie com o time se o rótulo continua "Blocos" ou vira "Unidades" e mantenha o termo igual em todo o app.
- **Critérios de aceite:**
  - O atalho não mostra mais "em breve".

### GB-042 · Escala do professor
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF03
- **Perfil:** Admin
- **Depende de:** GB-040
- **Descrição:** Em `InstructorDetailsView`, adicione a seção "Escala", onde o admin inclui e remove turnos (unidade, dia e horário de início/fim). Valide sobreposição de turnos do mesmo professor.
- **Critérios de aceite:**
  - Turnos sobrepostos são recusados com mensagem clara.

### GB-043 · Vínculo do aluno: unidade e modalidade
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF03, RF04
- **Perfil:** Professor, Admin
- **Depende de:** GB-003, GB-040
- **Descrição:** No detalhe do aluno (professor, GB-051; admin, `_StudentSheet` em `instructor_details_view.dart`), permita definir a unidade e a modalidade (Presencial/Remoto) do aluno. Esses campos alimentam o card "Remotos" do admin e os filtros da lista de alunos.
- **Critérios de aceite:**
  - O aluno não consegue alterar a própria unidade nem a modalidade (regra GB-003).

### GB-044 · Exibir unidade atual e próxima nas telas
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF03, RF06
- **Perfil:** Professor, Aluno
- **Depende de:** GB-040, GB-042
- **Remove mock:** "Bloco atual: Bloco A (Manhã)" (`professor_dashboard_view.dart`, `lista_alunos.dart`), card "Próximo Turno: Bloco B 11:00", "BLOCO / TURNO: Bloco A 06:00 - 09:00" (`aluno_profile_view.dart`)
- **Descrição:** O dashboard e a lista do professor mostram o turno atual e o próximo da escala. O perfil do aluno mostra a unidade dele. Sem escala: "Sem turno agora".
- **Critérios de aceite:**
  - Nenhum "Bloco A/B" fixo em `lib/`.

---

## E6 · Gestão de alunos pelo professor (RF02)

### GB-050 · Lista de alunos do professor com dados reais
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF02, RF06
- **Perfil:** Professor
- **Depende de:** GB-053
- **Remove mock:** cards fixos "Pablo" e "Marcos" e a foto `assets/profMarcos.png` em `lista_alunos.dart`
- **Descrição:** `ListaAlunosView` hoje não é aberta por nenhuma tela. Abra-a pelo card "Alunos" do dashboard (e por um "Ver todos"). Ela usa `TeacherUserSearcher.streamLinkedUsers`, com busca por nome e filtros Todos / por unidade / Inativos / Avaliação pendente (chips hoje com `onPressed: () {}`). Cada card mostra foto (`UserAvatar`), status Ativo/Inativo e "Próximo treino…" ou "Inativo (X dias)". **Remova o botão "Mensagem"**; o aluno inativo fica com "Ver perfil" e "Montar treino". A saudação usa o nome real do professor.
- **Critérios de aceite:**
  - O filtro ativo fica destacado visualmente.
  - Teste de widget da busca e dos filtros.
- **Arquivos:** `lib/view/teacher/lista_alunos.dart`, `lib/view/teacher/professor_dashboard_view.dart`

### GB-051 · Detalhe do aluno para o professor ("Ver perfil")
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF02
- **Perfil:** Professor
- **Depende de:** GB-050
- **Descrição:** Crie uma tela com dados do aluno, objetivo, medidas, saúde (condições, restrições, observações), contato de emergência, ficha atual, última sessão e próxima avaliação, com as ações "Editar treino" (GB-052), "Agendar avaliação" (GB-061) e o vínculo de unidade/modalidade (GB-043). Extraia o `_StudentSheet` de `instructor_details_view.dart` para um componente compartilhado em vez de duplicar.
- **Critérios de aceite:**
  - Admin e professor usam o mesmo componente de ficha do aluno.

### GB-052 · "Editar treino" abre a montagem com o aluno selecionado
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF02, RF08
- **Perfil:** Professor
- **Depende de:** GB-023, GB-050
- **Descrição:** `ProfessorMontagemTreinoView` hoje sempre começa no primeiro aluno. Aceite um `alunoId` inicial e permita trocar de aba no `ProfessorAreaView` já com o aluno escolhido (ex.: callback ou `ValueNotifier` no `ProfessorAreaView`). A lista de alunos da montagem também precisa se atualizar quando um aluno novo se vincula (hoje ela usa `.first` do stream, ou seja, só lê uma vez).
- **Critérios de aceite:**
  - Tocar em "Editar treino" na lista leva à montagem com o aluno certo.

### GB-053 · Cálculo de status do aluno (ativo, risco, inativo)
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF02, RF04, RF06
- **Perfil:** —
- **Depende de:** GB-031, GB-004
- **Descrição:** Crie `lib/service/students/student_status.dart` com funções puras: `daysWithoutTraining(lastFinishedAt, now)` e `statusFor(...) → ativo | risco | inativo | novo` (novo = cadastrado e ainda sem sessão), usando as constantes P1/P2. Todas as telas (dashboard, lista, admin) usam essa função.
- **Critérios de aceite:**
  - Testes unitários cobrindo cada limite.

---

## E7 · Avaliações físicas e evolução (RF12)

### GB-060 · Modelo e service de avaliações físicas
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF12
- **Perfil:** Professor, Aluno
- **Depende de:** GB-004
- **Descrição:** Crie `AssessmentModel` (+ changelog) conforme a coleção `assessments` do `AGENTS.md`: aluno, professor, tipo (presencial/online), `scheduledAt`, `performedAt`, status (`scheduled`/`done`/`cancelled`), peso, % de gordura, massa magra e observações profissionais. Service: `schedule`, `record`, `cancel`, `streamForStudent`, `pendingForInstructor`. Regras: o professor responsável cria e edita; o aluno lê as próprias; o admin lê todas. **Dado de saúde:** nunca exiba para outro aluno.
- **Critérios de aceite:**
  - Testes com `fake_cloud_firestore`.

### GB-061 · Professor: agendar avaliação
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF12
- **Perfil:** Professor
- **Depende de:** GB-060
- **Descrição:** Pelo detalhe do aluno ou pela aba Evolução, o professor escolhe data, hora e tipo. O aluno recebe uma notificação (GB-112).
- **Critérios de aceite:**
  - Não permite agendar no passado.
  - O aluno vê "Avaliação presencial marcada com o Prof. {nome}" na Evolução.

### GB-062 · Aba Evolução do professor: registrar avaliações
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF12
- **Perfil:** Professor
- **Depende de:** GB-060
- **Remove mock:** `_AbaProfessorPendente` "Tela em desenvolvimento" (`professor_area_view.dart`)
- **Descrição:** A aba lista as avaliações pendentes e vencidas dos alunos do professor e permite buscar um aluno para ver o histórico. "Registrar avaliação" abre um formulário com peso, % de gordura, massa magra e observações profissionais, com validação de faixas plausíveis.
- **Critérios de aceite:**
  - Uma avaliação registrada aparece na hora na Evolução do aluno.

### GB-063 · Evolução do aluno com dados reais
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF12
- **Perfil:** Aluno
- **Depende de:** GB-060
- **Remove mock:** valores fixos de `aluno_evolucao_view.dart` (71,2 kg, 28,4%, 51,1 kg, datas de junho/março de 2026, "Prof. Marcos")
- **Descrição:** Gráfico de peso com `fl_chart` (já é dependência do projeto) e filtros 3 meses / 6 meses / 1 ano funcionando. Cards de gordura e massa magra com a variação em relação à avaliação anterior. Última observação profissional. Histórico de avaliações (data e tipo). Próxima avaliação agendada. Estado vazio: "Sua primeira avaliação ainda não foi registrada".
- **Critérios de aceite:**
  - Nenhum `onPressed: () {}` na tela.
  - Teste de widget com 0, 1 e N avaliações.

### GB-064 · Regras de avaliação pendente, próxima do vencimento e vencida
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF05, RF06, RF12
- **Perfil:** —
- **Depende de:** GB-060
- **Descrição:** Crie funções puras (`isPending`, `isDueSoon` (P4), `isOverdue`) usadas pelo dashboard do professor, pelo filtro "Avaliação pendente" e pela equipe no admin.
- **Critérios de aceite:**
  - Testes unitários.

---

## E8 · Painel do professor (RF06)

### GB-070 · Dashboard do professor: saudação, unidade e acesso aos alunos
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF06
- **Perfil:** Professor
- **Depende de:** GB-044
- **Remove mock:** "Olá, Marcos" fixo
- **Descrição:** A saudação usa o nome do professor logado. O card "Alunos ativos" abre a lista (GB-050). A raiz da aba não mostra a seta de voltar (`showBackButton: false`).
- **Critérios de aceite:**
  - Teste de widget com nome vindo do service.

### GB-071 · Dashboard do professor: presenças de hoje e risco de evasão
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF06
- **Perfil:** Professor
- **Depende de:** GB-031, GB-053
- **Remove mock:** "Presenças 15 hoje" e "3 Risco de evasão"
- **Descrição:** Presenças = alunos do professor com sessão finalizada hoje. Risco de evasão = alunos com status `risco`. Tocar no card de risco abre a lista já filtrada.
- **Critérios de aceite:**
  - Contadores batem com os dados do Firestore em teste com `fake_cloud_firestore`.

### GB-072 · Dashboard do professor: prioridades e alertas gerados
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF06
- **Perfil:** Professor
- **Depende de:** GB-053, GB-064, GB-020
- **Remove mock:** cards fixos "Ana Lima", "Bruno Alves", "Carla Souza" e o badge "3 Alertas"
- **Descrição:** Gere a lista de prioridades: avaliação vence em X dias → "Revisar" (abre o aluno); X dias sem treinar → "Ver perfil" ("Contatar" sai junto com a Mensagem); sem ficha ativa ou ficha vencida → "Montar" (abre a montagem com o aluno). O badge mostra o total. Ordene por gravidade.
- **Critérios de aceite:**
  - Cada ação navega para a tela correta.
  - Estado vazio: "Nenhuma pendência hoje".

---

## E9 · Painel administrativo e gestão da equipe (RF04, RF05)

### GB-080 · Home do admin: cards de remotos e inativos reais
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RF04
- **Perfil:** Admin
- **Depende de:** GB-043, GB-053
- **Remove mock:** `AdminHomeMockData.remoteStudents` e `inactiveStudents`
- **Descrição:** Remotos = alunos com `modality == 'remote'`. Inativos (30d+) = status `inativo`. Revise também "Alunos ativos": hoje ele conta todos os alunos cadastrados (`getStudentStats.total`); com sessões, ativos = total − inativos.
- **Critérios de aceite:**
  - Testes do `AdminDashboardService` atualizados.

### GB-081 · Home do admin: horários de maior movimento
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF04
- **Perfil:** Admin
- **Depende de:** GB-031
- **Remove mock:** `AdminHomeMockData.hourlyMovement`, `peakLabel`, `hourLabels`
- **Descrição:** Agrupe por hora as sessões iniciadas nos últimos 30 dias (06h–22h) e destaque o pico. Filtro opcional por unidade.
- **Critérios de aceite:**
  - Teste unitário da agregação.
  - Estado vazio quando não há sessões.

### GB-082 · Ocorrências operacionais
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF04
- **Perfil:** Admin, Professor
- **Depende de:** GB-040
- **Descrição:** Crie `OccurrenceModel` (coleção `occurrences`: título, descrição, unidade, severidade, autor, status aberta/resolvida) com service e regras. Professor e admin registram (ex.: "Esteira 04 com ruído"); só o admin resolve. Defina com o time onde fica o botão "Registrar ocorrência" do professor (sugestão: Perfil ou dashboard).
- **Critérios de aceite:**
  - Uma ocorrência aberta aparece nos alertas do admin com o autor ("Último registro: Prof. X").

### GB-083 · Alertas operacionais do admin (ocorrências + automáticos)
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF04
- **Perfil:** Admin
- **Depende de:** GB-082, GB-086, GB-053
- **Remove mock:** `AdminHomeMockData.alerts` (incluindo o alerta de lotação do Spinning, que sai de vez)
- **Descrição:** Junte as ocorrências abertas com os alertas calculados: professor acima da capacidade, avaliações vencidas por professor, treinos vencidos e inativos acima do limiar P6. Depois disso, apague `lib/view/admin/mocks/admin_home_mock_data.dart`.
- **Critérios de aceite:**
  - Cada alerta automático leva à tela relacionada (equipe, detalhes do professor).

### GB-084 · Atalhos da home do admin
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF04
- **Perfil:** Admin
- **Depende de:** GB-041, GB-100
- **Descrição:** "Blocos" → tela de unidades (GB-041). "Aulas" → grade de aulas (GB-100). **Remova "Finanças"** (pagamento fora do escopo). Remova `_showSoon` quando não sobrar uso.
- **Critérios de aceite:**
  - Nenhum SnackBar "estará disponível em breve" na home do admin.

### GB-085 · Especialidade e capacidade por professor
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF05
- **Perfil:** Admin
- **Depende de:** GB-003
- **Remove mock:** `AdminTeamMockData.studentCapacity` e `instructorRole`; "Especialista" fixo no perfil do aluno
- **Descrição:** Adicione os campos especialidade e capacidade de alunos no `RegisterInstructorView` e uma ação "Editar professor" em `InstructorDetailsView`. A carga (%) e o status "Sobrecarga" usam a capacidade do próprio professor (com padrão de 30 quando vazio). O perfil do aluno mostra a especialidade real do professor responsável.
- **Critérios de aceite:**
  - Testes de widget de cadastro e edição atualizados.

### GB-086 · Equipe: avaliações pendentes e treinos vencidos por professor
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF05
- **Perfil:** Admin
- **Depende de:** GB-020, GB-064, GB-085
- **Remove mock:** `AdminTeamMockData.pendingEvaluations` (`'--'`) e, ao final, o arquivo `admin_team_mock_data.dart`
- **Descrição:** No `AdminDashboardService.getTeamWorkload` e em `getInstructorDetails`, inclua avaliações pendentes/vencidas e fichas vencidas (`validUntil < hoje`) por professor. Mostre os números no card do professor, nos detalhes e no comparativo. "Ver pendências" abre os detalhes com essa seção em foco.
- **Critérios de aceite:**
  - Testes do service com `fake_cloud_firestore`.

---

## E10 · Home do aluno (RF13)

### GB-090 · Home do aluno: treino em destaque e professor responsável
- **Tipo:** História
- **Prioridade:** Alta
- **Tamanho:** M
- **Requisito:** RF13
- **Perfil:** Aluno
- **Depende de:** GB-030, GB-034
- **Remove mock:** "Treino do dia — Pernas + Glúteos / Nível intermediário…" fixos
- **Descrição:** Mostre a ficha recomendada (GB-034) com foco e nível. "Iniciar treino" (hoje `onPressed: () {}`) abre a execução (`AlunoTreinoDiaView`). Exiba o professor responsável (nome e foto). Sem ficha: "Aguardando seu professor montar seu treino".
- **Critérios de aceite:**
  - Teste de widget com e sem ficha.

### GB-091 · Home do aluno: sequência e resumo de evolução
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF13
- **Perfil:** Aluno
- **Depende de:** GB-031, GB-060
- **Remove mock:** "12 dias — Você está on fire!" e "+15% esta semana"
- **Descrição:** Sequência conforme a regra P3, calculada das sessões. O resumo de evolução mostra a variação de peso (ou de gordura) entre as duas últimas avaliações.
- **Critérios de aceite:**
  - Testes unitários do cálculo da sequência.

### GB-092 · Home do aluno: próxima aula ou atividade
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF13
- **Perfil:** Aluno
- **Depende de:** GB-100, GB-060
- **Remove mock:** "Pilates — Próxima aula hoje às 18h"
- **Descrição:** Mostre o próximo evento entre a próxima aula da grade da unidade do aluno e a próxima avaliação agendada (o que vier primeiro).
- **Critérios de aceite:**
  - Estado vazio quando não há aula nem avaliação.

### GB-093 · Home do aluno: atalhos Saúde, Treinar em casa, Aulas e Avaliação
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF13, RF14
- **Perfil:** Aluno
- **Depende de:** GB-030, GB-101, GB-063
- **Descrição:** Os 4 botões hoje com `onPressed: () {}` passam a funcionar: Saúde → seção de saúde do Perfil; Treinar em casa → aba Treinos com "Treinar em casa" selecionado; Aulas → grade (GB-101); Avaliação → aba Evolução.
- **Critérios de aceite:**
  - Nenhum `onPressed: () {}` em `aluno_home_view.dart`.

---

## E11 · Aulas e treino em casa

### GB-100 · Grade de aulas: modelo e cadastro pelo admin
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF13
- **Perfil:** Admin
- **Depende de:** GB-040
- **Descrição:** Use a coleção `gym_classes` (já prevista em `firestore.rules`, hoje sem escrita). Crie `GymClassModel` (+ changelog): modalidade, unidade, professor, dia da semana, horário, duração, capacidade **só informativa** e `active`. O admin cadastra e edita a grade. **Sem reserva e sem alerta de lotação.** Ajuste a regra para o admin poder escrever.
- **Critérios de aceite:**
  - Testes do service.

### GB-101 · Grade de aulas para o aluno (somente leitura)
- **Tipo:** História
- **Prioridade:** Baixa
- **Tamanho:** P
- **Requisito:** RF13
- **Perfil:** Aluno
- **Depende de:** GB-100
- **Descrição:** Uma tela com as aulas da semana da unidade do aluno, agrupadas por dia, sem botão de reserva.
- **Critérios de aceite:**
  - Mostra só aulas ativas da unidade do aluno.

### GB-102 · Treinar em casa: treinos complementares reais
- **Tipo:** História
- **Prioridade:** Baixa
- **Tamanho:** M
- **Requisito:** RF09
- **Perfil:** Aluno, Professor
- **Depende de:** GB-030
- **Remove mock:** `complementares` de `TreinosMockData` (pilates, dança etc.)
- **Descrição:** A seção "Treinos complementares / vídeos guiados" passa a listar fichas com modalidade `home` marcadas como complementares pelo professor. **Sem vídeo** (decisão desta entrega): o card mostra imagem, duração e descrição. Avalie trocar o título "Vídeos guiados" por "Treinos guiados".
- **Critérios de aceite:**
  - Seção oculta quando não há complementares.

---

## E12 · Navegação e notificações (RF14)

### GB-110 · Modelo e service de notificações
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF14
- **Perfil:** Todos
- **Depende de:** GB-004
- **Descrição:** Crie `AppNotificationModel` (+ changelog) na coleção `notifications` (destinatário, tipo, título, corpo, `relatedId`, `read`, `createdAt`). Service: `streamForUser`, `unreadCount`, `markAsRead`, `markAllAsRead`, `send`. Regras: o destinatário lê e só altera `read`; professor/admin criam notificações apenas para usuários relacionados (alunos vinculados, ou qualquer um no caso do admin).
- **Critérios de aceite:**
  - Testes com `fake_cloud_firestore`.

### GB-111 · Tela de notificações e badge no sino
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RF14
- **Perfil:** Todos
- **Depende de:** GB-110
- **Descrição:** O `CustomAppBar` abre a tela de notificações por padrão (hoje `onNotificationPressed` é nulo em todas as telas) e mostra um badge com as não lidas. Tocar numa notificação marca como lida e navega para o item relacionado (treino, avaliação).
- **Critérios de aceite:**
  - O badge some ao ler tudo.
  - Estado vazio.

### GB-112 · Gatilhos de notificação
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF14
- **Perfil:** Professor, Aluno
- **Depende de:** GB-111, GB-023, GB-061
- **Descrição:** Sem Cloud Functions, quem faz a ação cria a notificação no mesmo fluxo: treino atribuído/atualizado → aluno; avaliação agendada → aluno; avaliação registrada → aluno. Respeite a preferência "Avisos do professor" do aluno (`PreferencesService.professorNotices`). Como hoje ela é local, avalie movê-la para o documento do usuário.
- **Critérios de aceite:**
  - Com a preferência desligada, o aluno não recebe avisos do professor.

### GB-113 · Revisão da navegação por perfil
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RF14, RNF02
- **Perfil:** Todos
- **Depende de:** GB-012, GB-062
- **Descrição:** Abas finais: **Aluno**: Início, Treinos, Evolução, Perfil. **Professor**: Início, Treinos (montagem), Evolução, Perfil, com a lista de alunos aberta pelo Início. **Admin**: Início, Exercícios, Equipe, Perfil. Telas raiz de aba usam `showBackButton: false` (hoje várias mostram uma seta que não volta para lugar nenhum). Tocar de novo na aba do professor volta à raiz, como já acontece no `MainShell`.
- **Critérios de aceite:**
  - `tab_router_test.dart` cobre as abas dos 3 perfis.

---

## E13 · Escopo, interface e qualidade (RNF02)

### GB-120 · Remover Plano e Mensalidade
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** Restrição 8
- **Perfil:** Aluno, Professor
- **Depende de:** —
- **Remove mock:** "Plano Conexão Semestral", "Renovação em 10/11/2023", "#GB-2023-0482", "Musculação + Pilates" e "Plano Presencial + App" (`aluno_profile_view.dart`)
- **Descrição:** Remova o card "Plano e Mensalidade" e o selo de plano do resumo do perfil. Pagamentos estão fora do escopo.
- **Critérios de aceite:**
  - `aluno_profile_view_test.dart` atualizado.

### GB-121 · Remover "Mensagem" e "Redistribuir alunos"
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** Escopo
- **Perfil:** Professor, Admin
- **Depende de:** —
- **Descrição:** Remova o botão "Mensagem" do `CardAluno` (`lista_alunos.dart`) e o asset `mensagem.svg`, se ficar sem uso. Remova "Redistribuir Alunos" de `admin_team_view.dart` e `instructor_details_view.dart`, com as respectivas keys nos testes.
- **Critérios de aceite:**
  - Testes de admin passando sem as keys `botao_redistribuir_*`.

### GB-122 · Tela de Privacidade e Termos
- **Tipo:** História
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RNF01
- **Perfil:** Todos
- **Depende de:** —
- **Descrição:** "Privacidade & Termos" no perfil não tem ação, e o autocadastro pede o aceite dos "Termos de Uso e Política de Privacidade (LGPD)" sem mostrar o texto. Crie a tela com o texto (fornecido pelo time) e ligue-a nos dois lugares.
- **Critérios de aceite:**
  - O link no autocadastro abre o texto sem perder o rascunho do cadastro.

### GB-123 · Perfil: remover textos fixos restantes
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** P
- **Requisito:** RNF02
- **Perfil:** Aluno
- **Depende de:** GB-085
- **Remove mock:** "Avisos do Prof. Marcos"
- **Descrição:** "Avisos do Prof. {nome do responsável}". Aplique a decisão P7 sobre o toggle "Lembrete diário".
- **Critérios de aceite:**
  - Nenhum nome de pessoa fixo em `lib/` (`grep -rn "Marcos" lib` vazio).

### GB-124 · Padronização visual com o tema
- **Tipo:** Tarefa
- **Prioridade:** Média
- **Tamanho:** M
- **Requisito:** RNF02
- **Perfil:** Todos
- **Depende de:** —
- **Descrição:** `professor_dashboard_view.dart` e `lista_alunos.dart` declaram cores locais (`Color(0xFF001E2D)`, `0xFFBA1A1A`…), e `tab_router.dart`/`professor_area_view.dart` usam `Color(0xFFE5E5E5)`. Mova tudo para `AppColors` (criando tokens se faltar) e alinhe tipografia (Barlow Condensed para títulos, Inter para texto) conforme o protótipo. Os estados de carregando, vazio e erro seguem um componente único (`lib/view/components/`).
- **Critérios de aceite:**
  - `grep -rn "Color(0x" lib/view` só encontra resultados dentro de `lib/theme/`.

### GB-125 · Eliminar a pasta mocks de lib/
- **Tipo:** Tarefa
- **Prioridade:** Alta
- **Tamanho:** P
- **Requisito:** RNF02
- **Perfil:** —
- **Depende de:** GB-030, GB-021, GB-083, GB-086
- **Descrição:** Depois das integrações, mova para `test/fixtures/` os dados de exemplo ainda usados pelos testes (`aluno_treino_dia_view_test.dart`, `aluno_exercicio_detalhe_view_test.dart` e `aluno_treinos_view_test.dart` importam `TreinosMockData`) e apague `lib/view/**/mocks/`. Esse é o card de fechamento do "tirar dados mockados".
- **Critérios de aceite:**
  - `grep -rni "mock" lib/` não retorna dados falsos.
  - `flutter test` passando.

### GB-126 · Testes das regras do Firestore no emulador
- **Tipo:** Tarefa
- **Prioridade:** Baixa
- **Tamanho:** M
- **Requisito:** RNF01
- **Perfil:** —
- **Depende de:** GB-001
- **Descrição:** Configure o Firebase Emulator e uma suíte `@firebase/rules-unit-testing` em `firestore-tests/` cobrindo os cenários de permissão de cada coleção (aluno x aluno, professor x aluno de outro professor, admin). Opcionalmente, rode no CI.
- **Critérios de aceite:**
  - `npm test` em `firestore-tests/` passa localmente.

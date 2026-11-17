# AGB-205 — Login interativo Grazi Braz

## Entrega

Redesign implementado em `lib/view/login_view.dart`, com componentes locais em
`lib/view/login/`. Não é um esqueleto nem uma imagem sobreposta ao aplicativo:
os campos, botões e estados são widgets Flutter funcionais.

Base examinada: `sprint-7`, commit
`13fdc062dffb4045e79c3cb3b4519512dc8f2648` (inclui Planos e Mensalidades).

## Visual e interação

- Logo oficial centralizado, headline “Seu corpo. Seu ritmo.” e formulário claro
  com cantos arredondados, campos com ícones, CTA verde e criação de conta.
- Presencial: fotografia local do estúdio, texto de acompanhamento presencial.
- Treino em casa: fotografia local de casa, texto de flexibilidade.
- Alternância automática a cada 5 segundos, transição de 550 milissegundos.
- Escolha manual adia a próxima alternância por 8 segundos.
- Com foco em e-mail ou senha, o automático permanece pausado, mesmo sem digitar.
  Depois de sair dos campos, retoma após 8 segundos sem nova interação.
- Uma requisição de login/recuperação, cadastro aberto ou app em segundo plano
  também interrompe a rotação. Não existe botão visível de pausa/retomada.
- `disableAnimations` ou `accessibleNavigation` do MediaQuery desliga a rotação
  e as transições decorativas; mantém a seleção manual.
- Os dois textos reservam a mesma área, impedindo saltos do formulário durante
  a troca. Controladores e conteúdo dos campos são preservados.
- Largura máxima de 430 pixels no desktop. Rolagem em telas pequenas, paisagem,
  teclado aberto e texto ampliado. Não há moldura de celular no app real.

Os valores de tempo e os textos estão centralizados em
`lib/view/login/login_scene.dart`. São parâmetros de apresentação, não regras
comerciais e não são persistidos no Firebase.

## Fotografias e identidade

Usa o logo existente e **dois assets novos incluídos no pacote**, na pasta `assets/login/` já registrada no `pubspec.yaml`:

```
assets/logoLogin.png
assets/login/agb205_presencial.webp
assets/login/agb205_casa.webp
```

As imagens foram preparadas a partir do conceito visual aprovado e mostram
ambientes acolhedores, sem destaque em pessoas. As imagens antigas permanecem no
repositório, mas não são usadas pelo novo login.

Nenhum download de imagem acontece no uso da tela. As duas fotografias permanecem
montadas para evitar piscadas ao alternar. Se uma imagem falhar, há um fundo neutro
que preserva a utilização do formulário.

A imagem dos dois telefones aprovada na conversa é **referência conceitual**, não
um screenshot da implementação nem um asset usado no aplicativo. Esta entrega
usa as fotografias do repositório, não recortes da imagem dos aparelhos.

A fonte vem do `AppTheme` existente (Barlow Condensed). Cores usam os tokens
`AppColors`. A headline em caixa de frase e o botão verde seguem o conceito de
login aprovado e o botão verde que já existia; a exceção local está registrada no
AGENTS.md. O tema global não foi alterado. A máscara sobre as fotos é neutra e não
recria o gradiente institucional.

## O que foi preservado

- `LoginController.loginUser` e `resetPassword` existentes.
- `AuthWrapper` como destino após autenticação: perfis, `StudentAccessGate` e
  bloqueio por mensalidade continuam no caminho original.
- Cadastro por `SelfRegisterView`, convite, termos, recuperação de senha e
  visibilidade da senha.
- `welcome_view.dart`, abertura animada, faixa corrigida pelo AGB-139.
- Planos e Mensalidades, regras e índices Firestore, todos os outros perfis.
- Dependências e `pubspec.yaml`; nenhuma atualização de pacote é necessária.

A alternância NÃO muda perfil, modalidade cadastrada, plano, permissão ou conta.

## Arquivos do card

Alterados:
- `lib/view/login_view.dart`
- `test/view/login_view_test.dart` — só o helper desliga o automático nos testes
  legados de autenticação. Nenhum teste é apagado ou tem asserção removida.
- `AGENTS.md` — acréscimo específico do AGB-205, sem apagar regras anteriores.
- `docs/BACKLOG.md` — acréscimo do card, sem alterar o escopo financeiro.

Novos:
- `lib/view/login/login_scene.dart`
- `lib/view/login/login_visuals.dart`
- `test/view/login/login_interactive_view_test.dart`
- `docs/AGB-205_LOGIN.md`

## Testes entregues

A suíte nova cobre estado inicial, troca automática/manual, conservação de
credenciais e posição, pausa no foco, retomada após 8 segundos, remoção do botão de pausa,
redução de movimento, segundo plano, descarte do timer, ida/volta ao cadastro,
requisição duplicada, exceções de login/recuperação, cinco tamanhos de viewport,
teclado e texto ampliado. A suíte original continua cobrindo o destino AuthWrapper,
campos vazios, visibilidade, cadastro e recuperação.

Execute, na pasta do worktree:

```bat
flutter pub get
dart run build_runner build
dart format lib/view/login_view.dart lib/view/login test/view/login_view_test.dart test/view/login
flutter analyze
flutter test test/view/login_view_test.dart test/view/login/login_interactive_view_test.dart
flutter test
git diff --check
```

## Homologação manual

1. Abrir deslogado: a abertura animada continua igual; em seguida aparece o login.
2. Sem tocar, aguardar a alternância. Conferir a fotografia, a legenda e o seletor.
3. Alternar manualmente, digitar e conferir que os campos não são apagados.
4. Manter o foco num campo por mais de 10 segundos: cenário não deve trocar.
5. Sair dos campos e aguardar 8 segundos; conferir que a rotação retoma automaticamente.
6. Testar entrar com credencial válida, inválida, campos vazios e recuperação.
7. Abrir cadastro e voltar: e-mail e senha preenchidos permanecem no login.
8. Testar aluno, professor e admin. Para aluno, testar também o controle de
   acesso por mensalidades existente, sem alterá-lo.
9. Verificar no Chrome e Android com teclado aberto, janela estreita e texto
   ampliado. Verificar configuração do sistema para redução de animações.

## Situação de validação na entrega do pacote

O código foi inspecionado e o instalador é acompanhado de testes Python locais.
O ambiente que produziu o ZIP não tem Flutter/Dart instalado: **analyze, testes
Flutter e renderização do app ainda devem ser executados no ambiente do projeto**.
`01_TESTAR.cmd` automatiza esses comandos e interrompe na primeira falha.
Não há alegação de testes Flutter já aprovados nesta entrega.

Não fazer deploy do Firebase, seed, `pub upgrade`, `reset --hard`, `clean -fd`
ou push direto à sprint para aplicar este card.

## Revisão visual V2 (17/11/2026)

- Substituídas as imagens anteriores pelos cenários com sala/estúdio em tons
  quentes, plantas, equipamentos discretos e ambiente doméstico com tapete e
  halteres, conforme o mockup aprovado.
- Excluída a legenda adicional “conexão e movimento” abaixo do seletor, mantendo
  somente o logo e o título principal.
- Excluído o controle visível de pausar e retomar imagens; a animação continua
  automática e pausa quando há foco ou interação com o formulário.
- Corrigido o teste de lifecycle (`AppLifecycleState`) com transições válidas.
- Nenhum dado de usuário, plano, mensalidade ou autenticação foi alterado.

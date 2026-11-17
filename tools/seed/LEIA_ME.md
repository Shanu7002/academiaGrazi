# Dados de demonstração (Firestore DEV)

Popula o projeto `academia-grazi-dev-ab105` com dados **fictícios** no mesmo formato que o app grava. Use para demonstrações e testes manuais. Nunca rode em produção: o script recusa qualquer outro projeto.

## O que é criado

| Item | Quantidade |
|---|---|
| Contas de login (Firebase Auth) | 35: 1 admin, 4 professores, 30 alunos |
| Unidades (`units`) | 2: Bloco Centro e Bloco Jardim |
| Escala (`instructorShifts`) | 18 turnos |
| Grade de aulas (`gym_classes`) | 13 aulas |
| Fichas publicadas (`trainingPlans` + `trainingState`) | alunos presenciais |
| Treino em casa (`homeWorkouts`) | 6 alunos remotos |
| Sessões finalizadas (`trainingSessions`) | ~400, nas últimas 8 semanas |
| Avaliações físicas (`evaluations`) | 2 ou 3 por aluno (menos os novos) |

Os alunos têm perfis de frequência diferentes (ativos, irregulares, em risco de evasão, inativos e novos), para os painéis do admin e do professor ficarem preenchidos.

**Contas principais:**

| Perfil | E-mail |
|---|---|
| Admin Demonstração | `admin@demo.com` |
| Professor Demonstração | `prof@demo.com` |
| Aluno Demonstração | `aluno@demo.com` (aluno do Professor Demonstração; tem treino de segunda a sábado) |

Os demais e-mails seguem `nome.sobrenome@demo.com` e aparecem na simulação. Todas as contas usam a senha de `SENHA_DEMO`.

Tudo tem ID com prefixo `demo-`. Rodar de novo **substitui** os dados `demo-*` (as datas são recalculadas a partir de hoje). Nada fora do prefixo é alterado.

## Como rodar

1. Gere uma chave de conta de serviço: Console do Firebase → Configurações do projeto → Contas de serviço → **Gerar nova chave privada**. Guarde o JSON **fora do repositório** e nunca o envie no chat nem para o Git.
2. Instale as dependências:
   ```bash
   cd tools/seed
   npm install
   ```
3. Simule (não grava nada):
   ```bash
   npm run simular
   ```
4. Grave:
   ```bash
   GOOGLE_APPLICATION_CREDENTIALS=/caminho/fora/do/repo/chave.json \
   SENHA_DEMO='sua-senha' \
   npm run popular:dev
   ```

Se algum e-mail `@demo.com` já existir com outra conta (por exemplo, um `admin@demo.com` criado à mão no Console), o script para antes de gravar e lista os e-mails. Apague essas contas em Authentication e rode de novo.

## Planos e mensalidades

`popular_planos.cjs` cuida só de `membershipPlans` e `memberships`. Ele **apaga todos os planos do catálogo e todos os planos dos alunos** que existirem (não só os `demo-*`), cria 6 planos (um deles fora do catálogo) e atribui um plano a quase todos os alunos, com situações variadas: em dia, vence em breve, uma ou duas mensalidades em atraso, novo, encerrado e sem plano. Alunos remotos recebem o "Plano Treino em Casa". Os alunos com atraso de 8 ou 20 dias ficam com o **app bloqueado** (tolerância de 5 dias); `aluno@demo.com` fica sempre em dia. Não cria contas, então não precisa de `SENHA_DEMO`.

```bash
GOOGLE_APPLICATION_CREDENTIALS=/caminho/fora/do/repo/chave.json node popular_planos.cjs           # simula
GOOGLE_APPLICATION_CREDENTIALS=/caminho/fora/do/repo/chave.json node popular_planos.cjs --apply   # grava
```

Rode depois do `popular:dev`: as datas são calculadas a partir de hoje. O `limpar:dev` também remove os planos `demo-*`.

## Como remover tudo

```bash
GOOGLE_APPLICATION_CREDENTIALS=/caminho/fora/do/repo/chave.json npm run limpar:dev
```

Apaga as contas e os documentos `demo-*`, incluindo as subcoleções dos alunos.

## Testes

```bash
npm test
```

Os testes conferem os vínculos (aluno → professor → unidade, programação → treinos), as datas das sessões, os perfis de frequência e que nenhuma senha vai para os documentos.

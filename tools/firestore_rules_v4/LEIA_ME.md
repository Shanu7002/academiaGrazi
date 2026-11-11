# Testes de regras Firestore - Academia Grazi

Esta suite testa o arquivo oficial `firestore.rules`, na raiz do repositorio.
Contem 102 cenarios de seguranca e nunca acessa o banco Firebase real.

## Instalar e executar

No CMD do Windows:

```cmd
cd /d C:\Projetos\academiaGrazi\tools\firestore_rules_v4
npm ci
npm test
```

- `npm test` entra automaticamente na raiz do repositorio para executar o emulador.
- Configuracao de teste: `firebase.rules-test.json`, situada na raiz.
- Regras sob teste: `firestore.rules`, tambem na raiz (sem copias divergentes).
- Projeto ficticio isolado: `demo-grazi-local`.
- Emulador: `127.0.0.1:18085`.
- A biblioteca `@firebase/rules-unit-testing` le as mesmas regras para realizar os testes.
- Nunca execute `firebase deploy` para testar as regras.

O `firebase.json` da raiz continua reservado ao projeto Flutter. Nao use
`tools/firestore_rules_v4/firebase.json`: a CLI impede referencias a rules
fora da raiz do projeto.

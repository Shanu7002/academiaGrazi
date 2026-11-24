# Instruções de Marca — Grazi Braz

> Fonte oficial da identidade visual e do tom de voz. As regras já aplicadas ao app (tokens, tema e ajustes de leitura) estão no `AGENTS.md`, §7.1.

Siga estas regras em qualquer conteúdo, interface, peça visual ou texto gerado para a marca Grazi Braz. Em caso de conflito com preferências genéricas de design, este documento prevalece.

## 1. Identidade

- Nome: **GRAZI BRAZ** (sempre em caixa alta no logotipo)
- Segmento: treino personalizado (personal trainer)
- Assinatura/tagline: **conexão e movimento**
- Descritor secundário: *Treino personalizado*
- Conceito central: uma marca que gera impacto — humano, na comunidade, na natureza e na saúde

### Verbos de ação da marca

- **CONECTAR** — o que nos torna humanos. Construir vínculo, colocar-se no lugar do outro, entender dores e necessidades. Conectar o outro a si e o todo à natureza.
- **MOVIMENTAR** — o que gera bem-estar. Movimentar braços, pernas e mente. Movimento requer esforço, disciplina e, principalmente, propósito.

## 2. Tom de voz

- Próximo, humano, motivador e acolhedor; sem agressividade de "academia hardcore"
- Escrita clara, simples e sem ruídos — frases curtas, fácil entendimento
- Fala com o aluno em segunda pessoa ("você", "sua energia de treino")
- Pode usar perguntas para engajar (ex.: "Como está sua **energia de treino** para esta semana?")
- Pode usar humor leve em opções/enquetes (ex.: "Animação total", "De arrasto", "Game over")
- Temas recorrentes: disciplina, propósito, constância, bem-estar, comunidade, saúde
- Idioma principal: português do Brasil. Frases de impacto em inglês são permitidas pontualmente (ex.: "KEEP PUSHING BEYOND LIMITS")

## 3. Tipografia

- Fonte única: **Barlow Condensed** (Google Fonts)
- Títulos e logotipo: Barlow Condensed, peso Medium/SemiBold, CAIXA ALTA, tracking levemente aberto
- Tagline e subtítulos de seção: Barlow Condensed *Italic*, peso Light/Regular, caixa baixa ou título
- Corpo de texto: Barlow Condensed Light/Regular, tracking levemente aberto
- Destaques no corpo: palavra-chave em CAIXA ALTA e/ou bold na cor de impacto
- Padrão de título de seção: `PALAVRA EM CAIXA ALTA / Complemento em itálico` (ex.: `INTRODUÇÃO / Posicionamento`, `GRAZI BRAZ / Conexão e movimento`)

```css
@import url('https://fonts.googleapis.com/css2?family=Barlow+Condensed:ital,wght@0,300;0,400;0,500;0,600;0,700;1,300;1,400&display=swap');
font-family: 'Barlow Condensed', sans-serif;
```

## 4. Cores

### Paleta principal

| Função | Nome | HEX | Pantone |
|---|---|---|---|
| Cor de impacto | Laranja | `#E37747` | 164C |
| Cor institucional | Verde | `#02594F` | 3292C |
| Ponto de luz | Amarelo | `#F2BE48` | 142C |
| Pontos de atenção e respiro | Azul/Índigo | `#2A327B` | 2746C |

### Apoio (amostrado do manual, não oficial)

| Função | HEX |
|---|---|
| Texto corrido | `#707070` |
| Fundo claro (off-white) | `#EBE8E6` a `#FFFFFF` |

```css
:root {
  --gb-laranja: #E37747;
  --gb-verde: #02594F;
  --gb-amarelo: #F2BE48;
  --gb-azul: #2A327B;
  --gb-texto: #707070;
  --gb-fundo: #EBE8E6;
  --gb-branco: #FFFFFF;
}
```

### Proporção e uso

Ordem de predominância: laranja > verde > amarelo > azul.

- **Laranja (impacto):** chamar atenção para a frase principal, CTAs, palavras-chave em destaque
- **Verde (institucional):** cor da marca e do logo; gerar contraste e entendimento; fundos institucionais; o logo sempre pode ser aplicado em verde
- **Amarelo (ponto de luz):** trazer luz a um assunto; parte mais clara e iluminada da arte; brilho e nuances; títulos de seção sobre fundo claro
- **Azul (questionar/respiro):** perguntas ao público e pontos de atenção; traz seriedade de forma diferente do verde; ajuda a compor com o verde sem saturar de cor escura. Usar com moderação
- **Cinza:** texto corrido

## 5. Gradiente

- Gradiente orgânico, fluido e desfocado (mesh/blur) combinando laranja, amarelo, azul e verde, com textura granulada (noise) sutil
- Usos: capas, faixas laterais verticais, barras de destaque, contorno do símbolo, ícones na versão com gradiente
- Fundos claros: off-white com manchas suaves e desfocadas de cinza claro/branco (efeito "névoa"), também com grão sutil
- Fundos escuros: verde institucional `#02594F` chapado com grão sutil

```css
background: radial-gradient(ellipse at 20% 10%, #2A327B 0%, transparent 45%),
            radial-gradient(ellipse at 70% 30%, #F2BE48 0%, transparent 50%),
            radial-gradient(ellipse at 30% 60%, #E37747 0%, transparent 55%),
            radial-gradient(ellipse at 80% 95%, #02594F 0%, transparent 50%),
            #E37747;
```

## 6. Símbolo

- Flor de 8 pétalas alongadas e arredondadas, irradiando do centro
- Conceito: cada pétala sozinha não significa nada; unidas formam o símbolo que conecta e movimenta — representa **conexão e movimento**
- Versões: sólida (preenchida) e outline (traço/linha), incluindo outline com gradiente
- Pode ser usado isolado, como elemento gráfico grande e recortado na borda da composição, ou como marca d'água em linha branca/verde sobre fundo
- Animação de construção: pétalas surgindo uma a uma até formar a flor

## 7. Logotipo

Composição: símbolo + "GRAZI BRAZ" (Barlow Condensed, caixa alta) + tagline "conexão e movimento" (itálico, caixa baixa).

Versões aprovadas:

1. **Horizontal:** "GRAZI BRAZ" em uma linha, símbolo no canto superior direito, tagline centralizada abaixo
2. **Vertical:** símbolo centralizado acima, "GRAZI BRAZ" em uma linha, tagline abaixo
3. **Empilhada:** símbolo acima, "GRAZI" / "BRAZ" em duas linhas, tagline abaixo — alinhada à esquerda ou à direita
4. **Reduzida:** símbolo + nome, sem tagline

Cores do logo: monocromático em qualquer uma das 4 cores da paleta (verde é a principal) ou branco sobre fundo verde/laranja/gradiente.

Não fazer:

- Não distorcer, rotacionar ou alterar proporções
- Não trocar a fonte do nome
- Não aplicar cores fora da paleta
- Não aplicar o logo multicolorido (cada parte de uma cor)
- Não aplicar sobre fundo sem contraste suficiente

## 8. Ícones

- Família iconográfica própria, estilo linha (outline), traço uniforme, cantos levemente arredondados
- Duas versões: verde sólido `#02594F` e gradiente (laranja → amarelo → azul)
- Ícones existentes: Família, Corrida, Rotina, Depoimentos, Evolução, Meus Treinos, Receitas, Anamnese, Alunos
- Novos ícones devem seguir o mesmo estilo (linha, mesmo peso de traço, sem preenchimento)

## 9. Fotografia

- Pessoas reais treinando ou em momentos de conexão (high-five, sorrisos, cumplicidade)
- Diversidade de corpos e perfis; foco em mulheres ativas
- Ambientes: urbano/ao ar livre (concreto, quadras), academias com luz natural
- Roupas de treino preferencialmente nas cores da marca (laranja, verde)
- Tratamento: luz natural, cores quentes, leve grão analógico; pode-se usar versão P&B lado a lado com a colorida
- Evitar fotos de estúdio frias, poses artificiais ou estética agressiva/bodybuilding

## 10. Layout e composição

- Muito respiro (espaço em branco); composições limpas e assimétricas
- Grid: texto pequeno e alinhado à esquerda, títulos grandes em caixa alta
- Faixas verticais de gradiente na lateral como elemento de marca
- Símbolo grande recortado nas bordas como elemento decorativo
- Cabeçalho de páginas/seções: navegação discreta em caixa alta, tamanho pequeno, cor amarela (ex.: `GRAZI BRAZ · GUIA DE MARCA · SEÇÃO`)
- Títulos de destaque podem ser sobrepostos à imagem

## 11. Aplicações de referência

- Posts e stories de redes sociais (enquetes, perguntas ao aluno, frases motivacionais)
- App/tela mobile: fundo verde, símbolo em linha branca ao centro, ícones da família em gradiente
- Papelaria: cartão de visita laranja e verde, ficha de anamnese
- Vestuário: camiseta laranja com símbolo em linha branca e tagline
- Sinalização: placa laranja com logo vertical em branco
- Smartwatch: tela verde com símbolo

## 12. Checklist antes de entregar

- [ ] Apenas Barlow Condensed
- [ ] Apenas cores da paleta (+ cinza de texto e off-white de fundo)
- [ ] Laranja usado para o destaque principal; verde como cor institucional
- [ ] Azul usado com moderação
- [ ] Títulos em caixa alta; tagline em itálico caixa baixa
- [ ] Logo em uma das versões aprovadas e cor única
- [ ] Texto claro, curto, humano e motivador
- [ ] Espaço em branco suficiente

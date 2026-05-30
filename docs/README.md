# Relatório em LaTeX

Este repositório contém um relatório técnico desenvolvido em LaTeX. O arquivo principal do documento é `main.tex`, responsável por importar os pacotes, definir título, autores, seções, imagens e demais elementos do relatório.

## Estrutura básica do projeto

```text
.
├── main.tex
├── main.pdf
├── images/
│   ├── visaoGeral.png
│   ├── readMisseHit.png
│   ├── lru.png
│   └── final.png
└── README.md
````

O arquivo `main.tex` é o documento principal.
A pasta `images/` armazena as figuras utilizadas no relatório.
O arquivo `main.pdf` é gerado automaticamente após a compilação.

## Requisitos

Para compilar o documento, é necessário ter uma distribuição LaTeX instalada.

Algumas opções comuns são:

* TeX Live
* MiKTeX
* MacTeX
* BasicTeX

Também é recomendado instalar a extensão:

```text
LaTeX Workshop
```

Ela permite compilar o arquivo `.tex`, visualizar o PDF gerado e acompanhar erros de compilação diretamente no editor.

## Pacotes LaTeX utilizados

O documento utiliza pacotes como:

```latex
inputenc
babel
fontenc
graphicx
booktabs
xcolor
geometry
float
hyperref
verbatim
listings
placeins
```

Caso algum pacote esteja ausente, a compilação pode falhar com uma mensagem semelhante a:

```text
LaTeX Error: File `nome-do-pacote.sty' not found.
```

Nesse caso, instale o pacote indicado pela mensagem de erro.

Exemplo:

```bash
sudo tlmgr install placeins
```

## Como compilar o documento pelo terminal

Na pasta do projeto, execute:

```bash
pdflatex main.tex
```

Para atualizar corretamente referências, numeração de figuras e links internos, rode o comando duas vezes:

```bash
pdflatex main.tex
pdflatex main.tex
```

Após a compilação, será gerado o arquivo:

```text
main.pdf
```

## Como abrir o PDF gerado

Após compilar, abra o arquivo `main.pdf` na própria pasta do projeto ou utilize o comando adequado para o seu sistema.

No macOS:

```bash
open main.pdf
```

No Linux:

```bash
xdg-open main.pdf
```

No Windows PowerShell:

```powershell
start main.pdf
```

## Como compilar usando a extensão LaTeX Workshop

Com o arquivo `main.tex` aberto, use a paleta de comandos:

```text
Ctrl + Shift + P
```

ou, no macOS:

```text
Cmd + Shift + P
```

Procure por:

```text
LaTeX Workshop: Build with recipe
```

Em seguida, selecione uma receita de compilação, como:

```text
pdflatex
```

Depois, para visualizar o PDF, procure por:

```text
LaTeX Workshop: View LaTeX PDF
```

## Configuração recomendada

Caso a compilação automática não funcione corretamente, é possível configurar a extensão para usar `pdflatex`.

No arquivo de configurações JSON do editor, adicione:

```json
{
  "latex-workshop.latex.autoBuild.run": "onSave",
  "latex-workshop.view.pdf.viewer": "tab",
  "latex-workshop.latex.recipe.default": "pdflatex",
  "latex-workshop.latex.tools": [
    {
      "name": "pdflatex",
      "command": "pdflatex",
      "args": [
        "-interaction=nonstopmode",
        "-synctex=1",
        "%DOC%"
      ]
    }
  ],
  "latex-workshop.latex.recipes": [
    {
      "name": "pdflatex",
      "tools": [
        "pdflatex"
      ]
    }
  ]
}
```

Com essa configuração, o documento será compilado com `pdflatex`.

## Observações importantes

Não remova a pasta `images/`, pois o relatório depende das figuras armazenadas nela.

Caso uma imagem não seja encontrada, verifique se o nome no comando `\includegraphics` corresponde exatamente ao nome do arquivo.

Exemplo:

```latex
\includegraphics[width=\textwidth]{visaoGeral.png}
```

O projeto também utiliza:

```latex
\graphicspath{{images/}}
```

Isso significa que o LaTeX procura automaticamente as imagens dentro da pasta `images/`.

## Problemas comuns

### Erro: `spawn latexmk ENOENT`

Esse erro indica que a ferramenta `latexmk` não está instalada ou não foi encontrada no PATH.

Soluções possíveis:

1. Instalar o `latexmk`:

```bash
sudo tlmgr install latexmk
```

2. Ou configurar a extensão para usar `pdflatex`, conforme mostrado anteriormente.

### Erro: pacote `.sty` não encontrado

Exemplo:

```text
LaTeX Error: File `placeins.sty' not found.
```

Instale o pacote correspondente:

```bash
sudo tlmgr install placeins
```

### Erro: imagem não encontrada

Verifique se a imagem está dentro da pasta `images/` e se o nome está exatamente igual ao usado no arquivo `.tex`.

## Fluxo recomendado de edição

1. Edite o arquivo `main.tex`.
2. Salve o arquivo.
3. Compile com `pdflatex main.tex` ou pela extensão LaTeX Workshop.
4. Abra ou atualize o `main.pdf`.
5. Corrija eventuais erros indicados no terminal ou no painel de logs.
6. Compile novamente até o PDF ser gerado corretamente.
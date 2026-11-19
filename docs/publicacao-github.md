# Preparação para publicação no GitHub

Este documento orienta a publicação manual. A preparação da documentação não
inicializa Git, não cria repositório remoto e não realiza commit ou push.

## Antes de publicar

- Conferir os cinco nomes e RMs oficiais já identificados na seção de integrantes
  do [README](../README.md).
- Revisar README, roteiro e registros em `docs/evidencias/`.
- Conferir que não há dados pessoais, senhas, tokens ou arquivos de configuração privada.
- Manter `pubspec.lock` versionado para reproduzir a resolução desta aplicação.
- Preservar `.gitignore`: `.dart_tool/`, `build/` e `coverage/` não devem ser publicados.
- Decidir com o grupo a conta, o nome e a visibilidade do repositório. Não há remoto
  configurado na preparação desta entrega.
- Não incluir licença ou afirmar permissões de distribuição sem decisão do grupo.

## Revisão e commit local, quando o grupo decidir publicar

Executar na raiz de `binova_mobile`, onde está o `pubspec.yaml`. A proposta abaixo
faz dessa pasta a raiz do repositório, sem criar outro projeto Dart.

```sh
git init
git status --short
git add .gitignore analysis_options.yaml pubspec.yaml pubspec.lock README.md CHANGELOG.md bin lib test docs
git diff --cached --stat
git diff --cached
```

Revisar os arquivos preparados antes do commit. Se o Git solicitar identidade,
configurar o autor real conforme a orientação da equipe; não usar nomes de usuários
mockados. Depois da revisão, o responsável pode executar:

```sh
git commit -m "Prepara MVP Binova em Dart com testes e evidencias"
git branch -M main
```

## Remoto e envio

Criar um repositório vazio no GitHub pela conta escolhida, sem gerar outro README,
licença ou `.gitignore`. Copiar a URL real exibida pelo GitHub. Para adicioná-la,
digitar `git remote add origin` seguido dessa URL; depois conferir com
`git remote -v` e executar `git push -u origin main`.

Não colocar tokens na URL nem em arquivos do projeto. Se já existir repositório
ou remoto quando estas instruções forem usadas, inspecionar `git status` e
`git remote -v` e adaptar os passos; não sobrescrever histórico nem usar push forçado.

## Conferência após publicação

Abrir o repositório e conferir README, código, testes, documentos e logs. Validar
o acesso de outro integrante e testar os comandos em uma cópia nova. Somente
após essa conferência registrar o link real do repositório na entrega acadêmica.
O link do vídeo e o do Figma devem ser adicionados apenas quando existirem e
estiverem acessíveis conforme a orientação da disciplina.

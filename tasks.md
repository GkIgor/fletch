# Project Tasks: Fletch

Checklist de status do projeto e roteiro de implementação.

## ✅ O que já existe e funciona
- [x] **Arquitetura Base:** Estrutura de pastas (models, providers, repositories, screens, widgets).
- [x] **Gerenciamento de Estado:** Providers para Coleções, Workspaces, Usuário e Tema.
- [x] **Persistência Local (Secure):** Repositório que salva coleções com validação de integridade (Hash dinâmico por máquina/usuário).
- [x] **Interface - Sidebar:** Navegação por coleções e lista de requisições.
- [x] **Interface - Tema:** Suporte completo a Dark Mode e Light Mode.
- [x] **Interface - Header:** Topbar com seletor de workspace e perfil.

## ⚠️ O que precisa de melhoria (Melhorias Técnicas)
- [x] **RequestListItem:** O método `_editRequest` (double tap) agora está funcional no RequestEditor.
- [x] **RequestSidebar (Gerenciamento de Requisições e Pastas):**
  - [x] Drag & Drop para mover livremente requisições entre pastas (coleções).
  - [x] Drag & Drop para reordenar pastas (coleções) na sidebar.
  - [x] Ações contextuais: Duplicar requisição.
  - [x] Ações contextuais: Renomear requisição.
  - [x] Ações contextuais: Excluir requisição.
  - [x] Ações contextuais: Mover para outra pasta/coleção (via diálogo).
  - [x] Menu suspenso acionado por botão `...` ou clique com botão direito.
- [x] **Importação/Exportação Oficial na UI:** Botões e diálogos para exportar coleções e importar recalculando assinatura.
- [x] **Feedback de Segurança e Validação de Hash:** Exibir aviso (diálogo/banner) se assinatura falhar, com opção de re-assinar.
- [x] **Formatador de JSON:** Botão "Beautify" no Body Editor para alinhar/formatar o JSON de forma legível.
- [x] **Redimensionamento da Sidebar (Resizable Sidebar):** Arrastar para ajustar a largura da sidebar, com clamp responsivo e sem overflows no editor ou rodapé.
- [ ] **Empty Methods:** Diversos placeholders espalhados pelo código (ex: `// TODO: Request options`).

## 🚀 O que falta implementar (Essencial)
- [x] **Request Editor:** Interface para editar Método HTTP, URL, Query Params, Headers e Body.
- [x] **Execução de Requisições:** Integração com o pacote `dio` para disparar as chamadas reais.
- [x] **Response Viewer:** Painel para exibir o resultado da requisição.
- [x] **Importação/Exportação Oficial:** Único método permitido para mover coleções entre diferentes máquinas, garantindo a re-validação do hash.
- [x] **Gerenciamento de Workspaces:** Tela funcional para criar, editar e deletar workspaces.
- [x] **Seletor de Ambientes:** Implementar a lógica real de variáveis de ambiente (Selector funcional).

## 🚀 Path to Beta (Roadmap)

### 1. Advanced Authentication Panel
- [x] **Native Auth Mechanisms:** Implement a dedicated UI tab to support OAuth (1.0/2.0), Basic Auth, API Keys, and Bearer Tokens out of the box (migrating from manually writing headers).
  - *Nota:* Sistema de herança recursiva em 3 níveis (Request, Collection/Folder, Workspace) implementado e testado via testes de integração automatizados.
  - *Nota:* Sintaxe de interpolação e realce dinâmico de variáveis implementada.

### 2. Sandbox Automation Scripts (Pre/Post-Request)
- [/] **Basic (Low-Code):** Visual node-based workflow editor (similar to a simplified N8N) to chain dynamic variables, assertions, and conditions. Inherits recursively in 3 levels (Workspace -> Collection -> Request) with OOP-based step nodes and JIT compilation cache.
- [ ] **Advanced (Code Editor):** Sandbox script execution using Dart DSL inside an isolated sandbox, sharing the same ExecutionContext. (Coming soon dialog placeholder)

### 3. JSON-to-Types Generator
- [ ] **Response Converter:** Generate type/interface/class/struct models from JSON responses:
  - Supported Languages: Dart `[x]`, TypeScript `[x]`, Go `[ ]`, Kotlin `[ ]`
  - Configurations: Class Name setting, Options (Null safety, snake_case → camelCase conversion, final fields).

### 4. Payload Bulk Importer
- [ ] **Payload Import Menu:** Import one or multiple JSON payloads. Allow generating a new request for each payload or importing them directly into an existing request via context menu.

### 5. Auto Collections Generator
- [ ] **Scaffolding Tool:** Wizard screen to configure the active workspace and bulk-generate nested directories, subfolders, and pre-configured requests automatically (preventing tedious manual creation per domain/feature).

### 6. Local Git Integration
- [ ] **VCS Versioning:** Integrate local Git to version and track changes of Fletch artifacts (workspaces, collections, requests, history, etc.).

### 7. Sync to GitHub (Cloud Sync)
- [ ] **GitHub Storage:** Provide users the option to synchronize and store their Fletch data securely using GitHub as their cloud backend.

### 8. Profiles (Workspace Isolation)
- [ ] **Workspace Profiles:** Feature to create offline profiles (e.g. Work, College, Personal) to keep workspaces and collections fully separated under different user profiles.

### 9. Cookie Manager & Redirects
- [ ] **Cookie Store:** Automate cookie jar storage/replay between requests and add controls to follow or block HTTP redirect chains.

### 10. Request History
- [ ] **Execution History:** A sidebar panel listing recently executed requests to inspect past responses without re-triggering.

### 11. Code Snippet Generator
- [ ] **Code Exporter:** Generate request configuration snippets in multiple languages (cURL, Python, Go, JS Fetch, etc.).

### 12. Enterprise Sync to Server (Post-Beta)
- [ ] **Self-Hosted Backend:** Connect and synchronize data with a private custom server for collaborative enterprise teams.

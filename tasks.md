# Project Tasks: gk_http_client

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
- [ ] **RequestSidebar:** O botão de "More Options" (`onMoreOptions`) nas requisições é um TODO.
- [ ] **Empty Methods:** Diversos placeholders espalhados pelo código (ex: `// TODO: Request options`).
- [ ] **Feedback de Erro:** A persistência ignora arquivos silenciosamente se o hash falhar; adicionar avisos ao usuário quando um arquivo for bloqueado por segurança.

## 🚀 O que falta implementar (Essencial)
- [x] **Request Editor:** Interface para editar Método HTTP, URL, Query Params, Headers e Body.
- [x] **Execução de Requisições:** Integração com o pacote `dio` para disparar as chamadas reais.
- [x] **Response Viewer:** Painel para exibir o resultado da requisição.
- [ ] **Importação/Exportação Oficial:** Único método permitido para mover coleções entre diferentes máquinas, garantindo a re-validação do hash.
- [x] **Gerenciamento de Workspaces:** Tela funcional para criar, editar e deletar workspaces.
- [x] **Seletor de Ambientes:** Implementar a lógica real de variáveis de ambiente (Selector funcional).

## 🛠️ Recursos de um Cliente HTTP Profissional (Roadmap)
- [x] **Ambientes (Environments):** Variáveis dinâmicas (ex: `{{base_url}}`).
- [ ] **Autenticação:** Suporte a Basic Auth, Bearer Token, API Keys e OAuth2.
- [ ] **Histórico:** Lista de requisições enviadas recentemente.
- [ ] **Scripts:** Pre-request e Post-request scripts para automação.
- [ ] **Importação/Exportação:** Suporte a formatos Postman, Insomnia e cURL.
- [ ] **Formatadores de Body:** Suporte a JSON (com lint), Form Data, URL Encoded e GraphQL.
- [ ] **Geração de Código:** Transformar a requisição em trechos de código (cURL, Python, JavaScript, etc).
- [ ] **Gerenciador de Cookies:** Persistência automática de cookies entre requisições.

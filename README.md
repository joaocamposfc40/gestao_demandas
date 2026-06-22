# Gestão de Demandas — Auditoria de Dados (Ferreira Costa)

Aplicativo web (HTML/CSS/JS puro) para gestão de demandas da Auditoria Corporativa:
login por matrícula, fluxo de aprovação por hierarquia e notificações — sincronizado
com o Supabase.

## Telas
- `index.html` — entrada (intro)
- `menu.html` — menu principal
- `app.html` — aplicativo (Painel, Quadro, Calendário, Listagem, Aprovações, Histórico)
- `roster.js` — quadro de usuários (login por matrícula)

## Hospedagem
Arquivos estáticos via **GitHub Pages**. Back-end (banco, autenticação e RLS) no **Supabase**
(a chave *publishable* exposta no HTML é segura; a proteção real é a RLS).

> Acesso restrito aos colaboradores cadastrados da área!

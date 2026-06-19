#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Cria TODAS as contas de usuário no Supabase Auth de uma vez (Admin API).

  ┌─ SEGURANÇA ────────────────────────────────────────────────────────┐
  │ Este script usa a SERVICE_ROLE key (poder total, ignora RLS).       │
  │ Ela NUNCA fica no arquivo: é lida da variável de ambiente.          │
  │ Rode LOCALMENTE e nunca faça commit da chave.                       │
  └────────────────────────────────────────────────────────────────────┘

USO (PowerShell):
  $env:SB_SERVICE_KEY = "COLE_AQUI_A_SERVICE_ROLE_KEY"
  python seed_users.py

A service_role key fica em: Supabase → Project Settings → API → "service_role".
Se essa chave já foi exposta antes, gere uma nova (Rotate) antes de usar.

Idempotente: se a conta já existir, apenas avisa e segue.
Depois de rodar este script, execute supabase_governanca.sql no SQL Editor.
"""
import os, json, urllib.request, urllib.error

SB_URL = "https://xtpirxyjmqwcvjlcajsz.supabase.co"
SERVICE_KEY = os.environ.get("SB_SERVICE_KEY")

# Senha inicial provisória para TODOS. Oriente cada pessoa a trocar depois.
SENHA_INICIAL = "Auditoria@2025"

# (matrícula, nome, e-mail)
USERS = [
    ("0",     "Admin",              "admin@demandas.ferreiracosta.com.br"),
    ("15712", "Jurandir Pereira",   "jurandir.pereira@ferreiracosta.com.br"),
    ("18242", "Emerson Cardoso",    "emerson.cardoso@ferreiracosta.com.br"),
    ("15406", "Isabela de Freitas", "isabela.freitas@ferreiracosta.com.br"),
    ("30785", "Rilma Saraiva",      "rilma.saraiva@ferreiracosta.com.br"),
    ("25963", "João Campos",        "joao.campos@ferreiracosta.com.br"),
    ("11692", "Marcelo Castim",     "marcelo.castim@ferreiracosta.com.br"),
    ("30855", "Ângelo Constâncio",  "angelo.constancio@ferreiracosta.com.br"),
    ("27884", "Layanne Santos",     "layanne.santos@ferreiracosta.com.br"),
    ("29446", "Bianca Bione",       "bianca.bione@ferreiracosta.com.br"),
    ("30188", "Rayssa Santos",      "rayssa.santos@ferreiracosta.com.br"),
    ("30805", "Alexia Botelho",     "alexia.botelho@ferreiracosta.com.br"),
    ("12549", "Tatiane Bandeira",   "tatiane.carvalho@ferreiracosta.com.br"),
    ("23741", "Suzane Sena",        "suzane.sena@ferreiracosta.com.br"),
    ("25884", "Pedro Eugenio",      "pedro.eugenio@ferreiracosta.com.br"),
]


def criar(mat, nome, email):
    body = json.dumps({
        "email": email,
        "password": SENHA_INICIAL,
        "email_confirm": True,                       # já confirma (sem e-mail)
        "user_metadata": {"matricula": mat, "nome": nome},
    }).encode("utf-8")
    req = urllib.request.Request(
        f"{SB_URL}/auth/v1/admin/users",
        data=body, method="POST",
        headers={
            "apikey": SERVICE_KEY,
            "Authorization": f"Bearer {SERVICE_KEY}",
            "Content-Type": "application/json",
        },
    )
    try:
        urllib.request.urlopen(req)
        print(f"  [criado]   {mat:>6}  {nome}")
    except urllib.error.HTTPError as e:
        msg = e.read().decode("utf-8", "ignore")
        if e.code in (422, 409) or "already" in msg.lower() or "registered" in msg.lower():
            print(f"  [já existe]{mat:>6}  {nome}")
        else:
            print(f"  [ERRO {e.code}]{mat:>6}  {nome} -> {msg}")
    except Exception as e:
        print(f"  [FALHA]    {mat:>6}  {nome} -> {e}")


if __name__ == "__main__":
    if not SERVICE_KEY:
        raise SystemExit(
            "Defina a variável SB_SERVICE_KEY antes de rodar.\n"
            '  PowerShell:  $env:SB_SERVICE_KEY = "sua_service_role_key"'
        )
    print(f"Criando {len(USERS)} contas em {SB_URL}")
    print(f"Senha inicial de todos: {SENHA_INICIAL}\n")
    for u in USERS:
        criar(*u)
    print("\nConcluido. Proximo passo: rodar supabase_governanca.sql no SQL Editor.")

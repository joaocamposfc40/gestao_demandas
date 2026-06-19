-- ════════════════════════════════════════════════════════════════════
-- GESTÃO DE DEMANDAS — Cria as 15 contas de usuário direto no SQL Editor
-- (sem terminal / sem PowerShell). Rode ANTES do supabase_governanca.sql.
--
-- Senha inicial de TODOS: Auditoria@2025
-- É idempotente: quem já existir é ignorado.
-- ════════════════════════════════════════════════════════════════════

create extension if not exists pgcrypto;

do $$
declare
  r       record;
  v_id    uuid;
  v_senha text := 'Auditoria@2025';   -- <<< senha inicial de todos
begin
  for r in
    select * from (values
      ('admin@demandas.ferreiracosta.com.br',   '0',     'Admin'),
      ('jurandir.pereira@ferreiracosta.com.br', '15712', 'Jurandir Pereira'),
      ('emerson.cardoso@ferreiracosta.com.br',  '18242', 'Emerson Cardoso'),
      ('isabela.freitas@ferreiracosta.com.br',  '15406', 'Isabela de Freitas'),
      ('rilma.saraiva@ferreiracosta.com.br',    '30785', 'Rilma Saraiva'),
      ('joao.campos@ferreiracosta.com.br',      '25963', 'João Campos'),
      ('marcelo.castim@ferreiracosta.com.br',   '11692', 'Marcelo Castim'),
      ('angelo.constancio@ferreiracosta.com.br','30855', 'Ângelo Constâncio'),
      ('layanne.santos@ferreiracosta.com.br',   '27884', 'Layanne Santos'),
      ('bianca.bione@ferreiracosta.com.br',     '29446', 'Bianca Bione'),
      ('rayssa.santos@ferreiracosta.com.br',    '30188', 'Rayssa Santos'),
      ('alexia.botelho@ferreiracosta.com.br',   '30805', 'Alexia Botelho'),
      ('tatiane.carvalho@ferreiracosta.com.br', '12549', 'Tatiane Bandeira'),
      ('suzane.sena@ferreiracosta.com.br',      '23741', 'Suzane Sena'),
      ('pedro.eugenio@ferreiracosta.com.br',    '25884', 'Pedro Eugenio')
    ) as t(email, matricula, nome)
  loop
    -- pula quem já existe
    if exists (select 1 from auth.users where email = r.email) then
      continue;
    end if;

    v_id := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_app_meta_data, raw_user_meta_data, is_super_admin,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', v_id, 'authenticated', 'authenticated',
      r.email, crypt(v_senha, gen_salt('bf')),
      now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('matricula', r.matricula, 'nome', r.nome),
      false, '', '', '', ''
    );

    -- identidade de e-mail (necessária p/ login por senha nas versões atuais)
    insert into auth.identities (
      provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      v_id::text, v_id,
      jsonb_build_object('sub', v_id::text, 'email', r.email,
                         'email_verified', true, 'phone_verified', false),
      'email', now(), now(), now()
    );
  end loop;
end $$;

-- Conferência:
select email, raw_user_meta_data->>'matricula' as matricula
from auth.users order by 2;

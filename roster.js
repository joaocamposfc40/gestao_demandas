/* ══════════════════════════════════════════════════════════════════
   ROSTER — quadro fixo de usuários da Auditoria Corporativa.
   Usado para: (1) login por matrícula → e-mail, (2) hierarquia/perfis no cliente.
   A fonte de verdade de SEGURANÇA é a tabela `profiles` + RLS no Supabase;
   este arquivo é só conveniência de interface (não é segredo).
   ══════════════════════════════════════════════════════════════════ */
const ROSTER = [
  { matricula: "0",     nome: "Admin",              cargo: "Desenvolvedor do Sistema",          email: "admin@demandas.ferreiracosta.com.br", perfil: "desenvolvedor", gestor: null },
  { matricula: "15712", nome: "Jurandir Pereira",   cargo: "Diretor de Auditoria Corporativa",  email: "jurandir.pereira@ferreiracosta.com.br", perfil: "gestor_master", gestor: null },
  { matricula: "18242", nome: "Emerson Cardoso",    cargo: "Gerente de Auditoria Interna",      email: "emerson.cardoso@ferreiracosta.com.br",  perfil: "gestor",        gestor: "15712" },
  { matricula: "15406", nome: "Isabela de Freitas", cargo: "Gerente de CI, Riscos & Compliance",email: "isabela.freitas@ferreiracosta.com.br",  perfil: "gestor",        gestor: "15712" },
  { matricula: "30785", nome: "Rilma Saraiva",      cargo: "Coordenadora de ESG",               email: "rilma.saraiva@ferreiracosta.com.br",    perfil: "gestor",        gestor: "15712" },
  { matricula: "25963", nome: "João Campos",        cargo: "Auditor de Dados",                  email: "joao.campos@ferreiracosta.com.br",      perfil: "usuario",       gestor: "15712" },
  { matricula: "11692", nome: "Marcelo Castim",     cargo: "DPO",                               email: "marcelo.castim@ferreiracosta.com.br",   perfil: "usuario",       gestor: "15712" },
  { matricula: "30855", nome: "Ângelo Constâncio",  cargo: "Analista de CI",                    email: "angelo.constancio@ferreiracosta.com.br",perfil: "usuario",       gestor: "15406" },
  { matricula: "27884", nome: "Layanne Santos",     cargo: "Analista de CI",                    email: "layanne.santos@ferreiracosta.com.br",   perfil: "usuario",       gestor: "15406" },
  { matricula: "29446", nome: "Bianca Bione",       cargo: "Analista de Compliance",            email: "bianca.bione@ferreiracosta.com.br",     perfil: "usuario",       gestor: "15406" },
  { matricula: "30188", nome: "Rayssa Santos",      cargo: "Aprendiz",                          email: "rayssa.santos@ferreiracosta.com.br",    perfil: "usuario",       gestor: "15406" },
  { matricula: "30805", nome: "Alexia Botelho",     cargo: "Auxiliar Administrativo",           email: "alexia.botelho@ferreiracosta.com.br",   perfil: "usuario",       gestor: "15406" },
  { matricula: "12549", nome: "Tatiane Bandeira",   cargo: "Analista ESG",                      email: "tatiane.carvalho@ferreiracosta.com.br", perfil: "usuario",       gestor: "30785" },
  { matricula: "23741", nome: "Suzane Sena",        cargo: "Analista ESG",                      email: "suzane.sena@ferreiracosta.com.br",      perfil: "usuario",       gestor: "30785" },
  { matricula: "25884", nome: "Pedro Eugenio",      cargo: "Auxiliar Administrativo",           email: "pedro.eugenio@ferreiracosta.com.br",    perfil: "usuario",       gestor: "30785" },
];

const ROSTER_BY_MAT   = Object.fromEntries(ROSTER.map(u => [u.matricula, u]));
const ROSTER_BY_EMAIL = Object.fromEntries(ROSTER.map(u => [u.email.toLowerCase(), u]));

const PERFIL_LABEL = {
  desenvolvedor: "Desenvolvedor",
  gestor_master: "Gestor Master",
  gestor:        "Gestor",
  usuario:       "Usuário",
};

/* helpers de papel */
function rosterByMat(mat)     { return ROSTER_BY_MAT[String(mat).trim()] || null; }
function rosterByEmail(email) { return ROSTER_BY_EMAIL[String(email || "").toLowerCase()] || null; }
function isGestorPerfil(p)    { return p === "gestor" || p === "gestor_master" || p === "desenvolvedor"; }
function gestorDe(mat) {
  const u = rosterByMat(mat);
  return u && u.gestor ? rosterByMat(u.gestor) : null;
}

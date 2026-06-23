/* ══════════════════════════════════════════════════════════════════
   ROSTER — quadro fixo de usuários da Auditoria Corporativa.
   Login por matrícula → e-mail. Hierarquia (gestor) só para aprovações.
   Visibilidade é por SETOR (ver governanca_v2.sql / RLS).
   Não é segredo — a proteção real é a RLS no Supabase.
   ══════════════════════════════════════════════════════════════════ */
const ROSTER = [
  { matricula: "0",     nome: "Admin",              cargo: "Desenvolvedor do Sistema",          setor: "Admin",                    email: "admin@demandas.ferreiracosta.com.br", perfil: "desenvolvedor", gestor: null },
  { matricula: "15712", nome: "Jurandir Pereira",   cargo: "Diretor de Auditoria Corporativa",  setor: "Diretoria",                email: "jurandir.pereira@ferreiracosta.com.br", perfil: "gestor_master", gestor: null },
  { matricula: "18242", nome: "Emerson Cardoso",    cargo: "Gerente de Auditoria Interna",      setor: "Auditoria Interna",        email: "emerson.cardoso@ferreiracosta.com.br",  perfil: "gestor",        gestor: "15712" },
  { matricula: "31700", nome: "Mac Kinlley",        cargo: "Auditor Interno",                   setor: "Auditoria Interna",        email: "mac.castilho@ferreiracosta.com.br",     perfil: "usuario",       gestor: "18242" },
  { matricula: "22012", nome: "Wilson Belfort",     cargo: "Auditor Interno",                   setor: "Auditoria Interna",        email: "wilson.pires@ferreiracosta.com.br",     perfil: "usuario",       gestor: "18242" },
  { matricula: "19404", nome: "Antônio Moura",      cargo: "Auditor Interno",                   setor: "Auditoria Interna",        email: "antonio.neto@ferreiracosta.com.br",     perfil: "usuario",       gestor: "18242" },
  { matricula: "15406", nome: "Isabela de Freitas", cargo: "Gerente de CI, Riscos & Compliance",setor: "CI, Riscos e Compliance",  email: "isabela.freitas@ferreiracosta.com.br",  perfil: "gestor",        gestor: "15712" },
  { matricula: "30855", nome: "Ângelo Constâncio",  cargo: "Analista de CI",                    setor: "CI, Riscos e Compliance",  email: "angelo.constancio@ferreiracosta.com.br",perfil: "usuario",       gestor: "15406" },
  { matricula: "27884", nome: "Layanne Santos",     cargo: "Analista de CI",                    setor: "CI, Riscos e Compliance",  email: "layanne.santos@ferreiracosta.com.br",   perfil: "usuario",       gestor: "15406" },
  { matricula: "29446", nome: "Bianca Bione",       cargo: "Analista de Compliance",            setor: "CI, Riscos e Compliance",  email: "bianca.bione@ferreiracosta.com.br",     perfil: "usuario",       gestor: "15406" },
  { matricula: "30188", nome: "Rayssa Santos",      cargo: "Aprendiz",                          setor: "CI, Riscos e Compliance",  email: "rayssa.santos@ferreiracosta.com.br",    perfil: "individual",    gestor: "15406" },
  { matricula: "30805", nome: "Alexia Botelho",     cargo: "Auxiliar Administrativo",           setor: "CI, Riscos e Compliance",  email: "alexia.botelho@ferreiracosta.com.br",   perfil: "individual",    gestor: "15406" },
  { matricula: "25963", nome: "João Campos",        cargo: "Auditor de Dados",                  setor: "Dados",                    email: "joao.campos@ferreiracosta.com.br",      perfil: "usuario",       gestor: "15712" },
  { matricula: "30785", nome: "Rilma Saraiva",      cargo: "Coordenadora de ESG",               setor: "ESG",                      email: "rilma.saraiva@ferreiracosta.com.br",    perfil: "gestor",        gestor: "15712" },
  { matricula: "12549", nome: "Tatiane Bandeira",   cargo: "Analista ESG",                      setor: "ESG",                      email: "tatiane.carvalho@ferreiracosta.com.br", perfil: "usuario",       gestor: "30785" },
  { matricula: "23741", nome: "Suzane Sena",        cargo: "Analista ESG",                      setor: "ESG",                      email: "suzane.sena@ferreiracosta.com.br",      perfil: "usuario",       gestor: "30785" },
  { matricula: "25884", nome: "Pedro Eugenio",      cargo: "Auxiliar Administrativo",           setor: "ESG",                      email: "pedro.eugenio@ferreiracosta.com.br",    perfil: "usuario",       gestor: "30785" },
  { matricula: "29873", nome: "Daniele dos Santos", cargo: "Analista ESG",                      setor: "ESG",                      email: "daniele.santos@ferreiracosta.com.br",   perfil: "usuario",       gestor: "30785" },
  { matricula: "11692", nome: "Marcelo Castim",     cargo: "DPO",                               setor: "Segurança da Informação",  email: "marcelo.castim@ferreiracosta.com.br",   perfil: "usuario",       gestor: "15712" },
];

const ROSTER_BY_MAT   = Object.fromEntries(ROSTER.map(u => [u.matricula, u]));
const ROSTER_BY_EMAIL = Object.fromEntries(ROSTER.map(u => [u.email.toLowerCase(), u]));

/* Setores operacionais (para gráficos/filtros). Admin/Diretoria ficam de fora. */
const SETORES = ["Auditoria Interna", "CI, Riscos e Compliance", "Dados", "ESG", "Segurança da Informação"];

const PERFIL_LABEL = {
  desenvolvedor: "Desenvolvedor",
  gestor_master: "Gestor Master",
  gestor:        "Gestor",
  usuario:       "Usuário",
  individual:    "Perfil individual",
};

function rosterByMat(mat)     { return ROSTER_BY_MAT[String(mat).trim()] || null; }
function rosterByEmail(email) { return ROSTER_BY_EMAIL[String(email || "").toLowerCase()] || null; }
function isGestorPerfil(p)    { return p === "gestor" || p === "gestor_master" || p === "desenvolvedor"; }
function vemTudo(p)           { return p === "gestor_master" || p === "desenvolvedor"; }
function gestorDe(mat) {
  const u = rosterByMat(mat);
  return u && u.gestor ? rosterByMat(u.gestor) : null;
}
function setorDe(mat) { const u = rosterByMat(mat); return u ? u.setor : null; }
/* Pessoas selecionáveis em formulários (exclui o Admin de teste). */
function pessoasSelecionaveis() { return ROSTER.filter(u => u.matricula !== "0"); }

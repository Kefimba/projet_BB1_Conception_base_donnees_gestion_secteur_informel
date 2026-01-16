/* ============================================================
   MPD PostgreSQL - Secteur informel (Merise → Relationnel)
   Tables d’associations renommées par VERBES Merise
   ============================================================ */

BEGIN;

-- ============================================================
-- 1) Référentiels (ROLE) + UTILISATEUR
-- Association : UTILISATEUR --(AVOIR ROLE)-- ROLE (1,1)-(1,n) -> FK utilisateur.id_role
-- ============================================================
CREATE TABLE role (
  id_role SERIAL CONSTRAINT pk_role PRIMARY KEY,
  libelle_role VARCHAR(50) CONSTRAINT uq_role_libelle UNIQUE NOT NULL
);

CREATE TABLE utilisateur (
  id_user SERIAL CONSTRAINT pk_utilisateur PRIMARY KEY,
  nom VARCHAR(80) NOT NULL,
  prenom VARCHAR(80) NOT NULL,
  email VARCHAR(120) CONSTRAINT uq_utilisateur_email UNIQUE NOT NULL,
  telephone VARCHAR(30),
  date_creation TIMESTAMP NOT NULL DEFAULT NOW(),
  actif BOOLEAN NOT NULL DEFAULT TRUE,
  id_role INT NOT NULL,
  CONSTRAINT fk_utilisateur_role
    FOREIGN KEY (id_role) REFERENCES role(id_role)
);

-- ============================================================
-- 2) Découpage territorial
-- REGION --(CONTENIR)--> DEPARTEMENT --(CONTENIR)--> COMMUNE --(CONTENIR)--> SITE (FK dans enfant)
-- ============================================================
CREATE TABLE region (
  id_region SERIAL CONSTRAINT pk_region PRIMARY KEY,
  nom_region VARCHAR(120) CONSTRAINT uq_region_nom UNIQUE NOT NULL
);

CREATE TABLE departement (
  id_dept SERIAL CONSTRAINT pk_departement PRIMARY KEY,
  nom_dept VARCHAR(120) NOT NULL,
  id_region INT NOT NULL,
  CONSTRAINT fk_departement_region
    FOREIGN KEY (id_region) REFERENCES region(id_region),
  CONSTRAINT uq_departement_nom_region UNIQUE (nom_dept, id_region)
);

CREATE TABLE commune (
  id_commune SERIAL CONSTRAINT pk_commune PRIMARY KEY,
  nom_commune VARCHAR(120) NOT NULL,
  type_commune VARCHAR(40),
  id_dept INT NOT NULL,
  CONSTRAINT fk_commune_departement
    FOREIGN KEY (id_dept) REFERENCES departement(id_dept),
  CONSTRAINT uq_commune_nom_dept UNIQUE (nom_commune, id_dept)
);

CREATE TABLE site (
  id_site SERIAL CONSTRAINT pk_site PRIMARY KEY,
  nom_site VARCHAR(140) NOT NULL,
  type_site VARCHAR(60) NOT NULL,
  description TEXT,
  id_commune INT NOT NULL,
  CONSTRAINT fk_site_commune
    FOREIGN KEY (id_commune) REFERENCES commune(id_commune),
  CONSTRAINT uq_site_nom_commune UNIQUE (nom_site, id_commune)
);

-- ============================================================
-- 3) Activité & unité informelle
-- SITE --(LOCALISER)--> UNITE_INFORMELLE  -> FK id_site
-- ACTIVITE_ECO --(EXERCER)--> UNITE_INFORMELLE -> FK id_activite
-- ============================================================
CREATE TABLE activite_eco (
  id_activite SERIAL CONSTRAINT pk_activite PRIMARY KEY,
  secteur VARCHAR(30) NOT NULL,
  sous_secteur VARCHAR(80),
  type_production VARCHAR(80),
  saisonnalite VARCHAR(60),
  description TEXT
);

CREATE TABLE unite_informelle (
  id_unite SERIAL CONSTRAINT pk_unite PRIMARY KEY,
  code_unite VARCHAR(40) CONSTRAINT uq_unite_code UNIQUE NOT NULL,
  nom_activite VARCHAR(160) NOT NULL,
  type_activite VARCHAR(80),
  statut_juridique VARCHAR(60),
  date_creation DATE,
  niveau_formalisation VARCHAR(40) NOT NULL,
  ca_estime NUMERIC(18,2),
  id_site INT NOT NULL,
  id_activite INT NOT NULL,
  CONSTRAINT fk_unite_site
    FOREIGN KEY (id_site) REFERENCES site(id_site),
  CONSTRAINT fk_unite_activite
    FOREIGN KEY (id_activite) REFERENCES activite_eco(id_activite),
  CONSTRAINT ck_unite_ca CHECK (ca_estime IS NULL OR ca_estime >= 0)
);

-- ============================================================
-- 4) TRAVAILLEUR
-- UNITE_INFORMELLE --(APPARTENIR)--> TRAVAILLEUR -> FK id_unite
-- ============================================================
CREATE TABLE travailleur (
  id_trav SERIAL CONSTRAINT pk_travailleur PRIMARY KEY,
  identifiant_ext VARCHAR(60),
  sexe CHAR(1) NOT NULL,
  age INT,
  niveau_instruction VARCHAR(60),
  role_unite VARCHAR(40) NOT NULL,
  anciennete_mois INT,
  couverture_sociale BOOLEAN NOT NULL DEFAULT FALSE,
  id_unite INT NOT NULL,
  CONSTRAINT ck_trav_sexe CHECK (sexe IN ('M','F')),
  CONSTRAINT ck_trav_age CHECK (age IS NULL OR age BETWEEN 10 AND 100),
  CONSTRAINT ck_trav_anciennete CHECK (anciennete_mois IS NULL OR anciennete_mois >= 0),
  CONSTRAINT fk_trav_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite)
);

-- ============================================================
-- 5) SITUATION_ECO
-- UNITE_INFORMELLE --(AVOIR_OBSERVATIONS)--> SITUATION_ECO -> FK id_unite
-- ============================================================
CREATE TABLE situation_eco (
  id_sit SERIAL CONSTRAINT pk_situation PRIMARY KEY,
  nb_travailleurs_decl INT,
  revenu_mensuel_estime NUMERIC(18,2),
  charges_principales NUMERIC(18,2),
  variation_saisonniere VARCHAR(60),
  date_obs DATE NOT NULL,
  id_unite INT NOT NULL,
  CONSTRAINT ck_sit_nb CHECK (nb_travailleurs_decl IS NULL OR nb_travailleurs_decl >= 0),
  CONSTRAINT ck_sit_revenu CHECK (revenu_mensuel_estime IS NULL OR revenu_mensuel_estime >= 0),
  CONSTRAINT ck_sit_charges CHECK (charges_principales IS NULL OR charges_principales >= 0),
  CONSTRAINT fk_sit_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite),
  CONSTRAINT uq_sit_unite_date UNIQUE (id_unite, date_obs)
);

-- ============================================================
-- 6) EQUIPEMENT + UTILISER (n,n) avec attribut "remarque"
-- ACTIVITE_ECO --(UTILISER)--> EQUIPEMENT -> table UTILISER
-- ============================================================
CREATE TABLE equipement (
  id_equipement SERIAL CONSTRAINT pk_equipement PRIMARY KEY,
  libelle_equipement VARCHAR(120) CONSTRAINT uq_equipement_libelle UNIQUE NOT NULL
);

CREATE TABLE utiliser (
  id_activite INT NOT NULL,
  id_equipement INT NOT NULL,
  remarque TEXT,
  CONSTRAINT pk_utiliser PRIMARY KEY (id_activite, id_equipement),
  CONSTRAINT fk_utiliser_activite
    FOREIGN KEY (id_activite) REFERENCES activite_eco(id_activite) ON DELETE CASCADE,
  CONSTRAINT fk_utiliser_equipement
    FOREIGN KEY (id_equipement) REFERENCES equipement(id_equipement) ON DELETE CASCADE
);

-- ============================================================
-- 7) Vulnérabilités : DIFFICULTE/RISQUE/BESOIN + tables verbes
-- ============================================================
CREATE TABLE difficulte (
  id_diff SERIAL CONSTRAINT pk_difficulte PRIMARY KEY,
  libelle_diff VARCHAR(120) CONSTRAINT uq_difficulte_libelle UNIQUE NOT NULL
);

-- UNITE --(DECLARER_DIFFICULTE)--> DIFFICULTE  (niveau_severite, date_decl)
CREATE TABLE declarer_difficulte (
  id_unite INT NOT NULL,
  id_diff INT NOT NULL,
  niveau_severite INT,
  date_decl DATE NOT NULL,
  CONSTRAINT pk_declarer_difficulte PRIMARY KEY (id_unite, id_diff, date_decl),
  CONSTRAINT fk_dd_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite) ON DELETE CASCADE,
  CONSTRAINT fk_dd_diff
    FOREIGN KEY (id_diff) REFERENCES difficulte(id_diff),
  CONSTRAINT ck_dd_niveau CHECK (niveau_severite IS NULL OR niveau_severite BETWEEN 1 AND 5)
);

CREATE TABLE risque (
  id_risque SERIAL CONSTRAINT pk_risque PRIMARY KEY,
  libelle_risque VARCHAR(120) CONSTRAINT uq_risque_libelle UNIQUE NOT NULL
);

-- UNITE --(DECLARER_RISQUE)--> RISQUE  (probabilite_percue, date_decl)
CREATE TABLE declarer_risque (
  id_unite INT NOT NULL,
  id_risque INT NOT NULL,
  probabilite_percue INT,
  date_decl DATE NOT NULL,
  CONSTRAINT pk_declarer_risque PRIMARY KEY (id_unite, id_risque, date_decl),
  CONSTRAINT fk_dr_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite) ON DELETE CASCADE,
  CONSTRAINT fk_dr_risque
    FOREIGN KEY (id_risque) REFERENCES risque(id_risque),
  CONSTRAINT ck_dr_prob CHECK (probabilite_percue IS NULL OR probabilite_percue BETWEEN 1 AND 5)
);

CREATE TABLE besoin (
  id_besoin SERIAL CONSTRAINT pk_besoin PRIMARY KEY,
  libelle_besoin VARCHAR(120) CONSTRAINT uq_besoin_libelle UNIQUE NOT NULL
);

-- UNITE --(EXPRIMER_BESOIN)--> BESOIN (priorite, date_decl)
CREATE TABLE exprimer_besoin (
  id_unite INT NOT NULL,
  id_besoin INT NOT NULL,
  priorite INT,
  date_decl DATE NOT NULL,
  CONSTRAINT pk_exprimer_besoin PRIMARY KEY (id_unite, id_besoin, date_decl),
  CONSTRAINT fk_eb_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite) ON DELETE CASCADE,
  CONSTRAINT fk_eb_besoin
    FOREIGN KEY (id_besoin) REFERENCES besoin(id_besoin),
  CONSTRAINT ck_eb_priorite CHECK (priorite IS NULL OR priorite BETWEEN 1 AND 5)
);

-- ============================================================
-- 8) Programmes + sessions + PARTICIPER (n,n) avec attributs
-- PROGRAMME --(AVOIR_SESSIONS)--> SESSION_PROG -> FK id_prog
-- UNITE --(PARTICIPER)--> SESSION_PROG -> table PARTICIPER
-- ============================================================
CREATE TABLE programme (
  id_prog SERIAL CONSTRAINT pk_programme PRIMARY KEY,
  nom_prog VARCHAR(160) NOT NULL,
  type_prog VARCHAR(60) NOT NULL,
  organisme VARCHAR(120),
  description TEXT,
  date_debut DATE,
  date_fin DATE,
  CONSTRAINT ck_prog_dates CHECK (date_fin IS NULL OR date_debut IS NULL OR date_fin >= date_debut)
);

CREATE TABLE session_prog (
  id_session SERIAL CONSTRAINT pk_session PRIMARY KEY,
  libelle_session VARCHAR(160) NOT NULL,
  date_debut DATE,
  date_fin DATE,
  lieu VARCHAR(160),
  id_prog INT NOT NULL,
  CONSTRAINT fk_session_programme
    FOREIGN KEY (id_prog) REFERENCES programme(id_prog) ON DELETE CASCADE,
  CONSTRAINT ck_session_dates CHECK (date_fin IS NULL OR date_debut IS NULL OR date_fin >= date_debut)
);

CREATE TABLE participer (
  id_unite INT NOT NULL,
  id_session INT NOT NULL,
  date_inscription DATE NOT NULL,
  statut VARCHAR(40) NOT NULL,
  resultat_obtenu VARCHAR(160),
  montant_financement NUMERIC(18,2),
  CONSTRAINT pk_participer PRIMARY KEY (id_unite, id_session),
  CONSTRAINT fk_participer_unite
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite) ON DELETE CASCADE,
  CONSTRAINT fk_participer_session
    FOREIGN KEY (id_session) REFERENCES session_prog(id_session) ON DELETE CASCADE,
  CONSTRAINT ck_participer_montant CHECK (montant_financement IS NULL OR montant_financement >= 0)
);

-- ============================================================
-- 9) DOCUMENT
-- UTILISATEUR --(DEPOSER)--> DOCUMENT -> FK id_user
-- UNITE --(CONCERNER)--> DOCUMENT -> FK id_unite
-- ============================================================
CREATE TABLE document (
  id_doc SERIAL CONSTRAINT pk_document PRIMARY KEY,
  type_doc VARCHAR(60) NOT NULL,
  date_doc DATE NOT NULL,
  chemin_fichier TEXT NOT NULL,
  commentaire TEXT,
  id_user INT NOT NULL,
  id_unite INT NOT NULL,
  CONSTRAINT fk_document_deposer
    FOREIGN KEY (id_user) REFERENCES utilisateur(id_user),
  CONSTRAINT fk_document_concerner
    FOREIGN KEY (id_unite) REFERENCES unite_informelle(id_unite) ON DELETE CASCADE
);

-- ============================================================
-- 10) Index
-- ============================================================
CREATE INDEX idx_unite_site ON unite_informelle(id_site);
CREATE INDEX idx_unite_activite ON unite_informelle(id_activite);
CREATE INDEX idx_trav_unite ON travailleur(id_unite);
CREATE INDEX idx_sit_unite_date ON situation_eco(id_unite, date_obs);

CREATE INDEX idx_utiliser_act ON utiliser(id_activite);
CREATE INDEX idx_dd_unite ON declarer_difficulte(id_unite);
CREATE INDEX idx_dr_unite ON declarer_risque(id_unite);
CREATE INDEX idx_eb_unite ON exprimer_besoin(id_unite);

CREATE INDEX idx_participer_session ON participer(id_session);
CREATE INDEX idx_doc_unite ON document(id_unite);

COMMIT;
-- ============================================================
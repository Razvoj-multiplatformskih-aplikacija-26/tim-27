-- Šema baze za KT2. Server pri pokretanju izvršava svaki fajl iz ovog foldera tačno jednom,
-- po redu imena, i beleži ga u tabeli sema_migracije.

CREATE TABLE korisnici (
  id text PRIMARY KEY,
  ime text NOT NULL,
  telefon text NOT NULL DEFAULT '',
  uloga text NOT NULL CHECK (uloga IN ('klijent', 'serviser', 'sefServisa')),
  korisnicko_ime text UNIQUE,
  lozinka_hes text
);

CREATE SEQUENCE broj_naloga START 3001;

CREATE TABLE nalozi (
  id text PRIMARY KEY,
  klijent_id text NOT NULL REFERENCES korisnici (id),
  serviser_id text REFERENCES korisnici (id),
  vrsta_uredjaja text NOT NULL CHECK (vrsta_uredjaja IN ('laptop', 'desktop', 'monitor', 'stampac', 'ostalo')),
  naziv_uredjaja text NOT NULL CHECK (length(trim(naziv_uredjaja)) > 0),
  opis_kvara text NOT NULL,
  primljen_u timestamptz NOT NULL,
  stanje text NOT NULL CHECK (stanje IN (
    'primljen', 'dijagnostika', 'ceka-odobrenje', 'u-popravci',
    'spreman-za-preuzimanje', 'preuzet', 'otkazan', 'odbijena-ponuda'
  )),
  ponuda_iznos int CHECK (ponuda_iznos > 0),
  ponuda_opis text,
  ponuda_poslata_u timestamptz,
  preuzet_u timestamptz,
  razlog_otkaza text,
  CONSTRAINT nalozi_ponuda_u_stanju CHECK (
    (stanje IN ('ceka-odobrenje', 'u-popravci', 'odbijena-ponuda')) = (ponuda_iznos IS NOT NULL)
  ),
  CONSTRAINT nalozi_serviser_posle_prijema CHECK (stanje = 'primljen' OR stanje = 'otkazan' OR serviser_id IS NOT NULL)
);

CREATE INDEX nalozi_po_klijentu ON nalozi (klijent_id);
CREATE INDEX nalozi_po_serviseru ON nalozi (serviser_id);

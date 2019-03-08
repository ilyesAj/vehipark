CREATE TABLE CLIENT
(
  noPermis NUMBER(10) NOT NULL,
  nomClient VARCHAR(60) NOT NULL,
  prenomClient VARCHAR(60) NOT NULL,
  adresseClient VARCHAR(60) NOT NULL,
  villeClient VARCHAR(60) NOT NULL,
  cpClient VARCHAR(60) NOT NULL,
  paysClient VARCHAR(60) NOT NULL,
  telephoneClient VARCHAR(60) NOT NULL,
  mailClient VARCHAR(60) NOT NULL
);

CREATE TABLE AGENCE
(
  codeAgence VARCHAR(60) NOT NULL,
  adresseAgence VARCHAR(60) NOT NULL,
  villeAgence VARCHAR(60) NOT NULL,
  cpAgence VARCHAR(60) NOT NULL,
  comissionAgence NUMBER(10) NOT NULL
);

CREATE TABLE VEHICULE
(
  immatriculationVehicule VARCHAR(60) NOT NULL,
  dateAchatVehicule DATE NOT NULL,
  kilometrageVehicule NUMBER(10) NOT NULL,
  modeleVehicule VARCHAR(60) NOT NULL,
  puissanceVehicule NUMBER(10) NOT NULL,
  categorieVehicule VARCHAR(60) NOT NULL,
  marqueVehicule VARCHAR(60) NOT NULL,
  prixJournalierVehicule NUMBER(10,2) NOT NULL,
  prixkmVehicule NUMBER(10,2) NOT NULL,
  depotGarantieVehicule NUMBER(10,2) NOT NULL,
  typeCarburantVehicule VARCHAR(60) NOT NULL,
  codeAgence VARCHAR(60) NOT NULL
);

CREATE TABLE FACTURE
(
  noFacture NUMBER(10) NOT NULL,
  dateFacture DATE NOT NULL,
  totalFacture NUMBER(10,2) NOT NULL,
  supplementPleinFacture NUMBER(10,2) NOT NULL,
  supplementKmFacture NUMBER(10,2) NOT NULL,
  supplementretardFacture NUMBER(10,2) NOT NULL,
  supplementagenceFacture NUMBER(10,2) NOT NULL,
  soustractionGarantieFacture NUMBER(10,2) NOT NULL,
  noContrat number(10) NOT NULL
);

CREATE TABLE ficheRetour
(
  noFicheRetour NUMBER(10) NOT NULL,
  dateRetourReel DATE NOT NULL,
  kmRetourReel NUMBER(10) NOT NULL,
  pourcentageReparation NUMBER(10) NOT NULL,
  nbLitresManquants NUMBER(10) NOT NULL,
  codeAgence VARCHAR(60) NOT NULL,
  noPermis NUMBER(10) NOT NULL,
  noContrat NUMBER(10)  NOT NULL
);

CREATE TABLE CONTRAT
(
  noContrat NUMBER(10) NOT NULL,
  dateDepartContrat DATE NOT NULL,
  dateRetourPrevue DATE NOT NULL,
  kmDepartContrat NUMBER(10) NOT NULL,
  dateContrat DATE NOT NULL,
  limiteKM NUMBER(10) ,
  immatriculationVehicule VARCHAR(60) NOT NULL,
  noPermis NUMBER(10) NOT NULL,
  codeAgence VARCHAR(60) NOT NULL,
  retournercodeAgence VARCHAR(60) NOT NULL,
  prixlitre NUMBER(10,2) NOT NULL,
  idtypeContrat NUMBER(10) NOT NULL
);

CREATE TABLE typeContrat
(
  idtypeContrat NUMBER(10) NOT NULL,
  typeContrat VARCHAR(60) NOT NULL
);



ALTER TABLE CLIENT ADD CONSTRAINT clePrimaiteClient PRIMARY KEY (noPermis);
ALTER TABLE AGENCE ADD CONSTRAINT clePrimaiteAgence  PRIMARY KEY (codeAgence);
ALTER TABLE VEHICULE ADD CONSTRAINT clePrimaireVehicule  PRIMARY KEY (immatriculationVehicule);
ALTER TABLE CONTRAT ADD CONSTRAINT clePrimaireContrat PRIMARY KEY (noContrat);
ALTER TABLE FACTURE ADD CONSTRAINT clePrimaireFacture   PRIMARY KEY (noFacture);
ALTER TABLE ficheRetour ADD CONSTRAINT clePrimairefiche   PRIMARY KEY (noFicheRetour);
ALTER TABLE typeContrat ADD CONSTRAINT clePrimaireTypeContrat  PRIMARY KEY (idtypeContrat);

ALTER TABLE ficheRetour ADD CONSTRAINT cleEtrangereFiche FOREIGN KEY (codeAgence) REFERENCES AGENCE(codeAgence);
ALTER TABLE ficheRetour ADD CONSTRAINT cleEtrangerefiche1  FOREIGN KEY (noPermis) REFERENCES CLIENT(noPermis);
ALTER TABLE ficheRetour ADD CONSTRAINT cleEtrangerefiche2  FOREIGN KEY (noContrat) REFERENCES CONTRAT(noContrat);
ALTER TABLE VEHICULE ADD CONSTRAINT cleEtrangereVeHICULE  FOREIGN KEY (codeAgence) REFERENCES AGENCE(codeAgence);

ALTER TABLE CONTRAT ADD CONSTRAINT cleEtrangereContrat1 FOREIGN KEY (immatriculationVehicule) REFERENCES VEHICULE(immatriculationVehicule);
ALTER TABLE CONTRAT ADD CONSTRAINT cleEtrangereContrat2 FOREIGN KEY (noPermis) REFERENCES CLIENT(noPermis);
ALTER TABLE CONTRAT ADD CONSTRAINT cleEtrangereContrat4 FOREIGN KEY (codeAgence) REFERENCES AGENCE(codeAgence);
ALTER TABLE CONTRAT ADD CONSTRAINT cleEtrangereContrat5 FOREIGN KEY (retournercodeAgence) REFERENCES AGENCE(codeAgence);

ALTER TABLE CONTRAT ADD CONSTRAINT cleEtrangereTypeContrat FOREIGN KEY (idtypeContrat) REFERENCES typeContrat(idtypeContrat);
ALTER TABLE FACTURE ADD CONSTRAINT cleEtrangereFacture   FOREIGN KEY (noContrat) REFERENCES CONTRAT (noContrat) ;

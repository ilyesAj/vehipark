LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/client.csv' APPEND INTO TABLE client FIELDS TERMINATED BY ','
(
noPermis,nomClient,prenomClient,adresseClient,villeClient,cpClient,paysClient,telephoneClient,mailClient
 )
LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/agencefinal.csv' APPEND INTO TABLE agence FIELDS TERMINATED BY ','
(
codeAgence,adresseAgence,villeAgence,cpAgence,comissionAgence
 )
LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/TYPECONTRAT.csv' APPEND INTO TABLE TYPECONTRAT FIELDS TERMINATED BY ','
(
idtypeContrat,typeContrat
 )
LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/voiturefinal.csv' APPEND INTO TABLE vehicule FIELDS TERMINATED BY ','
(
immatriculationVehicule,dateAchatVehicule,kilometrageVehicule,modeleVehicule,puissanceVehicule,categorieVehicule,marqueVehicule,prixJournalierVehicule,prixkmVehicule,depotGarantieVehicule,typeCarburantVehicule,codeAgence
 )

LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/contrat.csv' APPEND INTO TABLE contrat FIELDS TERMINATED BY ','
(
noContrat,dateDepartContrat,dateRetourPrevue,kmDepartContrat,dateContrat,limiteKM,immatriculationVehicule,noPermis,codeAgence,retournercodeAgence,prixlitre,idtypeContrat
 )
LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/ficheRetour.csv' APPEND INTO TABLE ficheretour FIELDS TERMINATED BY ','
(
noFicheRetour,dateRetourReel,kmRetourReel,pourcentageReparation,nbLitresManquants,codeAgence,noPermis,nocontrat
 )

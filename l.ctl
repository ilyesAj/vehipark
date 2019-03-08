LOAD DATA INFILE '/home/oracle/Desktop/projet/donnee/ficheRetour.csv' APPEND INTO TABLE ficheretour FIELDS TERMINATED BY ','
(
noFicheRetour,dateRetourReel,kmRetourReel,pourcentageReparation,nbLitresManquants,codeAgence,noPermis,nocontrat
 )

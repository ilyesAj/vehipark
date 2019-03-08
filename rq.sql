

-- Trigger de creation du prix journalier / depot garantit / prix du KLM
create or replace trigger tarifLocationJournalier 
before insert or update 
on VEHICULE 
for each row 
BEGIN
:NEW.PRIXJOURNALIERVEHICULE := 70 + ( (:NEW.PUISSANCEVEHICULE / 15 ) - (:NEW.KILOMETRAGEVEHICULE / 10000)  );
:NEW.prixkmVehicule := :NEW.PRIXJOURNALIERVEHICULE / 10;
:NEW.depotGarantieVehicule := :NEW.PRIXJOURNALIERVEHICULE * 20;
END;
/

Alter table CONTRAT add constraint dates check ( dateDepartContrat >= dateContrat and dateDepartContrat <= dateRetourPrevue );
Alter table typeContrat add constraint veriftypecontrat check ( typeContrat in ('kilometre','jour'));
alter table vehicule add constraint verifcarbur check (typeCarburantVehicule in ('essence','diesel'));
Alter table AGENCE add constraint commission check ( comissionAgence between 0 and 11);


create or replace trigger kmCompteurContrat 
before insert
on CONTRAT
for each row 
DECLARE
kmCompteur VEHICULE.kilometrageVehicule%TYPE;
carb 	   VEHICULE.typeCarburantVehicule%type;
tcont      typeContrat.typeContrat%type;
controw     CONTRAT%rowtype;
testdisp    number(2):=0;
cursor cont is 
select * from CONTRAT
where immatriculationVehicule =  :NEW.immatriculationVehicule;


BEGIN
      	-- Verification si le vehicule est deja loue (en utilisant l'immatriculation et dates)
	open cont ;
	LOOP
	FETCH cont into controw;
	IF cont%NOTFOUND THEN
	EXIT;
	END IF;
	if controw.dateDepartContrat >= :NEW.dateDepartContrat  and controw.dateDepartContrat <= :NEW.dateRetourPrevue then
	testdisp := 1;
	end if ;
	if controw.dateRetourPrevue >= :NEW.dateDepartContrat  and controw.dateRetourPrevue <= :NEW.dateRetourPrevue then
	testdisp := 1;
	end if ;
	
	if testdisp = 1 then
	EXIT;
	end if ;
	
	END LOOP;
	close cont;
	if testdisp = 1 then 
	RAISE_APPLICATION_ERROR (-20011,
	'vehicule indisponible');
	end if;
	-- Exception si le vehicule est deja loue

	-- Lors de l'ajout d'un vehicule dans le contrat, son kilometrage est ajouté aussi.
	SELECT kilometrageVehicule into kmCompteur 
	FROM VEHICULE 
	where immatriculationVehicule=:NEW.immatriculationVehicule;
      	 :NEW.kmDepartContrat:=kmCompteur;
	
	-- Definition du prix du litre de plein dans le contrat suivant le type de carburant
	select typeCarburantVehicule into carb
	from vehicule 
	where immatriculationVehicule=:NEW.immatriculationVehicule;
	if carb = 'essence' then 
	:NEW.prixlitre := 1.8;
	else 
	:NEW.prixlitre := 1.6;
	end if;

	-- Verification de la presence du kilometrage du vehicule de retour si le type de contrat est kilometre
	select typecontrat into tcont 
	from typeContrat 
	where idtypeContrat = :NEW.idtypeContrat;
	if ( tcont ='kilometre' and (:NEW.limiteKM = 0 or :NEW.limiteKM is null)) then 
	RAISE_APPLICATION_ERROR (-20003,
	'viol integrité table CONTRAT (immatriculationVehicule)');
	end if ;
	


      	 
END;
/


-- Calcul du prix de base (prix estime de la location) lors de la signature d'un contrat
-- Le prix total sera calcule lorsque la fiche de retour du vehicule est signe (trigger calfact et factfinal)
create or replace trigger premfact 
after insert 
on contrat 
for each row 
DECLARE
prixj VEHICULE.prixJournalierVehicule%type;
prixk VEHICULE.prixkmVehicule%type;
tcont TYPECONTRAT.typeContrat%type;
totfact FACTURE.totalFacture%type;
id FACTURE.NOfacture%type;
BEGIN

--Extraction du type de contrat 
select typecontrat into tcont from
typecontrat 
where 
idtypecontrat = :NEW.idtypecontrat;
-- dans le cas ou le type de contrat est jour
if tcont = 'jour' then
-- Extraction du prix journalier d'un vehicule 
select prixJournalierVehicule into prixj from
vehicule
where immatriculationVehicule = :NEW.immatriculationVehicule;
-- Calcul du prix estime de la location 
totfact := prixj * ( :NEW.dateRetourPrevue - :NEW.dateDepartContrat );
else 
-- dans le cas d'un contrat kilometre 
-- Extraction du prix de kilometre 
select prixkmVehicule into prixk from
vehicule 
where immatriculationVehicule = :NEW.immatriculationVehicule;
-- Calcul du prix estime de la location
totfact := prixk * (:NEW.limiteKM - :NEW.kmDepartContrat);
end if;
-- Recuperation de la valeur suivante de la sequence 
    SELECT seq_facture.NEXTVAL 
  INTO id
  FROM dual;
-- Creation du tuple contenant les details de la facture 
insert into facture values (id,sysdate,totfact,0,0,0,0,0,:NEW.nocontrat,totfact);
END;
/



-- Calcul des supplements a rajouter dans la facture lors 
-- de la signature de la fiche de retour d'un vehicule
create or replace trigger factfinal 
before insert 
on ficheretour 
for each row 
DECLARE
tcont TYPECONTRAT.typeContrat%type;
datret CONTRAT.dateRetourPrevue%type;
kmret CONTRAT.kmDepartContrat%type;
prixj VEHICULE.prixJournalierVehicule%type;
prixk VEHICULE.prixkmVehicule%type;
prixl CONTRAT.prixlitre%type;
nvprix FACTURE.supplementretardFacture%type;
nvprixk FACTURE.supplementKmFacture%type;
nvprixl FACTURE.supplementPleinFacture%type;
cagence AGENCE.codeAgence%type;
depgar  VEHICULE.depotGarantieVehicule%type;
nvgar   FACTURE.soustractionGarantieFacture%type;
nocont  ficheretour.noficheretour%type;
BEGIN

-- Mise a jour du nouveau kilometrage d'un vehicule lors de son retour
update vehicule set kilometrageVehicule = :NEW.kmRetourReel where immatriculationVehicule = (select immatriculationVehicule from contrat where nocontrat = :NEW.nocontrat );
-- Extraction type contrat 
select typecontrat into tcont from
typecontrat c , contrat cc 
where 
cc.idtypecontrat = c.idtypecontrat
and cc.nocontrat = :NEW.nocontrat ;
-- dans le cas ou le type de contrat est kilometre 
-- Calcul exces kilometres si existant 
if tcont = 'kilometre' then
-- selection du kilometrage prevu du vehicule 
select limiteKM into kmret
from contrat 
where nocontrat = :NEW.nocontrat;
	-- Dans le cas d'un exces 
	if kmret < :NEW.kmRetourReel then 
	-- selection du prix du kilometre en exces 
	select prixkmVehicule into prixk from
	vehicule v, contrat c
	where v.immatriculationVehicule = c.immatriculationVehicule
	and c.nocontrat = :NEW.nocontrat;
	-- calcul du suppelemnt kilometre 
	nvprixk := prixk * (1.05) * (:NEW.kmRetourReel - kmret);
	-- mise a jour de la table facture par le nouvel supplement
	update facture set supplementKmFacture = nvprixk where nocontrat = :NEW.nocontrat;
	end if ;
	
end if;
-- selection de la date retour prevu du vehicule 
select dateRetourPrevue into datret
from contrat 
where nocontrat = :NEW.nocontrat;
	-- dans le cas de retard 
	if datret < :NEW.dateRetourReel then 
	-- selection du prix journalier du vehicule
	select prixJournalierVehicule into prixj from
	vehicule v, contrat c
	where v.immatriculationVehicule = c.immatriculationVehicule
	and c.nocontrat = :NEW.nocontrat;
	-- calcul supplement retard 
	nvprix := prixj * (1.1) * ( :NEW.dateRetourReel - datret);
	-- mise a jour de la table facture par le nouvel supplement
	update facture set supplementretardFacture = nvprix where nocontrat = :NEW.nocontrat;
	end if;
-- Dans le cas ou le reservoir du vehicule rendu est non plein
if :NEW.nbLitresManquants > 0 then
-- Selection du prix du litre  
select prixlitre into prixl
from contrat 
where nocontrat = :NEW.nocontrat;
-- Calcul du suppelement carburant
nvprixl := :NEW.nbLitresManquants * prixl ;
-- mise a jour de la table facture par le nouvel supplement
update facture set supplementPleinFacture = nvprixl where nocontrat = :NEW.nocontrat;
end if;

-- Selection du code agence ou le vehicule est rendu
select retournercodeAgence into cagence 
from contrat 
where nocontrat = :NEW.nocontrat;
--  dans le cas ou le vehicule est rendu dans une agence differente du contrat
if cagence <> :NEW.codeAgence then 
-- mise a jour de la table facture par le nouvel supplement
update facture set supplementagenceFacture = 700 where nocontrat = :NEW.nocontrat;
-- mise a jour de la table vehicule par la nouvelle position du vehicule
update vehicule set codeagence = cagence where immatriculationVehicule = (select immatriculationVehicule from contrat where nocontrat = :NEW.nocontrat );
end if;

-- selection du depot de garantie du vehicule
select depotGarantieVehicule into depgar 
from
vehicule v , contrat c 
where
v.immatriculationVehicule = c.immatriculationVehicule
and c.nocontrat = :NEW.nocontrat;
-- Calcul du cout de repartion suivant le pourcentage du degat 
nvgar := (depgar * :NEW.pourcentageReparation / 100);
-- mise a jour de la table facture par le nouvel supplement
update facture set soustractionGarantieFacture = nvgar where nocontrat = :NEW.nocontrat;

END;
/

-- Calcul du total facture lors de la mise a jour de la table facture 
-- par un/des suppelements
create or replace trigger calfact 
before update 
on facture  
for each row 
DECLARE
BEGIN

:NEW.totalfacture := :NEW.prixdebase + :NEW.supplementPleinFacture + :NEW.supplementKmFacture + :NEW.supplementretardFacture + :NEW.supplementagenceFacture + :NEW.soustractionGarantieFacture;
END;
/

--comission agance ne doit pas depasser 11%
-- pas d'erreur

-- la date d'achat de voiture ne doit pas depasser 2014
create or replace trigger dateAchatVeh
before insert or update 
on VEHICULE
for each row
BEGIN
IF ( :NEW.dateAchatVehicule < to_date('01-JAN-14', 'DD-MON-YY') ) THEN 
RAISE_APPLICATION_ERROR (-20011,
'Date vehicule ilegale  (dateAchatVehicule)');
END IF ;
END;
/
-- a tester
--trigger foreign key
--**********************************************************************************************************************************************************************************************
--trigger prof
-- table CONTRAT

-- Triggers de verification de l'existance de la cle etrangere 
-- en tant que cle primaire dans la table "mere"
create or replace trigger verif_contrat 
before insert or update 
on CONTRAT
for each row

DECLARE
cursor immatveh is 
select immatriculationVehicule from VEHICULE;
immat CONTRAT.immatriculationVehicule%type;
testImmat number(2) := 0;

cursor Npermis is 
select noPermis from CLIENT;
permis CONTRAT.noPermis%type;
testPermis number(2) := 0;


cursor Cagence is 
select codeAgence from AGENCE;
agencec AGENCE.codeAgence%type;
testagence number(2) := 0;
testagence2 number(2) := 0;


cursor tcontr is 
select idtypeContrat from typeContrat;
contr typeContrat.idtypeContrat%type;
testcont number(2) := 0;


BEGIN
-- Ouverture du curseur les cle primaire de la table "mere"
OPEN tcontr;
LOOP
FETCH tcontr into contr;
IF tcontr%NOTFOUND THEN
EXIT;
END IF;
-- Test : cle etrangere egale t elle la cle primaire 
-- Si oui la cle etrangere existe bien dans la table "mere"
-- Une variable de test changera et la boucle s'arretera
IF (:NEW.idtypeContrat = contr) THEN 
testcont := 1;
END IF ;
IF (testcont =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE tcontr;
-- Si la variable de test reste inchange =>Cle absente exception
IF testcont = 0 THEN 
RAISE_APPLICATION_ERROR (-20003,
'viol integrité table CONTRAT (idtypeContrat)');
END IF;



OPEN immatveh;
LOOP
FETCH immatveh into immat;
IF immatveh%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.immatriculationVehicule = immat) THEN 
testImmat := 1;
END IF ;
IF (testImmat =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE immatveh;

IF testImmat = 0 THEN 
RAISE_APPLICATION_ERROR (-20003,
'viol integrité table CONTRAT (immatriculationVehicule)');
END IF;

OPEN Npermis;
LOOP
FETCH Npermis into permis;
IF Npermis%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.noPermis = permis) THEN 
testPermis := 1;
END IF ;
IF (testPermis =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE Npermis;

IF testPermis = 0 THEN 
RAISE_APPLICATION_ERROR (-20004,
'viol integrité table CONTRAT (noPermis)');
END IF;




OPEN Cagence;
LOOP
FETCH Cagence into agencec;
IF Cagence%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.retournercodeAgence = agencec) THEN 
testagence := 1;
END IF ;
IF (:NEW.codeAgence = agencec) THEN 
testagence2 := 1;
END IF ;
IF (testagence =1 and testagence2=1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE Cagence;

IF testagence = 0 THEN 
RAISE_APPLICATION_ERROR (-20003,
'viol integrité table CONTRAT (retournercodeAgence)');
END IF;
IF testagence2 = 0 THEN 
RAISE_APPLICATION_ERROR (-20003,
'viol integrité table CONTRAT (codeAgence)');
END IF;
END;
/
--************************************************************************************************************************
-- table VERICULE
create or replace trigger verif_vehicule
before insert or update 
on VEHICULE
for each row


DECLARE
cursor Cgence is 
select codeAgence from AGENCE;
agence VEHICULE.codeAgence%type;
testagence number(2) := 0;


BEGIN

select codeAgence into agence from agence where codeAgence = :NEW.codeagence;
if agence <> :NEW.code
OPEN Cgence;
LOOP
FETCH Cgence into agence;
IF Cgence%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.codeAgence = agence) THEN 
testagence := 1;
END IF ;
IF (testagence =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE Cgence;

IF testagence = 0 THEN 
RAISE_APPLICATION_ERROR (-20008,
'viol integrité table VEHICULE (codeAgence)');
END IF;
END;
/
--************************************************************************************************************************
create or replace trigger verif_ficheretour 
before insert or update 
on FICHERETOUR
for each row

DECLARE

cursor Npermis is 
select noPermis from CLIENT;
permis CONTRAT.noPermis%type;
testPermis number(2) := 0;


cursor Cagence is 
select codeAgence from AGENCE;
agencec AGENCE.codeAgence%type;
testagence number(2) := 0;

cursor ncont is 
select nocontrat from contrat;
cont CONTRAT.nocontrat%type;
testcont number(2) := 0;

BEGIN

OPEN ncont;
LOOP
FETCH ncont into cont;
IF ncont%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.noContrat = cont) THEN 
testcont := 1;
END IF ;
IF (testcont =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE ncont;

IF testcont = 0 THEN 
RAISE_APPLICATION_ERROR (-20004,
'viol integrité table CONTRAT (noContrat)');
END IF;



OPEN Npermis;
LOOP
FETCH Npermis into permis;
IF Npermis%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.noPermis = permis) THEN 
testPermis := 1;
END IF ;
IF (testPermis =1 ) THEN
EXIT;
END IF;
END LOOP;
CLOSE Npermis;

IF testPermis = 0 THEN 
RAISE_APPLICATION_ERROR (-20004,
'viol integrité table CONTRAT (noPermis)');
END IF;




OPEN Cagence;
LOOP
FETCH Cagence into agencec;
IF Cagence%NOTFOUND THEN
EXIT;
END IF;
IF (:NEW.codeAgence = agencec) THEN 
testagence := 1;
END IF ;
IF (testagence =1) THEN
EXIT;
END IF;
END LOOP;
CLOSE Cagence;

IF testagence = 0 THEN 
RAISE_APPLICATION_ERROR (-20003,
'viol integrité table CONTRAT (retournercodeAgence)');
END IF;

END;
/

--**********************************************************************************************************************************************

--**************************************************************************************************************************************************************************************

-- Creation d'une table qui contiendra la liste des contraintes
create table contraintes (constraint_name VARCHAR2(30),constraint_type VARCHAR2(30),table_name VARCHAR2(30),SEARCH_CONDITION CLOB);
-- liste_ora_constraints

-- Script de recuperation des contraintes
DECLARE 

BEGIN
-- Vider les anciennes valeurs 
delete from contraintes;
-- Recuperer les contraintes suivant l'utilisateur tries par les nom des tableaux et types de contraintes
insert into contraintes (constraint_name,constraint_type,table_name,SEARCH_CONDITION) 
SELECT constraint_name,DECODE (constraint_type, 'P', 'cle primaire','R', 'cle etrangere','C','check','U','unique','V','check view','O','lecture seule') type,table_name,to_lob(SEARCH_CONDITION) FROM user_constraints WHERE table_name in (SELECT table_name FROM user_tables) order by table_name,constraint_type desc ;


END;
/
-- Tables contenant les triggers 
create table triggers (trigger_name VARCHAR2(30),table_name VARCHAR2(30));

-- Script de recuperation des triggers
DECLARE

BEGIN
-- Vider les anciennes valeurs 
delete from triggers;
-- Selection des triggers
insert into triggers (trigger_name,table_name) 
select trigger_name,table_name from all_triggers
where table_name in (SELECT table_name FROM user_tables) order by table_name;
END;
/

-- Creation d'une table qui contiendra la liste des cle primaires
create table cle_primaire (constraint_name VARCHAR2(30),table_name VARCHAR2(30),column_name VARCHAR2(4000));

-- liste cle primaire de chaque table et nom contrainte 
DECLARE

BEGIN
delete from cle_primaire;

insert into cle_primaire (constraint_name,table_name,column_name)
select c.constraint_name,c.table_name,a.column_name from user_constraints c, all_cons_columns a 
where c.constraint_name= a.constraint_name and c.table_name = a.table_name and c.constraint_type = 'P'
and c.table_name in (SELECT table_name FROM user_tables) order by c.table_name;
END;
/


-- Creation d'une table qui contiendra la liste des cle etrangeres
create table cle_etrangere (constraint_name VARCHAR2(30),table_name VARCHAR2(30),column_name VARCHAR2(4000),r_table_name VARCHAR2(30) );
-- liste cle etrangeres les tables et colonnes qui les referents 
DECLARE

BEGIN
delete from cle_etrangere;
insert into cle_etrangere (constraint_name,table_name,column_name,r_table_name)
SELECT c.constraint_name,c.table_name,a.column_name, (select r.table_name from user_constraints r where r.constraint_name = c.r_constraint_name) r_table_name
FROM user_constraints c, all_cons_columns a 
where c.constraint_name = a.constraint_name and c.table_name = a.table_name and 
 constraint_type = 'R' and c.table_name in (SELECT table_name FROM user_tables) order by c.table_name;
END;
/


-- EXPLAIN PLAN
explain plan 
for
SELECT distinct IMMATRICULATIONVEHICULE from (select IMMATRICULATIONVEHICULE,SUBSTR(cpAgence,0,2) as departement
from contrat c , agence a 
where a.codeagence = c.codeAgence) rq1
where not exists (
    select * from (SELECT SUBSTR(cpAgence,0,2) as departement
FROM agence
group by SUBSTR(cpAgence,0,2)) rq2
    where not exists (
        select * from (select IMMATRICULATIONVEHICULE,SUBSTR(cpAgence,0,2) as departement
from contrat c , agence a 
where a.codeagence = c.codeAgence) rq3
        where rq3.departement = rq2.departement
        and   rq3.IMMATRICULATIONVEHICULE = rq1.IMMATRICULATIONVEHICULE
    )
);
select * from table(dbms_xplan.display);

-----------------------------------------------------------------------------------------------------
| Id  | Operation                       | Name              | Rows  | Bytes | Cost (%CPU)| Time     |
-----------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                |                   |    20 |   640 |    20   (5)| 00:00:01 |
|   1 |  HASH UNIQUE                    |                   |    20 |   640 |    20   (5)| 00:00:01 |
|*  2 |   FILTER                        |                   |       |       |            |          |
|   3 |    TABLE ACCESS FULL            | CONTRAT           |    33 |  1056 |     3   (0)| 00:00:01 |
|*  4 |    FILTER                       |                   |       |       |            |          |
|   5 |     TABLE ACCESS FULL           | AGENCE            |    34 |  1088 |     3   (0)| 00:00:01 |
|   6 |     NESTED LOOPS                |                   |       |       |            |          |
|   7 |      NESTED LOOPS               |                   |     1 |   128 |     3   (0)| 00:00:01 |
|*  8 |       TABLE ACCESS FULL         | CONTRAT           |     1 |    64 |     3   (0)| 00:00:01 |
|*  9 |       INDEX UNIQUE SCAN         | CLEPRIMAITEAGENCE |     1 |       |     0   (0)| 00:00:01 |
|* 10 |      TABLE ACCESS BY INDEX ROWID| AGENCE            |     1 |    64 |     0   (0)| 00:00:01 |
-----------------------------------------------------------------------------------------------------


Predicate Information (identified by operation id):
---------------------------------------------------

   2 - filter( NOT EXISTS (SELECT 0 FROM "AGENCE" "SYS_ALIAS_1" WHERE  NOT EXISTS (SELECT 0
              FROM "AGENCE" "A","CONTRAT" "C" WHERE "IMMATRICULATIONVEHICULE"=:B1 AND
              "A"."CODEAGENCE"="C"."CODEAGENCE" AND SUBSTR("CPAGENCE",0,2)=SUBSTR(:B2,0,2))))
   4 - filter( NOT EXISTS (SELECT 0 FROM "AGENCE" "A","CONTRAT" "C" WHERE
              "IMMATRICULATIONVEHICULE"=:B1 AND "A"."CODEAGENCE"="C"."CODEAGENCE" AND
              SUBSTR("CPAGENCE",0,2)=SUBSTR(:B2,0,2)))
   8 - filter("IMMATRICULATIONVEHICULE"=:B1)
   9 - access("A"."CODEAGENCE"="C"."CODEAGENCE")
  10 - filter(SUBSTR("CPAGENCE",0,2)=SUBSTR(:B1,0,2))

Note
-----
   - dynamic sampling used for this statement (level=2)
explain plan 
for
with stat as (
		select EXTRACT(month from datecontrat) as mois,sum(totalFacture) as recettes
		from contrat JOIN FACTURE on contrat.noContrat=FACTURE.noContrat
		where datecontrat between to_date('01-JAN-2018', 'DD-MON-RR') 
		and to_date('31-DEC-2018', 'DD-MON-RR')
		group by EXTRACT(month from datecontrat)
		)
select TO_CHAR(TO_DATE(mois, 'MM'), 'MONTH')as mois,recettes 
from stat 
where recettes = (select max(recettes) from stat);
select * from table(dbms_xplan.display);


-------------------------------------------------------------------------------------------------------------
| Id  | Operation                       | Name                      | Rows  | Bytes | Cost (%CPU)| Time     |
-------------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                |                           |    24 |   624 |     8  (13)| 00:00:01 |
|   1 |  TEMP TABLE TRANSFORMATION      |                           |       |       |            |          |
|   2 |   LOAD AS SELECT                | SYS_TEMP_0FD9D6605_A08741 |       |       |            |          |
|   3 |    HASH GROUP BY                |                           |    24 |  1584 |     4  (25)| 00:00:01 |
|   4 |     NESTED LOOPS                |                           |       |       |            |          |
|   5 |      NESTED LOOPS               |                           |    24 |  1584 |     3   (0)| 00:00:01 |
|   6 |       TABLE ACCESS FULL         | FACTURE                   |    33 |   858 |     3   (0)| 00:00:01 |
|*  7 |       INDEX UNIQUE SCAN         | CLEPRIMAIRECONTRAT        |     1 |       |     0   (0)| 00:00:01 |
|*  8 |      TABLE ACCESS BY INDEX ROWID| CONTRAT                   |     1 |    40 |     0   (0)| 00:00:01 |
|*  9 |   VIEW                          |                           |    24 |   624 |     2   (0)| 00:00:01 |
|  10 |    TABLE ACCESS FULL            | SYS_TEMP_0FD9D6605_A08741 |    24 |   624 |     2   (0)| 00:00:01 |
|  11 |    SORT AGGREGATE               |                           |     1 |    13 |            |          |
|  12 |     VIEW                        |                           |    24 |   312 |     2   (0)| 00:00:01 |
|  13 |      TABLE ACCESS FULL          | SYS_TEMP_0FD9D6605_A08741 |    24 |   624 |     2   (0)| 00:00:01 |
-------------------------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   7 - access("CONTRAT"."NOCONTRAT"="FACTURE"."NOCONTRAT")
   8 - filter("CONTRAT"."DATECONTRAT">=TO_DATE(' 2018-01-01 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND
              "CONTRAT"."DATECONTRAT"<=TO_DATE(' 2018-12-31 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND
              "DATEDEPARTCONTRAT">=TO_DATE(' 2018-01-01 00:00:00', 'syyyy-mm-dd hh24:mi:ss') AND
              "DATERETOURPREVUE">=TO_DATE(' 2018-01-01 00:00:00', 'syyyy-mm-dd hh24:mi:ss'))
   9 - filter("RECETTES"= (SELECT MAX("RECETTES") FROM  (SELECT /*+ CACHE_TEMP_TABLE ("T1") */ "C0"
              "MOIS","C1" "RECETTES" FROM "SYS"."SYS_TEMP_0FD9D6605_A08741" "T1") "STAT"))

Note
-----
   - dynamic sampling used for this statement (level=2)


--BROUILLON


-- TESTS
 insert into vehicule values ('AA-236-UGC','2.JUL.2017',62781,'Mercedes-Benz',340,'C-Class','Berline',0,100095,'Paris');
 insert into agence values ('Paris',7512022,'3 rue Harpignies',75020,6);
	insert into plein values (28912,100095,30.26);
insert into contrat values(201800032,'29.JUL.2018','30.JUL.2018','9.NOV.2018',58253,61055,'28.OCT.2018',318.4,9304810,9404204,'AA-236-UGC',14056013,28943,0);
update contrat set immatriculationVehicule = 'AA-236-UGC' where immatriculationVehicule = 'BN-268-LVP';
select totalfacture from contrat where nocontrat = 201800001;
select prixJournalierVehicule from vehicule where  immatriculationVehicule= 'AA-236-UGC';

insert into contrat values (201800050,'12.JUL.2018','19.JUL.2019',44390,'11.JUL.2018',62500,'AA-236-UGC',67454398,7512022,7512022,0,6001);
insert into ficheretour values (5000,'21.JUL.2019',62781,16,19,7512022,67454398,201800001);

INSERT INTO CONTRAT VALUES(201800011,'18.JUL.2018','20.JUL.2018',22490,'17.JAN.2018',0,'AA-236-UGC',37497384,9164502,7511903,0,6002);
select *
    from contrat 
    where immatriculationVehicule = 'AA-236-UGC';


ALTER TABLE facture ADD prixdebase number(10,2);
-- rajouter 10% au prix journalier d'un vehicule qui a un prix journalier inferieur a 50 euro

update VEHICULE set prixJournalierVehicule = prixJournalierVehicule*(1.1) where prixJournalierVehicule < 50;


-- sequence 
--nocontrat
BEGIN
DECLARE
seqval contrat.noContrat%type;
  BEGIN
  SELECT MAX(noContrat)
  INTO seqval
  FROM contrat;
  execute immediate('CREATE SEQUENCE seq_contrat MINVALUE 201000000 START WITH '||seqval||' INCREMENT BY 1 CACHE 20');
  END;
END;
/
CREATE OR REPLACE TRIGGER trig_Nocontrat
before INSERT ON contrat
FOR EACH ROW
BEGIN
  SELECT seq_contrat.NEXTVAL 
  INTO :new.noContrat
  FROM dual;
END;
/

--NOFICHERETOUR 
BEGIN
DECLARE
seqval FICHERETOUR.NOFICHERETOUR%type;
  BEGIN
  SELECT MAX(NOFICHERETOUR)
  INTO seqval
  FROM FICHERETOUR;
  execute immediate('CREATE SEQUENCE seq_FICHERETOUR MINVALUE 5000 START WITH '||seqval||' INCREMENT BY 1 CACHE 20');
  END;
END;
/
CREATE OR REPLACE TRIGGER trig_NOFICHERETOUR
before INSERT ON FICHERETOUR
FOR EACH ROW
BEGIN
  SELECT seq_FICHERETOUR.NEXTVAL 
  INTO :new.NOFICHERETOUR
  FROM dual;
END;
/







	

	



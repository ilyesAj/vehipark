procedure de rendement de vehicule 
--les marques de vehicules préférées des clients 
-- premier select pour afficher la marque de vehicule qui a le max de contrat .
--le deuxieme et troixieme select pour extraire le max du nb de contrat selon la marque 
select count(noPermis) as nb,marqueVehicule
	FROM contrat C ,vehicule v
	where 
	c.immatriculationVehicule=v.immatriculationVehicule
	group by( marqueVehicule)
	having count(noPermis) in (select max(nb)
				   from
				   (select count(noPermis) as nb,marqueVehicule
	                            FROM contrat C ,vehicule v
				    where 
				    c.immatriculationVehicule=v.immatriculationVehicule
	  			    group by( marqueVehicule)));

--les noms des clients qui ont reservés(ou retourner) dans le département 78 
SELECT nomClient,prenomCLient 
FROM client c ,contrat co 
WHERE co.noPermis=c.noPermis and  ( RETOURNERCODEAGENCE in (SELECT codeAgence FROM agence where cpAgence LIKE '78%' ) or CODEAGENCE in (SELECT codeAgence FROM agence where cpAgence LIKE '78%' ) );

--les vehicules de type coupé qui n'ont pas été loué À PARTIR DE 1 JANVIER 2019
select immatriculationVehicule 
from vehicule
where categorieVehicule='Coupe' and 
immatriculationVehicule not in (select immatriculationVehicule from contrat where datedepartcontrat >to_date('01-JAN-2019', 'DD-MON-RR'));

-- le pourcentage  du cout des pleins de l'essence par rapport au total des contrats 
SELECT sum(c.prixLitre*f.NBLITRESMANQUANTS)/sum(fa.totalfacture)*100 
from contrat c,ficheRetour f,facture fa
WHERE c.noContrat=f.noContrat
and fa.noContrat=c.noContrat;

--les département qui n'a eu ni un retour ni un contrat 
SELECT SUBSTR(cpAgence,0,2)
FROM agence
where codeAgence not in (select codeagence from contrat UNION select CODEAGENCE from ficheretour );
--les immatriculation de tout les vehicules qui ont ete loués sur tout les département 

-- Codes des deparmetements ou il existe des agences X1
SELECT SUBSTR(cpAgence,0,2)
SELECT SUBSTR(cpAgence,0,2) as departement									
FROM agence
group by SUBSTR(cpAgence,0,2);

--immatricualation des vehicules accompagnes par les codes departement X2
select IMMATRICULATIONVEHICULE,SUBSTR(cpAgence,0,2) as departement
from contrat c , agence a 
where a.codeagence = c.codeAgence;


-- X2 div X1 : les immatriculation de  tout les vehicules qui ont ete loués sur tout les département
select distinct IMMATRICULATIONVEHICULE from (select IMMATRICULATIONVEHICULE,SUBSTR(cpAgence,0,2) as departement
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

--le type de vehicule le plus rentable en été de 2018  
-- la sous-table somme contient le total des facture selon l'immatriculation dans la periode de l'ete 
select categorieVehicule
from vehicule
where immatriculationVehicule in (
	with somme as(select immatriculationVehicule,sum(totalfacture) sm
			from contrat c join facture f on f.noContrat=c.noContrat
			where dateDepartContrat between to_date('01-JUN-2018', 'DD-MON-RR') and to_date('31-AUG-2018', 'DD-MON-RR')
			group by (immatriculationVehicule))
	select immatriculationVehicule from somme where sm=(select max(sm) from somme)); 



--les clients qui ont pris des vehicules dans une agence et l'on rendu dans une autre agence 
SELECT nomClient,prenomClient 
from contrat c,client cl,ficheretour f
WHERE c.noPermis=cl.noPermis
and c.noContrat=f.noContrat
AND  c.codeAgence <> f.codeAgence;

--les clients qui ont reservé une vehicule  de type monospace et de puissance supérieure à 100 
SELECT distinct nomClient,prenomClient 
from contrat c,client cl,vehicule vl
WHERE c.noPermis=cl.noPermis
and c.immatriculationVehicule=vl.immatriculationVehicule
AND  vl.categorieVehicule='Monospace'
And vl.puissanceVehicule>100;

--le prix moyen de contrat pour les véhicules achetés en 2018  
SELECT vehicule.immatriculationVehicule,AVG(totalfacture) 
FROM CONTRAT,vehicule,facture
where CONTRAT.immatriculationVehicule=vehicule.immatriculationVehicule
AND facture.noContrat=contrat.noContrat
AND vehicule.dateAchatVehicule >= '01JAN2018' 
AND vehicule.dateAchatVehicule < '01JAN2019' 
GROUP BY vehicule.immatriculationVehicule;
--le pays des clients qui ont une facture de plus de 1000 euros en 2018
SELECT distinct paysClient 
from client,contrat ,facture
where client.noPermis=contrat.noPermis
AND facture.nocontrat=contrat.nocontrat
AND contrat.dateContrat >= '01JAN2018' 
AND contrat.dateContrat < '01JAN2019' 
AND facture.totalfacture>1000
-- l'agence qui a reservé le plus de contrats entre 2017 et 2018
select numero, max(nombreDeContrat) 
FROM 
    (SELECT CONTRAT.codeAgence as numero,count(*) as nombreDeContrat
    FROM contrat
    WHERE contrat.dateContrat >= '01JAN2017' 
    AND contrat.dateContrat < '01JAN2019' group by CONTRAT.codeAgence )
GROUP BY numero;

--le code de l'agence qui a fait que des retours (sans faire aucun contrat)
SELECT codeAgence 
FROM agence 
WHERE codeAgence in (SELECT codeAgence FROM ficheRetour)
AND codeAgence not in (SELECT codeAgence FROM contrat);
	
--le nom des clients qui ont plus de 5 jours de retard 
--HOUNI hatit sysdate 5ater el reele matetbedel ken ki ykaml w twali ont eu mch ont :p
SELECT nomClient,prenomCLient 
FROM client c ,contrat co 
WHERE c.noPermis=co.noPermis AND SYSDATE-dateRetourPrevue > 5 ;

-- le nombre de contrat qui ont un depot de garantie de plus de 10% du prix total de la facture
SELECT count(*) 
FROM facture , contrat ,vehicule
WHERE facture.noContrat=contrat.noContrat    
AND contrat.immatriculationVehicule=vehicule.immatriculationVehicule
AND facture.totalfacture*0.1 < vehicule.DEPOTGARANTIEVEHICULE;

-- le nom du client le plus fidéle(le client qui ont reservés plus que tout les clients ) 
select nomclient from
(select count(nopermis) as nb,nopermis from contrat 
group by  nopermis) t, client c
where c.nopermis=t.nopermis and t.nb = (select max(nb) from 
(select count(nopermis) as nb,nopermis from contrat 
group by  nopermis)) ; 

-- le type préféré d'un client donnée 

select CATEGORIEVEHICULE 
from (select count(CATEGORIEVEHICULE ) as nb, CATEGORIEVEHICULE from vehicule v, contrat c 
where c.IMMATRICULATIONVEHICULE = v.IMMATRICULATIONVEHICULE
and c.nopermis = 67454398
group by CATEGORIEVEHICULE )
where nb = (select max(nb) from (select count(CATEGORIEVEHICULE ) as nb, CATEGORIEVEHICULE from vehicule v, contrat c 
where c.IMMATRICULATIONVEHICULE = v.IMMATRICULATIONVEHICULE
and c.nopermis = 67454398
group by CATEGORIEVEHICULE) );

-- le mois le plus rentable en 2018 
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

--la liste des vehicule , l'agence de location et l'argence de retour
select c.immatriculationVehicule ,c.codeagence,fr.codeagence
from contrat c join ficheretour fr on c.noContrat=fr.noContrat;





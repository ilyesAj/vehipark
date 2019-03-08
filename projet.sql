drop user projet CASCADE ;
create user projet identified by projet 
default tablespace users 
QUOTA 10M on users ; 
grant unlimited tablespace to projet ;
grant create session , alter session , grant any privilege to projet ;
grant create table to projet ;
grant create tablespace , alter tablespace , drop tablespace to projet ;
GRANT CREATE TRIGGER TO projet;

GRANT CREATE ANY INDEX  to projet;

connect projet/projet ;  

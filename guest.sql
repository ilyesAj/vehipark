drop user iheb CASCADE ;
create user iheb identified by iheb 
default tablespace users 
QUOTA 10M on users ; 
grant unlimited tablespace to iheb ;



connect iheb/iheb ;  

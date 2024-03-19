create table users(
user_id int,
name varchar(255),
PRIMARY KEY (user_id)
);
create table country_area(
area_id int,
parent_area_id int REFERENCES country_area(area_id),
name varchar(255),
PRIMARY KEY (area_id)
);

create table country_area_manager(
user_id int REFERENCES users(user_id),
area_id int REFERENCES country_area(area_id),
PRIMARY KEY (user_id,area_id)
);




-- 1-------------------------------function create_users

create or replace function create_users( ucount int )
returns int 
LANGUAGE plpgsql
 as $$
 declare
   u_count int;
 begin 	
  u_count := (select count(user_id) from users);
 	for c in 1..ucount 
 	loop 	
	 	insert into users (user_id  , name ) values (c+u_count , concat('user',c+u_count)) ;	
 	end loop ;
 	return ucount ;
 end; $$ ;

-- 2------------------------function create_country

create or replace function create_country( ucount int )
returns int 
LANGUAGE plpgsql
 as $$
 declare
   c_count int;
 begin 	
  c_count := (select count(area_id) from country_area);
 	for c in 1..ucount 
 	loop 	
	 	insert into country_area (area_id  , name )
	 values (c+c_count ,   concat('area',c+c_count)) ;	
 	end loop ;
 
 	for c in 1..ucount 
 	loop
	 	UPDATE country_area 
	 SET parent_area_id = floor(random() * ( ((ucount+c_count)-(c_count+c))+1) + (c_count+c))::int 
	WHERE area_id = c +c_count	;
 	end loop ;	
 
 UPDATE country_area SET parent_area_id = null WHERE area_id = parent_area_id	;
 return ucount ;
 end; $$ ; 



-- 3-------------CREATE link_users_to_areas_without_manager

CREATE OR REPLACE FUNCTION link_users_to_areas_without_manager()
RETURNS VOID AS
$$
BEGIN
 INSERT INTO country_area_manager (user_id, area_id)
    SELECT u.user_id, ca.area_id
    FROM users u
    JOIN country_area ca ON NOT EXISTS (
        SELECT 1
        FROM country_area_manager cam
        WHERE cam.area_id = ca.area_id
    )
    LEFT JOIN country_area_manager cam2 ON u.user_id = cam2.user_id
    WHERE cam2.area_id IS NULL;
END;
$$ LANGUAGE plpgsql;


-- -----sd
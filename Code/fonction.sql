-- 2)

/*
 *	Les types personnalisés nous évitent
 *	plusieurs redéfinitions en cas de changement :
 *	
 *	- typeName (varchar (50))
 *	- typePrice (numeric (8, 2))
 *	- coupleNamePrice (typeName, typePrice)
 */
 

drop type
if exists
typeName
cascade
;

create type
typeName
as (base varchar (50))
;


drop type
if exists
typePrice
cascade
;

create type
typePrice
as (base numeric (8, 2))
;


drop type
if exists
coupleNamePrice
cascade
;

create type
coupleNamePrice
as
(
	_name typeName,
	price typePrice
);


create or replace function
loadData ()
returns void
as $$


	declare
	
		catalogName meta.table_name % type;
		attributeName text;
		attributePrice text;
		formatCode meta.trans_code % type;
		
		product coupleNamePrice;
		productName typeName;
		productPrice typePrice;
		

	begin
		
		raise info E'\nDébut de loadData ()';
		

		-- 2.1)
		
		drop table
		if exists
		C_ALL
		cascade
		;
	
	
		-- 2.2 et 2.6)
	
		create table
		C_ALL
		(
			-- "pid" s'incrémente automatiquement
			pid serial primary key,
			pname varchar (50),
			pprice numeric (8, 2)
		);
		
		
		-- 2.3)
		
		-- Curseur sur les noms des tables catalogues
		for catalogName
		in
			select distinct meta.table_name
			from meta
			
		loop
			
			
			-- 2.4)
			
			-- Attribut du nom
			select column_name
			from information_schema.columns
			into attributeName
			where upper (table_name) = catalogName
			and column_name like '%name%'
			limit 1
			;
			
			-- Attribut du prix
			select column_name
			from information_schema.columns
			into attributePrice
			where upper (table_name) = catalogName
			and column_name like '%price%'
			limit 1
			;
			
			
			-- 2.7)
			
			-- Code de formattage des données
			select trans_code
			from meta
			into formatCode
			where upper (meta.table_name) = catalogName
			limit 1
			;
			
			
			-- 2.5)
			
			-- Curseur sur les noms et les prix
			for product
			in
				execute
					'select row ('
					|| attributeName
					|| '), row ('
					|| attributePrice
					|| ') from '
					|| catalogName
					|| ';'
			
			loop
				
				
				-- 2.7)
			
				productName.base = (product._name).base;
				productPrice.base = (product.price).base;
				
				-- Formattage des données
				if formatCode like '%CAP%'
				then
					productName.base := upper (productName.base);
				end if;
				
				if formatCode like '%CUR%'
				then
					productPrice.base := productPrice.base / 1.05;
				end if;
				
				-- Insertion
				insert into
				C_ALL
				values
				(
					default,
					productName.base,
					productPrice.base
				);
			
			
			end loop;
			
			
		end loop;
		
		return;
		
		
	end
	

$$ language plpgsql;

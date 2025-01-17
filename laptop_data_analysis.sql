-- first step is to create a backup table
-- CREATING BACKUP
CREATE TABLE laptops_backup LIKE laptops;

INSERT INTO laptops_backup 
(SELECT * FROM laptops); 

-- KNOW INFORMATION ABOUT TABLE

SELECT * FROM information_schema.TABLES
WHERE TABLE_SCHEMA = "data_cleaning";

-- drop UNAMED:0 
ALTER TABLE laptops DROP COLUMN `Unnamed: 0`;

-- ADDING INDEX COL
ALTER TABLE laptops 
ADD COLUMN `index` INTEGER AUTO_INCREMENT PRIMARY KEY;


-- 
-- /**************************** + DATA CLEANING + ****************************\  

-- Remove the null values
WITH Temp_table AS 
        (
        SELECT `index`
        FROM laptops
        WHERE Company IS NULL 
        AND TypeName IS NULL 
        AND Inches IS NULL
        AND ScreenResolution IS NULL 
        AND Cpu IS NULL 
        AND Ram IS NULL
        AND Memory IS NULL 
        AND Gpu IS NULL 
        AND OpSys IS NULL
        AND Weight IS NULL 
        AND Price IS NULL
        )

        DELETE FROM laptops
        WHERE `index` IN (SELECT `index` FROM Temp_table);

-- CHANGING DTYPE
 ALTER TABLE laptops MODIFY COLUMN Inches DECIMAL(10,1);

-- Remove the GB from Ram column to make it a integer column
 UPDATE laptops 
        SET Ram = REPLACE(Ram,"GB","")

ALTER TABLE laptops MODIFY COLUMN Ram INTEGER;

-- Remove the kg from Weight column to make it a integer column
UPDATE laptops l1
        SET Weight = (SELECT WGHT FROM (SELECT `index`,REPLACE(Weight,"kg","") AS WGHT FROM laptops ) l2 WHERE l1.index = l2.index);
ALTER TABLE laptops MODIFY COLUMN Weight INTEGER;

USE data_cleaning;

-- FINDING DUPLICATES
SELECT * FROM (
SELECT MIN(`index`) AS `index`,COUNT(*) AS Duplicate_counts 
FROM laptops 
GROUP BY Company,
TypeName,
Inches,
ScreenResolution,
Cpu,
Ram,
Memory,
Gpu,
OpSys,
Weight,
Price) t1	
WHERE Duplicate_counts >= 1;

-- DUPLICATES REMOVAL

WITH ndx_to_keep AS (SELECT MIN(`index`) AS `index`
FROM laptops 
GROUP BY Company,
TypeName,
Inches,
ScreenResolution,
Cpu,
Ram,
Memory,
Gpu,
OpSys,
Weight,
Price)

DELETE FROM laptops WHERE `index` NOT IN (SELECT * FROM ndx_to_keep);
       

-- Roundinf off prices to make it integer

SELECT Price FROM laptops;
UPDATE laptops l1
SET Price = (SELECT Pricing FROM (SELECT `index`,Round(Price) As Pricing 
								FROM laptops) l2 WHERE l1.index = l2.index);
                             
ALTER TABLE laptops MODIFY COLUMN Price INTEGER;

-- cleaning operating system column
UPDATE laptops
SET OpSys = 
CASE 
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys = 'No OS' THEN 'N/A'
    ELSE 'other'
END;

SELECT * FROM laptops;

-- /**************************** + FEATURE ENGINEERING + ****************************\

-- Feature eng on gpu col
ALTER TABLE laptops
ADD COLUMN gpu_brand VARCHAR(255) AFTER Gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

SELECT Gpu, SUBSTRING_INDEX(Gpu, " ", 1 ) FROM laptops;

UPDATE laptops l1
SET gpu_brand = (SELECT Temp FROM (SELECT `index`,SUBSTRING_INDEX(Gpu,' ',1) AS Temp
				FROM laptops )l2 WHERE l2.index = l1.index);
                
SELECT * FROM laptops;



                
UPDATE laptops l1
SET gpu_name = (SELECT Temp FROM (SELECT `index`,REPLACE(Gpu,gpu_brand,'')  AS Temp
				FROM laptops )l2 WHERE l2.index = l1.index);
                
SELECT * FROM laptops;
ALTER TABLE laptops DROP COLUMN Gpu;



-- Feature eng on cpu col
ALTER TABLE laptops
ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_name;

UPDATE laptops l1
SET cpu_brand = (SELECT Temp FROM (SELECT `index`,SUBSTRING_INDEX(Cpu,' ',1)  AS Temp
				FROM laptops )l2 WHERE l2.index = l1.index);
                
SELECT * FROM laptops;

SELECT `index`, CAST(REPLACE(SUBSTRING_INDEX(Cpu,' ',-1),'GHz','') AS DECIMAL(10,2)) AS Temp FROM laptops;

-- Remove GHz from cpu speed to make it float
UPDATE laptops l1
SET cpu_speed = (SELECT Temp FROM (SELECT  `index`, CAST(REPLACE(SUBSTRING_INDEX(Cpu,' ',-1),'GHz','') AS DECIMAL(10,2)) AS Temp
				FROM laptops )l2 WHERE l2.index = l1.index);
                
                

SELECT Cpu, TRIM(TRAILING SUBSTRING_INDEX(Cpu,' ',-1) FROM (TRIM(leading cpu_brand FROM Cpu))) AS cpu_name 
FROM laptops;

-- removing white spaces
UPDATE laptops l1
SET cpu_name = (SELECT Temp FROM (SELECT  `index`, TRIM(TRAILING SUBSTRING_INDEX(Cpu,' ',-1) FROM (TRIM(leading cpu_brand FROM Cpu))) AS Temp
				FROM laptops )l2 WHERE l2.index = l1.index);
                
                
SELECT * FROM laptops;

ALTER TABLE laptops DROP COLUMN Cpu;


-- Feature eng on ScreenResolution
ALTER TABLE laptops 
ADD COLUMN res_width INTEGER AFTER ScreenResolution,
ADD COLUMN res_height INTEGER AFTER res_width,
ADD COLUMN is_touchscreen INTEGER AFTER res_height;

SELECT ScreenResolution,SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ', -1), "x",1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ', -1), "x",-1) FROM laptops;

UPDATE laptops
SET res_height = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ', -1), "x",1),
res_width = SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ', -1), "x",-1);

SELECT ScreenResolution,ScreenResolution LIKE "%TOUCHSCREEN%" FROM laptops;

UPDATE laptops l1
SET is_touchscreen = (SELECT Temp FROM
					(SELECT `index`,ScreenResolution LIKE "%TOUCHSCREEN%" AS Temp FROM laptops) l2
					WHERE l1.index = l2.index);
                    
                    


-- Feature engineering on cpu_name
ALTER TABLE laptops
ADD COLUMN Cpu_gen VARCHAR(255) AFTER cpu_name;


SELECT cpu_name,
CASE WHEN cpu_name LIKE "%CORE%" AND NOT substring_index(TRIM(cpu_name)," ",-1) LIKE "%i%"
  THEN substring_index(TRIM(cpu_name)," ",-1) 
ELSE NULL
END AS generation
FROM laptops;


UPDATE laptops l1
SET Cpu_gen = CASE WHEN cpu_name LIKE "%CORE%" AND NOT substring_index(TRIM(cpu_name)," ",-1) LIKE "%i%"
  THEN substring_index(TRIM(cpu_name)," ",-1) 
ELSE NULL
END;


ALTER TABLE laptops
DROP COLUMN ScreenResolution;


SELECT cpu_name,
SUBSTRING_INDEX(TRIM(cpu_name),' ',2)
FROM laptops;

UPDATE laptops
SET cpu_name = SUBSTRING_INDEX(TRIM(cpu_name),' ',2);


SELECT DISTINCT cpu_name FROM laptops;


--Feature engineering on Memory col


ALTER TABLE laptops
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_storage INTEGER AFTER memory_type,
ADD COLUMN secondary_storage INTEGER AFTER primary_storage;


SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptops;

UPDATE laptops
SET memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END;

-- ram and rom ki info
SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,' ',1),'[0-9]+'),
CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END
FROM laptops;

UPDATE laptops
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END;

-- Converting Terabyte to Gigabyte

SELECT 
primary_storage,
CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage,
CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END
FROM laptops;

UPDATE laptops
SET primary_storage = CASE WHEN primary_storage <= 2 THEN primary_storage*1024 ELSE primary_storage END,
secondary_storage = CASE WHEN secondary_storage <= 2 THEN secondary_storage*1024 ELSE secondary_storage END;


ALTER TABLE laptops DROP COLUMN gpu_name;
ALTER TABLE laptops DROP COLUMN Memory;

SELECT * FROM laptops;




-- /**************************** + EXPLORATORY DATA ANALYSIS + ****************************\

-- head
SELECT * FROM laptops 
ORDER BY `index` ASC LIMIT 5;

-- tail
SELECT * FROM laptops 
ORDER BY `index` DESC LIMIT 5;

-- RANDOM 5
SELECT * FROM laptops 
ORDER BY RAND() ASC LIMIT 5;

-- MEAN MEDIAN STD ETC 8 NUMBER SUMMARY 
SELECT Price, COUNT(Price) OVER(),
MIN(Price) OVER(),
MAX(Price) OVER(),
AVG(Price) OVER(),
STD(Price) OVER(),
(SELECT MAX(Q1) FROM
(SELECT 
CASE WHEN PERCENT_RANK() OVER(ORDER BY Price) > 0.24 AND PERCENT_RANK() OVER(ORDER BY Price) < 0.25  THEN  MAX(Price) OVER(ORDER BY Price) END AS  'Q1' FROM laptops)L1)  AS Q1,
(SELECT MAX(MEDIAN) FROM
(SELECT 
CASE WHEN PERCENT_RANK() OVER(ORDER BY Price) > 0.49 AND PERCENT_RANK() OVER(ORDER BY Price) < 0.50  THEN  MAX(Price) OVER(ORDER BY Price) END AS  'MEDIAN' FROM laptops)L1) AS MEDIAN,
(SELECT MAX(Q3) FROM
(SELECT 
CASE WHEN PERCENT_RANK() OVER(ORDER BY Price) > 0.74 AND PERCENT_RANK() OVER(ORDER BY Price) < 0.75  THEN  MAX(Price) OVER(ORDER BY Price) END AS  'Q3' FROM laptops)L1) AS Q3
FROM laptops
ORDER BY `index`LIMIT 1; 


SELECT Price, PERCENT_RANK() OVER(ORDER BY Price) FROM laptops;

-- MISSING VALUES IN PRICE
SELECT COUNT(*) FROM laptops WHERE Price IS NULL; 


-- OUTLIER IN PRICE
-- outliers
SELECT * FROM (SELECT *, 
(SELECT MAX(Q1)FROM
(SELECT 
CASE WHEN PERCENT_RANK() OVER(ORDER BY Price) > 0.24 AND PERCENT_RANK() OVER(ORDER BY Price) < 0.25  THEN  MAX(Price) OVER(ORDER BY Price) END AS  'Q1' FROM laptops)L1)  AS Q1 ,
(SELECT MAX(Q3) FROM
(SELECT 
CASE WHEN PERCENT_RANK() OVER(ORDER BY Price) > 0.74 AND PERCENT_RANK() OVER(ORDER BY Price) < 0.75  THEN  MAX(Price) OVER(ORDER BY Price) END AS  'Q3' FROM laptops)L1)  AS Q3
FROM laptops) t
WHERE t.Price < t.Q1 - (1.5*(t.Q3 - t.Q1)) OR
t.Price > t.Q3 + (1.5*(t.Q3 - t.Q1));  


-- /************************** HISTOGRAM IN SQL **************************/
SELECT t.buckets,REPEAT('*',COUNT(*)/5) FROM (SELECT price, 
CASE 
	WHEN price BETWEEN 0 AND 25000 THEN '0-25K'
    WHEN price BETWEEN 25001 AND 50000 THEN '25K-50K'
    WHEN price BETWEEN 50001 AND 75000 THEN '50K-75K'
    WHEN price BETWEEN 75001 AND 100000 THEN '75K-100K'
	ELSE '>100K'
END AS 'buckets'
FROM laptops) t
GROUP BY t.buckets; 
 
 -- vertical histogram
SELECT 
CASE WHEN t.`0-25K`/45 >= t.`index` THEN  "*" ELSE "" END AS "0-25K",
CASE WHEN t.`25K-50K`/45 >= t.`index` THEN  "*" ELSE "" END AS "25K-50K",
CASE WHEN t.`50K-75K`/45 >= t.`index` THEN  "*" ELSE "" END AS "50K-75K",
CASE WHEN t.`75K-100K`/45 >= t.`index` THEN  "*" ELSE "" END AS "75K-100K"
FROM (SELECT Price,`index`,
SUM(CASE WHEN price BETWEEN 0 AND 25000 THEN 1 ELSE 0 END) OVER() AS '0-25K',
SUM(CASE WHEN price BETWEEN 25001 AND 50000  THEN 1 ELSE 0 END) OVER() AS '25K-50K',
SUM(CASE WHEN price BETWEEN 50001 AND 75000 THEN 1 ELSE 0 END) OVER() AS '50K-75K',
SUM(CASE WHEN price BETWEEN 75001 AND 100000 THEN 1 ELSE 0 END) OVER() AS '75K-100K'
FROM laptops) t;


-- FREQUENCY OF CAT VARIABLE 
SELECT Company,COUNT(Company) AS "COUNT" FROM laptops
GROUP BY Company ORDER BY COUNT DESC; 



-- /************************** BI VARIATE ANALYSIS **************************/ 


-- BI VARIATE ANALYSIS 
-- CAT VS CAT, CONTENGENCY TABLE
SELECT Company,
SUM(CASE WHEN Touchscreen = 1 THEN 1 ELSE 0 END) AS 'Touchscreen_yes',
SUM(CASE WHEN Touchscreen = 0 THEN 1 ELSE 0 END) AS 'Touchscreen_no'
FROM laptops
GROUP BY Company;


-- COMPANY VS CPU BRAND

SELECT Company,
SUM(CASE WHEN cpu_brand = 'Intel' THEN 1 ELSE 0 END) AS 'intel',
SUM(CASE WHEN cpu_brand = 'AMD' THEN 1 ELSE 0 END) AS 'amd',
SUM(CASE WHEN cpu_brand = 'Samsung' THEN 1 ELSE 0 END) AS 'samsung'
FROM laptops
GROUP BY Company;


-- Categorical Numerical Bivariate analysis company and price  wala col
SELECT Company,MIN(price),
MAX(price),AVG(price),STD(price)
FROM laptops
GROUP BY Company;


-- Dealing with missing values

SELECT * FROM laptops
WHERE price IS NULL;

UPDATE laptops
SET price = NULL
WHERE `index` IN (7,869,1148,827,865,821,1056,1043,692,1114)


-- replace missing values with mean price of corresponding company + processor
UPDATE laptops l1
SET price = (SELECT Temp From 
			(SELECT AVG(price) AS Temp FROM laptops Where 
            Company = l1.Company AND cpu_name = l1.cpu_name)l2 )
WHERE price IS NULL;




-- Feature Engineering
ALTER TABLE laptops ADD COLUMN ppi INTEGER;

UPDATE laptops
SET ppi = ROUND(SQRT(res_width*res_width + res_height*res_height)/Inches);

SELECT * FROM laptops
ORDER BY ppi DESC;

ALTER TABLE laptops ADD COLUMN screen_size VARCHAR(255) AFTER Inches;


-- CONVERTING screen_size COL TO CATEGORICAL VARIABLE
UPDATE laptops
SET screen_size = 
CASE 
	WHEN Inches < 14.0 THEN 'small'
    WHEN Inches >= 14.0 AND Inches < 17.0 THEN 'medium'
	ELSE 'large'
END;


-- PRICE BASED ON screen size
SELECT screen_size,AVG(price) FROM laptops
GROUP BY screen_size;


-- One Hot Encoding
SELECT gpu_brand,
CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS 'intel',
CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS 'amd',
CASE WHEN gpu_brand = 'nvidia' THEN 1 ELSE 0 END AS 'nvidia',
CASE WHEN gpu_brand = 'arm' THEN 1 ELSE 0 END AS 'arm'
FROM laptops

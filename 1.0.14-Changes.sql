/*!50003 DROP PROCEDURE IF EXISTS `showAvailableFacilities` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `showAvailableFacilities`(IN v_sessionId VARCHAR(100),IN v_operation INT, IN v_fromDateTime TIMESTAMP, 
IN v_toDateTime TIMESTAMP, IN v_minCost DOUBLE, IN v_maxCost DOUBLE, IN v_maxCapacity INT, IN v_typeId INT, IN v_cityId INT, IN v_localityId INT, 
IN v_offers INT, IN v_amenity VARCHAR(50), IN v_pageNo INT, IN v_sortBy INT, IN v_orderBy INT, INOUT v_counting INT, OUT v_result INT)
BEGIN
    
/*v_operation = 1 -> Show Available Facilities for Consumer*/
/*v_operation = 2 -> Show all Facilities of SP*/
/*v_operation = 3 -> Getting Favorite Facilities of Consumer*/
/*v_operation = 4 -> Getting All the Facilities For Advisor*/

DECLARE p_fromDateTime TIMESTAMP;
DECLARE p_toDateTime TIMESTAMP;
DECLARE v_lowerBound INT;
DECLARE v_count INT;
DECLARE v_totalRecords INT;
DECLARE v_minCapacity INT;
DECLARE v_userType INT;
DECLARE v_fromTime TIME;
DECLARE v_toTime TIME;
DECLARE v_fromDay INT;
DECLARE v_toDay INT;
DECLARE v_Ids MEDIUMTEXT;

SET v_totalRecords = 0;
SET v_result = 0;
SET v_lowerBound = (v_pageNo - 1) * v_counting;

SET v_minCapacity = v_maxCapacity;
SET v_maxCapacity = v_minCapacity * 1.5;

SELECT userType INTO v_userType FROM user_pref WHERE sessionId = v_sessionId;
    IF(v_operation <> 1 AND v_userType IS NULL) THEN
		SET v_result = -1;
	ELSEIF(v_operation = 1)THEN
SELECT DATE_ADD(v_fromDateTime, INTERVAL 1 SECOND), DATE_SUB(v_toDateTime, INTERVAL 1 SECOND) INTO p_fromDateTime, p_toDateTime;

	SET @queryOne = "SELECT COUNT(DISTINCT f.id) INTO @v_totalRecords FROM huddil.facility f JOIN huddil.city c ON c.name = f.cityName JOIN huddil.locality l on l.name = f.localityName JOIN huddil.location lo on lo.id = f.locationId JOIN huddil.facility_type t ON t.name = f.typeName JOIN huddil.facility_photo p ON p.facilityId = f.id JOIN huddil.facility_amenity a ON a.facilityId = f.id _join";
    SET @query = "SELECT DISTINCT f.id, f.title, f.description,f.capacity, f.latitude, f.longtitude, f.costPerHour, f.costPerDay, f.costPerMonth, f.averageRating, f.size, f.status, f.contactNo, f.alternateContactNo, f.emailId, f.alternateEmailId, f.thumbnail, f.typeName, f.cityName as city, f.localityName as locality, lo.name as locationName, lo.landmark, lo.address, lo.nearBy, GROUP_CONCAT(DISTINCT a.amenityId) as Amenities, GROUP_CONCAT(DISTINCT p.imgPath) as imgPath FROM huddil.facility f JOIN huddil.city c ON c.name = f.cityName JOIN huddil.locality l on l.name = f.localityName JOIN huddil.location lo on lo.id = f.locationId JOIN huddil.facility_type t ON t.name = f.typeName JOIN huddil.facility_photo p ON p.facilityId = f.id JOIN huddil.facility_amenity a ON a.facilityId = f.id _join";
	
    IF(v_offers != 0)THEN
		SET @queryOne = REPLACE(@queryOne, ' _join','JOIN huddil.facility_offers o ON o.facilityId = f.id');
		SET @query = REPLACE(@query, ' _join','JOIN huddil.facility_offers o ON o.facilityId = f.id');
	ELSE
		SET @queryOne = REPLACE(@queryOne, ' _join', '');
		SET @query = REPLACE(@query, ' _join', '');
	END IF;
    
    IF(p_fromDateTime <> '' && p_toDateTime <> '')THEN	
		SET @queryOne = CONCAT(@queryOne, ' WHERE f.id NOT IN(SELECT b.facilityId FROM huddil.booking b WHERE (b.toTime >= \'',p_fromDateTime,'\'','  && b.fromTime <= \'',p_toDateTime,'\'',')) AND f.id NOT IN(SELECT m.facilityId FROM huddil.facility_under_maintenance m WHERE (m.toDateTime >= CAST(\'',p_fromDateTime,'\'',' AS DATE) && m.fromDateTime <= CAST(\'',p_toDateTime,'\'',' AS DATE)))');
		SET @query = CONCAT(@query, ' WHERE f.id NOT IN(SELECT b.facilityId FROM huddil.booking b WHERE (b.toTime >= \'',p_fromDateTime,'\'','  && b.fromTime <= \'',p_toDateTime,'\'',')) AND f.id NOT IN(SELECT m.facilityId FROM huddil.facility_under_maintenance m WHERE (m.toDateTime >= CAST(\'',p_fromDateTime,'\'',' AS DATE) && m.fromDateTime <= CAST(\'',p_toDateTime,'\'',' AS DATE)))');
	END IF;
    IF(v_cityId != 0 OR v_localityId != 0)THEN
		
		SET @queryOne = CONCAT(@queryOne, ' AND c.id = v_cityId');
		SET @query = CONCAT(@query, ' AND c.id = v_cityId');
	END IF;
    IF(v_localityId != 0)THEN
		
		SET @queryOne = CONCAT(@queryOne, ' AND l.id = v_localityId');
		SET @query = CONCAT(@query, ' AND l.id = v_localityId');
	END IF;
    
    IF(v_amenity = '')THEN
		
        SET @queryOne = CONCAT(@queryOne, ' ');
		SET @query = CONCAT(@query, ' ');
	ELSE
		SELECT (LENGTH(v_amenity) - LENGTH(REPLACE(v_amenity, ',', '')) + 1 ) INTO v_count;
        
        SET @queryOne = CONCAT(@queryOne, ' AND f.id IN (SELECT facilityId FROM huddil.facility_amenity WHERE amenityId IN(v_amenity) group by facilityId having count(facilityId) = v_count)');
		SET @query = CONCAT(@query, ' AND f.id IN (SELECT facilityId FROM huddil.facility_amenity WHERE amenityId IN(v_amenity) group by facilityId having count(facilityId) = v_count)');
	END IF;
    
    IF(v_maxCapacity !=0)THEN
    
		SET @queryOne = CONCAT(@queryOne, ' AND f.capacity BETWEEN v_minCapacity AND v_maxCapacity');
		SET @query = CONCAT(@query, ' AND f.capacity BETWEEN v_minCapacity AND v_maxCapacity');
	END IF;
	
    IF(v_maxCost !=0)THEN
    
		SET @queryOne = CONCAT(@queryOne, ' AND f.costPerDay BETWEEN v_minCost AND v_maxCost');
		SET @query = CONCAT(@query, ' AND f.costPerDay BETWEEN v_minCost AND v_maxCost');
	ELSEIF(v_minCost != 0) THEN
		SET @queryOne = CONCAT(@queryOne, ' AND f.costPerDay > v_minCost');
		SET @query = CONCAT(@query, ' AND f.costPerDay > v_minCost');
	END IF;
    
    IF(v_typeId !=0)THEN
    
		SET @queryOne = CONCAT(@queryOne, ' AND t.id = v_typeId');
		SET @query = CONCAT(@query, ' AND t.id = v_typeId');
        
    END IF;
    
    SET @queryOne = CONCAT(@queryOne, ' AND (f.status = 7 OR f.status = 8 OR f.status = 5)');
    SET @query = CONCAT(@query, ' AND (f.status = 7 OR f.status = 8 OR f.status = 5) GROUP by f.id order by condition LIMIT v_lowerBound, v_counting');
	
    IF(p_fromDateTime !=  '1970-11-01 00:00:02' && p_toDateTime != '1970-11-01 00:00:00')THEN
		
		SELECT TIME(v_fromDateTime), TIME(v_toDateTime) INTO v_fromTime, v_toTime;
		SELECT DAYOFWEEK(v_fromDateTime) INTO v_fromDay;
		SELECT DAYOFWEEK(v_toDateTime) INTO v_toDay;
				
        IF(v_fromDay = v_toDay)THEN
			
			SELECT GROUP_CONCAT(facilityId) INTO v_Ids FROM facility_timing t WHERE (t.closingTime >= v_toTime AND t.openingTime <= v_fromTime AND t.weekDay IN(v_fromDay));
            IF(v_Ids IS NULL) THEN
				SET v_Ids = 0;
			END IF;
			

		ELSE
			SELECT DISTINCT GROUP_CONCAT(facilityId) INTO v_Ids FROM (
				SELECT t.facilityId FROM facility_timing t WHERE 
				(t.openingTime <= v_fromTime AND t.closingTime >= v_fromTime AND t.weekDay IN (v_fromDay))) AS t1
				INNER JOIN (
				SELECT t.facilityId FROM facility_timing t WHERE
				(t.closingTime >= v_toTime AND t.openingTime <= v_toTime AND t.weekDay IN (v_toDay))) AS t2 USING(facilityId);
		END IF;	
        IF(v_Ids IS NOT NULL) THEN
			SET @query = REPLACE(@query, ' GROUP by f.id order by condition LIMIT v_lowerBound, v_counting', '');
			SET @query = CONCAT(@query, ' AND f.id IN (v_Ids) GROUP by f.id order by condition LIMIT v_lowerBound, v_counting');
			SET @queryOne = CONCAT(@queryOne, ' AND f.id IN (v_Ids)');
			SET @query = REPLACE(@query, 'v_Ids', v_Ids);
			SET @queryOne = REPLACE(@queryOne, 'v_Ids', v_Ids);
		END IF;
	END IF;
    
		
    IF(p_fromDateTime <> '' && p_toDateTime <> '')THEN
		
        SET @queryOne = REPLACE(@queryOne, 'p_fromDateTime', p_fromDateTime);
        SET @queryOne = REPLACE(@queryOne, 'p_toDateTime', p_toDateTime);
        
		SET @query = REPLACE(@query, 'p_fromDateTime', p_fromDateTime);
		SET @query = REPLACE(@query, 'p_toDateTime', p_toDateTime);
	END IF;
	
    IF(v_maxCost != 0)THEN
    
		SET @queryOne = REPLACE(@queryOne, 'v_minCost', v_minCost);
		SET @queryOne = REPLACE(@queryOne, 'v_maxCost', v_maxCost);
        
		SET @query = REPLACE(@query, 'v_minCost', v_minCost);
		SET @query = REPLACE(@query, 'v_maxCost', v_maxCost);
	ELSEIF(v_minCost != 0) THEN
		SET @queryOne = REPLACE(@queryOne, 'v_minCost', v_minCost);
		SET @query = REPLACE(@query, 'v_minCost', v_minCost);
	END IF;
    
    
	IF(v_sortBy = 0 && v_orderBy = 1) THEN
	  	 SET @query = REPLACE(@query, 'order by condition', 'order by f.averageRating asc');
	  ELSEIF(v_sortBy = 0 && v_orderBy = 0)THEN
	  	 SET @query = REPLACE(@query, 'order by condition', 'order by f.averageRating desc');
	END IF;
    
    IF(v_sortBy = 1 && v_orderBy = 1) THEN
       		SET @query = REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerHour !=0 GROUP by f.id order by f.costPerHour asc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerHour !=0');
		ELSEIF(v_sortBy = 2 && v_orderBy = 1)THEN
	   		SET @query = REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerDay !=0 GROUP by f.id order by f.costPerDay asc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerDay !=0');
		ELSEIF(v_sortBy =3 && v_orderBy = 1)THEN
			SET @query = REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerMonth !=0 GROUP by f.id order by f.costPerMonth asc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerMonth !=0');
		ELSEIF(v_sortBy = 1 && v_orderBy = 0)THEN
			SET @query = REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerHour !=0 GROUP by f.id order by f.costPerHour desc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerHour !=0');
		ELSEIF(v_sortBy = 2 && v_orderBy = 0)THEN
			SET @query= REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerDay !=0 GROUP by f.id order by f.costPerDay desc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerDay !=0');
		ELSEIF(v_sortBy = 3 && v_orderBy = 0)THEN
			SET @query = REPLACE(@query, 'GROUP by f.id order by condition', 'AND f.costPerMonth !=0 GROUP by f.id order by f.costPerMonth desc, f.averageRating desc');
            SET @queryOne = CONCAT(@queryOne, ' AND f.costPerMonth !=0');
		ELSE
			SET @query = REPLACE(@query, 'order by condition', 'order by f.averageRating desc');
		END IF;
	
		    
    SET @queryOne = REPLACE(@queryOne, 'v_minCapacity', v_minCapacity);
    SET @queryOne = REPLACE(@queryOne, 'v_maxCapacity', v_maxCapacity);
    SET @queryOne = REPLACE(@queryOne, 'v_cityId', v_cityId);
	SET @queryOne = REPLACE(@queryOne, 'v_localityId', v_localityId);
    
	SET @query = REPLACE(@query, 'v_minCapacity', v_minCapacity);
    SET @query = REPLACE(@query, 'v_maxCapacity', v_maxCapacity);
    SET @query = REPLACE(@query, 'v_cityId', v_cityId);
	SET @query = REPLACE(@query, 'v_localityId', v_localityId);

	SET @query = REPLACE(@query, 'v_counting', v_counting);
    
    IF(v_amenity <> '')THEN
		
        SET @queryOne = REPLACE(@queryOne, 'v_amenity', v_amenity);
		SET @queryOne = REPLACE(@queryOne, 'v_count', v_count);
        
		SET @query = REPLACE(@query, 'v_amenity', v_amenity);
		SET @query = REPLACE(@query, 'v_count', v_count);
	END IF;
    
    SET @queryOne = REPLACE(@queryOne, 'v_typeId', v_typeId);
    SET @query = REPLACE(@query, 'v_typeId', v_typeId);
    
    SET @query = REPLACE(@query, 'v_lowerBound', v_lowerBound);

	PREPARE stmt FROM @query;
    EXECUTE stmt;
	
    PREPARE stmt FROM @queryOne;
    EXECUTE stmt;
    SET v_counting = @v_totalRecords;
    


/*Facility Listing for Service Provider*/
ELSEIF(v_operation = 2)THEN
    
    SELECT DISTINCT f.id, f.spUserId, f.title, f.description,f.capacity, f.latitude, f.longtitude, f.costPerHour, f.costPerDay, 
	f.costPerMonth, f.averageRating, f.size, f.status, f.contactNo, f.alternateContactNo, f.emailId, f.alternateEmailId, f.thumbnail, f.typeName, f.cityName as city, 
	f.localityName as locality, lo.name as locationName, lo.landmark, lo.address, lo.nearBy, GROUP_CONCAT(DISTINCT am.id) as Amenities, 
	GROUP_CONCAT(DISTINCT ph.imgPath) as imgPath FROM huddil.facility f 
		JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
		JOIN huddil.facility_amenity a ON a.facilityId = f.id 
		JOIN huddil.amenity am ON am.id = a.amenityId 
		JOIN huddil.city c ON c.name = f.cityName 
		JOIN huddil.locality l ON l.name = f.localityName 
		JOIN huddil.location lo ON lo.id = f.locationId
		JOIN huddil.user_pref p ON p.userId = f.spUserId 
		WHERE p.sessionId = v_sessionId AND f.status > -1 group by f.id LIMIT v_lowerBound, v_counting;
        
        IF(v_pageNo = 1)THEN
			SELECT COUNT(DISTINCT f.id) INTO v_counting FROM huddil.facility f 
				JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
				JOIN huddil.facility_amenity a ON a.facilityId = f.id 
				JOIN huddil.amenity am ON am.id = a.amenityId 
				JOIN huddil.city c ON c.name = f.cityName 
				JOIN huddil.locality l ON l.name = f.localityName 
				JOIN huddil.location lo ON lo.id = f.locationId
				JOIN huddil.user_pref p ON p.userId = f.spUserId 
					WHERE p.sessionId = v_sessionId AND f.status >-1;
		END IF;

/*Favorites Facility Listing for Consumer*/
ELSEIF(v_operation = 3)THEN

	SELECT f.id, f.title, f.description, f.capacity, f.latitude, f.longtitude, f.costPerHour, f.costPerDay, 
    f.costPerMonth, f.averageRating, f.size, f.status, f.contactNo, f.alternateContactNo, f.emailId, f.alternateEmailId, f.thumbnail, f.typeName, f.cityName as city, 
    f.localityName as locality, lo.name as locationName, lo.landmark, lo.address, lo.nearBy, GROUP_CONCAT(DISTINCT am.id) as Amenities, 
    GROUP_CONCAT(DISTINCT ph.imgPath) as imgPath FROM huddil.facility f 
		JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
		JOIN huddil.facility_amenity a ON a.facilityId = f.id 
		JOIN huddil.amenity am ON am.id = a.amenityId 
		JOIN huddil.city c ON c.name = f.cityName 
		JOIN huddil.locality l ON l.name = f.localityName 
		JOIN huddil.location lo ON lo.id = f.locationId 
		RIGHT JOIN huddil.favorites fa ON fa.facilityId = f.id 
		JOIN huddil.user_pref p ON p.userId = fa.userId
			WHERE p.sessionId = v_sessionId AND f.status > -1 group by f.id LIMIT v_lowerBound, v_counting;
    
    IF(v_pageNo =1)THEN
		SELECT COUNT(DISTINCT f.id) INTO v_counting FROM huddil.facility f 
			JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
			JOIN huddil.facility_amenity a ON a.facilityId = f.id 
			JOIN huddil.amenity am ON am.id = a.amenityId 
			JOIN huddil.city c ON c.name = f.cityName 
			JOIN huddil.locality l ON l.name = f.localityName 
			JOIN huddil.location lo ON lo.id = f.locationId 
			RIGHT JOIN huddil.favorites fa ON fa.facilityId = f.id 
			JOIN huddil.user_pref p ON p.userId = fa.userId
				WHERE p.sessionId = v_sessionId AND f.status > -1;
	END IF;

/*Facility Listing for Advisor*/
ELSEIF(v_operation = 4)THEN
		
    SELECT f.id, f.title, f.description,f.capacity, f.latitude, f.longtitude, f.costPerHour, f.costPerDay, 
    f.costPerMonth, f.averageRating, f.size, f.status, f.contactNo, f.alternateContactNo, f.emailId, f.alternateEmailId, f.thumbnail, f.typeName, f.cityName as city, 
    f.localityName as locality, lo.name as locationName, lo.landmark, lo.address, lo.nearBy, GROUP_CONCAT(DISTINCT am.id) as Amenities, 
    GROUP_CONCAT(DISTINCT ph.imgPath) as imgPath FROM huddil.facility f 
		JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
		JOIN huddil.user_pref p 
		JOIN huddil.facility_amenity a ON a.facilityId = f.id 
		JOIN huddil.amenity am ON am.id = a.amenityId 
		JOIN huddil.city c ON c.name = f.cityName 
		JOIN huddil.locality l ON l.name = f.localityName 
		JOIN huddil.location lo ON lo.id = f.locationId 
					WHERE p.sessionId = v_sessionId AND (f.status = 1 OR f.status = 2 OR f.status = 5 OR f.status =6) group by f.id order by f.dateTime desc LIMIT v_lowerBound, v_counting;
    
    IF(v_pageNo = 1)THEN
		
		SELECT COUNT(DISTINCT f.id) INTO v_counting FROM huddil.facility f 
			JOIN huddil.facility_photo ph ON ph.facilityId = f.id 
			JOIN huddil.user_pref p 
			JOIN huddil.facility_amenity a ON a.facilityId = f.id 
			JOIN huddil.amenity am ON am.id = a.amenityId 
			JOIN huddil.city c ON c.name = f.cityName 
			JOIN huddil.locality l ON l.name = f.localityName 
			JOIN huddil.location lo ON lo.id = f.locationId 
						WHERE p.sessionId = v_sessionId AND (f.status = 1 OR f.status = 2 OR f.status = 5 OR f.status =6);
	END IF;
		
		END IF;
END;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `searchBooking` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `searchBooking`(IN p_bookingId INT, IN p_cityId INT, 
IN p_localityId INT, IN p_status INT, IN p_month INT, IN p_typeId INT, IN p_sessionId VARCHAR(128), OUT p_result INT)
BEGIN

DECLARE v_flag INT;
DECLARE p_userId INT;
DECLARE p_userType INT;

SELECT p.userId, p.userType INTO p_userId, p_userType FROM user_pref p WHERE p.sessionId = p_sessionId;

IF(p_userId IS NOT NULL)THEN
	IF(p_userType = 6 OR p_userType = 7)THEN
		
		IF(p_status = 1 OR p_status = 3)THEN
			
			SET @query ="SELECT DISTINCT b.id as bookingId, b.fromTime as bookedFrom, b.toTime as bookedTo, b.bookedTime, b.approvedTime, b.totalPrice, 
						b.paymentMethod, b.status, f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						booking b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.userId = p.userId _join WHERE b.id = p_bookingId AND f.spUserId = p_userId AND b.status <> 0 _add";
		ELSEIF(p_status = 2 OR p_status = 4)THEN
			
			SET @query = "SELECT DISTINCT b.bookingId, b.bookedFrom, b.bookedTo, b.bookedTime, b.approvedTime, b.totalPrice, 
						b.paymentMethod, IF(b.bookedStatus = 4, 4, 2) as status , f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						cancellation b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.bookedUserId = p.userId _join WHERE b.bookingId = p_bookingId AND f.spUserId = p_userId _add";
		ELSEIF(p_status = 5)THEN
			
			SET @query = "SELECT DISTINCT b.bookingId, b.fromDateTime as bookedFrom, b.toDateTime as bookedTo, b.bookedTime, b.approvedTime, b.price as totalPrice, 
						b.paymentMethod, 5 as status, f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						booking_history b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.userId = p.userId _join WHERE b.bookingId = p_bookingId AND f.spUserId = p_userId _add";
		ELSEIF(p_status = 0)THEN
			
			SET @query = "SELECT DISTINCT b.id as bookingId, b.fromTime as bookedFrom, b.toTime as bookedTo, b.bookedTime, b.approvedTime, b.totalPrice, 
						b.paymentMethod, b.status, f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						booking b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.userId = p.userId _join WHERE b.id = p_bookingId AND f.spUserId = p_userId AND b.status <> 0 _add1 UNION SELECT DISTINCT b.bookingId, b.bookedFrom, b.bookedTo, b.bookedTime, b.approvedTime, b.totalPrice, 
						b.paymentMethod, IF(b.bookedStatus = 4, 4, 2) as status , f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						cancellation b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.bookedUserId = p.userId _join WHERE b.bookingId = p_bookingId AND f.spUserId = p_userId _add2 UNION SELECT DISTINCT b.bookingId, b.fromDateTime as bookedFrom, b.toDateTime as bookedTo, b.bookedTime, b.approvedTime, b.price as totalPrice, 
						b.paymentMethod, 5 as status, f.title, f.typeName, lo.name, lo.address, p.displayName, p.emailId, p.mobileNo, b.seats FROM 
						booking_history b JOIN facility f ON f.id = b.facilityId JOIN location lo ON lo.id = f.locationId 
						JOIN user_pref p ON b.userId = p.userId _join WHERE b.bookingId = p_bookingId AND f.spUserId = p_userId _add3";
		END IF;
			IF(p_userType = 6)THEN
				SET @query = REPLACE(@query, ' AND f.spUserId = p_userId', '');
			END IF;
			IF(p_cityId <> 0)THEN
				SET @query = REPLACE(@query, '_join', 'JOIN city c ON c.name = f.cityName append');
				SET v_flag = 1;
			END IF;
			IF(p_localityId <> 0)THEN
				IF(v_flag = 1)THEN
					SET @query = REPLACE(@query, 'append', 'JOIN locality l ON l.name = f.localityName append');
				ELSE
					SET @query = REPLACE(@query, '_join', 'JOIN locality l ON l.name = f.localityName append');
					SET v_flag =1;
				END IF;
			END IF;
			IF(p_typeId <> 0)THEN
				IF(v_flag =1)THEN
					SET @query = REPLACE(@query, 'append', 'JOIN facility_type t ON t.name = f.typeName ');
				ELSE
					SET @query = REPLACE(@query, '_join', 'JOIN facility_type t ON t.name = f.typeName ');
					SET v_flag =1;
				END IF;
			END IF;
			IF(p_status = 1 OR p_status = 3)THEN
				SET @query = REPLACE(@query, 'b.status <> 0', 'b.status = p_status');
				SET @query = REPLACE(@query, 'p_status', p_status);
			END IF;
			IF(p_month <> 0 AND (p_status = 1 OR p_status =3))THEN
					SET @query = REPLACE(@query, '_add', 'AND month(b.bookedTime) = p_month');
				ELSEIF(p_month <> 0 AND (p_status = 5))THEN
					SET @query = REPLACE(@query, '_add', 'AND month(b.bookedTime) = p_month');
				ELSEIF(p_month <> 0 AND (p_status = 2 OR p_status = 4))THEN
					SET @query = REPLACE(@query, '_add', 'AND month(b.cancelledDateTime) = p_month');
				ELSEIF(p_month <> 0 AND p_status = 0)THEN
					SET @query = REPLACE(@query, '_add1', 'AND month(b.bookedTime) = p_month');
					SET @query = REPLACE(@query, '_add2', 'AND month(b.cancelledDateTime) = p_month');
					SET @query = REPLACE(@query, '_add3', 'AND month(b.bookedTime) = p_month');
				ELSEIF(p_month = 0 AND p_status = 0)THEN
					SET @query = REPLACE(@query, '_add1', '');
					SET @query = REPLACE(@query, '_add2', '');
					SET @query = REPLACE(@query, '_add3', '');
			END IF;
			IF(p_cityId = 0 AND p_localityId = 0 AND p_typeId =0)THEN
				SET @query = REPLACE(@query, '_join', '');
				SET @query = REPLACE(@query, '_add', '');
			END IF;		
			IF(p_cityId <> 0)THEN
				/*SET @query = REPLACE(@query, 'p_cityId', p_cityId);*/
				SET @query = REPLACE(@query, '_add', 'AND c.id= p_cityId _add');
				SET @query = REPLACE(@query, 'p_cityId', p_cityId);
			END IF;
			IF(p_localityId <> 0)THEN
				SET @query = REPLACE(@query, '_add', 'AND l.id = p_localityId _add');
				SET @query = REPLACE(@query, 'p_localityId', p_localityId);
			END IF;
			IF(p_bookingId <> 0)THEN
				SET @query = REPLACE(@query, 'p_bookingId', p_bookingId);
			END IF;
			IF(p_typeId <> 0)THEN
				SET @query = REPLACE(@query, '_add', 'AND t.id = p_typeId');
				SET @query = REPLACE(@query, 'p_typeId', p_typeId);
			END IF;
			IF(p_userId <> 0)THEN
				SET @query = REPLACE(@query, 'p_userId', p_userId);
			END IF;
			IF(p_month <> 0)THEN
				SET @query = REPLACE(@query, 'p_month', p_month);
			END IF;
		PREPARE stmt FROM @query;
		EXECUTE stmt;
		SET p_result = 1;
	ELSE
		SET p_result = -2;
	END IF;
ELSE
	SET p_result =-1;
END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `getBlockedTimings` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8 */ ;
/*!50003 SET character_set_results = utf8 */ ;
/*!50003 SET collation_connection  = utf8_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getBlockedTimings`(IN p_sessionId VARCHAR(128), IN p_status INT, IN p_fId INT, 
IN p_pageNo INT, INOUT p_count INT)
BEGIN

	DECLARE v_userType INT;
    DECLARE v_userId INT;
    DECLARE v_lowerBound INT;
    DECLARE v_totalRecords INT;
    
    SET v_totalRecords = 0;
	SET v_lowerBound = (P_pageNo - 1) * p_count;
    
	SELECT p.userType, p.userId INTO v_userType, v_userId FROM huddil.user_pref p WHERE p.sessionId = p_sessionId;
    
    IF(v_userId IS NULL) THEN
		SET p_count = -1;
    ELSEIF(v_userType <> (SELECT id FROM user_type WHERE name = 'Service Provider')) THEN
		SET p_count = -2;
	ELSE
		IF(p_status = 0) THEN
			SELECT DISTINCT b.id AS bookingId, b.fromTime AS bookedFrom, b.toTime AS bookedTo, b.bookedTime, b.totalPrice, '' AS paymentMethod, 
            b.status, '' AS title, '' AS typeName, '' AS name, '' AS address, '' AS displayName, '' AS emailId, '' AS mobileNo, b.seats 
            FROM huddil.booking b 
            JOIN huddil.facility f ON f.id = b.facilityId 
            JOIN huddil.user_pref p ON p.userId = f.spUserId AND b.userId = f.spUserId
            WHERE p.sessionId = p_sessionId AND f.id = p_fId LIMIT v_lowerBound, p_count;
            IF(p_pageNo = 1) THEN
				SELECT COUNT(DISTINCT b.id) INTO p_count FROM huddil.booking b 
				JOIN huddil.facility f ON f.id = b.facilityId 
				JOIN huddil.user_pref p ON p.userId = f.spUserId AND b.userId = f.spUserId
				WHERE p.sessionId = p_sessionId AND f.id = p_fId;
            END IF;
		ELSEIF(p_status = 1) THEN
			SELECT DISTINCT b.id AS bookingId, b.fromDateTime AS bookedFrom, b.toDateTime AS bookedTo, b.bookedTime, b.price, '' AS paymentMethod, 
            5 AS status, '' AS title, '' AS typeName, '' AS name, '' AS address, '' AS displayName, '' AS emailId, '' AS mobileNo, b.seats 
            FROM huddil.booking_history b 
            JOIN huddil.facility f ON f.id = b.facilityId 
            JOIN huddil.user_pref p ON p.userId = f.spUserId AND b.userId = f.spUserId
            WHERE p.sessionId = p_sessionId AND f.id = p_fId LIMIT v_lowerBound, p_count;
            IF(p_pageNo = 1) THEN
				SELECT COUNT(DISTINCT b.id) INTO p_count FROM huddil.booking_history b 
				JOIN huddil.facility f ON f.id = b.facilityId 
				JOIN huddil.user_pref p ON p.userId = f.spUserId AND b.userId = f.spUserId
                WHERE p.sessionId = p_sessionId AND f.id = p_fId LIMIT v_lowerBound, p_count;
            END If;
        END IF;
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
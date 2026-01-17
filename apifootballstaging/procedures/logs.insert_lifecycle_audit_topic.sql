DROP PROCEDURE IF EXISTS logs.insert_lifecycle_audit_topic;

/* 
	Wraps insert_lifestyle_audit so the procedure can be called with a specific topic
	
	History:
	1.00 - 17/01/2026 - NW - Created
*/

CREATE PROCEDURE logs.insert_lifecycle_audit_topic (
	 IN p_topic 					VARCHAR(50)
	,IN p_item_code					CHAR(3)
	,IN p_initiating_system_code	CHAR(10)
	,IN p_initiating_uid			UUID
	,IN p_uid						UUID
) LANGUAGE plpgsql
AS $body$
	DECLARE	v_lifecycle_code CHAR(6);
BEGIN
	/* Parameters checked by child proc with the exception of p_topic */
	IF COALESCE(p_topic, '') = '' THEN
		RAISE EXCEPTION 'logs.insert_lifecycle_audit_topic  - One or more required input parameters not set';
	END IF;
	/* Use the lookup to get the specific lifecycle */
	SELECT
		l.lifecycle_code
	INTO
		v_lifecycle_code
	FROM
				logs.lifecycle_topic t
	INNER JOIN	logs.lifecycle l
		ON t.lifecycle_id = l.lifecycle_id
	WHERE
		t.topic = p_topic
	AND t.is_active = true;

	IF v_lifecycle_code IS NULL THEN 
		RAISE EXCEPTION 'No rows returned for topic "%"', p_topic;
	END IF;

	CALL logs.insert_lifecycle_audit (v_lifecycle_code, p_item_code,p_initiating_system_code, p_initiating_uid, p_uid);

END $body$
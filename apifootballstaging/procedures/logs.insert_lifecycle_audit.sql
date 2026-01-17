DROP PROCEDURE IF EXISTS logs.insert_lifecycle_audit;

/*
	The lifecycle refers to what should be happening when an event triggers processing. It's not a validation
	of what's been produced, only that what should have happened has.

	History:
	1.00 - 17/01/2026 - Nick White - Created
*/

CREATE PROCEDURE logs.insert_lifecycle_audit (
	 p_lifecycle_code			CHAR(6)
	,p_item_code				CHAR(3)
	,p_initiating_system_code	CHAR(10)
	,p_initiating_uid			UUID
	,p_uid						UUID
) LANGUAGE plpgsql
AS $$
	DECLARE	v_system_code 		CHAR(10);
	 		v_lifecycle_id		INTEGER;
			v_lifecycle_item_id	INTEGER;
BEGIN
	/* Check input paramaters */
	IF COALESCE(p_lifecycle_code, '') = '' OR COALESCE(p_item_code,'') = '' OR COALESCE(p_initiating_system_code, '') = '' OR p_initiating_uid IS NULL or p_uid IS NULL THEN
		RAISE EXCEPTION 'One or more required input parameters not set';
	END IF;

	/* The system code will always be the calling system */
	SELECT
		CAST(v.value_str AS CHAR(10)) 
	INTO v_system_code
	FROM
				logs.config_item i 
	INNER JOIN	logs.config_value v
		ON i.config_item_id = v.config_item_id
	WHERE
		i.item_code = 'SYSCDE'
	AND i.is_active = True
	AND v.is_current = True;

	/* If the system code is null something has gone terribly wrong */
	IF COALESCE(v_system_code, '') = '' THEN
		RAISE EXCEPTION 'Unable to find system code';
	END IF;

	/* Set the lifecycle ID */
	SELECT
		l.lifecycle_id
	INTO
		v_lifecycle_id
	FROM
		logs.lifecycle l
	WHERE
		l.lifecycle_code = p_lifecycle_code;

	IF v_lifecycle_id IS NULL THEN
		RAISE EXCEPTION 'No valid record found in logs.lifecycle for lifecycle code "%"', p_lifecycle_code;
	END IF;

	/* Set the item ID */
	SELECT
		i.lifecycle_item_id
	INTO v_lifecycle_item_id
	FROM
		logs.lifecycle_item i
	WHERE
		i.lifecycle_id = v_lifecycle_id
	AND	i.item_code = p_item_code;

	IF v_lifecycle_item_id IS NULL THEN
		RAISE EXCEPTION 'No valid record found in logs.lifecycle_item for lifecycle_id "%" and item_code "%"', v_lifecycle_id, p_item_code;
	END IF;
	
	/* Finally insert the record */
	INSERT INTO logs.lifecycle_audit (
		 lifecycle_item_id
		,initiating_system_code
		,initiating_uid
		,system_code
		,uid
	) VALUES (
		 v_lifecycle_item_id
		,p_initiating_system_code
		,p_initiating_uid
		,v_system_code
		,p_uid
	);	
END $$;
DROP PROCEDURE IF EXISTS logs.update_process_log;

CREATE PROCEDURE logs.update_process_log (
	 IN p_process_uid	UUID
	,IN p_status		CHAR(3)
	,IN p_exception		VARCHAR(1000)
) LANGUAGE plpgsql
AS $$
	DECLARE	v_process_log_id	INTEGER;
			v_now_utc			TIMESTAMP = timezone('utc',now());
BEGIN
	IF p_process_uid IS NULL OR COALESCE(p_status, '') = '' THEN
		RAISE EXCEPTION 'One or more required input parameters not set';
	END IF;

	SELECT
		p.process_log_id
	INTO
		v_process_log_id
	FROM
		logs.process_log p
	WHERE
		p.process_uid = p_process_uid;

	UPDATE logs.process_log
		SET  updated_utc = v_now_utc
			,attempts = attempts + 1
			,status = CASE WHEN p_status = 'FAI' AND attempts + 1 <  attempts_max 	THEN 'PEN'
				  		   WHEN p_status = 'FAI' AND attempts + 1 >= attempts_max 	THEN 'FAI' 
				  														  			ELSE p_status
			 		   END
			,delay_utc = CASE WHEN p_status = 'FAI' AND attempts + 1 < attempts_max THEN v_now_utc + make_interval(secs >= delay_secs) ELSE delay_utc END
	WHERE
		process_log_id = v_process_log_id;

END $$;
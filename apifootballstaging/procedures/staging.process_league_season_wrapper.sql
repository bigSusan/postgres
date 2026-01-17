DROP PROCEDURE IF EXISTS staging.process_league_season_wrapper;

/*
	

*/

CREATE PROCEDURE staging.process_league_season_wrapper (
	 IN p_event_input_id 	INTEGER
	,IN p_league_id			INTEGER
	,IN p_payload 			JSON
) LANGUAGE plpgsql
AS $body$
	DECLARE v_process_uid 		UUID = gen_random_uuid();
			v_event_trigger_in 	VARCHAR(50) = 'apisplit-football-league-season';
			v_event_uid 		UUID;
			v_system_code		CHAR(10);
			v_now_utc			TIMESTAMP = timezone('utc',now());
BEGIN
	/* Check inputs */
	IF p_event_input_id IS NULL OR p_league_id IS NULL OR p_payload IS NULL THEN
		RAISE EXCEPTION 'staging.process_league_season_wrapper - One or more required input parameters not set';
	END IF;

	/* Retrieve the event input uid so it's common across these child events */
	SELECT
		event_uid
	INTO v_event_uid
	FROM
		logs.event_input e
	WHERE
		event_input_id = p_event_input_id;

	/* Check to ensure a valid event input has been passed */
	IF v_event_uid IS NULL THEN
		RAISE EXCEPTION 'No data returned from logs.event_input for event_input_id "%"', p_event_input_id;
	END IF;

	/* Although the event itself is from an upstream system this is generated here */
	v_system_code = logs.get_system_code(); /* Throws its own null exception */

	/* Insert the child event */
	CALL logs.insert_event_input (v_system_code,v_event_uid, v_process_uid, v_event_trigger_in, v_now_utc, p_payload);

	/* Attempt to process once */
	CALL logs.process_league_season (p_league_id, v_process_uid);

END $body$;
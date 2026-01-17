DROP PROCEDURE IF EXISTS logs.insert_event_input;

/*
	Aside from scheduled batch processes real time processing in apifootballstaging is triggered by events, i.e
	a message is received by an application which then inserts into the postgres database with everything needed
	to process the data. The use of 'topic' and 'event_trigger' is interchangeable here since a message topic may
	simply insert some data into a table or as is in this case trigger some processing action.
	
	History:
	1.00 - 17/01/2026 - NW - Created

*/

CREATE PROCEDURE logs.insert_event_input (
	,IN p_event_uid 			UUID
	,IN p_process_uid			UUID /* Nullable but needs to be passed as a message will trigger processing in some cases */
	,IN p_topic					VARCHAR(50)
	,IN p_event_utc				TIMESTAMP
	,IN p_payload				JSON
) LANGUAGE plpgsql
AS $BODY$
	DECLARE	v_process_id 				INTEGER;
			v_process_max_attempts		INTEGER;
			v_process_code				CHAR(10);
			v_event_trigger_out			VARCHAR(50); /* Typically the topic of the message the process will trigger */
			v_event_input_id			INTEGER;
			v_now_utc					TIMESTAMP = timezone('utc',now());
			v_row_count					INTEGER;
			v_initiating_system_code	CHAR(10);
			v_processing_proc			VARCHAR(50);
			v_delay_secs				INTEGER;
			
BEGIN
	/* Check input parameters */
	IF COALESCE(p_source_system_code, '') = '' OR p_event_uid IS NULL OR COALESCE(p_topic, '') = '' OR p_event_utc IS NULL OR p_payload IS NULL THEN
		RAISE EXCEPTION 'One or more required input parameters not set';
	END IF;

	/* The minimum viable action is just to log the event */
	INSERT INTO logs.event_input (
		 source_system_code
		,event_uid
		,topic
		,event_utc
		,payload
	) VALUES (
		 p_source_system_code
		,p_event_uid
		,p_topic
		,p_event_utc
		,p_payload
	) RETURNING event_input_id INTO v_event_input_id;

	/* The event input may trigger a process log event in which case it needs to  */
	IF p_process_uid IS NOT NULL THEN
		/* Set the initiating system code which for all processing events is this */
		v_initiating_system_code = logs.get_system_code(); /* throws its own null exception */

		/* Insert a lifecycle audit */
		CALL logs.insert_lifecycle_audit_topic (p_topic, 'RPR'::CHAR(3), v_initiating_system_code, p_event_uid, p_process_uid);
		
		/* Confugrable process set by the topic of the event input */
		SELECT
			p.process_id, p.max_attempts, p.process_code, p.event_trigger_out, p.max_attempts, p.processing_proc, p.delay_secs
		INTO v_process_id, v_process_max_attempts, v_process_code, v_event_trigger_out, v_process_max_attempts, v_processing_proc, v_delay_secs
		FROM
			logs.process p
		WHERE
			p.event_trigger_in = p_topic
		AND p.is_active = True
		AND p.is_current = True;

		GET DIAGNOSTICS v_row_count = ROW_COUNT;

		IF v_row_count = 0 THEN
			RAISE EXCEPTION 'No data returned from logs.process for topic "%"', p_topic;
		END IF;

		/* Finally insert a process log record */
		INSERT INTO logs.process_log (
			 process_uid
			,event_input_id
			,process_id
			,process_code
			,triggered_on
			,event_trigger_out
			,processing_proc
			,attempts
			,attempts_max
			,delay_secs
			,delay_utc
			,status
		) VALUES (
			 p_process_uid
			,v_event_input_id
			,v_process_id
			,v_process_code
			,'E'
			,v_event_trigger_out
			,v_processing_proc
			,0
			,v_process_max_attempts
			,v_delay_secs
			,v_now_utc
			,'PEN'
		);
	END IF;

END $BODY$
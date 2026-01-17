DROP PROCEDURE IF EXISTS logs.insert_event_output;

/*	
	The database recieves input events which trigger some kind of processing action. This may result in output events. These
	are really just messages to be picked up by another process and sent to a message broker.
	
	History:
	1.00 - 17/01/2026 - Nick White - Created
	
*/

CREATE PROCEDURE logs.insert_event_output (
	 IN p_source_table		VARCHAR(50)
	,IN p_source_id 		INTEGER
	,IN p_topic				VARCHAR(50)
	,IN p_event_utc			TIMESTAMP /* Nullable as it will default if null */
	,IN p_delay_utc			TIMESTAMP /* It's possible to delay when the event will be polled by the producer */
	,IN p_payload			JSON /* It's up to the calling proc to create this */
	,IN p_initiating_uid	UUID /* Required to log process lifecycle records */
	,OUT p_event_output_id INTEGER
) LANGUAGE plpgsql
AS $$
	DECLARE	v_system_code 	CHAR(10);
			v_event_uid		UUID = gen_random_uuid();
			v_payload		JSON;
BEGIN
	/* Check input parameters */
	IF COALESCE(p_source_table, '') = '' OR p_source_id IS NULL OR COALESCE(p_topic, '') = '' THEN
		RAISE EXCEPTION 'logs.insert_event_output - One or more required input parameters not set';
	END IF;

	v_system_code = logs.get_system_code(); /* throws its own null exception */

	/* Insert a lifecycle audit */
	CALL logs.insert_lifecycle_audit_topic (p_topic, 'EVO'::CHAR(3), v_system_code, p_initiating_uid, v_event_uid);

	/* Apply all the metadata created her to a json object and append the payload */
	v_payload = JSON_BUILD_OBJECT (
		 'sourceSystem', v_system_code
		,'eventUid', v_event_uid
		,'eventUtc', p_event_utc
		,'topic', p_topic
		,'body', p_payload
	);

	/* Insert the event output so it can be picked up for production */
	INSERT INTO logs.event_output (
		 source_table
		,source_id
		,system_code
		,event_uid
		,topic
		,event_utc
		,delay_utc
		,payload
	) VALUES (
		 p_source_table
		,p_source_id
		,v_system_code
		,v_event_uid
		,p_topic
		,p_event_utc
		,p_delay_utc
		,v_payload
	) RETURNING event_output_id INTO p_event_output_id;
END $$;
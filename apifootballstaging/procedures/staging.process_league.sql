DROP PROCEDURE IF EXISTS staging.process_league;

/*
	Picks up the json associated with an api football league call and determines if it needs to 
	be sent up stream for processing. Splits out league season records into a separate process
	as these have their own event output topic.

	History:
	1.00 - 17/01/2026 - Nick White - Created
*/

CREATE PROCEDURE staging.process_league (
	IN p_process_uid	UUID
) LANGUAGE plpgsql
AS $body$
	DECLARE	v_payload 			JSON;
			v_process_log_id	INTEGER;
			v_process_id		INTEGER;
			v_event_trigger_out	VARCHAR(50);
			v_event_input_id	INTEGER;
			v_event_output_id	INTEGER;
			v_ins_eveo			BOOLEAN;
			v_now_utc			TIMESTAMP = timezone('utc', now());
			v_staging_id		INTEGER;
			v_row_hash			VARCHAR(32);
			v_id				INTEGER;
			v_name				VARCHAR(50);
			v_type				VARCHAR(20);
			v_logo				VARCHAR(200);
			v_country			VARCHAR(50);
			v_seasons			JSON;
			
BEGIN
	/* There is something wrong with the calling app if null so fail */
	IF p_process_uid IS NULL THEN
		RAISE EXCEPTION 'staging.process_league - One or more required input parameters not set';
	END IF;

	SELECT 
		p.process_log_id, p.event_input_id, p.process_id
	INTO v_process_log_id, v_event_input_id, v_process_id
	FROM 
		logs.process_log p
	WHERE
		process_uid = p_process_uid;

	/* Again there is something wrong with the calling app if null so fail if an invalud uid is passed */
	IF v_process_log_id IS NULL THEN
		RAISE EXCEPTION 'No rows returned from logs.process_log for process_uid "%"', p_process_uid;
	END IF;

	/* This process is triggered by an event and itself should trigger an event */
	SELECT
		p.event_trigger_out
	INTO v_event_trigger_out
	FROM
		logs.process p
	WHERE
		p.process_id = v_process_id;
		
	/* Purely a safety measure, should never hit this point as the transaction rolled back on exception */
	DELETE FROM staging.league
	WHERE
		process_log_id = v_process_log_id;

	/* The CTE is here to making hashing the row more convenient */
	WITH a (id, name, type, logo, country, seasons) AS (
		SELECT
			  CAST(response->'league'->>'id' AS INT)
			 ,CAST(response->'league'->>'name' AS VARCHAR(50))
			 ,CAST(response->'league'->>'type' AS VARCHAR(20))
			 ,CAST(response->'league'->>'logo' AS VARCHAR(200))
			 ,CAST(response->'country'->>'name' AS VARCHAR(50))
			 ,CAST(response->>'seasons' AS JSON)
		FROM
			logs.event_input e, LATERAL jsonb_array_elements(e.payload::JSONB->'response') AS response 
		WHERE
			e.event_input_id = v_event_input_id
	)
	INSERT INTO staging.league (
		 process_log_id
		,row_hash
		,id
		,name
		,type
		,logo
		,country
		,seasons
	)
	SELECT
		 v_process_log_id
		,md5(row(a.id,a.name,a.type,a.logo,a.country,a.seasons)::TEXT)
		,a.id
		,a.name
		,a.type
		,a.logo
		,a.country
		,a.seasons
	FROM
		a;

	/* I can't see any other way other than to do this in a loop */
	WHILE true
	LOOP
		/* Reset variable in each iteration of loop */
		v_staging_id = NULL;

		SELECT
			s.staging_id, s.row_hash, s.id, s.name, s.type, s.logo, s.country, s.seasons
		INTO
			v_staging_id, v_row_hash, v_id, v_name, v_type, v_logo, v_country, v_seasons
		FROM
			staging.league s
		WHERE
			s.process_log_id = v_process_log_id
		AND s.is_processed = false;

		/* Assume all the imported records have been processed */
		IF v_staging_id IS NULL THEN
			EXIT;
		END IF;

		/* First of all if there's something to process assume there's at least on season record 
		and pass it to the wrapper procedure for league season. This will attempt to process the 
		league season record and create an event output where necessary. */
		CALL staging.process_league_season_wrapper (v_event_input_id, v_id, v_seasons); /* Should fail gracefully then send for retry after the seasons staging data is inserted */

		/* The roll of this is to check a record in its current state has been sent upstream not to determine if 
		an upstream change needs to be made. So just compare on the row hash. */
		IF NOT EXISTS (SELECT 1 FROM staging.league_current c WHERE row_hash = v_row_hash LIMIT 1) THEN 
			INSERT INTO staging.league_current (
				 staging_id
				,row_hash
				,id
				,name
				,type
				,logo
				,country
			) VALUES (
				 v_staging_id
				,v_row_hash
				,v_id
				,v_name
				,v_type
				,v_logo
				,v_country
			);
			/* It doesn't exist so assume there needs to be a message sent ustream */
			v_payload = JSON_BUILD_OBJECT (
				'competition_id', v_id, 'competition_name', v_name, 'competition_type', v_type, 'competition_logo', v_logo, 'competition_country', v_country
			);
			/* Call event output proc */
			CALL logs.insert_event_output ('staging.league', v_staging_id, v_event_trigger_out, v_now_utc, v_now_utc, v_payload, p_process_uid, v_event_output_id);
			/* To audit where staging records have created events */
			UPDATE staging.league
				SET  updated_utc = v_now_utc
					,event_output_id = v_event_output_id
			WHERE
				staging_id = v_staging_id;
		END IF;

		/* Update here to ensure there's no infinite loop */
		UPDATE staging.league
			SET  updated_utc = v_now_utc
				,is_processed = true
		WHERE
			staging_id = v_staging_id;
	END LOOP;

	/* At this point everything that needs processing should have been processed so assume success */
	CALL logs.update_process_log (p_process_uid, 'COM', null);

	/* Gracefully handle exceptions so the calling app continues processing, not bothered about ordering
	   that should be dealt with upstream. */
	EXCEPTION WHEN others THEN
		CALL logs.update_process_log (p_process_uid, 'FAI', SQLERRM); /* Needs improving at some point */
		/* Raise a notice */
		RAISE NOTICE '%', SQLERRM;
	
END $body$;
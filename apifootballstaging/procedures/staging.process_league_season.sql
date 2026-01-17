DROP PROCEDURE IF EXISTS staging.process_league_season;

CREATE PROCEDURE staging.process_league_season (
	 p_process_uid	UUID 
	,p_league_id	INTEGER
) LANGUAGE plpgsql
AS $body$
	DECLARE v_payload 								JSON;
			v_process_log_id						INTEGER;
			v_process_id							INTEGER;
			v_event_trigger_out						VARCHAR(50);
			v_event_input_id						INTEGER;
			v_event_output_id						INTEGER;
			v_now_utc								TIMESTAMP = timezone('utc', now());
			v_staging_id							INTEGER;
			v_row_hash								VARCHAR(32);
			v_year									INTEGER;
			v_start_date							DATE;
			v_end_date								DATE;
			v_current								BOOLEAN;
			v_coverage_fixtures_events				BOOLEAN;
			v_coverage_fixtures_lineups				BOOLEAN;
			v_coverage_fixtures_statistics_fixtures BOOLEAN;
			v_coverage_fixtures_statistics_players	BOOLEAN;
			v_coverage_standings					BOOLEAN;
			v_coverage_players						BOOLEAN;
			v_coverage_top_scorers					BOOLEAN;
			v_coverage_top_assists					BOOLEAN;
			v_coverage_top_cards					BOOLEAN;
			v_coverage_injuries						BOOLEAN;
			v_coverage_predictions					BOOLEAN;
			v_coverage_odds							BOOLEAN;
BEGIN
	/* There is something wrong with the calling app if null so fail */
	IF p_process_uid IS NULL THEN
		RAISE EXCEPTION 'staging.process_league_season - One or more required input parameters not set';
	END IF;

	/* Since a UID is being passed retrieve the basic parameters required for processing here */
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

	/* Purely a safety measure, should never hit this point as the transaction rolled back on exception */
	DELETE FROM staging.league_season
	WHERE
		process_log_id = v_process_log_id;

	WITH a (year,start_date,end_date,current,coverage_fixtures_events,coverage_fixtures_lineups,coverage_fixtures_statistics_fixtures, coverage_fixtures_statistics_players,coverage_standings,coverage_players,coverage_top_scorers,coverage_top_assists, coverage_top_cards,coverage_injuries,coverage_predictions,coverage_odds) AS (
		SELECT
			 CAST(season->>'year' AS INTEGER)
			,CAST(season->>'start' AS DATE)
			,CAST(season->>'end' AS DATE)
			,CAST(season->>'current' AS BOOLEAN)
			,CAST(season->'coverage'->'fixtures'->>'events' AS BOOLEAN)
			,CAST(season->'coverage'->'fixtures'->>'lineups' AS BOOLEAN)
			,CAST(season->'coverage'->'fixtures'->>'statistics_fixtures' AS BOOLEAN)
			,CAST(season->'coverage'->'fixtures'->>'statistics_players' AS BOOLEAN)
			,CAST(season->'coverage'->>'standings' AS BOOLEAN)
			,CAST(season->'coverage'->>'players' AS BOOLEAN)
			,CAST(season->'coverage'->>'top_scorers' AS BOOLEAN)
			,CAST(season->'coverage'->>'top_assists' AS BOOLEAN)
			,CAST(season->'coverage'->>'top_cards' AS BOOLEAN)
			,CAST(season->'coverage'->>'injuries' AS BOOLEAN)
			,CAST(season->'coverage'->>'predictions' AS BOOLEAN)
			,CAST(season->'coverage'->>'odds' AS BOOLEAN)
			
		FROM
			logs.event_input e, LATERAL jsonb_array_elements(e.payload::JSONB) AS season 
		WHERE
			e.event_input_id = v_event_input_id
	)
	INSERT INTO staging.league_season (
		 process_log_id
		,row_hash
		,league_id
		,year
		,start_date
		,end_date
		,current
		,coverage_fixtures_events
		,coverage_fixtures_lineups
		,coverage_fixtures_statistics_fixtures
		,coverage_fixtures_statistics_players
		,coverage_standings
		,coverage_players
		,coverage_top_scorers
		,coverage_top_assists
		,coverage_top_cards
		,coverage_injuries
		,coverage_predictions
		,coverage_odds
	)
	SELECT
		 v_process_log_id
		,md5(row(p_league_id,a.year,a.start_date,a.end_date,a.current,a.coverage_fixtures_events,a.coverage_fixtures_lineups,a.coverage_fixtures_statistics_fixtures,a.coverage_fixtures_statistics_players, a.coverage_standings,a.coverage_players,a.coverage_top_scorers,a.coverage_top_assists, a.coverage_top_cards,a.coverage_injuries,a.coverage_predictions,a.coverage_odds)::TEXT)
		,p_league_id
		,year
		,start_date
		,end_date
		,current
		,coverage_fixtures_events
		,coverage_fixtures_lineups
		,coverage_fixtures_statistics_fixtures
		,coverage_fixtures_statistics_players
		,coverage_standings
		,coverage_players
		,coverage_top_scorers
		,coverage_top_assists
		,coverage_top_cards
		,coverage_injuries
		,coverage_predictions
		,coverage_odds
	FROM
		a;

	WHILE true
	LOOP
		/* Reset variable in each iteration of loop */
		v_staging_id = NULL;

		SELECT
			s.staging_id, s.row_hash, s.league_id, s.year, s.start_date, s.end_date, s.current, s.coverage_fixtures_events,s.coverage_fixtures_lineups,s.coverage_fixtures_statistics_fixtures, s.coverage_fixtures_statistics_players, s.coverage_standings, s.coverage_players, s.coverage_top_scorers, s.coverage_top_assists, s.coverage_top_cards, s.coverage_injuries, s.coverage_predictions, s.coverage_odds
		INTO
			v_staging_id, v_row_hash, p_league_id, v_year, v_start_date, v_end_date, v_current, v_coverage_fixtures_events, v_coverage_fixtures_lineups, v_coverage_fixtures_statistics_fixtures, v_coverage_fixtures_statistics_players, v_coverage_standings, v_coverage_players, v_coverage_top_scorers, v_coverage_top_assists, v_coverage_top_cards, v_coverage_injuries, v_coverage_predictions, v_coverage_odds
		FROM
			staging.league_season s
		WHERE
			s.process_log_id = v_process_log_id
		AND s.is_processed = false;

		/* Assume all the imported records have been processed */
		IF v_staging_id IS NULL THEN
			EXIT;
		END IF;

		/* Since the purpose here is to find out if the data in its current form has been sent upstream compare by row_hash */
		IF NOT EXISTS (SELECT 1 FROM staging.league_season_current c WHERE row_hash = v_row_hash LIMIT 1) THEN
			INSERT INTO staging.league_season_current (
				 row_hash
				,league_id
				,year
				,start_date
				,end_date
				,current
				,coverage_fixtures_events
				,coverage_fixtures_lineups
				,coverage_fixtures_statistics_fixtures
				,coverage_fixtures_statistics_players
				,coverage_standings
				,coverage_players
				,coverage_top_scorers
				,coverage_top_assists
				,coverage_top_cards
				,coverage_injuries
				,coverage_predictions
				,coverage_odds
			) VALUES (
				 v_row_hash
				,p_league_id
				,v_year
				,v_start_date
				,v_end_date
				,v_current
				,v_coverage_fixtures_events
				,v_coverage_fixtures_lineups
				,v_coverage_fixtures_statistics_fixtures
				,v_coverage_fixtures_statistics_players
				,v_coverage_standings
				,v_coverage_players
				,v_coverage_top_scorers
				,v_coverage_top_assists
				,v_coverage_top_cards
				,v_coverage_injuries
				,v_coverage_predictions
				,v_coverage_odds
			);
			/* Since this has yet to be sent create an event output */
			v_payload = JSON_BUILD_OBJECT (
				'league_id', p_league_id,
				'year', v_year,
				'start_date', v_start_date,
				'end_date', v_end_date,
				'current', v_current,
				'coverage', JSON_BUILD_OBJECT (
					'fixtures_events', v_coverage_fixtures_events,
					'fixtures_lineups', v_coverage_fixtures_lineups,
					'fixtures_statistics_fixtures', v_coverage_fixtures_statistics_fixtures,
					'fixtures_statistics_players', v_coverage_fixtures_statistics_players,
					'standings', v_coverage_standings,
					'players', v_coverage_players,
					'top_scorers', v_coverage_top_scorers,
					'top_assists', v_coverage_top_assists,
					'top_cards', v_coverage_top_cards,
					'injuries', v_coverage_injuries,
					'predictions', v_coverage_predictions,
					'odds', v_coverage_odds
				)
			);
			/* It now needs the event output */
			CALL logs.insert_event_output ('staging.league', v_staging_id, v_event_trigger_out, v_now_utc, v_now_utc, v_payload, p_process_uid, v_event_output_id);
			/* To audit where staging records have created events */
			UPDATE staging.league
				SET  updated_utc = v_now_utc
					,event_output_id = v_event_output_id
			WHERE
				staging_id = v_staging_id;
		END IF;

		/* Update to prevent infinite loop */
		UPDATE staging.league_season
			SET  updated_utc = v_now_utc
				,event_output_id = v_event_output_id
				,is_processed = true
		WHERE
			staging_id = v_staging_id;

	END LOOP;

	/* At this point everything that needs processing should have been processed so assume success */
	CALL logs.update_process_log (p_process_uid, 'COM', null);

	EXCEPTION WHEN others THEN
		CALL logs.update_process_log (p_process_uid, 'FAI', SQLERRM); /* Needs improving at some point */
		/* Raise a notice */
		RAISE NOTICE '%', SQLERRM;


END $body$;


DO $$
	DECLARE v_from_utc 	TIMESTAMP = timezone('utc',now());
			v_to_utc	TIMESTAMP = '9999-12-31 23:59:59';
BEGIN

	TRUNCATE TABLE logs.process;
	
	INSERT INTO logs.process (
		 process_code
		,process_name
		,triggered_on
		,event_trigger_in
		,event_trigger_out
		,processing_proc
		,max_attempts
		,delay_secs
		,from_utc
		,to_utc
		,is_current
		,is_active
	) VALUES ('PAPCFTBRND','Process Api Call Football Round', 'E', 'apisource-football-round', 'pre-processing-football-round', 'staing.process_round', 3, 30, v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBFIX','Process Api Call Football Fixture', 'E', 'apisource-football-fixture','pre-processing-football-fixture', 'staging.process_fixture', 3, 30, v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBFXE','Process Api Call Fixture Event', 'E', 'apisource-football-fixture-event', 'pre-processing-football-fixture-event', 'staging.process_fixture_event', 3, 30, v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBLGE','Process Api Call Football League', 'E', 'apisource-football-league','pre-processing-football-league', 'staging.process_league', 3, 30, v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBPLY','Process Api Call Football Player', 'E', 'apisource-football-player','pre-processing-football-player', 'staging.process_player', 3, 30, v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBTRN','Process Api Call Football Transfer', 'E', 'apisource-football-transfer','pre-processing-football-transfer','staging.process_transfer',3,30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBVEN','Process Api Call Football Venue','E','apisource-football-venue','pre-processing-football-venue','staging.process_venue',3,30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBTEM','Process Api Call Football Team', 'E','apisource-football-team', 'pre-processing-football-team','staging.process_team', 3, 30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBSQD','Process Api Call Football Squad', 'E', 'apisource-football-squad','pr-processing-football-squad','staging.process_squad', 3, 30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBSID','Process Api Call Football Sidelined', 'E', 'apisource-football-sidelined','pre-processing-football-sidelined','staging.process_sidelined',3, 30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBCCH','Process Api Call Football Coach', 'E', 'apisource-football-coach','pre-processing-football-coach','staging.process_coach', 3, 30,v_from_utc, v_to_utc, True, True),
			 ('PAPCFTBINJ','Process Api Call Football Injury','E','apisource-football-injury','pre-processing-football-injury','staging.process_injury',3, 30,v_from_utc, v_to_utc, True, True);

	TRUNCATE TABLE logs.lifecycle;

	INSERT INTO logs.lifecycle (
		 lifecycle_code
		,lifecycle_name
	) VALUES ('FTBRND', 'Football Round'),
			 ('FTBFIX', 'Football Fixture'),
			 ('FTBFXE', 'Football Fixture Event'),
			 ('FTBLGE', 'Football League'),
			 ('FTBPLY', 'Football Player'),
			 ('FTBTRN', 'Football Transfer'),
			 ('FTBVEN', 'Football Venue'),
			 ('FTBTEM', 'Football Team'),
			 ('FTBSQD', 'Football Squad'),
			 ('FTBSID', 'Football Sidelined'),
			 ('FTBCCH', 'Football Coach'),
			 ('FTBINJ', 'Football Injury');

	TRUNCATE TABLE logs.lifecycle_item;

	WITH a (item_code,required) AS (
		SELECT 'EVI', true  UNION ALL /* Event in */
		SELECT 'RPR', true  UNION ALL /* Record processing */
		SELECT 'PRS', false UNION ALL /* Processing success */
		SELECT 'PRF', false UNION ALL /* Processing failure */
		SELECT 'EVO', true /* Processing failure */ 
	)
	INSERT INTO logs.lifecycle_item (
		 lifecycle_id
		,item_code
		,required
	)
	SELECT
		 l.lifecycle_id
		,a.item_code
		,a.required
	FROM
		logs.lifecycle l CROSS JOIN a;

	TRUNCATE TABLE logs.lifecycle_topic;

	WITH a (lifecycle_code, topic) AS (
		SELECT 'FTBRND', 'apisource-football-round'   UNION ALL
		SELECT 'FTBRND', 'pre-processing-football-round' UNION ALL
		SELECT 'FTBFIX', 'apisource-football-fixture' UNION ALL
		SELECT 'FTBVEN', 'apisource-football-venue' UNION ALL
		SELECT 'FTBVEN', 'pre-processing-football-venue' UNION ALL
		SELECT 'FTBTRN', 'apisource-football-transfer' UNION ALL
		SELECT 'FTBTRN', 'pre-processing-football-transfer' UNION ALL
		SELECT 'FTBTEM', 'apisource-football-team' UNION ALL
		SELECT 'FTBTEM', 'pre-processing-football-team' UNION ALL
		SELECT 'FTBSQD', 'apisource-football-squad' UNION ALL
		SELECT 'FTBSQD', 'pre-processing-football-squad' UNION ALL
		SELECT 'FTBSID', 'apisource-football-sidelined' UNION ALL
		SELECT 'FTBSID', 'pre-processing-football-sidelined' UNION ALL
		SELECT 'FTBPLY', 'apisource-football-player' UNION ALL
		SELECT 'FTBPLY', 'pre-processing-football-player' UNION ALL
		SELECT 'FTBLGE', 'apisource-football-league' UNION ALL
		SELECT 'FTBLGE', 'pre-processing-football-league' UNION ALL
		SELECT 'FTBFXE', 'apisource-football-fixture-event' UNION ALL
		SELECT 'FTBFXE', 'pre-processing-football-fixture-event'
	)
	INSERT INTO logs.lifecycle_topic (
		 lifecycle_id
		,topic
		,is_active
	)
	SELECT
		 l.lifecycle_id
		,a.topic
		,true
	FROM
		a 
	INNER JOIN logs.lifecycle l
		ON a.lifecycle_code = l.lifecycle_code;
	
END $$;

SELECT * FROM logs.process;
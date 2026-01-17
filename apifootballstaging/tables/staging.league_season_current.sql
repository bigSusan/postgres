DROP TABLE IF EXISTS staging.league_season_current;

CREATE TABLE staging.league_season_current (
	 staging_id								INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc							TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc							TIMESTAMP			NULL
	,row_hash								VARCHAR(32)		NOT NULL 
	,league_id								INTEGER			NOT NULL
	,year									INTEGER			NOT NULL
	,start_date								DATE			NOT NULL
	,end_date								DATE				NULL
	,current								BOOLEAN			NOT NULL
	,coverage_fixtures_events				BOOLEAN			NOT NULL
	,coverage_fixtures_lineups				BOOLEAN			NOT NULL
	,coverage_fixtures_statistics_fixtures	BOOLEAN			NOT NULL
	,coverage_fixtures_statistics_players	BOOLEAN			NOT NULL
	,coverage_standings						BOOLEAN			NOT NULL
	,coverage_players						BOOLEAN			NOT NULL
	,coverage_top_scorers					BOOLEAN			NOT NULL
	,coverage_top_assists					BOOLEAN			NOT NULL
	,coverage_top_cards						BOOLEAN			NOT NULL
	,coverage_injuries						BOOLEAN			NOT NULL
	,coverage_predictions					BOOLEAN			NOT NULL
	,coverage_odds							BOOLEAN			NOT NULL
	,CONSTRAINT pk_staging_league_season_current
		PRIMARY KEY (staging_id)
);

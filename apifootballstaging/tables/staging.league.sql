DROP TABLE IF EXISTS staging.league;

CREATE TABLE staging.league (
	 staging_id			INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc		TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP			NULL
	,is_current			BOOLEAN			NOT NULL DEFAULT false
	,is_processed		BOOLEAN			NOT NULL DEFAULT false
	,process_log_id		INTEGER			NOT NULL
	,event_output_id	INTEGER			 	NULL
	,row_hash			VARCHAR(32)		NOT NULL 
	,id					INTEGER			NOT NULL
	,name				VARCHAR(50)		NOT NULL
	,type				VARCHAR(20)		NOT NULL
	,logo				VARCHAR(200)	NOT NULL
	,country			VARCHAR(50)		NOT NULL
	,seasons			JSON			NOT NULL /* This will be passed to a child proc that will process the season */
	,CONSTRAINT pk_staging_league
		PRIMARY KEY (staging_id)
);
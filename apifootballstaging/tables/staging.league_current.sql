DROP TABLE IF EXISTS staging.league_current;

CREATE TABLE staging.league_current (
	 staging_id			INTEGER			NOT NULL 
	,created_utc		TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP			NULL
	,row_hash			VARCHAR(32)		NOT NULL 
	,id					INTEGER			NOT NULL
	,name				VARCHAR(50)		NOT NULL
	,type				VARCHAR(20)		NOT NULL
	,logo				VARCHAR(200)	NOT NULL
	,country			VARCHAR(50)		NOT NULL
	,CONSTRAINT pk_staging_league_current
		PRIMARY KEY (staging_id)
);
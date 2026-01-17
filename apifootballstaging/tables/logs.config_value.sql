DROP TABLE IF EXISTS logs.config_value;

CREATE TABLE logs.config_value (
	 config_value_id		INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc			TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc			TIMESTAMP			NULL
	,config_item_id			INTEGER			NOT NULL
	,value_str				VARCHAR(1000)		NULL
	,value_int				INTEGER				NULL
	,value_ts				TIMESTAMP			NULL
	,value_d				DATE				NULL
	,value_bool				BOOLEAN				NULL
	,from_utc				TIMESTAMP		NOT NULL
	,to_utc					TIMESTAMP		NOT NULL
	,is_current				BOOLEAN			NOT NULL
	,CONSTRAINT pk_logs_config_value
		PRIMARY KEY (config_value_id)
);

/* Indexing to be reviewed */

/* While these may not be called directly by either procedure calls may reference this table */
GRANT SELECT ON logs.config_value TO airflow_user, flink_user;
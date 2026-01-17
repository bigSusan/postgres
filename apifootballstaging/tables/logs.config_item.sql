DROP TABLE IF EXISTS logs.config_item;

CREATE TABLE logs.config_item (
	 config_item_id			INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc			TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc			TIMESTAMP			NULL
	,item_code				CHAR(6)			NOT NULL /* For select statements and external calls independent of generated id */
	,item_name				VARCHAR(50)		NOT NULL
	,is_active				BOOLEAN			NOT NULL
	,CONSTRAINT pk_logs_config_item
		PRIMARY KEY (config_item_id)
);

/* Indexing to be reviewed */

/* While these may not be called directly by either procedure calls may reference this table */
GRANT SELECT ON logs.config_item TO airflow_user, flink_user;
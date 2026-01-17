DROP TABLE IF EXISTS logs.lifecycle_item;

CREATE TABLE logs.lifecycle_item (
	 lifecycle_item_id	INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc		TIMESTAMP	NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP		NULL
	,lifecycle_id		INTEGER		NOT NULL
	,item_code			CHAR(3)		NOT NULL /* Code is sufficient here as api_request (API) -> event_input (EVI) -> record_processing (RPR) -> event_output (EVO) */
	,required			BOOLEAN		NOT NULL /* event_output for example may not be required */
	,CONSTRAINT pk_logs_lifecycle_item
		PRIMARY KEY (lifecycle_item_id)
);

GRANT SELECT ON logs.lifecycle TO airflow_user, flink_user;
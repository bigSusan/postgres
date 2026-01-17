DROP TABLE IF EXISTS logs.event_output_batch_processing;


CREATE TABLE logs.event_output_batch_processing (
	 event_output_id		INTEGER			NOT NULL
	,event_output_batch_id	INTEGER			NOT NULL
	,created_utc			TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,CONSTRAINT pk_logs_event_output_batch_processing
		PRIMARY KEY (event_output_id, event_output_batch_id)
);

GRANT SELECT, INSERT, DELETE ON logs.event_output_batch_processing TO airflow_user;
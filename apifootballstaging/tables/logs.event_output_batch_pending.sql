DROP TABLE IF EXISTS logs.event_output_batch_pending;

CREATE TABLE logs.event_output_batch_pending (
	 event_output_id			INTEGER			NOT NULL
	,created_utc				TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
);

GRANT SELECT, INSERT, DELETE ON logs.event_output_batch_pending TO airflow_user;
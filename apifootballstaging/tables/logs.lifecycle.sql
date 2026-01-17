DROP TABLE IF EXISTS logs.lifecycle;

CREATE TABLE logs.lifecycle (
	 lifecycle_id		INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc		TIMESTAMP	NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP		NULL
	,lifecycle_code		CHAR(6)		NOT NULL /* For selects independent of inserted ids */
	,lifecycle_name		VARCHAR(50)	NOT NULL /* descriptive only */
	,CONSTRAINT pk_logs_lifecycle
		PRIMARY KEY (lifecycle_id)
);

GRANT SELECT ON logs.lifecycle TO airflow_user, flink_user;
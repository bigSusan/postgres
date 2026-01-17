DROP TABLE IF EXISTS logs.lifecycle_topic;

CREATE TABLE logs.lifecycle_topic (
	 lifecycle_topic_id		INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,lifecycle_id			INTEGER		NOT NULL
	,created_utc			TIMESTAMP	NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc			TIMESTAMP		NULL
	,topic					VARCHAR(50)	NOT NULL
	,is_active				BOOLEAN		NOT NULL
	,CONSTRAINT pk_logs_lifecycle_topic
		PRIMARY KEY (lifecycle_topic_id)
);

GRANT SELECT ON logs.lifecycle_topic TO airflow_user, flink_user;
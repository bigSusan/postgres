DROP TABLE IF EXISTS logs.lifecycle_audit;

/* 
	It's up to whatever tries to interrogate this to make sense of the input
*/

CREATE TABLE logs.lifecycle_audit (
	 lifecycle_audit_id			INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc				TIMESTAMP	NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc				TIMESTAMP		NULL
	,lifecycle_item_id			INTEGER		NOT NULL
	,initiating_system_code		CHAR(10)	NOT NULL 
	,initiating_uid				UUID		NOT NULL
	,system_code				CHAR(10)	NOT NULL
	,uid						UUID		NOT NULL
	,CONSTRAINT pk_logs_lifecycle_audit
		PRIMARY KEY (lifecycle_audit_id)
);

GRANT SELECT, INSERT ON logs.lifecycle_audit TO airflow_user;
GRANT INSERT ON logs.lifecycle_audit TO flink_user;

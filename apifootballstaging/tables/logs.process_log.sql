DROP TABLE IF EXISTS logs.process_log;

/*
	This acts as a queue as much as a job and maintains the current state of the process. It's used
	by both scheduled and event driven processes.

	History....
	1.00 - 03/01/2026 - Nick White - Created
*/

CREATE TABLE logs.process_log (
	 process_log_id		INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc		TIMESTAMP	NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP		NULL
	,process_uid		UUID		NOT NULL /* Set by calling application */
	,event_input_id		INTEGER		 	NULL /* So the process knows where it get its data if event driven */
	,process_id			INTEGER		NOT NULL
	,process_code		CHAR(10)	NOT NULL /* Scheduled jobs need to pick up on hard coded values */
	,triggered_on		CHAR(1)		NOT NULL /* So a scheduled job doesn't try to pick up an event driven process */
	,event_trigger_out	VARCHAR(50)		NULL
	,processing_proc	VARCHAR(50)		NULL
	,attempts			INTEGER		NOT NULL
	,attempts_max		INTEGER		NOT NULL /* The config value */
	,delay_secs			INTEGER		NOT NULL /* The config value */
	,delay_utc			TIMESTAMP	NOT NULL /* When the table is queried this may delay sending of event or push to next schedule */
	,status				CHAR(3)		NOT NULL /* PEN,PRO,COM,FAI */
	,CONSTRAINT pk_logs_process_log
		PRIMARY KEY (process_log_id)
);

/* Index for process_uid where the process is event driven */
CREATE INDEX ix_logs_process_log_event
	ON logs.process_log (process_uid,triggered_on) INCLUDE (process_log_id, process_id);

/* Index for process_code for scheduled processes */
CREATE INDEX ix_logs_process_log_scheduled
	ON logs.process_log (process_code,triggered_on,delay_utc,status) INCLUDE (process_log_id,process_id); 

/* No delete permissions required */
GRANT SELECT, INSERT, UPDATE ON logs.process_log TO airflow_user, flink_user;

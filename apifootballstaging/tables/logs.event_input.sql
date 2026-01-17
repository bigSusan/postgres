DROP TABLE IF EXISTS logs.event_input;

/* 
	Now I get to it event_input, output is a bit ambiguous as the goal is for processing
   	where possible to be event driven but I don't want to go back and change it now. This
   	represents an input from a message broker. Rather than attempt to process in the streaming
	app the goal is to insert the json directly and have postgres process it.
 */

CREATE TABLE logs.event_input (
	 event_input_id			INTEGER		NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc			TIMESTAMP	NOT NULL DEFAULT (timezone('utc', now()))
	,updated_utc			TIMESTAMP		NULL
	,source_system_code		CHAR(10)	NOT NULL
	,event_uid				UUID		NOT NULL
	,topic					VARCHAR(50)	NOT NULL
	,event_utc				TIMESTAMP	NOT NULL
	,payload				JSON		NOT NULL
	,CONSTRAINT pk_logs_event_input
		PRIMARY KEY (event_input_id)
);

GRANT SELECT, INSERT, UPDATE ON logs.event_input TO airflow_user, flink_user;

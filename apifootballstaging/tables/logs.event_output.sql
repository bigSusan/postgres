DROP TABLE IF EXISTS logs.event_output;

/*
	An airflow package will run every 30 seconds which will poll this table and look for messages to enqueue

*/

CREATE TABLE logs.event_output (
	 event_output_id		INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc			TIMESTAMP		NOT NULL DEFAULT (timezone('utc', now()))
	,updated_utc			TIMESTAMP			NULL
	,source_table			VARCHAR(50)		NOT NULL 
	,source_id				INTEGER			NOT NULL
	,system_code			CHAR(10)		NOT NULL /* Unique to each producer of messages */
	,event_uid				UUID			NOT NULL
	,topic					VARCHAR(50)		NOT NULL
	,event_utc				TIMESTAMP		NOT NULL DEFAULT (timezone('utc', now())) /* Although same as created_utc here may be different */
	,delay_utc				TIMESTAMP		NOT NULL /* Allows a time to be set before the message is produced */
	,payload 				JSON			NOT NULL /* {Meta{},Body{}} */
	,event_output_batch_id	INTEGER				NULL
	,CONSTRAINT pk_logs_event_output
		PRIMARY KEY (event_output_id)
);

GRANT SELECT, INSERT, UPDATE ON logs.event_output TO airflow_user;

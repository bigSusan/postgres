DROP TABLE IF EXISTS logs.process;

/*
	Where data needs to be processed, it's been inserted into staging but now a process needs
	to pick it up and determine what needs to be done with it. The event trigger is the topic
	name of a message, so when the calling application recieves the message it knows which stored
	procedure (process_procedure) it needs to call.

	History....
	1.00 - 03/01/2026 - Nick White - Created

*/

CREATE TABLE logs.process (
	 process_id			INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc		TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc		TIMESTAMP			NULL
	,process_code		CHAR(10)		NOT NULL /*  */	
	,process_name		VARCHAR(50)		NOT NULL /* Descriptive only */
	,triggered_on		CHAR(1)			NOT NULL /* E - event, S - schedule */
	,event_trigger_in	VARCHAR(50)			NULL /* Should be NULL where tiggered_on = 'S' */
	,event_trigger_out	VARCHAR(50)			NULL /* It's not necessarily the case that an event input will trigger an output */
	,processing_proc	VARCHAR(50)			NULL
	,max_attempts		INTEGER			NOT NULL /* On failure a message should be sent to retry */
	,delay_secs			INTEGER			NOT NULL /* To delay when the message is polled */
	,from_utc			TIMESTAMP		NOT NULL /* History may be required */
	,to_utc				TIMESTAMP		NOT NULL
	,is_current			BOOLEAN			NOT NULL
	,is_active			BOOLEAN			NOT NULL /* If current is not active then any process should fail  */
	,CONSTRAINT pk_logs_process
		PRIMARY KEY (process_id)
);

/* At this point there seems to be little benefit in indexing as there are going to be 15 records at most */

/* There's no reason for these users to do anything other than select */
GRANT SELECT ON logs.process TO airflow_user, flink_user;
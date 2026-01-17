DROP TABLE IF EXISTS logs.event_output_batch;
/* 
	event outputs are picked up by an airflow package periodically and the entire batach is sent to kafka.
	As a result the entire batch of outputs is either logged as a success or failure.
	1. Create the batch and assign any outputs that need to be sent to the message broker
	2. Select all the messages
	3. If success we can remove anything from the output queue
	   If failed update the status of the batch and update the queue

	History....
	1.00 - 03/01/2026 - Nick White - Created
*/
CREATE TABLE logs.event_output_batch (
	 event_output_batch_id		INTEGER			NOT NULL GENERATED ALWAYS AS IDENTITY
	,created_utc				TIMESTAMP		NOT NULL DEFAULT (timezone('utc',now()))
	,updated_utc				TIMESTAMP			NULL
	,batch_uid					UUID			NOT NULL /* Set by calling application */
	,topic						VARCHAR(50)		NOT NULL
	,status						CHAR(3)			NOT NULL
	,rowcount					INTEGER			NOT NULL DEFAULT 0
	,CONSTRAINT pk_logs_event_output_batch
		PRIMARY KEY (event_output_batch_id)
);

/* I think we only need to index on batch_uid at this stage */
CREATE INDEX ix_logs_event_output_batch_batch_uid
	ON logs.event_output_batch (batch_uid);

/* Flink doesn't need access to this */
GRANT INSERT, UPDATE, SELECT ON logs.event_output_batch TO airflow_user;
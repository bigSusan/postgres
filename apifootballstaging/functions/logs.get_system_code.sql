DROP FUNCTION IF EXISTS logs.get_system_code;

CREATE FUNCTION logs.get_system_code (

) RETURNS CHAR(10) LANGUAGE plpgsql
AS $body$
	DECLARE v_system_code CHAR(10);
BEGIN
	SELECT
		CAST(v.value_str AS CHAR(10))
	INTO v_system_code
	FROM
				logs.config_item i
	INNER JOIN	logs.config_value v
		ON i.config_item_id = v.config_item_id
	WHERE
		v.is_current = true
	AND i.is_active = true
	AND i.item_code = 'SYSCDE';

	IF v_system_code IS NULL THEN
		RAISE EXCEPTION 'No system code found';
	END IF;

	RETURN v_system_code;

END $body$

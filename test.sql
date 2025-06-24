SET TERM ^ ;

EXECUTE BLOCK
	RETURNS (
		"V0" VARCHAR(100) CHARACTER SET OCTETS
		, "V1" VARCHAR(100) CHARACTER SET OCTETS
	)
AS
	DECLARE VARIABLE "in_str" VARCHAR(100) CHARACTER SET OCTETS;
BEGIN
	:"in_str" = ascii_char(0) || ascii_char(16) || ascii_char(0) || ascii_char(0);

    FOR SELECT
            "SET_BIT_IN_OCTETS"(:"in_str", 2, 0) AS "V0"
            , "SET_BIT_IN_OCTETS"(:"in_str", 2, 1) AS "V1"
        FROM
            rdb$database
        INTO
            :"V0"
            , :"V1"
    DO SUSPEND;
END
^

SET TERM ; ^
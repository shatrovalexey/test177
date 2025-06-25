SET TERM ^ ;
CREATE OR ALTER FUNCTION "STR_CHAR_PAD_OCTETS"(
    "IN_VAL" VARCHAR(98) CHARACTER SET octets
    , "IN_CHAR" CHAR(1) CHARACTER SET octets
    , "IN_LEN" INTEGER
)
    RETURNS VARCHAR(98) CHARACTER SET octets
    DETERMINISTIC
AS
    DECLARE "V_LEN_MAX" INTEGER = 98;
    DECLARE "V_I" INTEGER;
BEGIN
    IF (:"IN_LEN" IS null) THEN
        RETURN :"IN_VAL";

    IF (:"IN_LEN" NOT BETWEEN 0 AND :"V_LEN_MAX") THEN
        :"IN_LEN" = :"V_LEN_MAX";

    IF (:"IN_CHAR" IS null) THEN
        :"IN_CHAR" = ascii_char(0);

    IF (:"IN_VAL" IS null) THEN
        :"IN_VAL" = '';

    :"V_I" = :"IN_LEN" - octet_length(:"IN_VAL");

    WHILE (:"V_I" > 0) DO
    BEGIN
        :"IN_VAL" = :"IN_VAL" || :"IN_CHAR";
        :"V_I" = :"V_I" - 1;
    END

    RETURN :"IN_VAL";
END
^

CREATE OR ALTER FUNCTION "SET_BIT_IN_OCTETS" (
    "IN_VAL" VARCHAR(100) CHARACTER SET octets
    , "IN_POS" INTEGER
    , "IN_SET" SMALLINT
)
    RETURNS VARCHAR(100) CHARACTER SET octets
    DETERMINISTIC
AS
    DECLARE VARIABLE "V_OCTET" SMALLINT = 8;
    DECLARE VARIABLE "V_LEN_MAX" SMALLINT = 98;
    DECLARE VARIABLE "V_DATA_LEN" INTEGER;
    DECLARE VARIABLE "V_BYTE_INDEX" INTEGER;
    DECLARE VARIABLE "V_BYTE_VALUE" INTEGER;
    DECLARE VARIABLE "V_MASK" INTEGER;
    DECLARE VARIABLE "V_LEN" SMALLINT;
    DECLARE VARIABLE "V_NULL" CHAR(1) CHARACTER SET octets;
BEGIN
    IF (
        (:"IN_POS" IS null)
        OR (:"IN_SET" IS null)
        OR (:"IN_SET" NOT IN (0, 1))
        OR (:"IN_POS" NOT BETWEEN 0 AND :"V_LEN_MAX" - 1)
    ) THEN
        RETURN null;

    :"V_LEN" = octet_length(:"IN_VAL") - 2;
    :"V_NULL" = ascii_char(0);

    IF ((:"IN_VAL" IS null) OR (:"V_LEN" < 1)) THEN
    BEGIN
        :"IN_VAL" = "STR_CHAR_PAD_OCTETS"('', :"V_NULL", 2);
        :"V_LEN" = 0;
    END

    IF (:"V_LEN" < :"IN_POS") THEN
        :"IN_VAL" = :"IN_VAL" || "STR_CHAR_PAD_OCTETS"('', :"V_NULL", :"IN_POS" - :"V_LEN");

    :"V_DATA_LEN" = bin_or(
        bin_shl(ascii_val(substring(:"IN_VAL" FROM 1 FOR 1)), :"V_OCTET")
        , ascii_val(substring(:"IN_VAL" FROM 2 FOR 1))
    );

    IF (:"IN_POS" NOT BETWEEN 0 AND :"V_DATA_LEN" * :"V_OCTET" - 1) THEN
        RETURN null;

    :"V_BYTE_INDEX" = 3 + floor(:"IN_POS" / :"V_OCTET");
    :"V_BYTE_VALUE" = ascii_val(substring(:"IN_VAL" FROM :"V_BYTE_INDEX" FOR 1));
    :"V_MASK" = bin_shl(1, 7 - mod(:"IN_POS", :"V_OCTET"));

    RETURN
        substring(:"IN_VAL" FROM 1 FOR :"V_BYTE_INDEX" - 1)
            || ascii_char(
                CASE
                    :"IN_SET"
                WHEN 1 THEN
                    bin_or(:"V_BYTE_VALUE", :"V_MASK")
                ELSE
                    bin_and(:"V_BYTE_VALUE", :"V_MASK")
                END
            )
            || substring(:"IN_VAL" FROM :"V_BYTE_INDEX" + 1);
END
^

COMMENT ON FUNCTION "STR_CHAR_PAD_OCTETS" IS 'Дополняет строку символами до нужной длинны строки'
^

COMMENT ON FUNCTION "SET_BIT_IN_OCTETS" IS 'Задача для собеседования (Firebird, хранимая функция):
У вас есть строка в формате VARCHAR(100) CHARACTER SET OCTETS, содержащая битовую
последовательность следующего формата:
• Первые 2 байта (big-endian) — длина полезных данных (в байтах).
• Далее — сами данные, хранящиеся в виде битовой строки (байтовое представление).
Требуется реализовать хранимую функцию, которая:
• Принимает три аргумента:
o битовая строка (VARCHAR(100) CHARACTER SET OCTETS)
o номер бита (0 и далее)
o значение бита (0 или 1)
• Устанавливает указанный бит в заданное значение.
• Биты считаются слева направо, т.е. бит 0 — старший в байте.
• Возвращает обновлённую строку в том же формате.'^

SET TERM ; ^
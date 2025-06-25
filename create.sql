SET TERM ^ ;
CREATE OR ALTER FUNCTION "SET_BIT_IN_OCTETS" (
    "IN_VAL" VARCHAR(100) CHARACTER SET octets
    , "IN_POS" INTEGER
    , "IN_SET" "BIT"
)
    RETURNS VARCHAR(100) CHARACTER SET octets
    DETERMINISTIC
AS
    DECLARE VARIABLE "V_OCTET" SMALLINT = 8;
    DECLARE VARIABLE "V_LEN_MAX" SMALLINT = 100;
    DECLARE VARIABLE "V_DATA_LEN" INTEGER;
    DECLARE VARIABLE "V_BYTE_INDEX" INTEGER;
    DECLARE VARIABLE "V_BYTE_VALUE" INTEGER;
    DECLARE VARIABLE "V_MASK" INTEGER;
    DECLARE VARIABLE "V_LEN" SMALLINT;
BEGIN
    IF (
        (:"IN_POS" IS null)
        OR (:"IN_POS" > :"V_LEN_MAX")
        OR (:"IN_SET" IS null)
        OR (:"IN_SET" NOT IN (0, 1))
    ) THEN
        RETURN null;

    :"V_LEN" = octet_length(:"IN_VAL");

    IF ((:"IN_VAL" IS null) OR (:"V_LEN" < 3)) THEN
        :"IN_VAL" = '';

    IF (:V_LEN < :IN_POS) THEN
    BEGIN
        :"V_LEN" = :"IN_POS" - :"V_LEN";

        WHILE (:"V_LEN" > 0) DO
        BEGIN
            :"IN_VAL" = :"IN_VAL" || ascii_char(0);
            :"V_LEN" = :"V_LEN" - 1;
        END
    END

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
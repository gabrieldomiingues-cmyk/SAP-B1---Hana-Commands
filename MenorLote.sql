WITH MenorLotePorPosicao AS (
    SELECT
   "ItemCode",
        "ID da Posição",
        "Código da Posição",
        "ID do Lote",
        "DistNumber",
        "ExpDate",
        ROW_NUMBER() OVER (PARTITION BY "ItemCode" ORDER BY "ExpDate" ASC, "Código da Posição" ASC ) AS rn
    FROM "DW"."PRD_SaldoPorPosicao"
)

SELECT
    T0."DocNum" AS "PEDIDO",
    TO_VARCHAR(T0."TaxDate", 'DD/MM/YYYY') AS "DATA_PEDIDO",
    T0."CardName" AS "RAZÃO_SOCIAL",
    T1."ItemCode" AS "SKU",
    T1."Dscription" AS "DESCRIÇÃO",
    T1."Quantity" AS "QTD",
    T1."Código da Posição" AS "POSIÇÃO",
    T0."U_Obs_Mercos" AS "OBS_MERCOS",
    T0."Comments" AS "OBS",
    '*** ' || UPPER(T2."Name") || ' ***' AS TP_PED
FROM
    ORDR T0
    INNER JOIN (
        SELECT
            T0."DocEntry",
            T0."ItemCode",
            T0."Dscription",
            T0."Quantity",
            T1."ExpDate" AS "Data do Lote",
            T1."Código da Posição"
        FROM
            RDR1 T0
            LEFT JOIN MenorLotePorPosicao T1 
            ON T0."ItemCode" = T1."ItemCode"
            AND T1.rn = 1
    ) T1 ON T1."DocEntry" = T0."DocEntry"
    INNER JOIN "@TIPO_PEDIDO" T2 ON T0."U_Tipo_Pedido" = T2."Code"
WHERE
    T0."DocStatus" = 'O'
    AND T0."CANCELED" = 'N' 
    AND T0."U_Ciclo_Pedido" IN ('3')
    AND T0."DocNum" = '917';
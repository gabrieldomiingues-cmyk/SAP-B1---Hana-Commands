SELECT
    PV0."DocEntry",
    NF."Serial",
    NF."ItemCode",
    PV1."ItemCode",
    PV0."U_Id_Mercos",
    NF."DocEntry",
    NF."LineTotal",
    CASE 
        WHEN PV0."CANCELED" = 'Y' AND PV0."U_Status_Integracao" = '1' THEN 'CANCELAR'
        WHEN PV0."DocStatus" = 'C' AND PV0."CANCELED" = 'N'AND  PV0."U_Status_Integracao" = '1' THEN 'FATURAR'
        --ELSE 'FORA DE PADRÃO'
    END AS "Acao"
    FROM ORDR PV0
    INNER JOIN RDR1 PV1 
    ON PV0."DocEntry" = PV1."DocEntry"
    LEFT JOIN (SELECT NF0."Serial",NF0."DocStatus", NF1.* FROM OINV NF0
                INNER JOIN INV1 NF1
                ON NF0."DocEntry" = NF1."DocEntry"
                AND NF0."CANCELED" = 'N'
                AND NF1."BaseType" = '17') NF
    ON NF."BaseEntry" = PV1."DocEntry"
    AND NF."BaseLine" = PV1."LineNum"
    AND NF."BaseType" = '17'
    AND PV1."TargetType" = '13'
    WHERE  PV0."DocEntry" = '24'
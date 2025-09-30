SELECT
    PV0."DocEntry",
    PV1."ItemCode",
    NF1."DocEntry",
    NF1."ItemCode"
    FROM ORDR PV0
    INNER JOIN RDR1 PV1 
    ON PV0."DocEntry" = PV1."DocEntry"
    INNER JOIN INV1 NF1
    ON NF1."BaseEntry" = PV1."DocEntry"
    AND NF1."BaseLine" = PV1."LineNum"
    --AND NF1."Quantity" <> PV1."U_QtdPicking"
    AND NF1."BaseType" = '17'
    AND PV1."TargetType" = '13'
    INNER JOIN OINV NF0
    ON  NF0."DocEntry" = NF1."DocEntry"
    AND NF0."CANCELED" = 'N'

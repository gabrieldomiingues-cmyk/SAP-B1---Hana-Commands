SELECT
    I0."ItemCode",
    I0."ItemName",
    I2."ItmsGrpNam",
    I0."ManBtchNum",
    I1."Name",
    I0."CodeBars",
    I3."UomCode",
    I0."OrdrMulti" AS "Multíplo",

    CASE
    WHEN S2."AbsEntry" IS NULL THEN Q1."AbsEntry"
    ELSE S2."AbsEntry"
    END AS "ID da Posição",

    CASE
    WHEN S2."BinCode" IS NULL OR S2."BinCode" = '' THEN Q1."BinCode"
    ELSE S2."BinCode"
    END AS "Código da Posição",

    S1."AbsEntry" AS "ID do Lote",
    S1."DistNumber",
    S1."ExpDate",

    CASE
    WHEN S0."OnHandQty" IS NULL THEN Q0."OnHandQty"
    ELSE S0."OnHandQty" 
    END AS "Qtd na Posição"
FROM "QAS_GRACIOSA".OITM I0
INNER JOIN "QAS_GRACIOSA"."@CATEGORIA_PROD" I1
ON I0."U_Categoria" = I1."Code"
INNER JOIN "QAS_GRACIOSA".OITB I2
ON I0."ItmsGrpCod" = I2."ItmsGrpCod"
INNER JOIN "QAS_GRACIOSA".OUOM I3
ON I0."UgpEntry" = I3."UomEntry"
/*TRATATIVA SALDO POR POSIÇÃO COM LOTE*/
LEFT JOIN "QAS_GRACIOSA".OBBQ S0  
ON  I0."ItemCode" = S0."ItemCode"
AND S0."OnHandQty" > 0
AND I0."ManBtchNum" = 'Y'
LEFT JOIN "QAS_GRACIOSA".OBTN S1 
ON S0."SnBMDAbs" = S1."AbsEntry" 
LEFT JOIN "QAS_GRACIOSA".OBIN S2 
ON S0."BinAbs" = S2."AbsEntry"
/*TRATATIVA SALDO POR POSIÇÃO SEM LOTE*/
LEFT JOIN "QAS_GRACIOSA".OIBQ Q0
ON  I0."ItemCode" = Q0."ItemCode"
AND Q0."OnHandQty" > 0
AND I0."ManBtchNum" = 'N'
LEFT JOIN "QAS_GRACIOSA".OBIN Q1 
ON Q0."BinAbs" = Q1."AbsEntry"
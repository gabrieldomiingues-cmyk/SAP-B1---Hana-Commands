SELECT
    T0."DocNum" "Pedido",
    T1."Name" "Tipo Pedido",
    T0."TaxDate" "Data Pedido",
    T0."CardCode" "Cód. Cliente",
    T0."CardName" "Razão Social",
    T7."Name" AS "Regime Tributário",
    T6."State" "UF",
    T3."ItemCode",
    T3."Dscription",
    T9."NcmCode",
    T9."CEST",
    T9."ProductSrc",
    T9."Desc",
    T8."Usage",
    T3."Quantity",
    T3."Price",
    T3."LineTotal",
    T4."StcCode",
    T5."Name",
    T4."StaCode",
    T4."TaxRate" AS "Aliquota",
    T4."BaseSum" AS "Tributada",
    T4."TaxSum",
    T4."TaxInPrice",
    T4."Exempt"
FROM
    ORDR T0
    INNER JOIN RDR1  T3
    ON T0."DocEntry" = T3."DocEntry"

    INNER JOIN RDR4 T4
    ON T3."DocEntry" = T4."DocEntry"
    AND T3."LineNum" = T4."LineNum"

    INNER JOIN OSTT T5
    ON T5."AbsId" = T4."staType"

    INNER JOIN "@TIPO_PEDIDO" T1 
    ON T1."Code" = T0."U_Tipo_Pedido"

    INNER JOIN "OCRD" T2 
    ON T2."CardCode" = T0."CardCode"

    INNER JOIN "CRD1" T6 
    ON T6."CardCode" = T0."CardCode"
    AND T6."LineNum" = 0

    INNER JOIN "@REGIME_TRIBUTARIO" T7
    ON  T7."Code" = T2."U_Regime_Tributario"

    INNER JOIN "OUSG" T8
    ON T8."ID" = T3."Usage"

    INNER JOIN (SELECT 
                T0."ItemCode",
                T1."NcmCode",
                T2."CEST",
                T0."ProductSrc",
                T3."Desc" 
                FROM "SAP_SCHEMA"."OITM"  T0 
                INNER JOIN "SAP_SCHEMA"."ONCM"  T1 
                ON T0."NCMCode" = T1."AbsEntry" 
                INNER JOIN "SAP_SCHEMA"."OCEST"  T2 
                ON T0."CESTCode" = T2."AbsId"
                INNER JOIN OPSC T3
                ON T3."Code" = T0."ProductSrc") T9
    ON  T9."ItemCode" = T3."ItemCode"

WHERE
    T0."DocStatus" = 'O'
    AND T0."CANCELED" = 'N' 
    AND T0."DocNum" NOT IN ('31','34','40')
ORDER BY

    T0."DocNum"

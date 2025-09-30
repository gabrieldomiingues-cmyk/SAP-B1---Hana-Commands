/* SELECT FROM ORDR T0 */ 
DECLARE Nped BIGINT; 
Nped := /* T0.DocNum */ '[%0]';
SELECT
    T0."CardCode",
    T0."CardName",
    T0."DocDate",
    T0."TaxDate",
    T1."ItemCode",
    T1."Dscription",
    T1."Quantity",
    T0."U_Obs_Mercos",
    T0."Comments"
FROM
    ORDR T0
    INNER JOIN RDR1 T1 ON T0."DocEntry" = T1."DocEntry"
WHERE T0."DocStatus" = 'O'
AND T0."CANCELED" = 'N'
AND T0."U_Ciclo_Pedido" IN ('3','4')
AND T0."DocNum" = :Nped;
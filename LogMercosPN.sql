SELECT
    T0."CardCode",
    T0."CardName",
    T0."U_Log_Integracao"
FROM OCRD T0
WHERE T0."U_Data_Log_Integracao" = CURRENT_DATE
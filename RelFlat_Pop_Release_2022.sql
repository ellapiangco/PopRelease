IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'Prc_RelFlat_Pop_ReleaseFlat') DROP PROCEDURE dbo.Prc_RelFlat_Pop_ReleaseFlat

GO one
  
CREATE PROCEDURE dbo.Prc_RelFlat_Pop_ReleaseFlat       
          
AS          
/*        
************************************************************************************************************************************************************        
*                                                                                                                                                          *        
* Procedure Name : Prc_RelFlat_Pop_ReleaseFlat																									       *        
*                                                                                                                                                          *         
* Input Parameters   : none																																   *        
* Output Parameters  : none																																   *        
*                                                                                                                                                          *        
* Database Name  : ASPDB																																   *        
*                                                                                                                                                          *        
* Description  : This stored procedure will populate the computed fields of Tbl_RSU_ReleaseFlat_Trans.													   *
*																																						   *
* Called by Procedure(s)    : None																														   *        
* This procedure calls      : None																														   *        
*																																						   *        
*-------------------------------------------------------------------------------------------------------------------------------------------------------   *        
* Sno  Date   Ver Modified By                     Description																							   *         
*-------------------------------------------------------------------------------------------------------------------------------------------------------   *        
*  01   10/17/2022  1.0  Matias E Mahusay Jr. (MEM) Created SP																							   *
*  01   10/18/2022  2.0  Matias E Mahusay Jr. (MEM) Correction on roundown formula for SharesToBeDeliveredWhole											   *
*  01   11/14/2022  3.0	 Matias E Mahusay Jr. (MEM) Update on Tax Rate formula																			   *
*  01   12/01/2022  4.0  Matias E Mahusay Jr. (MEM) Update round to 2 decimal for cols with LOC and USD													   *
***********************************************************************************************************************************************************        
*/   
  
  
--------------------------------  
-- VARIABLES  --  
--------------------------------  
DECLARE
	  @intError INT 
	, @chvErrLog VARCHAR(100)   
	, @chvSuccess VARCHAR(100) 
  
--------------------------------  
-- SET VARIABLES VALUE  --  
--------------------------------  
SET @intError = 0 
SET @chvErrLog = 'CHECK ERROR LOGS'
SET @chvSuccess = 'COMPUTED FIELDS POPULATED'

--------------------------------  
-- WORKING TABLES  --  
--------------------------------  

  
  
----------------------------------------------  
-- BEGIN POPULATE COMPUTED FIELDS --  
----------------------------------------------  
  

BEGIN TRY

	--- TaxableCompUSD
	------------- Special FMV
	UPDATE trrt
		SET trrt.TaxableCompUSD = ROUND(trrt.SharesReleasing * trrt.SpecialFMVatEvent,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt
	INNER JOIN dbo.Tbl_CompanyCd_Param [tcp]
	ON trrt.CompanyCd = tcp.CompanyCd
	INNER JOIN dbo.Tbl_Country tc
	ON tcp.Country_Code = tc.CountryKey
	WHERE tc.CountryNm IN (SELECT Value FROM Tbl_variables_param WHERE Name = 'Special_FMV_country')

	------------- FMV
	UPDATE trrt
		SET trrt.TaxableCompUSD = ROUND(trrt.SharesReleasing * trrt.FMVatEvent,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt
	INNER JOIN dbo.Tbl_CompanyCd_Param [tcp]
	ON trrt.CompanyCd = tcp.CompanyCd
	INNER JOIN dbo.Tbl_Country tc
	ON tcp.Country_Code = tc.CountryKey
	WHERE tc.CountryNm NOT IN (SELECT Value FROM Tbl_variables_param WHERE Name = 'Special_FMV_country')

	--- TaxableCompLoc
	------------- Special FMV
	UPDATE trrt
		SET trrt.TaxableCompLoc = ROUND(trrt.SharesReleasing * trrt.SpecialFMVatEvent * trrt.ExchangeRate,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt
	INNER JOIN dbo.Tbl_CompanyCd_Param [tcp]
	ON trrt.CompanyCd = tcp.CompanyCd
	INNER JOIN dbo.Tbl_Country tc
	ON tcp.Country_Code = tc.CountryKey
	WHERE tc.CountryNm IN (SELECT Value FROM Tbl_variables_param WHERE Name = 'Special_FMV_country')

	------------- FMV
	UPDATE trrt
		SET trrt.TaxableCompLoc = ROUND(trrt.SharesReleasing * trrt.FMVatEvent * trrt.ExchangeRate,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt
	INNER JOIN dbo.Tbl_CompanyCd_Param [tcp]
	ON trrt.CompanyCd = tcp.CompanyCd
	INNER JOIN dbo.Tbl_Country tc
	ON tcp.Country_Code = tc.CountryKey
	WHERE tc.CountryNm NOT IN (SELECT Value FROM Tbl_variables_param WHERE Name = 'Special_FMV_country')

	--- EstimatedTaxShares
	UPDATE trrt
		SET trrt.EstimatedTaxShares = (trrt.TaxRate/100) * trrt.SharesReleasing -- 11/14/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- SharesToBeDeliveredWhole
	UPDATE trrt
		SET trrt.SharesToBeDeliveredWhole = FLOOR(trrt.SharesReleasing - trrt.EstimatedTaxShares) -- 10/18/2022 correction on roundown formula MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- EstimatedTaxUSD
	UPDATE trrt
		SET trrt.EstimatedTaxUSD = ROUND((trrt.TaxRate/100) * trrt.SharesReleasing * trrt.FMVatEvent,2) -- 11/14/2022 MEM --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- EstimatedTaxLoc
	UPDATE trrt
		SET trrt.EstimatedTaxLoc = ROUND((trrt.TaxRate/100) * trrt.SharesReleasing * trrt.FMVatEvent * trrt.ExchangeRate,2) -- 11/14/2022 MEM --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt
	
	--- EstimatedFracShares
	UPDATE trrt
		SET trrt.EstimatedFracShares = trrt.SharesReleasing - trrt.EstimatedTaxShares - trrt.SharesToBeDeliveredWhole
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- EstimatedFracUSD
	UPDATE trrt
		SET trrt.EstimatedFracUSD = ROUND((trrt.SharesReleasing - trrt.EstimatedTaxShares - trrt.SharesToBeDeliveredWhole) * trrt.FMVatEvent,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- EstimatedFracLoc
	UPDATE trrt
		SET trrt.EstimatedFracLoc = ROUND((trrt.SharesReleasing - trrt.EstimatedTaxShares - trrt.SharesToBeDeliveredWhole) * trrt.FMVatEvent * trrt.ExchangeRate,2) --12/01/2022 MEM
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- ActualTaxShares, ActualTaxUSD, ActualTaxLoc
	UPDATE trrt
		SET trrt.ActualTaxShares = trrt.EstimatedTaxShares
		  , trrt.ActualTaxUSD = trrt.EstimatedTaxUSD
		  , trrt.ActualTaxLoc = trrt.EstimatedTaxLoc
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- SharesToBeDelivered
	UPDATE trrt
		SET trrt.SharesToBeDelivered = trrt.SharesReleasing - trrt.ActualTaxShares
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- FinalFracShares, FinalFracUSD, FinalFracLoc
	UPDATE trrt
		SET trrt.FinalFracShares = trrt.EstimatedFracShares
		  , trrt.FinalFracUSD = trrt.EstimatedFracUSD
		  , trrt.FinalFracLoc = trrt.EstimatedFracLoc
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt

	--- SharesWithheld
	UPDATE trrt
		SET trrt.SharesWithheld = trrt.ActualTaxShares + trrt.FinalFracShares
	FROM dbo.Tbl_RSU_ReleaseFlat_Trans trrt


END TRY  
 BEGIN CATCH  
  SET @intError = 1  
     INSERT INTO TBL_ERROR_LOG    
  VALUES ('Prc_Reflat_Pop_ReleaseFlat',ERROR_NUMBER(),ERROR_MESSAGE(), GETDATE())    
 END CATCH  

----------------------------------------------  
-- END POPULATE COMPUTED FIELDS --  
----------------------------------------------  

  
--------------------------------  
-- BEGIN: DROP WORKING TABLES --  
--------------------------------  

------------------------------  
-- END: DROP WORKING TABLES --  
------------------------------   
EndOFExecution:    

IF @intError > 0
 BEGIN
    INSERT INTO TBL_ERROR_LOG  
    VALUES ('Prc_RelFlat_Pop_ReleaseFlat ','',@chvErrLog, GETDATE()) 
  PRINT 'Failed to execute dbo.Prc_Reflat_Pop_ReleaseFlat'
  SELECT 2
 END
ELSE
 BEGIN

	SELECT 'SUCCESS. ' + ISNULL(@chvSuccess,'')
	PRINT 'dbo.Prc_RelFlat_Pop_ReleaseFlat successfully executed'
	SELECT 0
 END 
SET NOCOUNT ON;

DECLARE @latestProcessDate INT = (SELECT max(ProcessDate) FROM VSARCU02.cfsconnectors.cu.EAUltiproStage);

-- Drop the temporary table if it already exists
IF OBJECT_ID('tempdb..#AUSResults') IS NOT NULL
BEGIN
    DROP TABLE #AUSResults;
END

-- Create the temporary table
CREATE TABLE #AUSResults (
    Result INT,
    Description VARCHAR(100)
);


-- Insert values into the temporary table
INSERT INTO #AUSResults (Result, Description)
VALUES
	(0, 'None'),
    (1, 'Approve/Eligible'),
    (2, 'Approve/Inelegible'),
    (3, 'Refer/Eligible'),
    (4, 'Refer/Ineligible'),
    (5, 'Refer with Caution'),
    (6, 'Out of Scope'),
    (7, 'Error'),
    (8, 'Accept'),
    (9, 'Caution'),
    (10, 'Ineligible'),
    (11, 'Incomplete'),
    (12, 'Invalid'),
    (13, 'Refer'),
    (14, 'Eligible'),
    (15, 'Unable to Determine'),
    (16, 'Other'),
    (17, 'Not Applicable'),
    (18, 'Accept/Eligible'),
    (19, 'Accept/Inelgible'),
    (20, 'Accept/Unable to Determine'),
    (21, 'Refer with Caution/Eligible'),
    (22, 'Refer with Caution/Ineligible'),
    (23, 'Refer/Unable to Determine'),
    (24, 'Refer with Caution/Unable to Determine');

-- Drop the temporary table if it already exists
IF OBJECT_ID('tempdb..#DenialReasons') IS NOT NULL
BEGIN
    DROP TABLE #DenialReasons;
END

-- Create the temporary table
CREATE TABLE #DenialReasons (
    Result INT,
    Description VARCHAR(100)
);


-- Insert values into the temporary table
INSERT INTO #DenialReasons (Result, Description)
VALUES
	(0, 'None'),
    (1, 'Debt to Income Ratio'),
    (2, 'Employment History'),
    (3, 'Credit History'),
    (4, 'Collateral'),
    (5, 'Insufficient Cash'),
    (6, 'Unverifiable Info'),
    (7, 'Credit App Incomplete'),
    (8, 'Mortgage Ins Denied'),
    (9, 'Other'),
    (10, 'Not Applicable');
    --(11, 'Incomplete'),
    --(12, 'Invalid'),
    --(13, 'Refer'),
    --(14, 'Eligible'),
    --(15, 'Unable to Determine'),
    --(16, 'Other'),
    --(17, 'Not Applicable'),
    --(18, 'Accept/Eligible'),
    --(19, 'Accept/Inelgible'),
    --(20, 'Accept/Unable to Determine'),
    --(21, 'Refer with Caution/Eligible'),
    --(22, 'Refer with Caution/Ineligible'),
    --(23, 'Refer/Unable to Determine'),
    --(24, 'Refer with Caution/Unable to Determine');


with maxDenied as (

select 
	max(IDX) as 'Index'
	,spec.LNKEY
	--,max(decision_date) 'MaxDate'
	from [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_URLASPEC] spec
	--where uw_hist.UW_DECISION = 'Denied' 
	group by LNKEY
),
UnpivotedRaces as (

	SELECT LNKEY, WHICHBORR, Race
	FROM (
		SELECT 
			bi.LNKEY,
			bi.WHICHBORR,
			CASE WHEN bl.LNKEY IS NOT NULL THEN 'Y' END AS 'Black or African American',
			CASE WHEN white.LNKEY IS NOT NULL THEN 'Y' END AS 'White',
			CASE WHEN asian.LNKEY IS NOT NULL THEN 'Y' END AS 'Asian',
			CASE WHEN amind.LNKEY IS NOT NULL THEN 'Y' END AS 'American Indian or Alaska Native',
			CASE WHEN pa.LNKEY IS NOT NULL THEN 'Y' END AS 'Native Hawaiian or Other Pacific Islander',
			CASE WHEN np.LNKEY IS NOT NULL THEN 'Y' END AS 'Not Provided',
			CASE WHEN na.LNKEY IS NOT NULL THEN 'Y' END AS 'Not Applicable'
			--CASE WHEN noCo.LNKEY IS NOT NULL THEN 'Y' END AS 'No Coapplicant'
		FROM [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bi
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bl
			ON bl.LNKEY = bi.[LNKEY] AND bl.WHICHBORR = bi.WHICHBORR AND bl.RACEBL_AF_AM = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] white
			ON white.LNKEY = bi.[LNKEY] AND white.WHICHBORR = bi.WHICHBORR AND white.RACEWHITE = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] asian
			ON asian.LNKEY = bi.[LNKEY] AND asian.WHICHBORR = bi.WHICHBORR AND asian.RACEASIAN = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] amind
			ON amind.LNKEY = bi.[LNKEY] AND amind.WHICHBORR = bi.WHICHBORR AND amind.RACEAM_IND_AK = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] pa
			ON pa.LNKEY = bi.[LNKEY] AND pa.WHICHBORR = bi.WHICHBORR AND pa.RACEHI_PACISL = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] np
			ON np.LNKEY = bi.[LNKEY] AND np.WHICHBORR = bi.WHICHBORR AND np.RACENOTPROVID = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] na
			ON na.LNKEY = bi.[LNKEY] AND na.WHICHBORR = bi.WHICHBORR AND na.RACENOTAPPL = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] noCo
			ON noCo.LNKEY = bi.[LNKEY] AND noCo.WHICHBORR = bi.WHICHBORR AND noCo.RACENOCOAPPL = 'Y'
	) AS SourceTable
	UNPIVOT (
		Value FOR Race IN ([Black or African American], [White], [Asian], [American Indian or Alaska Native], [Native Hawaiian or Other Pacific Islander], [Not Provided], [Not Applicable])
	) AS UnpivotedTable
)
,
races as (

SELECT 
    bi.LNKEY,
    bi.WHICHBORR,
    MAX(CASE WHEN ur.RaceRank = 1 THEN ur.Race END) AS HMDARaceType,
	MAX(CASE WHEN ur.RaceRank = 1 THEN ur.Race END) AS HMDARaceType1,
    MAX(CASE WHEN ur.RaceRank = 2 THEN ur.Race END) AS HMDARaceType2,
    MAX(CASE WHEN ur.RaceRank = 3 THEN ur.Race END) AS HMDARaceType3,
    MAX(CASE WHEN ur.RaceRank = 4 THEN ur.Race END) AS HMDARaceType4,
    MAX(CASE WHEN ur.RaceRank = 5 THEN ur.Race END) AS HMDARaceType5
FROM [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bi
LEFT JOIN (
    SELECT 
        LNKEY,
        WHICHBORR,
        Race,
        ROW_NUMBER() OVER (PARTITION BY LNKEY, WHICHBORR ORDER BY Race) AS RaceRank
    FROM UnpivotedRaces
) ur
ON bi.LNKEY = ur.LNKEY AND bi.WHICHBORR = ur.WHICHBORR --and ur.Race <> RaceNOCOAPPL
GROUP BY bi.LNKEY, bi.WHICHBORR
--order by lnkey,WHICHBORR

),
unpivotedEthnicity as (
	SELECT LNKEY, WHICHBORR, Ethnicity
	FROM (
		SELECT 
			bi.LNKEY,
			bi.WHICHBORR,
			--CASE WHEN hispanic.LNKEY IS NOT NULL THEN 'Y' END AS 'Hispanic',
			--CASE WHEN nothispanic.LNKEY IS NOT NULL THEN 'Y' END AS 'Not Hispanic',
			--CASE WHEN notprovided.LNKEY IS NOT NULL THEN 'Y' END AS 'Not Provided',
			--CASE WHEN notapplicable.LNKEY IS NOT NULL THEN 'Y' END AS 'Not Applicable',
			CASE WHEN mexican.LNKEY IS NOT NULL THEN 'Y' END AS 'Mexican',
			CASE WHEN cuban.LNKEY IS NOT NULL THEN 'Y' END AS 'Cuban',
			CASE WHEN puertorican.LNKEY IS NOT NULL THEN 'Y' END AS 'Puerto Rican'
			--CASE WHEN noCo.LNKEY IS NOT NULL THEN 'Y' END AS 'No Coapplicant'
		FROM [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bi
		--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] hispanic
		--	ON hispanic.LNKEY = bi.[LNKEY] AND hispanic.WHICHBORR = bi.WHICHBORR AND hispanic.ETHINICITY = 1
		--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] nothispanic
		--	ON nothispanic.LNKEY = bi.[LNKEY] AND nothispanic.WHICHBORR = bi.WHICHBORR AND nothispanic.ETHINICITY = 2
		--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] notprovided
		--	ON notprovided.LNKEY = bi.[LNKEY] AND notprovided.WHICHBORR = bi.WHICHBORR AND notprovided.ETHINICITY = 3
		--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] notapplicable
		--	ON notapplicable.LNKEY = bi.[LNKEY] AND notapplicable.WHICHBORR = bi.WHICHBORR AND notapplicable.ETHINICITY = 4
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO2] mexican
			ON mexican.LNKEY = bi.[LNKEY] AND mexican.WHICHBORR = bi.WHICHBORR AND mexican.ETHNICITY_MEXICAN = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO2] cuban
			ON cuban.LNKEY = bi.[LNKEY] AND cuban.WHICHBORR = bi.WHICHBORR AND cuban.ETHNICITY_CUBAN = 'Y'
		LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO2] puertorican
			ON puertorican.LNKEY = bi.[LNKEY] AND puertorican.WHICHBORR = bi.WHICHBORR AND puertorican.ETHNICITY_PUERTO_RICAN = 'Y'

	) AS SourceTable
	UNPIVOT (
		Value FOR Ethnicity IN (
		--[HISPANIC_LATINO], [NOT_HISPANIC_LATINO], [NOT_PROVIDED], [NOT_APPLICABLE]
		[Mexican],[Cuban],[Puerto Rican])
	) AS UnpivotedTable
),
ethnicities as (
	SELECT 
		bi.LNKEY,
		bi.WHICHBORR,
	 --   MAX(CASE WHEN ur.EthnicityRank = 1 THEN ur.Ethnicity END) AS HMDAEthnicityType,
		--MAX(CASE WHEN ur.EthnicityRank = 1 THEN ur.Ethnicity END) AS HMDAEthnicityType1,
		MAX(CASE WHEN ur.EthnicityRank = 1 THEN ur.Ethnicity END) AS HMDAEthnicityType2,
		MAX(CASE WHEN ur.EthnicityRank = 2 THEN ur.Ethnicity END) AS HMDAEthnicityType3,
		MAX(CASE WHEN ur.EthnicityRank = 3 THEN ur.Ethnicity END) AS HMDAEthnicityType4,
		MAX(CASE WHEN ur.EthnicityRank = 4 THEN ur.Ethnicity END) AS HMDAEthnicityType5
	FROM [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bi
	LEFT JOIN (
		SELECT 
			LNKEY,
			WHICHBORR,
			Ethnicity,
			ROW_NUMBER() OVER (PARTITION BY LNKEY, WHICHBORR ORDER BY Ethnicity) AS EthnicityRank
		FROM unpivotedEthnicity
	) ur
	ON bi.LNKEY = ur.LNKEY AND bi.WHICHBORR = ur.WHICHBORR --and ur.Race <> RaceNOCOAPPL
	GROUP BY bi.LNKEY, bi.WHICHBORR
),

hmdaFields as (

SELECT 
DISTINCT
--top 2000 
	CONCAT('H', l.[Loan Number]) 'LoanNumber'
	--l.[Loan Number] 'LoanNumber'

	,CONCAT(bi1.BORR_HOUSENUM, ' ', b.[Borrower Address Line 1]) 'Borrower_Address1'
	,b.[Borrower Age] 'Borrower_Age'
	,b.[Which Borrower] 'Borrower_Position' 
	,b.[Borrower City] 'Borrower_City'
	--,'Ethnicity Type Observed' 'EthnicityTypeVisualObservation'
	, CASE 
		WHEN bi2.ETHNICITY_COLLECT_VISUALSURNAM=0
		THEN '0 - Unknown'
		WHEN bi2.ETHNICITY_COLLECT_VISUALSURNAM=1
		THEN '1 - Yes'
		WHEN bi2.ETHNICITY_COLLECT_VISUALSURNAM=2
		THEN '2 - No'
		WHEN bi2.ETHNICITY_COLLECT_VISUALSURNAM=3
		THEN '3 - Not Applicable'
		END as	'EthnicityTypeVisualObservation'
	,b.[Borrower Last Name] 'Borrower_LastName'
	--,b.[Borrower First Name] 'Borrower_FirstName'
	--,bi1.BORR_SEX
	,CASE 
		WHEN b.[Borrower Gender] = 0
		THEN 'Unkown'
		WHEN b.[Borrower Gender] = 1
		THEN 'Female'
		WHEN b.[Borrower Gender] = 2
		THEN 'Male'
		WHEN b.[Borrower Gender] = 3
		THEN 'Not Prov'
		WHEN b.[Borrower Gender] = 4
		THEN 'Not Appl'
		WHEN b.[Borrower Gender] = 6
		THEN 'Applicant seleted both male and female'
		END as 'GenderType'
	--,bi2.SEX_COLLECT_VISUALSURNAM 'GenderTypeVisualObservation'
		, CASE 
		WHEN bi2.SEX_COLLECT_VISUALSURNAM=0
		THEN '0 - Unknown'
		WHEN bi2.SEX_COLLECT_VISUALSURNAM=1
		THEN '1 - Yes'
		WHEN bi2.SEX_COLLECT_VISUALSURNAM=2
		THEN '2 - No'
		WHEN bi2.SEX_COLLECT_VISUALSURNAM=3
		THEN '3 - Not Applicable'
		END as	'GenderTypeVisualObservation'


	--,b.Ethnicity
	--,bi2.ETHNICITY_CUBAN
	--,bi2.ETHNICITY_MEXICAN
	--,bi2.ETHNICITY_PUERTO_RICAN

	,CASE 
		WHEN b.Ethnicity = 1
		THEN '1 - HISPANIC_LATINO'
		WHEN b.Ethnicity = 2
		THEN '2 - NOT_HISPANIC_LATINO'
		WHEN b.Ethnicity = 3
		THEN '3 - NOT_PROVIDED'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 11
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		END as 'HMDAEthnicityType'
	,CASE 
		WHEN b.Ethnicity = 1
		THEN '1 - HISPANIC_LATINO'
		WHEN b.Ethnicity = 2
		THEN '2 - NOT_HISPANIC_LATINO'
		WHEN b.Ethnicity = 3
		THEN '3 - NOT_PROVIDED'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 11
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		WHEN b.Ethnicity = 4
		THEN '4 - NOT_APPLICABLE'
		END as 'HMDAEthnicityType1'
	,CASE 
		WHEN ethnicities.HMDAEthnicityType2 = 'Mexican'
		THEN '11 - Mexican'
		WHEN ethnicities.HMDAEthnicityType2 = 'Puerto Rican'
		THEN '12 - Puerto Rican'
		WHEN ethnicities.HMDAEthnicityType2 = 'Cuban'
		THEN '13 - Cuban'
		END AS 'HMDAEthnicityType2'
	,CASE 
		WHEN ethnicities.HMDAEthnicityType3 = 'Mexican'
		THEN '11 - Mexican'
		WHEN ethnicities.HMDAEthnicityType3 = 'Puerto Rican'
		THEN '12 - Puerto Rican'
		WHEN ethnicities.HMDAEthnicityType3 = 'Cuban'
		THEN '13 - Cuban'
		END AS 'HMDAEthnicityType3'
	,CASE 
		WHEN ethnicities.HMDAEthnicityType4 = 'Mexican'
		THEN '11 - Mexican'
		WHEN ethnicities.HMDAEthnicityType4 = 'Puerto Rican'
		THEN '12 - Puerto Rican'
		WHEN ethnicities.HMDAEthnicityType4 = 'Cuban'
		THEN '13 - Cuban'
		END AS 'HMDAEthnicityType4'
	,CASE 
		WHEN ethnicities.HMDAEthnicityType5 = 'Mexican'
		THEN '11 - Mexican'
		WHEN ethnicities.HMDAEthnicityType5 = 'Puerto Rican'
		THEN '12 - Puerto Rican'
		WHEN ethnicities.HMDAEthnicityType5 = 'Cuban'
		THEN '13 - Cuban'
		END AS 'HMDAEthnicityType5'
	--,bi2.ETHNICITY_OTHER 
	,bi2.ETHNICITY_OTHER_FREEFORM 'HMDAEthnicityOther'
	--,HMDA_NO_COAPPLICANT as NO_CO_APPL
	--,CASE 
	--	WHEN races.HMDARaceType = 'American Indian or Alaska Native'
	--	THEN '1 - American Indian or Alaska Native'
	--	WHEN races.HMDARaceType = 'Asian'
	--	THEN '2 - Asian'
	--	WHEN races.HMDARaceType = 'Black or African American'
	--	THEN '3 - Black or African American'
	--	WHEN races.HMDARaceType = ''
	--	THEN '4 - Native Hawaiian or Other Pacific Islander'
	--	WHEN races.HMDARaceType = 'White'
	--	THEN '5 - White'
	--	WHEN races.HMDARaceType = 'Not Provided'
	--	THEN '6 - Not Provided'
	--	WHEN races.HMDARaceType = 'Not Applicable'
	--	THEN '7 - Not Applicable'
	--	WHEN races.HMDARaceType = 'No Coapplicant'
	--	THEN '8 - No Coapplicant'
	--	END as 'HMDARaceType'
	,races.HMDARaceType
	,COALESCE(races.HMDARaceType1,(CASE WHEN bi1.RACENOCOAPPL = 'Y' THEN 'No Coapplicant' END)) as 'HMDARaceType1'
	,COALESCE(races.HMDARaceType2,(CASE WHEN bi1.RACENOCOAPPL = 'Y' THEN 'No Coapplicant' END)) as 'HMDARaceType2'
	,CASE WHEN COALESCE(races.HMDARaceType2,(CASE WHEN bi1.RACENOCOAPPL = 'Y' THEN 'No Coapplicant' END)) <> 'No Coapplicant' THEN  COALESCE(races.HMDARaceType3,(CASE WHEN bi1.RACENOCOAPPL = 'Y' THEN 'No Coapplicant' END)) END as 'HMDARaceType3'
	,races.HMDARaceType4
	,races.HMDARaceType5
	,bi2.RACE_ENROLLED_PRINCIPAL_TRIBE 'HMDARaceAmIndianOther'
	--,bi2.RACE_OTHER_ASIAN
	,bi2.RACE_OTHER_ASIAN_FREEFORM 'HMDARaceAsianOther'
	,bi2.RACE_OTHER_PACIFIC_FREEFORM 'HMDARacePacificIslanderOther'
	, CASE 
		WHEN bi2.RACE_COLLECT_VISUALSURNAM = 0
		THEN '0 - Unknown'
		WHEN bi2.RACE_COLLECT_VISUALSURNAM = 1
		THEN '1 - Yes'
		WHEN bi2.RACE_COLLECT_VISUALSURNAM = 2
		THEN '2 - No'
		WHEN bi2.RACE_COLLECT_VISUALSURNAM = 3
		THEN '3 - Not Applicable'
		END 'RaceTypeVisualObservation'

	--,bi3.ETHNICITY_HISPANIC_LATINO
	--,bi3.ETHNICITY_NOT_APPLICABLE
	--,bi3.ETHNICITY_NOT_HISPANIC_LATINO
	--,bi3.ETHNICITY_NOT_PROVIDED

	--, LN_REGULAT.[HMDA_NO_COAPPLICANT]
	--,b.[Primary Borrower Flag]
	--,b.[Borrower ID]

	,b.[Borrower State] 'Borrower_State'
	,b.[Borrower Zip Code] 'Borrower_Zip'
	,FORMAT(ld.[Application Date], 'yyyy-MM-dd') 'AppDate_ACES'
	,bi1.CREDIT_SCORE  'AppCreditScore_ACES'

	--,bi3.SERVICEID_CREDITSCOREMODEL 
	, CASE 
		WHEN [Which Borrower]=1 and c.creditscoremodel_borr1 is not null
		THEN CONCAT(c.creditscoremodel_borr1, ' - ',bi3.SERVICEID_CREDITSCOREMODEL)
		WHEN [Which Borrower]=2 and c.creditscoremodel_borr2 is not null
		THEN CONCAT(c.creditscoremodel_borr2, ' - ',bi3.SERVICEID_CREDITSCOREMODEL)
		ELSE NULL
		END as 'AppCreditScoreModel_ACES'
	, CASE 
		WHEN [Which Borrower] = 1
		THEN c.CREDITSCOREMODELFREEFORM_BORR1
		WHEN [Which Borrower] = 2
		THEN c.CREDITSCOREMODELFREEFORM_BORR2
		ELSE NULL
		END as 'AppOtherCreditScoreModel_ACES'
	,CASE spec.APP_TAKEN 
        WHEN 1 THEN '1- Face-to-face'
        WHEN 2 THEN '2- Mail'
        WHEN 3 THEN '3- Telephone'
        WHEN 4 THEN '4- Internet'
        WHEN 5 THEN '5- Not applicable'
        ELSE 'Unknown'
	end as 'AppMethod_ACES'

	--,dblocks.MACHINE
	--,c.AUS_RECOMMENDATION_TOTAL
	,'TOTAL' 'AUS1_ACES'
	,CASE WHEN totalResult.Result is not null THEN CONCAT(totalResult.Result, ' - ' ,totalResult.Description) END as 'AUSResult1_ACES'
	, 'LP' 'AUS2_ACES'
	,CASE WHEN LPResult.Result is not null THEN CONCAT(LPResult.Result, ' - ' ,LPResult.Description) END as 'AUSResult2_ACES'
	,'GUS' 'AUS3_ACES'
	,CASE WHEN gusResult.Result is not null THEN CONCAT(gusResult.Result, ' - ' ,gusResult.Description) END as 'AUSResult3_ACES'
	,'DU' 'AUS4_ACES'
	,CASE WHEN duResult.Result is not null THEN CONCAT(duResult.Result, ' - ' ,duResult.Description) END as 'AUSResult4_ACES'
	,NULL as 'AUS5_ACES'
	,NULL as 'AUSResult5_ACES'
	,c.AUS_OTHER 'AUSOther_ACES'
	,CASE WHEN otherResult.Result is not null THEN CONCAT(otherResult.Result, ' - ' ,otherResult.Description) END as 'AUSResultOther_ACES'
	--,lpResult.Result 'lp'
	--,lpResult.Description 'lpTotal'
	,CASE 
		WHEN reg.BUSINESS_COMMERCIAL_PURPOSE =1
		THEN 'Y'
		WHEN reg.BUSINESS_COMMERCIAL_PURPOSE =2
		THEN 'N'
		END as 'BusinessCommIndicator' --Indicator that displays if the loan is for a business or commercial purpose.
	--,reg.HMDA_NO_COAPPLICANT
	,CASE 
		WHEN reg.HMDA_NO_COAPPLICANT = 'N' or b.[Which Borrower] = 2
		THEN(
				CASE
				WHEN b.[Which Borrower] = 1
				THEN CREDITSCORE_BORR2
				WHEN b.[Which Borrower] = 2
				THEN CREDITSCORE_BORR1
				END 
			)
		ELSE NULL
		END	as 'CoAppCreditScore_ACES'
	,CASE 
		WHEN reg.HMDA_NO_COAPPLICANT = 'N' or b.[Which Borrower] = 2
		THEN(
				CASE
				WHEN b.[Which Borrower] = 1
				THEN cred2.SERVICEID_CREDITSCOREMODEL
				WHEN b.[Which Borrower] = 2
				THEN cred1.SERVICEID_CREDITSCOREMODEL
				END 
			)
		ELSE NULL
		END	as 'CoAppCreditScoreModel_ACES'
	,c.CLTV_RATIO 'CLTVACES'
	--,trans.SELLERNAME
	,'Keesler Federal Credit Union' 'CompanyName_ACES'
	--,'HMDA Construction Method' 'ConstructionMethod_ACES'
	--,fhaTrans.CONSTRUCTIONTYPE
	,CASE
		WHEN ul.CONST_METHOD_TYPE = 0
		THEN '0 - Unknown'
		WHEN ul.CONST_METHOD_TYPE = 1
		THEN '1 - Site Built'
		WHEN ul.CONST_METHOD_TYPE = 2
		THEN '2 - Manufactured Home'
		END as 'ConstructionMethod_ACES' -- Describes construction process for the main dwelling unit
	--,prop2.MAN_HOUS_IND
	--,CONSTFLAG

	,lp.[County Code] 'CountyCode_ACES'
	,c.DEBT_TO_INCOME_RATIO 'DTIACES'
	,reg.TOTAL_DISCOUNT_POINTS 'DiscountPointsACES'
	,c.ANNUAL_INCOME 'HMDA_Income'
	,CASE 
		WHEN lp.[HMDA - HOEPA Status] =0
		THEN '0 - Unknown'
		WHEN lp.[HMDA - HOEPA Status] =1
		THEN '1 - HOEPA'
		WHEN lp.[HMDA - HOEPA Status] =2
		THEN '2 - Not a HOEPA loan'
		WHEN lp.[HMDA - HOEPA Status] =3
		THEN '3 - Not applicable'
		END as	'HOEPAStatus_ACES'
	,CASE 
		WHEN reg.INITIALLY_PAYABLE_TO_INSTITUTE =0
		THEN '0 - Unknown'
		WHEN reg.INITIALLY_PAYABLE_TO_INSTITUTE =1
		THEN '1 - Initially payable to your institution'
		WHEN reg.INITIALLY_PAYABLE_TO_INSTITUTE =2
		THEN '2 - Not initially payable to your institution'
		WHEN reg.INITIALLY_PAYABLE_TO_INSTITUTE =3
		THEN '3 - NA'
		END as 'InitiallyPayable_ACES'
	,lm.[Interest Rate] 'InterestRateACES'
	,reg.INTRODUCTORY_RATE_PERIOD 'IntroRatePeriod_ACES'
	,reg.LEGAL_ENTITY_IDENTIFIER_LEI 'LEI_ACES'
	,gfe.LENDERCREDITS 'LenderCreditsACES'
	,CASE
		WHEN lp.[HMDA - Lien Status] = 0
		THEN '0 - Unknown'
		WHEN lp.[HMDA - Lien Status] = 1
		THEN '1 - Secured by a first lien'
		WHEN lp.[HMDA - Lien Status] = 2
		THEN '2 - Secured by a subordinate lien'
		END as 'LienStatus_ACES'
	,lm.[Loan Amount (Principal)] 'LoanAmountACES'

	,l.[Loan Purpose Description] 'LoanPurpose_ACES'
	--,reg.LOAN_PURPOSE
	,reg.TERM_MONTHS 'LoanTerm_ACES'
	,l.[Loan Type Description] 'LoanType_ACES'
	
	--,'HMDA Manufactured Home Secured Property Type' 'ManufacturedHomeSecuredPropType_ACES'
	--,NULL as 'ManufacturedHomeLandPropertyInterest_ACES'
	,CASE 
		WHEN reg.LAND_OWNERSHIP = 0
		THEN '0 - Unknown'
		WHEN reg.LAND_OWNERSHIP = 1
		THEN '1 - Direct Ownership'
		WHEN reg.LAND_OWNERSHIP = 2
		THEN '2 - Indirect Ownership'
		WHEN reg.LAND_OWNERSHIP = 3
		THEN '3 - Paid Leasehold'
		WHEN reg.LAND_OWNERSHIP = 4
		THEN '4 - Unpaid Leasehold'
		WHEN reg.LAND_OWNERSHIP = 5
		THEN '5 - NA'
		END as 'ManufacturedHomeLandPropertyInterest_ACES'

	,CASE 
		WHEN reg.PROPERTY_SECURED_PROPERTY_TYPE =0
		THEN '0 - Unknown'
		WHEN reg.PROPERTY_SECURED_PROPERTY_TYPE =1
		THEN '1 - Manufactured home and land'
		WHEN reg.PROPERTY_SECURED_PROPERTY_TYPE =2
		THEN '2 - Manufactured home and not land'
		WHEN reg.PROPERTY_SECURED_PROPERTY_TYPE =3
		THEN '3 - NA'
		END as 'ManufacturedHomeSecuredPropType_ACES'
	
	
	,reg.MULTIFAMILY_AFFORDABLE_UNITS 'MultifamilyAffordableUnits_ACES'
	,pln.BALLOONFLAG 'BalloonPayment_ACES'
	,pln.INTONLYFLAG 'IntOnlyPayments_ACES'
	, CASE 
		WHEN urla.NEG_AM_FLAG = 1
		THEN '1 - Yes'
		WHEN urla.NEG_AM_FLAG = 2
		THEN '2 - No'
		ELSE urla.NEG_AM_FLAG
		END as 'NegAmortization_ACES'
	--,lploan.NEGAMORT
	--,lploan.NEGAMORTFLG
	, CASE 
		WHEN terms.AMORTOTHDESC = 1
		THEN '1 - Yes'
		WHEN urla.NEG_AM_FLAG = 2
		THEN '2 - No'
		END as	'OtherNonAmortizingFeatures_ACES'
	,l.[Occupancy Description] 'OccupancyType_ACES'
	,CASE
		WHEN reg.OPEN_END_LINE_OF_CREDIT=0
		THEN '0 - Unknown'
		WHEN reg.OPEN_END_LINE_OF_CREDIT=1
		THEN '1 - Yes'
		WHEN reg.OPEN_END_LINE_OF_CREDIT=2
		THEN '2 - No'
		END as 'OpenEndLOCIndicator_ACES'
	--,calc.HELOCFLAG 
	,reg.TOTAL_ORIGINATION_CHARGES 'OriginationChargesACES'
	,reg.PREPAYMENT_PENALTY 'PrepaymentPenaltyTerm_ACES'
	,c.PROPERTY_VALUE 'PropValueACES'
	--,lsnap.LOCK_DATE
	,FORMAT(terms.LOCKINDATE, 'yyyy-MM-dd') 'RateLockDate_ACES'
	,lp.[HMDA - Actual Rate Spread] 'SpreadACES'
	--,reg.DENIAL_REASON1 
	--,denied.REASON1
	,CASE WHEN denial1.Result is not null THEN CONCAT(denial1.Result, ' - ' ,denial1.Description) END as 'Denial1_ACES'
	,CASE WHEN denial2.Result is not null THEN CONCAT(denial2.Result, ' - ' ,denial2.Description) END as 'Denial2_ACES'
	,CASE WHEN denial3.Result is not null THEN CONCAT(denial3.Result, ' - ' ,denial3.Description) END as 'Denial3_ACES'
	,CASE WHEN denial4.Result is not null THEN CONCAT(denial4.Result, ' - ' ,denial4.Description) END as 'Denial4_ACES'

	----,reg.DENIAL_REASON3 
	----,reg.DENIAL_REASON4 
	,reg.DENIAL_REASON_OTHER 'DenialOther_ACES'
	, 'N' 'ReverseMtgIndicator_ACES'
	,CASE 
		WHEN reg.SUBMISSION_OF_APPLICATION=0
		THEN '0 - Unknown'
		WHEN reg.SUBMISSION_OF_APPLICATION=1
		THEN '1 - Submitted directly to your institution'
		WHEN reg.SUBMISSION_OF_APPLICATION=2
		THEN '2 - Not submitted directly to your institution'
		WHEN reg.SUBMISSION_OF_APPLICATION=3
		THEN '3 - NA'
		END as'AppSubmission_ACES'
	,reg.TOTAL_LOAN_COSTS 'TotalLoanCostsACES'
	,reg.TOTAL_POINTS_FEES 'TotalPointsFeesACES'
	--,reg.TOTAL_DISCOUNT_POINTS
	
	,prop.PROP_UNITS 'TotalUnits_ACES'

	,reg.TYPE_OF_PURCHASER 'Purchaser_ACES'
	,reg.UNIVERSAL_LOAN_IDENTIFIER_ULI 'ULI_ACES'

     
FROM 	[VSODSDB01].[EmpowerODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOAN] l
INNER JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_REGULAT] reg
	ON l.[Loan Number] = reg.LNKEY
		and LARS_INCLUDE = 'Y'
INNER JOIN [VSODSDB01].[EmpowerODS].EMPOWER_WK.LN_DBLOCKS 
	ON LN_DBLOCKS.LNKEY = L.[Loan Number]
--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_REGULAT] 
--	ON l.[Loan Number] = LN_REGULAT.LNKEY
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b 
	ON l.[Loan Number] = b.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_REGULAT_CREDITDEC_SNAPSHOT] c 
	ON c.LNKEY = l.[Loan Number]
--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_REGULAT_CREDITDEC_SNAPSHOT] csn
--	on csn.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO] bi1
	on bi1.LNKEY = l.[Loan Number]
		and bi1.WHICHBORR = b.[Which Borrower]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO2] bi2
	on bi2.LNKEY = l.[Loan Number]
		and bi2.WHICHBORR = b.[Which Borrower]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO3] bi3
	on bi3.LNKEY = l.[Loan Number]
		and bi3.WHICHBORR = b.[Which Borrower]
--LEFT JOIN EmpowerODS.EMPOWER_DIM.ODS_DIM_BORROWER dimBor
--	on dimBor.LOAN_ID = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_CURRADDR] addr
	on addr.LNKEY = l.[Loan Number]
		and addr.WHICHBORR = b.[Which Borrower]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANDATE] ld 
		ON l.[Loan Number] = ld.[Loan Number]
--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_CREDSCORE] cred
--	on cred.LNKEY = l.[Loan Number]
--		and cred.WHICHBORR = b.[Which Borrower]
--		and cred.IS_DECISION_SCORE='Y'
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO3] cred1
	on cred1.LNKEY = l.[Loan Number]
		and cred1.WHICHBORR = 1
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_BORRINFO3] cred2
	on cred2.LNKEY = l.[Loan Number]
		and cred2.WHICHBORR = 2
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANPROPERTY] lp
	ON l.[Loan Number] = lp.[Loan Number]
--LEFT JOIN EmpowerODS.EMPOWER_WK.LN_REGULAT reg
--	on reg.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANMEASURES] lm
	ON l.[Loan Number] = lm.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_GFEDATA] gfe
	on gfe.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_PLANDAT pln
	on pln.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_URLA_DETAILS urla
	on urla.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_LPLOAN lploan
	on lploan.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_MTGTERMS terms
	on terms.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_CALC calc
	on calc.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_PROPINFO prop
	on prop.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].EmpowerODS.EMPOWER_WK.LN_PROPINFO2 prop2
	on prop2.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_ULDD] ul
	on ul.LNKEY = l.[Loan Number]
--LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_DEBTS] debts
--	on debts.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_TRANSUMM] trans
	on trans.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_FHA_TRANS_SUMM] fhaTrans
	on fhaTrans.LNKEY = l.[Loan Number]
LEFT JOIN maxDenied 
	on maxDenied.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_UW_HISTORY] denied 
	on denied.LNKEY = maxDenied.LNKEY and denied.IDX = maxDenied.[Index]
LEFT JOIN #DenialReasons denial1
	on denial1.Result = reg.DENIAL_REASON1 
LEFT JOIN #DenialReasons denial2
	on denial2.Result = reg.DENIAL_REASON2
LEFT JOIN #DenialReasons denial3
	on denial3.Result = reg.DENIAL_REASON3 
LEFT JOIN #DenialReasons denial4
	on denial4.Result = reg.DENIAL_REASON4
--LEFT JOIN #DenialReasons denialOther
--	on denialOther.Result = reg.
LEFT JOIN #AUSResults totalResult
	on totalResult.Result = c.AUS_RECOMMENDATION_TOTAL
LEFT JOIN #AUSResults lpResult
	on lpResult.Result = c.AUS_RECOMMENDATION_LP
LEFT JOIN #AUSResults gusResult
	on gusResult.Result = c.AUS_RECOMMENDATION_GUS
LEFT JOIN #AUSResults duResult
	on duResult.Result = c.AUS_RECOMMENDATION_DU
LEFT JOIN #AUSResults otherResult
	on otherResult.Result = c.AUS_OTHER
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_DBLOCKS] dblocks
	on dblocks.LNKEY = l.[Loan Number]
LEFT JOIN [VSODSDB01].[EmpowerODS].[EMPOWER_WK].[LN_URLASPEC] spec
	on spec.LNKEY = l.[Loan Number]
		and spec.IDX = b.[Which Borrower]
--LEFT JOIN VSARCU02.kRAP.ACES.AUSResultTypes total
--	on total.Number = c.AUS_RECOMMENDATION_TOTAL
LEFT JOIN races
	on races.lnkey = l.[Loan Number]
		and races.WHICHBORR = b.[Which Borrower]
LEFT JOIN ethnicities
	on ethnicities.lnkey = l.[Loan Number]
		and ethnicities.WHICHBORR = b.[Which Borrower]

)-- end hmda
,

StandFields as (

	SELECT DISTINCT 

	--lreg.LARS_INCLUDE
	CASE 
		WHEN lreg.LARS_INCLUDE = 'Y' 
			and l.[Underwriters Decision Code] = 180 -- 'Clear to Close'
			and l.[Loan Status Code] = 234		-- 'Completed Loan'
		THEN 'HMDA Originated'
		WHEN (
				l.[Loan Status Code] = 234		-- 'Completed Loan'
				and (
						[Underwriters Decision Code] IN 
						(
							173,	--'Withdrawn'
							185,	--'Denied'
							171,	--'Denied - Second Signer'
							186,	--'Application Approved, Not Accepted'
							168,	--'Denied - First Signer'
							190,	--'Prequalified Denied'
							182		--'ECOA Denied'

						)
						or ud.LAST_DECISION like '%denied%'
					)
				and lreg.LARS_INCLUDE = 'Y' 
			)
		THEN 'HMDA Non-Originated'
		WHEN (
				l.[Loan Status Code] = 234		-- 'Completed Loan'
				and (
						[Underwriters Decision Code] IN 
						(
							173,	--'Withdrawn'
							185,	--'Denied'
							171,	--'Denied - Second Signer'
							186,	--'Application Approved, Not Accepted'
							168,	--'Denied - First Signer'
							190,	--'Prequalified Denied'
							182		--'ECOA Denied'

						)
						or ud.LAST_DECISION like '%denied%'
					)
			)
		THEN 'Adverse'
		WHEN (
				l.[Underwriters Decision Code] = 180	--'Clear to Close'
				and l.[Loan Status Code] IN
				( 
					210,	-- In Underwriting
					220,	-- 'In Closing'
					226		-- 'In Funding'
				)
			 )
		THEN 'Pre-Funding'
		WHEN (
				l.[Underwriters Decision Code] = 180	--'Clear to Close'
				and l.[Loan Status Code] IN
				( 
					234,		-- 'Completed Loan'
					221			-- 'In Post Closing'
				)
			)
		THEN 'Post-Closing'
		WHEN l.[Loan Status Code] NOT IN (234, 221) 
		THEN 'In-Progress'
		ELSE 'Uncategorized'
	END as LoanStatus

	, FORMAT(h.DECISION_DATE, 'yyyy-MM-dd') 'LoanStatusDate'

	--Required
	, CASE 
		WHEN lreg.LARS_INCLUDE = 'Y' 
			and l.[Underwriters Decision Code] = 180 -- 'Clear to Close'
			and l.[Loan Status Code] = 234		-- 'Completed Loan'
		THEN CONCAT('H', l.[Loan Number]) 
		WHEN (
				l.[Loan Status Code] = 234		-- 'Completed Loan'
				and (
						[Underwriters Decision Code] IN 
						(
							173,	--'Withdrawn'
							185,	--'Denied'
							171,	--'Denied - Second Signer'
							186,	--'Application Approved, Not Accepted'
							168,	--'Denied - First Signer'
							190,	--'Prequalified Denied'
							182		--'ECOA Denied'

						)
						or ud.LAST_DECISION like '%denied%'
					)
				and lreg.LARS_INCLUDE = 'Y' 
			)
		THEN CONCAT('H', l.[Loan Number]) 
		ELSE l.[Loan Number]
		END as	'LoanNumber'


FROM
	[VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOAN] l
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_REGULAT] lreg
		ON l.[Loan Number] = lreg.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].Empower_WK.LN_UW_HISTORY h
	   ON l.[Loan Number] = h.LNKEY
		and h.IDX in (select MAX(IDX) from [VSODSDB01].[EMPOWERODS].Empower_WK.LN_UW_HISTORY h2 where h2.LNKEY=h.LNKEY)
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[Empower_WK].LN_UNDERWRITING_DECISION ud
		ON ud.LNKEY = l.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANPERSONNEL] lper
		ON l.[Loan Number] = lper.[Loan Number]


where [Underwriters Decision Code] <> 120		-- Suspended
and [Underwriters Decision Code] <> 174		-- Cancelled
and ud.LAST_DECISION  not like '%request%'	--filter out 'cancel request' 'withdrawn request' etc
--and [Underwriters Decision Code] not in  ( 187, 188, 192) -- not a 'request'

--Not Testing
and	
	(lper.Underwriter		is null		OR lper.Underwriter		= ''	or	lper.Underwriter		not like 'Test %')
and (lper.[Loan Officer]	is null		OR lper.[Loan Officer]	= ''	or	lper.[Loan Officer]		not like 'Test %')
and (lper.[Closer Name]		is null		OR lper.[Loan Officer]	= ''	or	lper.[Closer Name]		not like 'Test %')
and (lper.Processor			is null		OR lper.[Loan Officer]	= ''	or lper.Processor			not like 'Test %')
and (lper.funder			is null		OR lper.[Loan Officer]	= ''	or lper.Funder				not like 'Test %')



) --end standardFields



----HMDA QUERY
select

 MAX(ISNULL(CAST(s.LoanStatus		AS VARCHAR(20)),'')) LoanStatus
, MAX(ISNULL(CAST(s.LoanStatusDate	AS VARCHAR(10)),'')) LoanStatusDate
, MAX(ISNULL(CAST(h.LoanNumber		AS VARCHAR(10)),'')) LoanNumber
									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_Address1 										END AS VARCHAR(50)),'')) AS Borrower_Address1 							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_Age 												END AS VARCHAR(50)),'')) AS Borrower_Age 								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_Position											END AS VARCHAR(50)),'')) AS Borrower_Position							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_City 											END AS VARCHAR(50)),'')) AS Borrower_City 								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN EthnicityTypeVisualObservation							END AS VARCHAR(50)),'')) AS EthnicityTypeVisualObservation				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_LastName 										END AS VARCHAR(50)),'')) AS Borrower_LastName 							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN GenderType 												END AS VARCHAR(50)),'')) AS GenderType 									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN GenderTypeVisualObservation								END AS VARCHAR(50)),'')) AS GenderTypeVisualObservation					
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppCreditScore_ACES										END AS VARCHAR(50)),'')) AS AppCreditScore_ACES							
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppCreditScoreModel_ACES									END AS VARCHAR(50)),'')) AS AppCreditScoreModel_ACES					
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppOtherCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS AppOtherCreditScoreModel_ACES				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType											END AS VARCHAR(50)),'')) AS HMDAEthnicityType							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType1										END AS VARCHAR(50)),'')) AS HMDAEthnicityType1							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType2										END AS VARCHAR(50)),'')) AS HMDAEthnicityType2							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType3										END AS VARCHAR(50)),'')) AS HMDAEthnicityType3							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType4										END AS VARCHAR(50)),'')) AS HMDAEthnicityType4							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityType5										END AS VARCHAR(50)),'')) AS HMDAEthnicityType5							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDAEthnicityOther										END AS VARCHAR(50)),'')) AS HMDAEthnicityOther							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType 												END AS VARCHAR(50)),'')) AS HMDARaceType 								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType1												END AS VARCHAR(50)),'')) AS HMDARaceType1								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType2												END AS VARCHAR(50)),'')) AS HMDARaceType2								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType3												END AS VARCHAR(50)),'')) AS HMDARaceType3								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType4												END AS VARCHAR(50)),'')) AS HMDARaceType4								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceType5												END AS VARCHAR(50)),'')) AS HMDARaceType5								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceAmIndianOther										END AS VARCHAR(50)),'')) AS HMDARaceAmIndianOther						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARaceAsianOther										END AS VARCHAR(50)),'')) AS HMDARaceAsianOther							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDARacePacificIslanderOther								END AS VARCHAR(50)),'')) AS HMDARacePacificIslanderOther				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN RaceTypeVisualObservation									END AS VARCHAR(50)),'')) AS RaceTypeVisualObservation					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_State 											END AS VARCHAR(50)),'')) AS Borrower_State 								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Borrower_Zip 												END AS VARCHAR(50)),'')) AS Borrower_Zip 								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppDate_ACES												END AS VARCHAR(50)),'')) AS AppDate_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppCreditScore_ACES										END AS VARCHAR(50)),'')) AS AppCreditScore_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppCreditScoreModel_ACES									END AS VARCHAR(50)),'')) AS AppCreditScoreModel_ACES					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppOtherCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS AppOtherCreditScoreModel_ACES				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppMethod_ACES											END AS VARCHAR(50)),'')) AS AppMethod_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResult1_ACES											END AS VARCHAR(50)),'')) AS AUSResult1_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResult2_ACES											END AS VARCHAR(50)),'')) AS AUSResult2_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResult3_ACES											END AS VARCHAR(50)),'')) AS AUSResult3_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResult4_ACES											END AS VARCHAR(50)),'')) AS AUSResult4_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResult5_ACES											END AS VARCHAR(50)),'')) AS AUSResult5_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUS1_ACES													END AS VARCHAR(50)),'')) AS AUS1_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUS2_ACES													END AS VARCHAR(50)),'')) AS AUS2_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUS3_ACES													END AS VARCHAR(50)),'')) AS AUS3_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUS4_ACES													END AS VARCHAR(50)),'')) AS AUS4_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUS5_ACES													END AS VARCHAR(50)),'')) AS AUS5_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSOther_ACES												END AS VARCHAR(50)),'')) AS AUSOther_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AUSResultOther_ACES										END AS VARCHAR(50)),'')) AS AUSResultOther_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN BusinessCommIndicator										END AS VARCHAR(50)),'')) AS BusinessCommIndicator						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN CoAppCreditScore_ACES										END AS VARCHAR(50)),'')) AS CoAppCreditScore_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN CoAppCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS CoAppCreditScoreModel_ACES					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN CLTVACES													END AS VARCHAR(50)),'')) AS CLTVACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN CompanyName_ACES											END AS VARCHAR(50)),'')) AS CompanyName_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN ConstructionMethod_ACES									END AS VARCHAR(50)),'')) AS ConstructionMethod_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN CountyCode_ACES											END AS VARCHAR(50)),'')) AS CountyCode_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN DTIACES													END AS VARCHAR(50)),'')) AS DTIACES										
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN DiscountPointsACES										END AS VARCHAR(50)),'')) AS DiscountPointsACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HMDA_Income												END AS VARCHAR(50)),'')) AS HMDA_Income									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN HOEPAStatus_ACES											END AS VARCHAR(50)),'')) AS HOEPAStatus_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN InitiallyPayable_ACES										END AS VARCHAR(50)),'')) AS InitiallyPayable_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN InterestRateACES											END AS VARCHAR(50)),'')) AS InterestRateACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN IntroRatePeriod_ACES										END AS VARCHAR(50)),'')) AS IntroRatePeriod_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LEI_ACES													END AS VARCHAR(50)),'')) AS LEI_ACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LenderCreditsACES											END AS VARCHAR(50)),'')) AS LenderCreditsACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LienStatus_ACES											END AS VARCHAR(50)),'')) AS LienStatus_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LoanAmountACES											END AS VARCHAR(50)),'')) AS LoanAmountACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LoanPurpose_ACES											END AS VARCHAR(50)),'')) AS LoanPurpose_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LoanTerm_ACES												END AS VARCHAR(50)),'')) AS LoanTerm_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN LoanType_ACES												END AS VARCHAR(50)),'')) AS LoanType_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN ManufacturedHomeLandPropertyInterest_ACES					END AS VARCHAR(50)),'')) AS ManufacturedHomeLandPropertyInterest_ACES	
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN ManufacturedHomeSecuredPropType_ACES						END AS VARCHAR(50)),'')) AS ManufacturedHomeSecuredPropType_ACES		
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN MultifamilyAffordableUnits_ACES							END AS VARCHAR(50)),'')) AS MultifamilyAffordableUnits_ACES				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN BalloonPayment_ACES										END AS VARCHAR(50)),'')) AS BalloonPayment_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN IntOnlyPayments_ACES										END AS VARCHAR(50)),'')) AS IntOnlyPayments_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN NegAmortization_ACES										END AS VARCHAR(50)),'')) AS NegAmortization_ACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN OtherNonAmortizingFeatures_ACES							END AS VARCHAR(50)),'')) AS OtherNonAmortizingFeatures_ACES				
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN OccupancyType_ACES										END AS VARCHAR(50)),'')) AS OccupancyType_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN OpenEndLOCIndicator_ACES									END AS VARCHAR(50)),'')) AS OpenEndLOCIndicator_ACES					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN OriginationChargesACES									END AS VARCHAR(50)),'')) AS OriginationChargesACES						
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN DenialOther_ACES											END AS VARCHAR(50)),'')) AS DenialOther_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN PrepaymentPenaltyTerm_ACES								END AS VARCHAR(50)),'')) AS PrepaymentPenaltyTerm_ACES					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN PropValueACES												END AS VARCHAR(50)),'')) AS PropValueACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN RateLockDate_ACES											END AS VARCHAR(50)),'')) AS RateLockDate_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN SpreadACES												END AS VARCHAR(50)),'')) AS SpreadACES									
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Denial1_ACES												END AS VARCHAR(50)),'')) AS Denial1_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Denial2_ACES												END AS VARCHAR(50)),'')) AS Denial2_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Denial3_ACES												END AS VARCHAR(50)),'')) AS Denial3_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Denial4_ACES												END AS VARCHAR(50)),'')) AS Denial4_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN ReverseMtgIndicator_ACES									END AS VARCHAR(50)),'')) AS ReverseMtgIndicator_ACES					
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN AppSubmission_ACES										END AS VARCHAR(50)),'')) AS AppSubmission_ACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN TotalLoanCostsACES										END AS VARCHAR(50)),'')) AS TotalLoanCostsACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN TotalPointsFeesACES										END AS VARCHAR(50)),'')) AS TotalPointsFeesACES							
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN TotalUnits_ACES											END AS VARCHAR(50)),'')) AS TotalUnits_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN Purchaser_ACES											END AS VARCHAR(50)),'')) AS Purchaser_ACES								
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =1 THEN ULI_ACES													END AS VARCHAR(50)),'')) AS ULI_ACES                                     


, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_Address1 										END AS VARCHAR(50)),'')) AS Borrower_Address1_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_Age 												END AS VARCHAR(50)),'')) AS Borrower_Age_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_Position											END AS VARCHAR(50)),'')) AS Borrower_Position_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_City 											END AS VARCHAR(50)),'')) AS Borrower_City_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN EthnicityTypeVisualObservation							END AS VARCHAR(50)),'')) AS EthnicityTypeVisualObservation_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_LastName 										END AS VARCHAR(50)),'')) AS Borrower_LastName_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN GenderType 												END AS VARCHAR(50)),'')) AS GenderType_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN GenderTypeVisualObservation								END AS VARCHAR(50)),'')) AS GenderTypeVisualObservation_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppCreditScore_ACES										END AS VARCHAR(50)),'')) AS AppCreditScore_ACES_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppCreditScoreModel_ACES									END AS VARCHAR(50)),'')) AS AppCreditScoreModel_ACES_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppOtherCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS AppOtherCreditScoreModel_ACES_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType											END AS VARCHAR(50)),'')) AS HMDAEthnicityType_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType1										END AS VARCHAR(50)),'')) AS HMDAEthnicityType1_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType2										END AS VARCHAR(50)),'')) AS HMDAEthnicityType2_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType3										END AS VARCHAR(50)),'')) AS HMDAEthnicityType3_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType4										END AS VARCHAR(50)),'')) AS HMDAEthnicityType4_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityType5										END AS VARCHAR(50)),'')) AS HMDAEthnicityType5_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDAEthnicityOther										END AS VARCHAR(50)),'')) AS HMDAEthnicityOther_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType 												END AS VARCHAR(50)),'')) AS HMDARaceType_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType1												END AS VARCHAR(50)),'')) AS HMDARaceType1_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType2												END AS VARCHAR(50)),'')) AS HMDARaceType2_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType3												END AS VARCHAR(50)),'')) AS HMDARaceType3_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType4												END AS VARCHAR(50)),'')) AS HMDARaceType4_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceType5												END AS VARCHAR(50)),'')) AS HMDARaceType5_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceAmIndianOther										END AS VARCHAR(50)),'')) AS HMDARaceAmIndianOther_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARaceAsianOther										END AS VARCHAR(50)),'')) AS HMDARaceAsianOther_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDARacePacificIslanderOther								END AS VARCHAR(50)),'')) AS HMDARacePacificIslanderOther_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN RaceTypeVisualObservation									END AS VARCHAR(50)),'')) AS RaceTypeVisualObservation_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_State 											END AS VARCHAR(50)),'')) AS Borrower_State_2
, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Borrower_Zip 												END AS VARCHAR(50)),'')) AS Borrower_Zip_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppDate_ACES												END AS VARCHAR(50)),'')) AS AppDate_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppCreditScore_ACES										END AS VARCHAR(50)),'')) AS AppCreditScore_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppCreditScoreModel_ACES									END AS VARCHAR(50)),'')) AS AppCreditScoreModel_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppOtherCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS AppOtherCreditScoreModel_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppMethod_ACES											END AS VARCHAR(50)),'')) AS AppMethod_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResult1_ACES											END AS VARCHAR(50)),'')) AS AUSResult1_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResult2_ACES											END AS VARCHAR(50)),'')) AS AUSResult2_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResult3_ACES											END AS VARCHAR(50)),'')) AS AUSResult3_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResult4_ACES											END AS VARCHAR(50)),'')) AS AUSResult4_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResult5_ACES											END AS VARCHAR(50)),'')) AS AUSResult5_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUS1_ACES													END AS VARCHAR(50)),'')) AS AUS1_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUS2_ACES													END AS VARCHAR(50)),'')) AS AUS2_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUS3_ACES													END AS VARCHAR(50)),'')) AS AUS3_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUS4_ACES													END AS VARCHAR(50)),'')) AS AUS4_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUS5_ACES													END AS VARCHAR(50)),'')) AS AUS5_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSOther_ACES												END AS VARCHAR(50)),'')) AS AUSOther_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AUSResultOther_ACES										END AS VARCHAR(50)),'')) AS AUSResultOther_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN BusinessCommIndicator										END AS VARCHAR(50)),'')) AS BusinessCommIndicator_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN CoAppCreditScore_ACES										END AS VARCHAR(50)),'')) AS CoAppCreditScore_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN CoAppCreditScoreModel_ACES								END AS VARCHAR(50)),'')) AS CoAppCreditScoreModel_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN CLTVACES													END AS VARCHAR(50)),'')) AS CLTVACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN CompanyName_ACES											END AS VARCHAR(50)),'')) AS CompanyName_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN ConstructionMethod_ACES									END AS VARCHAR(50)),'')) AS ConstructionMethod_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN CountyCode_ACES											END AS VARCHAR(50)),'')) AS CountyCode_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN DTIACES													END AS VARCHAR(50)),'')) AS DTIACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN DiscountPointsACES										END AS VARCHAR(50)),'')) AS DiscountPointsACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HMDA_Income												END AS VARCHAR(50)),'')) AS HMDA_Income_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN HOEPAStatus_ACES											END AS VARCHAR(50)),'')) AS HOEPAStatus_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN InitiallyPayable_ACES										END AS VARCHAR(50)),'')) AS InitiallyPayable_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN InterestRateACES											END AS VARCHAR(50)),'')) AS InterestRateACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN IntroRatePeriod_ACES										END AS VARCHAR(50)),'')) AS IntroRatePeriod_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LEI_ACES													END AS VARCHAR(50)),'')) AS LEI_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LenderCreditsACES											END AS VARCHAR(50)),'')) AS LenderCreditsACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LienStatus_ACES											END AS VARCHAR(50)),'')) AS LienStatus_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LoanAmountACES											END AS VARCHAR(50)),'')) AS LoanAmountACE_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LoanPurpose_ACES											END AS VARCHAR(50)),'')) AS LoanPurpose_AES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LoanTerm_ACES												END AS VARCHAR(50)),'')) AS LoanTerm_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN LoanType_ACES												END AS VARCHAR(50)),'')) AS LoanType_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN ManufacturedHomeLandPropertyInterest_ACES					END AS VARCHAR(50)),'')) AS ManufacturedHomeLandPropertyInterest_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN ManufacturedHomeSecuredPropType_ACES						END AS VARCHAR(50)),'')) AS ManufacturedHomeSecuredPropType_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN MultifamilyAffordableUnits_ACES							END AS VARCHAR(50)),'')) AS MultifamilyAffordableUnits_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN BalloonPayment_ACES										END AS VARCHAR(50)),'')) AS BalloonPayment_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN IntOnlyPayments_ACES										END AS VARCHAR(50)),'')) AS IntOnlyPayments_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN NegAmortization_ACES										END AS VARCHAR(50)),'')) AS NegAmortization_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN OtherNonAmortizingFeatures_ACES							END AS VARCHAR(50)),'')) AS OtherNonAmortizingFeatures_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN OccupancyType_ACES										END AS VARCHAR(50)),'')) AS OccupancyType_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN OpenEndLOCIndicator_ACES									END AS VARCHAR(50)),'')) AS OpenEndLOCIndicator_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN OriginationChargesACES									END AS VARCHAR(50)),'')) AS OriginationChargesACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN DenialOther_ACES											END AS VARCHAR(50)),'')) AS DenialOther_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN PrepaymentPenaltyTerm_ACES								END AS VARCHAR(50)),'')) AS PrepaymentPenaltyTerm_ACES2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN PropValueACES												END AS VARCHAR(50)),'')) AS PropValueACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN RateLockDate_ACES											END AS VARCHAR(50)),'')) AS RateLockDate_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN SpreadACES												END AS VARCHAR(50)),'')) AS SpreadACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Denial1_ACES												END AS VARCHAR(50)),'')) AS Denial1_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Denial2_ACES												END AS VARCHAR(50)),'')) AS Denial2_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Denial3_ACES												END AS VARCHAR(50)),'')) AS Denial3_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Denial4_ACES												END AS VARCHAR(50)),'')) AS Denial4_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN ReverseMtgIndicator_ACES									END AS VARCHAR(50)),'')) AS ReverseMtgIndicator_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN AppSubmission_ACES										END AS VARCHAR(50)),'')) AS AppSubmission_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN TotalLoanCostsACES										END AS VARCHAR(50)),'')) AS TotalLoanCostsACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN TotalPointsFeesACES										END AS VARCHAR(50)),'')) AS TotalPointsFeesACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN TotalUnits_ACES											END AS VARCHAR(50)),'')) AS TotalUnits_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN Purchaser_ACES											END AS VARCHAR(50)),'')) AS Purchaser_ACES_2
--, MAX(ISNULL(CAST(CASE WHEN Borrower_Position =2 THEN ULI_ACES													END AS VARCHAR(50)),'')) AS ULI_ACES_2

from standFields s
INNER join hmdaFields h
	on CAST(s.LoanNumber AS VARCHAR) = h.LoanNumber 
where s.loannumber is not null
and loanstatus is not null
and loanstatusdate is not null
and (	
		LoanStatus = 'HMDA Originated' 
		or 
		LoanStatus = 'HMDA Non-Originated'
	)

group by h.LoanNumber
order by LoanStatus,LoanNumber,Borrower_Position


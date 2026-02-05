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

StandFields as (

	SELECT DISTINCT 

	--lreg.LARS_INCLUDE
	CASE 
		--WHEN lreg.LARS_INCLUDE = 'Y' 
		--	and l.[Underwriters Decision Code] = 180 -- 'Clear to Close'
		--	and l.[Loan Status Code] = 234		-- 'Completed Loan'
		--THEN 'HMDA Originated'

		--WHEN (
		--		l.[Loan Status Code] = 234		-- 'Completed Loan'
		--		and (
		--				[Underwriters Decision Code] IN 
		--				(
		--					173,	--'Withdrawn'
		--					185,	--'Denied'
		--					171,	--'Denied - Second Signer'
		--					186,	--'Application Approved, Not Accepted'
		--					168,	--'Denied - First Signer'
		--					190,	--'Prequalified Denied'
		--					182		--'ECOA Denied'

		--				)
		--				or ud.LAST_DECISION like '%denied%'
		--			)
		--		and lreg.LARS_INCLUDE = 'Y' 
		--	)
		--THEN 'HMDA Non-Originated'

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

	--------LoanStatus
	--------, ud.LAST_DECISION 'UW_Decision'
	--------,l.[Underwriters Decision Code] 'UW_DecisionCode'
	, FORMAT(h.DECISION_DATE, 'yyyy-MM-dd') 'LoanStatusDate'

	--, l.[Loan Status Code] 'LoanStatusCode'
	, l.[Loan Status Description] 'EmpowerLoanStatus' 

	, ud.LAST_DECISION 'LastDecision'
	--, ctcdate.ctcDate 'ClearToCloseDate'
	--, CASE	WHEN (
	--			l.[Loan Status Code] = 234		-- 'Completed Loan'
	--			and (
	--					[Underwriters Decision Code] IN 
	--					(
	--						173,	--'Withdrawn'
	--					)
	--				)
	--		)
	--	THEN ud.LAST_DECISION
	--	WHEN (
	--			l.[Loan Status Code] = 234		-- 'Completed Loan'
	--			and (
	--					[Underwriters Decision Code] IN 
	--					(
	--						186,	--'Application Approved, Not Accepted'
	--					)
	--				)
	--		)
	--	THEN ud.LAST_DECISION
	--	END 

	--Required
	--, CASE 
		--WHEN lreg.LARS_INCLUDE = 'Y' 
		--	and l.[Underwriters Decision Code] = 180 -- 'Clear to Close'
		--	and l.[Loan Status Code] = 234		-- 'Completed Loan'
		--THEN CONCAT('H', l.[Loan Number]) 
		--WHEN (
		--		l.[Loan Status Code] = 234		-- 'Completed Loan'
		--		and (
		--				[Underwriters Decision Code] IN 
		--				(
		--					173,	--'Withdrawn'
		--					185,	--'Denied'
		--					171,	--'Denied - Second Signer'
		--					186,	--'Application Approved, Not Accepted'
		--					168,	--'Denied - First Signer'
		--					190,	--'Prequalified Denied'
		--					182		--'ECOA Denied'

		--				)
		--				or ud.LAST_DECISION like '%denied%'
		--			)
		--		and lreg.LARS_INCLUDE = 'Y' 
		--	)
		--THEN CONCAT('H', l.[Loan Number]) 
		--ELSE l.[Loan Number]
		--END as	'LoanNumber'
	, l.[Loan Number] as 'LoanNumber'

	--Required
	, FORMAT(ld.[Application Date], 'yyyy-MM-dd') as 'BorrowerApplicationSignedDate'

	--Required
	--LienType = Lien Position of Loan ( 'First Mortgage' or 'Second Mortgage')
	, CASE WHEN l.[Fannie Mae DU Lien Type] = 1 THEN 'First'
		WHEN l.[Fannie Mae DU Lien Type] = 2 THEN 'Subordinate'
		--WHEN l.[Fannie Mae DU Lien Type] = 3 THEN 'Other'
		ELSE NULL
		end as 'LienType'

		--UPDATED FOR ACES PROTECT SPEC:
		, CASE 
		WHEN CHARINDEX('fixed',l.[Loan Plan Description],1) > 0
		THEN 'Fixed'
		WHEN l.[Loan Plan Description] like 'Home Buyer Advantage%'
		THEN 'Fixed'
		WHEN l.[Loan Plan Description] like '%HELoan%'
		THEN 'Fixed'
		WHEN l.[Loan Plan Description] like '%VA IRRRL 30yr%'
		THEN 'Fixed'
		WHEN l.[Loan Plan Description] like 'No Product Available'
		THEN 'Fixed'
		WHEN l.[Loan Plan Description] like '%12 Month Construction 2X Close%'
		THEN 'DAILY'
		WHEN terms.AMORTTYPE = 3
		THEN 'AdjustableRate'
		ELSE (CASE WHEN terms.AMORTTYPE = 1 THEN 'Fixed' END)
		END as 'LoanAmortizationType'
	--Required
	--LoanPurpose
	--, l.[Loan Purpose Code] 'LoanPurposeCode'
	, CASE WHEN (l.[Loan Purpose Description]) like '%Refi%' or (l.[Loan Purpose Description]) like '%IRRRL%'
		THEN 'Refinance'
		WHEN (l.[Loan Purpose Description]) like '%Const Perm - Purchase%'
		THEN 'Purchase'
		ELSE l.[Loan Purpose Description]
		end as 'LoanPurposeType'
	
	--Required
	, CASE WHEN l.[Mortgage Applied For] is NULL and l.[Loan Plan Number] = 4000
		THEN 'USDA'
		ELSE l.[Mortgage Applied For]
		END 'LoanType'

	--Required
	--, l.[Occupancy Code] 
	, CASE WHEN l.[Occupancy Description] = 'Owner Occupied'
		THEN 'PrimaryResidence'
		WHEN l.[Occupancy Description] = 'Investment Property'
		THEN 'Investment'
		WHEN l.[Occupancy Description] = 'Second Home'
		THEN 'SecondHome'
		--else l.[Occupancy Description]
		ELSE 'Other'
		END as 'Occupancy'

	--Required
	, lm.[LTV Ratio] 'OriginalLTVRatioPercent'

	--Required
	, l.[Loan Plan Description] 'ProductName' 
	--, lp.[Property Type Description]

	--Required
	--1 Unit; 2-4 Unit; Condominium; Cooperative; Manufactured;  Mixed Use; Planned Unit Development
	,  CASE WHEN lp.[Property Type Description] like 'SFR%' or trans.UUTS_1UNIT = 'Y' -- Detached' or lp.[Property Type Description] = 'SFR Attached'
			THEN 'SingleFamily'
			WHEN lp.[Property Type Description] = 'PUD' or trans.UUTS_PUD = 'Y'
			THEN 'PUD'
			WHEN lp.[Property Type Description] = '3 Unit' or lp.[Property Type Description] = '2 Unit' or lp.[Property Type Description] = '4 Unit' or trans.UUTS_24UNITS = 'Y'
			THEN '2-4 Unit'
			WHEN lp.[Property Type Description] like '%Condo%' or trans.UUTS_CONDO = 'Y'
			-- 'High Rise Condo (9+)' or lp.[Property Type Description] = 'Low-Rise Condo (1-4)' or lp.[Property Type Description] = 'Mid Rise Condo (5-8)' or lp.[Property Type Description] = 'Detached Condo'
			THEN 'Condo'
			WHEN lp.[Property Type Description] = 'Unimproved land/Lot'
			THEN 'Land'
			WHEN lp.[Property Type Description] = 'Townhome'
			THEN 'SingleFamily'
			WHEN lp.[Property Type Description] = 'Modular'
			THEN 'SingleFamily'
			ELSE NULL
		END	as 'PropertyType'


	--Required
	--, 'Fannie Mae;FHA;Freddie Mac;USDA;VA'
	,	CASE WHEN 
			(CASE WHEN l.[Mortgage Applied For] is NULL and l.[Loan Plan Number] = 4000
				THEN 'USDA'
				ELSE l.[Mortgage Applied For] END ) = 'CONVENTIONAL'
		THEN 'Freddie Mac'
		ELSE CASE WHEN l.[Mortgage Applied For] is NULL and l.[Loan Plan Number] = 4000
				THEN 'USDA'
				ELSE l.[Mortgage Applied For] END
		END  'QC_Policy'

	--Required
	, 'F' 'Reverse_Mortgage' 

	--Required
	, UPPER(lp.[Property State]) 'AddressState'
	--------, UPPER(lp.[Property City]) 'AddressCity'
	--------, CASE 
 --------       WHEN LEN(lp.[Property Zip]) > 5 
	--------	THEN LEFT(lp.[Property Zip], 5)
 --------       ELSE lp.[Property Zip]
	--------  END  'AddressZip'
	

	--------Required
	--------Automated, GUS, LoanProductAdvisor, ManuallyUnderwritten
	--------if manual uw_type should be MANUAL
	--------if second then MANUAL
	, CASE 
		WHEN h.UW_TYPE = 1  --Manual 
			or l.[Fannie Mae DU Lien Type] = 2 --HELoan
			or muw.MANUAL_UW_INDIC = 'Y' --Manual
			or [Property Type Description] like '%Unimproved land/Lot%' 
			or l.[Loan Plan Description] like '%HELoan%' 
			or l.[Loan Plan Description] like '%Land Loan Fixed%' 
			or l.[Loan Plan Description] like '12 Month Construction 2X Close' 
			or l.[Loan Plan Description] like '%VA IRRRL%' 
		THEN 'Manually Underwritten'
		WHEN h.UW_TYPE = 2 
			or h.UW_TYPE = 3 
			or l.[Loan Plan Description] like '%Conforming%Fixed%' 
			or c.AUS_RECOMMENDATION_LP is not null
		THEN 'Loan Product Advisor'
		WHEN h.UW_TYPE = 4 or c.AUS_RECOMMENDATION_GUS is not null
		THEN 'GUS'
		ELSE NULL
	  END as 'Underwriting_Type'

	 , UPPER(CASE 
		WHEN lper.[Loan Officer] = 'BROOKE JORDAN'
		THEN 'Brooke Jordan'
		WHEN lper.[Loan Officer] = 'Allison Galant'
		THEN 'Allison Holloway'
		WHEN lper.[Loan Officer] = 'Allison Gallant'
		THEN 'Allison Holloway'
		WHEN lper.[Loan Officer] = 'Brittany Ravenscraft'
		THEN 'Brittany Mealey'
		ELSE lper.[Loan Officer]
		END) as 'LoanOfficerName'
	 ,UPPER(RTRIM(REPLACE(LoanOfficer.Summary, '|', ''))) as 'LoanOfficerEmail'
	 ,UPPER(RTRIM(REPLACE(LoanOfficer.Summary, '|', ''))) as 'LoanOfficerAddressCode'
	 --, LoanOfficer.ReportsToName 'LoanOfficerAORManager'
	 --,REPLACE(LEFT(LoanOfficer.ReportsToName, CHARINDEX(' ', LoanOfficer.ReportsToName) - 1) + ' ' + 
		--RIGHT(LoanOfficer.ReportsToName, LEN(LoanOfficer.ReportsToName) - CHARINDEX('.', LoanOfficer.ReportsToName)),'  ',' ') as 
	, UPPER(CASE 
        WHEN CHARINDEX('.', LoanOfficer.ReportsToName) > 0 THEN
            LEFT(LoanOfficer.ReportsToName, CHARINDEX(' ', LoanOfficer.ReportsToName) - 1) + ' ' + 
            RIGHT(LoanOfficer.ReportsToName, LEN(LoanOfficer.ReportsToName) - CHARINDEX('.', LoanOfficer.ReportsToName) - 1)
        ELSE
            LoanOfficer.ReportsToName
		END) AS'LoanOfficerAORManager'
	 , UPPER(CASE WHEN LoanOfficer.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(LnOfficerMgr.Summary, '|', '')) 
		END) as 'LoanOfficerAORManagerEmail'
	 , UPPER(CASE WHEN LoanOfficer.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(LnOfficerMgr.Summary, '|', '')) 
		END) as 'LoanOfficerManagerAddressCode'

	 ,UPPER(lper.[Funder]) 'FunderName'
	 ,UPPER(RTRIM(REPLACE(Funder.Summary, '|', ''))) as 'FunderEmail'
	 ,UPPER(RTRIM(REPLACE(Funder.Summary, '|', ''))) as 'FunderAddressCode'
	 --,Funder.ReportsToName 'FunderAORManager'
	 --,REPLACE(LEFT(Funder.ReportsToName, CHARINDEX(' ', Funder.ReportsToName) - 1) + ' ' + 
		--RIGHT(Funder.ReportsToName, LEN(Funder.ReportsToName) - CHARINDEX('.', Funder.ReportsToName)),'  ',' ') as 
		, UPPER(CASE 
        WHEN CHARINDEX('.', Funder.ReportsToName) > 0 THEN
            LEFT(Funder.ReportsToName, CHARINDEX(' ', Funder.ReportsToName) - 1) + ' ' + 
            RIGHT(Funder.ReportsToName, LEN(Funder.ReportsToName) - CHARINDEX('.', Funder.ReportsToName) - 1)
        ELSE
            Funder.ReportsToName
		END) AS'FunderAORManager'
	 , UPPER(CASE WHEN Funder.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(FunderMgr.Summary, '|', '')) 
		END) as 'FunderAORManagerEmail'
	 , UPPER(CASE WHEN Funder.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(FunderMgr.Summary, '|', '')) 
		END) as 'FunderManagerAddressCode'

	 , UPPER(CASE 
		WHEN lper.Underwriter like 'Victor Alvarez%'
		THEN 'Victor Alvarez'
		WHEN lper.Underwriter like 'Janice Mckinnon%'
		THEN 'Janice McKinnon'
		else lper.Underwriter
		end) as'UnderwriterName'
	 ,UPPER(CASE WHEN lper.Underwriter like 'ANGIE FAVRE'
		THEN 'ANGIE.FAVRE@KFCU.ORG'
		ELSE RTRIM(REPLACE(Underwriter.Summary, '|', ''))
		END) as 'UnderwriterEmail'
	 ,UPPER(CASE WHEN lper.Underwriter like 'ANGIE FAVRE'
		THEN 'ANGIE.FAVRE@KFCU.ORG'
		ELSE RTRIM(REPLACE(Underwriter.Summary, '|', ''))
		END) as 'UnderwriterAddressCode'
	 --,Underwriter.ReportsToName 'UnderwriterAORManager'
	 --,REPLACE(LEFT(Underwriter.ReportsToName, CHARINDEX(' ', Underwriter.ReportsToName) - 1) + ' ' + 
		--RIGHT(Underwriter.ReportsToName, LEN(Underwriter.ReportsToName) - CHARINDEX('.', Underwriter.ReportsToName)),'  ',' ')
	, UPPER(CASE 
        WHEN CHARINDEX('.', Underwriter.ReportsToName) > 0 THEN
            LEFT(Underwriter.ReportsToName, CHARINDEX(' ', Underwriter.ReportsToName) - 1) + ' ' + 
            RIGHT(Underwriter.ReportsToName, LEN(Underwriter.ReportsToName) - CHARINDEX('.', Underwriter.ReportsToName) - 1)
        ELSE
            Underwriter.ReportsToName
		END) as 'UnderwriterAORManager'
	 ,UPPER(RTRIM(REPLACE(UnderwriterMgr.Summary, '|', ''))) as 'UnderwriterAORManagerEmail'
	 ,UPPER(RTRIM(REPLACE(UnderwriterMgr.Summary, '|', ''))) as 'UnderwriterManagerAddressCode'

	 ,UPPER(lper.[Closer Name]) 'CloserName'
	 ,UPPER(RTRIM(REPLACE(Closer.Summary, '|', ''))) as 'CloserEmail'
	 ,UPPER(RTRIM(REPLACE(Closer.Summary, '|', ''))) as 'CloserAddressCode'
	 --,Closer.ReportsToName 'CloserAORManager'
	 --,REPLACE(LEFT(Closer.ReportsToName, CHARINDEX(' ', Closer.ReportsToName) - 1) + ' ' + 
		--RIGHT(Closer.ReportsToName, LEN(Closer.ReportsToName) - CHARINDEX('.', Closer.ReportsToName)),'  ',' ') as 'CloserAORManager'
	, UPPER(CASE 
        WHEN CHARINDEX('.', Closer.ReportsToName) > 0 THEN
            LEFT(Closer.ReportsToName, CHARINDEX(' ', Closer.ReportsToName) - 1) + ' ' + 
            RIGHT(Closer.ReportsToName, LEN(Closer.ReportsToName) - CHARINDEX('.', Closer.ReportsToName) - 1)
        ELSE
            Closer.ReportsToName
		END) AS 'CloserAORManager'
	 ,UPPER(CASE WHEN Closer.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(CloserMgr.Summary, '|', '')) 
		END) as 'CloserAORManagerEmail'
	 ,UPPER(CASE WHEN Closer.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(CloserMgr.Summary, '|', '')) 
		END) as 'CloserAORManagerAddressCode'

	 ,UPPER(CASE 
		WHEN lper.[Processor] = 'CARLY OWEN'
		THEN 'Carly Morgan'
		WHEN lper.[Processor] = 'ALESHA JONES'
		THEN 'Alesha Shaw'
		WHEN lper.[Processor] = 'Allison Gallant'
		THEN 'Allison Holloway'
		ELSE lper.[Processor]
		END) 'ProcessorName'
	 --,RTRIM(REPLACE(Processor.Summary, '|', '')) as 'ProcessorEmail'
	 --,RTRIM(REPLACE(Processor.Summary, '|', '')) as 'ProcessorAddressCode'
	 ,UPPER(CASE WHEN lper.Processor like 'RUTHIE BEACH'
		THEN 'ruthie.beach@kfcu.org'
		WHEN lper.Processor like 'CARLY OWEN'
		THEN 'carly.morgan@kfcu.org'
		ELSE RTRIM(REPLACE(Processor.Summary, '|', ''))
		END) as 'ProcessorEmail'
	 ,UPPER(CASE WHEN lper.Processor like 'RUTHIE BEACH'
		THEN 'ruthie.beach@kfcu.org'
		WHEN lper.Processor like 'CARLY OWEN'
		THEN 'carly.morgan@kfcu.org'
		ELSE RTRIM(REPLACE(Processor.Summary, '|', ''))
		END) as 'ProcessorAddressCode'
	-- ,Processor.ReportsToName 'ProcessorAORManager'
	 --	,REPLACE(LEFT(Processor.ReportsToName, CHARINDEX(' ', Processor.ReportsToName) - 1) + ' ' + 
		--RIGHT(Processor.ReportsToName, LEN(Processor.ReportsToName) - CHARINDEX('.', Processor.ReportsToName)),'  ',' ')
	, UPPER(CASE 
        WHEN CHARINDEX('.', Processor.ReportsToName) > 0 THEN
            LEFT(Processor.ReportsToName, CHARINDEX(' ', Processor.ReportsToName) - 1) + ' ' + 
            RIGHT(Processor.ReportsToName, LEN(Processor.ReportsToName) - CHARINDEX('.', Processor.ReportsToName) - 1)
        ELSE
            Processor.ReportsToName
		END) AS 'ProcessorAORManager'
	 ,UPPER(CASE WHEN Processor.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(ProcessorMgr.Summary, '|', '')) 
		END) as 'ProcessorAORManagerEmail'
	 ,UPPER(CASE WHEN Processor.ReportsToName like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE RTRIM(REPLACE(ProcessorMgr.Summary, '|', '')) 
		END) as 'ProcessorManagerAddressCode'

	--PostCloser is retrieved differently, see join
	 ,PostCloser 'PostCloserName'
	 ,PostCloserEmail 'PostCloserEmail'
	 ,PostCloserEmail 'PostCloserAddressCode'
	 --,PostCloserMgr 'PostCloserAORManager'
	-- ,REPLACE(LEFT(PostCloserMgr, CHARINDEX(' ', PostCloserMgr) - 1) + ' ' + 
	--	RIGHT(PostCloserMgr, LEN(PostCloserMgr) - CHARINDEX('.', PostCloserMgr)),'  ', ' ')
	, UPPER(CASE 
        WHEN CHARINDEX('.', PostCloserMgr) > 0 THEN
            LEFT(PostCloserMgr, CHARINDEX(' ', PostCloserMgr) - 1) + ' ' + 
            RIGHT(PostCloserMgr, LEN(PostCloserMgr) - CHARINDEX('.', PostCloserMgr) - 1)
        ELSE
            PostCloserMgr
		END) AS 'PostCloserAORManager'
	 ,UPPER(CASE WHEN PostCloserMgr like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE PostCloserMgrEmail
		END) as 'PostCloserManagerEmail'
	 ,UPPER(CASE WHEN PostCloserMgr like 'Carrie Graetz'
		THEN 'carrie.graetz@kfcu.org'
		ELSE PostCloserMgrEmail
		END) as 'PostCloserManagerAddressCode'

	--, lper.Funder 'FunderName'
	--, lper.Underwriter 'UnderwriterName'
	--, lper.[Closer Name] 'CloserName'
	--, lper.Processor 'ProcessorName'




		--Required
	, CASE WHEN b.[Borrower Last Name] is not null and SUBSTRING(b.[Borrower ID], CHARINDEX('.', b.[Borrower ID]) + 1, LEN(b.[Borrower ID]) - CHARINDEX('.', b.[Borrower ID])) = 1
		THEN UPPER(b.[Borrower Last Name])
		END 'LastNameBorrower1'
	--, CASE WHEN b.[Borrower Last Name] is not null and SUBSTRING(b.[Borrower ID], CHARINDEX('.', b.[Borrower ID]) + 1, LEN(b.[Borrower ID]) - CHARINDEX('.', b.[Borrower ID])) = 1
	--	THEN UPPER(b.[Borrower First Name])
	--	END as 'FirstNameBorrower1'
	--, CASE WHEN b.[Borrower Last Name] is not null and SUBSTRING(b.[Borrower ID], CHARINDEX('.', b.[Borrower ID]) + 1, LEN(b.[Borrower ID]) - CHARINDEX('.', b.[Borrower ID])) = 1
	--	THEN UPPER(b.[Borrower Middle Name])
	--	END as 'MiddleInitialBorrower1'

	, CASE WHEN b2.[Borrower Last Name] is not null and SUBSTRING(b2.[Borrower ID], CHARINDEX('.', b2.[Borrower ID]) + 1, LEN(b2.[Borrower ID]) - CHARINDEX('.', b2.[Borrower ID])) = 2
		THEN UPPER(b2.[Borrower Last Name])
		END 'LastNameBorrower2'
	, CASE WHEN b3.[Borrower Last Name] is not null and SUBSTRING(b3.[Borrower ID], CHARINDEX('.', b3.[Borrower ID]) + 1, LEN(b3.[Borrower ID]) - CHARINDEX('.', b3.[Borrower ID])) = 3
		THEN UPPER(b3.[Borrower Last Name])
		END 'LastNameBorrower3'
	, CASE WHEN b4.[Borrower Last Name] is not null and SUBSTRING(b4.[Borrower ID], CHARINDEX('.', b4.[Borrower ID]) + 1, LEN(b4.[Borrower ID]) - CHARINDEX('.', b4.[Borrower ID])) = 4
		THEN UPPER(b4.[Borrower Last Name])
		END 'LastNameBorrower4'
	, CASE WHEN b5.[Borrower Last Name] is not null and SUBSTRING(b5.[Borrower ID], CHARINDEX('.', b5.[Borrower ID]) + 1, LEN(b5.[Borrower ID]) - CHARINDEX('.', b5.[Borrower ID])) = 5
		THEN UPPER(b5.[Borrower Last Name])
		END 'LastNameBorrower5'
	, CASE WHEN b6.[Borrower Last Name] is not null and SUBSTRING(b6.[Borrower ID], CHARINDEX('.', b6.[Borrower ID]) + 1, LEN(b6.[Borrower ID]) - CHARINDEX('.', b6.[Borrower ID])) = 6
		THEN UPPER(b6.[Borrower Last Name])
		END 'LastNameBorrower6'
	, CASE WHEN b7.[Borrower Last Name] is not null and SUBSTRING(b7.[Borrower ID], CHARINDEX('.', b7.[Borrower ID]) + 1, LEN(b7.[Borrower ID]) - CHARINDEX('.', b7.[Borrower ID])) = 7
		THEN UPPER(b7.[Borrower Last Name])
		END 'LastNameBorrower7'
	, CASE WHEN b8.[Borrower Last Name] is not null and SUBSTRING(b8.[Borrower ID], CHARINDEX('.', b8.[Borrower ID]) + 1, LEN(b8.[Borrower ID]) - CHARINDEX('.', b8.[Borrower ID])) = 8
		THEN UPPER(b8.[Borrower Last Name])
		END 'LastNameBorrower8'

FROM
	[VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOAN] l
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b
		ON l.[Loan Number] = b.[Loan Number]
			--and b.[Borrower Last Name] is not null
		and SUBSTRING(b.[Borrower ID], CHARINDEX('.', b.[Borrower ID]) + 1, LEN(b.[Borrower ID]) - CHARINDEX('.', b.[Borrower ID])) = 1

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b2 
		ON l.[Loan Number] = b2.[Loan Number]
		and SUBSTRING(b2.[Borrower ID], CHARINDEX('.', b2.[Borrower ID]) + 1, LEN(b2.[Borrower ID]) - CHARINDEX('.', b2.[Borrower ID])) = 2

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b3
		ON l.[Loan Number] = b3.[Loan Number]
		and SUBSTRING(b3.[Borrower ID], CHARINDEX('.', b3.[Borrower ID]) + 1, LEN(b3.[Borrower ID]) - CHARINDEX('.', b3.[Borrower ID])) = 3

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b4
		ON l.[Loan Number] = b4.[Loan Number]
		and SUBSTRING(b4.[Borrower ID], CHARINDEX('.', b4.[Borrower ID]) + 1, LEN(b4.[Borrower ID]) - CHARINDEX('.', b4.[Borrower ID])) = 4

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b5
		ON l.[Loan Number] = b5.[Loan Number]
		and SUBSTRING(b5.[Borrower ID], CHARINDEX('.', b5.[Borrower ID]) + 1, LEN(b5.[Borrower ID]) - CHARINDEX('.', b5.[Borrower ID])) = 5

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b6
		ON l.[Loan Number] = b6.[Loan Number]
		and SUBSTRING(b6.[Borrower ID], CHARINDEX('.', b6.[Borrower ID]) + 1, LEN(b6.[Borrower ID]) - CHARINDEX('.', b6.[Borrower ID])) = 6

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b7
		ON l.[Loan Number] = b7.[Loan Number]
		and SUBSTRING(b7.[Borrower ID], CHARINDEX('.', b7.[Borrower ID]) + 1, LEN(b7.[Borrower ID]) - CHARINDEX('.', b7.[Borrower ID])) = 7

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_BORROWER] b8
		ON l.[Loan Number] = b8.[Loan Number]
		and SUBSTRING(b8.[Borrower ID], CHARINDEX('.', b8.[Borrower ID]) + 1, LEN(b8.[Borrower ID]) - CHARINDEX('.', b8.[Borrower ID])) = 8

	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANDATE] ld 
		ON l.[Loan Number] = ld.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].EMPOWER_DIM.ODS_STG_LOANDATE lsd	
		on l.[Loan Number] = lsd.LOAN_ID
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANPROPERTY] lp
		ON l.[Loan Number] = lp.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANPERSONNEL] lper
		ON l.[Loan Number] = lper.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_REPORTING].[ODS_VW_STG_LOANMEASURES] lm
		ON l.[Loan Number] = lm.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].Empower_WK.LN_UW_HISTORY h
	   ON l.[Loan Number] = h.LNKEY
		and h.IDX in (select MAX(IDX) from [VSODSDB01].[EMPOWERODS].Empower_WK.LN_UW_HISTORY h2 where h2.LNKEY=h.LNKEY)
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[Empower_WK].LN_UNDERWRITING_DECISION ud
		ON ud.LNKEY = l.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_PROPINFO] p
		ON l.[Loan Number] = p.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_FRAUDGUARD] f
		ON l.[Loan Number] = f.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_DOCGEN] dg
		ON l.[Loan Number] = dg.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_MTGTERMS] mtg
		ON l.[Loan Number] = mtg.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_REALEC] r
		ON l.[Loan Number] = r.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_TRANSUMM] tr
		on l.[Loan Number] = tr.LNKEY
	LEFT  JOIN [VSODSDB01].[EMPOWERODS].EMPOWER_WK.LN_STATUS ls
		on l.[Loan Number] = ls.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_UNDERWRITING_DECISION] ctc
		on ctc.LNKEY = l.[Loan Number]
			and ctc.LAST_DECISION like '%Clear to Close%' 
	LEFT JOIN (SELECT [LNKEY],EVENTNUM,[DATES]
				FROM [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_EVENTS]
				where lnkey in (select lnkey from [VSODSDB01].[EMPOWERODS].empower_wk.LN_UNDERWRITING_DECISION where LAST_DECISION = 'Withdrawn' or LAST_DECISION = 'Withdrawn Request') and lnkey in (select h.lnkey from  [VSODSDB01].[EMPOWERODS].EMPOWER_WK.LN_UNDERWRITING_DECISION d left join [VSODSDB01].[EMPOWERODS].empower_wk.LN_UW_HISTORY h on d.lnkey = h.lnkey where h.UW_DECISION = 'Withdrawn')
				and descrip = 'Withdrawn') withdrawn
		on withdrawn.lnkey = l.[Loan Number]
	LEFT JOIN (
				SELECT distinct h.[LNKEY]
				  ,max([DECISION_DATE]) 'Denied Date'
				  ,max(d.LAST_DECISION) 'last_decision'
				FROM [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_UW_HISTORY] h
				left join [VSODSDB01].[EMPOWERODS].EMPOWER_WK.LN_UNDERWRITING_DECISION d 
					on h.lnkey = d.lnkey and (d.LAST_DECISION = 'Denied' or d.LAST_DECISION = 'Denied - Second Signer' or d.LAST_DECISION = 'ECOA Denied' or d.LAST_DECISION = 'Prequalified Denied' or d.LAST_DECISION = 'Denied - First Signer') 
				where LAST_DECISION is not null and LAST_DECISION = UW_DECISION
				group by h.lnkey
				) denied
		on denied.lnkey = l.[Loan Number]

	--LEFT JOIN EMPOWER_WK.LN_CURREMPL emp
	--	on emp.LNKEY = l.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_ULDD_CLOSING_MOD] muw
		on muw.LNKEY = l.[Loan Number]
			and muw.MANUAL_UW_INDIC = 'Y'
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_MTGTERMS] terms
		on terms.LNKEY = l.[Loan Number]
	--LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_CREDITLINES] credline
	--	on credline.LNKEY = l.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_REGULAT] lreg
		ON l.[Loan Number] = lreg.LNKEY
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_REGULAT_CREDITDEC_SNAPSHOT] c
		ON c.LNKEY = l.[Loan Number]
	LEFT JOIN [VSODSDB01].[EMPOWERODS].[EMPOWER_WK].[LN_TRANSUMM] trans
		on trans.LNKEY = l.[Loan Number]

	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage LoanOfficer
		on  (CASE 
				WHEN lper.[Loan Officer] = 'ALAN ALLRED'
				THEN 'James Allred'
				WHEN lper.[Loan Officer] = 'Brittany Ravenscraft'
				THEN 'Brittany Mealey'
				WHEN lper.[Loan Officer] = 'Allison Gallant'
				THEN 'Allison Holloway'
				WHEN lper.[Loan Officer] = 'Allison Galant'
				THEN 'Allison Holloway'
				ELSE REPLACE(lper.[Loan Officer],'-', ' ')
				END
			) like REPLACE(CONCAT('%',LoanOfficer.FirstName, '%', LoanOfficer.LastName,'%'), '-', ' ')
		and LoanOfficer.status ='Active'
		and	LoanOfficer.processdate = @latestProcessDate
	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage LnOfficerMgr
		on (CASE 
				WHEN CHARINDEX(' ', LoanOfficer.ReportsToName) > 0 
				THEN LEFT(LoanOfficer.ReportsToName, CHARINDEX(' ', LoanOfficer.ReportsToName) - 1) 
				ELSE LoanOfficer.ReportsToName 
				END) like LnOfficerMgr.FirstName
			and RIGHT(LoanOfficer.ReportsToName, LEN(LoanOfficer.ReportsToName) - CHARINDEX(' ', LoanOfficer.ReportsToName, CHARINDEX(' ', LoanOfficer.ReportsToName) + 1)) like LnOfficerMgr.LastName
			
			and LnOfficerMgr.status ='Active'
			and	LnOfficerMgr.processdate = @latestProcessDate
	--		, lper.[Loan Officer] 'LoanOfficerName'

	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage Funder
		on  
			(CASE 
				WHEN lper.[Funder] = 'ALAN ALLRED'
				THEN 'James Allred'
				ELSE REPLACE(lper.[Funder],'-', ' ')
				END
			) like REPLACE(CONCAT('%',Funder.FirstName, '%', Funder.LastName,'%'), '-', ' ')
		and Funder.status ='Active'
		and	Funder.processdate = @latestProcessDate
	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage FunderMgr
		on (CASE 
				WHEN CHARINDEX(' ', Funder.ReportsToName) > 0 
				THEN LEFT(Funder.ReportsToName, CHARINDEX(' ', Funder.ReportsToName) - 1) 
				ELSE Funder.ReportsToName 
				END) like FunderMgr.FirstName
			and RIGHT(Funder.ReportsToName, LEN(Funder.ReportsToName) - CHARINDEX(' ', Funder.ReportsToName, CHARINDEX(' ', Funder.ReportsToName) + 1)) like FunderMgr.LastName
			and LnOfficerMgr.status ='Active'
			and	LnOfficerMgr.processdate = @latestProcessDate
			--, lper.Funder 'FunderName'

	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage Underwriter
		on  
			(CASE 
				WHEN lper.Underwriter = 'ALAN ALLRED'
				THEN 'James Allred'
				WHEN lper.Underwriter like 'VICTOR ALVAREZ%'
				THEN 'VICTOR ALVAREZ'
				WHEN lper.Underwriter like 'JANICE MCKINNON%'
				THEN 'JANICE MCKINNON'
				ELSE REPLACE(lper.Underwriter,'-', ' ')
				END
			) like REPLACE(CONCAT('%',Underwriter.FirstName, '%', Underwriter.LastName,'%'), '-', ' ')
		and Underwriter.status ='Active'
		and	Underwriter.processdate = @latestProcessDate
	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage UnderWriterMgr
		on (CASE 
				WHEN CHARINDEX(' ', Underwriter.ReportsToName) > 0 
				THEN LEFT(Underwriter.ReportsToName, CHARINDEX(' ', Underwriter.ReportsToName) - 1) 
				ELSE Underwriter.ReportsToName 
				END) like UnderWriterMgr.FirstName
			and RIGHT(Underwriter.ReportsToName, LEN(Underwriter.ReportsToName) - CHARINDEX(' ', Underwriter.ReportsToName, CHARINDEX(' ', Underwriter.ReportsToName) + 1)) like UnderWriterMgr.LastName
			and UnderWriterMgr.status ='Active'
			and	UnderWriterMgr.processdate = @latestProcessDate
			--, lper.Underwriter 'UnderwriterName'

	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage Closer
		on  
			(CASE 
				WHEN lper.[Closer Name] = 'ALAN ALLRED'
				THEN 'James Allred'
				ELSE REPLACE(lper.[Closer Name],'-', ' ')
				END
			) like REPLACE(CONCAT('%',Closer.FirstName, '%', Closer.LastName,'%'), '-', ' ')
		and Closer.status ='Active'
		and	Closer.processdate = @latestProcessDate
	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage CloserMgr
		on (CASE 
				WHEN CHARINDEX(' ', Closer.ReportsToName) > 0 
				THEN LEFT(Closer.ReportsToName, CHARINDEX(' ', Closer.ReportsToName) - 1) 
				ELSE Closer.ReportsToName 
				END) like CloserMgr.FirstName
			and RIGHT(Closer.ReportsToName, LEN(Closer.ReportsToName) - CHARINDEX(' ', Closer.ReportsToName, CHARINDEX(' ', Closer.ReportsToName) + 1)) like CloserMgr.LastName
			and CloserMgr.status ='Active'
			and	CloserMgr.processdate = @latestProcessDate
			--, lper.[Closer Name] 'CloserName'

	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage Processor
		on  
			(CASE 
				WHEN lper.Processor = 'ALAN ALLRED'
				THEN 'James Allred'
				WHEN lper.Processor = 'RUTHIE BEACH'
				THEN 'Stavroula Beach'
				WHEN lper.Processor = 'CARLY OWEN'
				THEN 'Carly Morgan'
				WHEN lper.Processor = 'ALESHA JONES'
				THEN 'Alesha Shaw'
				WHEN lper.Processor = 'Allison Gallant'
				THEN 'Allison Holloway'
				ELSE REPLACE(lper.Processor,'-', ' ')
				END
			) like REPLACE(CONCAT('%',Processor.FirstName, '%', Processor.LastName,'%'), '-', ' ')
		and Processor.status ='Active'
		and	Processor.processdate = @latestProcessDate
	LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage ProcessorMgr
		on (CASE 
				WHEN CHARINDEX(' ', Processor.ReportsToName) > 0 
				THEN LEFT(Processor.ReportsToName, CHARINDEX(' ', Processor.ReportsToName) - 1) 
				ELSE Processor.ReportsToName 
				END) like ProcessorMgr.FirstName
			and RIGHT(Processor.ReportsToName, LEN(Processor.ReportsToName) - CHARINDEX(' ', Processor.ReportsToName, CHARINDEX(' ', Processor.ReportsToName) + 1)) like ProcessorMgr.LastName
			and ProcessorMgr.status ='Active'
			and	ProcessorMgr.processdate = @latestProcessDate
	--, lper.Processor 'ProcessorName'
	LEFT JOIN (
				--DECLARE @latestProcessDate INT = (SELECT max(ProcessDate) FROM VSARCU02.cfsconnectors.cu.EAUltiproStage);
				select 
					lnCon.LnKey
					,CONCAT(ultipro.Firstname,' ', ultipro.LastName) PostCloser
					,RTRIM(REPLACE(ultipro.summary, '|', '')) PostCloserEmail
					,ultipro.ReportsToName PostCloserMgr
					,RTRIM(REPLACE(PostCloserMgr.Summary, '|', '')) PostCloserMgrEmail
				from VSODSDB01.[EmpowerODS].[EMPOWER_WK].[LN_CONTACTS] lnCon
				inner join VSARCU02.cfsconnectors.cu.EAUltiproStage ultipro
					on	(   
							LEFT(lnCon.Post_Closer_Userid, CHARINDEX('.', lnCon.Post_Closer_Userid) - 1)
						) like REPLACE(CONCAT('%',ultipro.FirstName, '%'), '-', ' ')

						and		(
									SUBSTRING(lnCon.Post_Closer_Userid, CHARINDEX('.', lnCon.Post_Closer_Userid) + 1, LEN(lnCon.Post_Closer_Userid))
								) like REPLACE(CONCAT('%',ultipro.LastName, '%'), '-', ' ')
						and ultipro.status ='Active'
						and	ultipro.processdate = @latestProcessDate
				LEFT JOIN VSARCU02.cfsconnectors.cu.EAUltiproStage PostCloserMgr
					on	(	CASE 
								WHEN CHARINDEX(' ', ultipro.ReportsToName) > 0 
								THEN LEFT(ultipro.ReportsToName, CHARINDEX(' ', ultipro.ReportsToName) - 1) 
								ELSE ultipro.ReportsToName 
								END
							) like PostCloserMgr.FirstName
						and RIGHT(ultipro.ReportsToName, LEN(ultipro.ReportsToName) - CHARINDEX(' ', ultipro.ReportsToName, CHARINDEX(' ', ultipro.ReportsToName) + 1)) like PostCloserMgr.LastName
						and PostCloserMgr.status ='Active'
						and	PostCloserMgr.processdate = @latestProcessDate
				) PostCloser 
					on PostCloser.LNKEY = l.[Loan Number]


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


----STANDARD FIELDS QUERY
select 
*
from
standFields
where loannumber is not null
and loanstatus is not null
and loanstatusdate is not null
and LoanStatus not like 'Uncategorized'
and LoanStatus not like 'In-Progress'
and LoanStatus not like 'HMDA%'

and LoanStatus = '{parameter}'

order by 
LoanStatus, EmpowerLoanStatus, 
LoanNumber





*This dofile performs bibliometric analysis on the Scopus and WOS (Web Of Science) data for the topic: Measurement gap between objective and perceived risk.
*Author: Emanuele Clemnte (emanuele.clemente@uniba.it)

**# SCOPUS query TITLE-ABS-KEY((("objective risk" OR "actual risk") AND ("perceived risk" OR "subjective risk")))

*Process citations file 
qui import delimited "${gsdDataRaw}\Scopus\Objective_actual_subjective_perceived\CitationOverview.csv", varnames(7) clear
keeporder publicationyear documenttitle issn journaltitle volume issue v8-v33 v36
local year 1999
forval i=8/33 {
	qui rename v`i' year_`year'
	qui replace year_`year'=. if `year' < publicationyear
	local year=`year'+1
}
egen AverageperYear=rowmean(year_*)
rename v36 TotalCitations 
clonevar title=documenttitle
recast str title
duplicates drop title, force
qui save "${gsdTemp}/citations_oasp_scopus.dta", replace 

*Process literature file 
qui import delimited "${gsdDataRaw}\Scopus\Objective_actual_subjective_perceived\scopus.csv", clear 
rename source database
recast str title
duplicates drop title, force
merge 1:1 title using "${gsdTemp}/citations_oasp_scopus.dta", keepusing(TotalCitations AverageperYear) nogen keep(1 3)
qui save "${gsdTemp}/literature_oasp_scopus.dta", replace 

**# WOS query TS=(("objective risk" OR "actual risk") AND ("perceived risk" OR "subjective risk"))

*Process citations file 
qui import excel "${gsdDataRaw}\WOS\Objective_actual_subjective_perceived\\citations.xlsx", sheet("savedrecs") firstrow clear cellrange(A11:BI340)
clonevar ArticleTitle=Title
duplicates drop *, force
duplicates drop  ArticleTitle, force
qui save "${gsdTemp}/citations_oasp_wos.dta", replace 

*Process literature file 
qui import excel "${gsdDataRaw}\WOS\Objective_actual_subjective_perceived\savedrecs.xls", sheet("savedrecs") firstrow clear 
duplicates drop *, force
duplicates drop  ArticleTitle, force
merge 1:1 ArticleTitle using "${gsdTemp}/citations_oasp_wos.dta", keep(1 3) nogen //import additional info from citations
rename (Affiliations Volume Issue DOI) (affiliations volume issue doi)
qui save "${gsdTemp}/literature_oasp_wos.dta", replace 

**# Combine results from two sources 
use "${gsdTemp}/literature_oasp_scopus.dta", clear 
append using "${gsdTemp}/literature_oasp_wos.dta"
qui replace database="WOS" if mi(database)
qui replace title=Title if mi(title) & !mi(Title)
qui replace citedby=TotalCitations if mi(citedby) & !mi(TotalCitations)
qui replace authors=Authors if mi(authors) & !mi(Authors)
qui replace year=PublicationYear if mi(year) & !mi(PublicationYear)
qui replace authorkeywords=authorkeywords+";"+AuthorKeywords+";"+indexkeywords+";"+KeywordsPlus
qui replace sourcetitle=SourceTitle if mi(sourcetitle) & !mi(SourceTitle)
qui replace abstract=Abstract if mi(abstract) & !mi(Abstract)

*Some publications may duplicate between the scopus and web of science results
qui replace title = subinstr(title, "à" , "A" , .)
qui replace title=strupper(strtrim(title))
qui replace doi=strupper(strtrim(doi))
qui replace authorkeywords=strupper(strtrim(authorkeywords))
qui duplicates tag title,gen (dup_title) 
qui duplicates tag doi,gen (dup_doi) 
sort title
qui drop if dup_title>0 & !mi(dup_title) & database=="WOS"
qui drop if dup_doi>0 & !mi(dup_doi) & !mi(doi) & database=="WOS"
drop Title- dup_doi

*Drop if citations are missing (that's the ranking criterion)
drop if mi(TotalCitations)

gsort -TotalCitations
br title year database AverageperYear TotalCitations
qui export delimited using "${gsdOutput}/\biblio.csv", replace

*Retain papers concerning climate issues 
keep if regexm(title,"flood|drought|dry spell|dryspell|emergency|seism") | regexm(authorkeywords, "flood|drought|dry spell|dryspell|emergency|seism") | regexm(abstract,"flood|drought|dry spell|dryspell|emergency|seism")

drop Authors BookAuthors BookGroupAuthors AuthorFullNames BookAuthorFullNames GroupAuthors AuthorKeywords //Affiliations Volume Issue DOILink BookDOI
qui export delimited using "${gsdOutput}/\biblio_restricted.csv", replace

*For ranking the top 20 papers, either use 1) total number of citations, 2) average number of yearly citations, 3) a weighted average of the normalized 1) and 2):
norm AverageperYear TotalCitations, method(mmx)
gen citation_score=(.5*mmx_AverageperYear)+(.5*mmx_TotalCitations)
gsort -citation_score
gen n=_n 
sort n
keep if n<21 //retain top 20 papers (if available)
br title year AverageperYear TotalCitations citation_score authors

**# Add h-index for first author of each top-20 paper (source: WOS)
gen h_index=22 if title=="ACTUAL VIS-A-VIS PERCEIVED RISK OF FLOOD PRONE URBAN COMMUNITIES IN PAKISTAN" 
replace h_index=9 if title=="RISK PERCEPTION, EXPERIENCE, AND OBJECTIVE RISK: A CROSS-NATIONAL STUDY WITH EUROPEAN EMERGENCY SURVIVORS" 
replace h_index=4 if title=="EMPIRICAL ANALYSIS OF FARMERS' DROUGHT RISK PERCEPTION: OBJECTIVE FACTORS, PERSONAL CIRCUMSTANCES, AND SOCIAL INFLUENCE" 
replace h_index=14 if title=="HEALTH RISK PERCEPTIONS AND LOCAL KNOWLEDGE OF WATER-RELATED INFECTIOUS DISEASE EXPOSURE AMONG KENYAN WETLAND COMMUNITIES" 
replace h_index=23 if title=="INDIVIDUAL ACTUAL OR PERCEIVED PROPERTY FLOOD RISK: DID IT PREDICT EVACUATION FROM HURRICANE ISABEL IN NORTH CAROLINA, 2003?" 
replace h_index=3 if title=="ASSESSING DISASTER PREPAREDNESS AMONG LATINO MIGRANT AND SEASONAL FARMWORKERS IN EASTERN NORTH CAROLINA" 
replace h_index=2 if title=="RELUCTANCE OF PARAMEDICS AND EMERGENCY MEDICAL TECHNICIANS TO PERFORM MOUTH-TO-MOUTH RESUSCITATION" 
replace h_index=37 if title=="PERCEIVED AND PROJECTED FLOOD RISK AND ADAPTATION IN COASTAL SOUTHEAST QUEENSLAND, AUSTRALIA" 
replace h_index=4 if title=="THE BETTER THE BOND, THE BETTER WE COPE. THE EFFECTS OF PLACE ATTACHMENT INTENSITY AND PLACE ATTACHMENT STYLES ON THE LINK BETWEEN PERCEPTION OF RISK AND EMOTIONAL AND BEHAVIORAL COPING" 
replace h_index=18 if title=="EXPLORING A SPATIAL STATISTICAL APPROACH TO QUANTIFY FLOOD RISK PERCEPTION USING COGNITIVE MAPS" 
replace h_index=6 if title=="GEOGRAPHIC DISTRIBUTIONS OF EXTREME WEATHER RISK PERCEPTIONS IN THE UNITED STATES" 
replace h_index=9 if title=="INSIGHTS INTO FLOOD RISK MISPERCEPTIONS OF HOMEOWNERS IN THE DUTCH RIVER DELTA" 
replace h_index=4 if title=="THE ASSOCIATION BETWEEN ACTUAL AND PERCEIVED FLOOD RISK AND EVACUATION FROM HURRICANE IRENE, BEAUFORT COUNTY, NORTH CAROLINA" 
replace h_index=10 if title=="RISK PERCEPTION AND EMERGENCY EXPERIENCE: COMPARING A REPRESENTATIVE GERMAN SAMPLE WITH GERMAN EMERGENCY SURVIVORS" 
replace h_index=22 if title=="EXPLORING GENDER DIFFERENCES IN PREP INTEREST AMONG INDIVIDUALS TESTING HIV NEGATIVE IN AN URBAN EMERGENCY DEPARTMENT" 
replace h_index=15 if title=="PAST AND FUTURE WATER CONFLICTS IN THE UPPER KLAMATH BASIN: AN ECONOMIC APPRAISAL" 
replace h_index=19 if title=="PERCEIVED AND ACTUAL RISKS OF DROUGHT: HOUSEHOLD AND EXPERT VIEWS FROM THE LOWER TEESTA RIVER BASIN OF NORTHERN BANGLADESH" 
replace h_index=2 if title=="OBJECTIVE AND PERCEIVED RISK IN SEISMIC VULNERABILITY ASSESSMENT AT AN URBAN SCALE" 

**# Add Citescore information for first author of each top-20 paper (source: Scopus)
gen citescore=6.9 if sourcetitle=="European Journal of Marketing" 
replace citescore=10.2 if sourcetitle=="Climatic Change" 
replace citescore=7.7 if sourcetitle=="Preventive Medicine" 
replace citescore=5.7 if sourcetitle=="Risk Analysis" 
replace citescore=8.6 if sourcetitle=="American Journal of Preventive Medicine" 
replace citescore=3.3 if sourcetitle=="Journal of Contemporary Criminal Justice" 
replace citescore=5.8 if sourcetitle=="Journal of Acquired Immune Deficiency Syndromes" 
replace citescore=9.8 if sourcetitle=="Circulation: Cardiovascular Quality and Outcomes" 
replace citescore=3.2 if sourcetitle=="Scandinavian Journal of Primary Health Care" 
replace citescore=4.9 if sourcetitle=="Natural Hazards" 
replace citescore=3.3 if sourcetitle=="Journal of Contemporary Criminal Justice" 
replace citescore=5.8 if sourcetitle=="Journal of Acquired Immune Deficiency Syndromes" 
replace citescore=9.8 if sourcetitle=="Circulation: Cardiovascular Quality and Outcomes" 
replace citescore=3.2 if sourcetitle=="Scandinavian Journal of Primary Health Care" 
replace citescore=4.9 if sourcetitle=="Natural Hazards" 
replace citescore=3.3 if sourcetitle=="Journal of Contemporary Criminal Justice" 
replace citescore=5.8 if sourcetitle=="Journal of Acquired Immune Deficiency Syndromes" 
replace citescore=9.8 if sourcetitle=="Circulation: Cardiovascular Quality and Outcomes" 
replace citescore=3.2 if sourcetitle=="Scandinavian Journal of Primary Health Care" 
replace citescore=4.9 if sourcetitle=="Natural Hazards" 

**# Metrics for tables (as per Scopus info provided by querying the 18 top papers)
qui import delimited "${gsdDataRaw}\Scopus_exported_refine_values.csv", varnames(7) clear

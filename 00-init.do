* ------------------------------------------------------------------
*    
*     This file contains the initialization to run the pipeline
*     for the Bibliometric Project
*                         
*-------------------------------------------------------------------

clear all
set more off
set maxvar 30000
set seed 10051990 

* Define username
global suser = c(username)

* Emanuele (WB laptop)
else if (inlist("${suser}","wb562201", "WB562201")) {
	*Local directory of your project
	local swdLocal = "G:\My Drive\Dottorato UNIBA/Tesi"
	*Box directory where the Raw Data folder can be located (for those who have access to it)
	local swdBox = "G:\My Drive\Dottorato UNIBA/Tesi"
}

* Emanuele (personal laptop)
else if (inlist("${suser}","emanu")) {
	*Local directory of your project
	local swdLocal = "G:\My Drive\Dottorato UNIBA/Tesi"
	*Box directory where the Raw Data folder can be located (for those who have access to it)
	local swdBox = "G:\My Drive\Dottorato UNIBA/Tesi"
}

* Anna
else if (inlist("${suser}","wb355053", "wb355053")) {
	*Local directory of your project
	local swdLocal = "C:\Users\wb355053\OneDrive - WBG\50x2030\50x2030 M&T\Uganda Soil & Climate Methods Study\Uganda EDI - WB"
	*Box directory where the Raw Data folder can be located (for those who have access to it)
	local swdBox = "C:\Users\wb355053\OneDrive - WBG\50x2030\50x2030 M&T\Uganda Soil & Climate Methods Study\Uganda EDI - WB"
}

* Michael
else if (inlist("${suser}","emanu")) {
	*Local directory of your project
	local swdLocal = "G:\My Drive\Dottorato UNIBA/Tesi"
	*Box directory where the Raw Data folder can be located (for those who have access to it)
	local swdBox = "G:\My Drive\Dottorato UNIBA/Tesi"
}


* Any other colleague
else if (inlist("${suser}","machine name of other colleague")) {
	local swdLocal = "/Users/somara/Desktop/K-LSRH"
	//temp
	local swdBox = "/Users/somara/Desktop/K-LSRH"
}

else {
	di as error "Configure work environment in init.do before running the code."
	error 1
}

* Define filepaths
global gsdProject="`swdBox'"
global gsdDataRaw = "`swdBox'/Bibliometric/Data/Raw"
global gsdDo = "`swdLocal'/Bibliometric/Do"
global gsdTemp = "`swdLocal'/Bibliometric/Data/Temp"
global gsdOutput = "`swdLocal'/Bibliometric/Data/Output"

macro list

*If needed, install the directories and packages used in the process 
*If folders don't exist create them
confirmdir "${gsdTemp}"
if  r(confirmdir)=="170" {
	shell mkdir "${gsdTemp}"
}
confirmdir "${gsdOutput}"
if  r(confirmdir)=="170" {
	shell mkdir "${gsdOutput}"
}

*If needed, install the necessary commands and packages 
local commands = "fs matchit freqindex savesome distinct confirmdir cfout readreplace winsor2 svygen mdesc labelmiss _gwtmean estout renvarlab keeporder gtools samplepps copydesc outdetect tabout spmap filelist unique multiline combineplot"
foreach c of local commands {
	qui capture which `c' 
	qui if _rc!=0 {
		noisily di "This command requires '`c''. The package will now be downloaded and installed."
		qui ssc install `c'
	}
}
*Github is required
qui capture which github
qui if _rc!=0 {
	noisily di "This command requires github. The package will now be downloaded and installed."
	net install github, from("https://haghish.github.io/github/")
}

* Andrea Bruckner
  PREDICT 411, Sec 55
  Spring 2016
  Unit 01: Moneyball
;

********************************************************************;
* Preliminary Steps--All Models;
********************************************************************;

* Access library where data sets are stored;

%let PATH = /folders/myfolders/PREDICT_411/Moneyball;
%let NAME = OLS; * This can be anything, I think;
%let LIB = &NAME..;

libname &NAME. "&PATH.";
%let INFILE = &LIB.MONEYBALL;

proc contents data=&INFILE.; run;

proc print data=&INFILE.(obs=10);
run;

********************************************************************;
* Exploratory Data Analysis--All Models;
********************************************************************;

proc means data=&INFILE. mean median n nmiss;
run;

proc means data=&INFILE. p1 p99;
var TARGET_WINS;
run;

* Correlation matrix for all but TEAM_BATTING_HBP;
ods graphics on;
proc corr data=&INFILE. plots=matrix; * Too much info to include scatterplots;
var
TARGET_WINS
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP;
run;
ods graphics off;

* Variables with highest correlation to TARGET_WINS; 
ods graphics on;
proc corr data=&INFILE. plots=matrix; 
var
TARGET_WINS
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_PITCHING_HR
TEAM_FIELDING_E
;
run;
ods graphics off;

* Variables with near perfect correlations;
ods graphics on;
proc corr data=&INFILE. plots=matrix;
var
TEAM_BATTING_HR
TEAM_PITCHING_HR
;
run;
ods graphics off;

* Examine histograms for outliers, skewness;
proc univariate data=&INFILE. plot;
var
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP;
run;

proc univariate data=&INFILE. plot;
var TARGET_WINS;
run;

* Look at variables with missing data for big outliers;
* 1/3 of values are missing for TEAM_BASERUN_CS whereas others have about 10% or less missing;
proc univariate data=&INFILE. plot;
var
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_PITCHING_SO
TEAM_FIELDING_DP
TEAM_BASERUN_CS
;
run;

* Look for suspicious 0s--maybe treat as missing;
proc freq data=&INFILE.;
tables
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;
quit;

********************************************************************;
* Data Cleaning--Model 1;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Model 1";
* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5;
M_TEAM_PITCHING_SO = 1;
end;

log_TEAM_BATTING_H = log(TEAM_BATTING_H); * otherwise set boundaries 1188 to 1950;

if TEAM_BATTING_2B > 450 then delete; * KEEP OR DO NOTHING;
if TEAM_BATTING_2B < 70 then delete;

if TEAM_BATTING_3B > 160 then delete;  * KEEP OR DO NOTHING otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR);

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; *p1 and p99;
if TEAM_BATTING_BB < 79 then TEAM_BATTING_BB = 79; * DO NOTHING;

log_TEAM_BATTING_SO = log(TEAM_BATTING_SO); * LOG LOOKS BAD, use IMP and maybe truncate by p1 and p99;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * otherwise truncate;

if TEAM_BASERUN_CS > 143 then TEAM_BASERUN_CS = 143; *p1 and p99 LOOKS WORSE;
if TEAM_BASERUN_CS < 16 then TEAM_BASERUN_CS = 16;* otherwise transform;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

log_TEAM_PITCHING_HR = log(TEAM_PITCHING_HR); * DON'T TRANSFORM, maybe leave alone;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

proc univariate data=tempfile plot;
var
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BASERUN_CS
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_DP

IMP_TEAM_BATTING_SO
IMP_TEAM_PITCHING_SO
log_TEAM_BATTING_H
log_TEAM_BATTING_HR
log_TEAM_BATTING_SO
log_TEAM_BASERUN_SB
log_TEAM_PITCHING_H
log_TEAM_PITCHING_HR
log_TEAM_FIELDING_E
;
run;

********************************************************************;
* Model Building--Model 1;
********************************************************************;

* Model 1;
proc reg data=tempfile;
M1: model TARGET_WINS =

log_TEAM_BATTING_H
TEAM_PITCHING_HR
TEAM_BATTING_2B
TEAM_BATTING_BB
log_TEAM_FIELDING_E
IMP_TEAM_PITCHING_SO
;
run;
quit;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Model 1;
********************************************************************;

* Do not include delete statements;
%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB= . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO=750; * I'm using medians for everything for now;
M_TEAM_BATTING_SO=1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO=813.5; * I'm using medians for everything for now;
M_TEAM_PITCHING_SO=1;
end;

log_TEAM_BATTING_H = log(TEAM_BATTING_H); * otherwise set boundaries 1188 to 1950;

*if TEAM_BATTING_2B > 450 then delete; * KEEP OR DO NOTHING;
*if TEAM_BATTING_2B < 70 then delete;

*if TEAM_BATTING_3B > 160 then delete;  * KEEP OR DO NOTHING otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR);

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; *p1 and p99;
if TEAM_BATTING_BB < 79 then TEAM_BATTING_BB = 79; * DO NOTHING;

log_TEAM_BATTING_SO = log(TEAM_BATTING_SO); * LOG LOOKS BAD, use IMP and maybe truncate by p1 and p99;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * otherwise truncate;

if TEAM_BASERUN_CS > 143 then TEAM_BASERUN_CS = 143; *p1 and p99 LOOKS WORSE;
if TEAM_BASERUN_CS < 16 then TEAM_BASERUN_CS = 16;* otherwise transform;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

log_TEAM_PITCHING_HR = log(TEAM_PITCHING_HR); * DON'T TRANSFORM, maybe leave alone;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 1;
P_TARGET_WINS = -605.14800 + 
97.64009*log_TEAM_BATTING_H + 
-0.01845*TEAM_PITCHING_HR + 
-0.04802*TEAM_BATTING_2B + 
0.02377*TEAM_BATTING_BB +
-5.51309*log_TEAM_FIELDING_E +
0.00626*IMP_TEAM_PITCHING_SO
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

ERROR_1 = (TARGET_WINS - P_TARGET_WINS)**2;

run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_1;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL_TEST--Model 1;
********************************************************************;

* Do not include delete statements;
%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB= . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO=750;
M_TEAM_BATTING_SO=1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO=813.5;
M_TEAM_PITCHING_SO=1;
end;

log_TEAM_BATTING_H = log(TEAM_BATTING_H); * otherwise set boundaries 1188 to 1950;

*if TEAM_BATTING_2B > 450 then delete; * KEEP OR DO NOTHING;
*if TEAM_BATTING_2B < 70 then delete;

*if TEAM_BATTING_3B > 160 then delete;  * KEEP OR DO NOTHING otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR);

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; *p1 and p99;
if TEAM_BATTING_BB < 79 then TEAM_BATTING_BB = 79; * DO NOTHING;

log_TEAM_BATTING_SO = log(TEAM_BATTING_SO); * LOG LOOKS BAD, use IMP and maybe truncate by p1 and p99;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * otherwise truncate;

if TEAM_BASERUN_CS > 143 then TEAM_BASERUN_CS = 143; *p1 and p99 LOOKS WORSE;
if TEAM_BASERUN_CS < 16 then TEAM_BASERUN_CS = 16;* otherwise transform;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

log_TEAM_PITCHING_HR = log(TEAM_PITCHING_HR); * DON'T TRANSFORM, maybe leave alone;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 1;
P_TARGET_WINS = -605.14800 + 
97.64009*log_TEAM_BATTING_H + 
-0.01845*TEAM_PITCHING_HR + 
-0.04802*TEAM_BATTING_2B + 
0.02377*TEAM_BATTING_BB +
-5.51309*log_TEAM_FIELDING_E +
0.00626*IMP_TEAM_PITCHING_SO
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

keep INDEX P_TARGET_WINS;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Exporting the Scored Model;
********************************************************************;

* Remove the comments to activate + change csv file name for each model;
*proc export data=OLS.BRUCKNER
   outfile='/folders/myfolders/PREDICT_411/Moneyball/annie01.csv'
   dbms=csv
   replace;
*run;

********************************************************************;
* Model 2;
********************************************************************;

* I accidentally overwrote my tempfile code for Model 2.
Below is the equation I ended up with;

* Kaggle Submission 2;
*P_TARGET_WINS = -0.87405 +
0.05038*TEAM_BATTING_H +
0.05701*TEAM_BATTING_3B +
0.01062*TEAM_BATTING_BB +
0.02708*TEAM_BASERUN_SB +
-0.00033705*TEAM_PITCHING_H +
0.00216*TEAM_PITCHING_SO +
-0.02137*TEAM_FIELDING_E
;

********************************************************************;
* Data Cleaning--Model 3;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Model 3";
* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

proc univariate data=tempfile plot;
var
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;

********************************************************************;
* Model Building--Model 3;
********************************************************************;

* These all resulted in the same model;

* Model Forward;
proc reg data=tempfile;
M3a: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = forward slentry=0.10;
;
run;
quit;

* Model Backward;
proc reg data=tempfile;
M3b: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = backward slstay=0.10;
;
run;
quit;

* Model Stepwise;
proc reg data=tempfile;
M3c: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

run;
quit;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Model 3;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

*Kaggle Model Submission 3;
P_TARGET_WINS = 26.60142 +
0.04325*TEAM_BATTING_H +
0.07210*TEAM_BATTING_3B +
0.01043*TEAM_BATTING_BB +
-0.00872*TEAM_BATTING_SO +
0.02587*TEAM_BASERUN_SB +
-0.00070967*TEAM_PITCHING_H +
0.06433*TEAM_PITCHING_HR +
0.00206*TEAM_PITCHING_SO +
-0.01911*TEAM_FIELDING_E +
-0.12113*TEAM_FIELDING_DP
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

ERROR_1 = (TARGET_WINS - P_TARGET_WINS)**2;

run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_1;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL_TEST--Model  3;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

*Kaggle Model Submission 3;
P_TARGET_WINS = 26.60142 +
0.04325*TEAM_BATTING_H +
0.07210*TEAM_BATTING_3B +
0.01043*TEAM_BATTING_BB +
-0.00872*TEAM_BATTING_SO +
0.02587*TEAM_BASERUN_SB +
-0.00070967*TEAM_PITCHING_H +
0.06433*TEAM_PITCHING_HR +
0.00206*TEAM_PITCHING_SO +
-0.01911*TEAM_FIELDING_E +
-0.12113*TEAM_FIELDING_DP
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

keep INDEX P_TARGET_WINS;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Data Cleaning--Model 4;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Model 4";
* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

if TEAM_BASERUN_SB > 439 then TEAM_BASERUN_SB = 439; * p99--MAYBE NOT;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

proc univariate data=tempfile plot;
var
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
log_TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
IMP_TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
log_TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
IMP_TEAM_PITCHING_SO
TEAM_FIELDING_E
log_TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;

********************************************************************;
* Model Building--Model 4;
********************************************************************;

* Stepwise Selection;
proc reg data=tempfile;
M4: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

run;
quit;

* Model Selection;
proc reg data=tempfile;
M4a: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = forward slentry=0.10;
;
run;
quit;

* Model Selection;
proc reg data=tempfile;
M4b: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = backward slstay=0.10;
;
run;
quit;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Model 4;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

if TEAM_BASERUN_SB > 439 then TEAM_BASERUN_SB = 439; * p99--MAYBE NOT;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 4;
P_TARGET_WINS = 26.18982 +
0.04334*TEAM_BATTING_H +
0.07215*TEAM_BATTING_3B +
0.01052*TEAM_BATTING_BB +
-0.00875*TEAM_BATTING_SO +
0.02676*TEAM_BASERUN_SB +
-0.00072629*TEAM_PITCHING_H +
0.06455*TEAM_PITCHING_HR +
0.00208*TEAM_PITCHING_SO +
-0.01895*TEAM_FIELDING_E +
-0.12028*TEAM_FIELDING_DP;

P_TARGET_WINS = round(P_TARGET_WINS, 1);
*keep INDEX P_TARGET_WINS;

ERROR_1 = (TARGET_WINS - P_TARGET_WINS)**2;

run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_1;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL_TEST--Model 4;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

if TEAM_BASERUN_SB > 439 then TEAM_BASERUN_SB = 439; * p99--MAYBE NOT;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 4;
P_TARGET_WINS = 26.18982 +
0.04334*TEAM_BATTING_H +
0.07215*TEAM_BATTING_3B +
0.01052*TEAM_BATTING_BB +
-0.00875*TEAM_BATTING_SO +
0.02676*TEAM_BASERUN_SB +
-0.00072629*TEAM_PITCHING_H +
0.06455*TEAM_PITCHING_HR +
0.00208*TEAM_PITCHING_SO +
-0.01895*TEAM_FIELDING_E +
-0.12028*TEAM_FIELDING_DP;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

keep INDEX P_TARGET_WINS;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Data Cleaning--Models 5 and 6;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Models 5 and 6";
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 735.6053358; * These are all means;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 124.7617716;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 52.8038564;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 817.7304508;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 146.3879397;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO; * Maybe also cap at 155 and 1192;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 735.6053358;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 817.7304508;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

log_TEAM_BATTING_3B = log(TEAM_BATTING_3B); * This looks much better;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * This looks good;

log_TEAM_BASERUN_CS = log(TEAM_BASERUN_CS);

if TEAM_PITCHING_H > 7093 then TEAM_PITCHING_HR = 7093; *p99;

if TEAM_PITCHING_HR > 244 then TEAM_PITCHING_HR = 244; *p1 and p99;
if TEAM_PITCHING_HR < 8 then TEAM_PITCHING_HR = 8;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924;

if IMP_TEAM_PITCHING_SO > 1464 then IMP_TEAM_PITCHING_SO =1464;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E);
if log_TEAM_FIELDING_E > 7.12044 then log_TEAM_FIELDING_E = 7.12044;
if log_TEAM_FIELDING_E < 4.45435 then log_TEAM_FIELDING_E = 4.45435;

* TEAM_FIELDING_DP looks fine--but maybe do 80 202 caps;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

proc univariate data=tempfile plot;
var
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
log_TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
IMP_TEAM_BATTING_SO
TEAM_BASERUN_SB
log_TEAM_BASERUN_SB
TEAM_BASERUN_CS
log_TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
IMP_TEAM_PITCHING_SO
TEAM_FIELDING_E
log_TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;

********************************************************************;
* Model Building--Models 5 and 6;
********************************************************************;

* Model 5;
proc reg data=tempfile;
M5: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;
run;

* Model 6;
proc reg data=tempfile;
M6: model TARGET_WINS =
TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Models 5 and 6;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

*I'm using means for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 735.6053358; * These are all means;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 124.7617716;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 52.8038564;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 817.7304508;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 146.3879397;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO; * Maybe also cap at 155 and 1192;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 735.6053358;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 817.7304508;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

log_TEAM_BATTING_3B = log(TEAM_BATTING_3B); * This looks much better;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * This looks good;

log_TEAM_BASERUN_CS = log(TEAM_BASERUN_CS);

if TEAM_PITCHING_H > 7093 then TEAM_PITCHING_HR = 7093; *p99;

if TEAM_PITCHING_HR > 244 then TEAM_PITCHING_HR = 244; *p1 and p99;
if TEAM_PITCHING_HR < 8 then TEAM_PITCHING_HR = 8;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924;

if IMP_TEAM_PITCHING_SO > 1464 then IMP_TEAM_PITCHING_SO =1464;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E);
if log_TEAM_FIELDING_E > 7.12044 then log_TEAM_FIELDING_E = 7.12044;
if log_TEAM_FIELDING_E < 4.45435 then log_TEAM_FIELDING_E = 4.45435;

* TEAM_FIELDING_DP looks fine--but maybe do 80 202 caps;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* For my actual submissions, I ran the code for Models 5 and 6 separately
so that each could be labled P_TARGET_WINS;

* Kaggle Model Submission 5;
P_TARGET_WINS_5 = 28.08597 +
0.04162*TEAM_BATTING_H +
0.08162*TEAM_BATTING_3B +
0.07400*TEAM_BATTING_HR +
0.00920*TEAM_BATTING_BB +
-0.00958*TEAM_BATTING_SO +
0.03109*TEAM_BASERUN_SB +
0.00171*TEAM_PITCHING_SO +
-0.02185*TEAM_FIELDING_E +
-0.12096*TEAM_FIELDING_DP
;

* Kaggle Model Submission 6;
P_TARGET_WINS_6 = 16.31604 +
0.03988*TEAM_BATTING_H +
0.09003*TEAM_BATTING_3B +
0.05940*TEAM_BATTING_HR +
-0.00691*TEAM_BATTING_SO +
0.03855*TEAM_BASERUN_SB +
0.00146*TEAM_PITCHING_SO +
-0.02374*TEAM_FIELDING_E
;

P_TARGET_WINS_5 = round(P_TARGET_WINS_5, 1);

P_TARGET_WINS_6 = round(P_TARGET_WINS_6, 1);

ERROR_5 = (TARGET_WINS - P_TARGET_WINS_5)**2;
ERROR_6 = (TARGET_WINS - P_TARGET_WINS_6)**2;
run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_5 ERROR_6;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS_5 P_TARGET_WINS_6;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL_TEST--Models 5 and 6;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 735.6053358; * These are all means;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 124.7617716;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 52.8038564;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 817.7304508;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 146.3879397;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO; * Maybe also cap at 155 and 1192;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 735.6053358;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 817.7304508;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

log_TEAM_BATTING_3B = log(TEAM_BATTING_3B); * This looks much better;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB); * This looks good;

log_TEAM_BASERUN_CS = log(TEAM_BASERUN_CS);

if TEAM_PITCHING_H > 7093 then TEAM_PITCHING_HR = 7093; *p99;

if TEAM_PITCHING_HR > 244 then TEAM_PITCHING_HR = 244; *p1 and p99;
if TEAM_PITCHING_HR < 8 then TEAM_PITCHING_HR = 8;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924;

if IMP_TEAM_PITCHING_SO > 1464 then IMP_TEAM_PITCHING_SO =1464;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E);
if log_TEAM_FIELDING_E > 7.12044 then log_TEAM_FIELDING_E = 7.12044;
if log_TEAM_FIELDING_E < 4.45435 then log_TEAM_FIELDING_E = 4.45435;

* TEAM_FIELDING_DP looks fine--but maybe do 80 202 caps;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* For my actual submissions, I ran the code for Models 5 and 6 separately
so that each could be labeld P_TARGET_WINS;

* Kaggle Model Submission 5;
P_TARGET_WINS_5 = 28.08597 +
0.04162*TEAM_BATTING_H +
0.08162*TEAM_BATTING_3B +
0.07400*TEAM_BATTING_HR +
0.00920*TEAM_BATTING_BB +
-0.00958*TEAM_BATTING_SO +
0.03109*TEAM_BASERUN_SB +
0.00171*TEAM_PITCHING_SO +
-0.02185*TEAM_FIELDING_E +
-0.12096*TEAM_FIELDING_DP
;

* Kaggle Model Submission 6;
P_TARGET_WINS_6 = 16.31604 +
0.03988*TEAM_BATTING_H +
0.09003*TEAM_BATTING_3B +
0.05940*TEAM_BATTING_HR +
-0.00691*TEAM_BATTING_SO +
0.03855*TEAM_BASERUN_SB +
0.00146*TEAM_PITCHING_SO +
-0.02374*TEAM_FIELDING_E
;

P_TARGET_WINS_5 = round(P_TARGET_WINS_5, 1);

P_TARGET_WINS_6 = round(P_TARGET_WINS_6, 1);

keep INDEX P_TARGET_WINS_5 P_TARGET_WINS_6;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS_5 P_TARGET_WINS_6;
run;

********************************************************************;
* Data Cleaning--Models 7 and 8;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Models 7 and 8";
* I'm using medians for everything for now;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750; * I'm using medians for everything for now;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5; * I'm using medians for everything for now;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB);
if log_TEAM_BASERUN_SB = . then log_TEAM_BASERUN_SB = 101;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

proc univariate data=tempfile plot;
var
TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
log_TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
IMP_TEAM_BATTING_SO
TEAM_BASERUN_SB
log_TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
log_TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
IMP_TEAM_PITCHING_SO
TEAM_FIELDING_E
log_TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;

********************************************************************;
* Model Building--Models 7 and 8;
********************************************************************;

* Model 7;
proc reg data=tempfile;
M7: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_HR
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB 
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
log_TEAM_BASERUN_SB

/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

run;
quit;

* Model 8;
proc reg data=tempfile;
M8: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_BB
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
log_TEAM_BASERUN_SB
;
run;
quit;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Models 7 and 8;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750; * I'm using medians for everything for now;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5; * I'm using medians for everything for now;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB);
if log_TEAM_BASERUN_SB = . then log_TEAM_BASERUN_SB = 101;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 7;
P_TARGET_WINS_7 = 26.60142 +
0.04325*TEAM_BATTING_H +
0.0721*TEAM_BATTING_3B +
0.01043*TEAM_BATTING_BB +
-0.00872*TEAM_BATTING_SO +
0.02587*TEAM_BASERUN_SB +
-0.00070967*TEAM_PITCHING_H +
0.06433*TEAM_PITCHING_HR +
0.00206*TEAM_PITCHING_SO +
-0.01911*TEAM_FIELDING_E +
-0.12113*TEAM_FIELDING_DP
;

* Kaggle Model Submission 8;
P_TARGET_WINS_8 = 21.52941 +
0.04515*TEAM_BATTING_H +
0.10198*TEAM_BATTING_3B +
0.01945*TEAM_BATTING_BB +
-0.00606*TEAM_BATTING_SO +
-0.00109*TEAM_PITCHING_H +
0.05522*TEAM_PITCHING_HR +
-0.00261*TEAM_PITCHING_BB +
0.00247*TEAM_PITCHING_SO +
-0.01379*TEAM_FIELDING_E +
-0.13351*TEAM_FIELDING_DP +
0.12603*log_TEAM_BASERUN_SB
;

P_TARGET_WINS_7 = round(P_TARGET_WINS_7, 1);

P_TARGET_WINS_8 = round(P_TARGET_WINS_8, 1);

ERROR_7 = (TARGET_WINS - P_TARGET_WINS_7)**2;
ERROR_8 = (TARGET_WINS - P_TARGET_WINS_8)**2;
run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_7 ERROR_8;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS_7 P_TARGET_WINS_8;
run;

********************************************************************;
* Model Scoring----Using MONEYBALL_TEST--Models 7 and 8;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

IMP_TEAM_BATTING_SO = TEAM_BATTING_SO;
if IMP_TEAM_BATTING_SO = 0 then do;
IMP_TEAM_BATTING_SO = 750; * I'm using medians for everything for now;
M_TEAM_BATTING_SO = 1;
end;

IMP_TEAM_PITCHING_SO = TEAM_PITCHING_SO;
if IMP_TEAM_PITCHING_SO = 0 then do;
IMP_TEAM_PITCHING_SO = 813.5; * I'm using medians for everything for now;
M_TEAM_PITCHING_SO = 1;
end;

if TEAM_BATTING_H > 1950 then TEAM_BATTING_H = 1950; * p1 and p99;
if TEAM_BATTING_H < 1188 then TEAM_BATTING_H = 1188;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;  * otherwise transform;

log_TEAM_BATTING_HR = log(TEAM_BATTING_HR); * MAYBE DO NOTHING;

log_TEAM_BASERUN_SB = log(TEAM_BASERUN_SB);
if log_TEAM_BASERUN_SB = . then log_TEAM_BASERUN_SB = 101;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* For my actual submissions, I ran the code for Models 7 and 8 separately
so that each could be labeld P_TARGET_WINS;

* Kaggle Model Submission 7;
P_TARGET_WINS_7 = 26.60142 +
0.04325*TEAM_BATTING_H +
0.0721*TEAM_BATTING_3B +
0.01043*TEAM_BATTING_BB +
-0.00872*TEAM_BATTING_SO +
0.02587*TEAM_BASERUN_SB +
-0.00070967*TEAM_PITCHING_H +
0.06433*TEAM_PITCHING_HR +
0.00206*TEAM_PITCHING_SO +
-0.01911*TEAM_FIELDING_E +
-0.12113*TEAM_FIELDING_DP
;

* Kaggle Model Submission 8;
P_TARGET_WINS_8 = 21.52941 +
0.04515*TEAM_BATTING_H +
0.10198*TEAM_BATTING_3B +
0.01945*TEAM_BATTING_BB +
-0.00606*TEAM_BATTING_SO +
-0.00109*TEAM_PITCHING_H +
0.05522*TEAM_PITCHING_HR +
-0.00261*TEAM_PITCHING_BB +
0.00247*TEAM_PITCHING_SO +
-0.01379*TEAM_FIELDING_E +
-0.13351*TEAM_FIELDING_DP +
0.12603*log_TEAM_BASERUN_SB
;

P_TARGET_WINS_7 = round(P_TARGET_WINS_7, 1);

P_TARGET_WINS_8 = round(P_TARGET_WINS_8, 1);

keep INDEX P_TARGET_WINS_7 P_TARGET_WINS_8;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS_7 P_TARGET_WINS_8;
run;

********************************************************************;
* Models 9, 10, 11, 12, and 13;
********************************************************************;

* This is all the remaining code from these models, unfortunately;

* Model 9;
*proc export data=OLS.BRUCKNER
   outfile='/folders/myfolders/PREDICT_411/Moneyball/annie09.csv'
   dbms=csv
   replace;
*run;

* Model 10;
*proc export data=OLS.BRUCKNER
   outfile='/folders/myfolders/PREDICT_411/Moneyball/annie10.csv'
   dbms=csv
   replace;
*run;

* Kaggle Model Submission 11;
*P_TARGET_WINS = -66.12318 +
0.02077*TEAM_BATTING_H +
0.11784*TEAM_BATTING_3B +
0.02135*TEAM_BATTING_BB +
0.07776*TEAM_BASERUN_SB +
0.07776*TEAM_BASERUN_CS +
0.08801*TEAM_PITCHING_HR +
33.04389*M_TEAM_BASERUN_SB +
9.832*M_TEAM_PITCHING_SO +
14.44992*log_TEAM_PITCHING_H +
-0.01703*M_TEAM_PITCHING_SO +
-0.05266*TEAM_FIELDING_E
;

* Model 12;
*proc export data=OLS.BRUCKNER
   outfile='/folders/myfolders/PREDICT_411/Moneyball/annie12.csv'
   dbms=csv
   replace;
*run;

* Model 13;
*proc reg data=tempfile;
*M13a: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_HR
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP

/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

*run;
*quit;

********************************************************************;
* Data Cleaning--Model 14;
********************************************************************;

* Best practice: Copy data set before messing with it;
data tempfile;
set &INFILE.;
title "Model 14";
* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if M_TEAM_FIELDING_DP = 1 then do;
if TEAM_FIELDING_E > 159 then TEAM_FIELDING_DP = 131;
if TEAM_FIELDING_E < 159 then TEAM_FIELDING_DP = 164;
end;

if TEAM_BATTING_H > 1696 then TEAM_BATTING_H = 1696; * p5 and p95;
if TEAM_BATTING_H < 1280 then TEAM_BATTING_H = 1280;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 108 then TEAM_BATTING_3B = 108;  * otherwise transform;

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; * p5 and p99;
if TEAM_BATTING_BB < 246 then TEAM_BATTING_BB = 246;

if TEAM_BASERUN_SB > 302 then TEAM_BASERUN_SB = 302; * p95;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;
run;

proc means data=tempfile min max mean median n nmiss;
run;

proc print data=tempfile(obs=10);
run;

********************************************************************;
* Model Building--Model 14;
********************************************************************;

* Model 14;
proc reg data=tempfile;
M14: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_2B
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_HR
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_BASERUN_CS
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP

/ adjrsq aic bic mse cp vif selection = stepwise slentry =0.10 slstay=0.10;

run;
quit;

********************************************************************;
* Model Scoring--Using MONEYBALL to examine error rate--Model 14;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if M_TEAM_FIELDING_DP = 1 then do;
if TEAM_FIELDING_E > 159 then TEAM_FIELDING_DP = 131;
if TEAM_FIELDING_E < 159 then TEAM_FIELDING_DP = 164;
end;

if TEAM_BATTING_H > 1696 then TEAM_BATTING_H = 1696; * p5 and p95;
if TEAM_BATTING_H < 1280 then TEAM_BATTING_H = 1280;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 108 then TEAM_BATTING_3B = 108;  * otherwise transform;

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; * p5 and p99;
if TEAM_BATTING_BB < 246 then TEAM_BATTING_BB = 246;

if TEAM_BASERUN_SB > 302 then TEAM_BASERUN_SB = 302; * p95;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 14;
P_TARGET_WINS = 26.50788 +
0.04084*TEAM_BATTING_H +
0.10813*TEAM_BATTING_3B +
0.01273*TEAM_BATTING_BB +
-0.00925*TEAM_BATTING_SO +
0.02893*TEAM_BASERUN_SB +
0.07644*TEAM_PITCHING_HR +
0.00115*TEAM_PITCHING_SO +
-0.02223*TEAM_FIELDING_E +
-0.12468*TEAM_FIELDING_DP
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

ERROR_1 = (TARGET_WINS - P_TARGET_WINS)**2;

run;

proc means data=OLS.BRUCKNER mean median;
var ERROR_1;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

********************************************************************;
* Model Scoring--Using MONEYBALL_TEST--Model 14;
********************************************************************;

%let SCORE_ME = &LIB.MONEYBALL_TEST;

proc means data=&SCORE_ME. n;
var INDEX;
run;

data OLS.BRUCKNER;
set &SCORE_ME.;

* I'm using medians for everything for now;
M_TEAM_BATTING_SO = missing(TEAM_BATTING_SO);
M_TEAM_BASERUN_SB = missing(TEAM_BASERUN_SB);
M_TEAM_BASERUN_CS = missing(TEAM_BASERUN_CS);
M_TEAM_PITCHING_SO = missing(TEAM_PITCHING_SO);
M_TEAM_FIELDING_DP = missing(TEAM_FIELDING_DP);
if TEAM_BATTING_SO = . then TEAM_BATTING_SO = 750;
if TEAM_BASERUN_SB = . then TEAM_BASERUN_SB = 101;
if TEAM_BASERUN_CS = . then TEAM_BASERUN_CS = 49;
if TEAM_PITCHING_SO = . then TEAM_PITCHING_SO = 813.5;
if TEAM_FIELDING_DP = . then TEAM_FIELDING_DP = 149;

if M_TEAM_FIELDING_DP = 1 then do;
if TEAM_FIELDING_E > 159 then TEAM_FIELDING_DP = 131;
if TEAM_FIELDING_E < 159 then TEAM_FIELDING_DP = 164;
end;

if TEAM_BATTING_H > 1696 then TEAM_BATTING_H = 1696; * p5 and p95;
if TEAM_BATTING_H < 1280 then TEAM_BATTING_H = 1280;

if TEAM_BATTING_2B > 403 then TEAM_BATTING_2B = 403; * highest and lowest outlier;
if TEAM_BATTING_2B < 112 then TEAM_BATTING_2B = 112;

if TEAM_BATTING_3B > 108 then TEAM_BATTING_3B = 108;  * otherwise transform;

if TEAM_BATTING_BB > 755 then TEAM_BATTING_BB = 755; * p5 and p99;
if TEAM_BATTING_BB < 246 then TEAM_BATTING_BB = 246;

if TEAM_BASERUN_SB > 302 then TEAM_BASERUN_SB = 302; * p95;

log_TEAM_PITCHING_H = log(TEAM_PITCHING_H); * MAYBE KEEP otherwise truncate;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; *p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;* LOOKS BETTER--MAYBE CAP JUST UPPER otherwise transform;

if IMP_TEAM_PITCHING_SO > 1474 then IMP_TEAM_PITCHING_SO = 1474; *p1 and p99;
if IMP_TEAM_PITCHING_SO < 205 then IMP_TEAM_PITCHING_SO = 205;* LOOKS BETTER, USE IMP otherwise transform;

log_TEAM_FIELDING_E = log(TEAM_FIELDING_E); * MAYBE KEEP;

* TEAM_FIELDING_DP looks fine--don't do anything;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 14;
P_TARGET_WINS = 26.50788 +
0.04084*TEAM_BATTING_H +
0.10813*TEAM_BATTING_3B +
0.01273*TEAM_BATTING_BB +
-0.00925*TEAM_BATTING_SO +
0.02893*TEAM_BASERUN_SB +
0.07644*TEAM_PITCHING_HR +
0.00115*TEAM_PITCHING_SO +
-0.02223*TEAM_FIELDING_E +
-0.12468*TEAM_FIELDING_DP
;

P_TARGET_WINS = round(P_TARGET_WINS, 1);

keep INDEX P_TARGET_WINS;
run;

proc print data=OLS.BRUCKNER(obs=10);
run;

proc means data=OLS.BRUCKNER n nmiss min max;
var P_TARGET_WINS;
run;

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

* I used just the variables chosen from stepwise selection in my original
code for PROC REG to code PROG GLM and PROC GENMOD. I removed the stepwise
selection for PROC REG here to save processing time ;

* PROC REG;

proc reg data=tempfile;
M4: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;
quit;

* PROC GLM;

proc glm data=tempfile;
M4: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
;
run;
quit;

* PROC GENMOD;

proc genmod data=tempfile;
M4: model TARGET_WINS =

TEAM_BATTING_H
TEAM_BATTING_3B
TEAM_BATTING_BB
TEAM_BATTING_SO
TEAM_BASERUN_SB
TEAM_PITCHING_H
TEAM_PITCHING_HR
TEAM_PITCHING_SO
TEAM_FIELDING_E
TEAM_FIELDING_DP
/ link=identity dist=normal
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
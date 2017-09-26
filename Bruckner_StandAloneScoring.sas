* Andrea Bruckner
  PREDICT 411, Sec 55
  Spring 2016
  Unit 01: Moneyball
;

********************************************************************;
* Model Scoring--Best Model (Kaggle Model 4);
********************************************************************;

* Set library name and path to data;
%let PATH = /folders/myfolders/PREDICT_411/Moneyball;
%let NAME = OLS;
%let LIB = &NAME..;

libname &NAME. "&PATH.";

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

if TEAM_BATTING_3B > 200 then TEAM_BATTING_3B = 200;

if TEAM_BASERUN_SB > 439 then TEAM_BASERUN_SB = 439;

if TEAM_PITCHING_BB > 924 then TEAM_PITCHING_BB = 924; * p1 and p99;
if TEAM_PITCHING_BB < 237 then TEAM_PITCHING_BB = 237;

drop TEAM_BATTING_HBP; * too many missing values to salvage;

* Kaggle Model Submission 4--BEST MODEL;
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
* Exporting the Scored Model;
********************************************************************;

proc export data=OLS.BRUCKNER
   outfile='/folders/myfolders/PREDICT_411/Moneyball/Bruckner_New.csv'
   dbms=csv
   replace;
run;
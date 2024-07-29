
%let output=<output directory>;
libname c '<directory>';

%macro create_map(mapping_variable,grouping_variable,dataset,chart_title);


	 /**graph options setting*/
	 GOPTIONS RESET=GLOBAL CBACK=WHITE ROTATE=LANDSCAPE DISPLAY  
	         COLORS=(BLACK RED GREEN BLUE PURPLE MAGENTA CYAN YELLOW);

	 PATTERN1 V=SOLID C=A00FF0000;
	 PATTERN2 V=SOLID C=A00FF0033;
	 PATTERN3 V=SOLID C=A00BB0077;
	 PATTERN4 V=SOLID C=A009900BB;
	 PATTERN5 V=SOLID C=A007700FF;


	/*need the SAS numeric state code for creating the map*/
	data &dataset;
	 set &dataset(rename = (state=state_cd));
	  if state_cd='AL'  then state=1;
	  else if state_cd='AK'    then state=2;
	  else if state_cd='AZ'    then state=4;
	  else if state_cd='AR'    then state=5;
	  else if state_cd='CA'    then state=6;
	  else if state_cd='CO'    then state=8;
	  else if state_cd='CT'  then state=9;
	  else if state_cd='DE'    then state=10;
	  else if state_cd='DC'    then state=11;
	  else if state_cd='FL'    then state=12;
	  else if state_cd='GA'    then state=13;
	  else if state_cd='HI'    then state=15;
	  else if state_cd='ID'    then state=16;
	  else if state_cd='IL'  then state=17;
	  else if state_cd='IN'    then state=18;
	  else if state_cd='IA'    then state=19;
	  else if state_cd='KS'    then state=20;
	  else if state_cd='KY'    then state=21;
	  else if state_cd='LA'    then state=22;
	  else if state_cd='ME'    then state=23;
	  else if state_cd='MD'  then state=24;
	  else if state_cd='MA'    then state=25;
	  else if state_cd='MI'    then state=26;
	  else if state_cd='MN'    then state=27;
	  else if state_cd='MS'    then state=28;
	  else if state_cd='MO'    then state=29;
	  else if state_cd='MT'    then state=30;
	  else if state_cd='NE'  then state=31;
	  else if state_cd='NV'    then state=32;
	  else if state_cd='NH'    then state=33;
	  else if state_cd='NJ'    then state=34;
	  else if state_cd='NM'    then state=35;
	  else if state_cd='NY'    then state=36;
	  else if state_cd='NC'    then state=37;
	  else if state_cd='ND'  then state=38;
	  else if state_cd='OH'    then state=39;
	  else if state_cd='OK'    then state=40;
	  else if state_cd='OR'    then state=41;
	  else if state_cd='PA'    then state=42;
	  else if state_cd='PR'    then state=72;
	  else if state_cd='RI'    then state=44;
	  else if state_cd='SC'    then state=45;
	  else if state_cd='SD'  then state=46;
	  else if state_cd='TN'    then state=47;
	  else if state_cd='TX'    then state=48;
	  else if state_cd='UT'    then state=49;
	  else if state_cd='VT'    then state=50;
	  else if state_cd='VA'    then state=51;
	  else if state_cd='WA'    then state=53;
	  else if state_cd='WV'  then state=54;
	  else if state_cd='WI'  then state=55;
	  else if state_cd='WY'  then state=56;

	if state = . then delete;

	run; 

	data labeldata(keep=state &mapping_variable) ;
	  set &dataset;
	run;

	proc sort data=labeldata;
	 by state;
	run;

	data center;
	   length function $ 8;
	   retain flag 0 xsys ysys '2' hsys '3' when 'a';
	   merge maps.uscenter
	       (where=(fipstate(state) ne 'DC')
	       drop=long lat in=a)
	         labeldata;
	   by state;
	   if a;

	   style = "'Albany AMT/bold'";
	   function='label';
	   text=left(put(&mapping_variable,percent6.3));
	   size=2.5;
	   position='5';

	   if ocean='Y' then
	      do;
	         position='6';
	         output;
	         function='move';
	         flag=1;
	      end;

	   else if flag=1 then
	      do;
	         function='draw';
	         size=.25;
	         flag=0;
	      end;
	   output;
	run;

	PROC GMAP DATA=&dataset ALL 
		MAP=MAPS.US 
		GOUT=c.MAPOUT;
		ID STATE;   
		CHORO &grouping_variable / DISCRETE   COUTLINE = BLACK annotate=center ;
		LEGEND  ACROSS=7 LABEL=NONE;
		TITLE3 C=BLACK H=2 "&chart_title";
	RUN;
	quit;

%mend;


/**************************************counts by state**********************************************/

data heat_map;
set c.Counts_by_state;
/*set null value to 0*/
if CARD_COUNT_PERSONAL = . then CARD_COUNT_PERSONAL = 0;
if CARD_COUNT_BUSINESS = . then CARD_COUNT_BUSINESS = 0;
run;

data heat_map;
set heat_map;
CARD_COUNT = CARD_COUNT_PERSONAL + CARD_COUNT_BUSINESS;
run;

proc sql;
select sum(CARD_COUNT) into : total_cards
from heat_map;
quit;

data heat_map;
set heat_map;
PERCENT_OF_CARDS = CARD_COUNT/&total_cards;
run;

/*need to create 5 ranges*/

%let var = PERCENT_OF_CARDS;

/*proc rank data=heat_map*/
/*	out=heat_map*/
/*	groups=5;*/
/*var &var;*/
/*ranks grouping;*/
/*run;*/
/*proc sql;*/
/*create table ranges as*/
/*select grouping*/
/*	,min(&var) as MIN*/
/*	,max(&var) as MAX*/
/*from heat_map*/
/*group by grouping;*/
/*quit;*/
/*proc print data = ranges noobs; run;*/

/*grouping MIN MAX */
/*0 0.000001 0.00010 */
/*1 0.000108 0.00026 */
/*2 0.000272 0.00081 */
/*3 0.000823 0.01868 */
/*4 0.020382 0.28738 */

PROC FORMAT;
VALUE COUNT_RANGE
	0 - 0.0001009 = 'a 0 - 0.010%' 
	0.000101 - 0.00026999 = 'b 0.011% - 0.0269%'  
	0.0.00027 - 0.00081999 = 'c 0.027% - 0.081%' 
	0.00082 - 0.0189999 = 'd 0.082% - 1.8%' 
	0.019 - 0.3 = 'e 1.9% - 30.0%'
;
RUN;

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
RANGE = substr(left(RANGE),1,18);
run;

%create_map(&var,RANGE,heat_map,BB&T CARDHOLDER ACCOUNTS);

proc datasets kill;
run; quit;



/*now look at all others*/

data heat_map;
set c.Cardholders_by_state;
run;

/*need to create 5 ranges*/

%let var = PERCENT_OF_CARDHOLDERS;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

proc sql;
select sum(PERCENT_OF_CARDHOLDERS) 
from heat_map;
quit;

/*grouping MIN MAX */
/*0 0.001517 0.005102 */
/*1 0.005192 0.010526 */
/*2 0.011329 0.014516 */
/*3 0.014902 0.031204 */
/*4 0.031702 0.091066 */

PROC FORMAT;
VALUE COUNT_RANGE
	0 - 0.005102999 = 'a 0 - 0.51%' 
	0.005103 - 0.010526999 = 'b 0.52% - 1.05%'  
	0.0.010527 - 0.014516999 = 'c 1.06% - 1.45%' 
	0.014517 - 0.031204999 = 'd 1.46% - 3.12%' 
	0.031205 - 0.1 = 'e 3.13% - 10.0%'
;
RUN;

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
RANGE = substr(left(RANGE),1,18);
run;

%create_map(&var,RANGE,heat_map,ALL CARDHOLDER ACCOUNTS);

proc datasets kill;
run; quit;







/*now look at card activity by state*/

data heat_map;
set c.Counts_by_state;
run;

%let var = CARD_COUNT_BUSINESS;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

PROC FORMAT;
VALUE COUNT_RANGE
	1 - 39 = 'a 1 - 39' 
	40 - 128 = 'b 40 - 128'  
	129 - 321 = 'c 129 - 321' 
	322 - 12353 = 'd 322 - 12,353' 
	12354 - 189839 = 'e 12,354 - 189,839'
;
RUN;

data heat_map;
set heat_map;
COUNT_RANGE = put(&var,count_range.);
run;

%create_map(&var,COUNT_RANGE,heat_map,BUSINESS CARDHOLDER ACCOUNTS);

proc datasets kill;
run; quit;

/****************************percent of cards by state**************************************/

data heat_map;
set c.Counts_by_state;
run;

/*need to create 5 ranges*/

%let var = PERCENT_OF_CARDS_PERSONAL;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

PROC FORMAT;
VALUE COUNT_RANGE
	0 - 0.000139999 = 'a 0 - 0.013%' 
	0.00014 - 0.00039999 = 'b 0.014% - 0.039%'  
	0.0004 - 0.00089999 = 'c 0.04% - 0.089%' 
	0.0009 - 0.0199999 = 'd 0.09% - 1.9%' 
	0.02 - 0.277 = 'e 2.0% - 27.7%'
;
RUN;

/*grouping MIN MAX */
/*0 0.000001 0.00013 */
/*1 0.000141 0.00030 */
/*2 0.000300 0.00086 */
/*3 0.000920 0.01909 */
/*4 0.019272 0.27669 */

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
run;

%create_map(&var,RANGE,heat_map,PERCENT OF PERSONAL CARD HOLDERS BY STATE);

proc datasets kill;
run; quit;

/*now look at card activity by state*/

data heat_map;
set c.Counts_by_state;
run;

%let var = PERCENT_OF_CARDS_BUSINESS;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

PROC FORMAT;
VALUE COUNT_RANGE
	0 - 0.000069999 = 'a 0 - 0.006%' 
	0.00007 - 0.00021999 = 'b 0.007% - 0.021%'  
	0.00022 - 0.00052999 = 'c 0.022% - 0.052%' 
	0.00053 - 0.0299999 = 'd 0.053% - 2.9%' 
	0.03 - 0.31 = 'e 3.0% - 31.0%'
;
RUN;

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
run;

%create_map(&var,RANGE,heat_map,PERCENT OF BUSINESS CARD HOLDERS BY STATE);

proc datasets kill;
run; quit;






/**************************************now activity per card**********************************************/


data heat_map;
set c.Counts_by_state;
run;

/*need to create 5 ranges*/

%let var = AUTH_PER_CARD_PERSONAL;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

PROC FORMAT;
VALUE COUNT_RANGE
	1 - 50.599999 = 'a 1 - 50.5' 
	50.6 - 57.99999 = 'b 50.6 - 57.9'  
	58.0 - 63.19999 = 'c 58.0 - 63.1' 
	63.2 - 74.29999 = 'd 63.2 - 74.2' 
	74.3 - 169.5 = 'e 74.3 - 169.5'
;
RUN;

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
run;

%create_map(&var,RANGE,heat_map,AUTHS PER PERSONAL CARD);

proc datasets kill;
run; quit;

/*now look at card activity by state*/

data heat_map;
set c.Counts_by_state;
run;

%let var = AUTH_PER_CARD_BUSINESS;

proc rank data=heat_map
	out=heat_map
	groups=5;
var &var;
ranks grouping;
run;
proc sql;
create table ranges as
select grouping
	,min(&var) as MIN
	,max(&var) as MAX
from heat_map
group by grouping;
quit;
proc print data = ranges noobs; run;

PROC FORMAT;
VALUE COUNT_RANGE
	1 - 50.599999 = 'a 1 - 50.5' 
	50.6 - 57.99999 = 'b 50.6 - 57.9'  
	58.0 - 63.19999 = 'c 58.0 - 63.1' 
	63.2 - 74.29999 = 'd 63.2 - 74.2' 
	74.3 - 169.5 = 'e 74.3 - 169.5'
;
RUN;

data heat_map;
set heat_map;
RANGE = put(&var,count_range.);
run;

%create_map(&var,RANGE,heat_map,AUTHS PER BUSINESS CARD);

proc datasets kill;
run; quit;






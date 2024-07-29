
libname data '<library>';
%let output=<output directory>;
%let woe_dir = <woe code directory>;

%include "&output\Macro Var List IN Stmnt.txt";
%put &var_in;
%include "&output\Macro Var List Keep Stmnt.txt";
%put &var_keep;

proc contents data = data.test_data(keep = &var_keep)
	out = vars(keep = NAME type);run;
proc sort data = vars; by name; run;

/*purge anything I don't need to bin*/
data vars;
set vars;
if name in ('CAT_SIC_MAX_DLR_AMT_24M','CHAIN','LOCAL_HOUR','SIC') then type = 2;
if name = 'CHECK_NUMBER' then delete;
run;

data num_var
	char_var;
	set vars;
if type = 1 then output num_var;
else output char_var; 
run;

data nlet;
length NAME $ 32.;
name = '%let num_vars =';
run;

data clet;
length NAME $ 32.;
name = '%let char_vars =';
run;

data wnlet;
length NAME $ 32.;
name = '%let wnum_vars =';
run;

data wclet;
length NAME $ 32.;
name = '%let wchar_vars =';
run;


data sc;
length NAME $ 32.;
name = ';';
run;

data wnum(drop = temp);
set Num_var(rename=(name=temp));
length NAME $ 32.;
NAME = compress('w'||temp);
run;

data wchar(drop = temp);
set Char_var(rename=(name=temp));
length NAME $ 32.;
NAME = compress('w'||temp);
run;

data _null_;
file "&output\num_vars.txt";
set nlet Num_var sc;
format NAME $32. ;
do;
put NAME $ ;
;
end;
run;

data _null_;
file "&output\char_vars.txt";
set clet Char_var sc;
format NAME $32. ;
do;
put NAME $ ;
;
end;
run;

data _null_;
file "&output\wnum_vars.txt";
set wnlet wNUM sc;
format NAME $32. ;
do;
put NAME $ ;
;
end;
run;

data _null_;
file "&output\wchar_vars.txt";
set wclet wchar sc;
format NAME $32. ;
do;
put NAME $ ;
;
end;
run;

%include "&output\char_vars.txt";
%include "&output\num_vars.txt";

%put &char_vars;
%put &num_vars;

%include "&output\wchar_vars.txt";
%include "&output\wnum_vars.txt";

%put &wchar_vars;
%put &wnum_vars;

/*Binning code*/
proc datasets kill;
run; quit;

/******************************START WITH CHALLENGER BINNING******************************/

data temp(keep = bad &num_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
run;

/*NUMERIC WOE*/
%include "C:\Local Model Build Code\woe.sas";
%woe(data=temp,y=bad,pvalue=0.05,groups=10,outfile=&output\woe_num_chall,merge_step_printed=No);

proc datasets kill;
run; quit;

data temp(keep = bad &char_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
run;

%include "C:\Local Model Build Code\woe_character.sas";
%woe_character(data=temp,y=bad,pvalue=0.05,outfile=&output/woe_char_chall,merge_step_printed=No);

proc datasets kill;
run; quit;


/******************************CHAMPION BINNING******************************/

data temp(keep = bad &num_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
run;

/*NUMERIC WOE*/
%include "C:\Local Model Build Code\woe.sas";
%woe(data=temp,y=bad,pvalue=0.05,groups=10,outfile=&output\woe_num_champ,merge_step_printed=No);

proc datasets kill;
run; quit;


data temp(keep = bad &char_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
run;

%include "C:\Local Model Build Code\woe_character.sas";
%woe_character(data=temp,y=bad,pvalue=0.05,outfile=&output/woe_char_champ,merge_step_printed=No);

proc datasets kill;
run; quit;

/*now do the manual bins*/

/*CHECK NUMBER ** CHECK NUMBER ** CHECK NUMBER ** CHECK NUMBER ** CHECK NUMBER ** CHECK NUMBER ** CHECK NUMBER*/

/*CHALLENGER CHECK NUMBER BINNING*/

data test(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 5;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 6;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 7;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 8;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 9;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 10;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 11;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 12;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 13;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 14;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 15;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 16;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 17;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 18;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 19;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 20;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 21;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 22;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 23;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 24;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 25;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 26;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 27;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 28;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 29;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 30;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 31;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 32;
else wCHECK_NUMBER = 33;
run;

data valdt(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 5;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 6;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 7;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 8;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 9;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 10;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 11;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 12;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 13;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 14;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 15;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 16;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 17;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 18;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 19;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 20;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 21;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 22;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 23;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 24;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 25;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 26;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 27;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 28;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 29;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 30;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 31;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 32;
else wCHECK_NUMBER = 33;
run;


proc sql;
select sum(wgt) into : test_count
from test;

create table test_perf as
select wCHECK_NUMBER
	,min(CHECK_NUMBER) as MIN_CHECK_NUMBER
	,max(CHECK_NUMBER) as MAX_CHECK_NUMBER

	,sum(wgt)/&test_count as PCNT_OF_TEST
	,sum(BAD)/sum(wgt) as PCNT_BAD_TEST
from test
group by wCHECK_NUMBER;

select sum(wgt) into : vldt_count
from valdt;

create table vldt_perf as
select wCHECK_NUMBER
	,sum(wgt)/&vldt_count as PCNT_OF_VLDT
	,sum(BAD)/sum(wgt) as PCNT_BAD_VLDT
from valdt
group by wCHECK_NUMBER;
quit;

data checkno_perf;
merge test_perf(in=a) vldt_perf(in=b);
by wCHECK_NUMBER;
if a;
run;

proc export data = checkno_perf
outfile = "&output\Check Number Binning Challenger.xlsb"
dbms = excelcs replace;
sheet = round1;
run;

proc datasets kill;
run; quit;

/******************************NOW CREATE BINS******************************/

data test(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 1;
else wCHECK_NUMBER = 1;
run;


data valdt(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 1;
else wCHECK_NUMBER = 1;
run;


proc sql;
select sum(wgt) into : test_count
from test;

create table test_perf as
select wCHECK_NUMBER
	,min(CHECK_NUMBER) as MIN_CHECK_NUMBER
	,max(CHECK_NUMBER) as MAX_CHECK_NUMBER

	,sum(wgt)/&test_count as PCNT_OF_TEST
	,sum(BAD)/sum(wgt) as PCNT_BAD_TEST
from test
group by wCHECK_NUMBER;

select sum(wgt) into : vldt_count
from valdt;

create table vldt_perf as
select wCHECK_NUMBER
	,sum(wgt)/&vldt_count as PCNT_OF_VLDT
	,sum(BAD)/sum(wgt) as PCNT_BAD_VLDT
from valdt
group by wCHECK_NUMBER;
quit;

data checkno_perf;
merge test_perf(in=a) vldt_perf(in=b);
by wCHECK_NUMBER;
if a;
run;
proc print data = checkno_perf noobs; run;


proc export data = checkno_perf
outfile = "&output\Check Number Binning Challenger.xlsb"
dbms = excelcs replace;
sheet = final;
run;

/*paste final binning into numeric woe file*/

proc datasets kill;
run; quit;


/******************************************************************************************************/

/*CHAMPION CHECK NUMBER BINNING*/

data test(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 5;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 6;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 7;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 8;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 9;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 10;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 11;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 12;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 13;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 14;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 15;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 16;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 17;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 18;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 19;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 20;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 21;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 22;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 23;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 24;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 25;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 26;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 27;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 28;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 29;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 30;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 31;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 32;
else wCHECK_NUMBER = 33;
run;


data valdt(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 5;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 6;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 7;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 8;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 9;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 10;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 11;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 12;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 13;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 14;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 15;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 16;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 17;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 18;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 19;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 20;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 21;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 22;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 23;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 24;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 25;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 26;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 27;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 28;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 29;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 30;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 31;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 32;
else wCHECK_NUMBER = 33;
run;


proc sql;
select sum(wgt) into : test_count
from test;

create table test_perf as
select wCHECK_NUMBER
	,min(CHECK_NUMBER) as MIN_CHECK_NUMBER
	,max(CHECK_NUMBER) as MAX_CHECK_NUMBER

	,sum(wgt)/&test_count as PCNT_OF_TEST
	,sum(BAD)/sum(wgt) as PCNT_BAD_TEST
from test
group by wCHECK_NUMBER;

select sum(wgt) into : vldt_count
from valdt;

create table vldt_perf as
select wCHECK_NUMBER
	,sum(wgt)/&vldt_count as PCNT_OF_VLDT
	,sum(BAD)/sum(wgt) as PCNT_BAD_VLDT
from valdt
group by wCHECK_NUMBER;
quit;

data checkno_perf;
merge test_perf(in=a) vldt_perf(in=b);
by wCHECK_NUMBER;
if a;
run;

proc export data = checkno_perf
outfile = "&output\Check Number Binning Champion.xlsb"
dbms = excelcs replace;
sheet = round1;
run;

proc datasets kill;
run; quit;

/******************************NOW CREATE BINS******************************/

data test(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 1;
else wCHECK_NUMBER = 1;
run;


data valdt(keep = bad wgt CHECK_NUMBER wCHECK_NUMBER);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));

if CHECK_NUMBER = 0 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 99 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 199 then wCHECK_NUMBER = 4;
else if CHECK_NUMBER <= 299 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 399 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 499 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 599 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 699 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 799 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 899 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 999 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1099 then wCHECK_NUMBER = 3;
else if CHECK_NUMBER <= 1199 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1299 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1399 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1499 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 1999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 2499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 2999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3499 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 3999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 4999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 5999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 6999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 7999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 8999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9998 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999 then wCHECK_NUMBER = 2;
else if CHECK_NUMBER <= 99999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 9999999 then wCHECK_NUMBER = 1;
else if CHECK_NUMBER <= 99999999 then wCHECK_NUMBER = 1;
else wCHECK_NUMBER = 1;
run;


proc sql;
select sum(wgt) into : test_count
from test;

create table test_perf as
select wCHECK_NUMBER
	,min(CHECK_NUMBER) as MIN_CHECK_NUMBER
	,max(CHECK_NUMBER) as MAX_CHECK_NUMBER

	,sum(wgt)/&test_count as PCNT_OF_TEST
	,sum(BAD)/sum(wgt) as PCNT_BAD_TEST
from test
group by wCHECK_NUMBER;

select sum(wgt) into : vldt_count
from valdt;

create table vldt_perf as
select wCHECK_NUMBER
	,sum(wgt)/&vldt_count as PCNT_OF_VLDT
	,sum(BAD)/sum(wgt) as PCNT_BAD_VLDT
from valdt
group by wCHECK_NUMBER;
quit;

data checkno_perf;
merge test_perf(in=a) vldt_perf(in=b);
by wCHECK_NUMBER;
if a;
run;
proc print data = checkno_perf noobs; run;

proc export data = checkno_perf
outfile = "&output\Check Number Binning Champion.xlsb"
dbms = excelcs replace;
sheet = final;
run;

/*BIN LOCAL HOUR ** BIN LOCAL HOUR ** BIN LOCAL HOUR ** BIN LOCAL HOUR ** BIN LOCAL HOUR ** BIN LOCAL HOUR*/

/*challenger*/

data test(keep = bad wgt local_hour);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
run;

data validate(keep = bad wgt local_hour);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
run;

proc sql;
create table test_bad_rates as
select LOCAL_HOUR
	,sum(wgt) as TRAN_COUNT_TEST
	,sum(bad) as BAD_COUNT_TEST
	,sum(bad)/sum(wgt) as BAD_RATE_TEST
from test
group by LOCAL_HOUR;

create table vldt_bad_rates as
select LOCAL_HOUR
	,sum(wgt) as TRAN_COUNT_VLDT
	,sum(bad) as BAD_COUNT_VLDT
	,sum(bad)/sum(wgt) as BAD_RATE_VLDT
from validate
group by LOCAL_HOUR;
quit;

data bad_rates;
merge test_bad_rates(in=a) vldt_bad_rates(in=b);
by LOCAL_HOUR;
run;
proc print data = bad_rates noobs; run;

proc export data = bad_rates
outfile = "&output\Local Hour Challenger.xlsb"
dbms = excelcs replace;
sheet = round1;
run;

proc datasets kill;
run; quit;

/******************************CHAMPION BINNING******************************/

data test(keep = bad wgt local_hour);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
run;

data validate(keep = bad wgt local_hour);
set data.validate_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
run;

proc sql;
create table test_bad_rates as
select LOCAL_HOUR
	,sum(wgt) as TRAN_COUNT_TEST
	,sum(bad) as BAD_COUNT_TEST
	,sum(bad)/sum(wgt) as BAD_RATE_TEST
from test
group by LOCAL_HOUR;

create table vldt_bad_rates as
select LOCAL_HOUR
	,sum(wgt) as TRAN_COUNT_VLDT
	,sum(bad) as BAD_COUNT_VLDT
	,sum(bad)/sum(wgt) as BAD_RATE_VLDT
from validate
group by LOCAL_HOUR;
quit;

data bad_rates;
merge test_bad_rates(in=a) vldt_bad_rates(in=b);
by LOCAL_HOUR;
run;
proc print data = bad_rates noobs; run;

proc export data = bad_rates
outfile = "&output\Local Hour Champion.xlsb"
dbms = excelcs replace;
sheet = round1;
run;

proc datasets kill;
run; quit;



/*******************Run individual regression on each attribute*******************/

data temp(keep = bad wgt &wchar_vars &wnum_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
%include "&output\woe_num_chall.woe";
%include "&output\woe_char_chall.woe";
run;
proc contents data = temp(drop = bad wgt) out=vars(keep = name) noprint; run;

proc sql;
select count(*) into : var_count
from vars;
quit;

%macro tester;

%do i = 1 %to &var_count;

	data _null_;
	set vars;
	if _n_ = &i then call symput('varm',name);
	run;

	proc logistic data=temp namelen=30;
	  class &varm /PARAM=REF;
	  model bad = &varm /lackfit ridging=NONE;
	  weight wgt;
	  ods output Type3 = chi;	
	run;

		data chi(drop=effect);
		set chi; 
		length variable $ 30.;
		 variable = "&varm";
		run;

	%if &i = 1 %then %do;
		proc sql;
		create table var_stats as 
		select variable, DF, WaldChiSq, ProbChiSq
		from chi;
		quit;
	%end;
	%else %if &i > 1 %then %do;
		data var_stats; set var_stats chi; run;
	%end;

proc delete data = chi; run;

%end;

%mend;

%tester;

proc sort data = var_stats out = data.challenger_var_stats; by descending WaldChiSq; run;

proc export data = data.challenger_var_stats
outfile = "&output\da_var_stats.xlsb"
dbms = excelcs replace;
run;
proc datasets kill;
run; quit;


/*Run individual regression on each attribute*/

data temp(keep = bad wgt &wchar_vars &wnum_vars);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
%include "&output\woe_num_champ.woe";
%include "&output\woe_char_champ.woe";
run;

proc contents data = temp(drop = bad wgt) out=vars(keep = name) noprint; run;

proc sql;
select count(*) into : var_count
from vars;
quit;

%macro tester;

%do i = 1 %to &var_count;

	data _null_;
	set vars;
	if _n_ = &i then call symput('varm',name);
	run;

	proc logistic data=temp namelen=30;
	  class &varm /PARAM=REF;
	  model bad = &varm /lackfit ridging=NONE;
	  weight wgt;
	  ods output Type3 = chi;	
	run;

		data chi(drop=effect);
		set chi; 
		length variable $ 30.;
		 variable = "&varm";
		run;

	%if &i = 1 %then %do;
		proc sql;
		create table var_stats as 
		select variable, DF, WaldChiSq, ProbChiSq
		from chi;
		quit;
	%end;
	%else %if &i > 1 %then %do;
		data var_stats; set var_stats chi; run;
	%end;

proc delete data = chi; run;

%end;

%mend;

%tester;

proc sort data = var_stats out = data.champion_var_stats; by descending WaldChiSq; run;

proc export data = data.champion_var_stats
outfile = "&output\no_da_var_stats.xlsb"
dbms = excelcs replace;
run;
proc datasets kill;
run; quit;


/*I forgot face amount*/

data temp(keep = bad FACE_AMOUNT);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'Y'));
run;

/*NUMERIC WOE*/
%include "C:\Local Model Build Code\woe.sas";
%woe(data=temp,y=bad,pvalue=0.05,groups=10,outfile=&output\woe_face_amount_chall,merge_step_printed=No);

proc datasets kill;
run; quit;


/******************************CHAMPION BINNING******************************/

data temp(keep = bad FACE_AMOUNT);
set data.test_data(where = (NAT_AUTH_RESULT = 'A'
					and delete_flag = 0
					and DA25_CHALLENGER_IND = 'N'));
run;

/*NUMERIC WOE*/
%include "C:\Local Model Build Code\woe.sas";
%woe(data=temp,y=bad,pvalue=0.05,groups=10,outfile=&output\woe_face_amount_champ,merge_step_printed=No);

proc datasets kill;
run; quit;







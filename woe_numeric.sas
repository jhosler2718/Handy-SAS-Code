%let EPS = 1.0e-30;  /* global macro variable used to avoid 0/0 */

/* This is the main macro of woe program */
%macro woe(data =, y =, pvalue =, groups =, outfile =, merge_step_printed =);
	/* Define output files. These files can not be existed when the program begins. */
	filename sascode "&outfile..sas" mod;  /* sas code to run woe program */
	filename woeout  "&outfile..out" mod;  /* univariate gains chart */
	filename woecode "&outfile..woe" mod;  /* sas code for woe recode */
	filename ksinfo  "&outfile..sig"  mod;  /* ks and infoval  */

	proc contents data = &data (keep = _numeric_) noprint out = varlist;
	run;

	data varlist;
		set varlist;
		if upcase(name) ^= upcase("&y");  /*scrub out any variable named "bad"*/
		/*SCRUB OUT THE FOLLOWING VARIABLES THAT NEED TO BE CLASSIFIED AS CATEGORITCAL*/
			/*OR THAT ARE JUST PLAIN CRAP --- ADDED BY JEH MARCH 23, 2009*/
			if upcase(name) = 'DAY_OF_WEEK' then delete;
				if upcase(name) = 'TS_SECOND_SIC_MAX_NO_CHK_24M' then delete; 
					if upcase(name) = 'TS_FIRST_SIC_MAX_NO_CHK_24M' then delete; 
						if upcase(name) = 'TS_SIC_MAX_DLR_AMT_24M' then delete;
			if upcase(name) = 'TS_DT_FIRST_CHK' then delete;
				if upcase(name) = 'TS_DT_LAST_APP_CHK' then delete; 
					if upcase(name) = 'TS_DT_LAST_CHK' then delete; 
						if upcase(name) = 'TS_DT_LAST_UNAPP_CHK' then delete;
			if upcase(name) = 'TS_DT_MAX_DLR_AMT' then delete;
				if upcase(name) = 'TS_DT_MAX_PAID_CLM' then delete; 
					if upcase(name) = 'TS_DT_PAID_LAST_CLM' then delete; 
						if upcase(name) = 'TS_DT_PYMNT_FIRST_PAID_CLM' then delete;
			if upcase(name) = 'A' then delete;
				if upcase(name) = 'YY' then delete; 
					if upcase(name) = 'BAD_DOLLARS' then delete; 
						if upcase(name) = 'WGT' then delete;
			if upcase(name) = 'FNSCORE' then delete;
				if upcase(name) = 'FRAUD' then delete; 
					if upcase(name) = 'FRAUD_TYPE' then delete;
						if upcase(name) = 'SALVAGE' then delete; 
			if upcase(name) = 'SVC_CHG' then delete;
				if upcase(name) = 'SVC_COLL' then delete; 
					if upcase(name) = 'TRANS_DATE' then delete;
						if upcase(name) = 'TRANS_NO' then delete;
			if upcase(name) = 'DEPVAR' then delete;



	run;

	proc sort data = varlist;
		by name;
	run;

	data _null_;
		set varlist;
		file sascode;
		num+1;
		put '%do_woe'"(data = &data, x = " name", y = &y, groups = &groups, pvalue = &pvalue,
                 num = " num")";
	run;

	%inc sascode;
%mend woe;


/* do woe for one variable x NOTE: THIS MACRO IS BEING CALLED FROM THE SAS CODE CREATED ABOVE*/
%macro do_woe(data =, x =, y =, groups =, pvalue =, num =);


		DM 'Clear log';
		DM 'Clear output';

	data _tmp;
		set &data (keep = &x &y) end = eof;  /* x - anlaysis variable, y - response variable*/
			
		retain total_record total_record_nonmissing 0;
		drop total_record total_record_nonmissing;
		total_record + 1;

		if &x ^= . and &y ^= . then total_record_nonmissing + 1;
		if eof then do;
			call symput('TOTAL_RECORD', trim(left(total_record)));
			call symput('TOTAL_RECORD_NONMISSING', trim(left(total_record_nonmissing)));
		end;

		if &y ^= .;    /* keep missing x but drop missing reponse variable */
	run;

	%if &TOTAL_RECORD_NONMISSING = 0 %then %do;
/*	in the event that there are no records without missing values produce a data set*/
/*		with independent variable = 0 for two observations with one observations independent*/
/*		variable = 1 and the other 0*/
		data _tmp;
			&x = 0; &y = 0; output;
			&x = 0; &y = 1; output;
		run;
	%end;

	proc rank data = _tmp groups = &groups out = _rtmp;		/*can create deciles for variable values*/
		var &x;
		ranks r&x;
	run;
	
	/*here looking at the summary statistics for both the dependent and independent varaibles by rank*/ 
	proc summary data = _rtmp missing nway min max mean sum;
		class r&x;
		var &x &y;
		output out = _tmp 
				mean(&x) = xmean 
				min(&x) = xmin 
				max(&x) = xmax 
				n = n 
				sum(&y) = y1sum;
	run;

	data _tmp (keep = r&x n xmean xmin xmax y1sum y0sum ymean);
		set _tmp;
		n = _freq_;
		y0sum = n - y1sum;
		ymean = y1sum/n;

		if _n_ = 1 then do;
			call symput('MISSING_X', trim(left(0)));
			call symput('MISSING_Y1SUM', trim(left(0)));
			call symput('MISSING_Y0SUM', trim(left(0)));
			if r&x = . then do;
				call symput('MISSING_X', trim(left(1)));
				call symput('MISSING_Y1SUM', trim(left(y1sum)));
				call symput('MISSING_Y0SUM', trim(left(y0sum)));
				delete;
			end;
		end;
	run;

	%get_ksinfo(data = _tmp)	
	%print_gainschart(data = __tmp, x = &x, num = &num)

	%merge_group(data = _tmp, pvalue = &pvalue)

	%get_ksinfo(data = _tmp)
	%print_gainschart(data = __tmp, x = &x, num = &num)
	%print_woe(data = __tmp, x = &x)
	%print_ksinfo(data = __tmp, x = &x, num = &num)

%mend do_woe;


/* Calculate ks and info value */
%macro get_ksinfo(data =);
	%global TOTAL_Y1 TOTAL_Y0;
	data _&data;
		set &data end = eof;
		cum_y1 + y1sum;
		cum_y0 + y0sum;
		if eof then do;
			call symput('TOTAL_Y1', trim(left(cum_y1)));
			call symput('TOTAL_Y0', trim(left(cum_y0)));
		end;	
	run;
	
	data _&data;
		set _&data;
		retain maxks 0;
		tot_y1 = &TOTAL_Y1;
		tot_y0 = &TOTAL_Y0;
		tot = tot_y1 + tot_y0;

		p_cum_y1 = 100 * cum_y1 / (tot_y1 + &EPS);   /*EPS = 1.0e-30*/
		p_cum_y0 = 100 * cum_y0 / (tot_y0 + &EPS);
		ks = abs(p_cum_y1 - p_cum_y0);
		if maxks < ks then maxks = ks;

		p_y1 = y1sum / (tot_y1 + &EPS);
		p_y0 = y0sum / (tot_y0 + &EPS);
		woe = log((p_y1 + &EPS) / (p_y0 + &EPS));
		info = (p_y1 - p_y0) * woe;
		tot_info + info;

		ratio = 100 * p_y1 / (p_y0 + &EPS);
		rate_y1 = 100 * y1sum / (y1sum + y0sum + &EPS);
		totrate_y1 = 100 * tot_y1 / (tot_y1 + tot_y0 + &EPS);
	run;
%mend get_ksinfo;


/* Print out the gainschart for each variable */
%macro print_gainschart(data =, x =, num =);
	data _null_;
		set &data end = eof;
		file woeout; 
		length undln1 undln2 $120;
		length lenstar $20;
		undln1 = repeat('-', 120);
		undln2 = repeat('=', 120);
		lenrat = abs(round(7*woe, 1)) - 1;
		if lenrat > 14 then lenrat = 14;

		if woe > 0 then do;
			if lenrat < 0 then lenstar = "+";
			else lenstar= "+" || repeat("*", lenrat); 
			posrat = 1 ; 
		end;
		else do; 
			if lenrat < 0 then lenstar = "+";
			else lenstar = repeat("*", lenrat) || "+"; 
			posrat = 0-lenrat; 
		end;

		if _n_ = 1 then do; 
			put / @1 "Variable # = &num  Variable = &x  " @;
			put "# obs = &TOTAL_RECORD  # valid = &TOTAL_RECORD_NONMISSING  % valid = %sysevalf(100*&TOTAL_RECORD_NONMISSING/&TOTAL_RECORD)"; 
			put @1 undln1;
			put '                     #         #      %cum        #      %cum     odds      %                            histogram of';
			put ' #      xmax       total     (y=1)    (y=1)     (y=0)    (y=0)   ratio    (y=1)      woe       ks      woe (normalized)';
			put @1 undln1 /;
		end;
		put 	@1  _n_ 
			@7  xmax BEST8.
			@16 n comma9.
			@26 y1sum COMMA9.
			@39 p_cum_y1 5.2 
			@45 y0sum COMMA9. 
			@58 p_cum_y0 5.2 
			@67 ratio 4. 
			@75 rate_y1 5.2 
			@84 woe 6.3 
			@94 ks 5.2 
			@(111+POSRAT) LENSTAR;
		if eof then do;
			put @1 undln2;
			put 	@1 'Total' 
				@16 tot comma9.
				@26 tot_y1 COMMA9. 
				@45 tot_y0 COMMA9.  
				@67 ' 100' 
				@75 totrate_y1 5.2 
				@85 'Max KS ='
				@94 maxks 5.2 
				@102 'Info Val =' tot_info 8.4;
			put @1 undln2 /;
		end;
	run;
%mend print_gainschart;


/* print out ks and info value to ksinfo file */
%macro print_ksinfo(data =, x =, num =);
	data _null_;
		set &data end = eof;
		file ksinfo;

		if eof then put "&num" @8 "&x" @42 "w&x" @76 'Max KS = ' @86 maxks 5.2 
				@93 'Info Value = ' @107 tot_info 6.4 ;
	run;
%mend print_ksinfo;


/* print out the woe code for each variable */
%macro print_woe(data =, x =);
	data _null_;
		set &data end = eof;
		file woecode; 
		retain pre_xmax;

		if _n_ = 1 then do;
 			put // "/* WOE recoding for &x */";
			put  "if ( -1e38 < &x <= " xmax ") then w&x = " woe 9.6 ";";
		end; 
		else if eof then do;
			put "else if ( &x > " pre_xmax ") then w&x = " woe 9.6 ";";
			%if (&MISSING_X = 1) %then %do;
				p_y1 = &MISSING_Y1SUM / (&TOTAL_Y1 + &EPS);
				p_y0 = &MISSING_Y0SUM / (&TOTAL_Y0 + &EPS);
				woe = log((p_y1 + &EPS) / (p_y0 + &EPS));
				put "else w&x = " woe 9.6 ";";
			%end;				
			%else %do; 
				put "else w&x = 0;";
			%end;
			
		end;
		else do;
			put "else if ( " pre_xmax "< &x <= " xmax ") then w&x = " woe 9.6 ";";
		end;

		pre_xmax = xmax;
	run;
%mend print_woe;


/* merge groups according to pvalue threshold */		
%macro merge_group(data =, pvalue =);
	%let MERGESTEP = 0;
	%let DONE = 0;

	/*print table if option selected*/
	%if %upcase(&merge_step_printed) = YES %then %do;
		proc print data = &data;
			title2 'Before merging';
		run;
	%end;

	/*proceed as long as the largest p-value is still above our set threshold, 0.05*/ 
	%do %while(&DONE = 0);
		%let MERGESTEP = %eval(&MERGESTEP + 1);

		/* calculate chi-square for each pair of groups */
		data &data (drop = pre_y1sum pre_y0sum);
			set &data; 
			retain pre_y1sum pre_y0sum;
			if _n_ = 1 then pval = 0;  /* less than normal pvalue */
			else do;
				%chisq(pre_y1sum, pre_y0sum, y1sum, y0sum, QP)
				pval = 1 - probchi(QP, 1);
			end;
			
			pre_y1sum = y1sum;
			pre_y0sum = y0sum;
		run;

		/* find the pair with max p-value */
		data &data;
			set &data end = eof;
			retain loc 0;
			retain pval_max 0;
			if pval_max < pval then do;
				loc = _n_;
				pval_max = pval;
			end;
			
			if eof then do;
				call symput("LOC", trim(left(loc)));	
				if pval_max < &pvalue then call symput("DONE", 1);
			end;
		run;

		%if %upcase(&merge_step_printed) = YES %then %do;
			proc print data = &data;
				title2 'Look for groups to merge';
			run;
		%end;

		/* merge 2 groups */ 
		%if &DONE = 0 %then %do;
			data &data (keep = r&x n xmean xmin xmax y1sum y0sum ymean);
				set &data;
				retain pre_n pre_xmean pre_xmin pre_xmax pre_y1sum pre_y0sum;

				if _n_ < &LOC - 1 or _n_ > &LOC then output;
				else if _n_ = &LOC then do;
					xmean = (xmean * n + pre_xmean * pre_n)/(n + pre_n); 
					xmin = min(xmin, pre_xmin);
					xmax = max(xmax, pre_xmax);
					y1sum = y1sum + pre_y1sum; 
					y0sum = y0sum + pre_y0sum;
					n = n + pre_n;
					ymean = y1sum/n;
					output;
				end;

				pre_n = n;
				pre_xmean = xmean;
				pre_xmin = xmin;
				pre_xmax = xmax;
				pre_y1sum = y1sum;
				pre_y0sum = y0sum;
			run;	

			%if %upcase(&merge_step_printed) = YES %then %do;
				proc print data = &data;
					title2 "Merge: Step &MERGESTEP";
				run;
			%end;
		%end;
	%end;
%mend merge_group;


/* Calculate Pearson chi-square based on 2x2 table */
%macro chisq(n11, n12, n21, n22, chisq);
	&chisq = (&n11+&n12+&n21+&n22)*(&n11*&n22-&n12*&n21)**2
		/(&n11+&n12+&EPS)/(&n21+&n22+&EPS)/(&n11+&n21+&EPS)/(&n12+&n22+&EPS);
%mend chisq;

/********************* end of woe.sas ********************************************/
%*woe(data=test1, 
		y=bad, 
		pvalue=0.05, 
		groups=10, 
		outfile=C:\Documents and Settings\WuWx\My Documents\Decision Sciences\Pep Boys\result, 
		merge_step_printed=No);


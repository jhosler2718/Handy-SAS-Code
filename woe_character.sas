%let EPS = 1.0e-30; /* global macro variable used to avoid 0/0 */

/* This is the main macro of woe program */
%macro woe_character(data =, y =, pvalue =, outfile =, merge_step_printed =);
	/* Define output files. These files can not be existed when the program begins. */
	filename sascode "&outfile..sas" mod;  /* sas code to run woe program */
	filename woeout  "&outfile..out" mod;  /* univariate gains chart */
	filename woecode "&outfile..woe" mod;  /* sas code for woe recode */
	filename ksinfo  "&outfile..sig" mod;  /* ks and infoval  */

	proc contents data = &data noprint out = varlist;
	run;

	data varlist;
		set varlist;
		if upcase(name) ^= upcase("&y");
	run;

	proc sort data = varlist;
		by name;
	run;

	data _null_;
		set varlist;
		file sascode;
		num+1;
		put '%do_woe'"(data = &data, x = " name", y = &y, pvalue = &pvalue, label = " 
			label ", num = " num")";
	run;

	%inc sascode;
%mend;


/* do woe for one variable x */
%macro do_woe(data =, x =, y =, pvalue =, label =, num =);
	data _tmp;
		set &data (keep = &x &y);
		where &y ^= .;
	run;

	proc summary data = _tmp nway min max mean sum;
		class &x / missing;
		var &y;
		output out = _tmp n = n sum(&y) = y1sum mean(&y) = ymean;
	run;

	/* sort categories according to ymean. It will be the order of merging.  */
	proc sort data = _tmp;
		by ymean;
	run;

	data _tmp (keep = &x xcat n y1sum y0sum ymean);
		set _tmp;
		length xcat $20000;
		y0sum = n - y1sum;
		xcat = "'" || trim(&x) || "'";
	run;

	%get_ksinfo(data = _tmp)
	%print_gainschart(data = __tmp, x = &x, label = &label, num = &num)

	%merge_group(data = _tmp, pvalue = &pvalue)

	%get_ksinfo(data = _tmp)
	%print_gainschart(data = __tmp, x = &x, label = &label, num = &num)
	%print_woe(data = __tmp, x = &x, label = &label)
	%print_ksinfo(data = __tmp, x = &x, label = &label, num = &num)

	DM 'Clear log';
	DM 'Clear output';

%mend do_woe;


/* Calculate ks and info value */
%macro get_ksinfo(data =);
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

		p_cum_y1 = 100 * cum_y1/(tot_y1 + &EPS);
		p_cum_y0 = 100 * cum_y0/(tot_y0 + &EPS);
		ks = abs(p_cum_y1 - p_cum_y0);
		if maxks < ks then maxks = ks;

		p_y1 = y1sum/tot_y1;
		p_y0 = y0sum/tot_y0;
		woe = log((p_y1+&EPS)/(p_y0+&EPS));
		info = (p_y1 - p_y0) * woe;
		tot_info + info;

		ratio = 100 * p_y1/(p_y0 + &EPS);
		rate_y1 = 100 * y1sum/(y1sum + y0sum + &EPS);
		totrate_y1 = 100 * tot_y1/(tot_y1 + tot_y0 + &EPS);
	run;
%mend get_ksinfo;


/* Print out the gainschart for each variable */
%macro print_gainschart(data =, x =, label =, num =);
	data _null_;
		set &data end = eof;
		file woeout;
		length undln1 $120;
		undln1 = repeat('-', 120);
		if _n_ = 1 then do; 
			put / @1 "Variable # = &num          Variable = &x          &label"; 
			put @1 undln1;
		end;		
		if length(xcat) < 100 then put @1 _n_ @7 xcat;
		else do;
			put @1 _n_ @7 @;
			%print_xcat(xcat)
		end;
		if eof then put @1 undln1;
	run;

	data _null_;
		set &data end = eof;
		file woeout; 
		length undln1 undln2 $120;
		length lenstar $20;
		undln1 = repeat('-', 120);
		undln2 = repeat('=', 120);
		lenrat = abs(round(5*woe, 1)) - 1;
		if lenrat > 10 then lenrat = 10;

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
			put / @1 "Variable # = &num          Variable = &x          &label"; 
			put @1 undln1;
			put '                     #         #      %cum        #      %cum     odds      %                            histogram of';
			put ' #      x          total     (y=1)    (y=1)     (y=0)    (y=0)   ratio    (y=1)      woe       ks      woe (normalized)';
			put @1 undln1 /;
		end;
		put 	@1  _n_ 
			@7  'cat' 
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
%macro print_ksinfo(data =, x =, label =, num =);
	data _null_;
		set &data end = eof;
		file ksinfo;

		if eof then put "&num" @8 "&x" @42 "w&x" @76 'Max KS = ' @86 maxks 5.2 
				@93 'Info Value = ' @107 tot_info 6.4 @116 "&label";
	run;
%mend print_ksinfo;


/* print out the woe code for each variable */
%macro print_woe(data =, x =, label =);
	data _null_;
		set &data end = eof;
		file woecode; 
		length xtmp $200;
		xtmp = "'" || trim(&x) || "'";

		if _n_ = 1 then do;
 			put // "/* WOE recoding for &x */";
			if xtmp = xcat then put  "if &x = " xcat "then w&x = " woe 9.6 ";";
			else if length(xcat) < 100 then put "if &x in ( " xcat ") then w&x = " woe 9.6 ";";
			else do;
				put "if &x in ( " @;
				%print_xcat(xcat)
				put ") then w&x = " woe 9.6 ";";
			end;
		end; 
		else if eof then do;
			if xtmp = xcat then put "else if &x = " xcat "then w&x = " woe 9.6 ";";
			else if length(xcat) < 100 then put "else if &x in ( " xcat ") then w&x = " woe 9.6 ";";
			else do;
				put "else if &x in ( " @;
				%print_xcat(xcat)
				put ") then w&x = " woe 9.6 ";";
			end;
			put "else w&x = 0;";
			put "label w&x = 'WOE of &label';";
		end;
		else do;
			if xtmp = xcat then put "else if &x = " xcat "then w&x = " woe 9.6 ";";
			else if length(xcat) < 100 then put "else if &x in ( " xcat ") then w&x = " woe 9.6 ";";
			else do;
				put "else if &x in ( " @; 
				%print_xcat(xcat)
				put ") then w&x = " woe 9.6 ";";
			end;			
		end;
	run;
%mend print_woe;


/* merge groups according to pvalue threshold */		
%macro merge_group(data =, pvalue =);
	%let MERGESTEP = 0;
	%let DONE = 0;

	%if %upcase(&merge_step_printed) = YES %then %do;
		proc print data = &data;
			title2 'Before merging';
		run;
	%end;

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
			data &data (keep = &x n xcat y1sum y0sum ymean);
				set &data;
				length pre_xcat $20000;
				retain pre_xcat pre_n pre_y1sum pre_y0sum;

				if _n_ < &LOC - 1 or _n_ > &LOC then output;
				else if _n_ = &LOC then do;
					xcat = trim(pre_xcat) || ", " || trim(xcat);
					y1sum = y1sum + pre_y1sum; 
					y0sum = y0sum + pre_y0sum;
					n = n + pre_n;
					ymean = y1sum/n;
					output;
				end;

				pre_n = n;
				pre_xcat = xcat;
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


/* print each element in xcat in one line */
%macro print_xcat(xcat);
	_xcat = &xcat;
	_pos = 1;
	do while(_pos > 0);
		_pos = index(_xcat, "',");
		if _pos > 0 then do;
			_xcat2 = substr(_xcat, 1, _pos + 1);
			_xcat = substr(_xcat, _pos + 2);
			put ' ' _xcat2;
		end;
		else put ' ' _xcat;
	end;
	drop _xcat _xcat2 _pos;
%mend print_xcat;


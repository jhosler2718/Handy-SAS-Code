/* If you choose, you can edit your calendar ranges here.  No other edits  */
/* are needed to the steps creating the data set CALENDAR.                 */

%let start='01jan2010'd;
%let stop='01jan2020'd;

/* Create a date set for holidays.  Adjust to fit your company's needs.     */
/* Note logic is illustrated for 'static' holidays and 'observed' holidays. */

data holidays;
  length type $25;
  format dt date9.;
  do year=year(&start) to year(&stop);

    /* example of 'observed' holiday logic  */
    type='New Years Day Observed';
    dt=MDY(1,1,YEAR);
    FDOY=dt;
    if weekday(dt)=1 then dt=dt+1;
    else if weekday(dt)=7 then dt=mdy(12,31,year-1);
    output;

    /* example of static holiday logic */
    type='Martin Luther King Day';
    dt=intnx('week.2',fdoy,(weekday(fdoy) ne 2)+2);
    output;

    type="Presidents Day";
    fdo_feb=intnx('month',fdoy,1);
    dt=intnx('week.2',fdo_feb,(weekday(fdo_feb) ne 2)+2);
    output;

    type='Memorial Day';
    fdo_may=intnx('month',fdoy,4);
    dt=intnx('week.2',fdo_may,(weekday(fdo_may) in (1,7))+4);
    output;

    type='Independance Day Observed';
    dt=MDY(7,4,YEAR);
    if weekday(dt)=1 then dt=dt+1;
    else if weekday(dt)=7 then dt=dt-1;
    output;

    type='Labor Day';
    fdo_sep=intnx('month',fdoy,8);
    dt=intnx('week.2',fdo_sep,(weekday(fdo_sep) ne 2));
    output;

    type='Election Day';
    fdo_nov=intnx('month',fdoy,10);
    dt=intnx('week.3',fdo_nov,1);
    output;

    type='Veterans Day Observed';
    dt=MDY(11,11,YEAR);
    if weekday(dt)=1 then dt=dt+1;
    else if weekday(dt)=7 then dt=dt-1;
    output;

    type='Thanksgiving Day';
    dt=intnx('week.5',fdo_nov,(weekday(fdo_nov) ne 5)+3);
    output;

    type='Christmas Day Observed';
    dt=MDY(12,25,YEAR);
    if weekday(dt)=1 then dt=dt+1;
    else if weekday(dt)=7 then dt=dt-1;
    output;
  end;
  keep dt type;
run;

proc sort data=holidays;
  by dt;
run;


/* Create a data set of weekends via the WEEKDAY function  */

data weekends;
  length type $25;
    format dt date9.;
  type='Weekend';
  do dt=&start to &stop;
    if weekday(dt) in (1,7) then output;
  end;
run;

/* Create a data set of all the days in the specified date range. */
/* TYPE will have the value 'Workday' for all observations.       */
/* Specifying ALLDAYS first in the following MERGE will allow any */
/* date matches from from HOLIDAY or WEEKEND to overwrite the     */
/* value of TYPE with the appropriate type of day.                */

data alldays;
  length type $25;
      format dt date9.;
  type='Workday';
  do dt=&start to &stop;
     output;
  end;
run;

data calendar;
/*  format dt date9.;*/
  merge alldays(in=a) weekends(in=w) holidays(in=h);
  by dt;
run;

/* Generate dummy data to use with CALENDAR for testing purposes */

data test;
  startdt='01nov2011'd;  stopdt='30nov2011'd;
  output;
  startdt='01jan2011'd;  stopdt='10jul2011'd;
  output;
  startdt='20dec2011'd;  stopdt='15jan2011'd;
  output;
  format startdt stopdt date9.;
run;

/* Method 1:  SQL */

proc sql;
  create table final_sql as
  select startdt format=date9.,
         stopdt format=date9.,
         (select count(*)
          from calendar
          where dt between stopdt and startdt
            and type = 'Workday') as workdays
  from test;
quit;

proc print data=final_sql;
  title 'Output from PROC SQL';
run;

/* Method 2:  DATA step using an INDEX and KEY=  */

/* Build index on CALENDAR */

proc datasets library=work nolist;
  modify calendar;
  index create dt;
quit;

data final_idx;
  set test;
  workdays=0;
  /* For each date between STARTDT and STOPDT, check to see if DT is a workday. */
  /* If so, increment the new variable WORKDAYS by 1.                           */
  do i=startdt to stopdt;
    dt=i;
    /* Look up the current value of DT in CALENDAR using the index on DT */
    set calendar key=dt/unique;
    /* Check return code from search */
    select (_iorc_);

      /* Match found */
      when (%sysrc(_sok)) do;
        if type='Workday' then workdays+1;
        if i=stopdt then output;
      end;

      /* Match not found in master */
      when (%sysrc(_dsenom)) do;
         _ERROR_=0;
      end;

      otherwise do;
        put 'Unexpected ERROR: _iorc_= ' _iorc_;
        stop;
      end;
    end;
  end;
  keep startdt stopdt workdays;
run;

proc print data=final_idx;
  title "Output from DATA Step";
run;

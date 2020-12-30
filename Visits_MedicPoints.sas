/*create library*/
libname Opdte "w:\SAS\Health-01";
libname Ipdte "w:\SAS\Health-02";
libname Enrol  "w:\SAS\Health-07";
libname Course "w:\SAS\";

/*Note::*/
/*OPDTE 1-12 month & only "10"*/

data year;
	input year $ @@;
	cards;
	103
	;
run;

data month;
	input month $ @@;
	cards;
	01 02 03 04 05 06 07 08 09 10 11 12
	;
run;

proc sql;
	create table ym as
	select *
	from year, month;
quit;

data aa;
	set ym;
	no+1;
run;


/*Problem 1.	Do counting and calculating for how many times for inpatient and outpatient visits and how much for inpatient and outpatient total medical points. 
		請分別於門住診檔中計算門住診就醫次數及門住診總就醫點數。*/

/***************/
/*OPDTE Dataset */
/***************/
%macro mv(x); 

	data _null_;
		set aa;
		text='opdte.h_nhi_opdte'||trim(year)||trim(month)||"_10"; 
		if no=&x then call symput('source',text);
	run;

	data course.opdte&x;
		set &source;

	proc sort data=course.opdte&x;
		by fee_ym appl_type appl_date case_type seq_no hosp_id;
	run;

%mend;


%macro loop;
	%do x=1 %to 12;
	%mv(&x);
	%end;
%mend;
%loop

/*Append datasets & sort*/
data course.opdte_all;
	set course.opdte1-course.opdte12;
run;

proc sort data=course.opdte_all;
	by id;
run;

/*Counting obs by ID*/
data course.opdte_all_visits;
	set course.opdte_all;
    by ID;
    if first.ID then op_visits=1;
    else op_visits+1;
run;

/*Total medical points*/
data course.opdte_all_visits_points;
	set course.opdte_all_visits;
	by id;
	retain op_total_points;
	op_total_points = op_total_points + t_dot;
	if first.id then op_total_points = t_dot;
run;

/*Group up by last ID*/
data course.opdte_all_visits_points;
	set course.opdte_all_visits_points;
	by id;
	if last.id;
run;


/***************/
/*IPDTE Dataset */
/***************/
data course.Ipdte;
	set Ipdte.H_nhi_ipdte103;
run;

/*Sort data by ID*/
proc sort data=course.ipdte;
	by ID;
run;


/*Counting obs by ID*/
data course.ipdte_visits;
	set course.ipdte;
    by ID;
    if first.ID then ip_visits=1;
    else ip_visits+1;
run;

/*Total medical points*/
data course.ipdte_visits_points;
	set course.ipdte_visits;
	by id;
	retain ip_total_points;
	ip_total_points = ip_total_points + med_dot;
	if first.id then ip_total_points = med_dot;
run;

/*Group up by last ID*/
data course.ipdte_visits_points;
	set course.ipdte_visits_points;
	by id;
	if last.id;
run;



/*Problem 2.	Then, merge with ENROL file (notice: you need to group by person). 
		接著，請與承保檔歸人後合併。*/

/***************/
/*ENROL Dataset */
/***************/

%macro mv_id(x); 
	data _null_;
		set aa;

		text='enrol.H_nhi_enrol'||trim(year)||trim(month); 
		if no=&x then call symput('source',text);
	run;

	data course.enrol&x;
		set &source;

	run;
%mend;

%macro loop;
	%do x=1 %to 12;
	%mv_id(&x);
	%end;
%mend;
%loop

/*Append 12 datasets into 1*/
data course.enrol_all;
	set course.enrol1-course.enrol12;
run;

/*Sort data by ID*/
proc sort data=course.enrol_all;
	by ID;
run;

/*No repeat data*/
proc sort data=course.enrol_all nodupkey;
	by id;
run;

/*merge ENROL with OPDETE & IPDTE*/
data course.en_op_ip;
	merge course.enrol_all(in=a) course.opdte_all_visits_points course.ipdte_visits_points;
	by ID;
	if a;
run;

/*Missing value assign 0*/
data course.en_op_ip;
	set course.en_op_ip;
	if ip_visits = . 				then ip_visits=0;
	if op_visits = . 			then op_visits=0;
	if ip_total_points= . 		then ip_total_points=0;
	if op_total_points= . 	then op_total_points=0;
run;


/*Problem 3.	Do proc freq procedure for inpatient and outpatient visits. 
						使用proc freq呈現門住診就醫次數。*/
title "Problem 3 - Display IPDTE & OPDTE visits";
proc freq data = course.en_op_ip;
	table ip_visits op_visits;
run;

/*Problem 4.	Create another new variable called “TotalMedPoint,” (Total medial points). */
data course.en_op_ip;
	set course.en_op_ip;
	TotalMedPoint = ip_total_points + op_total_points;
run;

/*Problem 5.	Finally, finish the following table. (Notice: you many apply only one procedure to print the table out.)*/
title "Problem 5 - Summary";
	proc means data = course.en_op_ip;
	var ip_visits op_visits TotalMedPoint ip_total_points op_total_points;
run;

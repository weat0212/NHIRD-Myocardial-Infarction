/*
██   ██ ██     ██ ██████  
██   ██ ██     ██      ██ 
███████ ██  █  ██  █████  
██   ██ ██ ███ ██      ██ 
██   ██  ███ ███  ██████  
*/

/**************************************/
/*Problem Topic: Myocardial infarction*/
/**************************************/

/*create library*/
libname Opdte "w:\SAS\Health-01";
libname Ipdte "w:\SAS\Health-02";
libname Enrol  "w:\SAS\Health-07";
libname HW "w:\SAS\";

/*Q2.Identify myocardial infarction (MI) patients: Based on lots of references, we could know that MI is divided by two types: acute myocardial infarction (ICD-9-CM 410) and other ischemic heart disease (ICD-9-CM 411-414). */
/*Based on the OUTPATIENT and INPATIENT datasets, for each subtypes how many patients have been diagnosed in that subtype?*/

/*++++++++++HINT++++++++++*/
/* 1. ICD by subtype*/
/* 2. Retain -> last, ID (padding 0)*/
/* 3. Identify MI -> Q3*/
/* 4. Grouping by person*/
/* 5. Freq*/
/*++++++++++++++++++++++++*/

/*---------------*/
/*-- IPDTE --*/
/*---------------*/
data HW.Ipdte410;
	set Ipdte.H_nhi_ipdte103;
	/*Find Acute myocardial infarction patients*/
	where substr(ICD9CM_1,1,3) =
	"410" |
	 substr(ICD9CM_2,1,3) =
	"410" |
	 substr(ICD9CM_3,1,3) =
	"410" |
	 substr(ICD9CM_4,1,3) =
	"410" |
	 substr(ICD9CM_5,1,3) =
	"410";
run;
proc sort data=HW.ipdte410 nodupkey;
	by id;
run;
/*OUTPUT=89*/

data HW.Ipdte411_414;
	set Ipdte.H_nhi_ipdte103;
	/*Find other ischemic heart disease patients*/
	where substr(ICD9CM_1,1,3) in
	("411","412","413","414") |
	 substr(ICD9CM_2,1,3) in
	("411","412","413","414") |
	 substr(ICD9CM_3,1,3) in
	("411","412","413","414") |
	 substr(ICD9CM_4,1,3) in
	("411","412","413","414") |
	 substr(ICD9CM_5,1,3) in
	("411","412","413","414");
run;
proc sort data=HW.ipdte411_414 nodupkey;
	by id;
run;
/*OUTPUT=508*/

/*Calculate the amount*/
data HW.ipdte_amount;
	set Ipdte.H_nhi_ipdte103;
run;

proc sort data = HW.ipdte_amount nodupkey;
	by id;
run;
/*Population Amount=8155*/

/*---------------*/
/*-- OPDTE --*/
/*---------------*/
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

data group;
input group $ @@;
cards;
10
;
run;

proc sql;
	create table ym as
	select *
	from year, month, group;
quit;

data aa;
	set ym;
	no+1;
run;

%macro mv(x);
	data _null_;
		set aa;
		text = 'opdte.H_nhi_opdte'|| trim(year) || trim(month) || "_" || trim(group); 
		if no= &x then call symput('source', text);
	run;

	data HW.OIHDOpdte&x;
		set &source;
		/*Find the Other ischemic heart disease patients*/
		where substr(ICD9CM_1,1,3) in
		("411","412","413","414") |
		 substr(ICD9CM_2,1,3) in
		("411","412","413","414") |
		  substr(ICD9CM_3,1,3) in
		("411","412","413","414");
	run;

	data HW.AMIOpdte&x;
		set &source;
		/*Find the Acute myocardial infarction patients*/
		where substr(ICD9CM_1,1,3) = "410" |
			substr(ICD9CM_2,1,3) = "410" |
			substr(ICD9CM_3,1,3) = "410";
	run;
%mend;

%macro loop;
	%do x=1 %to 12;
	%mv(&x);
	%end;
%mend;
%loop


/*MERGE PART*/
/*Acute myocardial infarction Part*/
data HW.OpdteAMI;
	set HW.AMIOpdte1-HW.AMIOpdte12;
run;
/*OUTPUT=1305*/

/*Other ischemic heart disease Part*/
data HW.OpdteOIHD;
	set HW.OIHDOpdte1-HW.OIHDOpdte12;
run;
/*OUTPUT=28362*/

/*FILTERING PART*/
proc sort data = HW.OpdteAMI nodupkey;
	by id;
run;
/*OUTPUT=170*/

proc sort data = HW.OpdteOIHD nodupkey;
	by id;
run;
/*OUTPUT=3842*/

/*Calculate the amount*/
%macro mv(x);
	data _null_;
		set aa;
		text = 'opdte.H_nhi_opdte'|| trim(year) || trim(month) || "_" || trim(group); 
		if no= &x then call symput('source', text);
	run;

	data HW.Opdte&x;
		set &source;
	run;
%mend;

%macro loop;
	%do x=1 %to 12;
	%mv(&x);
	%end;
%mend;
%loop

data HW.opdte_amount;
	set HW.Opdte1 - HW.Opdte12;
run;

proc sort data = HW.opdte_amount nodupkey;
	by id;
run;
/*Population Amount=90423*/


/*TOTAL*/
/*NOTICE: Inpatient patients must have check Outpatient clinic first*/
proc sql;
	SELECT COUNT(*)
	FROM HW.OpdteAMI AS op
	LEFT JOIN HW.Ipdte410 AS ip
	ON ip.ID = op.ID;
quit;
/*OUTPUT:170*/

proc sql;
	SELECT COUNT(*)
	FROM HW.OpdteOIHD AS op
	LEFT JOIN HW.Ipdte411_414 AS ip
	ON ip.ID = op.ID;
quit;
/*OUTPUT:3842*/


/*Q3.  Based on Q2, you should notice that MI could be divided by two categories. Therefore, please sum up them. How many patients have been diagnosed as MI?*/
/*Total: _____ patients have been diagnosed as MI*/

data HW.MI_Patient_ip;
	set HW.Ipdte410 HW.Ipdte411_414;
run;

proc sort data = HW.MI_Patient_ip nodupkey;
	by id;
run;
/*OUTPUT:529*/

data HW.MI_Patient_op;
	set HW.Opdteami HW.Opdteoihd;
run;
proc sort data = HW.MI_Patient_op nodupkey;
	by id;
run;
/*OUTPUT:3914*/

/*NOTICE: Inpatient patients must have check Outpatient clinic first*/
proc sql;
	SELECT COUNT(*)
	FROM HW.MI_Patient_op AS op
	LEFT JOIN HW.MI_Patient_ip AS ip
	ON ip.ID = op.ID;
quit;
/*OUTPUT:3914*/

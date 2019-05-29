*TerminalExtubation_descr

*destring variables
encode gender, gen(gender2)
encode insurance, gen(insurance2)
encode ethnicity, gen(ethnicity2)
encode last_careunit, gen(last_careunit2)
encode last_vent_mode, gen(last_vent_mode2)

*created age category variable.
gen age_cat=age
replace age_cat=1 if age_cat>=18 & age_cat <40
replace age_cat=2 if age_cat>=40 & age_cat <60
replace age_cat=3 if age_cat>=60 & age_cat <80
replace age_cat=4 if age_cat>=80 & age_cat <100
replace age_cat=5 if age_cat>=100 & age_cat <120



*Collapse ethnicity variable
gen ethnicity3=ethnicity2

*Collapsed Asian ethnicity
*1=Asian
replace ethnicity3=1 if ethnicity2>=2 & ethnicity2<=7
*2=Black
replace ethnicity3=2 if ethnicity2>=8 & ethnicity2<=10
*3=Hispanic
replace ethnicity3=3 if ethnicity2>=11 & ethnicity2<=13
*4=White
replace ethnicity3=4 if ethnicity2>=20 & ethnicity2<=22
*5=other
replace ethnicity3=5 if ethnicity2==16 | ethnicity2==1 | ethnicity2==14
*changed non-responders and NA to missing data
replace ethnicity3=. if ethnicity3>5

*collapsed insurance2 (put government into medicare), made NA=.
replace insurance2=3 if insurance2==1
replace insurance2=. if insurance2==4

*created no eye opeing variable as GCS==1
gen noeyeopen=1 if gcseyes_firstday==1
replace noeyeopen=0 if gcseyes_firstday==2 | gcseyes_firstday==3 | gcseyes_firstday==4 

*created mechvent time > 48hrs
gen vent48=mech_vent_duration_hrs
replace vent48=0 if mech_vent_duration_hrs<=48
replace vent48=1 if mech_vent_duration_hrs>48 & mech_vent_duration_hrs<99999

*dichotomized GCS 
gen lastgcs_dich=.
replace lastgcs_dich=1 if last_mingcs<9
replace lastgcs_dich=0 if last_mingcs>=9 & last_mingcs<=15

*dichotomized sofa score at the mean value for the population (7)
gen sofa_dich=sofa
replace sofa_dich=1 if sofa>7 & sofa< 40
replace sofa_dich=0 if sofa<=7

*gen severe pain score averaged from loop fx
gen sigpain=0
forval i=01/12 {
	replace sigpain=1 if ps_epoch_`i'>=3
	}

*creat last care unit dummy vars
tab last_careunit2, gen(last_careunitdum)

* indicate grouping variable for GEE (must be numeric).
encode last_careunit, gen(last_careunit2)
xtset last_careunit2

*ICD coding key for var icd1_col
//1= CAD/MI
//2= Vascular
//3= ETOH/liver/pancreas/ulcer/GIB
//4=AKI
//5=cancer
//6=abdominal ischemia
//7=operative/SICU
//8=resp failure
//9=sepsis
//10=neuro
//11=Diabetes related
//12=orthopedic
//13=ID
//14=drug abuse


*Univariate comparisons Table 1


sum last_mingcs if has_postext_tachypnea==1, detail
sum last_mingcs if has_postext_tachypnea==0, detail
ranksum last_mingcs, by (has_postext_tachypnea)

sum mech_vent_duration_hrs if has_postext_tachypnea==1, detail
sum mech_vent_duration_hrs if has_postext_tachypnea==0, detail
ranksum mech_vent_duration_hrs, by (has_postext_tachypnea)

sum sofa if has_postext_tachypnea==1, detail
sum sofa if has_postext_tachypnea==0, detail
ranksum sofa, by (has_postext_tachypnea)

sum time_from_ext_to_death_hrs if has_postext_tachypnea==1, detail 
sum time_from_ext_to_death_hrs if has_postext_tachypnea==0, detail 
ranksum time_from_ext_to_death_hrs, by (has_postext_tachypnea)
 
*created inverse of icd1 binary for neurological/non-neurological ICD code
gen icd1_bin_inv=1
replace icd1_bin_inv=0 if icd1_bin==1
tab icd1_bin_inv icd1_bin

*created ARDS variable
gen ARDS=0
replace ARDS=1 if PaO2FiO2<=200

*cox survival model
stset timefrom_ext_to_first_te_hrs

stcox ethnicity3dum2 ethnicity3dum3 ethnicity3dum4 ethnicity3dum5 \\\
 mingcs_firstday sofa_dich ARDS neurodx12 gender2 vent48 last_careunitdum2 \\\
 last_careunitdum3 last_careunitdum4 last_careunitdum5


 
*Bivariate models with ORs at output

 
*prelim GEE model
xtgee has_postext_tachypnea age_cat gender2 ethnicity3 vent_duration_days lastgcs_dich sofa

*Prelim best model with dummy unit 
logistic te_epoch_01 last_careunitdum1 last_careunitdum2 last_careunitdum3 last_care
> unitdum6 mingcs_firstday sofa

Logistic regression                             Number of obs     =        663
                                                LR chi2(6)        =      21.03
                                                Prob > chi2       =     0.0018
Log likelihood = -337.73532                     Pseudo R2         =     0.0302

-----------------------------------------------------------------------------------
      te_epoch_01 | Odds Ratio   Std. Err.      z    P>|z|     [95% Conf. Interval]
------------------+----------------------------------------------------------------
last_careunitdum1 |   1.579727   .6024037     1.20   0.230     .7481517    3.335601
last_careunitdum2 |   1.689743    .892422     0.99   0.321      .600159    4.757456
last_careunitdum3 |   2.100595   .5608596     2.78   0.005     1.244719    3.544977
last_careunitdum6 |   1.414594   .5313626     0.92   0.356     .6774789     2.95371
  mingcs_firstday |   1.041075   .0258572     1.62   0.105     .9916094    1.093008
             sofa |   1.054776   .0235368     2.39   0.017     1.009638    1.101931
            _cons |   .0654543   .0291687    -6.12   0.000     .0273283    .1567702
-----------------------------------------------------------------------------------

*created new binary variable for TE in epoch_01
gen te_epoch1_bin=0
replace te_epoch1_bin=1 if te_epoch_01>=1 & te_epoch_01<=11
replace te_epoch1_bin=. if te_epoch_01==.

 
* created risk time variable
gen risk_time=time_from_ext_to_death_hrs 
replace risk_time= timefrom_ext_to_first_te_hrs if has_postext_tachypnea==1
 
*Log transformed risk time
gen risk_timelog= ln(risk_time)
 
 *used a new model with risk_time as an offset function with time log transformed 
 logistic has_postext_tachypnea mingcs_firstday sofa icd1_bin gender2 insurance2 ethn
> icity2 gcseyes_firstday last_careunitdum2 last_careunitdum3 last_careunitdum5 icd2_c
> ol risk_time, off(risk_time)

*merged new variables
 merge 1:1 subject_id using "/Users/CoreyMacAir/Downloads/final_dataset-2.dta"
 
*FINAL MODELS USED FOR ANALYSIS
* Tachypnea within 1hr
logistic te_epoch1_bin2 AD ADBO ADBlack ADmale ADmingcs_firstday ethnicity3dum2 ///
 ethnicity3dum3 ethnicity3dum4 ethnicity3dum5 mingcs_firstday sofa_dich ARDS neurodx12 ///
 gender2 vent48 last_careunitdum2 last_careunitdum3 last_careunitdum4 ///
 last_careunitdum5, off(risk_timelog)
 
* Tachypnea within 12hrs
logistic has_postext_tachypnea AD ADBO ADBlack ADmale ethnicity3dum2 ethnicity3dum3 
> ethnicity3dum4 ethnicity3dum5 mingcs_firstday sofa_dich ARDS neurodx12 gender2 vent4
> 8 last_careunitdum2 last_careunitdum3 last_careunitdum4 last_careunitdum5, off(risk_
> timelog


*FINAL FINAL MUltivariate model
logistic te_epoch1_bin2 gender2 gcs9 ADinv ARDS neurodx12 last_careunitdum1 ///
 last_careunitdum2 last_careunitdum3 last_careunitdum5, off(risk_timelog)




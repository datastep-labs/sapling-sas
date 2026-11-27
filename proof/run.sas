/*******************************************************************************
| Program       : run.sas
| Purpose       : Run the SAS programs of one suite of the proof on your SAS 9.4:
|                 pharmaverse (its data are in proof/pharmaverse/data) or pilot1
|                 (put adsl.xpt, adadas.xpt, adlbc.xpt and adtte.xpt of
|                 github.com/RConsortium/submissions-pilot1, commit ba1d3e7, folder
|                 adam, into proof/pilot1/xpt first).
| Output        : work/<suite>/out: the numbers files (ard/*.csv), the tables
|                 (tlf/*.rtf, *.lst), the figures and the logs. Each number of
|                 proof/<suite>/results/*.csv (column sas) is in the numbers file.
*******************************************************************************/
%LET repo  = /path/to/sapling-sas;  /* the folder of this repository */
%LET suite = pharmaverse;           /* pharmaverse or pilot1 */

%LET spl_root = &repo.;
%INCLUDE "&repo./macros/sapling.sas";

%MACRO run_proof;
  %LOCAL members xpt programs i folder;
  %IF &suite. = pilot1 %THEN %DO;
    %LET members  = adsl adadas adlbc adtte;
    %LET xpt      = &repo./proof/pilot1/xpt;
    %LET programs = f14_1 t14_2_01 t14_3_01 t14_3_02;
  %END;
  %ELSE %DO;
    %LET members  = adsl adae;
    %LET xpt      = &repo./proof/pharmaverse/data;
    %LET programs = adverse_events demographic;
  %END;
  /* the folders of the run, each made when it is missing */
  OPTIONS DLCREATEDIR;
  %DO i = 1 %TO 7;
    %LET folder = %SCAN(work work/&suite. work/&suite./adam work/&suite./out work/&suite./out/ard
                        work/&suite./out/tlf work/&suite./out/figures, &i., %STR( ));
    LIBNAME _mk "&repo./&folder.";
    LIBNAME _mk CLEAR;
  %END;
  %LET spl_root = &repo./work/&suite.;
  %import_xpt(dir=&xpt., members=&members., out=&spl_root./adam)
  %DO i = 1 %TO %SYSFUNC(COUNTW(&programs., %STR( )));
    %INCLUDE "&repo./proof/&suite./programs/%SCAN(&programs., &i., %STR( )).sas";
    TITLE;
    FOOTNOTE;
  %END;
%MEND run_proof;
%run_proof

/*******************************************************************************
| Macro Name    : _spl_figure_par.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 27NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The parameters of a figure macro, before its checks. With
|                 plot= (draw the out= of a call again): data= is not given,
|                 plot= has the variables of out=, and each parameter of the
|                 computation that has a value gets a NOTE (it is not used).
|                 With par= (the outpar= of a call): each drawing parameter
|                 that the call leaves blank gets the VALUE of its row; a row
|                 that names no drawing parameter is an error. Then each
|                 parameter still blank gets its default from draw= or
|                 compute=. So a value in the call wins over a row of par=,
|                 and a row of par= over the default: the defaults of these
|                 parameters are here, not in the signature of the macro.
| Used By       : the figure macros (%kmplot, %forestplot, %meanplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| macro       The name of the calling macro                       Required
| draw        Its drawing parameters in the order of its          Required
|             signature, each as name or name=default
| compute     Its parameters of the computation that plot= does   Optional
|             not use, each as name or name=default
| shape       The variables of its out= that plot= must have      Required
| names       The name of a local macro variable of the caller:   Required
|             the names of the drawing parameters
| state       The name of a local macro variable of the caller:   Required
|             1 when the parameters are right, else 0
|-------------------------------------------------------------------------------
|
| Output        : LOG: one ERROR with its fix for a wrong plot= or par=, a NOTE
|                 for each parameter not used. The local macro variables of the
|                 caller: the parameters set from par= and from the defaults,
|                 state= and names=.
|
| Example:
|
 %_spl_figure_par(
     macro   = kmplot
   , draw    = columns by panel atrisk=yes xlabel ylabel="Survival (%)" file
   , compute = where time cnsr=CNSR
   , shape   = kind x y lower upper n censored
   , names   = drawn
   , state   = ok
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 13-NOV-2026 Sapling      1.6.0: initial version (plot=, par= and outpar= of
|                          the figure macros).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 27-NOV-2026 Sapling      1.10.0: the message prints a macro variable, not a
|                          macro expression: it reads the same in the log and in
|                          the code. No number changes.
|
*******************************************************************************/
%MACRO _spl_figure_par(
     macro   =   /* The name of the calling macro */
   , draw    =   /* Its drawing parameters: name or name=default */
   , compute =   /* Its parameters of the computation: name or name=default */
   , shape   =   /* The variables of its out= that plot= must have */
   , names   =   /* A local macro variable of the caller: the drawing parameters */
   , state   =   /* A local macro variable of the caller: 1 right, else 0 */
) / DES = 'Read par= and the defaults of a figure macro, and check plot=';
  %LOCAL _i _item _name _list _given _miss _dsid _rc _ok _shape;
  %LET &state. = 0;

  /* Step 1: the names of the drawing parameters, and those with a value in the call */
  %DO _i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(draw), %STR( ), q));
    %LET _name = %LOWCASE(%QSCAN(%QSCAN(%SUPERQ(draw), &_i., %STR( ), q), 1, %STR(=)));
    %LET _list = &_list. &_name.;
    %IF %LENGTH(%SUPERQ(&_name.)) %THEN %LET _given = &_given. &_name.;
  %END;
  %LET &names. = &_list.;

  /* Step 2: plot= without data=, with the variables of out=; the parameters it does not use */
  %IF %LENGTH(%SUPERQ(plot)) %THEN %DO;
    %IF %LENGTH(%SUPERQ(data)) %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] data= and plot= are both given;
      %PUT %STR(ERR)OR: [&macro.]   fix: give data= to compute, or plot= to draw an out= again.;
      %RETURN;
    %END;
    %IF not %SYSFUNC(EXIST(%SCAN(&plot., 1, %STR(%()))) %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] plot=&plot. does not exist;
      %PUT %STR(ERR)OR: [&macro.]   fix: give plot= an out= of &macro. (make it first).;
      %RETURN;
    %END;
    %LET _dsid = %SYSFUNC(OPEN(&plot.));
    %DO _i = 1 %TO %SYSFUNC(COUNTW(&shape., %STR( )));
      %IF %SYSFUNC(VARNUM(&_dsid., %SCAN(&shape., &_i., %STR( )))) = 0 %THEN
        %LET _miss = &_miss. %UPCASE(%SCAN(&shape., &_i., %STR( )));
    %END;
    %LET _rc = %SYSFUNC(CLOSE(&_dsid.));
    %IF %LENGTH(&_miss.) %THEN %DO;
      %LET _shape = %UPCASE(&shape.);  /* the variables of out= */
      %PUT %STR(ERR)OR: [&macro.] plot=&plot. has no variable &_miss.;
      %PUT %STR(ERR)OR: [&macro.]   fix: give plot= the shape of out=: &_shape..;
      %RETURN;
    %END;
    %DO _i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(compute)%STR( ), %STR( ), q));
      %LET _name = %LOWCASE(%QSCAN(%QSCAN(%SUPERQ(compute), &_i., %STR( ), q), 1, %STR(=)));
      %IF %LENGTH(%SUPERQ(&_name.)) %THEN
        %PUT NOTE: [&macro.] &_name.= is not used: plot= draws numbers computed before.;
    %END;
  %END;

  /* Step 3: par=: each drawing parameter blank in the call gets the value of its row */
  %IF %LENGTH(%SUPERQ(par)) %THEN %DO;
    %IF not %SYSFUNC(EXIST(%SCAN(&par., 1, %STR(%()))) %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] par=&par. does not exist;
      %PUT %STR(ERR)OR: [&macro.]   fix: give par= an outpar= of &macro. (make it first).;
      %RETURN;
    %END;
    %LET _dsid = %SYSFUNC(OPEN(&par.));
    %LET _ok   = %SYSFUNC(VARNUM(&_dsid., parameter));
    %IF &_ok. %THEN %LET _ok = %SYSFUNC(VARNUM(&_dsid., value));
    %LET _rc = %SYSFUNC(CLOSE(&_dsid.));
    %IF &_ok. = 0 %THEN %DO;
      %PUT %STR(ERR)OR: [&macro.] par=&par. has no variables PARAMETER and VALUE;
      %PUT %STR(ERR)OR: [&macro.]   fix: give par= an outpar= of &macro..;
      %RETURN;
    %END;
    %LET _ok = 1;
    DATA _NULL_;
      LENGTH _p $32;
      SET &par.;
      _p = LOWCASE(STRIP(parameter));
      IF NOT INDEXW("&_list.", STRIP(_p)) THEN DO;
        PUT "ERR" "OR: [&macro.] par=&par. has a row of no drawing parameter: "
            "give par= rows of outpar= of &macro. only " parameter=;
        CALL SYMPUTX('_ok', '0', 'F');
      END;
      ELSE IF NOT INDEXW("&_given.", STRIP(_p)) THEN CALL SYMPUTX(_p, value, 'F');
    RUN;
    %IF &_ok. = 0 %THEN %RETURN;
  %END;

  /* Step 4: each parameter still blank gets its default */
  %DO _i = 1 %TO %SYSFUNC(COUNTW(%SUPERQ(draw) %SUPERQ(compute), %STR( ), q));
    %LET _item = %QSCAN(%SUPERQ(draw) %SUPERQ(compute), &_i., %STR( ), q);
    %LET _name = %LOWCASE(%QSCAN(&_item., 1, %STR(=)));
    %IF %INDEX(&_item., %STR(=)) %THEN %DO;
      %IF %LENGTH(%SUPERQ(&_name.)) = 0 %THEN
        %LET &_name. = %QSUBSTR(&_item., %INDEX(&_item., %STR(=)) + 1);
    %END;
  %END;
  %LET &state. = 1;
%MEND _spl_figure_par;

/*******************************************************************************
| Macro Name    : _spl_figure_nodata.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.10.0
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : No record qualified for a figure: out= in the shape of the
|                 figure with no row, the NOTE No data qualified, and the figure
|                 that says so (a blank plot with the text, in the PNG and the
|                 RTF of file=, under the titles of the program).
| Used By       : the figure macros (%kmplot, %forestplot, %meanplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| keep        The variables of like= kept in out=                 Optional
| macro       The name of the calling macro                       Required
| like        The records, without a row                          Required
| chars       Character variables of out= ($200)                  Optional
| nums        Numeric variables of out=                           Optional
| file        The output without its extension                    Required
| width       The width of the figure                             Required
| height      The height of the figure                            Required
| out         The result to write (none: no data set)             Optional
|-------------------------------------------------------------------------------
|
| Output        : OUT: no row; FILE: <file>.png and <file>.rtf with the text.
|
| Example:
|
 %_spl_figure_nodata(
     keep   = &by.
   , macro  = kmplot
   , like   = _kmplot_records
   , chars  = kind
   , nums   = x y n censored
   , file   = &file.
   , width  = &width.
   , height = &height.
   , out    = &out.
 )
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version (the figure macros).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: the variables of the empty out= are set
|                          missing: no note that they are uninitialized
|                          (DEV-018). No number changes.
|
*******************************************************************************/
%MACRO _spl_figure_nodata(
     keep   =   /* The variables of like= kept in out= */
   , macro  =   /* The name of the calling macro */
   , like   =   /* The records, without a row */
   , chars  =   /* Character variables of out= */
   , nums   =   /* Numeric variables of out= */
   , file   =   /* The output without its extension */
   , width  =   /* The width of the figure */
   , height =   /* The height of the figure */
   , out    =   /* The result to write */
) / DES = 'The figure and the result when no record qualified';
  %LOCAL listing;

  /* Step 1: out= without a row, and the note */
  %IF %LENGTH(&out.) %THEN %DO;
    DATA &out.;
      %IF %LENGTH(&chars.) %THEN %DO;
        LENGTH &chars. $200;
      %END;
      %IF %LENGTH(&nums.) %THEN %DO;
        LENGTH &nums. 8;
      %END;
      %IF %LENGTH(&keep.) %THEN %DO;
        SET &like.(OBS=0 KEEP=&keep.);
      %END;
      %IF %LENGTH(&chars.&nums.) %THEN %DO;
        CALL MISSING(OF &chars. &nums.);
      %END;
      STOP;
    RUN;
    %PUT NOTE: [&macro.] No data qualified: no record meets where= and the conditions of the macro.;
    %PUT NOTE: [&macro.]   out=&out. has no row, and the figure &file. says No data qualified.;
  %END;
  %ELSE %DO;
    %PUT NOTE: [&macro.] No data qualified: no record meets where= and the conditions of the macro.;
    %PUT NOTE: [&macro.]   The figure &file. says No data qualified.;
  %END;

  /* Step 2: the figure with the text */
  DATA _figure_nodata_text;
    x    = 1;
    y    = 1;
    text = 'No data qualified';
  RUN;
  %_spl_figure_open(file=&file., width=&width., height=&height., state=listing)
  PROC SGPLOT DATA=_figure_nodata_text NOAUTOLEGEND;
    TEXT X=x Y=y TEXT=text / TEXTATTRS=(size = 14pt);
    XAXIS DISPLAY=none;
    YAXIS DISPLAY=none;
  RUN;
  %_spl_figure_close(listing=&listing.)

  /* Step 3: the work data sets are deleted */
  PROC DATASETS LIBRARY=work NOLIST NOWARN;
    DELETE _figure_nodata_:;
  QUIT;
%MEND _spl_figure_nodata;

/*******************************************************************************
| Macro Name    : _spl_rows.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The result shape: one row per statistic of the row just read.
|                 Each statistic is a numeric variable of the same name (n,
|                 mean, pval ...); the row gets STAT (its name), VALUE (its
|                 number), PATTERN and TEXT (the number as printed, %_spl_text:
|                 a p value, pval or padj, never as 0 or 1).
| Used By       : the statistics macros (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| missing     The text of a statistic without a value (default    Optional
|             blank; %km gives NE: not estimable)
| stats       The statistics in their order, each with its        Required
|             pattern (mean="XX.X") or without (the default
|             pattern of the statistic below)
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements: one row per statistic with STAT, VALUE
|                 and TEXT. The default patterns: XX for n, events, min, max;
|                 XX.X for mean, median, q1, q3, lsmean, diff, estimate, lcl,
|                 ucl; (XX.X%) for pct; X.XXX for pval; XX.XX for sd, se,
|                 lsmean_se, diff_se and any other statistic.
|
| Example:
|
 DATA result;
   SET means;
   %_spl_rows(stats=n="XX" mean="XX.X" sd)
 RUN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.2.0: the TEXT of pval and padj never 0 or 1
|                          (<0.001, >0.999). No number changes.
| 13-NOV-2026 Sapling      1.7.1: missing=: the text of a statistic without a
|                          value.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_rows(
     missing =   /* The text of a statistic without a value (default blank) */
   , stats   =   /* The statistics in their order, each with its pattern */
) / DES = 'The result shape: one row per statistic (DATA step statements)';
  %LOCAL _i _n _item _stat _pat _vars _names _pats;
  %LET _n = %SYSFUNC(COUNTW(%SUPERQ(stats), %STR( ), q));
  %DO _i = 1 %TO &_n.;
    %LET _item = %QSCAN(%SUPERQ(stats), &_i., %STR( ), q);
    %LET _stat = %LOWCASE(%QSCAN(&_item., 1, %STR(=)));
    %IF %INDEX(&_item., %STR(=)) %THEN %LET _pat = %QSUBSTR(&_item., %INDEX(&_item., %STR(=)) + 1);
    %ELSE %IF &_stat. = n or &_stat. = events or &_stat. = min or &_stat. = max %THEN
      %LET _pat = "XX";
    %ELSE %IF &_stat. = pct %THEN %LET _pat = %STR(%'(XX.X%%)%');
    %ELSE %IF &_stat. = pval %THEN %LET _pat = "X.XXX";
    %ELSE %IF %SYSFUNC(INDEXW(mean median q1 q3 lsmean diff estimate lcl ucl, &_stat.)) %THEN
      %LET _pat = "XX.X";
    %ELSE %LET _pat = "XX.XX";
    %LET _vars  = &_vars. &_stat.;
    %LET _names = &_names. "&_stat.";
    %LET _pats  = &_pats. &_pat.;
  %END;
  LENGTH stat $16 pattern text $40;
  ARRAY _rv {&_n.} &_vars.;
  ARRAY _rs {&_n.} $16 _TEMPORARY_ (%UNQUOTE(&_names.));
  ARRAY _rp {&_n.} $40 _TEMPORARY_ (%UNQUOTE(&_pats.));
  DO _ri = 1 TO &_n.;
    stat    = _rs{_ri};
    value   = _rv{_ri};
    pattern = _rp{_ri};
    %_spl_text(value=VALUE, pattern=PATTERN, text=TEXT, pvalue=STAT IN ('pval' 'padj'))
    %IF %LENGTH(&missing.) %THEN %DO;
      IF MISSING(value) THEN text = "&missing.";
    %END;
    OUTPUT;
  END;
  DROP _ri pattern;
%MEND _spl_rows;

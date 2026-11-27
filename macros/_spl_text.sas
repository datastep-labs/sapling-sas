/*******************************************************************************
| Macro Name    : _spl_text.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The text of a number by its pattern. A pattern shows one
|                 number as one group of X: XX, XX.X, (XX.X%), (N=XX). The
|                 number is rounded (ROUND) to the decimals of the X group,
|                 right aligned in its width and put in its place; the text is
|                 trimmed. A p value never prints as 0 or 1: rounded to 0 it is
|                 < and the smallest step (X.XXX: <0.001), rounded to 1 it is >
|                 and one step less (>0.999). The number is unchanged.
| Used By       : %_spl_rows, %adjust (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| value       The numeric variable                                Required
| pattern     The character variable with the pattern             Required
| text        The character variable to write (blank when the     Required
|             number is missing)
| pvalue      A condition that is true when the number is a p     0
|             value (STAT IN ('pval' 'padj'))
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements: TEXT is the number of VALUE as its
|                 PATTERN shows it (9.46 with (XX.X%) gives ( 9.5%); 86 with
|                 (N=XX) gives (N=86); 3 with XX gives 3; a p value 0.00004
|                 with X.XXX gives <0.001).
|
| Example:
|
 DATA result;
   SET rows;
   %_spl_text(
       value   = value
     , pattern = pattern
     , text    = text
     , pvalue  = stat IN ('pval' 'padj')
   )
 RUN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 11-NOV-2026 Sapling      1.0.0: initial version.
| 12-NOV-2026 Sapling      1.1.0: the house standard (docs/sas-style.md). No
|                          number changes.
| 12-NOV-2026 Sapling      1.2.0: pvalue=: a p value that rounds to 0 or 1
|                          prints as <0.001 or >0.999 (the text only; VALUE
|                          is unchanged).
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_text(
     value   =   /* The numeric variable */
   , pattern =   /* The character variable with the pattern */
   , text    =   /* The character variable to write */
   , pvalue  = 0 /* A condition: true for a p value */
) / DES = 'The text of a number by its pattern (DATA step statements)';
  LENGTH _tx _tnum _tpre _tpost $40;
  &text. = ' ';
  _tpos = PRXMATCH('/[Xx]+(\.[Xx]+)?/', &pattern.);
  IF _tpos > 0 AND NOT MISSING(&value.) THEN DO;
    /* the X group: its width and its decimals */
    _tx = PRXCHANGE('s/^[^Xx]*([Xx]+(\.[Xx]+)?).*$/$1/', 1, STRIP(&pattern.));
    _tw = LENGTH(_tx);
    _td = 0;
    IF INDEX(_tx, '.') > 0 THEN _td = _tw - INDEX(_tx, '.');
    /* the number, right aligned in the width of the X group */
    _tnum = STRIP(PUTN(ROUND(&value., 10 ** -_td), CATS('32.', _td)));
    /* a p value is never 0 or 1: the smallest step below it, or one step less than 1 */
    IF &pvalue. THEN DO;
      IF ROUND(&value., 10 ** -_td) = 0 THEN
   _tnum = '<' || STRIP(PUTN(10 ** -_td, CATS('32.', _td)));
      ELSE IF ROUND(&value., 10 ** -_td) = 1 THEN
        _tnum = '>' || STRIP(PUTN(1 - 10 ** -_td, CATS('32.', _td)));
    END;
    IF LENGTH(_tnum) < _tw THEN _tnum = REPEAT(' ', _tw - LENGTH(_tnum) - 1) || _tnum;
    /* the text of the pattern before and after the X group */
    _tpre  = ' ';
    _tpost = ' ';
    IF _tpos > 1 THEN _tpre = SUBSTR(&pattern., 1, _tpos - 1);
    IF LENGTH(&pattern.) >= _tpos + _tw THEN _tpost = SUBSTR(&pattern., _tpos + _tw);
    IF _tpos = 1 THEN &text. = STRIP(SUBSTR(_tnum, 1, MAX(_tw, LENGTH(_tnum))) || _tpost);
    ELSE              &text. = STRIP(SUBSTR(_tpre, 1, _tpos - 1)
                                     || SUBSTR(_tnum, 1, MAX(_tw, LENGTH(_tnum))) || _tpost);
  END;
  DROP _tx _tnum _tpre _tpost _tpos _tw _td;
%MEND _spl_text;

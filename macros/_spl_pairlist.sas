/*******************************************************************************
| Macro Name    : _spl_pairlist.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The pairs of groups of a parameter as rows: _K (the place of the
|                 pair), _A (the group) and _B (the group it is compared with).
|                 The pairs are separated by #, one pair per line, the first
|                 group against the second; a value with a blank or a hyphen is
|                 in quotes:
|                   pairs = "Xanomeline High Dose" "Placebo"
|                         # "Xanomeline Low Dose"  "Placebo"
|                 The form of version 1.0 is still read: "A"-"B" "C"-"D" (no #,
|                 every item a pair joined by a hyphen outside quotes).
| Used By       : %_spl_pairs, %_spl_stackpairs, %adjust (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| list        The parameter of the calling macro that holds the   Required
|             pairs (pairs, family)
|-------------------------------------------------------------------------------
|
| Output        : CODE: DATA step statements: one row (OUTPUT) per pair with _K, _A and
|                 _B ($200).
|
| Example:
|
 DATA _pairs_asked;
   %_spl_pairlist(list=pairs)
   KEEP _a _b;
 RUN;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version: the pairs separated by #;
|                          the form "A"-"B" of 1.0 still read.
| 12-NOV-2026 Sapling      1.1.0: the pairs are written into the code
|                          (%_spl_quote), not read by SYMGET when the step
|                          runs: the flat program has them. No number changes.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_pairlist(
     list =   /* The parameter that holds the pairs (pairs, family) */
) / DES = 'The pairs of groups of a parameter as rows _K _A _B (DATA step statements)';
  LENGTH _a _b $200 _list $4000 _item $410;
  /* the value of the parameter (as long as _LIST), on one line */
  _list = %_spl_quote(&list.);
  _list = TRANSLATE(_list, '   ', '090A0D'x);
  /* the form of 1.0: no # and every item a pair joined by a hyphen outside quotes */
  IF COUNTW(_list, '#', 'q') <= 1 THEN _old = 1;
  ELSE                                 _old = 0;
  DO _k = 1 TO COUNTW(_list, ' ', 'q');
    IF COUNTW(SCAN(_list, _k, ' ', 'q'), '-', 'q') NE 2 THEN _old = 0;
  END;
  IF _old THEN DO;
    DO _k = 1 TO COUNTW(_list, ' ', 'q');
      _item = SCAN(_list, _k, ' ', 'q');
      _a    = DEQUOTE(SCAN(_item, 1, '-', 'q'));
      _b    = DEQUOTE(SCAN(_item, 2, '-', 'q'));
      OUTPUT;
    END;
  END;
  /* else the pairs separated by #: in each the group, then the group it is compared with */
  ELSE DO;
    DO _k = 1 TO COUNTW(_list, '#', 'q');
      _item = SCAN(_list, _k, '#', 'q');
      _a    = DEQUOTE(SCAN(_item, 1, ' ', 'q'));
      _b    = DEQUOTE(SCAN(_item, 2, ' ', 'q'));
      OUTPUT;
    END;
  END;
  DROP _list _item _old;
%MEND _spl_pairlist;

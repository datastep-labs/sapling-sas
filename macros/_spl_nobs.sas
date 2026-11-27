/*******************************************************************************
| Macro Name    : _spl_nobs.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The number of rows of a data set (with the WHERE= of its data set
|                 options, when it has one); 0 when the data set does not exist.
| Used By       : the macros a person calls, before a procedure (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| _data       The data set                                        Required
|-------------------------------------------------------------------------------
|
| Output        : TEXT: the number, as text.
|
| Example:
|
 %IF %_spl_nobs(_describe_values) = 0 %THEN %DO;
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
|
*******************************************************************************/
%MACRO _spl_nobs(
     _data      /* The data set */
) / DES = 'The number of rows of a data set';
  %LOCAL dsid nobs rc;
  %LET nobs = 0;
  %LET dsid = %SYSFUNC(OPEN(&_data.));
  %IF &dsid. %THEN %DO;
    %LET nobs = %SYSFUNC(ATTRN(&dsid., NLOBSF));
    %LET rc   = %SYSFUNC(CLOSE(&dsid.));
  %END;
  &nobs.
%MEND _spl_nobs;

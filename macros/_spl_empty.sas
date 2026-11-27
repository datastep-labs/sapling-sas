/*******************************************************************************
| Macro Name    : _spl_empty.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : The result of a statistics macro when no record qualifies: the
|                 result shape without a row, and a NOTE that says so. A procedure
|                 never runs on no record, so the log has no error of one.
| Used By       : the statistics macros (inner part)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| keep        The group variables of the result (BY, WITHIN)      Optional
| macro       The name of the calling macro                       Required
| like        The records (without a row): the types and lengths  Required
|             of the group variables
| add         Character group variables the records do not have   Optional
|             (VERSUS)
| out         The result to write                                 Required
|-------------------------------------------------------------------------------
|
| Output        : OUT: KEEP, ADD, GROUPS, BLOCK, STAT, VALUE and TEXT and no
|                 row; the line NOTE: [macro] No data qualified ... in the log.
|
| Example:
|
 %_spl_empty(macro=cox, out=&out., like=_cox_records, keep=&by. &within., add=versus)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.1.0: initial version.
| 16-NOV-2026 Sapling      1.9.0: the license line; the example in the house
|                          case (names in lower case). No number changes.
| 16-NOV-2026 Sapling      1.9.1: the variables of add= (VERSUS) are set
|                          missing: no note that they are uninitialized
|                          (DEV-038). No number changes.
|
*******************************************************************************/
%MACRO _spl_empty(
     keep  =     /* The group variables of the result */
   , macro =     /* The name of the calling macro */
   , like  =     /* The records, without a row */
   , add   =     /* Character group variables the records do not have */
   , out   =     /* The result to write */
) / DES = 'The result shape without a row: no data qualified';
  DATA &out.;
    LENGTH &add. groups block $200 stat $16 text $40;
    %IF %LENGTH(&keep.) %THEN %DO;
      SET &like.(OBS=0 KEEP=&keep.);
    %END;
    CALL MISSING(OF &add. groups block stat text);
    value = .;
    STOP;
    KEEP &keep. &add. groups block stat value text;
  RUN;
  %PUT NOTE: [&macro.] No data qualified: no record meets where= and the conditions of the macro.;
  %PUT NOTE: [&macro.]   out=&out. has no row.;
%MEND _spl_empty;

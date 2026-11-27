/*******************************************************************************
| Macro Name    : _spl_figure_open.sas
| SAS Version   : SAS 9.4
| Macro Version : 1.9.1
| Created By    : Sapling
| Date          : 16NOV2026
| License       : Commercial, DataStep Labs (see LICENSE)
|
| Macro Purpose : Open the destinations of one figure: the PNG image (the LISTING
|                 destination with GPATH=, 300 dpi, image name and size from
|                 ODS GRAPHICS) and the RTF file with the figure on a page (the
|                 titles and footnotes of the program as text of the page:
|                 NOGTITLE NOGFOOTNOTE). The PNG carries the titles and the
|                 footnotes in the image (LISTING draws them in the graph, as
|                 SAS does by default), so a PNG alone says what it is. Both use
|                 the style HTMLBLUE: tick values 9pt, axis labels and legend
|                 10pt, titles 11pt. It notes in the macro variable named by
|                 state= whether LISTING was open, for %_spl_figure_close.
| Used By       : the figure macros (%kmplot, %forestplot, %meanplot ...)
|
| Input Parameters :
|
| Name        Description                                         Default
|-------------------------------------------------------------------------------
| file        The output without its extension: <file>.png and    Required
|             <file>.rtf
| width       The width of the figure                             Required
| height      The height of the figure                            Required
| state       The name of a local macro variable of the caller:   Required
|             yes when LISTING was open, else no
|-------------------------------------------------------------------------------
|
| Output        : CODE: the ODS statements that open the destinations.
|
| Example:
|
 %_spl_figure_open(file=&file., width=&width., height=&height., state=LISTING)
|
|-------------------------------------------------------------------------------
| Change Log :
| Date        Programmer   Description
|-------------------------------------------------------------------------------
| 12-NOV-2026 Sapling      1.3.0: initial version (the figure macros).
| 16-NOV-2026 Sapling      1.9.0: a missing output folder is made, with a NOTE
|                          that names the figure macro (%_spl_folder). The
|                          license line.
|
*******************************************************************************/
%MACRO _spl_figure_open(
     file   =   /* The output without its extension */
   , width  =   /* The width of the figure */
   , height =   /* The height of the figure */
   , state  =   /* A local macro variable of the caller: LISTING was open */
) / DES = 'Open the PNG and RTF destinations of a figure';
  %LOCAL name dir caller;
  %LET name = %SCAN(&file., -1, /);  /* the name of the image */
  %LET dir  = .;                     /* the folder of the image */
  %IF %LENGTH(&name.) < %LENGTH(&file.) %THEN
    %LET dir = %SUBSTR(&file., 1, %LENGTH(&file.) - %LENGTH(&name.) - 1);
  %LET &state. = no;
  %LET caller = %SYSMEXECDEPTH;                                /* the depth of this macro */
  %LET caller = %LOWCASE(%SYSMEXECNAME(%EVAL(&caller. - 1)));  /* the figure macro */
  %_spl_folder(&caller., %SUPERQ(file).png)
  DATA _NULL_;
    SET sashelp.vdest;
    IF UPCASE(destination) = 'LISTING' THEN CALL SYMPUTX("&state.", 'yes');
  RUN;
  ODS LISTING GPATH="&dir." IMAGE_DPI=300 STYLE=htmlblue;
  ODS GRAPHICS ON / RESET=all IMAGENAME="&name." IMAGEFMT=png WIDTH=&width. HEIGHT=&height.
                    NOBORDER;
  ODS RTF FILE="&file..rtf" STYLE=htmlblue IMAGE_DPI=300 NOGTITLE NOGFOOTNOTE;
%MEND _spl_figure_open;

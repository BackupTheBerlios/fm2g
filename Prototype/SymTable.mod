(* ---------------------------------------------------------------------- *)
(*  IMPLEMENTATION MODULE SymbolTable.                                    *)
(*                                                                        *)
(*  USEAGE : This module builds a symbol table containing DECLARATIONS    *)
(*           together with details of their TYPE and SCOPE.               *)
(*                                                                        *)
(*  COPYRIGHT    : (C) The Free Modula-2 Group 2005                       *)
(*  AUTHOR       : ScotaSys		DATE WRITTEN 05/05/2005                 *)
(* ---------------------------------------------------------------------- *)

MODULE SymbolTable;

TYPE
    Type        = POINTER TO TypeDetails;
    Declaration = POINTER TO DeclarationList;
    Scope       = POINTER TO ScopeList;

    TypeDetails = RECORD
		             Form   : INTEGER;        (* Record, array, etc  *)
		             Length : INTEGER;        (* Array size          *)
		             Fields : Declaration;	  (* Record fields       *)
	    	             Base   : Type;           (* INTEGER, REAL       *)
                  END;

    DeclarationList = RECORD
                         Name  : ARRAY [0..32]OF CHAR;(* Declaration name *)
                         Class : INTEGER;    (* Variable, const, etc     *)
                         type  : Type;       (* Data type                *)
                         Value : LONGINT;    (* Data value               *)
                         Next  : Declaration;(* Next declaration in list *)
                      END;

    ScopeList = RECORD
		            First : Scope;          (* Pointer to higher scope *)
		            Item  : Declaration;    (* Pointer to declarations *)
                      Next  : Scope;          (* Pointer to lower scope  *)
                END;

(* ProcedureName --------------------------------------------------------
    DESCRIPTION    : Describe what this procedure does on these few lines
                     here. Please keep it short and simple, unless you
                     really need to put a lot of information here.

    PRE-CONDITION  : Describe the procedure's inputs, if any, here.
    POST-CONDITION : Describe the procedure's outputs here.
   ------------------------------------------------------------------- *)

END SymbolTable.

(* ---------------------------------------------------------------------
       This software and its source code is released under the
                   GNU General Public Licence
        Copyright (C) 1989, 1991 Free Software Foundation, Inc.
         59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
   -------------------------------------------------------------------- *)

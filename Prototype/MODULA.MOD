MODULE Modula;
(* This is an example of a rudimentary main module for use with COCO/R.
   It assumes ISO I/O libraries are available.
   The auxiliary modules <Grammar>S (scanner) and <Grammar>P (parser)
   are assumed to have been constructed with COCO/R compiler generator. *)

  FROM ModulaS IMPORT lst, src, errors, Error, CharAt;
  FROM ModulaP IMPORT Parse, Successful;
  IMPORT
    ProgramArgs, Strings,
    SYSTEM, Storage, TextIO, WholeIO, StdChans, SeqFile, ChanConsts, IOChan;
    (* and any others needed *)

  TYPE
    INT32 = INTEGER (* 32 bit integers needed *);

  MODULE ListHandler;
  (* ------------------- Source Listing and Error handler -------------- *)
    IMPORT WholeIO, TextIO, Storage, SYSTEM;
    IMPORT lst, CharAt, errors, INT32;
    EXPORT StoreError, PrintListing;

    CONST
      CR = 15C;
      LF = 12C;
      EOF = 0C;

    TYPE
      Err = POINTER TO ErrDesc;
      ErrDesc = RECORD
        nr, line, col: INTEGER;
        next: Err
      END;

    CONST
      tab = 11C;

    VAR
      firstErr, lastErr: Err;
      Extra: INTEGER;

    PROCEDURE StoreError (nr, line, col: INTEGER; pos: INT32);
    (* Store an error message for later printing *)
      VAR
        nextErr: Err;
      BEGIN
        Storage.ALLOCATE(nextErr, SYSTEM.TSIZE(ErrDesc));
        nextErr^.nr := nr; nextErr^.line := line; nextErr^.col := col;
        nextErr^.next := NIL;
        IF firstErr = NIL
          THEN firstErr := nextErr
          ELSE lastErr^.next := nextErr
        END;
        lastErr := nextErr;
        INC(errors)
      END StoreError;

    PROCEDURE GetLine (VAR pos: INT32;
                       VAR line: ARRAY OF CHAR;
                       VAR eof: BOOLEAN);
    (* Read a source line. Return empty line if eof *)
      VAR
        ch: CHAR;
        i: CARDINAL;
      BEGIN
        i := 0; eof := FALSE; ch := CharAt(pos); INC(pos);
        WHILE (ch # CR) & (ch # LF) & (ch # EOF) DO
          line[i] := ch; INC(i); ch := CharAt(pos); INC(pos);
        END;
        eof := (i = 0) & (ch = EOF); line[i] := 0C;
        IF ch = CR THEN (* check for MsDos *)
          ch := CharAt(pos);
          IF ch = LF THEN INC(pos); Extra := 0 END
        END
      END GetLine;

    PROCEDURE PrintErr (line: ARRAY OF CHAR; nr, col: INTEGER);
    (* Print an error message *)

      PROCEDURE Msg (s: ARRAY OF CHAR);
        BEGIN
          TextIO.WriteString(lst, s)
        END Msg;

      PROCEDURE Pointer;
        VAR
          i: INTEGER;
        BEGIN
          TextIO.WriteString(lst, "*****  ");
          i := 0;
          WHILE i < col + Extra - 2 DO
            IF line[i] = tab
              THEN TextIO.WriteChar(lst, tab)
              ELSE TextIO.WriteChar(lst, ' ')
            END;
            INC(i)
          END;
          TextIO.WriteString(lst, "^ ")
        END Pointer;

      BEGIN
        Pointer;
        CASE nr OF
           0: Msg("EOF expected")
        |  1: Msg("identifier expected")
        |  2: Msg("integer expected")
        |  3: Msg("real expected")
        |  4: Msg("string expected")
        |  5: Msg("'DEFINITION' expected")
        |  6: Msg("'MODULE' expected")
        |  7: Msg("'IMPLEMENTATION' expected")
        |  8: Msg("'BEGIN' expected")
        |  9: Msg("'END' expected")
        | 10: Msg("'.' expected")
        | 11: Msg("'FROM' expected")
        | 12: Msg("';' expected")
        | 13: Msg("',' expected")
        | 14: Msg("'CONST' expected")
        | 15: Msg("'=' expected")
        | 16: Msg("'TYPE' expected")
        | 17: Msg("':' expected")
        | 18: Msg("'VAR' expected")
        | 19: Msg("'PROCEDURE' expected")
        | 20: Msg("'(' expected")
        | 21: Msg("')' expected")
        | 22: Msg("'ARRAY' expected")
        | 23: Msg("'OF' expected")
        | 24: Msg("'RECORD' expected")
        | 25: Msg("'SET' expected")
        | 26: Msg("'{' expected")
        | 27: Msg("'}' expected")
        | 28: Msg("'POINTER' expected")
        | 29: Msg("'TO' expected")
        | 30: Msg("'[' expected")
        | 31: Msg("'..' expected")
        | 32: Msg("']' expected")
        | 33: Msg("'^' expected")
        | 34: Msg("':=' expected")
        | 35: Msg("'CASE' expected")
        | 36: Msg("'|' expected")
        | 37: Msg("'ELSE' expected")
        | 38: Msg("'FOR' expected")
        | 39: Msg("'BY' expected")
        | 40: Msg("'DO' expected")
        | 41: Msg("'IF' expected")
        | 42: Msg("'THEN' expected")
        | 43: Msg("'ELSIF' expected")
        | 44: Msg("'LOOP' expected")
        | 45: Msg("'REPEAT' expected")
        | 46: Msg("'UNTIL' expected")
        | 47: Msg("'WHILE' expected")
        | 48: Msg("'WITH' expected")
        | 49: Msg("'+' expected")
        | 50: Msg("'-' expected")
        | 51: Msg("'#' expected")
        | 52: Msg("'<' expected")
        | 53: Msg("'<=' expected")
        | 54: Msg("'<>' expected")
        | 55: Msg("'>' expected")
        | 56: Msg("'>=' expected")
        | 57: Msg("'IN' expected")
        | 58: Msg("'OR' expected")
        | 59: Msg("'NOT' expected")
        | 60: Msg("'*' expected")
        | 61: Msg("'/' expected")
        | 62: Msg("'DIV' expected")
        | 63: Msg("'MOD' expected")
        | 64: Msg("'AND' expected")
        | 65: Msg("not expected")
        | 66: Msg("invalid Number")
        | 67: Msg("invalid FactorOperator")
        | 68: Msg("invalid Factor")
        | 69: Msg("invalid TermOperator")
        | 70: Msg("invalid Relation")
        | 71: Msg("invalid SimpleType")
        | 72: Msg("invalid Type")
        | 73: Msg("invalid Statements")
        
        (* add customized cases here *)
        ELSE Msg("Error: "); WholeIO.WriteInt(lst, nr, 0);
        END;
        TextIO.WriteLn(lst)
      END PrintErr;

    PROCEDURE PrintListing;
    (* Print a source listing with error messages *)
      VAR
        nextErr: Err;
        eof: BOOLEAN;
        lnr, errC: INTEGER;
        srcPos: INT32;
        line: ARRAY [0 .. 255] OF CHAR;
      BEGIN
        TextIO.WriteString(lst, "Listing:");
        TextIO.WriteLn(lst); TextIO.WriteLn(lst);
        srcPos := 0; nextErr := firstErr;
        GetLine(srcPos, line, eof); lnr := 1; errC := 0;
        WHILE ~ eof DO
          WholeIO.WriteInt(lst, lnr, 5); TextIO.WriteString(lst, "  ");
          TextIO.WriteString(lst, line); TextIO.WriteLn(lst);
          WHILE (nextErr # NIL) & (nextErr^.line = lnr) DO
            PrintErr(line, nextErr^.nr, nextErr^.col); INC(errC);
            nextErr := nextErr^.next
          END;
          GetLine(srcPos, line, eof); INC(lnr);
        END;
        IF nextErr # NIL THEN
          WholeIO.WriteInt(lst, lnr, 5); TextIO.WriteLn(lst);
          WHILE nextErr # NIL DO
            PrintErr(line, nextErr^.nr, nextErr^.col); INC(errC);
            nextErr := nextErr^.next
          END
        END;
        TextIO.WriteLn(lst);
        WholeIO.WriteInt(lst, errC, 5); TextIO.WriteString(lst, " error");
        IF errC # 1 THEN TextIO.WriteChar(lst, "s") END;
        TextIO.WriteLn(lst); TextIO.WriteLn(lst); TextIO.WriteLn(lst);
      END PrintListing;

    BEGIN
      firstErr := NIL; Extra := 1;
    END ListHandler;

  (* --------------------------- main module ------------------------------- *)

  PROCEDURE ChangeExtension (oldName, Ext: ARRAY OF CHAR;
                             VAR newName: ARRAY OF CHAR);
  (* Constructs newName as complete file name by appending ext to oldName
     Examples: (assume ext = "EXT")
           old.any ==> old.EXT
           old     ==> old.EXT
     This is not a file renaming facility, merely a string manipulation
     routine. *)
    VAR
      i, l: CARDINAL;
    BEGIN
      Strings.Assign(oldName, newName);
      i := LENGTH(oldName); l := i;
      WHILE (i > 0) & (oldName[i -1] # '.')
            & (oldName[i -1] # '\') & (oldName[i -1] # '/') DO
        DEC(i)
      END;
      IF (i > 0) & (oldName[i-1] = '.') THEN
        Strings.Delete(newName, i - 1, l + 1 - i)
      END;
      IF Ext[0] = '.' THEN Strings.Delete(Ext, 0, 1) END;
      Strings.Append(".", newName);
      Strings.Append(Ext, newName)
    END ChangeExtension;

  VAR
    sourceName, listName: ARRAY [0 .. 255] OF CHAR;
    StdOut: IOChan.ChanId;
    res: ChanConsts.OpenResults;

  BEGIN
    StdOut := StdChans.StdOutChan();
    (* check on correct parameter usage *)
    (* you may need ProgramArgs.NextArg(); to skip program name *)
    IF ProgramArgs.IsArgPresent()
      THEN
        TextIO.ReadToken(ProgramArgs.ArgChan(), sourceName);
      ELSE
        TextIO.WriteString(StdOut, "No input file specified");
        HALT
    END;

    (* open the source file - Scanner.src *)
    SeqFile.OpenRead(src, sourceName, SeqFile.raw + SeqFile.old + SeqFile.read, res);
    IF res # SeqFile.opened THEN
      TextIO.WriteString(StdOut, "Could not open input file");
      TextIO.WriteLn(StdOut);
      HALT
    END;

    (* open the output file for the source listing - Scanner.lst *)
    ChangeExtension(sourceName, ".LST", listName);
    SeqFile.OpenWrite(lst, listName, SeqFile.write + SeqFile.old, res);
    IF res # SeqFile.opened THEN
      TextIO.WriteString(StdOut, "Could not open listing file");
      TextIO.WriteLn(StdOut);
      (* default Scanner.lst to screen *) lst := StdOut;
    END;

    (* install error reporting procedure - Scanner.Error *)
    Error := StoreError;

    (* instigate the compilation - Parser.Parse *)
    TextIO.WriteString(StdOut, "Parsing"); TextIO.WriteLn(StdOut);
    Parse;

    (* generate the source listing on lst file *)
    PrintListing;
    IF lst # StdOut THEN SeqFile.Close(lst) END;
    
    (* examine the outcome *)
    IF NOT Successful()
      THEN
        TextIO.WriteString(StdOut, "Incorrect source");
      ELSE
        TextIO.WriteString(StdOut, "Parsed correctly");
        (* ++++++++ Add further activities if required ++++++++++ *)
    END;
  END Modula.

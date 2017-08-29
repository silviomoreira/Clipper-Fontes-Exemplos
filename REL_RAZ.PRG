/****************************************************************************
* Fonte na linguagem Clipper 5.0
* PROGRAMA: Relatorios
* AUTOR: Silvio Sergio
* DATA DE INICIO: 20/08/97
* DATA DE TERMINO: 02/09/97
* OBJETIVO: Demonstra Livro Razao
****************************************************************************/

#include "INKEY.CH"
#include "GRUMP.CH"

Local VEMP, VNOMREL, VANOMES, VCODLOCA, VDATEMI, VCCONTA, VCSCONTA, VLENCODLAN,;
      VPICCODLAN, VTOTDEB, VTOTCRE, VGERDEB, VGERCRE, VSALANT, VSALATU, VLOC,  ;
      F_CANCELIMP, I, N, F_SINALNEG, F_IMPLAN, F_IMPCONTA, VGRP, VSTR0
Priv  VANOMESI, VANOMESF, VDATINI, VDATFIM, VCODLOCS
Publ  V_PAG

// Abre arqs. no modo compartilhado
If ! FopenArq_I(  { {"DB",.F.}, {"CR",.F.}, {"LD",.F.}, {"LC",.F.}, ;
                    {"ET",.F.}, {"LO",.F.}, {"CN",.F.}, {"SC",.F.}, {"SD",.F.} }  )
   Alert("Arquivos bloqueados !")
   Close All
   Return
Endif
DbSelectArea( "SC" )
CN->(  DbSetOrder( 2 )  )
SC->(  DbSetOrder( 2 )  )
Set Relation to (CODIGP_SC+CODIGR_SC+CODISB_SC+CODICN_SC) into CN
SC->( DbGotop() )
DB->(  DbSetOrder( 3 )  )
CR->(  DbSetOrder( 3 )  )

V_PAG:=0
VEMP := EMP + " " + FRetCampo("ET",EMP,"RAZSOC_ET")
VNOMREL := "Razao Analitico"
VANOMESI := VANOMESF := Space(6)
VDATINI := Ctod(  "01/01/" + Alltrim( Str(Year(Date())) )  )
VDATFIM := Ctod(  "31/12/" + Alltrim( Str(Year(Date())) )  )
VDATEMI := Ctod( Space(8) )
VCODLOCS := '  ' + Repl( '.  ', 11 )
VLENCODLAN := Len( LD->CODLAN_LD )
VPICCODLAN := "@R " + Replicate( '9', LEN(LD->CODLAN_LD) )
F_CANCELIMP := .F.
VSTR0 := Str( 0, 12, 2 )

If ! FControImp( VNOMREL, {|| Filtro(@VANOMES,@VCODLOCA,@VDATEMI)} )
   Close All
   Return
Endif

@ Prow(), Pcol() Say Chr(15)

Do While .T.

   V_PAG := 0

   Do While SC->( ! Eof() )

      VGERDEB := VGERCRE := 0
      VCCONTA  := CN->(CODIGP_CN+CODIGR_CN+CODISB_CN+CODICN_CN)
      VCSCONTA := SC->(CODIGP_SC+CODIGR_SC+CODISB_SC+CODICN_SC+CODISC_SC)
      // Saldo do mes anterior
      VSALANT := FSalIni( VCODLOCA, VCSCONTA, VANOMES )
      F_IMPCONTA := .T.

      Do While VANOMES >= VANOMESI .and. VANOMES <= VANOMESF

         // =================================== //
         //            < Debitos >              //
         // =================================== //
         // Flag imprimiu lanc.
         F_IMPLAN := .F.
         VTOTDEB := VTOTCRE := 0
         PSetRela( "DB" )
         DB->(  DbSeek( VCODLOCA + " " + VCSCONTA + VANOMES, .T. )  )

         Do While DB->CODLOC_DB == VCODLOCA                 .and. ;
                  DB->(  FAnoMesC( DATLAN_DB )  ) = VANOMES .and. ;
                  DB->CCONTA_DB == VCSCONTA                 .and. ;
                  DB->( !Eof() )

            // Permite cancelar
            If F_TeclaImp( Chr(15) ) = K_ESC
               F_CANCELIMP := .T.
               Exit
            Endif

            If ! LD->(  DbSeek( DB->NUMMOV_DB )  )
                 // REGISTRA EM REGISTRO .TXT
                 PRegistra( "LD", "Seek", "Num. movimento: " + DB->NUMMOV_DB )
            Endif

            Do While LD->NUMMOV_LD == DB->NUMMOV_DB .and. LD->( !Eof() )

               If ProwCount() > 58 .or. V_PAG = 0
                  Pcab_Blc(VEMP,VNOMREL,VANOMES,VCODLOCA,VDATEMI)
               Endif
               If F_IMPCONTA
                  Imp(Prow()+1,000,"Conta:    "+Transform(VCCONTA,"@R 9.99.99.99")+"      "+ImpCarCont( Chr(14) )+CN->DESCRI_CN+ImpCarCont( Chr(15) ))
                  Imp(Prow()+1,000,"SubConta: "+Transform(VCSCONTA,"@R 9.99.99.99.999")+"  "+SC->DESCRI_SC)
                  Imp(Prow()+0,090,"Saldo anterior................"+Transform(VSALANT,"@E 99,999,999.99"))
                  F_IMPCONTA := .F.
               Endif
               Imp(Prow()+1,000,DB->DATLAN_DB)
               Imp(Prow()+0,013,Transform(Str(Val(LD->CODLAN_LD),VLENCODLAN),VPICCODLAN))
               Imp(Prow()+0,028,LD->LANCAM_LD)
               Imp(Prow()+0,073,"0")
               Imp(Prow()+0,078,CR->CCONTA_CR)
               Imp(Prow()+0,090,Transform(LD->VALLAN_LD,"@E 99,999,999.99"))

               VTOTDEB += LD->VALLAN_LD
               VGERDEB += LD->VALLAN_LD
               F_IMPLAN := .T.
               LD->( DbSkip() )
            Enddo

             DB->( DbSkip() )

         Enddo

         If F_CANCELIMP ;  Exit ;  Endif

         // =================================== //
         //            < Creditos >             //
         // =================================== //

         PSetRela( "CR" )
         CR->(  DbSeek( VCODLOCA + " " + VCSCONTA + VANOMES, .T. )  )

         Do While CR->CODLOC_CR == VCODLOCA                 .and. ;
                  CR->(  FAnoMesC( DATLAN_CR )  ) = VANOMES .and. ;
                  CR->CCONTA_CR == VCSCONTA                 .and. ;
                  CR->( !Eof() )

            // Permite cancelar
            If F_TeclaImp( Chr(15) ) = K_ESC
               F_CANCELIMP := .T.
               Exit
            Endif
            If ! LC->(  DbSeek( CR->NUMMOV_CR )  )
                 // REGISTRA EM REGISTRO .TXT
                 PRegistra( "LC", "Seek", "Num. movimento: " + CR->NUMMOV_CR )
            Endif

            Do While LC->NUMMOV_LC == CR->NUMMOV_CR .and. LC->( !Eof() )
               If ProwCount() > 58 .or. V_PAG = 0
                  Pcab_Blc(VEMP,VNOMREL,VANOMES,VCODLOCA,VDATEMI)
               Endif
               If F_IMPCONTA
                  Imp(Prow()+1,000,"Conta:    "+Transform(VCCONTA,"@R 9.99.99.99")+"      "+ImpCarCont( Chr(14) )+CN->DESCRI_CN+ImpCarCont( Chr(15) ))
                  Imp(Prow()+1,000,"SubConta: "+Transform(VCSCONTA,"@R 9.99.99.99.999")+"  "+SC->DESCRI_SC)
                  Imp(Prow()+0,090,"Saldo anterior................"+Transform(VSALANT,"@E 99,999,999.99"))
                  F_IMPCONTA := .F.
               Endif
               Imp(Prow()+1,000,CR->DATLAN_CR)
               Imp(Prow()+0,013,Transform(Str(Val(LC->CODLAN_LC),VLENCODLAN),VPICCODLAN))
               Imp(Prow()+0,028,LC->LANCAM_LC)
               Imp(Prow()+0,073,"0")
               Imp(Prow()+0,078,DB->CCONTA_DB)
               Imp(Prow()+0,105,Transform(LC->VALLAN_LC,"@E 99,999,999.99"))

               VTOTCRE += LC->VALLAN_LC
               VGERCRE += LC->VALLAN_LC
               F_IMPLAN := .T.
               LC->( DbSkip() )
            Enddo

            CR->( DbSkip() )

         Enddo
         // Calcula e imprime Saldo do mes
         VSALATU := FSaldoMes( VCSCONTA, VSALANT, VTOTDEB, VTOTCRE )
         If F_IMPLAN
            Imp(Prow()+0,120,Transform(VSALATU,"@E 99,999,999.99"))
         Endif

         If F_CANCELIMP ;  Exit ;  Endif

         // Armazena VANOMES
         VANOMES := FAdAnoMes( VANOMES, "+" )
         VSALANT := VSALATU

      Enddo
      // =================================== //
      //         Imprime saldo atual         //
      // =================================== //
      If Str( VGERDEB, 12, 2 ) # VSTR0 .or. Str( VGERCRE, 12, 2 ) # VSTR0
         Imp(Prow()+1,000,Replicate("-",133))
         Imp(Prow()+1,028,"Saldo Atual")
         Imp(Prow()+0,089,Transform(VGERDEB,"@E 999,999,999.99"))
         Imp(Prow()+0,104,Transform(VGERCRE,"@E 999,999,999.99"))
         Imp(Prow()+0,120,Transform(VSALATU,"@E 99,999,999.99"))
         Imp(Prow()+1,000,Replicate("-",133))
      Endif
      If F_CANCELIMP ;  Exit ;  Endif
      VANOMES := VANOMESI

      SC->( DbSkip() )

   Enddo

   VTOTDEB := VTOTCRE := 0

   If F_CANCELIMP ;  Exit ;  Endif

   // =================================== //
   //          Fim de Impressao           //
   // =================================== //

   DB->(  DbSetOrder( 3 )  )
   CR->(  DbSetOrder( 3 )  )
   // Mudanca de localizacao:
   If VANOMES > VANOMESF .and. _FLAGLO_PA = "M"
      If ProwCount() > 57 .or. V_PAG = 0
         Pcab_Blc(VEMP,VNOMREL,VANOMES,VCODLOCA,VDATEMI)
      Endif
      // Se mudou loc.
      If DB->CODLOC_DB # VCODLOCA .and. CR->CODLOC_CR # VCODLOCA .and. ;
         (  DB->( !Eof() ) .or. CR->( !Eof() )  )
         VLOC := If( DB->CODLOC_DB # VCODLOCA .and. DB->( !Eof() ), ;
                     DB->CODLOC_DB,                                 ;
                 If( CR->CODLOC_CR # VCODLOCA .and. CR->( !Eof() ), ;
                     CR->CODLOC_CR, ""                            ) )
      Else
         Do While DB->CODLOC_DB = VCODLOCA .and. DB->( !Eof() )
            DB->( DbSkip() )
         Enddo
         If DB->( !Eof() )
            VLOC := DB->CODLOC_DB
         Else
            Do While CR->CODLOC_CR = VCODLOCA .and. CR->( !Eof() )
               CR->( DbSkip() )
            Enddo
            VLOC := CR->CODLOC_CR
         Endif
      Endif
      If Empty( VLOC ) ;  Exit ;  Endif
      // Retorna proxima loc. em que foram encontrados dados
      VCODLOCA := FRetLocUti( VLOC, " "+Repl("0",10)+Dtos(VDATINI) )
      // Cabecario
      Pcab_Blc(VEMP,VNOMREL,VANOMES,VCODLOCA,VDATEMI)
   Endif

   SC->( DbGotop() )

   // Se nao mudou a localizacao sai
   If VCODLOCA == "00"
      Exit
   Endif

Enddo

// Imprime
PImpArq()
Close All
Return

*==================================================================
Static Procedure Pcab_Blc(VEMP,VNOMREL,VANOMES,VCODLOCA,VDATEMI)
*==================================================================
  V_PAG++
  PzeraLin()
  Imp(001,000,Replicate("-",133))
  Imp(002,000,VEMP)
  Imp(002,125,"Pag: "+StrZero(V_PAG,3))
  Imp(003,000,VNOMREL)
  Imp(004,000,"Periodo: "+Dtoc(VDATINI)+" a "+Dtoc(VDATFIM))
  Imp(004,114,"Emitido em "+DtoC(VDATEMI))
  If _FLAGLO_PA = "M"
     LO->(  DbSeek( VCODLOCA )  )
     Imp(Prow()+1,66,PadR("Localizacao: "+VCODLOCA+' - '+LO->DESCRI_LO,40))
  Endif
  Imp(Prow()+1,000,Replicate("-",133))
  Imp(Prow()+1,000,"Data           Lanc.     Historico                                    Doc.    C/Partida         Debitos       Creditos    Saldo atual")
  //                99/99/99     9999999     X                                           X   9    9999999999  99,999,999.99  99,999,999.99  99,999,999.99"
  Imp(Prow()+1,000,Replicate("-",133))
Return

*=================================================
Static Function Filtro(VANOMES,VCODLOCA,VDATEMI)
*=================================================
Local VCANT, VTELA, VSETCF, M, VL1, VC1, VL2, VC2, ;
      VCODLOCI

VCANT := Setcolor( "N/W+,W+/R" )

// Calcula tamanho Box
M:=FcalcBox(  11,                                                           ;
              If( _FLAGLO_PA = "M", 16, 14 ),                               ;
              If( _FLAGLO_PA = "M", "Digite Localizacoes ou <T> p/ todas:", ;
                                    "De 99/99/99 a 99/99/99" )              )
VL1 := M[1]
VC1 := M[2]
VL2 := M[3]
VC2 := M[4]
VTELA := ShadowBox( VL1, VC1, VL2, VC2 )  // ( 11, 30, 13, 49 )

VSETCF := Set( _SET_CONFIRM )
@ 12,29 Say "De" Get VDATINI When  ( Set( _SET_CONFIRM, .F. ), .T. )
@ 12,41 Say "a"  Get VDATFIM When  ( Set( _SET_CONFIRM, .F. ), .T. ) ;
                             Valid VDATFIM > VDATINI
@ 13,29 Say "Emitido em" Get VDATEMI When  ( Set( _SET_CONFIRM, .T. ), .T. )
If _FLAGLO_PA = "M"
   @ 14,29 Say "Digite Localizacoes ou <T> p/ todas:"
   @ 15,29 Get VCODLOCS Pict '@! 99' + Repl( '.99', 11 ) Valid !Empty(Left(VCODLOCS,2)) .or. Left(VCODLOCS,1) == "T"
   //                         99.99.99.99.99.99.99.99.99.99.99.99
Endif
Read
Set( _SET_CONFIRM, VSETCF )
If Lastkey() = K_ESC
   ByeByeBox( VTELA )
   Setcolor( VCANT )
   Return .F.
Endif

// Seeks( Posiciona arquivos )
If _FLAGLO_PA = "M"
   // Retorna primeira loc. em que foram encontrados dados
   VCODLOCI := FRetLocUti("00",Dtos(VDATINI))
Else
   VCODLOCI := "00"
Endif

// Se tiver locs. digitadas liga filtros
If _FLAGLO_PA = "M" .and. !("T" $ VCODLOCS)
   Sele DB
   Set Filter to DB->CODLOC_DB $ VCODLOCS
   Sele CR
   Set Filter to CR->CODLOC_CR $ VCODLOCS
Endif
VANOMES  := FAnoMesC( VDATINI )
VANOMESI := FAnoMesC( VDATINI )
VANOMESF := FAnoMesC( VDATFIM )
VCODLOCA := VCODLOCI

ByeByeBox( VTELA )
Setcolor( VCANT )
Return .T.

*==============================================================================
Static Procedure PSetRela(VARQATU)
*==============================================================================
Local VARQ
VARQ := If( VARQATU = "DB", "CR", "DB" )
(VARQATU)->(  DbSetOrder( 3 )  )
(VARQ)->( FDesligRel() )
(VARQATU)->(  FLigRel( VARQATU, VARQ )  )
Return

*==============================================================================
Static Function FLigRel(VARQAT,VARQ)
*==============================================================================
Priv VCHA
// Chave(DB/CR): CODLOC_ + IMPLAN_ + Dtos(DATLAN_) + CODLAN_
(VARQ)->(  DbSetOrder( 5 )  )
VCHA := Strtran(  (VARQ)->(  Rtrim( Indexkey() )  ), '_' + VARQ, '_' + VARQAT  )
Set Relation to &VCHA into ( VARQ )
*==============================================================================
Static Function FDesligRel()
*==============================================================================
Set Relation to
Return Nil

*==============================================================================
Function ImpCarCont( VCARCONTR )
*==============================================================================
local VLIN, VCOL, VSETPRA, VSETCOA
If V_PAG >= V_PAGI .and. V_PAG <= V_PAGF
   VSETPRA := Set( _SET_PRINTER, .T. )
   VLIN := Prow() ; VCOL := Pcol()
   VSETCOA := Set( _SET_CONSOLE, .F. )
   ?? VCARCONTR
   Set( _SET_CONSOLE, VSETCOA )
   SetPrc( VLIN, VCOL )
   Set( _SET_PRINTER, VSETPRA )
Endif
Return( "" )

*==============================================================================
Static Function FSaldoMes( VCSCONTA, VSALANT, VTOTDEB, VTOTCRE )
*==============================================================================
Local F_SINALNEG := FaSinalNeg( VCSCONTA )
Local VGRP := Left( VCSCONTA, 1 )
      If VGRP = '1'
         If ! F_SINALNEG
            VSALATU := VSALANT + VTOTDEB - VTOTCRE
         Else
            VSALATU := VSALANT - VTOTDEB + VTOTCRE
         Endif
      Elseif VGRP $ '2,3'
         If ! F_SINALNEG
            VSALATU := VSALANT - VTOTDEB + VTOTCRE
         Else
            VSALATU := VSALANT + VTOTDEB - VTOTCRE
         Endif
      Endif
Return( VSALATU )


{ KOL MCK } // Do not remove this line!
const N1 = 0;
const N2 = 1;
const N3 = 2;
const N6 = 3;
const N7 = 4;
const N8 = 5;
const N9 = 6;
const N12 = 7;
const N10 = 8;
const N11 = 9;
const N15 = 10;
const N16 = 11;
const N17 = 12;
const N18 = 13;
const N19 = 14;
const N20 = 15;
const N5 = 17;
const N13 = 19;


procedure NewFDropZone( var Result: PFDropZone; AParent: PControl );
begin

  {$IFDEF KOLCLASSES}
  Result := PFDropZone.Create;
  {$ELSE OBJECTS}
  New( Result, Create );
  {$ENDIF KOL CLASSES/OBJECTS}
  Result.Form := NewForm( AParent, 'FDropZone' ).SetPosition( 633, 217 );
  Result.Form.Add2AutoFree( Result );
    Result.Form.AlphaBlend := 254;
    Result.Form.HasBorder := False;
    Result.Form.SetClientSize( 214, 25);
    Result.Form.StayOnTop := True;
    Result.Form.Font.FontName := 'MS Sans Serif';
    Result.Form.Border := 0;
      Result.Form.OnMessage := Result.KOLForm1Message;
      Result.Form.OnClose := Result.KOLForm1Close;
      Result.Form.OnMouseDown := Result.KOLForm1MouseDown;
      Result.Form.OnMove := Result.KOLForm1Move;
      Result.Form.OnShow := Result.KOLForm1Show;
      Result.Form.OnHide := Result.KOLForm1Hide;
      Result.Form.OnPaint := Result.KOLForm1Paint;
    NewMenu( Result.Form, 0, [ '' ], nil );

    Result.Timer1 := NewTimer( 500 );
  Result.Form.Add2AutoFree( Result.Timer1 );
      Result.Timer1.OnTimer := Result.Timer1Timer;

    Result.Popup1 := NewMenu( Result.Form, 0, [ 'Transparent'
      , 'Snap', 'Remain', 'Alpha Blend', '(', '-!' + '30 %'
      , '-!' + '40 %', '-!' + '50 %', '-!' + '60 %'
      , '-!' + '70 %', '-!' + 'Disabled', ')', 'Font Size', '('
      , '100%', '125%', '150%', '175%', '200%', ')', '-' + ''
      , 'Close', '-' + '', 'Open Shollu', '' ], nil );
    Result.Popup1.AssignEvents( 0, [ Result.Popup1N1Menu ] );
    Result.Popup1.AssignEvents( 1, [ Result.Popup1N2Menu ] );
    Result.Popup1.AssignEvents( 2, [ Result.Popup1N3Menu ] );
    Result.Popup1.AssignEvents( 4, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 5, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 6, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 7, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 8, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 9, [ Result.Popup1N7Menu ] );
    Result.Popup1.AssignEvents( 11, [ Result.Popup1N16Menu ] );
    Result.Popup1.AssignEvents( 12, [ Result.Popup1N17Menu ] );
    Result.Popup1.AssignEvents( 13, [ Result.Popup1N18Menu ] );
    Result.Popup1.AssignEvents( 14, [ Result.Popup1N19Menu ] );
    Result.Popup1.AssignEvents( 15, [ Result.Popup1N20Menu ] );
    Result.Popup1.AssignEvents( 17, [ Result.Popup1N5Menu ] );
    Result.Popup1.AssignEvents( 19, [ Result.Popup1N13Menu ] );
      Result.Popup1.OnPopup := Result.Popup1Popup;
    Result.Linfo := NewLabel( Result.Form, '-' ).SetPosition( 14, 4 ).AutoSize( TRUE ).SetBorder( 2);
    Result.Linfo.Font.FontStyle := [ fsBold ];
    Result.Linfo.Font.FontHeight := 15;
    Result.Linfo.Font.FontName := 'Arial';
    Result.Linfo.Transparent := True;
    Result.LInfo2 := NewLabel( Result.Form, '-' ).SetPosition( 22, 4 ).AutoSize( TRUE ).SetBorder( 2);
    Result.LInfo2.Font.FontHeight := 15;
    Result.LInfo2.Font.FontName := 'Arial';
    Result.LInfo2.Transparent := True;
    Result.GPMain := NewGradientPanel( Result.Form, clBlue, clNavy ).SetAlign ( caClient ).SetBorder( 2);
    Result.GPMain.TabStop := FALSE;
    Result.GPMain.Visible := False;
    Result.GPMain.HasBorder := TRUE;
      Result.Linfo.OnMouseDown := Result.KOLForm1MouseDown;
      Result.Linfo.OnResize := Result.LinfoResize;
      Result.LInfo2.OnMouseDown := Result.KOLForm1MouseDown;
      Result.LInfo2.OnResize := Result.LinfoResize;
      Result.GPMain.OnMouseDown := Result.KOLForm1MouseDown;
    Result.Form.SetAutoPopupMenu( Result.Popup1 );
    Result.KOLForm1FormCreate( Result );

end;


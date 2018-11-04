unit umain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Spin, ComCtrls, ExtDlgs, BGRAVirtualScreen,
  BCTrackbarUpdown, BCPanel, BGRAImageList, BCButton, BGRALazPaint, BGRABitmap,
  BGRABitmapTypes, BGRATransform, BGRALayerOriginal, BGRAGraphics,
  uvectororiginal;

const
  EditorPointSize = 8;

type
  TPaintTool = (ptHand, ptRectangle, ptEllipse, ptPolyline, ptCurve, ptPolygon, ptClosedCurve);

const
  PaintToolClass : array[TPaintTool] of TVectorShapeAny =
    (nil, TRectShape, TEllipseShape, TPolylineShape, TCurveShape, TPolylineShape, TCurveShape);

function IsCreateShapeTool(ATool: TPaintTool): boolean;

const
  SplineStyleToStr : array[TSplineStyle] of string =
    ('Inside','Inside + ends','Crossing','Crossing + ends','Outside','Round outside','Vertex to side','Easy Bézier');

type
  { TForm1 }

  TForm1 = class(TForm)
    BackImage: TImage;
    Label2: TLabel;
    PanelBasicStyle: TBCPanel;
    PanelFile: TBCPanel;
    PanelExtendedStyle: TBCPanel;
    BCPanelToolChoice: TBCPanel;
    BCPanelToolbar: TBCPanel;
    BGRAImageList1: TBGRAImageList;
    BGRAVirtualScreen1: TBGRAVirtualScreen;
    ButtonLoadTex: TBCButton;
    ButtonOpenFile: TBCButton;
    ButtonSaveFile: TBCButton;
    ButtonSaveAs: TBCButton;
    ButtonNewFile: TBCButton;
    ButtonNoTex: TBCButton;
    ColorDialog1: TColorDialog;
    ComboBoxPenStyle: TComboBox;
    FloatSpinEditPenWidth: TFloatSpinEdit;
    Label1: TLabel;
    Label3: TLabel;
    OpenDialog1: TOpenDialog;
    OpenPictureDialog1: TOpenPictureDialog;
    RadioButtonSolid: TRadioButton;
    RadioButtonNone: TRadioButton;
    RadioButtonTex: TRadioButton;
    SaveDialog1: TSaveDialog;
    ShapeBackColor: TShape;
    ShapePenColor: TShape;
    ToolBar1: TToolBar;
    ToolButtonPolyline: TToolButton;
    ToolButtonCurve: TToolButton;
    ToolButtonMove: TToolButton;
    ToolButtonClosedCurve: TToolButton;
    ToolButtonPolygon: TToolButton;
    ToolButtonRectangle: TToolButton;
    ToolButtonEllipse: TToolButton;
    UpDownBackAlpha: TBCTrackbarUpdown;
    UpDownPenAlpha: TBCTrackbarUpdown;
    procedure BGRAVirtualScreen1MouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BGRAVirtualScreen1MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure BGRAVirtualScreen1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure BGRAVirtualScreen1Redraw(Sender: TObject; Bitmap: TBGRABitmap);
    procedure ButtonLoadTexClick(Sender: TObject);
    procedure ButtonNewFileClick(Sender: TObject);
    procedure ButtonNoTexClick(Sender: TObject);
    procedure ButtonOpenFileClick(Sender: TObject);
    procedure ButtonSaveAsClick(Sender: TObject);
    procedure ButtonSaveFileClick(Sender: TObject);
    procedure ComboBoxPenStyleChange(Sender: TObject);
    procedure FloatSpinEditPenWidthChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; {%H-}Shift: TShiftState);
    procedure RadioButtonBackChange(Sender: TObject);
    procedure ShapeBackColorMouseUp(Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure ShapePenColorMouseUp(Sender: TObject; {%H-}Button: TMouseButton;
      {%H-}Shift: TShiftState; X, Y: Integer);
    procedure ToolButtonClick(Sender: TObject);
    procedure UpDownBackAlphaChange(Sender: TObject; AByUser: boolean);
    procedure UpDownPenAlphaChange(Sender: TObject; AByUser: boolean);
  private
    FPenColor, FBackColor: TBGRAPixel;
    FBackTexture: TBGRABitmap;
    FPenWidth: single;
    FPenStyle: TBGRAPenStyle;
    FFlattened: TBGRABitmap;
    FLastEditorBounds: TRect;
    FUpdatingFromShape: boolean;
    FUpdatingComboBoxPenStyle, FUpdatingSpinEditPenWidth: boolean;
    FCurrentTool: TPaintTool;
    FSplineStyle: TSplineStyle;
    FComboboxSplineStyle: TComboBox;
    FUpdatingComboboxSplineStyle : boolean;
    procedure ComboBoxSplineStyleChange(Sender: TObject);
    function GetBackColor: TBGRAPixel;
    function GetBackTexture: TBGRABitmap;
    function GetPenColor: TBGRAPixel;
    function GetPenStyle: TBGRAPenStyle;
    function GetPenWidth: single;
    function GetSplineStyle: TSplineStyle;
    function GetVectorTransform: TAffineMatrix;
    procedure ImageChange(ARectF: TRectF);
    procedure OnEditingChange({%H-}ASender: TObject; AOriginal: TBGRALayerCustomOriginal);
    procedure OnOriginalChange({%H-}ASender: TObject; AOriginal: TBGRALayerCustomOriginal);
    procedure OnSelectShape(ASender: TObject; AShape: TVectorShape; APreviousShape: TVectorShape);
    procedure SetBackColor(AValue: TBGRAPixel);
    procedure SetBackTexture(AValue: TBGRABitmap);
    procedure SetCurrentTool(AValue: TPaintTool);
    procedure SetPenColor(AValue: TBGRAPixel);
    procedure SetPenStyle(AValue: TBGRAPenStyle);
    procedure SetPenWidth(AValue: single);
    procedure SetSplineStyle(AValue: TSplineStyle);
    procedure UpdateViewCursor(ACursor: TOriginalEditorCursor);
    procedure RenderAndUpdate(ADraft: boolean);
    procedure UpdateFlattenedImage(ARect: TRect);
    procedure UpdateView(AImageChangeRect: TRect);
    procedure UpdateToolbarFromShape(AShape: TVectorShape);
    procedure UpdateTitleBar;
    procedure ImageChangesCompletely;
    function CreateShape(const APoint1, APoint2: TPointF): TVectorShape;
    { private declarations }
  public
    { public declarations }
    img: TBGRALazPaintImage;
    filename: string;
    vectorOriginal: TVectorOriginal;
    zoom: TAffineMatrix;
    newShape: TVectorShape;
    justDown: boolean;
    newStartPoint: TPointF;
    newButton: TMouseButton;
    vectorLayer: Integer;
    mouseState: TShiftState;
    baseCaption: string;
    property vectorTransform: TAffineMatrix read GetVectorTransform;
    property penColor: TBGRAPixel read GetPenColor write SetPenColor;
    property backColor: TBGRAPixel read GetBackColor write SetBackColor;
    property backTexture: TBGRABitmap read GetBackTexture write SetBackTexture;
    property penWidth: single read GetPenWidth write SetPenWidth;
    property penStyle: TBGRAPenStyle read GetPenStyle write SetPenStyle;
    property splineStyle: TSplineStyle read GetSplineStyle write SetSplineStyle;
    property currentTool: TPaintTool read FCurrentTool write SetCurrentTool;
  end;

var
  Form1: TForm1;

implementation

uses math, LCLType, BGRAPen, BGRAThumbnail, BGRAGradientScanner;

function IsCreateShapeTool(ATool: TPaintTool): boolean;
begin
  result := PaintToolClass[ATool] <> nil;
end;

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  baseCaption:= Caption;
  img := TBGRALazPaintImage.Create(1600,1200);
  filename := '';
  vectorOriginal := TVectorOriginal.Create;
  vectorLayer := img.AddLayerFromOwnedOriginal(vectorOriginal);
  img.LayerOriginalMatrix[vectorLayer] := AffineMatrixScale(1,1);
  vectorOriginal.OnSelectShape:= @OnSelectShape;
  img.OnOriginalEditingChange:= @OnEditingChange;
  img.OnOriginalChange:= @OnOriginalChange;
  zoom := AffineMatrixScale(1,1);
  newShape:= nil;
  penColor := BGRABlack;
  backColor := CSSDodgerBlue;
  penWidth := 5;
  penStyle := SolidPenStyle;
  currentTool:= ptRectangle;
  splineStyle:= ssEasyBezier;
  UpdateTitleBar;
end;

procedure TForm1.BGRAVirtualScreen1Redraw(Sender: TObject; Bitmap: TBGRABitmap);
var
  topLeftF, bottomRightF: TPointF;
  zoomBounds: TRect;
begin
  topLeftF := zoom*PointF(0,0);
  bottomRightF := zoom*PointF(img.Width,img.Height);
  zoomBounds := Rect(round(topLeftF.X),round(topLeftF.Y),round(bottomRightF.X),round(bottomRightF.Y));
  Bitmap.DrawCheckers(zoomBounds, CSSWhite,CSSSilver);
  if FFlattened = nil then
    UpdateFlattenedImage(rect(0,0,img.Width,img.Height));
  Bitmap.StretchPutImage(zoomBounds, FFlattened, dmLinearBlend);
  FLastEditorBounds := img.DrawEditor(Bitmap, vectorLayer, zoom, EditorPointSize);
end;

procedure TForm1.ButtonLoadTexClick(Sender: TObject);
var
  newTex: TBGRABitmap;
begin
  if OpenPictureDialog1.Execute then
  begin
    try
      newTex := TBGRABitmap.Create(OpenPictureDialog1.FileName, true);
      backTexture := newTex;
      RadioButtonTex.Checked:= true;
    except
      on ex: exception do
        ShowMessage(ex.Message);
    end;
  end;
  if RadioButtonTex.Checked and (backTexture = nil) then
    RadioButtonNone.Checked:= true;
end;

procedure TForm1.ButtonNewFileClick(Sender: TObject);
begin
  if Assigned(vectorOriginal) then
  begin
    vectorOriginal.Clear;
    filename := '';
    UpdateTitleBar;
  end;
end;

procedure TForm1.ButtonNoTexClick(Sender: TObject);
begin
  backTexture := nil;
end;

procedure TForm1.ButtonOpenFileClick(Sender: TObject);
var
  openedImg: TBGRALazPaintImage;
  openedLayer: Integer;
  openedLayerOriginal: TBGRALayerCustomOriginal;
begin
  if OpenDialog1.Execute then
  begin
    openedImg := TBGRALazPaintImage.Create;
    try
      openedImg.LoadFromFile(OpenDialog1.FileName);
      if openedImg.NbLayers <> 1 then raise exception.Create('Expecting one layer only');
      openedLayer := 0;
      openedLayerOriginal := openedImg.LayerOriginal[openedLayer];
      if (openedLayerOriginal = nil) or not (openedLayerOriginal is TVectorOriginal) then
        raise exception.Create('Not a vectorial image');

      img.Free;
      img := openedImg;
      openedImg := nil;
      vectorLayer:= openedLayer;
      vectorOriginal := TVectorOriginal(openedLayerOriginal);
      vectorOriginal.OnSelectShape:= @OnSelectShape;
      img.OnOriginalEditingChange:= @OnEditingChange;
      img.OnOriginalChange:= @OnOriginalChange;
      filename:= OpenDialog1.FileName;
      UpdateTitleBar;
      ImageChangesCompletely;
    except
      on ex: exception do
        ShowMessage(ex.Message);
    end;
    openedImg.Free;
  end;
end;

procedure TForm1.ButtonSaveAsClick(Sender: TObject);
begin
  if not Assigned(img) then exit;
  if SaveDialog1.Execute then
  begin
    try
      img.SaveToFile(SaveDialog1.FileName);
      filename := SaveDialog1.FileName;
      UpdateTitleBar;
    except
      on ex: exception do
        ShowMessage(ex.Message);
    end;
  end;
end;

procedure TForm1.ButtonSaveFileClick(Sender: TObject);
begin
  if filename = '' then
    ButtonSaveAsClick(Sender)
  else
  begin
    try
      img.SaveToFile(filename);
    except
      on ex: exception do
        ShowMessage(ex.Message);
    end;
  end;
end;

procedure TForm1.ComboBoxPenStyleChange(Sender: TObject);
begin
  if FUpdatingComboBoxPenStyle then exit;
  case ComboBoxPenStyle.ItemIndex of
    0: penStyle := ClearPenStyle;
    1: penStyle := SolidPenStyle;
    2: penStyle := DashPenStyle;
    3: penStyle := DotPenStyle;
    4: penStyle := DashDotPenStyle;
    5: penStyle := DashDotDotPenStyle;
  end;
end;

procedure TForm1.FloatSpinEditPenWidthChange(Sender: TObject);
begin
  if FUpdatingSpinEditPenWidth then exit;
  penWidth := FloatSpinEditPenWidth.Value;
end;

procedure TForm1.BGRAVirtualScreen1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  imgPtF: TPointF;
  cur: TOriginalEditorCursor;
  handled: boolean;
begin
  mouseState:= Shift;
  imgPtF := AffineMatrixInverse(zoom)*PointF(X,Y);
  img.MouseDown(Button=mbRight, Shift, imgPtF.x, imgPtF.y, cur, handled);
  UpdateViewCursor(cur);
  if handled then exit;

  if not justDown and not Assigned(newShape) then
  begin
    newStartPoint := AffineMatrixInverse(vectorTransform)*imgPtF;
    newButton := Button;
    justDown := true;
  end;
end;

procedure TForm1.BGRAVirtualScreen1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  imgPtF, ptF: TPointF;
  prevRF, rF: TRectF;
  cur: TOriginalEditorCursor;
  handled: boolean;
begin
  mouseState:= Shift;
  imgPtF := AffineMatrixInverse(zoom)*PointF(X,Y);
  img.MouseMove(Shift, imgPtF.X, imgPtF.Y, cur, handled);
  UpdateViewCursor(cur);

  ptF := AffineMatrixInverse(vectorTransform)*imgPtF;
  if justDown and not Assigned(newShape) and IsCreateShapeTool(currentTool) then
  begin
    vectorOriginal.DeselectShape;
    newShape := CreateShape(newStartPoint,ptF);
    rF := newShape.GetRenderBounds(InfiniteRect, vectorTransform);
    ImageChange(rF);
    justDown := false;
  end else
  if Assigned(newShape) then
  begin
    prevRF := newShape.GetRenderBounds(InfiniteRect, vectorTransform);
    newShape.QuickDefine(newStartPoint,ptF);
    rF := newShape.GetRenderBounds(InfiniteRect, vectorTransform);
    ImageChange(rF.Union(prevRF, true));
  end;
end;

procedure TForm1.BGRAVirtualScreen1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  rF: TRectF;
  imgPtF: TPointF;
  handled: boolean;
  cur: TOriginalEditorCursor;
  addedShape: TVectorShape;
begin
  mouseState:= Shift;
  imgPtF := AffineMatrixInverse(zoom)*PointF(X,Y);
  img.MouseUp(Button = mbRight, Shift, imgPtF.X, imgPtF.Y, cur, handled);
  if handled then RenderAndUpdate(false);
  UpdateViewCursor(cur);

  if justDown and (Button = newButton) then
  begin
    if IsCreateShapeTool(currentTool) and (vsuCreate in PaintToolClass[currentTool].Usermodes) then
    begin
      vectorOriginal.AddShape(CreateShape(newStartPoint,newStartPoint), vsuCreate);
    end else
      vectorOriginal.MouseClick(newStartPoint);
    justDown:= false;
  end
  else if Assigned(newShape) and (Button = newButton) then
  begin
    rF := newShape.GetRenderBounds(InfiniteRect, vectorTransform);
    if not IsEmptyRectF(rF) or (vsuCreate in newShape.Usermodes) then
    begin
      addedShape := newShape;
      newShape := nil;
      vectorOriginal.AddShape(addedShape, vsuCreate);
    end
    else
      FreeAndNil(newShape);
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  img.Free;
  FFlattened.Free;
  FBackTexture.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
  );
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    if Assigned(vectorOriginal) then
      vectorOriginal.DeselectShape;
  end else
  if Key = VK_DELETE then
  begin
    Key := 0;
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
      vectorOriginal.RemoveShape(vectorOriginal.SelectedShape);
  end;
end;

procedure TForm1.RadioButtonBackChange(Sender: TObject);
var
  texId: Integer;
begin
  if FUpdatingFromShape then exit;
  if (Sender = RadioButtonNone) and RadioButtonNone.Checked then
  begin
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
    begin
      vectorOriginal.SelectedShape.BackTexture := EmptyTextureId;
      vectorOriginal.SelectedShape.BackColor := BGRAPixelTransparent;
      vectorOriginal.RemoveUnusedTextures;
    end;
  end else
  if (Sender = RadioButtonSolid) and RadioButtonSolid.Checked then
  begin
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
    begin
      vectorOriginal.SelectedShape.BackTexture := EmptyTextureId;
      vectorOriginal.SelectedShape.BackColor := FBackColor;
      vectorOriginal.RemoveUnusedTextures;
    end;
  end else
  if (Sender = RadioButtonTex) and RadioButtonTex.Checked then
  begin
    if backTexture = nil then
      ButtonLoadTexClick(Sender)
    else
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
    begin
      texId:= vectorOriginal.AddTexture(backTexture);
      vectorOriginal.SelectedShape.BackTexture := texId;
      vectorOriginal.SelectedShape.BackColor := BGRAPixelTransparent;
      vectorOriginal.RemoveUnusedTextures;
    end;
  end;
end;

procedure TForm1.ShapeBackColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ColorDialog1.Color := ShapeBackColor.Brush.Color;
  if ColorDialog1.Execute then
  begin
    if backColor.alpha <> 0 then
      backColor := ColorToBGRA(ColorDialog1.Color, backColor.alpha)
    else
      backColor := ColorDialog1.Color;
  end;
end;

procedure TForm1.ShapePenColorMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ColorDialog1.Color := ShapePenColor.Brush.Color;
  if ColorDialog1.Execute then
  begin
    if penColor.alpha <> 0 then
      penColor := ColorToBGRA(ColorDialog1.Color, penColor.alpha)
    else
      penColor := ColorDialog1.Color;
  end;
end;

procedure TForm1.ToolButtonClick(Sender: TObject);
begin
  currentTool := ptHand;
  if ToolButtonEllipse.Down then currentTool:= ptEllipse;
  if ToolButtonRectangle.Down then currentTool:= ptRectangle;
  if ToolButtonPolyline.Down then currentTool:= ptPolyline;
  if ToolButtonCurve.Down then currentTool:= ptCurve;
  if ToolButtonPolygon.Down then currentTool:= ptPolygon;
  if ToolButtonClosedCurve.Down then currentTool:= ptClosedCurve;
  if IsCreateShapeTool(currentTool) then
  begin
    if Assigned(vectorOriginal) and (vectorOriginal.SelectedShape <> nil) then vectorOriginal.DeselectShape
    else UpdateToolbarFromShape(nil);

    if currentTool in [ptPolyline, ptCurve] then
      RadioButtonNone.Checked := true;
  end;
end;

procedure TForm1.UpDownBackAlphaChange(Sender: TObject; AByUser: boolean);
begin
  if AByUser then
  begin
    FBackColor:= ColorToBGRA(ShapeBackColor.Brush.Color, UpDownBackAlpha.Value);
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
      vectorOriginal.SelectedShape.BackColor:= FBackColor;
  end;
end;

procedure TForm1.UpDownPenAlphaChange(Sender: TObject; AByUser: boolean);
begin
  if AByUser then
  begin
    FPenColor:= ColorToBGRA(ShapePenColor.Brush.Color, UpDownPenAlpha.Value);
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
      vectorOriginal.SelectedShape.PenColor:= FPenColor;
  end;
end;

procedure TForm1.ComboBoxSplineStyleChange(Sender: TObject);
begin
  if FUpdatingComboboxSplineStyle then exit;
  if FComboboxSplineStyle.ItemIndex <> -1 then
    splineStyle:= TSplineStyle(FComboboxSplineStyle.ItemIndex);
end;

function TForm1.GetBackColor: TBGRAPixel;
begin
  result := FBackColor;
end;

function TForm1.GetBackTexture: TBGRABitmap;
begin
  result := FBackTexture;
end;

function TForm1.GetPenColor: TBGRAPixel;
begin
  result := FPenColor;
end;

function TForm1.GetPenStyle: TBGRAPenStyle;
begin
  result := FPenStyle;
end;

function TForm1.GetPenWidth: single;
begin
  result := FPenWidth;
end;

function TForm1.GetSplineStyle: TSplineStyle;
begin
  result := FSplineStyle;
end;

function TForm1.GetVectorTransform: TAffineMatrix;
begin
  if vectorLayer<>-1 then
    result:= img.LayerOriginalMatrix[vectorLayer]
  else
    result:= AffineMatrixIdentity;
end;

procedure TForm1.ImageChange(ARectF: TRectF);
var
  changeRect: TRect;
begin
  if not IsEmptyRectF(ARectF) then
  begin
    changeRect := rect(floor(ARectF.Left),floor(ARectF.Top),ceil(ARectF.Right),ceil(ARectF.Bottom));
    UpdateFlattenedImage(changeRect);
  end;
end;

procedure TForm1.OnEditingChange(ASender: TObject;
  AOriginal: TBGRALayerCustomOriginal);
begin
  if AOriginal <> vectorOriginal then exit;
  UpdateView(EmptyRect);
end;

procedure TForm1.OnOriginalChange(ASender: TObject; AOriginal: TBGRALayerCustomOriginal);
var
  slowShape: boolean;
begin
  if AOriginal <> vectorOriginal then exit;
  slowShape := false;
  if mouseState * [ssLeft,ssRight] <> [] then
  begin
    if Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
      slowShape := vectorOriginal.SelectedShape.GetIsSlow(vectorTransform);
  end;
  RenderAndUpdate(slowShape);
end;

procedure TForm1.OnSelectShape(ASender: TObject; AShape: TVectorShape;
  APreviousShape: TVectorShape);
begin
  if ASender <> vectorOriginal then exit;
  UpdateToolbarFromShape(AShape);
  if APreviousShape <> nil then
    if IsEmptyRectF(APreviousShape.GetRenderBounds(InfiniteRect, vectorTransform)) then
    begin
      vectorOriginal.RemoveShape(APreviousShape);
      ShowMessage('Empty shape has been deleted');
    end;
end;

procedure TForm1.SetBackColor(AValue: TBGRAPixel);
begin
  FBackColor := AValue;
  ShapeBackColor.Brush.Color := AValue.ToColor;
  UpDownBackAlpha.Value := AValue.alpha;
  if not FUpdatingFromShape and Assigned(vectorOriginal) and RadioButtonSolid.Checked then
  begin
    if Assigned(vectorOriginal.SelectedShape) then
      vectorOriginal.SelectedShape.BackColor := AValue;
  end;
end;

procedure TForm1.SetBackTexture(AValue: TBGRABitmap);
var
  thumb: TBGRABitmap;
  bmpThumb: TBitmap;
begin
  if Assigned(AValue) and Assigned(FBackTexture) and AValue.Equals(FBackTexture) then exit;
  if AValue = FBackTexture then exit;
  FreeAndNil(FBackTexture);
  FBackTexture := AValue;
  if Assigned(FBackTexture) then
  begin
    thumb := GetBitmapThumbnail(FBackTexture, BackImage.Width,BackImage.Height,BGRAPixelTransparent,true);
    try
      bmpThumb := thumb.MakeBitmapCopy(clBtnFace);
      try
        BackImage.Picture.Assign(bmpThumb);
      finally
        bmpThumb.Free;
      end;
    finally
      thumb.Free;
    end;
    BackImage.Visible := true;
  end else
  begin
    BackImage.Picture.Clear;
    BackImage.Visible := false;
  end;
  if not FUpdatingFromShape and Assigned(vectorOriginal) and RadioButtonTex.Checked then
  begin
    if Assigned(vectorOriginal.SelectedShape) then
    begin
      vectorOriginal.SelectedShape.BackTexture := vectorOriginal.AddTexture(FBackTexture);
      vectorOriginal.RemoveUnusedTextures;
    end;
  end;
end;

procedure TForm1.SetCurrentTool(AValue: TPaintTool);
begin
  if FCurrentTool=AValue then Exit;
  FCurrentTool:=AValue;
  ToolButtonRectangle.Down := FCurrentTool = ptRectangle;
  ToolButtonEllipse.Down := FCurrentTool = ptEllipse;
  ToolButtonPolygon.Down := FCurrentTool = ptPolygon;
  ToolButtonClosedCurve.Down := FCurrentTool = ptClosedCurve;
  ToolButtonPolyline.Down := FCurrentTool = ptPolyline;
  ToolButtonCurve.Down := FCurrentTool = ptCurve;
end;

procedure TForm1.SetPenColor(AValue: TBGRAPixel);
begin
  FPenColor := AValue;
  ShapePenColor.Brush.Color := BGRA(AValue.red,AValue.green,AValue.blue).ToColor;
  UpDownPenAlpha.Value := AValue.alpha;
  if not FUpdatingFromShape and Assigned(vectorOriginal) then
  begin
    if Assigned(vectorOriginal.SelectedShape) then
      vectorOriginal.SelectedShape.PenColor := AValue;
  end;
end;

procedure TForm1.SetPenStyle(AValue: TBGRAPenStyle);
var cur: integer;
begin
  FPenStyle := AValue;
  case BGRAToPenStyle(AValue) of
    psClear: cur:= 0;
    psSolid: cur:= 1;
    psDash: cur := 2;
    psDot: cur := 3;
    psDashDot: cur := 4;
    psDashDotDot: cur := 5;
    else cur := 6;
  end;
  FUpdatingComboBoxPenStyle := true;
  ComboBoxPenStyle.ItemIndex := cur;
  FUpdatingComboBoxPenStyle := false;
  if not FUpdatingFromShape and Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
    vectorOriginal.SelectedShape.PenStyle := FPenStyle;
end;

procedure TForm1.SetPenWidth(AValue: single);
var
  cur: single;
begin
  FPenWidth := AValue;
  cur := FloatSpinEditPenWidth.Value;
  if AValue <> cur then
  begin
    FUpdatingSpinEditPenWidth:= true;
    FloatSpinEditPenWidth.Value := AValue;
    FUpdatingSpinEditPenWidth:= false;
  end;
  if not FUpdatingFromShape and Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) then
    vectorOriginal.SelectedShape.PenWidth:= penWidth;
end;

procedure TForm1.SetSplineStyle(AValue: TSplineStyle);
begin
  FSplineStyle := AValue;
  if Assigned(FComboboxSplineStyle) then
  begin
    FUpdatingComboboxSplineStyle := true;
    FComboboxSplineStyle.ItemIndex:= ord(FSplineStyle);
    FUpdatingComboboxSplineStyle := false;
  end;
  if not FUpdatingFromShape and Assigned(vectorOriginal) and Assigned(vectorOriginal.SelectedShape) and
    (vectorOriginal.SelectedShape is TCurveShape) then
    TCurveShape(vectorOriginal.SelectedShape).SplineStyle := FSplineStyle;
end;

procedure TForm1.UpdateViewCursor(ACursor: TOriginalEditorCursor);
begin
  case ACursor of
    oecDefault: BGRAVirtualScreen1.Cursor := crDefault;
    oecMove: BGRAVirtualScreen1.Cursor := crSizeAll;
    oecMoveN: BGRAVirtualScreen1.Cursor := crSizeN;
    oecMoveS: BGRAVirtualScreen1.Cursor := crSizeS;
    oecMoveE: BGRAVirtualScreen1.Cursor := crSizeE;
    oecMoveW: BGRAVirtualScreen1.Cursor := crSizeW;
    oecMoveNE: BGRAVirtualScreen1.Cursor := crSizeNE;
    oecMoveSW: BGRAVirtualScreen1.Cursor := crSizeSW;
    oecMoveNW: BGRAVirtualScreen1.Cursor := crSizeNW;
    oecMoveSE: BGRAVirtualScreen1.Cursor := crSizeSE;
  end;
end;

procedure TForm1.RenderAndUpdate(ADraft: boolean);
var
  renderedRect: TRect;
begin
  renderedRect := img.RenderOriginalsIfNecessary(ADraft);
  UpdateFlattenedImage(renderedRect);
end;

procedure TForm1.UpdateFlattenedImage(ARect: TRect);
var
  shapeRectF: TRectF;
  shapeRect: TRect;
begin
  if FFlattened = nil then
    FFlattened := img.ComputeFlatImage
  else
  if not IsRectEmpty(ARect) then
  begin
    FFlattened.FillRect(ARect,BGRAPixelTransparent,dmSet);
    FFlattened.ClipRect := ARect;
    img.Draw(FFlattened, 0,0);
    FFlattened.NoClip;
  end;

  if Assigned(newShape) and not IsRectEmpty(ARect) then
  begin
    shapeRectF := newShape.GetRenderBounds(InfiniteRect, vectorTransform);
    with shapeRectF do
      shapeRect := rect(floor(Left),floor(Top),ceil(Right),ceil(Bottom));
    if IntersectRect(shapeRect, shapeRect, ARect) then
    begin
      FFlattened.ClipRect := shapeRect;
      newShape.Render(FFlattened, vectorTransform, newShape.GetIsSlow(vectorTransform));
      FFlattened.NoClip;
    end;
  end;

  UpdateView(ARect);
end;

procedure TForm1.UpdateView(AImageChangeRect: TRect);
var
  viewRectF: TRectF;
  viewRect, newEditorBounds: TRect;
begin
  if IsRectEmpty(AImageChangeRect) then
  begin
    viewRectF := EmptyRectF;
    viewRect := EmptyRect;
  end
  else
  begin
    with AImageChangeRect do
      viewRectF := RectF(zoom* PointF(Left,Top), zoom* PointF(Right,Bottom));
    viewRect := rect(floor(viewRectF.Left),floor(viewRectF.Top),ceil(viewRectF.Right),ceil(viewRectF.Bottom));
  end;

  if not IsRectEmpty(FLastEditorBounds) then
  begin
    if IsRectEmpty(viewRect) then viewRect := FLastEditorBounds else
      UnionRect(viewRect,viewRect,FLastEditorBounds);
  end;
  if Assigned(img) then
  begin
    newEditorBounds := img.GetEditorBounds(vectorLayer, zoom, EditorPointSize);
    if not IsRectEmpty(newEditorBounds) then
    begin
      if IsRectEmpty(viewRect) then viewRect := newEditorBounds else
        UnionRect(viewRect,viewRect,newEditorBounds);
    end;
  end;

  if not IsRectEmpty(viewRect) then
  begin
    viewRect.Inflate(1,1);
    BGRAVirtualScreen1.RedrawBitmap(viewRect);
  end;
end;

procedure TForm1.UpdateToolbarFromShape(AShape: TVectorShape);
const ControlMargin = 8;
var
  f: TVectorShapeFields;
  showSplineStyle: boolean;
  nextControlPos: TPoint;
  s: TSplineStyle;
  texSource: TBGRABitmap;
begin
  if Assigned(FComboboxSplineStyle) then
  begin
    PanelExtendedStyle.RemoveControl(FComboboxSplineStyle);
    FreeAndNil(FComboboxSplineStyle);
  end;

  if AShape <> nil then
  begin
    FUpdatingFromShape := true;
    f := AShape.Fields;
    if vsfPenColor in f then penColor := AShape.PenColor;
    if vsfPenWidth in f then penWidth:= AShape.PenWidth;
    if vsfPenStyle in f then penStyle:= AShape.PenStyle;

    if (vsfBackTexture in f) and (AShape.BackTexture <> EmptyTextureId) then
    begin
      texSource := vectorOriginal.GetTexture(AShape.BackTexture);
      if Assigned(texSource) then
        backTexture := texSource.Duplicate as TBGRABitmap;
      RadioButtonTex.Checked := true;
    end else
    if (vsfBackColor in f) and (AShape.BackColor.alpha <> 0) then
    begin
      backColor := AShape.BackColor;
      RadioButtonSolid.Checked := true;
    end else
      RadioButtonNone.Checked := true;

    if AShape is TCurveShape then
    begin
      showSplineStyle:= true;
      splineStyle:= TCurveShape(AShape).SplineStyle;
    end else
      showSplineStyle:= false;
    FUpdatingFromShape := false;
  end else
  begin
    if IsCreateShapeTool(currentTool) then
    begin
      f := PaintToolClass[currentTool].Fields;
      showSplineStyle:= PaintToolClass[currentTool] = TCurveShape;
    end
    else
    begin
      f := [];
      showSplineStyle:= false;
    end;
  end;
  FloatSpinEditPenWidth.Enabled := vsfPenWidth in f;
  ComboBoxPenStyle.Enabled:= vsfPenStyle in f;

  nextControlPos := Point(ControlMargin,ShapeBackColor.Top);
  if showSplineStyle then
  begin
    FComboboxSplineStyle := TComboBox.Create(nil);
    FComboboxSplineStyle.Style := csDropDownList;
    FComboboxSplineStyle.Left := nextControlPos.X;
    FComboboxSplineStyle.Top := nextControlPos.Y;
    for s := low(SplineStyleToStr) to high(SplineStyleToStr) do
      FComboboxSplineStyle.Items.Add(SplineStyleToStr[s]);
    FComboboxSplineStyle.ItemIndex := ord(splineStyle);
    FComboboxSplineStyle.Width := 120;
    FComboboxSplineStyle.OnChange:= @ComboBoxSplineStyleChange;
    PanelExtendedStyle.InsertControl(FComboboxSplineStyle);
    nextControlPos.X := FComboboxSplineStyle.Left + FComboboxSplineStyle.Width + ControlMargin;
  end;
end;

procedure TForm1.UpdateTitleBar;
begin
  if filename = '' then
    Caption := baseCaption + ' - New image - ' + inttostr(img.Width)+'x'+inttostr(img.Height)
  else
    Caption := baseCaption + ' - ' + filename + ' - ' + inttostr(img.Width)+'x'+inttostr(img.Height);
end;

procedure TForm1.ImageChangesCompletely;
begin
  FreeAndNil(FFlattened);
  BGRAVirtualScreen1.DiscardBitmap;
end;

function TForm1.CreateShape(const APoint1,APoint2: TPointF): TVectorShape;
begin
  if not IsCreateShapeTool(currentTool) then
    raise exception.Create('No shape type selected');
  result := PaintToolClass[currentTool].Create(vectorOriginal);
  result.PenColor := penColor;

  if RadioButtonSolid.Checked then
    result.BackColor := backColor
  else if (vsfBackTexture in Result.Fields) and RadioButtonTex.Checked then
    result.BackTexture := vectorOriginal.AddTexture(backTexture)
  else
    result.BackColor := BGRAPixelTransparent;

  result.PenWidth := penWidth;
  result.PenStyle := penStyle;
  if currentTool in[ptClosedCurve,ptPolygon] then
    TCustomPolypointShape(result).Closed := true;
  if result is TCurveShape then TCurveShape(result).SplineStyle:= splineStyle;
  result.QuickDefine(APoint1,APoint2);
end;

end.


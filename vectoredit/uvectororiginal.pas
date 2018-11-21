unit uvectororiginal;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, BGRABitmap, BGRALayerOriginal, fgl, BGRAGradientOriginal, BGRABitmapTypes,
  BGRAPen, uvectorialfill;

const
  InfiniteRect : TRect = (Left: -MaxLongInt; Top: -MaxLongInt; Right: MaxLongInt; Bottom: MaxLongInt);
  EmptyTextureId = 0;

type
  TVectorOriginal = class;

  TShapeChangeEvent = procedure(ASender: TObject; ABounds: TRectF) of object;
  TShapeEditingChangeEvent = procedure(ASender: TObject) of object;

  TRenderBoundsOption = (rboAssumePenFill, rboAssumeBackFill);
  TRenderBoundsOptions = set of TRenderBoundsOption;
  TVectorShapeField = (vsfPenColor, vsfPenWidth, vsfPenStyle, vsfJoinStyle, vsfBackFill);
  TVectorShapeFields = set of TVectorShapeField;
  TVectorShapeUsermode = (vsuEdit, vsuCreate, vsuEditBackFill,
                          vsuCurveSetAuto, vsuCurveSetCurve, vsuCurveSetAngle);
  TVectorShapeUsermodes = set of TVectorShapeUsermode;

  { TVectorShape }

  TVectorShape = class
  private
    FOnChange: TShapeChangeEvent;
    FOnEditingChange: TShapeEditingChangeEvent;
    FUpdateCount: integer;
    FBoundsBeforeUpdate: TRectF;
    FPenColor: TBGRAPixel;
    FBackFill: TVectorialFill;
    FPenWidth: single;
    FStroker: TBGRAPenStroker;
    FUsermode: TVectorShapeUsermode;
    FContainer: TVectorOriginal;
    FRemoving: boolean;
    function GetIsBack: boolean;
    function GetIsFront: boolean;
    procedure SetContainer(AValue: TVectorOriginal);
  protected
    procedure BeginUpdate;
    procedure EndUpdate;
    function GetPenColor: TBGRAPixel; virtual;
    function GetPenWidth: single; virtual;
    function GetPenStyle: TBGRAPenStyle; virtual;
    function GetJoinStyle: TPenJoinStyle;
    function GetBackFill: TVectorialFill; virtual;
    procedure SetPenColor(AValue: TBGRAPixel); virtual;
    procedure SetPenWidth(AValue: single); virtual;
    procedure SetPenStyle({%H-}AValue: TBGRAPenStyle); virtual;
    procedure SetJoinStyle(AValue: TPenJoinStyle);
    procedure SetBackFill(AValue: TVectorialFill); virtual;
    procedure SetUsermode(AValue: TVectorShapeUsermode); virtual;
    procedure LoadFill(AStorage: TBGRACustomOriginalStorage; AObjectName: string; var AValue: TVectorialFill);
    procedure SaveFill(AStorage: TBGRACustomOriginalStorage; AObjectName: string; AValue: TVectorialFill);
    function ComputeStroke(APoints: ArrayOfTPointF; AClosed: boolean; AStrokeMatrix: TAffineMatrix): ArrayOfTPointF;
    function GetStroker: TBGRAPenStroker;
    property Stroker: TBGRAPenStroker read GetStroker;
    procedure FillChange({%H-}ASender: TObject); virtual;
  public
    constructor Create(AContainer: TVectorOriginal); virtual;
    destructor Destroy; override;
    procedure QuickDefine(const APoint1,APoint2: TPointF); virtual; abstract;
    procedure Render(ADest: TBGRABitmap; AMatrix: TAffineMatrix; ADraft: boolean); virtual; abstract;
    function GetRenderBounds(ADestRect: TRect; AMatrix: TAffineMatrix; AOptions: TRenderBoundsOptions = []): TRectF; virtual; abstract;
    function PointInShape(APoint: TPointF): boolean; virtual; abstract;
    procedure ConfigureEditor(AEditor: TBGRAOriginalEditor); virtual; abstract;
    procedure LoadFromStorage(AStorage: TBGRACustomOriginalStorage); virtual;
    procedure SaveToStorage(AStorage: TBGRACustomOriginalStorage); virtual;
    procedure MouseMove({%H-}Shift: TShiftState; {%H-}X, {%H-}Y: single; var {%H-}ACursor: TOriginalEditorCursor; var {%H-}AHandled: boolean); virtual;
    procedure MouseDown({%H-}RightButton: boolean; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: single; var {%H-}ACursor: TOriginalEditorCursor; var {%H-}AHandled: boolean); virtual;
    procedure MouseUp({%H-}RightButton: boolean; {%H-}Shift: TShiftState; {%H-}X, {%H-}Y: single; var {%H-}ACursor: TOriginalEditorCursor; var {%H-}AHandled: boolean); virtual;
    procedure KeyDown({%H-}Shift: TShiftState; {%H-}Key: TSpecialKey; var {%H-}AHandled: boolean); virtual;
    procedure KeyUp({%H-}Shift: TShiftState; {%H-}Key: TSpecialKey; var {%H-}AHandled: boolean); virtual;
    procedure KeyPress({%H-}UTF8Key: string; var {%H-}AHandled: boolean); virtual;
    procedure BringToFront;
    procedure SendToBack;
    procedure MoveUp(APassNonIntersectingShapes: boolean);
    procedure MoveDown(APassNonIntersectingShapes: boolean);
    procedure Remove;
    function Duplicate: TVectorShape;
    class function StorageClassName: RawByteString; virtual; abstract;
    function GetIsSlow({%H-}AMatrix: TAffineMatrix): boolean; virtual;
    class function Fields: TVectorShapeFields; virtual;
    class function Usermodes: TVectorShapeUsermodes; virtual;
    property OnChange: TShapeChangeEvent read FOnChange write FOnChange;
    property OnEditingChange: TShapeEditingChangeEvent read FOnEditingChange write FOnEditingChange;
    property PenColor: TBGRAPixel read GetPenColor write SetPenColor;
    property BackFill: TVectorialFill read GetBackFill write SetBackFill;
    property PenWidth: single read GetPenWidth write SetPenWidth;
    property PenStyle: TBGRAPenStyle read GetPenStyle write SetPenStyle;
    property JoinStyle: TPenJoinStyle read GetJoinStyle write SetJoinStyle;
    property Usermode: TVectorShapeUsermode read FUsermode write SetUsermode;
    property Container: TVectorOriginal read FContainer write SetContainer;
    property IsFront: boolean read GetIsFront;
    property IsBack: boolean read GetIsBack;
    property IsRemoving: boolean read FRemoving;
  end;
  TVectorShapes = specialize TFPGList<TVectorShape>;
  TVectorShapeAny = class of TVectorShape;

  TVectorOriginalSelectShapeEvent = procedure(ASender: TObject; AShape: TVectorShape; APreviousShape: TVectorShape) of object;

  TVectorOriginalEditor = class;

  { TVectorOriginal }

  TVectorOriginal = class(TBGRALayerCustomOriginal)
  private
    function GetShape(AIndex: integer): TVectorShape;
  protected
    FShapes: TVectorShapes;
    FDeletedShapes: TVectorShapes;
    FSelectedShape: TVectorShape;
    FFrozenShapesUnderSelection,
    FFrozenShapesOverSelection: TBGRABitmap;
    FFrozenShapesComputed: boolean;
    FFrozenShapeMatrix: TAffineMatrix;
    FOnSelectShape: TVectorOriginalSelectShapeEvent;
    FTextures: array of record
                 Bitmap: TBGRABitmap;
                 Id, Counter: integer;
               end;
    FTextureCount: integer;
    FLastTextureId: integer;
    procedure FreeDeletedShapes;
    procedure OnShapeChange(ASender: TObject; ABounds: TRectF);
    procedure OnShapeEditingChange({%H-}ASender: TObject);
    procedure DiscardFrozenShapes;
    function GetTextureId(ABitmap: TBGRABitmap): integer;
    function IndexOfTexture(AId: integer): integer;
    procedure AddTextureWithId(ATexture: TBGRABitmap; AId: integer);
    procedure ClearTextures;
    function GetShapeCount: integer;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure Clear;
    function AddTexture(ATexture: TBGRABitmap): integer;
    function GetTexture(AId: integer): TBGRABitmap;
    procedure DiscardUnusedTextures;
    function AddShape(AShape: TVectorShape): integer; overload;
    function AddShape(AShape: TVectorShape; AUsermode: TVectorShapeUsermode): integer; overload;
    function RemoveShape(AShape: TVectorShape): boolean;
    procedure SelectShape(AIndex: integer); overload;
    procedure SelectShape(AShape: TVectorShape); overload;
    procedure DeselectShape;
    procedure MouseClick(APoint: TPointF);
    procedure Render(ADest: TBGRABitmap; AMatrix: TAffineMatrix; ADraft: boolean); override;
    procedure ConfigureEditor(AEditor: TBGRAOriginalEditor); override;
    function CreateEditor: TBGRAOriginalEditor; override;
    function GetRenderBounds(ADestRect: TRect; {%H-}AMatrix: TAffineMatrix): TRect; override;
    procedure LoadFromStorage(AStorage: TBGRACustomOriginalStorage); override;
    procedure SaveToStorage(AStorage: TBGRACustomOriginalStorage); override;
    function IndexOfShape(AShape: TVectorShape): integer;
    procedure MoveShapeToIndex(AFromIndex: integer; AToIndex: integer);
    class function StorageClassName: RawByteString; override;
    property OnSelectShape: TVectorOriginalSelectShapeEvent read FOnSelectShape write FOnSelectShape;
    property SelectedShape: TVectorShape read FSelectedShape;
    property ShapeCount: integer read GetShapeCount;
    property Shape[AIndex: integer]: TVectorShape read GetShape;
  end;

  { TVectorOriginalEditor }

  TVectorOriginalEditor = class(TBGRAOriginalEditor)
  protected
    FOriginal: TVectorOriginal;
    FLabels: array of record
      Coord: TPointF;
      Text: string;
      HorizAlign: TAlignment;
      VertAlign: TTextLayout;
      Padding: integer;
    end;
    function NiceText(ADest: TBGRABitmap; x, y: integer; const ALayoutRect: TRect;
                      AText: string; AHorizAlign: TAlignment; AVertAlign: TTextLayout;
                      APadding: integer): TRect;
  public
    constructor Create(AOriginal: TVectorOriginal);
    procedure Clear; override;
    function Render(ADest: TBGRABitmap; const ALayoutRect: TRect): TRect; override;
    function GetRenderBounds(const ALayoutRect: TRect): TRect; override;
    procedure AddLabel(const ACoord: TPointF; AText: string; AHorizAlign: TAlignment; AVertAlign: TTextLayout);
    procedure AddLabel(APointIndex: integer; AText: string; AHorizAlign: TAlignment; AVertAlign: TTextLayout);
    procedure MouseMove(Shift: TShiftState; ViewX, ViewY: single; out ACursor: TOriginalEditorCursor; out AHandled: boolean); override;
    procedure MouseDown(RightButton: boolean; Shift: TShiftState; ViewX, ViewY: single; out ACursor: TOriginalEditorCursor; out AHandled: boolean); override;
    procedure MouseUp(RightButton: boolean; {%H-}Shift: TShiftState; {%H-}ViewX, {%H-}ViewY: single; out ACursor: TOriginalEditorCursor; out AHandled: boolean); override;
    procedure KeyDown(Shift: TShiftState; Key: TSpecialKey; out AHandled: boolean); override;
    procedure KeyUp(Shift: TShiftState; Key: TSpecialKey; out AHandled: boolean); override;
    procedure KeyPress(UTF8Key: string; out AHandled: boolean); override;
  end;

procedure RegisterVectorShape(AClass: TVectorShapeAny);
function GetVectorShapeByStorageClassName(AName: string): TVectorShapeAny;

implementation

uses math, BGRATransform, BGRAFillInfo, BGRAGraphics, BGRAPath, Types,
  BGRAText, BGRATextFX;

var
  VectorShapeClasses: array of TVectorShapeAny;

function GetVectorShapeByStorageClassName(AName: string): TVectorShapeAny;
var
  i: Integer;
begin
  for i := 0 to high(VectorShapeClasses) do
    if VectorShapeClasses[i].StorageClassName = AName then exit(VectorShapeClasses[i]);
  exit(nil);
end;

procedure RegisterVectorShape(AClass: TVectorShapeAny);
var
  i: Integer;
begin
  for i := 0 to high(VectorShapeClasses) do
    if VectorShapeClasses[i]=AClass then exit;
  if Assigned(GetVectorShapeByStorageClassName(AClass.StorageClassName)) then
    raise exception.Create('Duplicate class name "'+AClass.StorageClassName+'" for vector shape');
  setlength(VectorShapeClasses, length(VectorShapeClasses)+1);
  VectorShapeClasses[high(VectorShapeClasses)] := AClass;
end;

{ TVectorOriginalEditor }

constructor TVectorOriginalEditor.Create(AOriginal: TVectorOriginal);
begin
  inherited Create;
  FOriginal := AOriginal;
end;

procedure TVectorOriginalEditor.Clear;
begin
  inherited Clear;
  FLabels:= nil;
end;

function TVectorOriginalEditor.Render(ADest: TBGRABitmap;
  const ALayoutRect: TRect): TRect;
var
  i: Integer;
  ptF: TPointF;
  r: Classes.TRect;
begin
  Result:=inherited Render(ADest, ALayoutRect);
  for i := 0 to high(FLabels) do
    if not isEmptyPointF(FLabels[i].Coord) then
    begin
      ptF := OriginalCoordToView(FLabels[i].Coord);
      r := NiceText(ADest, round(ptF.x),round(ptF.y), ALayoutRect, FLabels[i].Text, FLabels[i].HorizAlign, FLabels[i].VertAlign, FLabels[i].Padding);
      if not IsRectEmpty(r) then
      begin
        if IsRectEmpty(result) then result:= r
        else UnionRect(result, result, r);
      end;
    end;
end;

function TVectorOriginalEditor.GetRenderBounds(const ALayoutRect: TRect): TRect;
var
  i: Integer;
  ptF: TPointF;
  r: Classes.TRect;
begin
  Result:=inherited GetRenderBounds(ALayoutRect);
  for i := 0 to high(FLabels) do
    if not isEmptyPointF(FLabels[i].Coord) then
    begin
      ptF := OriginalCoordToView(FLabels[i].Coord);
      r := NiceText(nil, round(ptF.x),round(ptF.y), ALayoutRect, FLabels[i].Text, FLabels[i].HorizAlign, FLabels[i].VertAlign, FLabels[i].Padding);
      if not IsRectEmpty(r) then
      begin
        if IsRectEmpty(result) then result:= r
        else UnionRect(result, result, r);
      end;
    end;
end;

procedure TVectorOriginalEditor.AddLabel(const ACoord: TPointF; AText: string;
  AHorizAlign: TAlignment; AVertAlign: TTextLayout);
begin
  setlength(FLabels, length(FLabels)+1);
  with FLabels[high(FLabels)] do
  begin
    Coord := ACoord;
    Text:= AText;
    HorizAlign:= AHorizAlign;
    VertAlign:= AVertAlign;
    Padding := 0;
  end;
end;

procedure TVectorOriginalEditor.AddLabel(APointIndex: integer; AText: string;
  AHorizAlign: TAlignment; AVertAlign: TTextLayout);
begin
  setlength(FLabels, length(FLabels)+1);
  with FLabels[high(FLabels)] do
  begin
    Coord := PointCoord[APointIndex];
    Text:= AText;
    HorizAlign:= AHorizAlign;
    VertAlign:= AVertAlign;
    Padding := round(PointSize);
  end;
end;

function TVectorOriginalEditor.NiceText(ADest: TBGRABitmap; x, y: integer;
      const ALayoutRect: TRect; AText: string; AHorizAlign: TAlignment;
      AVertAlign: TTextLayout; APadding: integer): TRect;
var fx: TBGRATextEffect;
    f: TFont;
    previousClip: TRect;
    shadowRadius: integer;
begin
  f := TFont.Create;
  f.Name := 'default';
  f.Height := round(PointSize*2.5);
  fx := TBGRATextEffect.Create(AText,f,true);

  if (AVertAlign = tlTop) and (AHorizAlign = taCenter) and (y+APadding+fx.TextSize.cy > ALayoutRect.Bottom) then AVertAlign:= tlBottom;
  if (AVertAlign = tlBottom) and (AHorizAlign = taCenter) and (y-APadding-fx.TextSize.cy < ALayoutRect.Top) then AVertAlign:= tlTop;
  if (AHorizAlign = taLeftJustify) and (AVertAlign = tlCenter) and (x+APadding+fx.TextSize.cx > ALayoutRect.Right) then AHorizAlign:= taRightJustify;
  if (AHorizAlign = taRightJustify) and (AVertAlign = tlCenter) and (x-APadding-fx.TextSize.cx < ALayoutRect.Left) then AHorizAlign:= taLeftJustify;

  if AVertAlign = tlBottom then y := y-APadding-fx.TextSize.cy else
  if AVertAlign = tlCenter then y := y-fx.TextSize.cy div 2 else inc(y,APadding);
  if y+fx.TextSize.cy > ALayoutRect.Bottom then y := ALayoutRect.Bottom-fx.TextSize.cy;
  if y < ALayoutRect.Top then y := ALayoutRect.Top;

  if AHorizAlign = taRightJustify then x := x-APadding-fx.TextSize.cx else
  if AHorizAlign = taCenter then x := x-fx.TextSize.cx div 2 else inc(x,APadding);
  if x+fx.TextSize.cx > ALayoutRect.Right then x := ALayoutRect.Right-fx.TextSize.cx;
  if x < ALayoutRect.Left then x := ALayoutRect.Left;

  shadowRadius:= round(PointSize*0.5);
  result := rect(x,y,x+fx.TextWidth+2*shadowRadius,y+fx.TextHeight+2*shadowRadius);
  if Assigned(ADest) then
  begin
    previousClip := ADest.ClipRect;
    ADest.ClipRect := result;
    if shadowRadius <> 0 then
      fx.DrawShadow(ADest,x+shadowRadius,y+shadowRadius,shadowRadius,BGRABlack);
    fx.DrawOutline(ADest,x,y,BGRABlack);
    fx.Draw(ADest,x,y,BGRAWhite);
    ADest.ClipRect := previousClip;
  end;
  fx.Free;
  f.Free;
end;

procedure TVectorOriginalEditor.MouseMove(Shift: TShiftState; ViewX, ViewY: single; out
  ACursor: TOriginalEditorCursor; out AHandled: boolean);
var
  ptF: TPointF;
begin
  inherited MouseMove(Shift, ViewX, ViewY, ACursor, AHandled);
  if not AHandled and Assigned(FOriginal.SelectedShape) then
  begin
    ptF := ViewCoordToOriginal(PointF(ViewX,ViewY));
    if GridActive then ptF := SnapToGrid(ptF, False);
    with ptF do FOriginal.SelectedShape.MouseMove(Shift, X,Y, ACursor, AHandled);
  end;
end;

procedure TVectorOriginalEditor.MouseDown(RightButton: boolean;
  Shift: TShiftState; ViewX, ViewY: single; out ACursor: TOriginalEditorCursor; out
  AHandled: boolean);
var
  ptF: TPointF;
begin
  inherited MouseDown(RightButton, Shift, ViewX, ViewY, ACursor, AHandled);
  if not AHandled and Assigned(FOriginal.SelectedShape) then
  begin
    ptF := ViewCoordToOriginal(PointF(ViewX,ViewY));
    if GridActive then ptF := SnapToGrid(ptF, False);
    with ptF do FOriginal.SelectedShape.MouseDown(RightButton, Shift, X,Y, ACursor, AHandled);
  end;
end;

procedure TVectorOriginalEditor.MouseUp(RightButton: boolean;
  Shift: TShiftState; ViewX, ViewY: single; out ACursor: TOriginalEditorCursor; out
  AHandled: boolean);
var
  ptF: TPointF;
begin
  inherited MouseUp(RightButton, Shift, ViewX, ViewY, ACursor, AHandled);
  if not AHandled and Assigned(FOriginal.SelectedShape) then
  begin
    ptF := ViewCoordToOriginal(PointF(ViewX,ViewY));
    if GridActive then ptF := SnapToGrid(ptF, False);
    with ptF do FOriginal.SelectedShape.MouseUp(RightButton, Shift, X,Y, ACursor, AHandled);
  end;
end;

procedure TVectorOriginalEditor.KeyDown(Shift: TShiftState; Key: TSpecialKey; out
  AHandled: boolean);
begin
  if Assigned(FOriginal.SelectedShape) then
  begin
    if (Key = skReturn) and ([ssShift,ssCtrl,ssAlt]*Shift = []) then
    begin
      FOriginal.DeselectShape;
      AHandled := true;
      exit;
    end else
    if (Key = skEscape) and ([ssShift,ssCtrl,ssAlt]*Shift = []) and (FOriginal.SelectedShape.Usermode = vsuCreate) then
    begin
     FOriginal.SelectedShape.Remove;
     AHandled:= true;
    end else
    begin
      AHandled := false;
      FOriginal.SelectedShape.KeyDown(Shift, Key, AHandled);
      if AHandled then exit;
    end;
  end;

  inherited KeyDown(Shift, Key, AHandled);
end;

procedure TVectorOriginalEditor.KeyUp(Shift: TShiftState; Key: TSpecialKey; out
  AHandled: boolean);
begin
  if Assigned(FOriginal.SelectedShape) then
  begin
    AHandled := false;
    FOriginal.SelectedShape.KeyUp(Shift, Key, AHandled);
    if AHandled then exit;
  end;

  inherited KeyUp(Shift, Key, AHandled);
end;

procedure TVectorOriginalEditor.KeyPress(UTF8Key: string; out
  AHandled: boolean);
begin
  if Assigned(FOriginal.SelectedShape) then
  begin
    AHandled := false;
    FOriginal.SelectedShape.KeyPress(UTF8Key, AHandled);
    if AHandled then exit;
  end;

  inherited KeyPress(UTF8Key, AHandled);
end;

{ TVectorShape }

function TVectorShape.GetIsSlow(AMatrix: TAffineMatrix): boolean;
begin
  result := false;
end;

class function TVectorShape.Fields: TVectorShapeFields;
begin
  result := [];
end;

function TVectorShape.GetJoinStyle: TPenJoinStyle;
begin
  result := Stroker.JoinStyle;
end;

procedure TVectorShape.SetJoinStyle(AValue: TPenJoinStyle);
begin
  BeginUpdate;
  Stroker.JoinStyle := AValue;
  EndUpdate;
end;

procedure TVectorShape.SetUsermode(AValue: TVectorShapeUsermode);
begin
  if FUsermode=AValue then Exit;
  FUsermode:=AValue;
  if Assigned(FOnEditingChange) then FOnEditingChange(self);
end;

procedure TVectorShape.LoadFill(AStorage: TBGRACustomOriginalStorage;
  AObjectName: string; var AValue: TVectorialFill);
var
  obj: TBGRACustomOriginalStorage;
  texId, texOpacity: integer;
  origin, xAxis, yAxis: TPointF;
  grad: TBGRALayerGradientOriginal;
  repetition: TTextureRepetition;
begin
  if AValue = nil then
  begin
    AValue := TVectorialFill.Create;
    AValue.OnChange := @FillChange;
  end;

  obj := AStorage.OpenObject(AObjectName+'-fill');
  if obj = nil then
  begin
    AValue.SetSolid(AStorage.Color[AObjectName+'-color']);
    exit;
  end;
  try
     case obj.RawString['class'] of
       'solid': AValue.SetSolid(obj.Color['color']);
       'texture': begin
           texId:= obj.Int['tex-id'];
           origin := obj.PointF['origin'];
           xAxis := obj.PointF['x-axis'];
           yAxis := obj.PointF['y-axis'];
           texOpacity := obj.IntDef['opacity',255];
           if texOpacity < 0 then texOpacity:= 0;
           if texOpacity > 255 then texOpacity:= 255;
           case obj.RawString['repetition'] of
             'none': repetition := trNone;
             'repeat-x': repetition := trRepeatX;
             'repeat-y': repetition := trRepeatY;
             else repetition := trRepeatBoth;
           end;
           if Assigned(Container) then
             AValue.SetTexture(Container.GetTexture(texId), AffineMatrix(xAxis,yAxis,origin), texOpacity, repetition)
           else
             AValue.Clear;
         end;
       'gradient': begin
           grad := TBGRALayerGradientOriginal.Create;
           grad.LoadFromStorage(obj);
           AValue.SetGradient(grad,true);
         end;
       else AValue.Clear;
     end;
  finally
    obj.Free;
  end;
end;

procedure TVectorShape.SaveFill(AStorage: TBGRACustomOriginalStorage;
  AObjectName: string; AValue: TVectorialFill);
var
  obj: TBGRACustomOriginalStorage;
  m: TAffineMatrix;
begin
  AStorage.RemoveObject(AObjectName+'-fill');
  AStorage.RemoveObject(AObjectName+'-color');
  if Assigned(AValue) then
  begin
    if AValue.IsSolid then
    begin
      AStorage.Color[AObjectName+'-color'] := AValue.SolidColor;
      exit;
    end else
    if not AValue.IsTexture and not AValue.IsGradient then exit;

    obj := AStorage.CreateObject(AObjectName+'-fill');
    try
      if AValue.IsSolid then
      begin
        obj.RawString['class'] := 'solid';
        obj.Color['color'] := AValue.SolidColor;
      end
      else
      if AValue.IsTexture then
      begin
        obj.RawString['class'] := 'texture';
        obj.Int['tex-id'] := Container.GetTextureId(AValue.Texture);
        m := AValue.TextureMatrix;
        obj.PointF['origin'] := PointF(m[1,3],m[2,3]);
        obj.PointF['x-axis'] := PointF(m[1,1],m[2,1]);
        obj.PointF['y-axis'] := PointF(m[1,2],m[2,2]);
        if AValue.TextureOpacity<>255 then
          obj.Int['opacity'] := AValue.TextureOpacity;
        case AValue.TextureRepetition of
          trNone: obj.RawString['repetition'] := 'none';
          trRepeatX: obj.RawString['repetition'] := 'repeat-x';
          trRepeatY: obj.RawString['repetition'] := 'repeat-y';
          trRepeatBoth: obj.RemoveAttribute('repetition');
        end;
      end else
      if AValue.IsGradient then
      begin
        obj.RawString['class'] := 'gradient';
        AValue.Gradient.SaveToStorage(obj);
      end else
        obj.RawString['class'] := 'none';
    finally
      obj.Free;
    end;
  end;
end;

class function TVectorShape.Usermodes: TVectorShapeUsermodes;
begin
  result := [vsuEdit];
  if vsfBackFill in Fields then result += [vsuEditBackFill];
end;

procedure TVectorShape.SetContainer(AValue: TVectorOriginal);
begin
  if FContainer=AValue then Exit;
  if Assigned(FContainer) then raise exception.Create('Container already assigned');
  FContainer:=AValue;
end;

function TVectorShape.GetIsBack: boolean;
begin
  result := Assigned(Container) and (Container.IndexOfShape(self)=0);
end;

function TVectorShape.GetIsFront: boolean;
begin
  result := Assigned(Container) and (Container.IndexOfShape(self)=Container.ShapeCount-1);
end;

procedure TVectorShape.BeginUpdate;
begin
  if FUpdateCount = 0 then
    FBoundsBeforeUpdate := GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
  FUpdateCount += 1;
end;

procedure TVectorShape.EndUpdate;
var
  boundsAfter: TRectF;
begin
  if FUpdateCount > 0 then
  begin
    FUpdateCount -= 1;
    if FUpdateCount = 0 then
    begin
      if Assigned(FOnChange) then
      begin
        boundsAfter := GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
        FOnChange(self, boundsAfter.Union(FBoundsBeforeUpdate, true));
      end;
    end;
  end;
end;

function TVectorShape.GetPenColor: TBGRAPixel;
begin
  result := FPenColor;
end;

function TVectorShape.GetPenWidth: single;
begin
  result := FPenWidth;
end;

function TVectorShape.GetPenStyle: TBGRAPenStyle;
begin
  result := Stroker.CustomPenStyle;
end;

function TVectorShape.GetBackFill: TVectorialFill;
begin
  if FBackFill = nil then
  begin
    FBackFill := TVectorialFill.Create;
    FBackFill.OnChange := @FillChange;
  end;
  result := FBackFill;
end;

function TVectorShape.ComputeStroke(APoints: ArrayOfTPointF; AClosed: boolean; AStrokeMatrix: TAffineMatrix): ArrayOfTPointF;
begin
  Stroker.StrokeMatrix := AStrokeMatrix;
  if AClosed then
    result := Stroker.ComputePolygon(APoints, PenWidth)
  else
    result := Stroker.ComputePolyline(APoints, PenWidth, PenColor);
end;

function TVectorShape.GetStroker: TBGRAPenStroker;
begin
  if FStroker = nil then
  begin
    FStroker := TBGRAPenStroker.Create;
    FStroker.MiterLimit:= sqrt(2);
  end;
  result := FStroker;
end;

procedure TVectorShape.FillChange(ASender: TObject);
begin
  if Assigned(FOnChange) and (FUpdateCount = 0) then
    FOnChange(self, GetRenderBounds(InfiniteRect, AffineMatrixIdentity));
end;

procedure TVectorShape.SetPenColor(AValue: TBGRAPixel);
begin
  if AValue.alpha = 0 then AValue := BGRAPixelTransparent;
  if FPenColor = AValue then exit;
  BeginUpdate;
  FPenColor := AValue;
  EndUpdate;
end;

procedure TVectorShape.SetPenWidth(AValue: single);
begin
  if AValue < 0 then AValue := 0;
  if FPenWidth = AValue then exit;
  BeginUpdate;
  FPenWidth := AValue;
  EndUpdate;
end;

procedure TVectorShape.SetPenStyle(AValue: TBGRAPenStyle);
begin
  BeginUpdate;
  Stroker.CustomPenStyle := AValue;
  EndUpdate;
end;

procedure TVectorShape.SetBackFill(AValue: TVectorialFill);
var
  sharedTex: TBGRABitmap;
  freeTex: Boolean;
begin
  if FBackFill.Equals(AValue) then exit;
  BeginUpdate;
  freeTex := Assigned(FBackFill) and Assigned(FBackFill.Texture) and
    not (Assigned(AValue) and AValue.IsTexture and (AValue.Texture = FBackFill.Texture));
  if AValue = nil then FreeAndNil(FBackFill) else
  if AValue.IsTexture then
  begin
    if Assigned(Container) then
      sharedTex := Container.GetTexture(Container.AddTexture(AValue.Texture))
    else
      sharedTex := AValue.Texture;
    BackFill.SetTexture(sharedTex, AValue.TextureMatrix, AValue.TextureOpacity, AValue.TextureRepetition);
  end else
    BackFill.Assign(AValue);
  if Assigned(Container) and freeTex then Container.DiscardUnusedTextures;
  EndUpdate;
end;

constructor TVectorShape.Create(AContainer: TVectorOriginal);
begin
  FContainer := AContainer;
  FPenColor := BGRAPixelTransparent;
  FPenWidth := 1;
  FStroker := nil;
  FOnChange := nil;
  FOnEditingChange := nil;
  FBackFill := nil;
  FUsermode:= vsuEdit;
  FRemoving:= false;
end;

destructor TVectorShape.Destroy;
begin
  FreeAndNil(FStroker);
  FreeAndNil(FBackFill);
  inherited Destroy;
end;

procedure TVectorShape.LoadFromStorage(AStorage: TBGRACustomOriginalStorage);
var
  f: TVectorShapeFields;
begin
  f := Fields;
  if f <> [] then
  begin
    BeginUpdate;
    if vsfPenColor in f then PenColor := AStorage.Color['pen-color'];
    if vsfPenWidth in f then PenWidth := AStorage.FloatDef['pen-width', 0];
    if vsfPenStyle in f then PenStyle := AStorage.FloatArray['pen-style'];
    if vsfJoinStyle in f then
      case AStorage.RawString['join-style'] of
      'round': JoinStyle := pjsRound;
      'bevel': JoinStyle := pjsBevel;
      else JoinStyle := pjsMiter;
      end;
    if vsfBackFill in f then LoadFill(AStorage, 'back', FBackFill);
    EndUpdate;
  end;
end;

procedure TVectorShape.SaveToStorage(AStorage: TBGRACustomOriginalStorage);
var
  f: TVectorShapeFields;
begin
  f := Fields;
  if vsfPenColor in f then AStorage.Color['pen-color'] := PenColor;
  if vsfPenWidth in f then AStorage.Float['pen-width'] := PenWidth;
  if vsfPenStyle in f then AStorage.FloatArray['pen-style'] := PenStyle;
  if vsfJoinStyle in f then
    case JoinStyle of
    pjsRound: AStorage.RawString['join-style'] := 'round';
    pjsBevel: AStorage.RawString['join-style'] := 'bevel';
    else AStorage.RawString['join-style'] := 'miter';
    end;
  if vsfBackFill in f then SaveFill(AStorage, 'back', FBackFill);
end;

procedure TVectorShape.MouseMove(Shift: TShiftState; X, Y: single; var
  ACursor: TOriginalEditorCursor; var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.MouseDown(RightButton: boolean; Shift: TShiftState; X,
  Y: single; var ACursor: TOriginalEditorCursor; var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.MouseUp(RightButton: boolean; Shift: TShiftState; X,
  Y: single; var ACursor: TOriginalEditorCursor; var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.KeyDown(Shift: TShiftState; Key: TSpecialKey;
  var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.KeyUp(Shift: TShiftState; Key: TSpecialKey;
  var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.KeyPress(UTF8Key: string; var AHandled: boolean);
begin
  //nothing
end;

procedure TVectorShape.BringToFront;
begin
  if Assigned(Container) then
    Container.MoveShapeToIndex(Container.IndexOfShape(self),Container.ShapeCount-1);
end;

procedure TVectorShape.SendToBack;
begin
  if Assigned(Container) then
    Container.MoveShapeToIndex(Container.IndexOfShape(self),0);
end;

procedure TVectorShape.MoveUp(APassNonIntersectingShapes: boolean);
var
  movedShapeBounds, otherShapeBounds: TRectF;
  sourceIdx,idx: integer;
begin
  if not Assigned(Container) then exit;
  sourceIdx := Container.IndexOfShape(self);
  if sourceIdx = Container.ShapeCount-1 then exit;
  idx := sourceIdx;
  if APassNonIntersectingShapes then
  begin
    movedShapeBounds := self.GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
    while idx < Container.ShapeCount-2 do
    begin
      otherShapeBounds := Container.Shape[idx+1].GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
      if movedShapeBounds.IntersectsWith(otherShapeBounds) then break;
      inc(idx);
    end;
  end;
  inc(idx);
  Container.MoveShapeToIndex(sourceIdx, idx);
end;

procedure TVectorShape.MoveDown(APassNonIntersectingShapes: boolean);
var
  movedShapeBounds, otherShapeBounds: TRectF;
  sourceIdx,idx: integer;
begin
  if not Assigned(Container) then exit;
  sourceIdx := Container.IndexOfShape(self);
  if sourceIdx = 0 then exit;
  idx := sourceIdx;
  if APassNonIntersectingShapes then
  begin
    movedShapeBounds := self.GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
    while idx > 1 do
    begin
      otherShapeBounds := Container.Shape[idx-1].GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
      if movedShapeBounds.IntersectsWith(otherShapeBounds) then break;
      dec(idx);
    end;
  end;
  dec(idx);
  Container.MoveShapeToIndex(sourceIdx, idx);
end;

procedure TVectorShape.Remove;
begin
  if Assigned(Container) then Container.RemoveShape(self)
  else raise exception.Create('Shape does not have a container');
end;

function TVectorShape.Duplicate: TVectorShape;
var temp: TBGRAMemOriginalStorage;
  shapeClass: TVectorShapeAny;
begin
  shapeClass:= GetVectorShapeByStorageClassName(StorageClassName);
  if shapeClass = nil then raise exception.Create('Shape class "'+StorageClassName+'" not registered');

  temp := TBGRAMemOriginalStorage.Create;
  SaveToStorage(temp);
  result := shapeClass.Create(Container);
  result.LoadFromStorage(temp);
  temp.Free;
  result.FContainer := nil;
end;

{ TVectorOriginal }

function TVectorOriginal.GetShapeCount: integer;
begin
  result := FShapes.Count;
end;

function TVectorOriginal.GetShape(AIndex: integer): TVectorShape;
begin
  result := FShapes[AIndex];
end;

procedure TVectorOriginal.FreeDeletedShapes;
var
  i: Integer;
begin
  for i := 0 to FDeletedShapes.Count-1 do
    FDeletedShapes[i].Free;
  FDeletedShapes.Clear
end;

procedure TVectorOriginal.OnShapeChange(ASender: TObject; ABounds: TRectF);
begin
  if ASender <> FSelectedShape then DiscardFrozenShapes;
  NotifyChange(ABounds);
end;

procedure TVectorOriginal.OnShapeEditingChange(ASender: TObject);
begin
  if ASender = FSelectedShape then
    NotifyEditorChange;
end;

procedure TVectorOriginal.DiscardFrozenShapes;
begin
  FFrozenShapesComputed:= false;
  FreeAndNil(FFrozenShapesUnderSelection);
  FreeAndNil(FFrozenShapesOverSelection);
end;

function TVectorOriginal.GetTextureId(ABitmap: TBGRABitmap): integer;
var
  i: Integer;
begin
  if (ABitmap = nil) or (ABitmap.NbPixels = 0) then exit(EmptyTextureId);
  for i := 0 to FTextureCount-1 do
    if FTextures[i].Bitmap = ABitmap then exit(FTextures[i].Id);
  for i := 0 to FTextureCount-1 do
    if FTextures[i].Bitmap.Equals(ABitmap) then exit(FTextures[i].Id);
  exit(-1);
end;

function TVectorOriginal.IndexOfTexture(AId: integer): integer;
var
  i: Integer;
begin
  if AId = EmptyTextureId then exit(-1);
  for i := 0 to FTextureCount-1 do
    if FTextures[i].Id = AId then exit(i);
  exit(-1);
end;

procedure TVectorOriginal.AddTextureWithId(ATexture: TBGRABitmap; AId: integer);
begin
  if FTextureCount >= length(FTextures) then
    setlength(FTextures, FTextureCount*2+2);
  if AId > FLastTextureId then FLastTextureId:= AId;
  FTextures[FTextureCount].Bitmap := ATexture.NewReference as TBGRABitmap;
  FTextures[FTextureCount].Id := AId;
  inc(FTextureCount);
end;

procedure TVectorOriginal.ClearTextures;
var
  i: Integer;
begin
  if Assigned(FShapes) and (FShapes.Count > 0) then
    raise exception.Create('There are still shapes that could use textures');
  for i := 0 to FTextureCount-1 do
  begin
    FTextures[i].Bitmap.FreeReference;
    FTextures[i].Bitmap := nil;
  end;
  FTextureCount := 0;
  FTextures := nil;
  FLastTextureId:= EmptyTextureId;
end;

constructor TVectorOriginal.Create;
begin
  inherited Create;
  FShapes := TVectorShapes.Create;
  FDeletedShapes := TVectorShapes.Create;
  FSelectedShape := nil;
  FFrozenShapesUnderSelection := nil;
  FFrozenShapesOverSelection := nil;
  FFrozenShapesComputed:= false;
  FLastTextureId:= EmptyTextureId;
end;

destructor TVectorOriginal.Destroy;
var
  i: Integer;
begin
  FSelectedShape := nil;
  for i := 0 to FShapes.Count-1 do
    FShapes[i].Free;
  FreeAndNil(FShapes);
  FreeDeletedShapes;
  FreeAndNil(FDeletedShapes);
  FreeAndNil(FFrozenShapesUnderSelection);
  FreeAndNil(FFrozenShapesOverSelection);
  ClearTextures;
  inherited Destroy;
end;

procedure TVectorOriginal.Clear;
var
  i: Integer;
begin
  if FShapes.Count > 0 then
  begin
    FSelectedShape := nil;
    for i := 0 to FShapes.Count-1 do
      FDeletedShapes.Add(FShapes[i]);
    FShapes.Clear;
    ClearTextures;
    NotifyChange;
  end;
end;

function TVectorOriginal.AddTexture(ATexture: TBGRABitmap): integer;
begin
  result := GetTextureId(ATexture);
  if result <> -1 then exit;
  result:= FLastTextureId+1;
  AddTextureWithId(ATexture, result);
end;

function TVectorOriginal.GetTexture(AId: integer): TBGRABitmap;
var
  index: Integer;
begin
  index := IndexOfTexture(AId);
  if index = -1 then
    result := nil
  else
    result := FTextures[index].Bitmap;
end;

procedure TVectorOriginal.DiscardUnusedTextures;
var
  i, j: Integer;
  f: TVectorShapeFields;
  tex: TBGRABitmap;
begin
  for i := 0 to FTextureCount-1 do
    FTextures[i].Counter:= 0;
  for i := 0 to FShapes.Count-1 do
  begin
    f:= FShapes[i].Fields;
    if (vsfBackFill in f) and FShapes[i].BackFill.IsTexture then
    begin
      tex := FShapes[i].BackFill.Texture;
      inc(FTextures[IndexOfTexture(GetTextureId(tex))].Counter);
    end;
  end;
  for i := FTextureCount-1 downto 0 do
    if FTextures[i].Counter = 0 then
    begin
      FTextures[i].Bitmap.FreeReference;
      FTextures[i].Bitmap := nil;
      for j := i to FTextureCount-2 do
        FTextures[j] := FTextures[j+1];
      dec(FTextureCount);
    end;
  if FTextureCount < length(FTextures) div 2 then
    setlength(FTextures, FTextureCount);
end;

function TVectorOriginal.AddShape(AShape: TVectorShape): integer;
begin
  if AShape.Container <> self then
  begin
    if AShape.Container = nil then
      AShape.Container := self
    else
      raise exception.Create('Container mismatch');
  end;
  result:= FShapes.Add(AShape);
  if (vsfBackFill in AShape.Fields) and AShape.BackFill.IsTexture then AddTexture(AShape.BackFill.Texture);
  AShape.OnChange := @OnShapeChange;
  AShape.OnEditingChange := @OnShapeEditingChange;
  DiscardFrozenShapes;
  NotifyChange(AShape.GetRenderBounds(InfiniteRect, AffineMatrixIdentity));
end;

function TVectorOriginal.AddShape(AShape: TVectorShape;
  AUsermode: TVectorShapeUsermode): integer;
begin
  result := AddShape(AShape);
  AShape.Usermode:= AUsermode;
  SelectShape(result);
end;

function TVectorOriginal.RemoveShape(AShape: TVectorShape): boolean;
var
  idx: LongInt;
  r: TRectF;
begin
  if AShape.FRemoving then exit;
  idx := FShapes.IndexOf(AShape);
  if idx = -1 then exit(false);
  AShape.FRemoving := true;
  if AShape = SelectedShape then DeselectShape;
  AShape.OnChange := nil;
  AShape.OnEditingChange := nil;
  r := AShape.GetRenderBounds(InfiniteRect, AffineMatrixIdentity);
  FShapes.Delete(idx);
  FDeletedShapes.Add(AShape);
  DiscardFrozenShapes;
  NotifyChange(r);
  AShape.FRemoving := false;
end;

procedure TVectorOriginal.SelectShape(AIndex: integer);
begin
  if (AIndex < 0) or (AIndex >= FShapes.Count) then
    raise ERangeError.Create('Index out of bounds');
  SelectShape(FShapes[AIndex]);
end;

procedure TVectorOriginal.SelectShape(AShape: TVectorShape);
var
  prev: TVectorShape;
  prevMode: TVectorShapeUsermode;
begin
  if FSelectedShape <> AShape then
  begin
    if AShape <> nil then
      if FShapes.IndexOf(AShape)=-1 then
        raise exception.Create('Shape not found');
    prev := FSelectedShape;
    FSelectedShape := nil;
    if Assigned(prev) then
    begin
      prevMode := prev.Usermode;
      prev.Usermode := vsuEdit;
    end else
      prevMode := vsuEdit;
    if Assigned(AShape) and (prevMode = vsuEditBackFill) and (prevMode in AShape.Usermodes) and
       AShape.BackFill.IsGradient then AShape.Usermode:= prevMode;
    FSelectedShape := AShape;
    DiscardFrozenShapes;
    NotifyEditorChange;
    if Assigned(FOnSelectShape) then
      FOnSelectShape(self, FSelectedShape, prev);
  end;
end;

procedure TVectorOriginal.DeselectShape;
begin
  SelectShape(nil);
end;

procedure TVectorOriginal.MouseClick(APoint: TPointF);
var
  i: LongInt;
begin
  for i:= FShapes.Count-1 downto 0 do
    if FShapes[i].PointInShape(APoint) then
    begin
      SelectShape(i);
      exit;
    end;
  DeselectShape;
end;

procedure TVectorOriginal.Render(ADest: TBGRABitmap; AMatrix: TAffineMatrix;
  ADraft: boolean);
var
  i: Integer;
  idxSelected: LongInt;
begin
  if AMatrix <> FFrozenShapeMatrix then DiscardFrozenShapes;
  idxSelected := FShapes.IndexOf(FSelectedShape);
  if idxSelected = -1 then
  begin
    FSelectedShape := nil;
    DiscardFrozenShapes;
  end;
  if FFrozenShapesComputed then
  begin
    ADest.PutImage(0,0,FFrozenShapesUnderSelection, dmSet);
    FSelectedShape.Render(ADest, AMatrix, ADraft);
    ADest.PutImage(0,0,FFrozenShapesOverSelection, dmDrawWithTransparency);
  end else
  begin
    if idxSelected <> -1 then
    begin
      if idxSelected > 0 then
      begin
        FreeAndNil(FFrozenShapesUnderSelection);
        FFrozenShapesUnderSelection := TBGRABitmap.Create(ADest.Width,ADest.Height);
        for i:= 0 to idxSelected-1 do
          FShapes[i].Render(FFrozenShapesUnderSelection, AMatrix, false);
        ADest.PutImage(0,0,FFrozenShapesUnderSelection, dmSet);
      end;
      FSelectedShape.Render(ADest, AMatrix, ADraft);
      if idxSelected < FShapes.Count-1 then
      begin
        FreeAndNil(FFrozenShapesOverSelection);
        FFrozenShapesOverSelection := TBGRABitmap.Create(ADest.Width,ADest.Height);
        for i:= idxSelected+1 to FShapes.Count-1 do
          FShapes[i].Render(FFrozenShapesOverSelection, AMatrix, false);
        ADest.PutImage(0,0,FFrozenShapesOverSelection, dmDrawWithTransparency);
      end;
      FFrozenShapesComputed := true;
      FFrozenShapeMatrix := AMatrix;
    end else
    begin
      for i:= 0 to FShapes.Count-1 do
        FShapes[i].Render(ADest, AMatrix, ADraft);
    end;
  end;
end;

procedure TVectorOriginal.ConfigureEditor(AEditor: TBGRAOriginalEditor);
begin
  inherited ConfigureEditor(AEditor);
  if Assigned(FSelectedShape) then
  begin
    if FShapes.IndexOf(FSelectedShape)=-1 then
    begin
      FSelectedShape := nil;
      DiscardFrozenShapes;
    end
    else
    begin
      if (FSelectedShape.Usermode = vsuEditBackFill) and
         (FSelectedShape.BackFill.IsGradient or FSelectedShape.BackFill.IsTexture) then
        FSelectedShape.BackFill.ConfigureEditor(AEditor)
      else
        FSelectedShape.ConfigureEditor(AEditor);
    end;
  end;
  //no more reference to event handlers
  FreeDeletedShapes;
end;

function TVectorOriginal.CreateEditor: TBGRAOriginalEditor;
begin
  Result:= TVectorOriginalEditor.Create(self);
end;

function TVectorOriginal.GetRenderBounds(ADestRect: TRect;
  AMatrix: TAffineMatrix): TRect;
var
  area, shapeArea: TRectF;
  i: Integer;
begin
  area:= EmptyRectF;
  for i:= 0 to FShapes.Count-1 do
  begin
    shapeArea := FShapes[i].GetRenderBounds(ADestRect, AMatrix);
    area := area.Union(shapeArea, true);
  end;

  if IsEmptyRectF(area) then
    result := EmptyRect
  else
    result := rect(floor(area.Left),floor(area.Top),ceil(area.Right),ceil(area.Bottom));
end;

procedure TVectorOriginal.LoadFromStorage(AStorage: TBGRACustomOriginalStorage);
var
  nb: LongInt;
  i: Integer;
  shapeObj, texObj: TBGRACustomOriginalStorage;
  objClassName, texName: String;
  shapeClass: TVectorShapeAny;
  loadedShape: TVectorShape;
  idList: array of single;
  mem: TMemoryStream;
  texId: integer;
  bmp: TBGRABitmap;
begin
  Clear;

  texObj := AStorage.OpenObject('textures');
  if Assigned(texObj) then
  begin
    try
      idList := texObj.FloatArray['id'];
      for i := 0 to high(idList) do
      begin
        texId:= round(idList[i]);
        texName:= 'tex'+inttostr(texId);
        mem := TMemoryStream.Create;
        try
          if not texObj.ReadFile(texName+'.png', mem) and
             not texObj.ReadFile(texName+'.jpg', mem) then
             raise exception.Create('Unable to find texture');
          mem.Position:= 0;
          bmp := TBGRABitmap.Create(mem);
          AddTextureWithId(bmp, texId);
          bmp.FreeReference;
        finally
          mem.Free;
        end;
      end;
    finally
      texObj.Free;
    end;
  end;

  nb := AStorage.Int['count'];
  for i:= 0 to nb-1 do
  begin
    shapeObj := AStorage.OpenObject('shape'+inttostr(i+1));
    if shapeObj <> nil then
    try
      objClassName := shapeObj.RawString['class'];
      if objClassName = '' then raise exception.Create('Shape class not defined');
      shapeClass:= GetVectorShapeByStorageClassName(objClassName);
      if shapeClass = nil then raise exception.Create('Unknown shape class "'+objClassName+'"');
      loadedShape := shapeClass.Create(self);
      loadedShape.LoadFromStorage(shapeObj);
      loadedShape.OnChange := @OnShapeChange;
      loadedShape.OnEditingChange := @OnShapeEditingChange;
      FShapes.Add(loadedShape);
    finally
      shapeObj.Free;
    end;
  end;
  NotifyChange;
end;

procedure TVectorOriginal.SaveToStorage(AStorage: TBGRACustomOriginalStorage);
var
  nb: LongInt;
  i, texIndex: Integer;
  shapeObj, texObj: TBGRACustomOriginalStorage;
  idList: array of single;
  texName: String;
  mem: TMemoryStream;
  texId: integer;
begin
  nb := AStorage.Int['count'];
  for i := 0 to nb-1 do AStorage.RemoveObject('shape'+inttostr(i+1));
  AStorage.Int['count'] := 0;

  for i := 0 to FShapes.Count-1 do
  begin
    shapeObj := AStorage.CreateObject('shape'+inttostr(i+1));
    shapeObj.RawString['class'] := FShapes[i].StorageClassName;
    try
      FShapes[i].SaveToStorage(shapeObj);
      AStorage.Int['count'] := i+1;
    finally
      shapeObj.Free;
    end;
  end;

  if FTextureCount = 0 then
    AStorage.RemoveObject('textures')
  else
  begin
    texObj := nil;
    try
      texObj := AStorage.OpenObject('textures');
      if texObj = nil then
        texObj := AStorage.CreateObject('textures');

      for i := 0 to FTextureCount-1 do
        FTextures[i].Counter:= 0;

      idList := texObj.FloatArray['id'];
      for i := 0 to high(idList) do
      begin
        texId := round(idList[i]);
        texIndex:= IndexOfTexture(texId);
        if texIndex=-1 then
        begin
          texName := 'tex'+inttostr(texId);
          texObj.RemoveFile(texName+'.png');
          texObj.RemoveFile(texName+'.jpg');
        end else
          inc(FTextures[texIndex].Counter);
      end;

      setlength(idList, FTextureCount);
      for i := 0 to FTextureCount-1 do
      begin
        if FTextures[i].Counter = 0 then
        begin
          texName := 'tex'+inttostr(FTextures[i].Id);
          mem := TMemoryStream.Create;
          try
            FTextures[i].Bitmap.SaveToStreamAsPng(mem);
            texObj.WriteFile(texName+'.png', mem, false);
          finally
            mem.Free;
          end;
        end;
        idList[i] := FTextures[i].Id;
      end;
      texObj.FloatArray['id'] := idList;
    finally
      texObj.Free;
    end;
  end;

end;

function TVectorOriginal.IndexOfShape(AShape: TVectorShape): integer;
begin
  result := FShapes.IndexOf(AShape);
end;

procedure TVectorOriginal.MoveShapeToIndex(AFromIndex: integer; AToIndex: integer);
var
  movedShape: TVectorShape;
begin
  if AFromIndex = AToIndex then exit;
  movedShape := FShapes[AFromIndex];
  FShapes.Move(AFromIndex,AToIndex);
  DiscardFrozenShapes;
  NotifyChange(movedShape.GetRenderBounds(InfiniteRect, AffineMatrixIdentity));
end;

class function TVectorOriginal.StorageClassName: RawByteString;
begin
  result := 'vector';
end;

initialization

  RegisterLayerOriginal(TVectorOriginal);

end.


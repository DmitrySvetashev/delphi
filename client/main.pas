unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  Vcl.ExtCtrls, Vcl.StdCtrls, IdIPWatch, Vcl.ComCtrls, Jpeg, IdAntiFreezeBase, IniFiles,
  acImage;

type
  TClient_MainForm = class(TForm)
    IdTCPClient: TIdTCPClient;
    IdIPWatch: TIdIPWatch;
    SendTimer: TTimer;
    StatusBar: TStatusBar;
    Image1: TImage;
    procedure FormShow(Sender: TObject);
    procedure ClientIdent(Sender: TObject);
    procedure ServerReg(Sender: TObject);
    procedure ReadParams(Sender : TObject);
    procedure ScreenShot(Sender : TObject);
    procedure SendTimerTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

type
  TCli_info = record
                ID : Byte;
                IP, NAME : String[255];
                UPTIME, PIC_Q, FPS : Byte;
                PIC_W, PIC_H : UInt16;
              end;

var
  Client_MainForm: TClient_MainForm;
  Server_Port_Cmd, Server_Port_Img : Uint64;
  Client_Status, Server_Host : String;
  Serv_Conn : Boolean;
  Client : TCli_info;

implementation

{$R *.dfm}

procedure TClient_MainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  Client_params_file : Tinifile;
begin
  SendTimer.Enabled := False;
  Client_params_file := TiniFile.Create(ExtractFilePath(ParamStr(0))+'client.ini');
  Client_params_file.WriteString('�����������','��� �����',Server_Host);
  Client_params_file.WriteInteger('�����������','���� ��� ������',Server_Port_Cmd);
  Client_params_file.WriteInteger('�����������','���� ��� ��������',Server_Port_Img);
  Client_params_file.Free;
end;

procedure TClient_MainForm.FormCreate(Sender: TObject);
var
  Client_params_file : Tinifile;
begin
  SendTimer.Enabled := False;
  Client_params_file := TiniFile.Create(ExtractFilePath(ParamStr(0))+'client.ini');
  Server_Host := Client_params_file.ReadString('�����������','��� �����','127.0.0.1');
  Server_Port_Cmd := Client_params_file.ReadInteger('�����������','���� ��� ������',6000);
  Server_Port_Img := Client_params_file.ReadInteger('�����������','���� ��� ��������',6001);
  Client_params_file.Free;
  Client.ID := 0;
end;

procedure TClient_MainForm.FormShow(Sender: TObject);
begin
  SendTimer.Enabled := False;
  ClientIdent(Sender);
  SendTimer.Enabled := True;
end;

procedure TClient_MainForm.ClientIdent(Sender: TObject);
var
  buffer : array[0..255] of WideChar;
  buff_size : Dword;
begin
  SendTimer.Enabled := False;
  Client.IP := IdIPWatch.LocalIP;
  buff_size := 256;
    if GetComputerName (buffer, buff_size)
      then Client.NAME := String(buffer)
      else Client.NAME := 'noname';
  SendTimer.Enabled := True;
end;

procedure TClient_MainForm.SendTimerTimer(Sender: TObject);
begin
  StatusBar.Panels[1].Text := '';

  if ((Client.ID = 0) or (not Serv_conn)) then begin
    ServerReg(Sender);
    ReadParams(Sender);
  end;

  ScreenShot(Sender);

  Client_Status := '������ [' + IntToStr(Client.ID) + '] ' + Client.NAME + ' (' + Client.IP + ')';
  if Serv_conn
    then StatusBar.Panels[0].Text := '����������� �� ������� �����������.'
    else StatusBar.Panels[0].Text := '������ �� ���������.';
  Client_MainForm.Caption := Client_status;
end;

procedure TClient_MainForm.ServerReg(Sender: TObject);
begin
  SendTimer.Enabled := False;
  IdTCPClient.Host := Server_Host;
  IdTCPClient.Port := Server_Port_Cmd;

  try
    IdTCPClient.Connect;
    try
      IdTCPClient.IOHandler.Write(0);
      IdTCPClient.IOHandler.WriteLn(Client.IP);
      IdTCPClient.IOHandler.WriteLn(Client.NAME);
      Client.ID := IdTCPClient.IOHandler.ReadByte;
    finally
      IdTCPClient.Disconnect;
      Serv_conn := True;
    end;
   except
    Serv_conn := False;
  end;
  SendTimer.Enabled := True;
end;

procedure TClient_MainForm.ReadParams(Sender : TObject);
begin
  if ((Client.ID = 0) or (not Serv_conn)) then exit;

  SendTimer.Enabled := False;
  IdTCPClient.Host := Server_Host;
  IdTCPClient.Port := Server_Port_Cmd;

  try
    IdTCPClient.Connect;
    try
      IdTCPClient.IOHandler.Write(1);
      IdTCPClient.IOHandler.Write(Client.ID);
      Client.PIC_Q := IdTCPClient.IOHandler.ReadByte;
      Client.PIC_W := IdTCPClient.IOHandler.ReadUInt16(false);
      Client.PIC_H := IdTCPClient.IOHandler.ReadUInt16(false);
      Client.FPS := IdTCPClient.IOHandler.ReadByte;
    finally
      IdTCPClient.Disconnect;
      Serv_conn := True;
      SendTimer.Interval := 1000 div Client.FPS;
    end;
   except
    Serv_conn := False;
  end;
  SendTimer.Enabled := True;
end;

procedure TClient_MainForm.ScreenShot(Sender : TObject);
var
  PictStream : TMemoryStream;
  Desktop_screen : Tcanvas;
  ScreenShot_bitmap : TBitmap;
  ScreenShot_jpeg : TJpegImage;
  StreamSize : uInt64;
begin

  StatusBar.Panels[1].Text := '';

  if ((Client.ID = 0) or (not Serv_conn)) then exit;

  SendTimer.Enabled := False;
  ReadParams(Sender);

  Desktop_screen := TCanvas.Create;
  Desktop_screen.Handle := GetDC(HWND_DESKTOP);
  ScreenShot_bitmap := TBitmap.Create;
  ScreenShot_bitmap.Width := Screen.Width;
  ScreenShot_bitmap.Height := Screen.Height;
  ScreenShot_bitmap.Canvas.CopyRect(ScreenShot_bitmap.Canvas.ClipRect, Desktop_screen, Desktop_screen.ClipRect);
  ReleaseDC(0, Desktop_screen.Handle);
  Desktop_screen.Free;

  SetStretchBltMode(ScreenShot_bitmap.Canvas.Handle,4);
  StretchBlt(ScreenShot_bitmap.Canvas.Handle,0,0,Client.PIC_W,Client.PIC_H,ScreenShot_bitmap.Canvas.Handle,0,0,Screen.Width,Screen.Height,SRCCOPY);

  ScreenShot_jpeg := TJpegImage.Create;
  ScreenShot_jpeg.Assign(ScreenShot_bitmap);
  ScreenShot_jpeg.CompressionQuality:=Client.PIC_Q;
  ScreenShot_jpeg.Compress;

  Image1.Visible := False;
  IdTCPClient.Port := Server_Port_Img;

  try
    IdTCPClient.Connect;
    try
      PictStream := TMemoryStream.Create;
      ScreenShot_jpeg.SaveToStream(PictStream);
      StreamSize := PictStream.Size;
      Image1.Picture.Bitmap := ScreenShot_bitmap;
      PictStream.Position := 0;
      IdTCPClient.IOHandler.Write(Client.ID);
      IdTCPClient.IOHandler.Write(StreamSize,false);
      IdTCPClient.IOHandler.Write(PictStream,StreamSize);
    finally
      StatusBar.Panels[1].Text := '����������: ' + inttostr(StreamSize);
      PictStream.Clear;
      PictStream.Free;
      IdTCPClient.Disconnect;
      Serv_conn := True;
    end;
  except
    Serv_conn := False;
  end;
  ScreenShot_bitmap.Free;
  ScreenShot_jpeg.Free;
  Image1.Visible := True;
  SendTimer.Enabled := True;
end;

{

procedure TForm1.IdTCPServer2Execute(AThread: TIdPeerThread);
var stxt:string;
begin
  stxt := AThread.Connection.ReadLn;
  if pos('see_message',stxt) <> 0 then
    //������� ��������� �� �����
    MessageBox(Handle,PChar(copy(stxt,12,length(stxt))),PChar('���������'),MB_OK+MB_SYSTEMMODAL);
end;

}
end.

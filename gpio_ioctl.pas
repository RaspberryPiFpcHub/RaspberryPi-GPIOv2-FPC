unit gpio_ioctl;

{$optimization autoInline}
{$mode objfpc}{$H+}

interface

uses
  Classes, Dialogs, unix, baseUnix, SysUtils;

const
  Consumer='gpio_ioctl';    //GPIO_MAX_NAME_SIZE; - use your name

  P3 = 2;
  P5 = 3;
  P7 = 4;
  P8 = 14;
  P10 = 15;
  P11 = 17;
  P12 = 18;
  P13 = 27;
  P15 = 22;
  P16 = 23;
  P18 = 24;
  P19 = 10;
  P21 = 9;
  P22 = 25;
  P23 = 11;
  P24 = 8;
  P26 = 7;
  //  p27 = 0;    // id_sd   dont use
  //  p28 = 1;    //  id_sc  dont use
  p29 = 5;
  p31 = 6;
  p32 = 12;
  p33 = 13;
  p35 = 19;
  p36 = 16;
  p37 = 26;
  p38 = 20;
  p40 = 21;

  pullup: qword = 1 << 8;
  pullDown: qword = 1 << 9;
  pullnone: qword = 1 << 10;
  aktivLow: qword = 1 << 1;

  opendrain: qword = 1 << 6;
  opensource: qword = 1 << 7;
  opennone: qword = 0;

  GPIO_V2_LINE_FLAG_USED: qword = 1 << 0;
  GPIO_V2_LINE_FLAG_ACTIVE_LOW: qword = 1 << 1;
  GPIO_V2_LINE_FLAG_INPUT: qword = 1 << 2;
  GPIO_V2_LINE_FLAG_OUTPUT: qword = 1 << 3;
  GPIO_V2_LINE_FLAG_EDGE_RISING: qword = 1 << 4;
  GPIO_V2_LINE_FLAG_EDGE_FALLING: qword = 1 << 5;
  GPIO_V2_LINE_FLAG_OPEN_DRAIN: qword = 1 << 6;
  GPIO_V2_LINE_FLAG_OPEN_SOURCE: qword = 1 << 7;
  GPIO_V2_LINE_FLAG_BIAS_PULL_UP: qword = 1 << 8;
  GPIO_V2_LINE_FLAG_BIAS_PULL_DOWN: qword = 1 << 9;
  GPIO_V2_LINE_FLAG_BIAS_DISABLED: qword = 1 << 10;
  GPIO_V2_LINE_FLAG_EVENT_CLOCK_REALTIME: qword = 1 << 11;
  GPIO_V2_LINE_FLAG_EVENT_CLOCK_HTE: qword = 1 << 12;

  GPIO_V2_LINES_MAX = 64;
  GPIO_MAX_NAME_SIZE = 32;
  GPIO_V2_LINE_NUM_ATTRS_MAX = 10;





type
  TGPIOV2LineAttributeUnion = record
    case integer of
      0: (flags: QWord);               // 64-Bit-Wert f�r Flags
      1: (values: QWord);              // 64-Bit-Wert f�r Values
      2: (debounce_period_us: cuint32); // 32-Bit-Wert f�r debounce_period_us
  end;

  TGPIOV2LineAttribute = record
    id: cuint32;                       // __u32 entspricht cuint32 in FPC
    padding: cuint32;                  // Padding, ebenfalls 32-Bit
    attr_union: TGPIOV2LineAttributeUnion; // Union mit den verschiedenen Attributen
  end;

type
  TGPIOV2LineConfigAttribute = record
    attr: TGPIOV2LineAttribute;  // Enthält die gpio_v2_line_attribute Struktur
    mask: QWord;                 // __aligned_u64 wird durch QWord (64-Bit) in FPC repräsentiert
  end;

type
  // Definition der gpio_v2_line_config Struktur
  TGPIOV2LineConfig = record
    flags: QWord;                                // __aligned_u64 wird als QWord (64-Bit) in Free Pascal repräsentiert
    num_attrs: cuint32;                          // __u32 entspricht cuint32 in FPC
    padding: array[0..4] of cuint32;             // Padding-Feld mit 5 Elementen (32-Bit-Werte)
    attrs: array[0..GPIO_V2_LINE_NUM_ATTRS_MAX - 1] of TGPIOV2LineConfigAttribute;  // Array von Attributen
  end;

type
  Tgpio_v2_line_request = record
    offsets: array[0..GPIO_V2_LINES_MAX - 1] of longword;
    consumer: array[0..GPIO_MAX_NAME_SIZE - 1] of ansichar;
    config: Tgpiov2lineconfig;
    num_lines: longword;
    event_buffer_size: longword;
    padding: array[0..4] of longword;
    fd: longint;
  end;

type
  TGPIOV2LineValues = record
    bits: QWord;   // entspricht __aligned_u64
    mask: QWord;   // entspricht __aligned_u64
  end;


var
  fd_device: integer;
  req: Tgpio_v2_line_request;
  pin_fd: array[0..63] of longint;
  GPIO_V2_GET_LINE_IOCTL: dword;
  GPIO_V2_LINE_GET_VALUES_IOCTL: dword;
  GPIO_V2_LINE_SET_VALUES_IOCTL: dword;

procedure GpioIniz; overload;
procedure GpioIniz(Lines: array of integer); overload;
procedure gpiosetbit(gpionummer: integer);
procedure gpioclearbit(gpionummer: integer);
procedure GpioOpenLineOutput(gpionummer: integer; Flags: Qword);
procedure GpioOpenLineInput(gpionummer: integer; Flags: Qword);
function gpiogetbit(gpionummer: integer): boolean;
procedure GpioCloseAllLines;


implementation


function IOWR(typ: longword; nr: longword; size: longword): longword;
const
  IOC_NRBITS = 8;
  IOC_TYPEBITS = 8;
  IOC_SIZEBITS = 14;

  IOC_NRSHIFT = 0;
  IOC_TYPESHIFT = IOC_NRSHIFT + IOC_NRBITS;
  IOC_SIZESHIFT = IOC_TYPESHIFT + IOC_TYPEBITS;
  IOC_DIRSHIFT = IOC_SIZESHIFT + IOC_SIZEBITS;

  IOC_NONE = 0;
  IOC_WRITE = 1;
  IOC_READ = 2;

  IOC_READWRITE = IOC_READ or IOC_WRITE;
begin
  Result := (IOC_READWRITE shl IOC_DIRSHIFT) or (typ shl IOC_TYPESHIFT) or (nr shl IOC_NRSHIFT) or (size shl IOC_SIZESHIFT);
end;


procedure GpioIniz;
var
  x: integer;
begin
  for x := 0 to 31 do
    pin_fd[x] := -1;
  GPIO_V2_GET_LINE_IOCTL := iowr($B4, $7, sizeof(Tgpio_v2_line_request));
  GPIO_V2_LINE_GET_VALUES_IOCTL := iowr($B4, $E, sizeof(TGPIOV2LineValues));
  GPIO_V2_LINE_SET_VALUES_IOCTL := iowr($B4, $F, sizeof(TGPIOV2LineValues));
end;

procedure GpioIniz(Lines: array of integer);
var
  x: integer;
begin
  for x := low(Lines) to high(Lines) do
    pin_fd[Lines[x]] := -1;
  GPIO_V2_GET_LINE_IOCTL := iowr($B4, $7, sizeof(Tgpio_v2_line_request));
  GPIO_V2_LINE_GET_VALUES_IOCTL := iowr($B4, $E, sizeof(TGPIOV2LineValues));
  GPIO_V2_LINE_SET_VALUES_IOCTL := iowr($B4, $F, sizeof(TGPIOV2LineValues));
end;


procedure GpioOpenLineInput(gpionummer: integer; Flags: Qword);
const
  GPIO_V2_LINE_ATTR_ID_BIAS = 1;
begin
  if pin_fd[gpionummer] > -1 then
  begin
    fpclose(pin_fd[gpionummer]);
    pin_fd[gpionummer] := -1;
  end;

  fd_device := FpOpen('/dev/gpiochip0', O_RDWR);
  fillchar(req, sizeof(req), 0);

  req.offsets[0] := gpionummer;
  req.consumer := consumer;
  req.num_lines := 1;

  // Bias-Attribut setzen
  req.config.num_attrs := 1;
  req.config.attrs[0].mask := GPIO_V2_LINE_ATTR_ID_BIAS;
  req.config.attrs[0].attr.attr_union.values := Flags;

  // Flags korrekt kombinieren
  req.config.flags := GPIO_V2_LINE_FLAG_INPUT or Flags;

  req.event_buffer_size := 0;

  FPioctl(fd_device, GPIO_V2_GET_LINE_IOCTL, @req);
  pin_fd[gpionummer] := req.fd;
  fpclose(fd_device);
end;



procedure GpioOpenLineOutput(gpionummer: integer; Flags: Qword);
begin
  if pin_fd[gpionummer] > -1 then
  begin
    fpclose(pin_fd[gpionummer]);
    pin_fd[gpionummer] := -1;
  end;

  fd_device := FpOpen('/dev/gpiochip0', O_RDWR);
  if fd_device < 0 then
    exit;
  fillchar(req, sizeof(req), 0);

  req.offsets[0] := gpionummer;
  req.consumer := consumer;
  req.num_lines := 1;

  req.config.num_attrs := 2;
  req.config.attrs[0].mask := %1;

  req.config.flags := GPIO_V2_LINE_FLAG_Output + Flags;

  //  req.event_buffer_size := 0;

  FPioctl(fd_device, GPIO_V2_GET_LINE_IOCTL, @req);
  pin_fd[gpionummer] := req.fd;
  fpclose(fd_device);
end;


function gpiogetbit(gpionummer: integer): boolean;
var
  LineValues: TGPIOV2LineValues;
begin
  lineValues.bits := 0;
  linevalues.mask := qword(1);
  FPioctl(pin_fd[gpionummer], GPIO_V2_LINE_GET_VALUES_IOCTL, @LineValues);
  Result := linevalues.bits > 0;
end;



procedure gpiosetbit(gpionummer: integer);
var
  LineValues: TGPIOV2LineValues;
begin
  linevalues.mask := qword(1);
  linevalues.bits := linevalues.mask;
  FPioctl(pin_fd[gpionummer], GPIO_V2_LINE_SET_VALUES_IOCTL, @LineValues);
end;

procedure gpioclearbit(gpionummer: integer);
var
  LineValues: TGPIOV2LineValues;
begin
  linevalues.mask := qword(1);
  linevalues.bits := 0;
  FPioctl(pin_fd[gpionummer], GPIO_V2_LINE_SET_VALUES_IOCTL, @LineValues);
end;



procedure CloseLine(LineNummer: integer);
begin
  if pin_fd[lineNummer] > -1 then
  begin
    fpclose(pin_fd[lineNummer]);
    pin_fd[lineNummer] := -1;
  end;
end;


procedure GpioCloseAllLines;
var
  x: integer;
begin
  for x := 0 to 31 do
  begin
    if pin_fd[x] > -1 then
    begin
      fpclose(pin_fd[x]);
      pin_fd[x] := -1;
    end;
  end;
end;

end.                             

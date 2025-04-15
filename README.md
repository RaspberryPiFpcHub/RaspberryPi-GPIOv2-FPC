# GPIOlib for Free Pascal on Linux

A simple and fast Pascal unit to control GPIO pins using the Linux GPIO character device interface (`/dev/gpiochip*`).  
Supports Raspberry Pi 4/5 and other boards using the new `gpiod` interface (kernel 5.x+).

## Features

- Open and configure GPIO lines by **pin name** (e.g., `p11`) or **GPIO number**
- Set direction: input or output
- Control pull-up, pull-down, and no-pull
- Support for active-low, open-drain, open-source, or push-pull
- Fast and lightweight, no external dependencies

## Usage

### Opening a GPIO line as output

```pascal
uses
  gpiolib;

var
  gpio: TGpioLine;

begin
  gpio := GpioOpenLineOutput(p11);           // Open pin 11 as output (default push-pull)
  gpioSetBit(p11);                           // Set high
  gpioClearBit(p11);                         // Set low
  GpioCloseAllLines; ;                       // Always close when everything is done
end.
```

### Opening a GPIO line as input with pull-up

```pascal
uses
  gpiolib;

var
  gpio: TGpioLine;

begin
  gpio := GpioOpenLineInput(p11, pullup);     // Open pin 11 as input with pull-up resistor
  if gpioGetBit  then
    writeln('High')
  else
    writeln('Low');
  gpioCloseAllLines; // only if you don't use any GpioFunctions anymore
 end.
```

## Available Flags

The following **predefined constants** can be used to configure GPIO behavior when calling `GpioOpenLineInput(...)` or `GpioOpenLineOutput(...)`:

```pascal
const
  pullup     = 1;   // Enable internal pull-up resistor
  pullDown   = 2;   // Enable internal pull-down resistor
  pullnone   = 4;   // Disable all pull resistors

  aktivLow   = 8;   // Logical level is inverted (active-low)

  opendrain  = 64;  // Open-drain output (only pulls LOW)
  opensource = 128; // Open-source output (only drives HIGH)
  opennone   = 0;   // Default push-pull output (neither open-drain nor open-source)
```

> 🔧 These constants are predefined in the `gpiolib.pas` unit and can be combined using `or`.

### Examples

```pascal
// Output with pull-down and active-low
 GpioOpenLineOutput(p13, pullDown or aktivLow);

// Input with no pull resistor
 GpioOpenLineInput(p15, pullnone);

// Push-pull output (explicit)
 GpioOpenLineOutput(p17, opennone);
```

## Pin Identification

GPIO lines can be opened by:

- **Predefined pin names** (e.g., `p11`, `p13`, etc.)
- **GPIO numbers** (e.g., `17`)

The predefined pin constants (like `p11`) correspond to the physical header pins on the Raspberry Pi and are mapped internally to the correct GPIO number.

## Use Cases

This library is ideal for:

- Reading buttons or switches
- Driving LEDs or relays
- Building GPIO-based sensors and control systems
- Fast prototyping on Raspberry Pi using Free Pascal

## License

MIT License

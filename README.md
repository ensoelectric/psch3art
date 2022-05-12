# psch3art07d

PSCH-3ART.07D.132/B (https://www.nzif.ru/uploads/sel/psch3art07d/ruk_psch3art07d.pdf) power meter communication utility.

## Build and use  
```
$ git clone https://github.com/ensoelectric/psch3art07d
$ cd psch3art07d 
```

```
$ cpan
Loading internal null logger. Install Log::Log4perl for logging messages
Terminal does not support AddHistory.

cpan shell -- CPAN exploration and modules installation (v2.18)
Enter 'h' for help.

cpan[1]> install Device::SerialPort
```

```
Usage: ./psch3art07d.pl RS485 ADDR
RS485 address of RS485 dongle (e.g. /dev/ttyUSB0), required
ADDR power meter net address(e.g. 010), required
```

## Example

```
./psch3art07d.pl /dev/ttyr01 024
{
  "U": {
    "p1": 227.564,
    "p2": 228.16,
    "p3": 227.915
  },
  "I": {
    "p1": 0,
    "p2": 0,
    "p3": 0
  },
  "P": {
    "p1": 77272.449,
    "p2": 57575.279,
    "p3": 0,
    "p4": 0,
    "sum": 134847.728
  },
  "S": {
    "p1": 10908.102,
    "p2": 11724.031,
    "p3": 0,
    "p4": 0,
    "sum": 22632.133
  }
}
```

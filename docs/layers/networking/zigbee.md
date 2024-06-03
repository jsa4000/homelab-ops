# Zigbee

## Commands

Useful commands to verify the devices connected and kernel features.

```bash
# Use dmesg print or control the kernel ring buffer
dmesg

[  440.815631] usb 3-1: USB disconnect, device number 2
[  535.665640] usb 3-1: new full-speed USB device number 3 using ohci-platform
[  535.898869] usb 3-1: New USB device found, idVendor=1a86, idProduct=55d4, bcdDevice= 4.42
[  535.898895] usb 3-1: New USB device strings: Mfr=1, Product=2, SerialNumber=3
[  535.898915] usb 3-1: Product: SONOFF Zigbee 3.0 USB Dongle Plus V2
[  535.898931] usb 3-1: Manufacturer: ITEAD
[  535.898948] usb 3-1: SerialNumber: 20240123152135
[  535.901325] cdc_acm 3-1:1.0: ttyACM0: USB ACM device

dmesg | grep tty

[  535.901325] cdc_acm 3-1:1.0: ttyACM0: USB ACM device

# List all USB devices connected
lsusb -t -v

# Take a look to uncommented lines.

#    /:  Bus 06.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/1p, 5000M
#    ID 1d6b:0003 Linux Foundation 3.0 root hub
#/:  Bus 05.Port 1: Dev 1, Class=root_hub, Driver=xhci-hcd/1p, 480M
#    ID 1d6b:0002 Linux Foundation 2.0 root hub
#/:  Bus 04.Port 1: Dev 1, Class=root_hub, Driver=ohci-platform/1p, 12M
#    ID 1d6b:0001 Linux Foundation 1.1 root hub
/:  Bus 03.Port 1: Dev 1, Class=root_hub, Driver=ohci-platform/1p, 12M
    ID 1d6b:0001 Linux Foundation 1.1 root hub
    |__ Port 1: Dev 2, If 0, Class=Communications, Driver=cdc_acm, 12M
        ID 1a86:55d4 QinHeng Electronics
    |__ Port 1: Dev 2, If 1, Class=CDC Data, Driver=cdc_acm, 12M
        ID 1a86:55d4 QinHeng Electronics
#/:  Bus 02.Port 1: Dev 1, Class=root_hub, Driver=ehci-platform/1p, 480M
#    ID 1d6b:0002 Linux Foundation 2.0 root hub
#/:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=ehci-platform/1p, 480M
#    ID 1d6b:0002 Linux Foundation 2.0 root hub
```

In order to get the port configuration for `zigbee2mqtt` or `ZHA` (Zigbee for Home Assistant) execute following commands.

```bash
# List all serials by identifier
ls -l /dev/serial/by-id

total 0
lrwxrwxrwx 1 root root 13 jun  3 18:11 usb-ITEAD_SONOFF_Zigbee_3.0_USB_Dongle_Plus_V2_20240123152135-if00 -> ../../ttyACM0
```

In this example the correct port would be `/dev/ttyACM0`

-- Copyright (C) 2024-2026 Simon <simon@example.com>
--

local m = Map("wol-pro", translate("Wake-on-LAN Pro Settings"),
	translate("Configure Wake-on-LAN devices and settings."))

-- Devices section
local s = m:section(TypedSection, "device", translate("Devices"),
	translate("List of devices that can be awakened via Wake-on-LAN."))
s.addremove = true
s.anonymous = true
s.template = "cbi/tblsection"

-- Name
s:option(Value, "name", translate("Device Name"),
	translate("A friendly name for this device.")).placeholder = "My PC"

-- MAC Address
local mac = s:option(Value, "mac", translate("MAC Address"),
	translate("The MAC address of the target device (format: XX:XX:XX:XX:XX:XX)."))
mac.placeholder = "00:11:22:33:44:55"
mac.datatype = "macaddr"
mac.required = true

-- IP Address (optional, for reference)
local ip = s:option(Value, "ipaddr", translate("IP Address"),
	translate("Optional: IP address for reference and status checking."))
ip.placeholder = "192.168.1.100"
ip.datatype = "ipaddr"

-- Broadcast Address
local broadcast = s:option(Value, "broadcast", translate("Broadcast Address"),
	translate("Broadcast address for sending magic packets."))
broadcast.placeholder = "255.255.255.255"
broadcast.default = "255.255.255.255"

-- Interface
local iface = s:option(Value, "iface", translate("Interface"),
	translate("Network interface to send magic packets through."))
iface.placeholder = "br-lan"
iface.default = "br-lan"

-- Notes
local notes = s:option(Value, "notes", translate("Notes"),
	translate("Optional notes about this device."))
notes.placeholder = "Desktop PC in office"

return m
-- Copyright (C) 2024-2026 Simon <simon@example.com>
--

module("luci.controller.wol-pro", package.seeall)

local LOG_FILE = "/var/log/wol-pro.log"
local MAX_LOG_ENTRIES = 100

function index()
	if not nixio.fs.access("/etc/config/wol-pro") then
		return
	end

	entry({"admin", "services", "wol-pro"},
		alias("admin", "services", "wol-pro", "devices"),
		_("Wake-on-LAN Pro"), 60).dependent = true

	entry({"admin", "services", "wol-pro", "devices"},
		template("wol-pro/index"),
		_("Devices"), 10).leaf = true

	entry({"admin", "services", "wol-pro", "logs"},
		template("wol-pro/logs"),
		_("Logs"), 20).leaf = true

	-- JSON API endpoints
	entry({"admin", "services", "wol-pro", "list"},
		call("action_list_devices")).leaf = true

	entry({"admin", "services", "wol-pro", "wake"},
		call("action_wake_device")).leaf = true

	entry({"admin", "services", "wol-pro", "save"},
		call("action_save_device")).leaf = true

	entry({"admin", "services", "wol-pro", "delete"},
		call("action_delete_device")).leaf = true

	entry({"admin", "services", "wol-pro", "status"},
		call("action_device_status")).leaf = true

	entry({"admin", "services", "wol-pro", "scan_arp"},
		call("action_scan_arp")).leaf = true

	entry({"admin", "services", "wol-pro", "get_logs"},
		call("action_get_logs")).leaf = true

	entry({"admin", "services", "wol-pro", "clear_logs"},
		call("action_clear_logs")).leaf = true
end

-- 璁板綍鏃ュ織锛堣嚜鍔ㄩ檺鍒舵潯鏁帮級
local function log_wake(device_name, mac, success, message)
	local timestamp = os.date("%Y-%m-%d %H:%M:%S")
	local log_entry = string.format("[%s] %s | MAC: %s | Status: %s | %s\n",
		timestamp,
		device_name or "Unknown",
		mac,
		success and "SUCCESS" or "FAILED",
		message or ""
	)

	-- 璇诲彇鐜版湁鏃ュ織
	local all_lines = {}
	local f = io.open(LOG_FILE, "r")
	if f then
		for line in f:lines() do
			if line and line ~= "" then
				table.insert(all_lines, line)
			end
		end
		f:close()
	end

	-- 娣诲姞鏂版棩蹇?	table.insert(all_lines, log_entry)

	-- 濡傛灉瓒呰繃鏈€澶ф潯鏁帮紝鍙繚鐣欐渶杩戠殑 MAX_LOG_ENTRIES 鏉?	if #all_lines > MAX_LOG_ENTRIES then
		local keep_lines = {}
		local start_idx = #all_lines - MAX_LOG_ENTRIES + 1
		for i = start_idx, #all_lines do
			table.insert(keep_lines, all_lines[i])
		end
		all_lines = keep_lines
	end

	-- 鍐欏洖鏃ュ織鏂囦欢
	f = io.open(LOG_FILE, "w")
	if f then
		for _, line in ipairs(all_lines) do
			f:write(line .. "\n")
		end
		f:close()
	end
end

-- List all configured devices
function action_list_devices()
	local uci = require "luci.model.uci".cursor()
	local devices = {}
	
	uci:foreach("wol-pro", "device", function(s)
		table.insert(devices, {
			[".name"] = s[".name"],
			name = s.name or "",
			mac = s.mac or "",
			ipaddr = s.ipaddr or "",
			broadcast = s.broadcast or "255.255.255.255",
			iface = s.iface or "br-lan",
			notes = s.notes or ""
		})
	end)
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true, devices = devices})
end

-- Wake a device
function action_wake_device()
	local json = require "luci.jsonc"
	local uci = require "luci.model.uci".cursor()
	local data = json.parse(luci.http.content())
	local mac = data and data.mac
	local broadcast = data and data.broadcast or "255.255.255.255"
	local iface = data and data.iface or "br-lan"
	local device_name = data and data.name or ""

	-- 濡傛灉娌℃湁璁惧鍚嶇О锛屽皾璇曚粠 UCI 閰嶇疆涓煡鎵?	if device_name == "" and mac then
		uci:foreach("wol-pro", "device", function(s)
			if s.mac and s.mac:lower() == mac:lower() then
				device_name = s.name or ""
				return false
			end
		end)
	end

	if not mac or mac == "" then
		luci.http.status(400)
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = false, message = "Missing MAC address"})
		return
	end

	-- 灏濊瘯澶氱 etherwake 璺緞鍜屽懡浠?	local result = -1
	local output = ""

	-- 鏂规硶1: etherwake (甯歌璺緞)
	local paths = {
		"/usr/bin/etherwake",
		"/usr/sbin/etherwake",
		"etherwake"
	}

	for _, path in ipairs(paths) do
		local cmd = string.format("%s -i %s %s 2>&1", path, iface, mac)
		local f = io.popen(cmd)
		if f then
			output = f:read("*a") or ""
			local success, exit_reason = f:close()
			if success then
				result = 0
				break
			end
		end
	end

	-- 濡傛灉 etherwake 閮藉け璐ワ紝灏濊瘯 ether-wake (OpenWRT 鍘熺敓)
	if result ~= 0 then
		local cmd = string.format("ether-wake -i %s %s 2>&1", iface, mac)
		local f = io.popen(cmd)
		if f then
			output = f:read("*a") or ""
			local success, exit_reason = f:close()
			if success then result = 0 end
		end
	end

	-- 鏈€鍚庡皾璇?wol 鍛戒护
	if result ~= 0 then
		local cmd = string.format("wol %s 2>&1", mac)
		local f = io.popen(cmd)
		if f then
			output = f:read("*a") or ""
			local success, exit_reason = f:close()
			if success then result = 0 end
		end
	end

	local success = (result == 0)
	local message = success and "Magic packet sent to " .. mac or "Failed to send magic packet: " .. output

	-- 璁板綍鏃ュ織
	log_wake(device_name, mac, success, message)

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		success = success,
		message = message
	})
end

-- Save or update a device
function action_save_device()
	local json = require "luci.jsonc"
	local uci = require "luci.model.uci".cursor()
	local data = json.parse(luci.http.content())
	
	if not data or not data.mac then
		luci.http.status(400)
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = false, message = "Invalid data"})
		return
	end
	
	local sid = data[".name"] or nil
	if sid then
		-- Update existing
		uci:set("wol-pro", sid, "device")
		uci:set("wol-pro", sid, "name", data.name or "")
		uci:set("wol-pro", sid, "mac", data.mac)
		uci:set("wol-pro", sid, "ipaddr", data.ipaddr or "")
		uci:set("wol-pro", sid, "broadcast", data.broadcast or "255.255.255.255")
		uci:set("wol-pro", sid, "iface", data.iface or "br-lan")
		uci:set("wol-pro", sid, "notes", data.notes or "")
	else
		-- Create new
		sid = uci:section("wol-pro", "device")
		uci:set("wol-pro", sid, "name", data.name or "")
		uci:set("wol-pro", sid, "mac", data.mac)
		uci:set("wol-pro", sid, "ipaddr", data.ipaddr or "")
		uci:set("wol-pro", sid, "broadcast", data.broadcast or "255.255.255.255")
		uci:set("wol-pro", sid, "iface", data.iface or "br-lan")
		uci:set("wol-pro", sid, "notes", data.notes or "")
	end
	
	uci:commit("wol-pro")
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true, sid = sid})
end

-- Delete a device
function action_delete_device()
	local json = require "luci.jsonc"
	local uci = require "luci.model.uci".cursor()
	local data = json.parse(luci.http.content())
	
	if not data or not data[".name"] then
		luci.http.status(400)
		luci.http.prepare_content("application/json")
		luci.http.write_json({success = false, message = "Invalid data"})
		return
	end
	
	uci:delete("wol-pro", data[".name"])
	uci:commit("wol-pro")
	
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true})
end

-- Check if a device is online (ping)
function action_device_status()
	local mac = luci.http.formvalue("mac")
	if not mac then
		luci.http.status(400)
		return
	end

	-- Try to find in ARP table
	local f = io.popen("cat /proc/net/arp | grep -i " .. mac .. " 2>/dev/null")
	local line = f:read()
	f:close()

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		online = (line ~= nil and line ~= ""),
		mac = mac
	})
end

-- 鑾峰彇鏃ュ織
function action_get_logs()
	local limit = tonumber(luci.http.formvalue("limit")) or 100
	local logs = {}

	local f = io.open(LOG_FILE, "r")
	if f then
		-- 璇诲彇鎵€鏈夎
		local all_lines = {}
		for line in f:lines() do
			if line and line ~= "" then
				table.insert(all_lines, line)
			end
		end
		f:close()

		-- 鍙栨渶杩戠殑 limit 鏉★紙浠庡悗寰€鍓嶏級
		local start_idx = math.max(1, #all_lines - limit + 1)
		for i = start_idx, #all_lines do
			local line = all_lines[i]
			-- 瑙ｆ瀽鏃ュ織琛? [鏃堕棿] 璁惧鍚?| MAC: xxx | Status: xxx | 娑堟伅
			local timestamp, device, mac, status, msg = line:match("^%[(.+)%]%s+(.+)%s+| MAC: ([%x:%x]+)%s+| Status: (%w+)%s+| (.+)$")
			if timestamp then
				table.insert(logs, {
					timestamp = timestamp,
					device = device,
					mac = mac,
					success = (status == "SUCCESS"),
					message = msg
				})
			else
				-- 鏃犳硶瑙ｆ瀽鐨勮锛屽師鏍蜂繚瀛?				table.insert(logs, {raw = line})
			end
		end
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({
		success = true,
		logs = logs,
		total = #logs
	})
end

-- 娓呯┖鏃ュ織
function action_clear_logs()
	local f = io.open(LOG_FILE, "w")
	if f then
		f:close()
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true, message = "Logs cleared"})
end
-- Scan ARP table for online devices
function action_scan_arp()
	local devices = {}
	local f = io.open("/proc/net/arp", "r")
	if f then
		f:read("*l")
		for line in f:lines() do
			local ip, hw_type, flags, mac, mask, iface = line:match("^(%S+)%s+0x(%x+)%s+0x(%x+)%s+(%S+)%s+(%S+)%s+(%S+)")
			if ip and mac and mac ~= "00:00:00:00:00:00" then
				table.insert(devices, {
					ip = ip,
					mac = mac:upper(),
					iface = iface or ""
				})
			end
		end
		f:close()
	end
	luci.http.prepare_content("application/json")
	luci.http.write_json({success = true, devices = devices})
end

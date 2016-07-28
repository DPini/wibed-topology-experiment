#!/usr/bin/lua

local wibed_wireless = require "wibed_wireless"
local wibed_system = require "wibed_system"

require "iwinfo"

local uci = require "uci"
local x = uci:cursor()


config = {}

config["2g"] = {}
config["2g"]["channel"] = "11"
config["2g"]["hwmode"] = "11na"
config["2g"]["htmode"] = "HT40"
config["2g"]["txpower"] = "21"
config["2g"]["country"] = "UZ"

config["5g"] = {}
config["5g"]["channel"] = "40"
config["5g"]["hwmode"] = "11na"
config["5g"]["htmode"] = "HT40"
config["5g"]["txpower"] = "21"
config["5g"]["country"] = "UZ"

local function configure_radio(radio,band)
  x:set("wireless", radio, "disabled", 0)
  x:set("wireless", radio, "channel", config[band]["channel"])
  x:set("wireless", radio, "hwmode", config[band]["hwmode"])
  -- x:set("wireless", radio, "htmode", config[band]["htmode"]) -- Uncomment only if all devices are capable
  x:set("wireless", radio, "txpower", config[band]["txpower"])
  x:set("wireless", radio, "country", config[band]["country"])
  x:set("wireless","scanradio", "wifi-iface" )
  x:set("wireless","scanradio", "device", radio )
  x:set("wireless","scanradio", "mode" , "adhoc" )
  x:set("wireless","scanradio", "ssid", hostname )
  x:set("wireless","scanradio", "bssid" , "02:C0:FF:EE:C0:DE" )
  x:set("wireless","scanradio", "encryption" , "none" )
  x:set("wireless","scanradio", "ifname" ,"scanradio" )
end

hostname = wibed_system.get_hostname()
print("Starting WiBED config for node " .. hostname )

if arg[1] == "2g" or arg[1] == "5g" then
  band = arg[1]
else
  print("Incorrect or non existent band argument. Using 2g as band")
  band = "2g"
end

radios = wibed_wireless.get_radios_band(band) or nil

--- First, try to configure a non configured radio.
--- If all the radios are configured, reconfigure a radio that is configured
--- using the freq band that we want to use for the scan.


if radios ~= nil and #radios > 0 then
  for i,j in pairs(radios) do
    if wibed_wireless.is_radio_configured(j) then
      print("radio " .. j .. " configured")
    else
      print("radio " .. j .. " not configured")
    end
    if wibed_wireless.is_radio_enabled(j) then
      print("radio " .. j .. " enabled")
    else
      print("radio " .. j .. " disabled")
    end
    if not wibed_wireless.is_radio_enabled(j) then
      radio = i
      print("radio "..radio.." selected!")
      break
    end
  end
  if radio == nil then
    for _,r in pairs(radios) do
      print("radio: " .. r)
      t = iwinfo.type(r)
      print("Radio "..r.." is type:" .. t)
      local iw = iwinfo[t]
      local freq = iw.frequency(r)
      if freq ~= nil then
        print("Radio "..r.." frequency is :" .. freq)
        freq = freq/1000
        local r_band = freq < 4 and "2g" or "5g"
        print("Radio "..r.." band is :" .. r_band)
        if r_band == band then
          radio = r
          print("radio "..radio.." selected!")
          break
        end
      -- if the device is configured but no freq. It could be that it's not beeing
      -- used (e.g. not wifi-iface in /etc/config/wireless), so we use it for scanning.
      else
        radio = r
        print("radio "..radio.." selected!")
        break
      end
    end

  end

  if radio ~= nil then
    -- delete any wifi-iface that corresponds to the wireless device to be configured
    x:foreach("wireless", "wifi-iface", function(s)
       if s["device"] == radio then
         print("Deleting " .. s[".name"] .. "section...")
         x:delete("wireless",s[".name"])
       end
    end)
    print("Configuring radio "..radio..". Band used: "..band)
    configure_radio(radio,band)
    x:commit("wireless")
  end
end
if radio == nil then
  print("No radios avaliable to configure")
end

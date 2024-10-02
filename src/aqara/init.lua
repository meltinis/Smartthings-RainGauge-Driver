local log = require "log"

local clusters = require "st.zigbee.zcl.clusters"
local battery_defaults = require "st.zigbee.defaults.battery_defaults"

local IASZone = clusters.IASZone
local PowerConfiguration = clusters.PowerConfiguration

local FINGERPRINTS = {
  { mfr = "LUMI", model = "lumi.sensor_magnet.aq2" }
}

local CONFIGURATIONS = {
  {
    cluster = IASZone.ID,
    attribute = IASZone.attributes.ZoneStatus.ID,
    minimum_interval = 30,
    maximum_interval = 3600,
    data_type = IASZone.attributes.ZoneStatus.base_type,
    reportable_change = 1
  },
  {
    cluster = PowerConfiguration.ID,
    attribute = PowerConfiguration.attributes.BatteryVoltage.ID,
    minimum_interval = 30,
    maximum_interval = 3600,
    data_type = PowerConfiguration.attributes.BatteryVoltage.base_type,
    reportable_change = 1
  }
}

local is_aqara_products = function(opts, driver, device, ...)
  local manufacturer = device:get_manufacturer()
  local model = device:get_model()
  
  -- Log the actual values returned by the device
  log.info("Device Manufacturer: " .. manufacturer)
  log.info("Device Model: " .. model)
  
  for _, fingerprint in ipairs(FINGERPRINTS) do
      -- Log the fingerprint being checked
      log.info("Checking fingerprint - Manufacturer: " .. fingerprint.mfr .. ", Model: " .. fingerprint.model)
      
      if manufacturer == fingerprint.mfr and model == fingerprint.model then
          log.info("Found the driver for manufacturer: " .. manufacturer .. ", model: " .. model)
          return true
      end
  end
  
  log.info("Did not find the driver")
  return false
end


local open_close_count = 0

local function contact_handler(driver, device, zb_rx)
    local contact_status = zb_rx.body.zcl_body.attr_value -- Get the value of the contact event

    if contact_status == 0 then
      log.info("Contact is closed")
    elseif contact_status == 1 then
      log.info("Contact is open")
    end

    open_close_count = open_close_count + 1
    log.info("Open/Close Count: " .. open_close_count)

    -- Emit an event for contact sensor change
    device:emit_event(capabilities.contactSensor.contact({value = (contact_status == 0 and "closed" or "open")}))
end




local function device_init(driver, device)
  battery_defaults.build_linear_voltage_init(2.6, 3.0)(driver, device)

  for _, attribute in ipairs(CONFIGURATIONS) do
    device:add_configured_attribute(attribute)
    device:add_monitored_attribute(attribute)
  end
end

local aqara_contact_handler = {
  NAME = "Aqara Contact Handler",
  lifecycle_handlers = {
    init = device_init
  },
  zigbee_handlers = {
    attr = {
      [IASZone.ID] = {
        [IASZone.attributes.ZoneStatus.ID] = contact_handler  -- Register the custom contact handler
      }
    }
  },
  can_handle = is_aqara_products
}

return aqara_contact_handler

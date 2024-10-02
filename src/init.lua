-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local log = require "log"
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local constants = require "st.zigbee.constants"
local defaults = require "st.zigbee.defaults"
local configurationMap = require "configurations"
local SMARTSENSE_MULTI_SENSOR_CUSTOM_PROFILE = 0xFC01
local clusters = require "st.zigbee.zcl.clusters"
local battery_defaults = require "st.zigbee.defaults.battery_defaults"

-- Set up clusters to be used
local OnOff = clusters.OnOff  -- On/Off cluster (0x0006)

-- Device initialization (e.g., setting up reporting)
local function device_init(driver, device)
  log.info("Initializing device: " .. device.label)

  -- Configure reporting for the On/Off status (open/close events)
  device:send(OnOff.attributes.OnOff:configure_reporting(device, 30, 3600, 1))
end

-- Initialize a counter for open/close events
local open_close_count = 0

-- Contact sensor event handler for On/Off cluster
local function contact_handler(driver, device, zb_rx)
  log.info("Contact handler called for device: " .. device.label)

  -- Since the OnOff status is directly available, we will use it without assuming a full ZCL structure
  if zb_rx == nil then
    log.error("Zigbee message is nil, cannot process contact event")
    return
  end

  -- Extract the OnOff status (true = open, false = closed) from the Zigbee message
  local on_off_status = zb_rx.body  -- Directly access the body
  log.info("Received Zigbee message: OnOff: " .. tostring(on_off_status))

  -- Map the OnOff status to contact sensor status
  local contact_status = (on_off_status == false) and "closed" or "open"

  -- Log the extracted contact status
  log.info("Contact status: " .. contact_status)

  -- Increment the open/close count
  open_close_count = open_close_count + 1
  log.info("Open/Close Count: " .. open_close_count)

  -- Emit an event to update the contact status in the SmartThings app
  device:emit_event(capabilities.contactSensor.contact({value = contact_status}))
end

-- Driver template configuration
local zigbee_contact_driver_template = {
  supported_capabilities = {
    capabilities.contactSensor,
    --capabilities.temperatureMeasurement,
    capabilities.battery,
    capabilities.threeAxis,
    capabilities.accelerationSensor
  },
  additional_zcl_profiles = {
    [SMARTSENSE_MULTI_SENSOR_CUSTOM_PROFILE] = true
  },
  lifecycle_handlers = {
    init = device_init
  },
  zigbee_handlers = {
    attr = {
        [OnOff.ID] = {  -- Listen for events from the On/Off cluster
            [OnOff.attributes.OnOff.ID] = contact_handler  -- Register the contact_handler for On/Off attribute
        }
    }
  },
  ias_zone_configuration_method = constants.IAS_ZONE_CONFIGURE_TYPE.AUTO_ENROLL_RESPONSE
}

-- Register default handlers
defaults.register_for_default_handlers(zigbee_contact_driver_template, zigbee_contact_driver_template.supported_capabilities)

-- Create and run the Zigbee driver
local zigbee_contact = ZigbeeDriver("zigbee_contact", zigbee_contact_driver_template)
zigbee_contact:run()

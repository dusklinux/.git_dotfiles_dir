-- Copyright (C) 2024 mesvam
-- 
-- This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.

require 'mp.msg'
-- settings
local options = {
	enabled = "false",
	silence_threshold = -23, -- in dB
	silence_duration = 0.25, -- in seconds
	speedup = 2^(1+6/12), -- this number is multiplied to normal playback speed to obtain the speed used during silence
	speed_change_osd = "false", -- display message when speed changes
	debug = "false",
}
require "mp.options".read_options(options)
-- convert to boolean before further usage
options.enabled = options.enabled == "true"
options.speed_change_osd = options.speed_change_osd == "true"
options.debug = options.debug == "true"

-- more convenient debug mode
-- to activate: --script-opts-append=ff_silence-debug=true
if options.debug then
	-- avoid clobbering other set options
	local msg_level = mp.get_property("msg-level") -- get_property_native doesn't work because table reorders items
	local additional = string.format("%s=trace", mp.get_script_name())
	if msg_level == "" then
		msg_level = additional
	else
		msg_level = msg_level .. ',' .. additional
	end
	mp.set_property("msg-level", msg_level)
	mp.msg.trace("debug mode enabled")

	mp.set_property("term-status-msg", "")
end
----------------------------------------------------------------
-- state variables
local normal_playback_speed
local fastforwarding = false
local skip_next_end = false
local last_processed_event_time = -1
mp.enable_messages("v") -- required to recieve silencedetect messages

-- predeclare functions as local, so they can be in any order and still be local
local auto_enable, enable, disable, toggle_active, silence_listener, parse_msg, fastforward, restore_original_speed, safe_time, get_silence_speed, change_speedup, change_silence_duration, change_silence_threshold, reset, add_silencedetect_filter, remove_silencedetect_filter

-- if enabled by script-opts, this activates the script only on first launch
function auto_enable()
	enable()
	mp.unregister_event(auto_enable)
end

function enable()
	add_silencedetect_filter(options.silence_threshold, options.silence_duration)
	normal_playback_speed = mp.get_property_native("speed")
	-- when audio-buffer < silence_duration, it's possible to recieve a silence_start with a timestamp that is before the current playback time (growing if silence duration threshold is long), since it needs to anlayze the entire duration length threshold before it can determine if all of it is silence
	-- there is no end/exit latency, since detection of sound is immediate. this means we never want to wait to restore to original speed
	mp.register_event("log-message", silence_listener)
	
	-- some events require a reset when script is active
	mp.register_event('seek', reset)
	mp.register_event("file-loaded", reset)
	mp.register_event("shutdown", reset)

	mp.osd_message("ff-silence enabled")
	options.enabled = true
end

function disable()
	remove_silencedetect_filter()
	mp.unregister_event(silence_listener)
	mp.unregister_event(reset)
	reset()
	mp.osd_message("ff-silence disabled")
	options.enabled = false
	fastforwarding = false
end

-- toggle all functions
function toggle_active()
	if not options.enabled then
		enable()
	else
		disable()
	end
end

-- toggle all functions
function toggle_active()
	if not options.enabled then
		enable()
	else
		disable()
	end
end

-- listens for detected silences
function silence_listener(msg)
	-- only process messages from the silencedetect filter
	if not (
		msg.prefix == "ffmpeg" and 
		msg.level == "v" and 
		string.find(msg.text, "silencedetect:")
	) then
		return
	end
	local now = safe_time()
	local type, time = parse_msg(msg.text)
	mp.msg.debug(string.format(
		"t= %s: msg= %s @ %f; diff= %s; since last= %s", 
		now, type, time,
		now and time-now or nil,
		last_processed_event_time~=-1 and time-last_processed_event_time or -1
	))
	mp.msg.trace(string.format(
		"time-pos: %s, audio-pts: %s",
		mp.get_property_native("time-pos"), mp.get_property_native("audio-pts")
	))
	
	-- due to a/v sync issues, it's possible to recieve the timestamp after playback has already crossed it. using last_processed_event_time instead of current playback time as past event filter threshold prevents a good transition from being ignored due to a/v desync. when this happens, the attack of audio is fast forwarded due to the transition delay delayed, but at least it doesn't fast forward through the entire audio
	if not (time > last_processed_event_time) then
		mp.msg.verbose(string.format("past event: ignored %s at %s", type, time))
		return
	end
	last_processed_event_time = time

	-- current time = nil means we are seeking; filter detects silence_end when seeking produces an artificial end of audio stream but playback position is undefined before seeking has ended. we should therefore should ignore message until stream has restarted playback. and if now is nil, we need to wait until we get a valid audio-pts to do anything anyways
	-- this is not a good detection method though, as a/v sync and mpv bugs may give nil even when it's time to do something, so we track the skipping state instead with skip_next_end
	if type == "end" and skip_next_end then
		mp.msg.debug("skip end from seeking")
		skip_next_end = false
		return
	end -- don't need to track next start, since that is already handled by the past event filter
	
	if type == "start" and not fastforwarding then
		fastforward()
	elseif type == "end" and fastforwarding then
		restore_original_speed()
	end
end

-- parse silencedetect messages
-- returns type and timestamp
function parse_msg(msg)
	-- msg.text examples:
	-- 	"silencedetect: silence_start: 36.8057\n"
	-- 	"silencedetect: silence_end: 37.4385 | silence_duration: 0.63275\n"
	-- silence_end returned is the actual silence boundary, not including duration threshold
	local type, time
	if string.find(msg, "silence_start") then
		type = "start"
		time = tonumber(string.match(msg, "silence_start: (%d+%.*%d*)"))
	else -- silence_end
		type = "end"
		time = tonumber(string.match(msg, "silence_end: (%d+%.*%d*)"))
	end
	return type, time
end

function fastforward()
	if fastforwarding then
		return
	end
	mp.msg.info("fast forward @", safe_time())
	normal_playback_speed = mp.get_property_native("speed")
	mp.set_property_native("speed", get_silence_speed())
	if options.speed_change_osd then
		mp.osd_message(string.format("⏩%.2fx", get_silence_speed()), 60)
	end
	fastforwarding = true
end

function restore_original_speed()
	if not fastforwarding then
		return
	end
	mp.msg.info("original speed @", safe_time())
	mp.set_property_native("speed", normal_playback_speed)
	if options.speed_change_osd then
		mp.osd_message(string.format("▶%.2fx", normal_playback_speed))
	end
	fastforwarding = false
end

-- a safe way to return current time
-- with video, sometimes audio-pts not available, but time-pos is
function safe_time()
	local now = mp.get_property_native('audio-pts')
	if now ~= nil then
		return now
	end
	now = mp.get_property_native('time-pos')
	if now ~= nil then
		return now
	end
	return -1
end

-- what the speed should be when fast forwarding during a silence period
function get_silence_speed()
	return normal_playback_speed * options.speedup
end

function change_speedup(v)
	options.speedup = options.speedup * 2^(v/12)
	if fastforwarding then
		mp.set_property_native("speed", get_silence_speed())
	end
	mp.osd_message(string.format("silence speed factor: %.2f", options.speedup))
end

function change_silence_duration(v)
	options.silence_duration = options.silence_duration * 2^(v/2)
	if options.enabled then
		remove_silencedetect_filter()
		add_silencedetect_filter(options.silence_threshold, options.silence_duration)
	end
	reset()
	mp.osd_message(string.format("silence duration: %.3f", options.silence_duration))
end

function change_silence_threshold(v)
	options.silence_threshold = options.silence_threshold + v
	if options.enabled then
		remove_silencedetect_filter()
		add_silencedetect_filter(options.silence_threshold, options.silence_duration)
	end
	reset()
	mp.osd_message(string.format("silence threshold: %ddB", options.silence_threshold))
end

function reset()
	mp.msg.trace("reset")
	last_processed_event_time = -1
	skip_next_end = false
	if fastforwarding then
		restore_original_speed()
	end
end

function add_silencedetect_filter(threshold, duration)
	mp.command(string.format("change-list af pre @ff-silence_silencedetect:lavfi=[silencedetect=n=%ddB:d=%s]", threshold, tostring(duration)))
end

function remove_silencedetect_filter()
	mp.command("change-list af remove @ff-silence_silencedetect")
end

----------------------------------------------------------------
-- default key binds
mp.add_key_binding("ctrl+a", "toggle_active", toggle_active)
mp.add_key_binding("alt+KP_ADD", "increase_speedup", function() change_speedup(1) end, {repeatable = true})
mp.add_key_binding("alt+KP_SUBTRACT", "decrease_speedup", function() change_speedup(-1) end, {repeatable = true})
mp.add_key_binding("ctrl+KP_ADD", "increase_original_speed", function() change_original_speed(1) end, {repeatable = true})
mp.add_key_binding("ctrl+KP_SUBTRACT", "decrease_original_speed", function() change_original_speed(-1) end, {repeatable = true})
mp.add_key_binding("alt+KP_MULTIPLY", "increase_silence_duration", function() change_silence_duration(1) end, {repeatable = true})
mp.add_key_binding("alt+KP_DIVIDE", "decrease_silence_duration", function() change_silence_duration(-1) end, {repeatable = true})
mp.add_key_binding("ctrl+KP_MULTIPLY", "increase_silence_threshold", function() change_silence_threshold(1) end, {repeatable = true})
mp.add_key_binding("ctrl+KP_DIVIDE", "decrease_silence_threshold", function() change_silence_threshold(-1) end, {repeatable = true})

if options.enabled then
	-- need to wait until file-loaded to get saved playback speed
	mp.register_event('file-loaded', auto_enable)
end

-- Increase playback speed during silence - a revolution in attention-deficit
-- induction technology.
--
-- Main repository: https://codeberg.org/ferreum/mpv-skipsilence/
--
-- Based on the script https://gist.github.com/bitingsock/e8a56446ad9c1ed92d872aeb38edf124
--
-- This is inspired by the NewPipe app's built-in "Fast-forward during silence"
-- feature.
--
-- Note: In mpv version 0.36 and below, the `scaletempo2` filter (default since
-- mpv version 0.34) caused audio-video de-synchronization when changing speed
-- a lot. This has been fixed in mpv 0.37. See [mpv issue
-- #12028](https://github.com/mpv-player/mpv/issues/12028). Small, frequent
-- speed changes instead of large steps may help to reduce this problem. The
-- scaletempo and rubberband filters didn't have this problem, but have
-- different audio quality characteristics.
--
-- Features:
-- - Parameterized speedup ramp, allowing profiles for different kinds of
--   media (ramp_*, speed_*, startdelay options).
-- - Noise reduction of the detected signal. This allows to speed up
--   pauses in speech despite background noise. The output audio is
--   unaffected by default (arnndn_* options).
-- - Saved time estimation.
-- - Integration with osd-msg, auto profiles, etc. (with user-data, mpv 0.36
--   and above only).
-- - Experimental: Lookahead for dynamic slowdown and faster reaction time
--   (`lookahead`, `slowdown_ramp_*`, `margin_*` options).
-- - Workaround for scaletempo2 audio-video desynchronization in mpv 0.36 and
--   below (resync_threshold_droppedframes option).
-- - Workaround for clicks during speed changes with scaletempo2 in mpv 0.36
--   and below (alt_normal_speed option).
--
-- Default bindings:
--
-- F2 - toggle
-- F3 - threshold-down
-- F4 - threshold-up
--
-- All supported bindings (bind with 'script-binding skipsilence/<name>'):
--
-- enable - enable the script, if it wasn't enabled.
-- disable - disable the script, if it was enabled.
-- toggle - toggle the script
-- threshold-down - decrease threshold_db by 1 (reduce amount skipped)
-- threshold-up - increase threshold_db by 1 (increase amount skipped)
-- info - show state info in osd
-- reset-total - reset total saved time statistic
-- cycle-info-style - cycle the infostyle option
-- toggle-arnndn - toggle the arnndn_enable option
-- toggle-arnndn-output - toggle the arnndn_output option
--
-- Script messages (use with 'script-message-to skipsilence <msg> ...'):
--
-- adjust-threshold-db <n>
--      Adjust threshold_db by n.
-- enable [no-osd]
--      Enable the script. Passing 'no-osd' suppresses the osd message.
-- disable [<speed>] [no-osd]
--      Disable the script. If speed is specified, set the playback speed to
--      the given value instead of the normal playback speed. Passing 'no-osd'
--      suppresses the osd message.
-- toggle [no-osd]
--      Toggle the script. Passing 'no-osd' suppresses the osd message.
-- info [<style>]
--      Show state as osd message. If style is specified, use it instead of
--      the infostyle option. Defaults to "verbose" if "off".
-- adjust-speed add|multiply|set <n>
--      During silence, adjust the base speed by adding it to n, multiplying
--      it with n, or setting it to n. This allows changing speed more
--      reliably than the apply_speed_change option.
--
--      Usage:
--      - Ensure that apply_speed_change is 'off' (default)
--      - Add an adjust-speed message to every speed change binding like so:
--
--          } multiply speed 2; script-message-to skipsilence adjust-speed multiply 2
--          ] add speed 0.1; script-message-to skipsilence adjust-speed add 0.1
--          X set speed 1; script-message-to skipsilence adjust-speed set 1
--
--      This is designed such that these bindings still work without
--      skipsilence being loaded.
--
-- User-data (mpv 0.36 and above):
--
-- user-data/skipsilence/enabled
--      true/false according to enabled state
-- user-data/skipsilence/base_speed
--      the original playback speed. Only updated while the script is enabled.
-- user-data/skipsilence/info
--      the current info according to the infostyle option
-- user-data/skipsilence/saved_total
--      the total time saved in seconds
--
-- These allow showing the state in osd like this:
--
--      osd-msg3=...${?user-data/skipsilence/enabled==true:S}...${user-data/skipsilence/info}
--
-- This shows "S" when skipsilence is enabled and shows the selected infostyle
-- in the next lines (infostyle=compact recommended).
--
-- Configuration:
--
-- For how to use these options, search the mpv man page for 'script-opts',
-- 'change-list', 'Key/value list options', and 'Configuration' for the
-- 'script-opts/osc.conf' documentation.
-- Use the prefix 'skipsilence' (unless the script was renamed).
local opts = {
    -- Whether skipsilence should be enabled by default. Can also be changed
    -- at runtime and reflects the current enabled state.
    enabled = true,

    -- The silence threshold in decibel. Anything quieter than this is
    -- detected as silence. Can be adjusted with the threshold-up,
    -- threshold-down bindings, and adjust-threshold-db script message.
    threshold_db = -25,
    -- Minimum duration of silence to be detected, in seconds. This is
    -- measured in seconds of stream time, as if playback speed was 1.
    threshold_duration = 0.05,
    -- How long to wait before speedup. This is measured in seconds of real
    -- time, thus higher playback speeds would reduce the length of content
    -- skipped.
    --
    -- Ignored while `lookahead` is used. Use `margin_start` instead.
    startdelay = 0.00,

    -- How long to look ahead to allow slowing down ahead of end of silence.
    --
    -- EXPERIMENTAL: Enabling this completely changes internal timing logic. It
    -- may be less reliable than operation without lookahead.
    --
    -- Low values (~0.2s) tend to make filter adjustments (threshold_*) more
    -- jarring because of skipped audio. Higher values (~1.0s) cause a seek
    -- event instead, which may be less problematic. Do not set this too high,
    -- as it introduces additional buffering and could reduce timing precision.
    --
    -- Recommended values are between 0.5 and 1.0.
    --
    -- Option filter_persistent should be enabled for seamless toggling of the
    -- script.
    lookahead = 0,

    -- EXPERIMENTAL: For lookahead: Extra margin at start and end of detected
    -- silence. `margin_start` delays speed-up, `margin_end` slows down
    -- earlier, by the specified time.
    --
    -- Measured in seconds of stream time. Negative values are allowed, having
    -- the opposite effect.
    --
    -- Requires lookahead to be active. Maximum backwards adjustment is limited
    -- by the lookahead period (positive `margin_end` or negative
    -- `margin_start`).
    margin_start = 0.05,
    margin_end = 0,

    -- EXPERIMENTAL: For lookahead: minimum length of silence for speed to be
    -- increased. This is a way to extend `threshold_duration` without needing
    -- to update the filter.
    --
    -- Increases the required duration of silence, without delaying the
    -- starting point like startdelay (by up to the lookahead duration).
    -- Measured in seconds of stream time.
    minduration = 0,

    -- How often to update the speed during silence, in seconds of real time.
    speed_updateinterval = 0.05,
    -- The maximum playback speed during silence.
    speed_max = 16,

    -- Speedup ramp parameters. The formula for playback speedup is:
    --
    --     ramp_constant + (time * ramp_factor) ^ ramp_exponent
    --
    -- Where time is the real time in seconds passed since start of speedup.
    -- The result is multiplied with the original playback speed.
    --
    -- - ramp_constant should always be greater or equal to one, otherwise it
    --   will slow down at the start of silence.
    -- - Setting ramp_factor to 0 disables the ramp, resulting in a constant
    --   speed during silence.
    -- - ramp_exponent is the "acceleration" of the curve. A value of 1
    --   results in a linear curve, values above 1 increase the speed faster
    --   the more time has passed, while values below 1 speed up at
    --   decreasing intervals.
    ramp_constant = 4.25,
    ramp_factor = 2.5,
    ramp_exponent = 3,

    -- EXPERIMENTAL: Same as ramp_* options, but for slowdown when using
    -- lookahead. 'time' is the remaining time to the end of silence.
    -- Note this is measured in stream time, different from the ramp_*
    -- options, which use real time. Choose a lower exponent to compensate.
    --
    -- While slowdown ramp is active, always the lower speed calculated by the
    -- two ramps is used.
    slowdown_ramp_constant = 1,
    slowdown_ramp_factor = 3,
    slowdown_ramp_exponent = 0.6,

    -- Noise reduction filter configuration.
    --
    -- This allows removing noise from the audio stream before the
    -- silencedetect filter, allowing to speed up pauses in speech despite
    -- background noise. The output audio is unaffected by default.
    --
    -- Whether the detected audio signal should be preprocessed with arnndn.
    -- If arnndn_modelpath is empty, this has no effect
    arnndn_enable = true,
    -- Path to the rnnn file containing the model parameters. If empty,
    -- noise reduction is disabled.
    -- The value is expanded with the expand-path command. See "Paths" in the
    -- mpv manual.
    -- Avoid special characters in this option, they must be escaped to
    -- work with "af add lavfi=[arnndn='...']".
    arnndn_modelpath = "",
    -- Whether the denoised signal should be used as the output. Disabled by
    -- default, so the output is unaffected.
    arnndn_output = false,

    -- If >= 0, use this value instead of a playback speed of 1.
    -- This is a work around to stop audio clicks when switching between
    -- normal playback and speeding up. Playing back at a slightly different
    -- speed (e.g. 1.01x), keeps the scaletempo2 filter active, so audio is
    -- played back without interruptions.
    alt_normal_speed = -1,

    -- Workaround for audio-video de-synchronization with scaletempo2 in
    -- mpv 0.36 and below. When disabling skipsilence, fix audio sync if this
    -- many frames have been dropped since the last playback restart
    -- (seek, etc.). Disabled if value is less than 0.
    --
    -- When disabling skipsilence while frame-drop-count is greater or equal
    -- to configured value, audio-video sync is fixed by running
    -- 'seek 0 exact'. May produce a short pause and/or audio repeat.
    --
    -- Note that frame-drop-count does not exactly correspond to the
    -- audio-video desynchronization. It is used as a heuristic to avoid
    -- resyncing every time the script is disabled. Recommended value: 100.
    resync_threshold_droppedframes = -1,

    -- Keep the filter added while the script is disabled. This prevents
    -- most audio interruptions/clicks when toggling the script.
    -- If arnndn_output is enabled, noise reduction also stays active while
    -- the script is disabled.
    filter_persistent = false,

    -- Info style used for the 'user-data/skipsilence/info' property and
    -- the default of the 'info' script-message/binding.
    -- May be one of
    -- - 'off' (no information),
    -- - 'total' (show total saved time),
    -- - 'compact' (show total and latest saved time),
    -- - 'verbose' (show most information).
    infostyle = "off",

    -- When to reset the total saved time.
    -- May be one of
    -- - 'file-start' (when a new file starts)
    -- - 'never' (do not reset total)
    reset_total = "file-start",

    -- How to apply external speed change during silence.
    -- This makes speed change bindings work during fast forward. Set the
    -- value according to what command you use to change speed:
    -- - 'add' - add the difference to the normal speed
    -- - 'multiply' - multiply the normal speed with factor of change
    -- If 'off', the script will override the speed during silence.
    -- Note: this option is unreliable in cases where the script changes speed
    -- at the exact same time. Prefer the adjust-speed message instead.
    apply_speed_change = "off",

    debug = false,
}

local is_enabled = false
local base_speed = 1
local is_silent = false
local is_filter_added = false
local filter_lookahead = 0
local filter_threshold_duration = 0
local expected_speed = 1
local last_speed_change_time = -1
local filter_reapply_time = -1
local is_paused = false
local total_saved_time = 0

local latest_speed = 1
local filter_restarted = false
local filter_restart_time_pos = nil
local input_ref_pts = nil
local input_ref_time = 0
local input_ref_pause_time = nil

local events_ifirst = 1
local events_ilast = 0
local events = {}

local check_time_timer = nil
local reapply_filter_timer = nil

local detect_filter_label = mp.get_script_name() .. "_silencedetect"

local function dprint(...)
    if opts.debug then
        print(("%.3f"):format(mp.get_time()), ...)
    end
end

-- like math.min with 2 args, but ignore nil
local function take_lower(a, b)
    if not a then return b end
    if not b then return a end
    if a < b then return a end
    return b
end

-- Get current detection filter input pts.
-- Precondition: requires `input_ref_pts` to be set.
local function get_input_pts(opt_now)
    local now = input_ref_pause_time or opt_now or mp.get_time()
    return input_ref_pts + (now - input_ref_time) * latest_speed
end

-- Estimate input time based on time-pos.
-- This is needed to cover the initial filter period of lookahead length,
-- because these events arrive before playback starts.
local function estimate_input_time(now)
    local time_pos = mp.get_property_number("time-pos")
    if time_pos then
        local buff = mp.get_property_number("audio-buffer", 0.2)
        input_ref_pts = time_pos + buff * latest_speed + filter_lookahead
        input_ref_time = now
        filter_restart_time_pos = input_ref_pts
        if is_paused then
            input_ref_pause_time = now
        end
        dprint("estimated input time:", input_ref_pts)
    else
        -- wait for core-idle false to estimate time
        filter_restarted = true
        filter_restart_time_pos = nil
    end
end

local function get_silence_filter()
    local filter = "silencedetect=n="..opts.threshold_db.."dB:d="..opts.threshold_duration
    local branch_detection = false
    local split_prefix = ""

    if opts.arnndn_enable and opts.arnndn_modelpath ~= "" then
        local path = mp.command_native{"expand-path", opts.arnndn_modelpath}
        local rnn = "arnndn='"..path.."',"

        if opts.lookahead > 0 and opts.arnndn_output then
            split_prefix = rnn
        else
            filter = rnn..filter
            -- arnndn requires 48kHz float; request it before asplit so amix
            -- does not require a second conversion for original audio
            split_prefix = "aformat=f=fltp:r=48000,"
            if not opts.arnndn_output then
                branch_detection = true
            end
        end
    end

    if opts.lookahead > 0 then
        -- Cut off beginning of audio after silencedetect filter. This causes
        -- detection to run ahead of the current audio playback.
        filter = filter..",asetpts=PTS-STARTPTS,atrim=start="..opts.lookahead
        branch_detection = true
        -- amix ends output early by the lookahead amount. Pad input with
        -- silence to fix this.
        split_prefix = split_prefix.."apad=pad_dur="..opts.lookahead..","
    end

    if branch_detection then
        -- need amix to keep the detection filter branch advancing with
        -- the playback stream. Weights only keep the original audio.
        --
        -- Parameter "duration" doesn't seem to affect output cutoff problem
        -- with lookahead. Explicit duration=shortest chosen that ought to
        -- resemble the required behavior for the workaround.
        filter = split_prefix.."asplit[ao],"..filter..",[ao]amix='weights=1 0':normalize=0:duration=shortest"
    end

    return "@"..detect_filter_label..":lavfi=["..filter.."]"
end

local function clear_events()
    events_ifirst = 1
    events_ilast = 0
    events = {}
end

local function drop_event()
    local i = events_ifirst
    assert(i <= events_ilast, "event list is empty")
    events[i] = nil
    events_ifirst = i + 1
end

local function drop_last_event()
    local i = events_ilast
    assert(i >= events_ifirst, "event list is empty")
    events[i] = nil
    events_ilast = i - 1
end

local speed_stats
local function stats_clear()
    speed_stats = {
        saved_current = 0,
        period_current = 0,
        silence_start_time = 0,
        time = nil,
        speed = 1,
        pause_start_time = nil,
    }
end
stats_clear()

local function get_saved_time(now)
    local s = speed_stats
    if not s.time then
        return s.saved_current, s.period_current
    end
    local period = (s.pause_start_time or now) - s.time
    local period_orig = period * s.speed / base_speed
    local saved = period_orig - period
    -- avoid negative value caused by float precision
    if saved > -0.001 and saved <= 0 then saved = 0 end
    return s.saved_current + saved, s.period_current + period_orig
end

local function stats_accumulate(now, speed)
    local s = speed_stats
    s.saved_current, s.period_current = get_saved_time(now)
    s.time = s.pause_start_time or now
    s.speed = speed
end

local function stats_start_current(now, speed)
    local s = speed_stats
    s.saved_current = 0
    s.period_current = 0
    s.silence_start_time = s.pause_start_time or now
    s.time = s.pause_start_time or now
    s.speed = speed
end

local function stats_end_current(now)
    local s = speed_stats
    stats_accumulate(now, s.speed)
    total_saved_time = total_saved_time + s.saved_current
    s.silence_start_time = nil
    s.time = nil
end

local function stats_handle_pause(now, pause)
    local s = speed_stats
    if pause then
        if not s.pause_start_time then
            s.pause_start_time = now
        end
    else
        if s.pause_start_time and is_silent then
            local pause_delta = now - s.pause_start_time
            s.silence_start_time = s.silence_start_time + pause_delta
            s.time = s.time + pause_delta
        end
        s.pause_start_time = nil
    end
end

local function stats_silence_length(now)
    local s = speed_stats
    return (s.pause_start_time or now) - s.silence_start_time
end

local function get_current_stats(now)
    local s = speed_stats
    local saved, period_current = get_saved_time(now)
    local saved_total = total_saved_time + (s.time and saved or 0)
    return saved_total, period_current, saved
end

local function format_info(style, saved_total, period_current, saved)
    if style == "total" then
        return ("Saved total: %.3fs"):format(saved_total)
    end

    local s_stats = ("Saved total: %.3fs\nLatest: %.3fs, %.3fs saved")
        :format(saved_total, period_current, saved)
    if style == "compact" then
        return s_stats
    end

    local s_threshold, s_lookahead
    if filter_lookahead > 0 then
        s_threshold = ("Threshold: %gdB, %gs (min: %gs)\n")
                :format(opts.threshold_db, opts.threshold_duration, opts.minduration)
            ..("Margin start: %gs, End: %gs\n")
                :format(opts.margin_start, opts.margin_end)
        s_lookahead = ("Lookahead: %gs\n")
                :format(filter_lookahead)
            ..("Slowdown ramp: %g + (time * %g) ^ %g\n")
                :format(opts.slowdown_ramp_constant, opts.slowdown_ramp_factor, opts.slowdown_ramp_exponent)
    else
        s_threshold = ("Threshold: %+gdB, %gs (+%gs)\n")
            :format(opts.threshold_db, opts.threshold_duration, opts.startdelay)
        s_lookahead = ""
    end

    return "Status: "..(is_enabled and "enabled" or "disabled").."\n"
        ..s_threshold
        .."Arnndn: "..(opts.arnndn_enable and opts.arnndn_modelpath ~= ""
                        and "enabled"..(opts.arnndn_output and " with output" or "") or "disabled").."\n"
        ..("Speedup ramp: %g + (time * %g) ^ %g\n")
            :format(opts.ramp_constant, opts.ramp_factor, opts.ramp_exponent)
        ..s_lookahead
        ..("Max speed: %gx, Update interval: %gs\n")
            :format(opts.speed_max, opts.speed_updateinterval)
        ..s_stats
end

local function update_info(opt_now)
    local now = opt_now or mp.get_time()
    local saved_total, period_current, saved = get_current_stats(now)
    mp.set_property("user-data/skipsilence/saved_total", ("%.3f"):format(saved_total))
    if opts.infostyle == "total" or opts.infostyle == "compact" or opts.infostyle == "verbose" then
        local s = speed_stats
        if (opts.infostyle == "total" or opts.infostyle == "compact")
            and saved_total + s.saved_current == 0 and s.time == nil then
            return false
        end
        local text = format_info(opts.infostyle, saved_total, period_current, saved)
        mp.set_property("user-data/skipsilence/info", "\n"..text)
        return true
    end
    return false
end

local function update_info_now(opt_now)
    if not update_info(opt_now) then
        mp.set_property("user-data/skipsilence/info", "")
    end
end

local update_info_timer = nil
local function schedule_update_info(opt_now)
    if is_enabled and not is_paused and is_silent then
        if not update_info_timer then
            -- long fractional part to prevent stats digits from lining up
            -- with update interval
            update_info_timer = mp.add_periodic_timer(0.0217, update_info)
        else
            update_info_timer:resume()
        end
    else
        if update_info_timer then
            update_info_timer:kill()
        end
    end
    update_info_now(opt_now)
end

local function set_base_speed(speed)
    base_speed = speed
    mp.set_property_number("user-data/skipsilence/base_speed", speed)
end

local function update_filter_opts()
    filter_lookahead = opts.lookahead
    filter_threshold_duration = opts.threshold_duration
end

local function reapply_filter()
    -- debounce with timer to avoid disrupting playback with repeated calls
    if reapply_filter_timer then
        reapply_filter_timer:kill()
    end
    reapply_filter_timer = mp.add_timeout(0.4, function()
        dprint("reapply filter")
        clear_events()

        local now = mp.get_time()
        -- remember last time filters were changed. Used to preserve
        -- silence state when changing options in some cases.
        -- Note: lookahead tends to case a backwards seek event on filter
        -- change, which prevents handling this.
        filter_reapply_time = now

        mp.commandv("af", "pre", get_silence_filter())
        update_filter_opts()
        update_info_now(now)
        estimate_input_time(now)
    end)
end

local function clear_silence_state()
    if is_silent then
        stats_end_current(mp.get_time())
        expected_speed = base_speed
        mp.set_property_number("speed", base_speed)
    end
    clear_events()
    is_silent = false
    input_ref_pts = nil
    input_ref_time = nil
    input_ref_pause_time = nil
    if check_time_timer ~= nil then
        check_time_timer:kill()
    end
end

local schedule_check_time -- function
local function check_time()
    local now = mp.get_time()
    local input_pts = nil
    local prev_speed = mp.get_property_number("speed")

    local new_speed = prev_speed
    local did_change = false
    local was_silent = is_silent
    local next_delay = nil
    local next_delay_pts = nil

    local index_current = events_ifirst

    for index = events_ifirst, events_ilast do
        local ev = events[index]

        if filter_lookahead > 0 then
            -- calc time based on pts while lookahead
            if not input_pts then
                input_pts = get_input_pts(now)
            end

            local offset
            if ev.is_silent then
                offset = opts.margin_start
            else
                offset = -opts.margin_end
            end
            local remaining_pts = offset + (ev.pts - input_pts) + filter_lookahead

            if ev.is_silent and opts.minduration > 0 and not events[index+1] then
                remaining_pts = math.max(remaining_pts,
                    ev.pts + opts.minduration - input_pts)
            end

            dprint("input_pts:", input_pts, "ev.pts:", ev.pts, "remaining:", remaining_pts)
            if remaining_pts > 0 then
                next_delay_pts = remaining_pts
                break
            end
        else
            local remaining = 0
            if ev.is_silent ~= was_silent then
                if ev.is_silent then
                    remaining = opts.startdelay - (now - ev.recv_time)
                else
                    -- events on filter reapply:
                    -- 1. filters removed and added
                    -- 2. (if silent)
                    --    silence end message
                    -- 3. (if still silent for new filter)
                    --    silence start message
                    --
                    -- wait before stopping the gap after reapply to preserve
                    -- speed if playback is still silent
                    remaining = 0.05 - (now - ev.filter_cleanup_time)
                end
            end
            if remaining > 0 and not events[index+1] then
                dprint("recheck in", remaining)
                next_delay = remaining
                break
            end
        end

        if ev.is_silent ~= is_silent then
            is_silent = ev.is_silent
            did_change = true
            ev.current = true
        end
        index_current = index
    end

    -- drop outdated events
    for _ = events_ifirst, index_current-1 do
        drop_event()
    end

    if did_change then
        if was_silent then
            stats_end_current(now)

            dprint("silence end, saved:", get_saved_time(now, prev_speed))
            new_speed = base_speed
        end
        if is_silent then
            stats_start_current(now, new_speed)
            dprint("silence start")

            if not was_silent then
                local new_base_speed = prev_speed
                if opts.alt_normal_speed >= 0 and math.abs(prev_speed - 1) < 0.001 then
                    new_base_speed = opts.alt_normal_speed
                    new_speed = new_base_speed
                end
                if new_base_speed ~= base_speed then
                    set_base_speed(new_base_speed)
                end
            end
            last_speed_change_time = -1
        end
        schedule_update_info(now)
    end
    if is_silent then
        local remaining = opts.speed_updateinterval - (now - last_speed_change_time)
        if remaining > 0 then
            dprint("last speed change too recent; recheck in", remaining)
            next_delay = take_lower(next_delay, remaining)
        else
            local s = base_speed * (opts.ramp_constant
                + (stats_silence_length(now) * opts.ramp_factor) ^ opts.ramp_exponent)
            if next_delay_pts then
                s = math.min(s, base_speed * (opts.slowdown_ramp_constant
                    + (next_delay_pts * opts.slowdown_ramp_factor) ^ opts.slowdown_ramp_exponent))
            end
            if next_delay_pts or s <= opts.speed_max or new_speed ~= opts.speed_max then
                new_speed = math.min(s, opts.speed_max)
                last_speed_change_time = now
                if next_delay_pts or new_speed ~= opts.speed_max then
                    next_delay = take_lower(next_delay, opts.speed_updateinterval)
                end
            end
        end
    end
    if new_speed ~= prev_speed then
        expected_speed = new_speed
        mp.set_property_number("speed", new_speed)
    end
    if next_delay_pts then
        next_delay = take_lower(next_delay, next_delay_pts / new_speed)
    end
    if next_delay then
        schedule_check_time(next_delay)
    end
    dprint("check_time: new_speed:", new_speed, "is_silent:", is_silent, "next_delay:", next_delay, "next_delay_pts:", next_delay_pts)
end

function schedule_check_time(time)
    -- no scheduling while paused; will check on resume
    if is_paused then return end
    if check_time_timer == nil then
        check_time_timer = mp.add_timeout(time, check_time)
    else
        check_time_timer:kill()
        check_time_timer.timeout = time
        check_time_timer:resume()
    end
end

local function handle_pause(name, paused)
    dprint("handle_pause", name, paused)
    is_paused = paused
    local now = mp.get_time()
    if input_ref_pts then
        if paused then
            if not input_ref_pause_time then
                input_ref_pause_time = now
            end
        elseif input_ref_pause_time then
            local delta = now - input_ref_pause_time
            input_ref_time = input_ref_time + delta
            input_ref_pause_time = nil
        end
    end

    if filter_lookahead > 0 and not paused and filter_restarted then
        filter_restarted = false
        estimate_input_time(now)
    end

    stats_handle_pause(now, paused)
    if is_enabled then
        if paused then
            if check_time_timer then
                check_time_timer:kill()
            end
        else
            check_time()
        end
        schedule_update_info(now)
    end
end

local function handle_speed(_, speed)
    dprint("handle_speed", speed)
    local time = nil
    if input_ref_pts ~= nil then
        time = mp.get_time()
        input_ref_pts = get_input_pts(time)
        input_ref_time = input_ref_pause_time or time
    end
    latest_speed = speed
    if is_silent then
        time = time or mp.get_time()
        stats_accumulate(time, speed)
    end

    if is_enabled and math.abs(speed - expected_speed) > 0.01 then
        local do_check = false
        dprint("handle_speed: external speed change: got", speed, "instead of", expected_speed)
        if is_silent then
            if opts.apply_speed_change == "add" then
                set_base_speed(base_speed + speed - expected_speed)
                do_check = true
            elseif opts.apply_speed_change == "multiply" then
                set_base_speed(base_speed * speed / expected_speed)
                do_check = true
            end
        else
            set_base_speed(speed)
        end
        expected_speed = speed
        if do_check then
            last_speed_change_time = -1
            check_time()
        end
    end
end

local function add_event(silent, pts)
    local prev = events[events_ilast]

    -- After reapply_filter, events can arrive late from the removed filter.
    -- Workaround: remove all events when there is a jump back.
    if prev and prev.pts > pts then
        clear_events()
        prev = nil
    end

    if not prev or silent ~= prev.is_silent then
        local time = mp.get_time()
        if not filter_restart_time_pos or pts >= filter_restart_time_pos then
            if silent then
                -- start message reports start of silence, so current pts is
                -- after threshold duration
                input_ref_pts = pts + filter_threshold_duration
            else
                input_ref_pts = pts
            end
            input_ref_time = time
            if is_paused then
                input_ref_pause_time = time
            end
        end

        if filter_lookahead and not silent and prev and not prev.current then
            if pts - prev.pts < opts.minduration then
                -- ignore too short silence
                drop_last_event()
                return
            end
        end

        local i = events_ilast + 1
        events[i] = {
            recv_time = time,
            is_silent = silent,
            filter_cleanup_time = filter_reapply_time,
            pts = pts,
        }
        events_ilast = i
        if not is_paused and is_enabled then
            check_time()
        end
    end
    if not is_enabled then
        -- remove outdated events: keep the newest event in the past relative
        -- to input time
        local input_pts = pts
        if filter_lookahead > 0 then
            input_pts = input_pts - filter_lookahead
        end
        for i = events_ifirst+1, events_ilast-1 do
            if events[i].pts > input_pts then
                drop_event()
            end
        end
    end
end

-- example messages:
-- [ffmpeg] silencedetect: silence_start: 6.07669
-- [ffmpeg] silencedetect: silence_end: 7.06427 | silence_duration: 0.987583
local function handle_silence_msg(msg)
    if msg.prefix ~= "ffmpeg" then return end
    -- find without pattern is significantly faster; jump out fast
    if msg.text:find("silencedetect: silence_", 1, true) ~= 1 then return end

    local startend, pts =
        msg.text:match("^silencedetect: silence_(%a+): ([0-9%.]+)")
    pts = tonumber(pts)
    if startend == "start" and pts then
        filter_reapply_time = -1
        dprint("got silence start message", pts)
        add_event(true, pts)
    elseif startend == "end" and pts then
        dprint("got silence end message", pts)
        add_event(false, pts)
    else
        dprint("invalid match:", msg.text)
    end
end

local function set_option(opt_name, value)
    mp.commandv("change-list", "script-opts", "append",
        mp.get_script_name().."-"..opt_name.."="..value)
end

local function adjust_thresholdDB(change)
    local value = opts.threshold_db + change
    set_option("threshold_db", tostring(value))
    mp.osd_message("silence threshold: "..value.."dB")
end

local function adjust_speed(method, number_str)
    local number = tonumber(number_str)
    if method ~= "add" and method ~= "multiply" and method ~= "set" or not number then
        mp.msg.error("invalid arguments; usage: adjust-speed add|multiply|set <number>")
        return
    end

    if is_silent then
        if method == "add" then
            set_base_speed(base_speed + number)
        elseif method == "multiply" then
            set_base_speed(base_speed * number)
        elseif method == "set" then
            set_base_speed(number)
        end
        last_speed_change_time = -1
        check_time()
    end
end

local function toggle_option(opt_name)
    local value = not opts[opt_name]
    local str = value and "yes" or "no"
    set_option(opt_name, str)
    mp.osd_message(mp.get_script_name().."-"..opt_name..": "..str)
end

local function cycle_info_style(style)
    local value = style or (
        opts.infostyle == "total" and "compact" or (
        opts.infostyle == "compact" and "verbose" or (
        opts.infostyle == "verbose" and "off" or "total")))
    set_option("infostyle", value)
    mp.osd_message(mp.get_script_name().."-infostyle: "..value)
end

-- called regardless of enabled state
local function handle_start_file()
    dprint("handle_start_file")
    clear_silence_state()
    filter_restarted = true
    filter_restart_time_pos = nil
    stats_clear()
    if opts.reset_total == "file-start" then
        total_saved_time = 0
    end
    update_info_now()
end

-- events on seek:
-- 1. seek event
-- 2. core-idle=true
-- 3. seeking=true
-- 4. (if target is silent) silence start msg
-- 5. playback-restart event
-- 6. core-idle=false
-- 7. seeking=false
local function handle_seek()
    dprint("handle_seek")
    clear_silence_state()
    filter_restarted = true
    filter_restart_time_pos = nil
end

local function insert_detect_filter()
    if not is_filter_added then
        -- if filter was added externally, silence start messages are
        -- missed; ensure it's removed first
        if mp.get_property("af"):find("@"..detect_filter_label..":[^!]") then
            -- replace with disabled anull to preserve filter position
            mp.commandv("af", "pre", "@"..detect_filter_label..":!anull")
        end
    end
    mp.commandv("af", "pre", get_silence_filter())

    if not mp.get_property("af"):find("@"..detect_filter_label..":", 1, true) then
        return false
    end
    update_filter_opts()

    if not is_filter_added then
        mp.register_event("seek", handle_seek)
        mp.register_event("log-message", handle_silence_msg)
        mp.observe_property("speed", "number", handle_speed)
        mp.observe_property("core-idle", "bool", handle_pause)
    end
    is_filter_added = true
    estimate_input_time(mp.get_time())
    return true
end

local function remove_detect_filter()
    if reapply_filter_timer then
        reapply_filter_timer:kill()
    end
    mp.unregister_event(handle_seek)
    mp.unregister_event(handle_silence_msg)
    mp.unobserve_property(handle_speed)
    mp.unobserve_property(handle_pause)
    -- replace with disabled anull to preserve filter position
    mp.commandv("af", "pre", "@"..detect_filter_label..":!anull")
    is_filter_added = false
    clear_events()
end

local function enable(flag)
    local no_osd = flag == "no-osd"

    if not is_enabled then
        if not insert_detect_filter() then
            if opts.enabled then set_option("enabled", "no") end
            mp.osd_message("skipsilence enable failed: see console output")
            return
        end
        is_enabled = true
        if not no_osd then
            mp.osd_message("skipsilence enabled")
        end
        set_base_speed(mp.get_property_number("speed"))

        check_time()
    end

    set_option("enabled", "yes")
    mp.set_property_bool("user-data/skipsilence/enabled", true)
end

local function disable(arg1, arg2)
    local no_osd = false
    local opt_base_speed = nil
    if arg1 == "no-osd" then
        no_osd = true
    else
        opt_base_speed = tonumber(arg1)
        if not opt_base_speed and arg1 then
            mp.msg.warn("invalid number:", arg1)
        end
        if arg2 == "no-osd" then
            no_osd = true
        end
    end

    if check_time_timer then
        check_time_timer:kill()
    end

    if is_enabled then
        if not opts.filter_persistent then
            remove_detect_filter()
        end

        if opt_base_speed then
            mp.set_property_number("speed", opt_base_speed)
        else
            local speed = is_silent and base_speed or mp.get_property_number("speed")
            if opts.alt_normal_speed and math.abs(speed - opts.alt_normal_speed) < 0.001 then
                mp.set_property_number("speed", 1)
            elseif is_silent then
                mp.set_property_number("speed", speed)
            end
        end

        if is_silent then
            stats_end_current(mp.get_time())
        end
        is_silent = false
        is_enabled = false
        schedule_update_info()
        if not no_osd then
            mp.osd_message("skipsilence disabled")
        end

        if opts.resync_threshold_droppedframes >= 0 then
            local drops = mp.get_property_number("frame-drop-count")
            if drops and drops >= opts.resync_threshold_droppedframes then
                mp.commandv("seek", "0", "exact")
            end
        end
    end

    if opts.enabled then set_option("enabled", "no") end
    mp.set_property_bool("user-data/skipsilence/enabled", false)
end

local function toggle(flag)
    local arg
    if flag == "no-osd" then
        arg = "no-osd"
    end
    if is_enabled then
        disable(arg)
    else
        enable(arg)
    end
end

local function info(style)
    mp.osd_message(format_info(
        style or opts.infostyle,
        get_current_stats(mp.get_time())))
end

local function reset_total_saved_time()
    total_saved_time = 0
    update_info_now()
end

(require "mp.options").read_options(opts, nil, function(list)
    if list["enabled"] and not opts.enabled and is_enabled then
        disable("no-osd")
    end
    if list["threshold_db"] or list["threshold_duration"] or list["lookahead"]
        or list["arnndn_enable"] or list["arnndn_modelpath"]
        or list["arnndn_output"] then
        if is_filter_added then
            reapply_filter()
        else
            update_filter_opts()
        end
    end
    if list["ramp_constant"] or list["ramp_factor"] or list["ramp_exponent"]
        or list["slowdown_ramp_constant"] or list["slowdown_ramp_factor"]
        or list["slowdown_ramp_exponent"] or list["minduration"]
        or list["startdelay"] or list["margin_start"] or list["margin_end"]
        or list["speed_updateinterval"] or list["speed_max"] then
        if is_enabled then
            check_time()
        end
        update_info_now()
    elseif list["infostyle"] then
        update_info_now()
    end
    if list["filter_persistent"] then
        if not opts.filter_persistent and not is_enabled and is_filter_added then
            remove_detect_filter()
        end
    end
    if list["enabled"] and opts.enabled and not is_enabled then
        enable("no-osd")
    end
end)

mp.enable_messages("v")
mp.add_key_binding(nil, "enable", enable)
mp.add_key_binding(nil, "disable", disable)
mp.add_key_binding("F2", "toggle", toggle)
mp.register_script_message("adjust-threshold-db", adjust_thresholdDB)
mp.add_key_binding("F3", "threshold-down", function() adjust_thresholdDB(-1) end, "repeatable")
mp.add_key_binding("F4", "threshold-up", function() adjust_thresholdDB(1) end, "repeatable")
mp.register_script_message("adjust-speed", adjust_speed, "repeatable")
mp.add_key_binding(nil, "info", info, "repeatable")
mp.add_key_binding(nil, "cycle-info-style", cycle_info_style)
mp.add_key_binding(nil, "reset-total", reset_total_saved_time)
mp.add_key_binding(nil, "toggle-arnndn", function() toggle_option("arnndn_enable") end)
mp.add_key_binding(nil, "toggle-arnndn-output", function() toggle_option("arnndn_output") end)
mp.register_event("start-file", handle_start_file)

set_base_speed(1)

update_filter_opts()
update_info_now()
if opts.enabled then
    enable("no-osd")
end

-- vim:set sw=4 sts=0 et tw=0:

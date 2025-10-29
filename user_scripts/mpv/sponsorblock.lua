-- sponsorblock.lua
--
-- This script skips sponsored segments of YouTube videos
-- using data from https://github.com/ajayyy/SponsorBlock

local ON_WINDOWS = package.config:sub(1,1) ~= "/"

local options = {
    server_address = "https://sponsor.ajay.app",

    python_path = ON_WINDOWS and "python" or "python3",

    -- Categories to fetch
    categories = "sponsor,intro,outro,interaction,selfpromo,filler",

    -- Categories to skip automatically
    skip_categories = "sponsor",

    -- If true, sponsored segments will only be skipped once
    skip_once = true,

    -- Note that sponsored segments may ocasionally be inaccurate if this is turned off
    -- see https://blog.ajay.app/voting-and-pseudo-randomness-or-sponsorblock-or-youtube-sponsorship-segment-blocker
    local_database = false,

    -- Update database on first run, does nothing if local_database is false
    auto_update = true,

    -- How long to wait between local database updates
    -- Format: "X[d,h,m]", leave blank to update on every mpv run
    auto_update_interval = "6h",

    -- User ID used to submit sponsored segments, leave blank for random
    user_id = "",

    -- Name to display on the stats page https://sponsor.ajay.app/stats/ leave blank to keep current name
    display_name = "",

    -- Tell the server when a skip happens
    report_views = true,

    -- Auto upvote skipped sponsors
    auto_upvote = false,

    -- Use sponsor times from server if they're more up to date than our local database
    server_fallback = true,

    -- Create chapters at sponsor boundaries for OSC display and manual skipping
    make_chapters = true,

    -- Minimum duration for sponsors (in seconds), segments under that threshold will be ignored
    min_duration = 1,

    -- Fade audio for smoother transitions
    audio_fade = false,

    -- Audio fade step, applied once every 100ms until cap is reached
    audio_fade_step = 10,

    -- Audio fade cap
    audio_fade_cap = 0,

    -- Fast forward through sponsors instead of skipping
    fast_forward = false,

    -- Playback speed modifier when fast forwarding, applied once every second until cap is reached
    fast_forward_increase = .2,

    -- Playback speed cap
    fast_forward_cap = 2,

    -- Length of the sha256 prefix (3-32) when querying server, 0 to disable
    sha256_length = 4,

    -- Pattern for video id in local files, ignored if blank
    -- Recommended value for base youtube-dl is "-([%w-_]+)%.[mw][kpe][v4b]m?$"
    local_pattern = "",

    -- Legacy option, use skip_categories instead
    skip = true
}

mp.options = require "mp.options"
mp.options.read_options(options, "sponsorblock")

local legacy = mp.command_native_async == nil
--[[
if legacy then
    options.local_database = false
end
--]]
options.local_database = false

local utils = require "mp.utils"
scripts_dir = mp.find_config_file("scripts")

local sponsorblock = utils.join_path(scripts_dir, "sponsorblock_shared/sponsorblock.py")
local uid_path = utils.join_path(scripts_dir, "sponsorblock_shared/sponsorblock.txt")
local database_file = options.local_database and utils.join_path(scripts_dir, "sponsorblock_shared/sponsorblock.db") or ""
local youtube_id = nil
local ranges = {}
local init = false
local segment = {a = 0, b = 0, progress = 0, first = true}
local retrying = false
local last_skip = {uuid = "", dir = nil}
local speed_timer = nil
local fade_timer = nil
local fade_dir = nil
local volume_before = mp.get_property_number("volume")
local categories = {}
local all_categories = {"sponsor", "intro", "outro", "interaction", "selfpromo", "preview", "music_offtopic", "filler"}
local chapter_cache = {}

for category in string.gmatch(options.skip_categories, "([^,]+)") do
    categories[category] = true
end

function file_exists(name)
    local f = io.open(name,"r")
    if f ~= nil then io.close(f) return true else return false end
end

function t_count(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function time_sort(a, b)
    if a.time == b.time then
        return string.match(a.title, "segment end")
    end
    return a.time < b.time
end

function parse_update_interval()
    local s = options.auto_update_interval
    if s == "" then return 0 end -- Interval Disabled

    local num, mod = s:match "^(%d+)([hdm])$"

    if num == nil or mod == nil then
        mp.osd_message("[sponsorblock] auto_update_interval " .. s .. " is invalid", 5)
        return nil
    end

    local time_table = {
        m = 60,
        h = 60 * 60,
        d = 60 * 60 * 24,
    }

    return num * time_table[mod]
end

function clean_chapters()
    local chapters = mp.get_property_native("chapter-list")
    local new_chapters = {}
    for _, chapter in pairs(chapters) do
        if chapter.title ~= "Preview segment start" and chapter.title ~= "Preview segment end" then
            table.insert(new_chapters, chapter)
        end
    end
    mp.set_property_native("chapter-list", new_chapters)
end

function create_chapter(chapter_title, chapter_time)
    local chapters = mp.get_property_native("chapter-list")
    local duration = mp.get_property_native("duration")
    table.insert(chapters, {title=chapter_title, time=(duration == nil or duration > chapter_time) and chapter_time or duration - .001})
    table.sort(chapters, time_sort)
    mp.set_property_native("chapter-list", chapters)
end

function process(uuid, t, new_ranges)
    start_time = tonumber(string.match(t, "[^,]+"))
    end_time = tonumber(string.sub(string.match(t, ",[^,]+"), 2))
    for o_uuid, o_t in pairs(ranges) do
        if (start_time >= o_t.start_time and start_time <= o_t.end_time) or (o_t.start_time >= start_time and o_t.start_time <= end_time) then
            new_ranges[o_uuid] = o_t
            return
        end
    end
    category = string.match(t, "[^,]+$")
    if categories[category] and end_time - start_time >= options.min_duration then
        new_ranges[uuid] = {
            start_time = start_time,
            end_time = end_time,
            category = category,
            skipped = false
        }
    end
    if options.make_chapters and not chapter_cache[uuid] then
        chapter_cache[uuid] = true
        local category_title = (category:gsub("^%l", string.upper):gsub("_", " "))
        create_chapter(category_title .. " segment start (" .. string.sub(uuid, 1, 6) .. ")", start_time)
        create_chapter(category_title .. " segment end (" .. string.sub(uuid, 1, 6) .. ")", end_time)
    end
end

function getranges(_, exists, db, more)
    if type(exists) == "table" and exists["status"] == "1" then
        if options.server_fallback then
            mp.add_timeout(0, function() getranges(true, true, "") end)
        else
            return mp.osd_message("[sponsorblock] database update failed, gave up")
        end
    end
    if db ~= "" and db ~= database_file then db = database_file end
    if exists ~= true and not file_exists(db) then
        if not retrying then
            mp.osd_message("[sponsorblock] database update failed, retrying...")
            retrying = true
        end
        return update()
    end
    if retrying then
        mp.osd_message("[sponsorblock] database update succeeded")
        retrying = false
    end
    local sponsors
    local args = {
        options.python_path,
        sponsorblock,
        "ranges",
        db,
        options.server_address,
        youtube_id,
        options.categories,
        tostring(options.sha256_length)
    }
    if not legacy then
        sponsors = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
    else
        sponsors = utils.subprocess({args = args})
    end
    mp.msg.debug("Got: " .. string.gsub(sponsors.stdout, "[\n\r]", ""))
    if not string.match(sponsors.stdout, "^%s*(.*%S)") then return end
    if string.match(sponsors.stdout, "error") then return getranges(true, true) end
    local new_ranges = {}
    local r_count = 0
    if more then r_count = -1 end
    for t in string.gmatch(sponsors.stdout, "[^:%s]+") do
        uuid = string.match(t, "([^,]+),[^,]+$")
        if ranges[uuid] then
            new_ranges[uuid] = ranges[uuid]
        else
            process(uuid, t, new_ranges)
        end
        r_count = r_count + 1
    end
    local c_count = t_count(ranges)
    if c_count == 0 or r_count >= c_count then
        ranges = new_ranges
    end
end

function fast_forward()
    if options.fast_forward and options.fast_forward == true then
        speed_timer = nil
        mp.set_property("speed", 1)
    end
    local last_speed = mp.get_property_number("speed")
    local new_speed = math.min(last_speed + options.fast_forward_increase, options.fast_forward_cap)
    if new_speed <= last_speed then return end
    mp.set_property("speed", new_speed)
end

function fade_audio(step)
    local last_volume = mp.get_property_number("volume")
    local new_volume = math.max(options.audio_fade_cap, math.min(last_volume + step, volume_before))
    if new_volume == last_volume then
        if step >= 0 then fade_dir = nil end
        if fade_timer ~= nil then fade_timer:kill() end
        fade_timer = nil
        return
    end
    mp.set_property("volume", new_volume)
end

function skip_ads(name, pos)
    if pos == nil then return end
    local sponsor_ahead = false
    for uuid, t in pairs(ranges) do
        if (options.fast_forward == uuid or not options.skip_once or not t.skipped) and t.start_time <= pos and t.end_time > pos then
            if options.fast_forward == uuid then return end
            if options.fast_forward == false then
                mp.osd_message("[sponsorblock] " .. t.category .. " skipped")
                mp.set_property("time-pos", t.end_time)
            else
                mp.osd_message("[sponsorblock] skipping " .. t.category)
            end
            t.skipped = true
            last_skip = {uuid = uuid, dir = nil}
            if options.report_views or options.auto_upvote then
                local args = {
                    options.python_path,
                    sponsorblock,
                    "stats",
                    database_file,
                    options.server_address,
                    youtube_id,
                    uuid,
                    options.report_views and "1" or "",
                    uid_path,
                    options.user_id,
                    options.auto_upvote and "1" or ""
                }
                if not legacy then
                    mp.command_native_async({name = "subprocess", playback_only = false, args = args}, function () end)
                else
                    utils.subprocess_detached({args = args})
                end
            end
            if options.fast_forward ~= false then
                options.fast_forward = uuid
                if speed_timer ~= nil then speed_timer:kill() end
                speed_timer = mp.add_periodic_timer(1, fast_forward)
            end
            return
        elseif (not options.skip_once or not t.skipped) and t.start_time <= pos + 1 and t.end_time > pos + 1 then
            sponsor_ahead = true
        end
    end
    if options.audio_fade then
        if sponsor_ahead then
            if fade_dir ~= false then
                if fade_dir == nil then volume_before = mp.get_property_number("volume") end
                if fade_timer ~= nil then fade_timer:kill() end
                fade_dir = false
                fade_timer = mp.add_periodic_timer(.1, function() fade_audio(-options.audio_fade_step) end)
            end
        elseif fade_dir == false then
            fade_dir = true
            if fade_timer ~= nil then fade_timer:kill() end
            fade_timer = mp.add_periodic_timer(.1, function() fade_audio(options.audio_fade_step) end)
        end
    end
    if options.fast_forward and options.fast_forward ~= true then
        options.fast_forward = true
        speed_timer:kill()
        speed_timer = nil
        mp.set_property("speed", 1)
    end
end

function vote(dir)
    if last_skip.uuid == "" then return mp.osd_message("[sponsorblock] no sponsors skipped, can't submit vote") end
    local updown = dir == "1" and "up" or "down"
    if last_skip.dir == dir then return mp.osd_message("[sponsorblock] " .. updown .. "vote already submitted") end
    last_skip.dir = dir
    local args = {
        options.python_path,
        sponsorblock,
        "stats",
        database_file,
        options.server_address,
        youtube_id,
        last_skip.uuid,
        "",
        uid_path,
        options.user_id,
        dir
    }
    if not legacy then
        mp.command_native_async({name = "subprocess", playback_only = false, args = args}, function () end)
    else
        utils.subprocess({args = args})
    end
    mp.osd_message("[sponsorblock] " .. updown .. "vote submitted")
end

function update()
    mp.command_native_async({name = "subprocess", playback_only = false, args = {
        options.python_path,
        sponsorblock,
        "update",
        database_file,
        options.server_address
    }}, getranges)
end

function file_loaded()
    local initialized = init
    ranges = {}
    segment = {a = 0, b = 0, progress = 0, first = true}
    last_skip = {uuid = "", dir = nil}
    chapter_cache = {}
    local video_path = mp.get_property("path", "")
    mp.msg.debug("Path: " .. video_path)
    local video_referer = string.match(mp.get_property("http-header-fields", ""), "Referer:([^,]+)") or ""
    mp.msg.debug("Referer: " .. video_referer)

    local urls = {
        "ytdl://([%w-_]+).*",
        "https?://youtu%.be/([%w-_]+).*",
        "https?://w?w?w?%.?youtube%.com/v/([%w-_]+).*",
        "/watch.*[?&]v=([%w-_]+).*",
        "/embed/([%w-_]+).*"
    }
    youtube_id = nil
    for i, url in ipairs(urls) do 
        youtube_id = youtube_id or string.match(video_path, url) or string.match(video_referer, url)
        if youtube_id then break end
    end
    youtube_id = youtube_id or string.match(video_path, options.local_pattern)
    
    if not youtube_id or string.len(youtube_id) < 11 or (local_pattern and string.len(youtube_id) ~= 11) then return end
    youtube_id = string.sub(youtube_id, 1, 11)
    mp.msg.debug("Found YouTube ID: " .. youtube_id)
    init = true
    if not options.local_database then
        getranges(true, true)
    else
        local exists = file_exists(database_file)
        if exists and options.server_fallback then
            getranges(true, true)
            mp.add_timeout(0, function() getranges(true, true, "", true) end)
        elseif exists then
            getranges(true, true)
        elseif options.server_fallback then
            mp.add_timeout(0, function() getranges(true, true, "") end)
        end
    end
    if initialized then return end
    if options.skip then
        mp.observe_property("time-pos", "native", skip_ads)
    end
    if options.display_name ~= "" then
        local args = {
            options.python_path,
            sponsorblock,
            "username",
            database_file,
            options.server_address,
            youtube_id,
            "",
            "",
            uid_path,
            options.user_id,
            options.display_name
        }
        if not legacy then
            mp.command_native_async({name = "subprocess", playback_only = false, args = args}, function () end)
        else
            utils.subprocess_detached({args = args})
        end
    end
    if not options.local_database or (not options.auto_update and file_exists(database_file)) then return end

    if file_exists(database_file) then
        local db_info = utils.file_info(database_file)
        local cur_time = os.time(os.date("*t"))
        local upd_interval = parse_update_interval()
        if upd_interval == nil or os.difftime(cur_time, db_info.mtime) < upd_interval then return end
    end

    update()
end

function set_segment()
    if not youtube_id then return end
    local pos = mp.get_property_number("time-pos")
    if pos == nil then return end
    if segment.progress > 1 then
        segment.progress = segment.progress - 2
    end
    if segment.progress == 1 then
        segment.progress = 0
        segment.b = pos
        mp.osd_message("[sponsorblock] segment boundary B set, press again for boundary A", 3)
    else
        segment.progress = 1
        segment.a = pos
        mp.osd_message("[sponsorblock] segment boundary A set, press again for boundary B", 3)
    end
    if options.make_chapters and not segment.first then
        local start_time = math.min(segment.a, segment.b)
        local end_time = math.max(segment.a, segment.b)
        if end_time - start_time ~= 0 and end_time ~= 0 then
            clean_chapters()
            create_chapter("Preview segment start", start_time)
            create_chapter("Preview segment end", end_time)
        end
    end
    segment.first = false
end

function select_category(selected)
    for category in string.gmatch(options.categories, "([^,]+)") do
        mp.remove_key_binding("select_category_"..category)
        mp.remove_key_binding("kp_select_category_"..category)
    end
    submit_segment(selected)
end

function submit_segment(category)
    if not youtube_id then return end
    local start_time = math.min(segment.a, segment.b)
    local end_time = math.max(segment.a, segment.b)
    if end_time - start_time == 0 or end_time == 0 then
        mp.osd_message("[sponsorblock] empty segment, not submitting")
    elseif segment.progress <= 1 then
        segment.progress = segment.progress + 2
        local category_list = ""
        for category_id, category in pairs(all_categories) do
            local category_title = (category:gsub("^%l", string.upper):gsub("_", " "))
            category_list = category_list .. category_id .. ": " .. category_title .. "\n"
            mp.add_forced_key_binding(tostring(category_id), "select_category_"..category, function() select_category(category) end)
            mp.add_forced_key_binding("KP"..tostring(category_id), "kp_select_category_"..category, function() select_category(category) end)
        end
        mp.osd_message(string.format("[sponsorblock] press a number to select category for segment: %.2d:%.2d:%.2d to %.2d:%.2d:%.2d\n\n" .. category_list .. "\nyou can press Shift+G again for default (Sponsor) or hide this message with g", math.floor(start_time/(60*60)), math.floor(start_time/60%60), math.floor(start_time%60), math.floor(end_time/(60*60)), math.floor(end_time/60%60), math.floor(end_time%60)), 30)
    else
        mp.osd_message("[sponsorblock] submitting segment...", 30)
        local submit
        local args = {
            options.python_path,
            sponsorblock,
            "submit",
            database_file,
            options.server_address,
            youtube_id,
            tostring(start_time),
            tostring(end_time),
            uid_path,
            options.user_id,
            category or "sponsor"
        }
        if not legacy then
            submit = mp.command_native({name = "subprocess", capture_stdout = true, playback_only = false, args = args})
        else
            submit = utils.subprocess({args = args})
        end
        if string.match(submit.stdout, "success") then
            segment = {a = 0, b = 0, progress = 0, first = true}
            mp.osd_message("[sponsorblock] segment submitted")
            if options.make_chapters then
                clean_chapters()
                create_chapter("Submitted segment start", start_time)
                create_chapter("Submitted segment end", end_time)
            end
        elseif string.match(submit.stdout, "error") then
            mp.osd_message("[sponsorblock] segment submission failed, server may be down. try again", 5)
        elseif string.match(submit.stdout, "502") then
            mp.osd_message("[sponsorblock] segment submission failed, server is down. try again", 5)
        elseif string.match(submit.stdout, "400") then
            mp.osd_message("[sponsorblock] segment submission failed, impossible inputs", 5)
            segment = {a = 0, b = 0, progress = 0, first = true}
        elseif string.match(submit.stdout, "429") then
            mp.osd_message("[sponsorblock] segment submission failed, rate limited. try again", 5)
        elseif string.match(submit.stdout, "409") then
            mp.osd_message("[sponsorblock] segment already submitted", 3)
            segment = {a = 0, b = 0, progress = 0, first = true}
        else
            mp.osd_message("[sponsorblock] segment submission failed", 5)
        end
    end
end

mp.register_event("file-loaded", file_loaded)
mp.add_key_binding("g", "set_segment", set_segment)
mp.add_key_binding("G", "submit_segment", submit_segment)
mp.add_key_binding("h", "upvote_segment", function() return vote("1") end)
mp.add_key_binding("H", "downvote_segment", function() return vote("0") end)
-- Bindings below are for backwards compatibility and could be removed at any time
mp.add_key_binding(nil, "sponsorblock_set_segment", set_segment)
mp.add_key_binding(nil, "sponsorblock_submit_segment", submit_segment)
mp.add_key_binding(nil, "sponsorblock_upvote", function() return vote("1") end)
mp.add_key_binding(nil, "sponsorblock_downvote", function() return vote("0") end)

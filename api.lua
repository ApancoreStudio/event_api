event_api.registered_events = {}
event_api.active_events = {}

local os_time = os.time

local function call_if_function(var, ...)
	if type(var) == "function" then
		return var(...)
	end
	return var
end

function event_api.register_new_event(event, def)
	if not event or type(event) ~= "string" then
		minetest.log("error", "Event API: couldn't create a new event: the name of event is undefined")
	end

	local start = call_if_function(def.starting_date, event, "start") or {
		year = 2000,
		month = 1,
		day = 1,
		hour = 0,
		min = 0,
	}
	local finish = call_if_function(def.finishing_date, event, 	"finish") or {
		year = 2100,
		month = 1,
		day = 1,
		hour = 0,
		min = 0,
	}
	def.starting_date = start
	def.finishing_date = finish
	local desc = def.description or "Unnamed Event"
	local form = def.formspec or ""

	event_api.registered_events[event] = def
end


function event_api.get_date_from_conf(name, type)
	local setting_name = "event_"..name.."_"..type.."date"
	local date = minetest.settings:get(setting_name)
	if not date then
		minetest.log("warning", "Event API: no `"..setting_name.."` setting.")
		return nil
	end
	local year, month, day, hour, min = string.match(date, "(%d+)/(%d+)/(%d+) (%d+):(%d+)")
	local parsed_date = {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
	}
	return parsed_date
end

function event_api.seconds_to_general_date(time)
	local sec_in_year, sec_in_month, sec_in_day, sec_in_hour = 365*24*60*60, 30*24*60*60, 24*60*60, 60*60
	local years, years_mod = math.floor(time/sec_in_year), time%sec_in_year
	local months, months_mod = math.floor(years_mod/sec_in_month), years_mod%sec_in_month
	local days, days_mod = math.floor(months_mod/sec_in_day), months_mod%sec_in_day
	local hours, hours_mod = math.floor(days_mod/sec_in_hour), days_mod%sec_in_hour
	local minutes, minutes_mod = math.floor(hours_mod/60), hours_mod%60
	local seconds = math.floor(minutes_mod)

	return {
		years = years,
		months = months,
		days = days,
		hours = hours,
		minutes = minutes,
		seconds = seconds
	}
end

local function is_now_in_bounds(start, finish)
	local now = os_time()
	start = os_time(start)
	finish = os_time(finish)

	if start <= now and now < finish then
		return true
	end
	return false
end

function event_api.get_event_def(event)
	local def = event_api.registered_events[event]
	if not def then
		minetest.log("error", "Event API: an event with name `"..event.."` is undefined")
		return false
	end
	return def
end

function event_api.get_event_setting(event, setting)
	if not event_api.get_event_def(event) then
		minetest.log("error", "Event API: couldn't find the event definition for an event with name `"..event.."`")
		return nil
	end
	return event_api.get_event_def(event)[setting]
end

function event_api.show_event_formspec(playername, event)
	local form = event_api.get_event_setting(event, "formspec")
	if form and event_api.is_event_active(event) then
		minetest.show_formspec(playername, event.."_formspec", form)
	end
end

function event_api.is_event_active(event)
	local start = event_api.get_event_setting(event, "starting_date")
	local finish = event_api.get_event_setting(event, "finishing_date")
	if start and finish then
		return is_now_in_bounds(start, finish)
	end
	minetest.log("error", "Event API: couldn't find time bounds for an event with name `"..event.."`")
	return false
end

function event_api.update_active_events()
	event_api.active_events = {}
	for event in pair(event_api.registered_events) do
		if event_api.is_event_active(event) then
			event_api.active_events[event] = true
		else
			event_api.active_events[event] = false
		end
	end
end

function event_api.time_until_start_or_finish(event, mode)
	if not (mode == "left" or mode == "until"  or mode == "auto") then
		mode = "auto"
	end

	local now = os_time()
	local start = os_time(event_api.get_event_setting(event, "starting_date"))
	local finish = os_time(event_api.get_event_setting(event, "finishing_date"))

	if mode == "auto" then
		if start <= now and now < finish then
			mode = "left" -- Left of event
		elseif now < start then
			mode = "until" -- Until the event
		end
	end

	if mode == "left" then
		return finish - now
	end

	return start - now
end

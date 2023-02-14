event_api = {}

dofile(minetest.get_modpath(minetest.get_current_modname()).."/api.lua")
dofile(minetest.get_modpath(minetest.get_current_modname()).."/test_event.lua")

minetest.register_chatcommand("show_event_form", {
	params = "<event>",
	privs = {server = true},
	func = function(playername, event)
		event_api.show_event_formspec(playername, event)

		local t = event_api.seconds_to_general_date(event_api.time_until_start_or_finish(event))

		minetest.log("It's "..t.years.." years, "..t.months.." months, "..t.days.." days, "
		..t.hours.." hours, "..t.minutes.." minutes and "..t.seconds.." seconds left")

		return "Show form of the \""..tostring(event_api.get_event_setting(event, "description")).."\""
	end
})

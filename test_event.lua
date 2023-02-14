local test_formspec = "size[4,4]" ..
"label[0,0;Hello, World!]" ..
"button_exit[1,2;2,1;exit;Close]"

event_api.register_new_event("event_api:test", {
	description = "Test Event",
	starting_date = event_api.get_date_from_conf,
	finishing_date = event_api.get_date_from_conf,
	formspec = test_formspec,
})

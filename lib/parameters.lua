--------------------------
-- musical params
--------------------------

-- variables and functions
scale_length = 88
root_note_default = 36
scale_names = {}
notes = {}
note_offset1 = 0
note_offset2 = 0


for i= 1, #MusicUtil.SCALES do
  table.insert(scale_names, string.lower(MusicUtil.SCALES[i].name))
end

build_scale = function()
  notes = {}
  notes = MusicUtil.generate_scale_of_length(params:get("root_note"), params:get("scale_mode"), scale_length)
  notes = MusicUtil.generate_scale_of_length(notes[params:get("root_note_offset")], params:get("scale_mode"), scale_length)
  local num_to_add = scale_length - #notes
  for i = 1, num_to_add do
    table.insert(notes, notes[scale_length - num_to_add])
  end
end

set_scale_length = function()
  scale_length = params:get("scale_length")
end

-- params

-- add a group
params:add_group("scales and notes",5)

-- add params
params:add{type = "option", id = "scale_mode", name = "scale mode",
  options = scale_names, default = 1,
  action = function() build_scale() end}
  
params:add{type = "number", id = "root_note", name = "root note",
min = 0, max = 127, default = root_note_default, formatter = function(param) return MusicUtil.note_num_to_name(param:get(), true) end}

params:add{type = "number", id = "root_note_offset", name = "root note offset",
min = 1, max = scale_length, default = 1 }

params:add{type = "trigger", id = "set_root", name = "set root",
action = function() build_scale() end} 

params:add{type = "trigger", id = "reset_offset", name = "reset offset",
action = function() 
  params:set("root_note_offset",1)
  build_scale()
end} 
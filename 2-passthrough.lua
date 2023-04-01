-- habitus
-- passthrough engine example

engine.name = 'HabitusPassthrough'
local pre_init_monitor_level;

function init()
  pre_init_monitor_level = params:get('monitor_level') -- capture 'monitor' level before we change it
  params:set('monitor_level',-inf)
  
  local function strip_trailing_zeroes(s)
    return string.format('%.2f', s):gsub("%.?0+$", "")
  end
  
  params:add_separator('header', 'engine controls')
  
  params:add_control(
    'eng_amp', -- ID
    'amp', -- display name
    controlspec.new(
      0, -- min
      2, -- max
      'lin', -- warp
      0.001, -- output quantization
      1, -- default value
      '', -- string for units
      0.005 -- adjustment quantization
    ),
    -- params UI formatter:
    function(param)
      return strip_trailing_zeroes(param:get()*100)..'%'
    end
  )
  
  params:set_action('eng_amp',
    function(x)
      engine.amp(x)
      screen_dirty = true
    end
  )

  screen_dirty = true
  redraw_timer = metro.init(
    function() -- what to perform at every tick
      if screen_dirty == true then
        redraw()
        screen_dirty = false
      end
    end,
    1/15 -- how often (15 fps)
    -- the above will repeat forever by default
  )
  redraw_timer:start()
  
end

function redraw()
  screen.clear()
  screen.move(64,32)
  screen.level(15)
  screen.font_size(17)
  screen.text_center('amp: '..params:string('eng_amp'))
  screen.update()
end

function enc(n,d)
  params:delta('eng_amp',d)
  screen_dirty = true
end

function cleanup()
  params:set('monitor_level', pre_init_monitor_level) -- restore 'monitor' level
end
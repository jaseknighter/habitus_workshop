-- habitus: passthru engine example

engine.name = 'Habitus'
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
    end
  )
  
end

function cleanup()
  params:set('monitor_level', pre_init_monitor_level) -- restore 'monitor' level
end
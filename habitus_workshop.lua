-- habitus workshop code: pitch detection
--
-- description
--
-- @jaseknighter & @dan_derks
-- v0.1
--    ▼ instructions below ▼
--
-- K2 repeat recording indefinitely
-- K3 set rec and pre to 50
--
-- long press K1: toggle controls
--
-- left side:
-- E1 rate
-- E2 rec level
-- E3 pre level
--
-- right side:
-- E1 rate slew
-- E2 frequency multipier
-- E3 loop length


-- references 
-- pitch detection
--      https://monome.org/docs/norns/study-5/
--      https://github.com/monome/norns/blob/0e8dd4f774b04b4eb679e43ba3b3131ac416dfcd/sc/core/CroneDefs.sc
-- softcut rate adjustment (and recording/overdubing)
--      https://github.com/monome/softcut-studies/blob/master/4-recdub.lua  

--------------------------
-- include files and set globals/constant variables
--------------------------

-- require built-in norns libs
Lattice = require ("lattice")
s = require("sequins")
MusicUtil = require("musicutil")

-- include custom libs
include ("lib/functions")
include ("lib/parameters")

-- set global variables
monitor_level = nil
right_side_focus = false 

rate = 1.0
latest_pitch = 0
rec = 0.5
pre = 0.5
slew = 0.05

freq_mult = 10
loop_end = 3

pat1_div_seq = s{1/16,1/8}
pat2_div_seq = s{1/4,1/8,1/2}
pat2_rate_seq = s{4,-4,2,-2,s{4,3,2,1,-1,-2,-3,-4}}

--------------------------
-- initialization functions
--------------------------

-- initialize the script (this runs whenever the script is loaded)
function init()
  -- capture the current monitor level to be restored when the script unloads
  monitor_level = params:get("monitor_level") 
  params:set("monitor_level",-inf) -- turn off the monitor level
  build_scale()
  init_lattice()
  init_softcut()
  -- init_reroute_audio()
  init_polling()  
  set_redraw_timer()

  lat:start()
end

-- setup lattice
function init_lattice()
  lat = Lattice:new{
    auto = true,
    meter = 4,
    ppqn = 96
  }

  -- setup a pattern to sequence softcut's filter frequency and rq
  lat_pat1 = lat:new_pattern{
    action = function(t) 
      softcut.post_filter_fc (1, latest_pitch*freq_mult)
      softcut.post_filter_rq (1, 1/latest_pitch*freq_mult)
      lat_pat1:set_division(pat1_div_seq())
    end,
    division = 1/4,
    enabled = true
  }

  -- setup a pattern to sequence softcut's rate
  lat_pat2 = lat:new_pattern{
    action = function(t) 

      -- option 1: set the rate according to a s pattern
      set_rate(pat2_rate_seq())

      -- option 2: set the rate according to detected frequency
      -- local note_num = MusicUtil.freq_to_note_num (latest_pitch)
      -- local quant_note_num = fn.quantize(note_num,notes)
      -- local new_rate = (quant_note_num-params:get("root_note"))/12
      -- set_rate(new_rate)

      lat_pat2:set_division(pat2_div_seq())
    end,
    division = 1/4,
    enabled = true
  }

end

-- setup softcut
function init_softcut()
  -- send audio input to softcut input
	audio.level_adc_cut(1)
  
  softcut.buffer_clear()
  softcut.enable(1,1)
  softcut.buffer(1,1)
  softcut.level(1,0.5)
  softcut.rate(1,1.0)
  softcut.loop(1,1)
  softcut.loop_start(1,1)
  softcut.loop_end(1,loop_end)
  softcut.position(1,1)
  softcut.play(1,1)


  -- set input rec level: input channel, voice, level
  softcut.level_input_cut(1,1,1.0)
  softcut.level_input_cut(2,1,1.0)
  -- set voice 1 record level 
  softcut.rec_level(1,rec)
  -- set voice 1 pre level
  softcut.pre_level(1,pre)
  -- set record state of voice 1 to 1
  softcut.rec(1,1)

  -- set slew time
  softcut.rate_slew_time (1, slew)

  --set post-filter band pass filter level
  softcut.post_filter_bp (1, 1)
  
end

-- reroute the audio to allow pitch detection from audio in and softcut
-- function init_reroute_audio()
--     os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
--     os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
--     os.execute("jack_connect softcut:output_1 SuperCollider:in_1;")  
--     os.execute("jack_connect softcut:output_2 SuperCollider:in_2;")      
-- end  

-- setup  polling for built-in pitch detection
function init_polling()
  --set the poll to the variable `l_freq_poll`
  l_freq_poll = poll.set("pitch_in_l")

  -- create a callback to call when the poll is triggered (in supercollider)
  l_freq_poll.callback = function(val)
    if val ~= -1 then
      latest_pitch = val
    end
  end
  -- set the frequency of the poll
  l_freq_poll.time = 0.1
  -- start the poll
  l_freq_poll:start()
end


--------------------------
-- encoder and key functions
--------------------------

-- encoder turn code
function enc(n,d)
  if n==1 then
    if right_side_focus == false then
      local val = util.clamp(rate+d/100,-4,4)
      set_rate(val)
    else
      local val = util.clamp(slew+d/100,0,1)
      set_slew(val)
    end
  elseif n==2 then
    if right_side_focus == false then
      local val = util.clamp(rec+d/100,0,1)
      set_rec(val)
    else 
      local val = util.clamp(freq_mult+d,5,100)
      set_freq_mult(val)
    end
  elseif n==3 then
    if right_side_focus == false then
      local val = util.clamp(pre+d/100,0,1)
      set_pre(val)
    else 
      local val = util.clamp(loop_end+d/100,0.01,3)
      set_loop_length(val)
    end
  end
end

-- key press code
function key(n,z)
  if n==1 and z == 1 then 
    right_side_focus = not right_side_focus 
  elseif n==2 and z==1 then
    -- repeat recorded audio indefinitely
    set_rec(0)
    set_pre(1)
  elseif n==3 and z==1 then
    -- set rec and pre to 50%
    set_rec(0.5)
    set_pre(0.5)

  end

  -- set dirty_screen to true to redraw the screen 
  fn.dirty_screen(true)
end

--------------------------
-- rate/rec/pre/freq_mult/loop_end functions
--------------------------

function set_rate(val)
  -- change the rate of softcut channel 1
    rate = val
    softcut.rate(1,rate)
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
end

function set_slew(val)
  -- change the rate of softcut channel 1
    slew = val
    softcut.rate_slew_time(1,slew)
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
end

function set_rec(val)
  -- change the record le of softcut channel 1
    rec = val
    softcut.rec_level(1,rec)
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
  end

function set_pre(val)
  -- change the prelevel of softcut channel 1
    pre = val
    softcut.pre_level(1,pre)
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
  end

  function set_freq_mult(val)
  -- set the frequency multipier
    freq_mult = val
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
  end

  function set_loop_length(val)
  -- set the length of the recording loop
    loop_end = val
    softcut.loop_end(1,loop_end)
    -- set dirty_screen to true to redraw the screen 
    fn.dirty_screen(true)
  end


--------------------------
-- redraw functions
--------------------------
-- set a timer to redraw every 1/15th of a second
function set_redraw_timer()
    redrawtimer = metro.init(function() 
      if not fn.dirty_screen() then -- don't do anything if dirty_screen returns false
        return 
      else -- otherwise redraw
        redraw()
        fn.dirty_screen(false)  
      end
    end, 1/15, -1) -- 1/15 sets the refresh rate and -1 means repeat forever 
    redrawtimer:start()  
end
  
function redraw()

  --draw the ui
  screen.clear() -- clear the screen 
  
  -- draw line if k1 is not pressed
  if right_side_focus == false then
    screen.move(10,20)
    screen.line(55,20)
    screen.stroke()
  end

  screen.move(10,30) 
  screen.text("rate ") 
  screen.move(55,30)
  screen.text_right(string.format("%.2f",rate))
  screen.move(10,40)
  screen.text("rec ")
  screen.move(55,40)
  screen.text_right(string.format("%.2f",rec))
  screen.move(10,50)
  screen.text("pre ")
  screen.move(55,50)
  screen.text_right(string.format("%.2f",pre))

  -- draw left ui
  -- draw line if k1 is pressed
  if right_side_focus == true then
    screen.move(65,20)
    screen.line(115,20)
    screen.stroke()
  end

  screen.move(65,30) 
  screen.text("slew ") 
  screen.move(120,30)
  screen.text_right(string.format("%.2f",slew))
  screen.move(65,40)
  screen.text("freq * ")
  screen.move(120,40)
  screen.text_right(string.format("%.2f",freq_mult))
  screen.move(65,50)
  screen.text("loop len ")
  screen.move(120,50)
  screen.text_right(string.format("%.2f",loop_end))

  -- update the screen with asssbove changes
  screen.update()
end

--------------------------
-- cleanup: run when the script is unloaded (e.g. when norns is shutdown or a new script is loaded)
--------------------------

function cleanup()
  -- restore the monitor level from when the script was first loaded
  params:set("monitor_level",monitor_level) 

--     os.execute("jack_disconnect softcut:output_1 SuperCollider:in_1;")  
--     os.execute("jack_disconnect softcut:output_2 SuperCollider:in_2;")
--     os.execute("jack_connect crone:output_5 SuperCollider:in_1;")  
--     os.execute("jack_connect crone:output_6 SuperCollider:in_2;")
  
end

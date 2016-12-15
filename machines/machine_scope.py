import serial
from serial_tools import Serial_Tools
from tools import *
import time

class MachineScope(object):
    def __init__(self):
        """Serial Setup"""
        self.ready = False
        self.trace_state=0
        self.ser = None
        self.s_t = Serial_Tools(self.ser)
        self.s_t.show_messages = False

        self.state = self.s_find_device
        
        self.trace_size = 1024 # Samples
        self.extra_trace = 4
        self.whole_trace = self.trace_size + self.extra_trace
        self.dump_size = self.trace_size
        self.extra_dump = self.extra_trace
        self.whole_dump = self.dump_size + self.extra_dump
        
        self.write_buffer = ""
        
        self.buffer_size = 3 * 4096

        """Data exposed through API"""
        self.data = {
            "device":{"connected":False, "model":None},
            "accepted_models":["BS0005", "BS0010"],
            "ch":{"active":{}},
            "trigger_level":32000,
            "trigger_display":0,
            "range_data":{"top":32000, "bot":0},
            "range":{"min":-5.8, "max":5.8, "high":4.0, "low":-1.0, "offset":1.5, "span":5.0},
            "timebase":{"min":15, "max":535, "value":40, "display":""},
            "current_channel":"a",
            "waveform":0,
            "symetry":32768,
            "symetry_percentage":50,
            "frequency":1,
            "on_time":0,
            "off_time":0
        }
                
        self.data['ch']['active'] = {
            "trace":[],
            "display_trace":[]
        }
        
        self.data['spock_option'] = [0,0,0,0,0,0,0,0] # This is BEian (7 -> 0)
        
        self.active = self.data['ch']['active']
        self.device = self.data['device']
        self.compute_times()
        self.ticks_to_timebase()

    """ Helper Functions """
    
    def compute_times(self):
        """ Works out the on and off times, based on the
            frequency and symetry.
        """
        d = self.data
        freq = d['frequency'] * 1000
        p_length = freq ** -1
        d['on_time'] = (p_length) * (d['symetry_percentage'] / 100.0)
        d['off_time'] = (p_length) * ((100.0 - d['symetry_percentage']) / 100.0)
        d['on_time'] = d['on_time'] * 1000000
        d['off_time'] = d['off_time'] * 1000000
        
    def restart_awg(self):
        """ Resends all AWG commands that can be altered in this mode """
        d = self.data
        leh = l_endian_hexify
        ### Synthesise ###
        out = (
        "[46]@[00]s" # CV
        + "[47]@[" + str(d['waveform']) + "]s"
        + "[5a]@[%s]sn[%s]s" % leh(d['symetry'], 2) # Phase Ratio
        + "Y"
        ### Translate ###
        + "[47]@[00]s"
        + "[5a]@[26]sn[31]sn[08]sn[00]s" # Phase Ratio
        + "X"
        ### Generate ###
        + "[46]@[02]s"
        + "[50]@[%s]sn[%s]s" % leh(self.freq_to_ticks(), 2) # Clock ticks 
        + "Z"
        )
        
        self.write_buffer += out
        
    def freq_to_ticks(self):
        """ Frequency relies on a constant phase ratio at the translate
            command.
            With 0x00083126 we get 8 periods per 1000 point table.
            clock_ticks = period / points_per_period
            frequency is in Hz, clock_ticks are 25ns long.
        """
        d = self.data
        points_per_period = 125.0
        period = (d['frequency'] * 1000.0) ** -1
        ticks_per_period = period / 0.000000025
        return int(round(ticks_per_period / points_per_period))
        
    def ticks_to_timebase(self):
        tb = self.data['timebase']
        tb['display'] = self.trace_size * (tb['value'] * 25)
        tb['display'] *= 0.000001
        
    """ API Functions """
        
    def step_waveform(self, inc):
        d = self.data
        d['waveform'], changed = increment(d['waveform'], inc, 0, 3)
        if changed:
            self.restart_awg()
        
    def select_waveform(self, choice):
        d = self.data
        choice = choice -1
        d['waveform'], changed = assignwithin(d['waveform'],choice, 0, 3) 
        if changed:
            self.restart_awg()

    def reset_symetry(self):
        sym = 50
        self.data['symetry_percentage'] = sym
        self.data['symetry'] = int(to_range(sym, (0, 100),(0, 65535)))
        self.compute_times()
        self.restart_awg()
        
    def reset_frequency(self):
        self.data['frequency'] = 4
        self.compute_times()
        self.restart_awg()

    def stop_wave(self):
        d = self.data
        leh = l_endian_hexify
        ### Synthesise ###
        out = (
        "[46]@[00]s" # CV
        +"[7c]@[80]s"
        )
        self.write_buffer = out

    def start_wave(self):
        d = self.data
        leh = l_endian_hexify
        ### Synthesise ###
        out = (
        "[46]@[02]s" # CV
        +"[7c]@[c0]s"
        )
        self.write_buffer = out

    def snap_symetry(self):
        d = self.data
        sym = round_to_n(d['symetry_percentage'], 2)
        d['symetry_percentage'] = sym
        d['symetry'] = int(to_range(sym, (0, 100),(0, 65535)))
        self.compute_times()
        self.restart_awg()
        
    def snap_frequency(self):
        d = self.data
        d['frequency'] = round_to_n(d['frequency'], 2)
        self.compute_times()
        self.restart_awg()
        
    def snap_on_off_time(self, select):
        d = self.data
        on = d['on_time']
        off = d['off_time']
        if select == "on":
            on = round_to_n(on, 2)
        elif select == "off":
            off = round_to_n(off, 2)
            
        on_frac = on / 1000000.0
        off_frac = off / 1000000.0
        
        newFreq = (((on_frac + off_frac) ** -1) / 1000.0)
        newSym = to_range(on_frac, (0, on_frac + off_frac), (0, 100))
        if 0.06 <= newFreq <= 8.0 and 0.0 <= newSym <= 100.0:
            d['on_time'] = on
            d['off_time'] = off
            d['frequency'] = newFreq
            d['symetry_percentage'] = newSym
            d['symetry'] = int(to_range(newSym, (0,100), (0,65535)))
            self.restart_awg()
        
    def adjust_symetry(self, inc):
        d = self.data
        d['symetry_percentage'], changed = increment(d['symetry_percentage'], inc, 0, 100)
        if changed:
            d['symetry'] = int(to_range(d['symetry_percentage'], (0,100), (0,65535)))
            self.restart_awg()
            self.compute_times()
        
    def assign_symetry(self, value):
        """ assign the value as symetry """
        d = self.data
        d['symetry_percentage'], changed = assignwithin(d['symetry_percentage'], value, 0, 100)
        if changed:
            d['symetry'] = int(to_range(d['symetry_percentage'], (0,100), (0,65535)))
            self.restart_awg()
            self.compute_times()

    def adjust_frequency(self, inc):
        d = self.data
        d['frequency'], changed = increment(d['frequency'], inc, 0.6, 8.0)
        if changed:
            self.restart_awg()
            self.compute_times()
            
    def assign_frequency(self, value):
        d = self.data
        d['frequency'], changed = assignwithin(d['frequency'], value, 0.6, 8.0)
        if changed:
            self.restart_awg()
            self.compute_times()

    def adjust_on_off_time(self, select, inc):
        d = self.data
        on_inc, off_inc = 0, 0
        if select == "on":
            on_inc = inc
        elif select == "off":
            off_inc = inc
        on = (d['on_time'] + on_inc) / 1000000.0
        off = (d['off_time'] + off_inc) / 1000000.0
        newFreq = (((on + off) ** -1) / 1000.0)
        newSym = to_range(on, (0, on + off), (0, 100))
        if 0.06 <= newFreq <= 8.0 and 0.0 <= newSym <= 100.0:
            d['on_time'] = on * 1000000
            d['off_time'] = off * 1000000
            d['frequency'] = newFreq
            d['symetry_percentage'] = newSym
            d['symetry'] = int(to_range(newSym, (0,100), (0,65535)))
            self.restart_awg()
    
    def set_timebase(self, value):
        tb = self.data['timebase']
        tb['value'], changed = assignwithin(tb['value'], value, tb['min'], tb['max'])
        if changed:
            self.write_buffer += ("[2e]@[%s]sn[%s]s" % l_endian_hexify(tb['value']))
            self.ticks_to_timebase()
       
    def adjust_timebase(self, inc):
        tb = self.data['timebase']
        tb['value'], changed = increment(tb['value'], inc, tb['min'], tb['max'])
        if changed:
            self.write_buffer += ("[2e]@[%s]sn[%s]s" % l_endian_hexify(tb['value']))
            self.ticks_to_timebase()

    def assign_channel(self, channel):
        """ Changes the capture channel, and the trigger channel """
        if channel == "b":
            self.data['current_channel'] = "b"
            code = "2"
            self.data['spock_option'][5] = True # Source bit (true = b, false = a)
        else:
            self.data['current_channel'] = "a"
            code = "1"
            self.data['spock_option'][5] = False
        self.write_buffer += "[37]@[0" + code + "]s"
        s_op = from_bin_array(self.data['spock_option'])
        self.write_buffer += "[07]@[%s]s" % l_endian_hexify(s_op,1)
        
    def change_channel(self):
        """ Changes the capture channel, and the trigger channel """
        if self.data['current_channel'] == "a":
            self.data['current_channel'] = "b"
            code = "2"
            self.data['spock_option'][5] = True # Source bit (true = b, false = a)
        else:
            self.data['current_channel'] = "a"
            code = "1"
            self.data['spock_option'][5] = False
        self.write_buffer += "[37]@[0" + code + "]s"
        s_op = from_bin_array(self.data['spock_option'])
        self.write_buffer += "[07]@[%s]s" % l_endian_hexify(s_op,1)
            
    def move_range(self, inc):
        r = self.data['range']
        if (r['high'] + inc) <= r['max'] and (r['low'] + inc) >= r['min']:
            self.adjust_range('high', inc)
            self.adjust_range('low', inc)
                        
    def adjust_range(self, hl, inc):
        r = self.data['range']
        r[hl] += inc
        if (r[hl] > r['max'] or r[hl] < r['min']
            or r['low'] >= r['high']):
            r[hl] -= inc
        else:
            r[hl] = round(r[hl], 1)
            # Get scale
            scale = r['high'] - r['low']
            r['span'] = scale
            # Get offset
            r['offset'] = r['low'] + (scale / 2)
            # Compute register values
            high, low = to_span(r['offset'], scale, self.data['device']['model'])
            # Figure out trigger
            trig_voltage = r['low'] + ((r['high'] - r['low']) / 2)
            self.data['trigger_display'] = trig_voltage
            self.data['trigger_level'] = int(to_range(trig_voltage, [-7.517, 10.816], [0,65535]))
            #self.data['trigger_level'] = int(to_range(trig_voltage, [-10.816, 10.816], [0,65535]))
            # Submit high, then low
            self.write_buffer += "[68]@[%s]sn[%s]s" % l_endian_hexify(self.data['trigger_level'], 2)
            self.write_buffer += "[66]@[%s]sn[%s]s" % l_endian_hexify(high)
            self.write_buffer += "[64]@[%s]sn[%s]s" % l_endian_hexify(low)
            
    def adjust_span(self, inc):
        r = self.data['range']
        if (r['high'] + inc) <= r['max'] and (r['low'] - inc) >= r['min']:
            self.adjust_range('high', inc)
            self.adjust_range('low', -inc)

    """ Utility States """
    def s_find_device(self):
        self.ser = self.s_t.find_device()
        if self.ser != None:
            self.data['device']['connected'] = True
            self.state = self.s_check_model
            
        else:
            if self.data['device']['connected']:
                self.data['device']['connected'] = False
            self.state = self.s_find_device

    def s_check_model(self):
        self.ser.read(10000) # Try to get anything in the buffer.
        self.s_t.clear_waiting() # Force the counter to reset.
        self.s_t.issue_wait("?")
        model = (self.ser.read(20)[1:7])
        self.data['device']['model'] = model

        self.dirty = True
        if model in self.data['accepted_models']:
            self.state = self.s_setup_bs
            print self.data['device']['model'] + " Connected."
        else:
            self.state = self.s_check_model
    def soft_reset(self):
        self.s_t.issue_wait("!") # Soft reset
        
    """ States """
    def s_setup_bs(self):
        siw = self.s_t.issue_wait
        si = self.s_t.issue
        leh = l_endian_hexify
        d = self.data
        ### General ###
        siw("!") # Reset!
        si(
            "[1c]@[%s]sn[%s]s" % leh(self.whole_dump) # Dump size
            + "[1e]@[00]s" # Dump mode
            + "[21]@[00]s" # Trace mode
            + "[08]@[00]sn[00]sn[00]s" # Default spock address
            + "[16]@[01]sn[00]s" # Iterations to 1
            + "[2a]@[%s]sn[%s]s" % leh(self.whole_trace) # Post trig cap
            + "[30]@[00]s" # Dump channel
            + "[31]@[00]s" # Buffer mode
            + "[37]@[01]s" # Analogue chan enable
            + "[26]@[01]sn[00]s" # Pre trig capture
            + "[22]@[00]sn[00]sn[00]sn[00]s" # Trigger checking delay period.
            + "[2c]@[00]sn[0a]s" # Timeout
            + "[2e]@[%s]sn[%s]s" % leh(d['timebase']['value']) # Set clock ticks
            + "[14]@[01]sn[00]s" # Clock scale

            ### Trigger ###
            + "[06]@[7f]s" # TriggerMask
            + "[05]@[80]s" # TriggerLogic
            + "[32]@[04]sn[00]s" # TriggerIntro
            + "[34]@[04]sn[00]s" # TriggerOutro
            + "[44]@[00]sn[00]s" # TriggerValue
            + "[68]@[%s]sn[%s]s" % leh(d['trigger_level'], 2) # TriggerLevel
            + "[07]@[%s]s" % leh(from_bin_array(d['spock_option']), 1) # SpockOption
        )
        ### Range / Span ###
        high, low = to_span(d['range']['offset'], d['range']['span'], d['device']['model'])
        si(
        "[66]@[%s]sn[%s]s" % l_endian_hexify(high)
        + "[64]@[%s]sn[%s]s" % l_endian_hexify(low)
        )
        
        ### AWG ###
        siw(
            "[7c]@[c0]s[86]@[00]s" # AWG on, clock gen off
            # Synthesize
            + "[46]@[00]sn[" + str(d['waveform']) + "]s" # CV, Op Mode
            + "[5a]@[%s]sn[%s]s" % leh(d['symetry'], 2) # Phase Ratio
            + "Y"
        )
        siw(
            # Translate
            "[47]@[00]s" # CV, Op Mode
            + "[4a]@[e8]sn[03]sn[00]sn[00]sn[00]sn[00]s" # Size, Index, Address
            + "[54]@[ff]sn[ff]sn[00]sn[00]s" # Level, Offset
            + "[5a]@[26]sn[31]sn[08]sn[00]s" # Phase Ratio
            + "X"
        )
        siw(
            # Generate
            "[48]@[f4]sn[80]s[52]@[e8]sn[03]s" # Option, Modulo
            + "[50]@[%s]sn[%s]s" % leh(self.freq_to_ticks()) # Clock ticks
            + "[5e]@[0a]sn[01]sn[01]sn[00]s" # Mark, Space
            + "[78]@[00]sn[7f]s" # Dac Output
            + "[46]@[02]s"
            + "Z"
        )
        
        ### Update ###
        self.s_t.issue_wait(">")
        siw("U")
        self.s_t.clear_waiting()
        self.ser.flushInput()
        
        self.state = self.s_init_req
        self.ready = True
        self.trace_state = 1
        
    def s_init_req(self):
        self.s_t.clear_waiting()
        self.ser.flushInput()
        self.s_t.issue_wait(">")
        self.s_t.issue("D")
        
        self.state = self.s_dump
        self.trace_state = 2
        
    def s_dump(self):
        self.s_t.clear_waiting()
        self.ser.read(24)
        end_address = unhexify(self.ser.read(8))
        self.ser.read(1)
        start_address = ((end_address + self.buffer_size) - self.whole_trace) % self.buffer_size
        self.s_t.issue("[08]@[%s]sn[%s]sn[%s]s" % l_endian_hexify(start_address, 3))
        self.s_t.issue_wait(">")
        self.s_t.issue("A")
        
        self.state = self.s_proc_req
        self.trace_state = 3

    def s_proc_req(self):
        self.s_t.clear_waiting()
        self.ser.read(self.extra_dump)
        self.active['trace'] = convert_8bit_dump(self.ser.read(self.dump_size))
        #self.active['trace'] = convert_8bit_dump(self.ser.read(self.whole_trace))
        if self.write_buffer:
            self.s_t.issue(self.write_buffer)
            self.s_t.issue_wait("U")
            self.write_buffer = ""
        
        self.s_t.issue_wait(">")
        self.s_t.issue("D")
        
        self.state = self.s_dump
        self.trace_state = 2
        
    """Data Processing Functions"""

    """Update Functions"""

    def update(self):
        try:
            self.state()
        except serial.SerialException:
            print "Device disconected | Error: SE"
            self.state = self.s_find_device
            self.ready = False
            self.trace_state = 0
        except serial.SerialTimeoutException:
            print "Device disconected | Error: STE"
            self.state = self.s_find_device
            self.ready = False
            self.trace_state = 0

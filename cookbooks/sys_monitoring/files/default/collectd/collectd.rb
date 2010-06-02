#
# Copyright (c) 2010 RightScale Inc
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class Collectd
  # Encode a string (type 0, null terminated string)
  def self.string(type, str)
    str += "\000"
    [type, str.length+4].pack("nn") + str
  end

  # Encode an integer
  def self.number(type, num)
    [type, 12].pack("nn") + [num >> 32, num & 0xffffffff].pack("NN")
  end

  # Create a collectd collection object tied to a specific destination server and port.
  # The host parameter is the hostname sent to collectd, typically `hostname -f`.strip
  # The use of the interval is unclear, it's simply sent to collectd with every packet...
  def initialize(server, port, host, interval)
    @sock = UDPSocket.new(Socket::AF_INET)
    @sock.connect(server, port)
    @interval = interval
    @host = host
    start
  end

  # Start a fresh packet, this is usually not called directly. Issues a time marker using either
  # the passed time (unix time integer) or the same time as the previous packet (useful when
  # overrunning from one packet to the next)
  def start(time=nil)
    @pkt = Collectd.string(0, @host)
    @time = time if time
    @pkt << Collectd.number(1, @time) if @time
    @pkt << Collectd.number(7, @interval)
    @plugin = @plugin_instance = @tipe = @tipe_instance = nil
  end
  # Send the current packet
  def flush
    @sock.send(@pkt.to_s, 0) rescue SystemCallError
  end
  # Check the length of the current packet and flush it if we reach a high-water mark
  def chk
    if @pkt.size > 900 # arbitrary flush, 1024 is the max allowed
      flush
      #sleep(0.01) # don't overwhelm output buffers
      start
    end
  end

  # Issue time, plugin, plugin_instance, type, and type_instance markers. These are not typically called
  # directly
  def time(t)            @pkt << Collectd.number(1, @time = t)            unless @time == t; end
  def plugin(p)          @pkt << Collectd.string(2, @plugin = p)          unless @plugin == p; end
  def plugin_instance(p) @pkt << Collectd.string(3, @plugin_instance = p) unless @plugin_instance == p; end
  def tipe(p)            @pkt << Collectd.string(4, @tipe = p)            unless @tipe == p; end
  def tipe_instance(p)   @pkt << Collectd.string(5, @tipe_instance = p)   unless @tipe_instance == p; end

  # Send a data point consisting of one or multiple values. Multiple values are used for RRDs with multiple
  # data series (DS's in RRD terms). An examples of a multi-valued RRDs in the collectd types is disk_write
  # with a 'read' and a 'write' value.
  # Arguments: pl=plugin, pi=plugin_instance, t=type, ti=type_instance, values: array of [type, value]
  # Eg.: values('disk', 'sda0', 'disk', 'ops', [[:counter, 1034], [:counter, 345]])
  @@type_code = {:gauge => 1, :counter => 0, :derive => 2, :absolute => 3}
  def values(pl, pi, t, ti, values)
    chk
    plugin(pl); plugin_instance(pi)
    tipe(t); tipe_instance(ti)
    @pkt << [6, 4+2+values.size*9, values.size].pack("nnn")
    @pkt << values.map{|t,v| [@@type_code[t]].pack("C")}.join
    @pkt << values.map{|t,v| t == :gauge ? [v].pack("E") : [v>>32, v & 0xffffffff].pack("NN")}.join
  end

  # Send a data point with one or multiple gauge values
  def gauge   (pl, pi, t, ti, value) values(pl, pi, t, ti, Array(value).map{|v| [:gauge, v]}); end
  # Send a data point with one or multiple counter values
  def counter (pl, pi, t, ti, value) values(pl, pi, t, ti, Array(value).map{|v| [:counter, v]}); end
  # Send a data point with one or multiple derive values
  def derive  (pl, pi, t, ti, value) values(pl, pi, t, ti, Array(value).map{|v| [:derive, v]}); end
  # Send a data point with one or multiple absolute values
  def absolute(pl, pi, t, ti, value) values(pl, pi, t, ti, Array(value).map{|v| [:absolute, v]}); end

  def to_s; @pkt; end
end

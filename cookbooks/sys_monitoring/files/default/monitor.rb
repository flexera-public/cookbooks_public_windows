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

module RightScale
  
  class Monitor
    
    RAW_PERCENTAGE_TO_COLLECTD_DIVISOR = 100000  # divisor to convert from 100Ns to 10ms

    COLLECTD_SENDERS = [ :gauge, :counter, :derive, :absolute ]  # valid send methods

    # For prioritization of monitors at runtime.
    HIGHEST_PRIORITY = 0
    HIGH_PRIORITY    = 1
    NORMAL_PRIORITY  = 2
    LOW_PRIORITY     = 3
    LOWEST_PRIORITY  = 4
    PRIORITIES = {:highest => HIGHEST_PRIORITY,
                  :high => HIGH_PRIORITY,
                  :normal => NORMAL_PRIORITY,
                  :low => LOW_PRIORITY,
                  :lowest => LOWEST_PRIORITY}

    attr_accessor :name, :current_iteration, :current_time, :script_timestamp

    # For instance_eval of lightweight monitoring scripts.
    attr_writer :collectd_plugin, :collectd_sender
    attr_writer :collectd_type, :collectd_type_instance, :collectd_units_factor
    attr_writer :wmi_query, :wmi_query_required_send

    # Initializer.
    #
    # === Parameters
    # opts[:wmi](object):: WMI object that can execute WMI queries
    # opts[:collectd](Collectd):: the collectd plugin to send metrics to
    # opts[:logger](Logger):: the logger for the monitor process
    # opts[:name](string):: name of the monitor
    def initialize(opts)
      @wmi       = opts[:wmi]
      @collectd  = opts[:collectd]
      @logger    = opts[:logger]
      @name      = opts[:name]

      @collectd_plugin           = nil
      @collectd_sender           = nil
      @collectd_type             = nil
      @collectd_type_instance    = nil
      @collectd_units_factor     = nil
      @current_time              = nil
      @current_iteration         = nil
      @priority                  = nil
      @wmi_query                 = nil
      @wmi_query_name_attribute  = nil
      @wmi_query_send_attributes = nil
      @wmi_query_required_send   = nil
    end

    # Getter/Setter for priority which converts symbol to int for priority queue.
    #
    # === Parameters
    # value(int or string or symbol):: priority value as an integer constant or symbol.
    #
    # === Returns
    # priority(int):: priority value converted to int (for indexing purposes)
    def priority(value = nil)
      # validate and set if value is given.
      if value
        # convert to symbol in case of string for flexibility.
        value = value.to_sym if value.kind_of?(String)

        # we want the integer value for priority, so attempt lookup by symbol or
        # by integer value (integer will hash to nul).
        if PRIORITIES[value]
          value = PRIORITIES[value]
        else
          raise "Priority must be one of #{PRIORITIES.keys.inspect}" unless PRIORITIES.values.include?(value)
        end
        @priority = value
      elsif !@priority
        # prioritize counters higher than gauges because some counters are time-sensitive.
        if @collectd_sender && :counter == @collectd_sender
          @priority = HIGH_PRIORITY
        else
          @priority = NORMAL_PRIORITY
        end
      end
      return @priority
    end

    # Getter/Setter for wmi_query_name_attribute.
    #
    # === Parameters
    # value(string):: attribute name to take from WMI query result and use as plugin instance name.
    #
    # === Returns
    # result(string):: attribute name or nil
    def wmi_query_name_attribute(value = nil)
      unless value.nil?
        @wmi_query_name_attribute = value
      end
      return @wmi_query_name_attribute
    end

    # Getter/Setter for wmi_query_send_attributes.
    #
    # === Parameters
    # value(string or Array(string)):: attribute name(s) to take from WMI query result and process for sending via collectd.
    #
    # === Returns
    # Array(string):: array of attribute names or nil
    def wmi_query_send_attributes(value = nil)
      unless value.nil?
        value = [value] unless value.kind_of?(Array)
        @wmi_query_send_attributes = value
      end
      return @wmi_query_send_attributes
    end

    # Runs this monitor.
    #
    # === Parameters
    # args[:now_time](int):: clock time in seconds since 1970 for current monitoring timeslice.
    # args[:iteration](int):: current monitoring iteration.
    def run_script(args)
      @current_time       = args[:now_time]
      @current_iteration  = args[:iteration]

      # run monitor.
      run
    end

    # Default run implementation supporting one or more attributes without any
    # additional calcuation beyond conversion to integer with an optional units
    # factor (overridable).
    def run

      # check monitor settings.
      raise "wmi_query is required" unless @wmi_query
      raise "wmi_query_send_attributes is required" unless @wmi_query_send_attributes
      raise "collectd_plugin is required" unless @collectd_plugin
      raise "collectd_type is required" unless @collectd_type

      attributes = @wmi_query_send_attributes
      sender = (@collectd_sender || COLLECTD_SENDERS[0]).to_sym
      type_name = @collectd_type_instance || name
      units = (@collectd_units_factor || 1).to_f
      raise "collectd_sender must be one of #{COLLECTD_SENDERS.inspect}" unless COLLECTD_SENDERS.include?(sender)
      required_send = @wmi_query_required_send ? @wmi_query_required_send : []
      required_send = [required_send] unless required_send.kind_of?(Array)

      # query.
      @logger.debug("WMI Query = #{@wmi_query}")
      query_results = execute_wmi_query(@wmi_query)

      # convert and send values for each object in results.
      for query_result in query_results do
        instance_name = ''
        if @wmi_query_name_attribute
          instance_name = query_result.send(@wmi_query_name_attribute.to_sym)
          instance_name = collectd_case(instance_name)
        end

        queried_value_hash = {}
        for attribute in attributes
          queried_value = query_result.send attribute.to_sym
          if is_number?(queried_value)
            queried_value_hash[attribute] = (queried_value.to_f * units).round
          else
            raise "#{attribute}=\"#{queried_value}\" is not a number."
          end
        end
        send_value = prepare_to_send_value(queried_value_hash)
        if send_value.respond_to?(:has_key?)
          send_value.each do |key, value|
            # send counter values only if non-zero to reduce data kept on server.
            # once a counter accumulates any value, it will be sent continuously.
            self.send(sender, @collectd_plugin, instance_name, @collectd_type, key, value) if (:counter != sender || value > 0 || required_send.include?(key))
          end
        else
          self.send(sender, @collectd_plugin, instance_name, @collectd_type, type_name, send_value)
        end
      end
    end

    def execute_wmi_query(query)
      @wmi.execquery(query)
    end

    def gauge(plugin_name, plugin_instance, type_name, type_instance, value)
      @logger.debug("Sending gauge(\"#{plugin_name}\", \"#{plugin_instance}\", \"#{type_name}\", \"#{type_instance}\", #{value.inspect})") if @logger.debug?
      @collectd.gauge(plugin_name, plugin_instance, type_name, type_instance, value)
    end

    def counter(plugin_name, plugin_instance, type_name, type_instance, value)
      @logger.debug("Sending counter(\"#{plugin_name}\", \"#{plugin_instance}\", \"#{type_name}\", \"#{type_instance}\", #{value.inspect})") if @logger.debug?
      @collectd.counter(plugin_name, plugin_instance, type_name, type_instance, value)
    end

    def derive(plugin_name, plugin_instance, type_name, type_instance, value)
      @logger.debug("Sending derive(\"#{plugin_name}\", \"#{plugin_instance}\", \"#{type_name}\", \"#{type_instance}\", #{value.inspect})") if @logger.debug?
      @collectd.derive(plugin_name, plugin_instance, type_name, type_instance, value)
    end

    def absolute(plugin_name, plugin_instance, type_name, type_instance, value)
      @logger.debug("Sending absolute(\"#{plugin_name}\", \"#{plugin_instance}\", \"#{type_name}\", \"#{type_instance}\", #{value.inspect})") if @logger.debug?
      @collectd.absolute(plugin_name, plugin_instance, type_name, type_instance, value)
    end

    # Processes a hash of values taken from a query result into a value to be
    # sent via collectd. The resulting value must either be a tuple (i.e. Array)
    # of integers or an integer depending on what the server plugin expects.
    # Optionally, a hash of instance type name to integer value or tuple can be
    # returned which will result in multiple sends.
    #
    # The default implementation returns a single integer value, an array or a
    # hash depending on the count of values and whether or not the instance type
    # name is a regular expression. If the instance type name is a regular
    # expression, then the instance type name for each send is the first field
    # matched from the attribute name. (overridable).
    #
    # === Parameters
    # queried_value_hash(Hash):: hash of attribute names to values from WMI query result
    #
    # === Returns
    # send_value(int or Array(int) or Hash):: value(s) to send
    def prepare_to_send_value(queried_value_hash)
      if @collectd_type_instance.kind_of?(Regexp)  # ok if nil
        regex = @collectd_type_instance
        value_hash = {}
        queried_value_hash.each do |key, value|
          match_result = key.match(regex)
          raise "Attribute name #{key} did not match #{regex.inspect}" unless match_result
          send_key = collectd_case(match_result[1])
          value_hash[send_key] = value
        end
        return value_hash
      else
        if 1 == queried_value_hash.size
          return queried_value_hash.values[0]
        end

        # preserve the ordering of the query values to ensure the resulting
        # tuple sends values in proper order.
        value_array = []
        attributes = @wmi_query_send_attributes
        attributes.each do |attribute|
          value_array << queried_value_hash[attribute]
        end
        return value_array
      end
    end

    # Converts a camel-case value to snake-case, if necessary.
    #
    # === Parameters
    # value(string):: camel-case value
    #
    # === Returns
    # result(string):: snake-case value
    def collectd_case(value)
      return snake_case(value).gsub(/[ \.\\\/:*?<>|]/, '_')
    end

    # Converts a camel-case value to snake-case, if necessary.
    #
    # === Parameters
    # value(string):: camel-case value
    #
    # === Returns
    # result(string):: snake-case value
    def snake_case(value)
      return value.downcase if value.match(/\A[A-Z]+\z/)
      return value.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
                   gsub(/([a-z])([A-Z])/, '\1_\2').
                   downcase
    end

    # Normalizes the given value from WMI raw percentage units to collectd units.
    #
    # === Parameters
    # raw_value(string):: value to normalize
    #
    # === Returns
    # normal_value(int):: normalized value
    def normalize_raw_value(raw_value)
      return (raw_value.to_f / RAW_PERCENTAGE_TO_COLLECTD_DIVISOR.to_f).round
    end

    # Calculates percentage from the change in value for a percentage-type WMI
    # value using the timestamps read from WMI.
    #
    # === Parameters
    # value_key(symbol):: key of value to calculate change
    # new_values(Hash):: hash of new values
    # old_values(Hash):: hash of old values
    #
    # === Returns
    # percentage(float):: calculated value as a percentage to two decimals
    def calculate_wmi_percentage(value_key, new_values, old_values)
      return (10000.0 * (new_values[value_key] - old_values[value_key]) / (new_values[:wmi_time] - old_values[:wmi_time])).round / 100.0
    end

    # Calculates percentage from the change in value for a percentage-type WMI
    # value using the timestamps sent by collectd.
    #
    # === Parameters
    # value_key(symbol):: key of value to calculate change
    # new_values(Hash):: hash of new values
    # old_values(Hash):: hash of old values
    #
    # === Returns
    # percentage(float):: calculated value as a percentage to two decimals
    def calculate_collectd_percentage(value_key, new_values, old_values)
      return (100.0 * (new_values[value_key] - old_values[value_key]) / (new_values[:clock_time] - old_values[:clock_time])).round / 100.0
    end
    
    # Does given object represent a number?
    # i.e. can o.to_i be safely called
    #
    # === Parameters
    # o(Object):: Object to be tested
    #
    # === Return
    # true:: If o is a number
    # false:: Otherwise
    def is_number?(o)
      res = o && !!o.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/)
    end

    # Handles method missing for attr_writer methods.
    def method_missing(method_symbol, *args, &block)
      writer_form = (method_symbol.to_s + "=").to_sym
      if self.respond_to?(writer_form)
        self.send(writer_form, *args, &block)
      else
        raise NoMethodError, "undefined method `#{method_symbol.to_s}' for #{self.class.to_s}"
      end
    end

  end
end

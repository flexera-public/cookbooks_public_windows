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

priority :highest  # cpu_load is always visible and very time sensitive.

# Initialize the last cpu count
#
# === Return
# true:: Always return true
def init
  @last_cpus = nil
  true
end

# Collect and send CPU load information
#
# === Return
# true:: Always return true
def run
  wmi_processor_attributes = ['Name',
                              'TimeStamp_Sys100NS',
                              'PercentIdleTime',
                              'PercentUserTime',
                              'PercentPrivilegedTime',
                              'PercentInterruptTime']
  wmi_query = "Select #{wmi_processor_attributes.join(", ")} from Win32_PerfRawData_PerfOS_Processor where Name != '_Total'"
  @logger.debug("WMI query = #{wmi_query}")
  wmi_result = execute_wmi_query(wmi_query)
  cpus = {}
  for cpu in wmi_result do
    cpu_name = cpu.Name
    cpu_values = {}
    cpus[cpu_name] = cpu_values

    cpu_values[:idle] = normalize_raw_value(cpu.PercentIdleTime)
    cpu_values[:interrupt] = normalize_raw_value(cpu.PercentInterruptTime)
    cpu_values[:system] = normalize_raw_value(cpu.PercentPrivilegedTime)
    cpu_values[:user] = normalize_raw_value(cpu.PercentUserTime)

    cpu_values[:wmi_time] = normalize_raw_value(cpu.TimeStamp_Sys100NS)
    cpu_values[:clock_time] = current_time

    # in WMI, system time includes interrupt and DPC time (deferred
    # procedure calls). subtract out interrupt time so that we can display
    # it separately. DPC is not displayable with Sketchy, so ignore it.
    cpu_values[:system] -= cpu_values[:interrupt]

    # as a sanity check, ensure values are strictly increasing from last
    # sample. this avoids spikes (negative value to unsigned integer)
    # resulting from subtracting interrupt from system (due ultimately to
    # small errors in WMI vs. clock time).
    if @last_cpus && (last_cpu_values = @last_cpus[cpu_name])
      cpu_values.keys.each do |k|
        if cpu_values[k] < last_cpu_values[k]
          cpu_values[k] = last_cpu_values[k]
        end
      end
    end

    # add counters
    counter('cpu', cpu_name, 'cpu', 'idle', cpu_values[:idle])
    counter('cpu', cpu_name, 'cpu', 'system', cpu_values[:system])
    counter('cpu', cpu_name, 'cpu', 'interrupt', cpu_values[:interrupt])
    counter('cpu', cpu_name, 'cpu', 'user', cpu_values[:user])

    # logger.
    if @logger.debug?
      @logger.debug("Sending CPU(#{cpu_name}) idle(#{cpu_values[:idle]}) user(#{cpu_values[:user]}) system(#{cpu_values[:system]}) interrupt(#{cpu_values[:interrupt]}) clock(#{cpu_values[:clock_time]})")
      if @last_cpus && (last_cpu_values = @last_cpus[cpu_name])

        # WMI percentages.
        idle_percentage = calculate_wmi_percentage(:idle, cpu_values, last_cpu_values)
        interrupt_percentage = calculate_wmi_percentage(:interrupt, cpu_values, last_cpu_values)
        system_percentage = calculate_wmi_percentage(:system, cpu_values, last_cpu_values)
        user_percentage = calculate_wmi_percentage(:user, cpu_values, last_cpu_values)
        total_percentage = idle_percentage + interrupt_percentage + system_percentage + user_percentage
        delta_time = cpu_values[:wmi_time] - last_cpu_values[:wmi_time]
        @logger.debug("WMI calculation: idle=#{idle_percentage}% user=#{user_percentage}% system=#{system_percentage}% interrupt=#{interrupt_percentage}% total=#{total_percentage}% delta_time=#{delta_time}")

        # collectd percentages.
        idle_percentage = calculate_collectd_percentage(:idle, cpu_values, last_cpu_values)
        interrupt_percentage = calculate_collectd_percentage(:interrupt, cpu_values, last_cpu_values)
        system_percentage = calculate_collectd_percentage(:system, cpu_values, last_cpu_values)
        user_percentage = calculate_collectd_percentage(:user, cpu_values, last_cpu_values)
        total_percentage = idle_percentage + interrupt_percentage + system_percentage + user_percentage
        delta_time = 100 * (cpu_values[:clock_time] - last_cpu_values[:clock_time])
        @logger.debug("collectd calculation: idle=#{idle_percentage}% user=#{user_percentage}% system=#{system_percentage}% interrupt=#{interrupt_percentage}% total=#{total_percentage}% delta_time=#{delta_time}")
      end
    end
  end
  @last_cpus = cpus
  
  true
end

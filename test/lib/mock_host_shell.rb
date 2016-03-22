
# This is partly a mock, but mostly a proxy.
# Rename it to HostShellProxyMock

class MockHostShell

  def initialize(dojo)
    @target = HostShell.new(dojo)
    @cd_exec_mock     = []
    @exec_mock        = []
  end

  # - - - - - - - - - - - - - - - - -

  def teardown
    raise "#{self.class.name} unused #{@cd_exec_mock}"     unless @cd_exec_mock     == []
    raise "#{self.class.name} unused #{@exec_mock}"        unless @exec_mock        == []
  end

  # - - - - - - - - - - - - - - - - -

  def mock_cd_exec(path, commands, output, exit_status)
    @cd_exec_mock << {
             path: path,
         commands: commands,
           output: output,
      exit_status: exit_status
    }
  end

  # - - - - - - - - - - - - - - - - -

  def cd_exec(path, *commands)
    return @target.cd_exec(path, *commands) if @cd_exec_mock == []
    mock = @cd_exec_mock.shift
    if [path,commands] != [mock[:path],mock[:commands]]
      complain('cd_exec', "#{mock[:path]}, #{mock[:commands]}", "#{path}, #{commands}")
    end
    return mock[:output], mock[:exit_status]
  end

  # - - - - - - - - - - - - - - - - -

  def mock_exec(commands, output, exit_status)
    @exec_mock << {
         commands: commands,
           output: output,
      exit_status: exit_status
    }
  end

  # - - - - - - - - - - - - - - - - -

  def exec(*commands)
    return @target.exec(*commands) if @exec_mock == []
    mock = @exec_mock.shift
    if commands != mock[:commands]
      complain('exec', "#{mock[:commands]}", "#{commands}")
    end
    return mock[:output], mock[:exit_status]
  end

  # - - - - - - - - - - - - - - - - -

  def success
    0
  end

  private

  def complain(cmd, expected, actual)
    raise [
      self.class.name,
      "expected: #{cmd}(#{expected})",
      "  actual: #{cmd}(#{actual})"
    ].join("\n") + "\n"
  end

end

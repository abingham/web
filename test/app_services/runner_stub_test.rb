require_relative 'app_services_test_base'
require_relative 'runner_stub'

class RunnerStubTest < AppServicesTestBase

  def self.hex_prefix
    'AF7'
  end

  def hex_setup
    set_runner_class('RunnerStub')
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '2C0', %w(
  stub_run can stub stdout and leave,
  stderr defaulted to stub empty-string and,
  status defaulted to stub zero and,
  timed_out defaulted to false,
  colour defaulted to red
  ) do
    stdout = 'syntax error line 1'
    runner.stub_run({stdout:stdout})
    json = runner.run_cyber_dojo_sh(*unused_args)
    run = json['run_cyber_dojo_sh']
    assert_equal stdout, run['stdout']['content']
    assert_equal '', run['stderr']['content']
    assert_equal 0, run['status']
    assert_equal false, run['timed_out']
    assert_equal 'red', json['colour']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '09C',
  'stdout,stderr,status,timed_out,colour can all be stubbed explicitly' do
    stub = {
      stdout: 'Assertion failed',
      stderr: 'makefile...',
      status: 2,
      timed_out: true,
      colour: 'amber'
    }
    runner.stub_run(stub)
    json = runner.run_cyber_dojo_sh(*unused_args)
    run = json['run_cyber_dojo_sh']
    assert_equal stub[:stdout], run['stdout']['content']
    assert_equal stub[:stderr], run['stderr']['content']
    assert_equal stub[:status], run['status']
    assert_equal stub[:timed_out], run['timed_out']
    assert_equal stub[:colour], json['colour']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '97A',
  'run without preceeding stub returns so/se/0/false/red' do
    json = runner.run_cyber_dojo_sh(*unused_args)
    run = json['run_cyber_dojo_sh']
    assert_equal 'so', run['stdout']['content']
    assert_equal 'se', run['stderr']['content']
    assert_equal 0, run['status']
    assert_equal false, run['timed_out']
    assert_equal 'red', json['colour']
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '902',
  'stub set in one thread has to be visible in another thread',
  'because app_controller methods are routed into a new thread' do
    stdout = 'syntax error line 1'
    runner.stub_run(stdout:stdout)
    json = nil
    tid = Thread.new {
      json = runner.run_cyber_dojo_sh(*unused_args)
    }
    tid.join
    run = json['run_cyber_dojo_sh']
    assert_equal stdout, run['stdout']['content']
  end

  private

  def unused_args
    args = []
    args << (image_name = nil)
    args << (kata_id = nil)
    args << (files = nil)
    args << (max_seconds = nil)
    args
  end

end

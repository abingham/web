require_relative 'disk_fake'
require 'json'

class RunnerStub

  def initialize(_externals)
    # This is @@disk and not @disk so that it behaves as
    # a real disk on tests that run across multiple threads
    # (as some app-controller tests do).
    @@disk ||= DiskFake.new(self)
  end

  # - - - - - - - - - - - - - - - - -

  def stub_run(stub = {})
    stub[:stdout] ||= ''
    stub[:stderr] ||= ''
    stub[:status] ||= 0
    stub[:timed_out] ||= false
    stub[:colour] ||= 'red'
    dir.make
    dir.write(filename, JSON.generate({
      'run_cyber_dojo_sh' => {
        'stdout' => file(stub[:stdout]),
        'stderr' => file(stub[:stderr]),
        'status' => stub[:status],
        'created' => {},
        'deleted' => [],
        'changed' => {},
        'timed_out' => stub[:timed_out]
      },
      'colour' => stub[:colour]
    }))
  end

  # - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(_image_name, _kata_id, _files, _max_seconds)
    if dir.exists?
      JSON.parse(dir.read(filename))
    else
      { 'run_cyber_dojo_sh' => {
          'stdout' => file('so'),
          'stderr' => file('se'),
          'status' => 0,
          'created' => {},
          'deleted' => [],
          'changed' => {},
          'timed_out' => false
        },
        'colour' => 'red'
      }
    end
  end

  private

  def filename
    'stub_output'
  end

  def dir
    disk[test_id]
  end

  def disk
    @@disk
  end

  def test_id
    ENV['CYBER_DOJO_TEST_ID']
  end

  def file(content)
    { 'content' => content,
      'truncated' => false
    }
  end

end

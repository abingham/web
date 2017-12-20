require_relative 'lib_test_base'
require_relative '../../lib/string_cleaner'

class StringCleanerTest < LibTestBase

  include StringCleaner

  test '3D982',
  'cleans invalid encodings' do
    bad_str = (100..1000).to_a.pack('c*').force_encoding('utf-8')
    refute bad_str.valid_encoding?
    good_str = cleaned(bad_str)
    assert good_str.valid_encoding?
  end

end

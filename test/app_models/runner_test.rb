require_relative 'app_models_test_base'

class RunnerTest < AppModelsTestBase

  def self.hex_prefix
    'Nn2'
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '151',
  'green: expected=42, actual=6*7' do
    runner.stub_run(colour:'green')
    in_new_kata(kata_params) do |kata|
      result = kata.run_tests
      assert_equal false, result[0]['timed_out'], :timed_out
      assert_equal 'green', result[0]['colour'], :colour
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  test '152',
  'timed_out: infinite loop' do
    runner.stub_run(timed_out:true)
    in_new_kata(kata_params) do |kata|
      result = kata.run_tests
      assert_equal true, result[0]['timed_out'], :timed_out
    end
  end

  #- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  # TODO: hidden_filenames
  # TODO: created files
  # TODO: deleted files
  # TODO: changed files

  private

  def kata_params(kata = katas.new_kata(starter_manifest))
    {
      id:kata.id,
      image_name:kata.manifest.image_name,
      max_seconds:kata.manifest.max_seconds,
      file_content:plain(kata.files),
      hidden_filenames:'[]'
    }
  end

end

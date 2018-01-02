require_relative 'app_controller_test_base'

class DashboardControllerTest < AppControllerTestBase

  def self.hex_prefix
    '62AB98'
  end

  #- - - - - - - - - - - - - - - -

  test '971',
  'dashboard when no avatars' do
    in_kata(:stateless) {
      dashboard
      options = [ false, true, 'xxx' ]
      options.each do |mc|
        options.each do |ar|
          dashboard minute_columns: mc, auto_refresh: ar
        end
      end
    }
  end

  #- - - - - - - - - - - - - - - -

  test '29E',
  'dashboard when avatars with no traffic-lights' do
    in_kata(:stateless) {
      4.times { start }
      dashboard
    }
  end

  #- - - - - - - - - - - - - - - -

  test 'E43',
  'dashboard when avatars with some traffic lights' do
    in_kata(:stateless) {
      3.times {
        start
        2.times {
          run_tests
        }
      }
      dashboard
    }
  end

  #- - - - - - - - - - - - - - - -

  test '6CB',
  'heartbeat when no avatars' do
    in_kata(:stateless) {
      heartbeat
    }
  end

  #- - - - - - - - - - - - - - - -

  test '1FB',
  'heartbeat when avatars with no traffic-lights' do
    in_kata(:stateless) {
      start
      heartbeat
    }
  end

  #- - - - - - - - - - - - - - - -

  test '785',
  'heartbeat when some traffic-lights' do
    in_kata(:stateless) {
      3.times {
        start
        2.times {
          run_tests
        }
      }
      heartbeat
    }
  end

  #- - - - - - - - - - - - - - - -

  test '330',
  'progress when no avatars' do
    in_kata(:stateless) {
      progress
    }
  end

  #- - - - - - - - - - - - - - - -

  test '619',
  'progress when avatars with no traffic-lights' do
    in_kata(:stateless) {
      start
      progress
    }
  end

  #- - - - - - - - - - - - - - - -

  test '4FE',
  'progress when avatar has only amber traffic-lights' do
    in_kata(:stateless) {
      start
      runner.stub_run_colour('amber')
      run_tests
      progress
    }
  end

  #- - - - - - - - - - - - - - - -

  test '920',
  'progress when avatar has only non-amber traffic-lights' do
    in_kata(:stateless) {
      start
      runner.stub_run_colour('red')
      run_tests
      progress
    }
  end

  private

  def dashboard(params = {})
    params[:id] = @id
    get '/dashboard/show', params:params
    assert_response :success
  end

  def heartbeat
    params = { :format => :js, :id => @id }
    get '/dashboard/heartbeat', params:params
    assert_response :success
  end

  def progress
    params = { :format => :js, :id => @id }
    get '/dashboard/progress', params:params
    assert_response :success
  end

end

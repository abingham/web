require_relative 'http_helper'

class CustomService

  def initialize(externals)
    @http = HttpHelper.new(externals, self, 'custom', 4526)
  end

  def ready?
    http.get
  end

  def sha
    http.get
  end

  def names
    http.get
  end

  def manifests
    http.get
  end

  def manifest(name)
    http.get(name)
  end

  private

  attr_reader :http

end

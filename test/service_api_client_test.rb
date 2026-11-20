require 'test/unit'
require 'json'
require 'yaml'

class ServiceApiClientTest < Test::Unit::TestCase
  def test_service_api_client_is_published_alongside_http_client
    root = File.expand_path('..', __dir__)
    term = YAML.load_file(File.join(root, 'oss-taxonomy/function/service-api-client.yml'))

    [root, File.join(root, 'docs')].each do |directory|
      functions = JSON.parse(File.read(File.join(directory, 'combined-taxonomy.json'))).fetch('function')
      assert_equal [term], functions.select { |entry| entry.fetch('name') == 'service-api-client' }
      assert_include functions.map { |entry| entry.fetch('name') }, 'http-client'

      ids = File.readlines(File.join(directory, 'terms.txt'), chomp: true)
      assert_equal 1, ids.count('function:service-api-client')
      assert_include ids, 'function:http-client'
    end
  end
end

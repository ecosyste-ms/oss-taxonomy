require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

class OperatingSystemAndFrontendTest < Test::Unit::TestCase
  def test_generator_exports_both_operating_system_facets_and_the_frontend_definition
    root = File.expand_path('..', __dir__)
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(root, 'oss-taxonomy'), dir)
      _, stderr, status = Open3.capture3(RbConfig.ruby, File.join(root, 'combine_yml_to_json.rb'), chdir: dir)
      assert_predicate status, :success?, stderr
      [dir, File.join(dir, 'docs')].each do |output|
        catalog = JSON.parse(File.read(File.join(output, 'combined-taxonomy.json')))
        flat = File.readlines(File.join(output, 'terms.txt'), chomp: true)
        assert_include flat, 'role:operating-system'
        assert_include flat, 'layer:operating-system'
        role = catalog.fetch('role').find { |term| term['name'] == 'operating-system' }
        layer = catalog.fetch('layer').find { |term| term['name'] == 'operating-system' }
        assert_include role.fetch('examples'), 'freertos-kernel'
        assert_include layer.fetch('examples'), 'systemd'
        frontend = catalog.fetch('layer').find { |term| term['name'] == 'frontend' }
        assert_include frontend.fetch('description'), 'presentation layer of a larger product'
        assert_include frontend.fetch('examples'), 'home-assistant-frontend'
      end
    end
  end
end

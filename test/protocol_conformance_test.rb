require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

class ProtocolConformanceTest < Test::Unit::TestCase
  def test_generator_exports_conformance_as_a_function_with_examples_and_aliases
    root = File.expand_path('..', __dir__)
    Dir.mktmpdir do |directory|
      FileUtils.cp_r(File.join(root, 'oss-taxonomy'), directory)
      FileUtils.cp(File.join(root, 'schema.json'), directory)
      _, stderr, status = Open3.capture3(RbConfig.ruby, File.join(root, 'combine_yml_to_json.rb'), chdir: directory)
      assert_predicate status, :success?, stderr
      combined = JSON.parse(File.read(File.join(directory, 'combined-taxonomy.json')))
      term = combined.fetch('function').find { |entry| entry.fetch('name') == 'protocol-conformance' }
      assert_equal %w[autobahn-testsuite lean-rfcs], term.fetch('examples')
      assert_includes term.fetch('aliases'), 'protocol-conformance-testing'
      assert_includes term.fetch('related'), 'testing'
      assert_includes term.fetch('related'), 'validation'
      assert_includes File.readlines(File.join(directory, 'terms.txt'), chomp: true), 'function:protocol-conformance'
      assert_equal 6, combined.values.count { |value| value.is_a?(Array) }
      assert_equal File.read(File.join(directory, 'combined-taxonomy.json')), File.read(File.join(directory, 'docs/combined-taxonomy.json'))
      assert_nil combined.fetch('technology').find { |entry| entry.fetch('name') == 'protocol-conformance' }
    end
  end
end

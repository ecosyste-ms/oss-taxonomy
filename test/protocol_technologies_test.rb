require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

class ProtocolTechnologiesTest < Test::Unit::TestCase
  def test_generator_exports_protocol_and_format_terms_in_the_existing_facet
    root = File.expand_path('..', __dir__)
    expected = %w[http dns tls quic ssh ldap smtp bgp websocket json uri gzip deflate zlib-format]
    Dir.mktmpdir do |directory|
      FileUtils.cp_r(File.join(root, 'oss-taxonomy'), directory)
      FileUtils.cp(File.join(root, 'schema.json'), directory)
      _, stderr, status = Open3.capture3(RbConfig.ruby, File.join(root, 'combine_yml_to_json.rb'), chdir: directory)
      assert_predicate status, :success?, stderr
      combined = JSON.parse(File.read(File.join(directory, 'combined-taxonomy.json')))
      terms = combined.fetch('technology').to_h { |term| [term.fetch('name'), term] }
      flat = File.readlines(File.join(directory, 'terms.txt'), chomp: true)
      names = combined.values.select { |value| value.is_a?(Array) }.flatten.map { |term| term.fetch('name') }
      expected.each do |name|
        assert_includes flat, "technology:#{name}"
        assert_operator terms.fetch(name).fetch('examples').size, :>=, 2
        terms.fetch(name).fetch('related').each { |related| assert_includes names, related }
      end
      assert_equal 6, combined.values.count { |value| value.is_a?(Array) }
      assert_equal File.read(File.join(directory, 'combined-taxonomy.json')), File.read(File.join(directory, 'docs/combined-taxonomy.json'))
      assert_equal File.read(File.join(directory, 'terms.txt')), File.read(File.join(directory, 'docs/terms.txt'))
      assert_equal 3, terms.values_at('gzip', 'deflate', 'zlib-format').map { |term| term.fetch('description') }.uniq.size
    end
  end
end

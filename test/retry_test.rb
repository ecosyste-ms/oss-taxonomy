require 'test/unit'
require 'json'

class RetryTest < Test::Unit::TestCase
  def test_published_taxonomy_includes_retry
    root = File.expand_path('..', __dir__)
    [root, File.join(root, 'docs')].each do |directory|
      functions = JSON.parse(File.read(File.join(directory, 'combined-taxonomy.json'))).fetch('function')
      retry_term = functions.find { |term| term.fetch('name') == 'retry' }
      assert_not_nil retry_term
      assert_include retry_term.fetch('aliases'), 'exponential-backoff'
      assert_equal %w[backoff go-resiliency], retry_term.fetch('examples')
      assert_include File.readlines(File.join(directory, 'terms.txt'), chomp: true), 'function:retry'
    end
  end
end

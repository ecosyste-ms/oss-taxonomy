require 'test/unit'
require 'json'

class TerminalStylingTest < Test::Unit::TestCase
  def test_terminal_styling_is_exported_as_a_distinct_function
    root = File.expand_path('..', __dir__)
    [root, File.join(root, 'docs')].each do |directory|
      functions = JSON.parse(File.read(File.join(directory, 'combined-taxonomy.json'))).fetch('function')
      matches = functions.select { |term| term.fetch('name') == 'terminal-styling' }
      assert_equal 1, matches.size
      assert_equal %w[bunt colors.js], matches.first.fetch('examples')
      assert_include matches.first.fetch('aliases'), 'ansi-styling'
      terms = File.readlines(File.join(directory, 'terms.txt'), chomp: true)
      assert_include terms, 'function:terminal-styling'
    end
  end
end

require 'test/unit'
require 'tmpdir'
require 'fileutils'
require 'json'
require 'open3'

class ScienceFunctionsTest < Test::Unit::TestCase
  EXAMPLES = {
    'code-editing' => 'codemirror',
    'code-formatting' => 'black',
    'dataset-loading' => 'tensorflow-datasets',
    'experiment-tracking' => 'mlflow',
    'font-processing' => 'harfbuzz',
    'llm-orchestration' => 'langchain',
    'map-rendering' => 'leaflet',
    'model-inference' => 'vllm',
    'model-training' => 'xgboost',
    'natural-language-processing' => 'spacy',
    'package-management' => 'conda',
    'parallel-computing' => 'dask',
    'programming-language-detection' => 'linguist',
    'progress-reporting' => 'tqdm',
    'symbolic-computation' => 'sympy',
    'synthetic-data-generation' => 'faker',
    'typesetting' => 'typst'
  }.freeze

  def test_function_examples_are_available_in_both_exports
    root = File.expand_path('..', __dir__)
    Dir.mktmpdir do |dir|
      FileUtils.cp_r(File.join(root, 'oss-taxonomy'), dir)
      _, stderr, status = Open3.capture3(RbConfig.ruby, File.join(root, 'combine_yml_to_json.rb'), chdir: dir)
      assert_predicate status, :success?, stderr
      [dir, File.join(dir, 'docs')].each do |output|
        catalog = JSON.parse(File.read(File.join(output, 'combined-taxonomy.json')))
        functions = catalog.fetch('function').to_h { |entry| [entry.fetch('name'), entry] }
        flat = File.readlines(File.join(output, 'terms.txt'), chomp: true)
        EXAMPLES.each do |name, project|
          assert_include functions.fetch(name).fetch('examples'), project
          assert_include flat, "function:#{name}"
        end
        assert_include flat, 'domain:natural-language-processing'
        assert_include flat, 'role:package-manager'
      end
    end
  end
end

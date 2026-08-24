require 'test/unit'
require 'open3'
require 'rbconfig'
require 'tempfile'
require_relative '../scripts/external_sources'

class ExternalSourcesTest < Test::Unit::TestCase
  def test_clean_html_removes_nested_and_encoded_tags
    nested = ExternalSources::Text.clean_html('before<<script>alert(1)</script>after')
    encoded = ExternalSources::Text.clean_html('before&lt;script&gt;alert(1)&lt;/script&gt;after')

    assert_equal 'beforealert(1)after', nested
    assert_equal 'beforealert(1)after', encoded
  end

  def test_pypi_classifiers_preserve_hierarchy
    html = <<~HTML
      <a href="/search/?c=Topic" data-clipboard-target="source">Topic :: Scientific/Engineering :: Physics</a>
      <a href="/search/?c=Audience" data-clipboard-target="source">Intended Audience :: Developers</a>
    HTML

    records = ExternalSources::PyPIClassifiers.new.parse(html)

    assert_equal 2, records.length
    assert_equal 'topic', records[0]['kind']
    assert_equal ['Topic', 'Scientific/Engineering', 'Physics'], records[0]['path']
    assert_equal 'developers', records[1]['label'].downcase
  end

  def test_crates_categories_include_counts
    body = JSON.generate('categories' => [{
      'slug' => 'accessibility',
      'category' => 'Accessibility',
      'description' => 'Assistive technology.',
      'crates_cnt' => 613
    }])

    record = ExternalSources::CratesCategories.new.parse(body).first

    assert_equal 'accessibility', record['id']
    assert_equal 613, record['count']
  end

  def test_openalex_fields_emit_domain_field_and_subfield_records
    body = JSON.generate('results' => [{
      'id' => 'https://openalex.org/fields/22',
      'display_name' => 'Engineering',
      'description' => 'Engineering research.',
      'works_count' => 10,
      'domain' => { 'id' => 'https://openalex.org/domains/3', 'display_name' => 'Physical Sciences' },
      'subfields' => [{ 'id' => 'https://openalex.org/subfields/2202', 'display_name' => 'Aerospace Engineering' }]
    }])

    records = ExternalSources::OpenAlexFields.new.parse(body)

    assert_equal %w[domain field subfield], records.map { |record| record['kind'] }
    assert_equal ['Physical Sciences', 'Engineering', 'Aerospace Engineering'], records.last['path']
  end

  def test_wikidata_software_classes_extract_entity_ids
    body = JSON.generate('results' => { 'bindings' => [{
      'class' => { 'value' => 'http://www.wikidata.org/entity/Q1403556' },
      'classLabel' => { 'value' => 'reference management software' },
      'count' => { 'value' => '57' }
    }] })

    record = ExternalSources::WikidataSoftwareClasses.new.parse(body).first

    assert_equal 'Q1403556', record['id']
    assert_equal 57, record['count']
  end

  def test_stackoverflow_tags_include_question_counts
    body = JSON.generate('items' => [{ 'name' => 'matlab', 'count' => 94_518 }])

    record = ExternalSources::StackOverflowTags.new.parse(body).first

    assert_equal 'matlab', record['id']
    assert_equal 94_518, record['count']
  end

  def test_freedesktop_categories_preserve_related_categories
    html = (<<~HTML).b
      <table><tbody>
        <tr><td>ProjectManagement</td><td>Project management application</td><td>Office or Development</td></tr>
      </tbody></table>
    HTML

    record = ExternalSources::FreeDesktopCategories.new.parse_table(html, 'additional-category', 'https://example.test').first

    assert_equal 'ProjectManagement', record['id']
    assert_equal ['Office', 'Development'], record['related']
  end

  def test_freedesktop_main_categories_preserve_notes
    html = '<table><tr><td>Audio</td><td>An audio application</td><td>Desktop entry must include AudioVideo as well</td></tr></table>'.b

    record = ExternalSources::FreeDesktopCategories.new.parse_table(html, 'main-category', 'https://example.test').first

    assert_equal 'Desktop entry must include AudioVideo as well', record['notes']
    assert_nil record['related']
  end

  def test_freedesktop_categories_identify_a_saved_main_category_page
    Tempfile.create(['freedesktop-main', '.html']) do |file|
      file.write('<table><thead><tr><th>Main Category</th><th>Description</th><th>Notes</th></tr></thead><tbody><tr><td>Science</td><td>Scientific software</td><td></td></tr></tbody></table>')
      file.flush

      record = ExternalSources::FreeDesktopCategories.new.collect(input: file.path).first

      assert_equal 'main-category', record['kind']
      assert_equal ExternalSources::FreeDesktopCategories::MAIN_URL, record['url']
    end
  end

  def test_stackshare_categories_aggregate_counts_and_examples
    csv = <<~CSV
      name,popularity,category,layer,function
      Git,10,build-test-deploy,devops,version-control-system
      Mercurial,5,build-test-deploy,devops,version-control-system
      Docker,8,build-test-deploy,devops,container-tools
    CSV

    records = ExternalSources::StackShareCategories.new.parse(csv)
    function = records.find { |record| record['id'] == 'version-control-system' }

    assert_equal 2, function['count']
    assert_equal ['Git', 'Mercurial'], function['examples']
    assert_equal 15.0, function.dig('metrics', 'popularity')
  end

  def test_stackshare_categories_prefer_the_local_snapshot
    Tempfile.create(['stackshare-tools', '.csv']) do |file|
      file.write(<<~CSV)
        name,popularity,category,layer,function
        Git,10,build-test-deploy,devops,version-control-system
      CSV
      file.flush

      records = ExternalSources::StackShareCategories.new(client: Object.new, local_path: file.path).collect

      assert_equal %w[category function layer], records.map { |record| record['kind'] }
    end
  end

  def test_formatter_supports_json_lines
    rendered = ExternalSources::Formatter.render([{ 'source' => 'test', 'kind' => 'tag', 'id' => 'ruby', 'label' => 'ruby' }], 'jsonl')

    assert_equal({ 'source' => 'test', 'kind' => 'tag', 'id' => 'ruby', 'label' => 'ruby' }, JSON.parse(rendered))
  end

  def test_cli_collects_and_filters_a_local_source
    Tempfile.create(['stackshare-tools', '.csv']) do |file|
      file.write(<<~CSV)
        name,popularity,category,layer,function
        Git,10,build-test-deploy,devops,version-control-system
        Docker,8,build-test-deploy,devops,container-tools
      CSV
      file.flush

      script = File.expand_path('../scripts/collect_external_source.rb', __dir__)
      stdout, stderr, status = Open3.capture3(
        RbConfig.ruby,
        script,
        'stackshare-categories',
        '--input', file.path,
        '--kind', 'function',
        '--limit', '1',
        '--format', 'json'
      )

      assert_predicate status, :success?, stderr
      assert_equal ['container-tools'], JSON.parse(stdout).map { |record| record['id'] }
    end
  end
end

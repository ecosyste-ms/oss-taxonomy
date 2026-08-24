require 'cgi/escape'
require 'csv'
require 'json'
require 'net/http'
require 'uri'

module ExternalSources
  USER_AGENT = 'oss-taxonomy external source collector (https://github.com/ecosyste-ms/oss-taxonomy)'

  class HTTPClient
    def get(url, redirects: 3)
      uri = URI(url)
      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = USER_AGENT

      response = Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == 'https',
        open_timeout: 15,
        read_timeout: 120
      ) { |http| http.request(request) }

      return response.body if response.is_a?(Net::HTTPSuccess)

      if response.is_a?(Net::HTTPRedirection) && redirects.positive?
        return get(URI.join(url, response['location']).to_s, redirects: redirects - 1)
      end

      raise "#{response.code} #{response.message} for #{url}"
    end
  end

  module Input
    def self.read(value, client)
      return client.get(value) if value.match?(/\Ahttps?:\/\//)

      File.read(value)
    end
  end

  module Text
    def self.clean_html(value)
      text = CGI.unescapeHTML(value.to_s.dup.force_encoding(Encoding::UTF_8).scrub)
      plain_text = +''
      inside_tag = false

      text.each_char do |character|
        if character == '<'
          inside_tag = true
        elsif inside_tag
          inside_tag = false if character == '>'
        else
          plain_text << character
        end
      end

      plain_text.tr("\u00A0", ' ').strip
    end

    def self.slug(value)
      value.to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-|\-\z/, '')
    end
  end

  class PyPIClassifiers
    URL = 'https://pypi.org/classifiers/'

    def initialize(client: HTTPClient.new, limit: nil)
      @client = client
      @limit = limit
    end

    def collect(input: nil)
      parse(input ? Input.read(input, @client) : @client.get(URL))
    end

    def parse(html)
      classifiers = html.scan(/<a[^>]+data-clipboard-target="source"[^>]*>(.*?)<\/a>/m).flatten

      classifiers.map do |classifier|
        classifier = Text.clean_html(classifier)
        path = classifier.split(' :: ')
        {
          'source' => 'pypi',
          'kind' => Text.slug(path.first),
          'id' => classifier,
          'label' => path.last,
          'path' => path,
          'url' => "https://pypi.org/search/?#{URI.encode_www_form(c: classifier)}"
        }
      end.first(@limit || classifiers.length)
    end
  end

  class CratesCategories
    URL = 'https://crates.io/api/v1/categories?page=1&per_page=100'

    def initialize(client: HTTPClient.new, limit: nil)
      @client = client
      @limit = limit
    end

    def collect(input: nil)
      parse(input ? Input.read(input, @client) : @client.get(URL))
    end

    def parse(body)
      JSON.parse(body).fetch('categories').map do |category|
        {
          'source' => 'crates.io',
          'kind' => 'category',
          'id' => category.fetch('slug'),
          'label' => category.fetch('category'),
          'count' => category.fetch('crates_cnt'),
          'description' => category['description'],
          'url' => "https://crates.io/categories/#{category.fetch('slug')}"
        }.compact
      end.first(@limit || 100)
    end
  end

  class OpenAlexFields
    URL = 'https://api.openalex.org/fields?per-page=100'

    def initialize(client: HTTPClient.new, limit: nil)
      @client = client
      @limit = limit
    end

    def collect(input: nil)
      parse(input ? Input.read(input, @client) : @client.get(URL))
    end

    def parse(body)
      records = {}

      JSON.parse(body).fetch('results').each do |field|
        domain = field.fetch('domain')
        records[['domain', domain.fetch('id')]] ||= {
          'source' => 'openalex',
          'kind' => 'domain',
          'id' => domain.fetch('id'),
          'label' => domain.fetch('display_name'),
          'path' => [domain.fetch('display_name')],
          'url' => domain.fetch('id')
        }

        records[['field', field.fetch('id')]] = {
          'source' => 'openalex',
          'kind' => 'field',
          'id' => field.fetch('id'),
          'label' => field.fetch('display_name'),
          'path' => [domain.fetch('display_name'), field.fetch('display_name')],
          'count' => field['works_count'],
          'description' => field['description'],
          'url' => field.fetch('id')
        }.compact

        Array(field['subfields']).each do |subfield|
          records[['subfield', subfield.fetch('id')]] = {
            'source' => 'openalex',
            'kind' => 'subfield',
            'id' => subfield.fetch('id'),
            'label' => subfield.fetch('display_name'),
            'path' => [domain.fetch('display_name'), field.fetch('display_name'), subfield.fetch('display_name')],
            'url' => subfield.fetch('id')
          }
        end
      end

      records.values.first(@limit || records.length)
    end
  end

  class WikidataSoftwareClasses
    ENDPOINT = 'https://query.wikidata.org/sparql'
    QUERY = <<~SPARQL.freeze
      SELECT ?class ?classLabel (COUNT(?software) AS ?count)
      WHERE {
        ?class wdt:P279 wd:Q7397.
        ?software wdt:P31 ?class.
        SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
      }
      GROUP BY ?class ?classLabel
      ORDER BY DESC(?count)
      LIMIT %<limit>d
    SPARQL

    def initialize(client: HTTPClient.new, limit: 200)
      @client = client
      @limit = limit || 200
    end

    def collect(input: nil)
      return parse(Input.read(input, @client)) if input

      query = format(QUERY, limit: @limit)
      url = "#{ENDPOINT}?#{URI.encode_www_form(format: 'json', query: query)}"
      parse(@client.get(url))
    end

    def parse(body)
      JSON.parse(body).dig('results', 'bindings').map do |binding|
        entity_url = binding.dig('class', 'value').sub('http://', 'https://')
        {
          'source' => 'wikidata',
          'kind' => 'software-class',
          'id' => entity_url.split('/').last,
          'label' => binding.dig('classLabel', 'value'),
          'count' => binding.dig('count', 'value').to_i,
          'url' => entity_url
        }
      end.first(@limit)
    end
  end

  class StackOverflowTags
    ENDPOINT = 'https://api.stackexchange.com/2.3/tags'

    def initialize(client: HTTPClient.new, limit: 100)
      @client = client
      @limit = limit || 100
    end

    def collect(input: nil)
      return parse(Input.read(input, @client)).first(@limit) if input

      records = []
      page = 1

      while records.length < @limit
        per_page = [@limit - records.length, 100].min
        query = URI.encode_www_form(site: 'stackoverflow', sort: 'popular', order: 'desc', pagesize: per_page, page: page)
        body = @client.get("#{ENDPOINT}?#{query}")
        parsed = JSON.parse(body)
        records.concat(records_from(parsed))
        break unless parsed['has_more']

        page += 1
      end

      records.first(@limit)
    end

    def parse(body)
      records_from(JSON.parse(body))
    end

    def records_from(payload)
      payload.fetch('items').map do |tag|
        name = tag.fetch('name')
        {
          'source' => 'stackoverflow',
          'kind' => 'tag',
          'id' => name,
          'label' => name,
          'count' => tag.fetch('count'),
          'url' => "https://stackoverflow.com/questions/tagged/#{URI.encode_www_form_component(name)}"
        }
      end
    end
  end

  class FreeDesktopCategories
    MAIN_URL = 'https://specifications.freedesktop.org/menu/latest/category-registry.html'
    ADDITIONAL_URL = 'https://specifications.freedesktop.org/menu/latest/additional-category-registry.html'

    def initialize(client: HTTPClient.new, limit: nil)
      @client = client
      @limit = limit
    end

    def collect(input: nil)
      records = if input
        body = Input.read(input, @client)
        kind = body.match?(/<th[^>]*>Main Category<\/th>/) ? 'main-category' : 'additional-category'
        url = kind == 'main-category' ? MAIN_URL : ADDITIONAL_URL
        parse_table(body, kind, url)
      else
        parse_table(@client.get(MAIN_URL), 'main-category', MAIN_URL) +
          parse_table(@client.get(ADDITIONAL_URL), 'additional-category', ADDITIONAL_URL)
      end

      records.first(@limit || records.length)
    end

    def parse_table(html, kind, url)
      html.scan(/<tr>(.*?)<\/tr>/m).filter_map do |row_match|
        cells = row_match.first.scan(/<t[dh][^>]*>(.*?)<\/t[dh]>/m).flatten.map { |cell| Text.clean_html(cell) }
        next if cells.length < 2 || cells.first.match?(/Category\z/)

        record = {
          'source' => 'freedesktop',
          'kind' => kind,
          'id' => cells.first,
          'label' => cells.first,
          'description' => cells[1],
          'url' => url
        }

        details = cells.fetch(2, '')
        if kind == 'main-category'
          record['notes'] = details unless details.empty?
        else
          record['related'] = details.split(/\s+or\s+|;/).map(&:strip).reject(&:empty?)
        end

        record
      end
    end
  end

  class StackShareCategories
    URL = 'https://raw.githubusercontent.com/captn3m0/stackshare-dataset/main/tools.csv'
    LOCAL_PATH = File.expand_path('../data/external/stackshare-tools.csv', __dir__)

    def initialize(client: HTTPClient.new, limit: nil, local_path: LOCAL_PATH)
      @client = client
      @limit = limit
      @local_path = local_path
    end

    def collect(input: nil)
      source = input || (File.exist?(@local_path) ? @local_path : URL)
      parse(Input.read(source, @client))
    end

    def parse(body)
      rows = CSV.parse(body, headers: true)
      records = %w[category layer function].flat_map do |kind|
        rows.group_by { |row| row[kind] }.filter_map do |label, matches|
          next if label.nil? || label.empty?

          examples = matches.sort_by { |row| -row['popularity'].to_f }.first(5).map { |row| row['name'] }
          {
            'source' => 'stackshare',
            'kind' => kind,
            'id' => label,
            'label' => label,
            'count' => matches.length,
            'examples' => examples,
            'metrics' => { 'popularity' => matches.sum { |row| row['popularity'].to_f }.round(1) },
            'url' => 'https://github.com/captn3m0/stackshare-dataset'
          }
        end
      end

      records.sort_by { |record| [record.fetch('kind'), -record.fetch('count'), record.fetch('label')] }
        .first(@limit || records.length)
    end
  end

  SOURCES = {
    'crates-categories' => CratesCategories,
    'freedesktop-categories' => FreeDesktopCategories,
    'openalex-fields' => OpenAlexFields,
    'pypi-classifiers' => PyPIClassifiers,
    'stackoverflow-tags' => StackOverflowTags,
    'stackshare-categories' => StackShareCategories,
    'wikidata-software-classes' => WikidataSoftwareClasses
  }.freeze
  MULTI_KIND_SOURCES = %w[
    freedesktop-categories
    openalex-fields
    pypi-classifiers
    stackshare-categories
  ].freeze

  def self.names
    SOURCES.keys.sort
  end

  def self.build(name, limit: nil, client: HTTPClient.new)
    collector = SOURCES[name]
    raise ArgumentError, "Unknown source: #{name}" unless collector

    collector.new(client: client, limit: limit)
  end

  def self.multiple_kinds?(name)
    MULTI_KIND_SOURCES.include?(name)
  end

  module Formatter
    def self.render(records, format)
      case format
      when 'json'
        JSON.pretty_generate(records)
      when 'jsonl'
        records.map { |record| JSON.generate(record) }.join("\n")
      when 'tsv'
        CSV.generate(col_sep: "\t") do |csv|
          csv << %w[source kind id label count path description url]
          records.each do |record|
            csv << [
              record['source'],
              record['kind'],
              record['id'],
              record['label'],
              record['count'],
              Array(record['path']).join(' > '),
              record['description'],
              record['url']
            ]
          end
        end
      else
        raise ArgumentError, "Unknown format: #{format}"
      end
    end
  end
end

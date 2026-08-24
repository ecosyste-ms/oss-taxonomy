require 'optparse'
require_relative 'external_sources'

options = {
  format: 'json',
  limit: nil,
  input: nil,
  kind: nil
}

parser = OptionParser.new do |opts|
  opts.banner = 'Usage: bundle exec ruby scripts/collect_external_source.rb SOURCE [options]'
  opts.on('--format FORMAT', 'json, jsonl, or tsv') { |value| options[:format] = value }
  opts.on('--input PATH_OR_URL', 'Read source data from a local file or URL') { |value| options[:input] = value }
  opts.on('--kind KIND', 'Keep records with this kind') { |value| options[:kind] = value }
  opts.on('--limit COUNT', Integer, 'Limit the number of records') { |value| options[:limit] = value }
  opts.on('--list', 'List available sources') do
    puts ExternalSources.names
    exit
  end
end

parser.parse!
source = ARGV.shift
abort parser.to_s unless source

collector_limit = options[:kind] && ExternalSources.multiple_kinds?(source) ? nil : options[:limit]
collector = ExternalSources.build(source, limit: collector_limit)
records = collector.collect(input: options[:input])
records = records.select { |record| record['kind'] == options[:kind] } if options[:kind]
records = records.first(options[:limit]) if options[:kind] && options[:limit]
puts ExternalSources::Formatter.render(records, options[:format])

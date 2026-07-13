# frozen_string_literal: true

lib_dir = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require "json"
require "optparse"
require "multi_json"

# Benchmark harness for comparing MultiJSON adapters across parse and generate workloads.
class MultiJSONBenchmark
  AdapterEntry = Struct.new(:name, :klass, keyword_init: true)
  PayloadCase = Struct.new(:shape, :bucket, :label, :object, :json, :bytes, keyword_init: true)
  Measurement = Struct.new(:payload, :operation, :adapter, :ips, :mbps, keyword_init: true)

  ADAPTER_NAMES = %i[fast_jsonparser oj yajl jr_jackson json_gem gson].freeze
  BYTES_PER_MEGABYTE = 1024.0 * 1024.0
  CLOCK = Process::CLOCK_MONOTONIC
  EPSILON = 1e-12
  MAX_ITERATIONS = 1_000_000
  DEFAULTS = {
    warmup: 0.03,
    time: 0.15,
    samples: 5,
    format: :plain,
    verify_preference: false
  }.freeze

  class << self
    def run(argv = ARGV)
      options = CLI.new.parse(argv)
      adapters = AdapterLoader.new.load(options[:adapters])
      raise "No supported adapters are available for benchmarking" if adapters.empty?

      measurements = Runner.new(adapters:, payloads: PayloadCatalog.new.build, options:).run
      Reporter.new(adapters:, measurements:, options:).print
      options[:verify_preference] ? verify_preference(adapters, measurements) : 0
    end

    private

    def verify_preference(adapters, measurements)
      verifier = PreferenceVerifier.new(adapters: adapters, measurements: measurements)
      verifier.report
      verifier.valid? ? 0 : 1
    end
  end

  # Command-line option parsing for the benchmark script.
  class CLI
    QUICK_OPTIONS = {
      warmup: 0.005,
      time: 0.02,
      samples: 1
    }.freeze
    private_constant :QUICK_OPTIONS

    def parse(argv)
      options = MultiJSONBenchmark::DEFAULTS.dup
      parser(options).parse!(argv)
      validate!(options)
      options
    end

    private

    def parser(options)
      OptionParser.new do |opts|
        opts.banner = "Usage: bundle exec ruby benchmark.rb [options]"
        add_timing_options(opts, options)
        add_format_options(opts, options)
        add_quick_option(opts, options)
      end
    end

    def add_timing_options(parser, options)
      add_warmup_option(parser, options)
      add_time_option(parser, options)
      add_samples_option(parser, options)
    end

    def add_format_options(parser, options)
      parser.on("--adapters x,y,z", Array, "Restrict to specific adapters") do |value|
        options[:adapters] = value.map { |name| name.strip.to_sym }
      end
      parser.on("--format FORMAT", %w[plain markdown], "Output format: plain or markdown") do |value|
        options[:format] = value.to_sym
      end
    end

    def add_quick_option(parser, options)
      parser.on("--quick", "Smoke-test mode with shorter timings") do
        options.merge!(QUICK_OPTIONS)
      end
      parser.on("--verify-preference", "Assert MultiJSON adapter preferences match benchmark ranking") do
        options[:verify_preference] = true
      end
    end

    def add_warmup_option(parser, options)
      parser.on(
        "--warmup SECONDS",
        Float,
        "Warmup time budget per benchmark (default: #{MultiJSONBenchmark::DEFAULTS[:warmup]})"
      ) do |value|
        options[:warmup] = value
      end
    end

    def add_time_option(parser, options)
      parser.on("--time SECONDS", Float, "Measurement time budget per sample (default: #{MultiJSONBenchmark::DEFAULTS[:time]})") do |value|
        options[:time] = value
      end
    end

    def add_samples_option(parser, options)
      parser.on("--samples COUNT", Integer, "Samples per benchmark (default: #{MultiJSONBenchmark::DEFAULTS[:samples]})") do |value|
        options[:samples] = value
      end
    end

    def validate!(options)
      validate_warmup!(options[:warmup])
      validate_time!(options[:time])
      validate_samples!(options[:samples])
    end

    def validate_warmup!(value)
      raise OptionParser::InvalidArgument, "--warmup must be >= 0" if value.negative?
    end

    def validate_time!(value)
      raise OptionParser::InvalidArgument, "--time must be > 0" unless value.positive?
    end

    def validate_samples!(value)
      raise OptionParser::InvalidArgument, "--samples must be > 0" unless value.positive?
    end
  end

  # Resolves benchmarkable adapters from the current Ruby environment.
  class AdapterLoader
    def load(selected = nil)
      adapter_names(selected).filter_map { |name| load_entry(name) }
    end

    private

    def adapter_names(selected)
      selected || MultiJSONBenchmark::ADAPTER_NAMES
    end

    def load_entry(name)
      klass = MultiJSON::AdapterSelector.send(:load_adapter, name)
      MultiJSONBenchmark::AdapterEntry.new(name: name, klass: klass)
    rescue MultiJSON::AdapterError
      warn "Skipping adapter #{name.inspect}: not available"
      nil
    end
  end

  # Builds the benchmark payload matrix across shapes and sizes.
  class PayloadCatalog
    CASES = [
      [:flat_scalars, :small, 40],
      [:flat_scalars, :medium, 400],
      [:flat_scalars, :large, 4_000],
      [:nested_records, :small, 8],
      [:nested_records, :medium, 64],
      [:nested_records, :large, 384],
      [:array_heavy, :small, 250],
      [:array_heavy, :medium, 2_500],
      [:array_heavy, :large, 25_000]
    ].freeze
    private_constant :CASES

    def build
      CASES.map { |shape, bucket, count| payload_case(shape, bucket, payload_object(shape, count)) }
    end

    private

    def payload_object(shape, count)
      case shape
      when :flat_scalars then MultiJSONBenchmark::ScalarPayloadFactory.new.flat_scalars(count)
      when :nested_records then MultiJSONBenchmark::RecordPayloadFactory.new.nested_records(count)
      else MultiJSONBenchmark::ScalarPayloadFactory.new.array_heavy(count)
      end
    end

    def payload_case(shape, bucket, object)
      json = JSON.generate(object).freeze
      MultiJSONBenchmark::PayloadCase.new(
        shape: shape,
        bucket: bucket,
        label: "#{shape}/#{bucket}",
        object: object,
        json: json,
        bytes: json.bytesize
      )
    end
  end

  # Builds flat scalar and array-heavy payloads.
  class ScalarPayloadFactory
    def flat_scalars(count)
      Array.new(count) { |index| scalar_field(index) }.to_h
    end

    def array_heavy(count)
      {
        "ints" => Array.new(count) { |index| index },
        "floats" => Array.new(count) { |index| ((index * 7) % 100_000) / 31.0 },
        "booleans" => Array.new(count, &:even?),
        "strings" => Array.new(count / 2) { |index| token("str", index, 18) },
        "matrix" => matrix(count)
      }
    end

    private

    def scalar_field(index)
      ["field_#{index}", scalar_value(index)]
    end

    def scalar_value(index)
      case index % 6
      when 0 then index
      when 1 then ((index * 13) % 10_000) / 10.0
      when 2 then token("value", index, 20)
      when 3 then index.even?
      when 4 then nil
      else scalar_tags(index)
      end
    end

    def scalar_tags(index)
      [token("tag", index, 6), token("tag", index + 1, 6), token("tag", index + 2, 6)]
    end

    def matrix(count)
      Array.new(count / 25) do |row|
        Array.new(20) { |column| (row * 20) + column }
      end
    end

    def token(prefix, index, width)
      "#{prefix}_#{index.to_s(36).rjust(width, "0")}"
    end
  end

  # Builds nested object-heavy record payloads.
  class RecordPayloadFactory
    COUNTRIES = %w[US DE BR JP IN AU GB CA].freeze
    EVENT_TYPES = %w[create update sync archive].freeze
    RECORD_TYPES = %w[user team account project].freeze
    private_constant :COUNTRIES, :EVENT_TYPES, :RECORD_TYPES

    def nested_records(count)
      {
        "meta" => metadata(count),
        "data" => Array.new(count) { |index| record(index) }
      }
    end

    private

    def metadata(count)
      {
        "count" => count,
        "generated_at" => "2026-01-01T00:00:00Z",
        "source" => "benchmark"
      }
    end

    def record(index)
      {
        "id" => index,
        "external_id" => token("user", index, 10),
        "type" => RECORD_TYPES[index % RECORD_TYPES.length],
        "active" => (index % 3).zero?,
        "profile" => profile(index),
        "metrics" => metrics(index),
        "events" => events(index)
      }
    end

    def profile(index)
      {
        "name" => token("name", index, 14),
        "email" => "user#{index}@example.test",
        "country" => COUNTRIES[index % COUNTRIES.length],
        "segments" => Array.new(4) { |offset| token("segment", index + offset, 6) }
      }
    end

    def metrics(index)
      {
        "logins" => index * 3,
        "score" => ((index * 17) % 10_000) / 100.0,
        "quota" => quota(index)
      }
    end

    def quota(index)
      used = index % 500
      {
        "used" => used,
        "limit" => 500,
        "overage" => used > 450
      }
    end

    def events(index)
      Array.new(3) { |offset| event(index + offset) }
    end

    def event(event_index)
      {
        "at" => event_timestamp(event_index),
        "type" => EVENT_TYPES[event_index % EVENT_TYPES.length],
        "delta" => (event_index % 17) - 8
      }
    end

    def event_timestamp(event_index)
      format("2026-02-%<day>02dT12:%<minute>02d:00Z", day: (event_index % 28) + 1, minute: event_index % 60)
    end

    def token(prefix, index, width)
      "#{prefix}_#{index.to_s(36).rjust(width, "0")}"
    end
  end

  # Runs the benchmark matrix across adapters, payloads, and operations.
  class Runner
    OPERATIONS = %i[parse generate].freeze
    private_constant :OPERATIONS

    def initialize(adapters:, payloads:, options:)
      @adapters = adapters
      @payloads = payloads
      @options = options
      @sampler = MultiJSONBenchmark::Sampler.new(options)
    end

    def run
      payloads.each_with_index.flat_map do |payload, payload_index|
        OPERATIONS.each_with_index.flat_map do |operation, operation_index|
          run_operation(payload, operation, payload_index + operation_index)
        end
      end
    end

    private

    attr_reader :adapters, :payloads, :options, :sampler

    def run_operation(payload, operation, index)
      puts "Benchmarking #{operation} #{payload.label} (#{MultiJSONBenchmark::Formatter.human_bytes(payload.bytes)})"
      rotated_adapters(index).map { |adapter| measure(adapter, payload, operation) }
    end

    def rotated_adapters(index)
      adapters.rotate(index % adapters.length)
    end

    def measure(adapter, payload, operation)
      prime_adapter!(adapter.klass, payload)
      ips = sampler.sample(adapter.klass, payload, operation)
      MultiJSONBenchmark::Measurement.new(
        payload: payload,
        operation: operation,
        adapter: adapter.name,
        ips: ips,
        mbps: (ips * payload.bytes) / MultiJSONBenchmark::BYTES_PER_MEGABYTE
      )
    end

    def prime_adapter!(adapter, payload)
      adapter.load(payload.json)
      adapter.dump(payload.object)
    end
  end

  # Measures throughput for a single adapter/payload/operation combination.
  class Sampler
    def initialize(options)
      @options = options
    end

    def sample(adapter, payload, operation)
      work = work_for(adapter, payload, operation)
      iterations = estimate_iterations(work)
      warmup(work, iterations)
      MultiJSONBenchmark::Formatter.median(sample_rates(work, iterations))
    end

    private

    attr_reader :options

    def work_for(adapter, payload, operation)
      return -> { adapter.load(payload.json) } if operation == :parse

      -> { adapter.dump(payload.object) }
    end

    def warmup(work, iterations)
      warmup_iterations = [(iterations * options[:warmup] / options[:time]).round, 1].max
      timed_loop(work, warmup_iterations)
    end

    def sample_rates(work, iterations)
      Array.new(options[:samples]) do
        GC.start
        elapsed = with_gc_disabled { timed_loop(work, iterations) }
        iterations / [elapsed, MultiJSONBenchmark::EPSILON].max
      end
    end

    def estimate_iterations(work)
      iterations = 1
      elapsed = with_gc_disabled { timed_loop(work, iterations) }

      while elapsed < 0.001 && iterations < MultiJSONBenchmark::MAX_ITERATIONS
        iterations *= 10
        elapsed = with_gc_disabled { timed_loop(work, iterations) }
      end

      estimated = ((options[:time] / [elapsed, MultiJSONBenchmark::EPSILON].max) * iterations).ceil
      estimated.clamp(1, MultiJSONBenchmark::MAX_ITERATIONS)
    end

    def timed_loop(work, iterations)
      started_at = Process.clock_gettime(MultiJSONBenchmark::CLOCK)
      sink = nil
      iterations.times { sink = work.call }
      raise "Benchmark produced nil" if sink.nil?

      Process.clock_gettime(MultiJSONBenchmark::CLOCK) - started_at
    end

    def with_gc_disabled
      already_disabled = GC.disable
      yield
    ensure
      GC.enable unless already_disabled
    end
  end

  # Prints the benchmark summary and detailed result tables.
  class Reporter
    SUMMARY_HEADERS = ["adapter", "parse score", "generate score", "overall score", "wins"].freeze
    SUMMARY_ALIGNMENTS = %i[left right right right right].freeze
    private_constant :SUMMARY_HEADERS, :SUMMARY_ALIGNMENTS

    def initialize(adapters:, measurements:, options:)
      @adapters = adapters
      @measurements = measurements
      @options = options
    end

    def print
      print_header
      print_summary
      puts
      print_details
    end

    private

    attr_reader :adapters, :measurements, :options

    def print_header
      puts
      puts "Ruby: #{RUBY_ENGINE} #{RUBY_VERSION} (#{RUBY_PLATFORM})"
      puts "Adapters: #{adapters.map(&:name).join(", ")}"
      puts "Method: median ops/s across #{options[:samples]} sample(s); overall score is the geometric"
      puts "mean of per-benchmark throughput normalized to that benchmark's winner, with parse and"
      puts "generate weighted equally."
      puts
    end

    def print_summary
      rows = MultiJSONBenchmark::Summary.new(adapters, measurements).rows
      puts "Overall winner: #{rows.first[0]}"
      puts MultiJSONBenchmark::TableRenderer.new(format: options[:format]).render(SUMMARY_HEADERS, rows, alignments: SUMMARY_ALIGNMENTS)
    end

    def print_details
      detail = MultiJSONBenchmark::Details.new(adapters, measurements)
      puts MultiJSONBenchmark::TableRenderer.new(format: options[:format]).render(
        detail.headers,
        detail.rows,
        alignments: detail.alignments
      )
    end
  end

  # Asserts MultiJSON::AdapterSelector::ADAPTERS matches the overall
  # benchmark throughput ranking.
  #
  # Compares only the adapters that both appear in ADAPTERS and were
  # benchmarked on this run, so missing native adapters (e.g.
  # fast_jsonparser on JRuby) are tolerated rather than treated as
  # failures. Adjacent adapters whose observed scores fall within
  # TOLERANCE of each other are treated as tied so noisy benchmark
  # runs that flip close pairs don't trigger a failure.
  class PreferenceVerifier
    TOLERANCE = 0.10
    private_constant :TOLERANCE

    def initialize(adapters:, measurements:)
      @adapters = adapters
      @measurements = measurements
    end

    def valid?
      violations.empty?
    end

    def report
      puts
      if valid?
        puts "ADAPTERS matches benchmark ranking within #{tolerance_pct}% tolerance: #{relevant_adapters.join(", ")}"
      else
        puts "ADAPTERS does not match benchmark ranking (>#{tolerance_pct}% tolerance):"
        violations.each { |violation| puts "  #{format_violation(violation)}" }
      end
    end

    private

    attr_reader :adapters, :measurements

    def preference_order
      MultiJSON::AdapterSelector::REQUIREMENT_MAP.keys
    end

    def scores
      @scores ||= measurements
        .group_by(&:adapter)
        .transform_values { |entries| MultiJSONBenchmark::Formatter.geometric_mean(entries.map(&:ips)) }
    end

    def relevant_adapters
      @relevant_adapters ||= preference_order.select { |adapter| scores.key?(adapter) }
    end

    def violations
      @violations ||= relevant_adapters.each_cons(2).filter_map do |earlier, later|
        violation_for(earlier, later)
      end
    end

    def violation_for(earlier, later)
      earlier_score = scores.fetch(earlier)
      later_score = scores.fetch(later)
      return nil if later_score <= earlier_score * (1 + TOLERANCE)

      {earlier: earlier, later: later, earlier_score: earlier_score, later_score: later_score}
    end

    def format_violation(violation)
      later = violation.fetch(:later)
      earlier = violation.fetch(:earlier)
      later_score = format_score(violation.fetch(:later_score))
      earlier_score = format_score(violation.fetch(:earlier_score))
      excess = (((violation.fetch(:later_score) / violation.fetch(:earlier_score)) - 1) * 100).round
      "#{later} (#{later_score} ops/s) outranks #{earlier} (#{earlier_score} ops/s) by #{excess}% but is preferenced after it"
    end

    def format_score(value)
      Kernel.format("%.0f", value)
    end

    def tolerance_pct
      (TOLERANCE * 100).to_i
    end
  end

  # Computes overall adapter scores and benchmark wins.
  class Summary
    def initialize(adapters, measurements)
      @adapters = adapters
      @measurements = measurements
    end

    def rows
      adapters
        .map { |adapter| summary_row(adapter) }
        .sort_by { |row| -row[3].to_f }
    end

    private

    attr_reader :adapters, :measurements

    def summary_row(adapter)
      parse_score = score_for(adapter.name, :parse)
      generate_score = score_for(adapter.name, :generate)
      [
        adapter.name.to_s,
        format("%.3f", parse_score),
        format("%.3f", generate_score),
        format("%.3f", Math.sqrt(parse_score * generate_score)),
        wins.fetch(adapter.name, 0).to_s
      ]
    end

    def score_for(adapter_name, operation)
      values = grouped_ratios.fetch(operation).fetch(adapter_name)
      MultiJSONBenchmark::Formatter.geometric_mean(values)
    end

    def grouped_ratios
      @grouped_ratios ||= begin
        ratios = {
          parse: Hash.new { |hash, key| hash[key] = [] },
          generate: Hash.new { |hash, key| hash[key] = [] }
        }
        grouped_measurements.each_value { |entries| append_ratios(ratios, entries) }
        ratios
      end
    end

    def wins
      @wins ||= begin
        counts = Hash.new(0)
        grouped_measurements.each_value { |entries| counts[entries.max_by(&:ips).adapter] += 1 }
        counts
      end
    end

    def grouped_measurements
      @grouped_measurements ||= measurements.group_by { |measurement| [measurement.payload.label, measurement.operation] }
    end

    def append_ratios(ratios, entries)
      peak = entries.max_by(&:ips).ips
      entries.each do |entry|
        ratios[entry.operation][entry.adapter] << normalized_ratio(entry.ips, peak)
      end
    end

    def normalized_ratio(value, peak)
      value / [peak, MultiJSONBenchmark::EPSILON].max
    end
  end

  # Builds the per-benchmark detail table rows.
  class Details
    def initialize(adapters, measurements)
      @adapters = adapters
      @measurements = measurements
    end

    def headers
      ["benchmark", "bytes", *adapters.map { |adapter| "#{adapter.name} ops/s" }, "winner"]
    end

    def rows
      ordered_keys.map { |key| detail_row(key) }
    end

    def alignments
      [:left, :right, *Array.new(adapters.length, :right), :left]
    end

    private

    attr_reader :adapters, :measurements

    def detail_row(key)
      entries = grouped_measurements.fetch(key)
      [
        benchmark_label(key),
        byte_label(entries),
        *adapter_rates(index_entries(entries)),
        winner_label(entries)
      ]
    end

    def benchmark_label(key)
      "#{key[1]} #{key[0]}"
    end

    def byte_label(entries)
      MultiJSONBenchmark::Formatter.human_bytes(entries.first.payload.bytes)
    end

    def index_entries(entries)
      entries.to_h { |entry| [entry.adapter, entry] }
    end

    def adapter_rates(indexed)
      adapters.map { |adapter| MultiJSONBenchmark::Formatter.format_rate(indexed.fetch(adapter.name).ips) }
    end

    def winner_label(entries)
      fastest = entries.max_by(&:ips)
      rate = MultiJSONBenchmark::Formatter.format_rate(fastest.ips)
      "#{fastest.adapter} (#{rate})"
    end

    def ordered_keys
      @ordered_keys ||= measurements.map { |measurement| [measurement.payload.label, measurement.operation] }.uniq
    end

    def grouped_measurements
      @grouped_measurements ||= measurements.group_by { |measurement| [measurement.payload.label, measurement.operation] }
    end
  end

  # Renders plain-text and markdown tables for benchmark output.
  class TableRenderer
    def initialize(format:)
      @format = format
    end

    def render(headers, rows, alignments:)
      widths = column_widths(headers, rows)
      return markdown_table(headers, rows, widths) if format == :markdown

      plain_table(headers, rows, widths, alignments)
    end

    private

    attr_reader :format

    def column_widths(headers, rows)
      headers.each_index.map do |index|
        ([headers[index].length] + rows.map { |row| row[index].to_s.length }).max
      end
    end

    def plain_table(headers, rows, widths, alignments)
      [
        format_row(headers, widths, alignments),
        format_row(widths.map { |width| "-" * width }, widths, Array.new(widths.length, :left)),
        *rows.map { |row| format_row(row, widths, alignments) }
      ].join("\n")
    end

    def markdown_table(headers, rows, widths)
      [
        markdown_row(headers, widths),
        markdown_row(widths.map { |width| "-" * width }, widths),
        *rows.map { |row| markdown_row(row, widths) }
      ].join("\n")
    end

    def format_row(row, widths, alignments)
      row.each_with_index.map do |cell, index|
        alignment = alignments[index] || :left
        align_cell(cell.to_s, widths[index], alignment)
      end.join("  ")
    end

    def markdown_row(row, widths)
      cells = row.each_with_index.map { |cell, index| cell.to_s.ljust(widths[index]) }
      "| #{cells.join(" | ")} |"
    end

    def align_cell(text, width, alignment)
      (alignment == :right) ? text.rjust(width) : text.ljust(width)
    end
  end

  # Shared numeric and display formatting helpers for benchmark output.
  class Formatter
    class << self
      def median(values)
        sorted = values.sort
        midpoint = sorted.length / 2
        return sorted[midpoint] if sorted.length.odd?

        (sorted[midpoint - 1] + sorted[midpoint]) / 2.0
      end

      def geometric_mean(values)
        Math.exp(values.sum { |value| Math.log([value, MultiJSONBenchmark::EPSILON].max) } / values.length)
      end

      def format_rate(rate)
        return format("%.2fM", rate / 1_000_000.0) if rate >= 1_000_000
        return format("%.1fk", rate / 1_000.0) if rate >= 1_000

        format("%.0f", rate)
      end

      def human_bytes(bytes)
        return "#{bytes} B" if bytes < 1024
        return format("%.1f KB", bytes / 1024.0) if bytes < 1024 * 1024

        format("%.2f MB", bytes / MultiJSONBenchmark::BYTES_PER_MEGABYTE)
      end
    end
  end
end

exit(MultiJSONBenchmark.run) if $PROGRAM_NAME == __FILE__

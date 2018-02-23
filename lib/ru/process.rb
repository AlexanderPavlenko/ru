require 'optparse'

module Ru
  class Process

    def initialize
      @options        = {}
      @options_parser = OptionParser.new do |opts|
        opts.banner = <<-EOF
          Usage: ru [OPTION]... CODE FILE...
                 cat FILE | ru [OPTION]... CODE
                 echo CODE | ru [OPTION]...
                 echo CODE | ru [OPTION]... '' [FILE...]
        EOF

        opts.on("-h", "Print usage help") do
          @options[:h] = true
        end

        opts.on("--help", "Print examples") do
          @options[:help] = true
        end

        opts.on("-v", "--version", "Print version") do
          @options[:version] = true
        end

        opts.on('-s', '--stream', 'Stream mode') do
          @options[:stream] = true
        end

        opts.on('-b', '--binary', 'Binary mode') do
          @options[:binary] = true
        end

        opts.on('--debug', 'Print debug messages') do
          @options[:debug] = true
          require 'logger'
          $debug = Logger.new($stderr)
          $debug.formatter = proc do |severity, _datetime, _progname, msg|
             "#{severity}: #{msg}\n"
          end
        end
      end
      @option_printer = OptionPrinter.new(options_parser: @options_parser)
    end

    def run
      output = process_options
      return output if output

      args   = ARGV.dup
      code   = args.shift.to_s
      parsed = prepare_code(code) { get_stdin(args, @options[:stream]) }
      $debug.debug parsed.inspect if $debug
      stdin  = parsed[:stdin]

      if parsed[:code].empty?
        $debug.error "CODE is empty" if $debug
        $stderr.puts @option_printer.run(:h)
        exit false
      end

      context =
        if stdin.kind_of?(String) && stdin.empty?
          $debug.info "STDIN is empty" if $debug
          Ru::Array.new([])
        else
          if @options[:stream]
            if @options[:binary]
              $debug.info "binary stream mode" if $debug
              Ru::Stream.new(stdin.each_byte.lazy)
            else
              $debug.info "text stream mode" if $debug
              Ru::Stream.new(stdin.each_line.lazy.map { |line| line.chomp("\n".freeze) })
            end
          else
            if @options[:binary]
              $debug.info "binary mode" if $debug
              Ru::Array.new(stdin.bytes)
            else
              $debug.info "text mode" if $debug
              # Prevent 'invalid byte sequence in UTF-8'
              stdin.encode!('UTF-8', 'UTF-8', invalid: :replace)
              Ru::Array.new(stdin.split("\n"))
            end
          end
        end

      begin
        output = context.instance_eval(parsed[:code])
      rescue NoMethodError
        $debug.info "loading active_support/all" if $debug
        require 'active_support/all'

        output = context.instance_eval(parsed[:code])
      end

      prepare_output(output)
    end

    private

    def prepare_code(code, &block)
      return code unless code.kind_of?(String)
      if code.empty?
        $debug.info "reading CODE from STDIN" if $debug
        stdin_code = $stdin.read
        if stdin_code.empty?
          { code: '', stdin: yield }
        else
          prepare_code(stdin_code, &block)
        end
      elsif code.start_with?('[')
        { code: "to_self#{code}", stdin: yield }
      elsif code.start_with?('=')
        { code: code[1..-1], stdin: '' }
      elsif code.start_with?('!')
        require 'active_support/deprecation'
        ActiveSupport::Deprecation.warn %('!1+2' syntax is going to be replaced with '=1+2')
        { code: code[1..-1], stdin: '' }
      elsif ::File.executable?(code)
        filename = code
        $debug.info "reading CODE from #{filename}" if $debug
        prepare_code(::File.read(filename), &block)
      else
        { code: code, stdin: yield }
      end
    end

    def prepare_output(output)
      if output.respond_to?(:to_stdout)
        $debug.info "serializing with output.to_stdout" if $debug
        output = output.to_stdout
      end
      if output.kind_of?(::Array)
        $debug.info "serializing with output.join" if $debug
        output = output.join("\n")
      end
      output.to_s
    end

    def process_options
      @options_parser.parse!
      $debug.info "options: #{@options.inspect}" if $debug
      @options.each do |option, _value|
        if @option_printer.exists?(option)
          return @option_printer.run(option)
        end
      end
      nil
    end

    def get_stdin(paths, stream)
      if !paths.empty?
        if stream
          $debug.info "opening file #{paths[0].inspect}" if $debug
          ::File.open(paths[0])
        else
          $debug.info "reading files: #{paths.map(&:inspect).join(",\n")}" if $debug
          paths.map { |path| ::File.read(path) }.join("\n")
        end
      else
        if stream
          $debug.info "opening STDIN" if $debug
          $stdin
        else
          $debug.info "reading STDIN" if $debug
          $stdin.read
        end
      end
    end
  end
end

require 'erb'
require 'ostruct'

module Ru
  class OptionPrinter

    attr_accessor :options_parser

    def initialize(options_parser: nil)
      @options_parser = options_parser
    end

    def exists?(option_key)
      !options[option_key].to_s.empty?
    end

    def run(option_key, option_value=nil)
      send(options[option_key], *option_value)
    end

    private

    def options
      {
        h:       :get_usage,
        help:    :get_help,
        version: :get_version
      }
    end

    def get_usage
      options_parser.to_s
    end

    def get_help
      namespace     = OpenStruct.new(version: Ru::VERSION)
      template_path = ::File.expand_path("../../../doc/help.erb", __FILE__)
      template      = ::File.open(template_path).read
      result        = get_usage
      result.concat "\n"
      result.concat ERB.new(template).result(namespace.instance_eval { binding })
      result
    end

    def get_version
      Ru::VERSION
    end
  end
end

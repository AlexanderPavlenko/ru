require 'open3'
require 'pp'

describe 'ru' do

  RU       = 'bin/ru'
  FILE     = 'spec/fixtures/files/test'
  EXPECTED = 'spec/fixtures/files/test-output'
  CODE     = %q('each_with_index.map{ |e,i| [i,%(-),e].join }')
  OUTPUT   = []

  def run(command)
    command = %(bash -c #{command.inspect})
    OUTPUT << '------------'
    OUTPUT << command
    result = {}
    Open3.popen3(command) { |_stdin, stdout, stderr, wait_thr|
      result[:out]    = stdout.read
      result[:err]    = stderr.read
      result[:status] = wait_thr.value # Process::Status
    }
    OUTPUT << '---STDOUT---'
    OUTPUT << result[:out]
    OUTPUT << '---STDERR---'
    OUTPUT << result[:err]
    OUTPUT << "\n\n"
    result
  end

  before do
    Dir.chdir File.expand_path('../../..', __FILE__)
    OUTPUT.clear
  end

  it "works" do
    [
      '--debug',
      '--debug --stream',
      '--debug --binary',
      '--debug --stream --binary',
    ].each do |opts|
      run %(#{RU} #{opts} #{CODE} #{FILE})
      run %(cat #{FILE} | #{RU} #{opts} #{CODE})
      run %(echo #{CODE} | #{RU} #{opts} '' #{FILE})
      run %(echo '1+2' | #{RU} #{opts})
      run %(echo '=1+2' | #{RU} #{opts})
    end

    if File.exist?(EXPECTED)
      expect(File.read(EXPECTED)).to eq OUTPUT.join("\n")
    else
      File.open(EXPECTED, 'w') { |f| f.write(OUTPUT.join("\n")) }
      fail "output recorded, run once again"
    end
  end

  it "works as a shebang script" do
    run %(spec/fixtures/scripts/executable /dev/null)
    expect(OUTPUT).to eq ["------------", "bash -c \"spec/fixtures/scripts/executable /dev/null\"", "---STDOUT---", "1024\n", "---STDERR---", "", "\n\n"]
  end
end

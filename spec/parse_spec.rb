require 'json'
require_relative 'parse_test_format'

RSpec.describe 'Starry.parse_*' do
  context 'structured-field-tests' do
    Dir.glob('./structured-field-tests/*.json') do |f|
      test_cases = JSON.parse(File.read(f))
      context(File.basename(f, '.*')) do
        test_cases.map do |test_case|
          field_value = test_case['raw'].join(', ')
          if test_case['must_fail']
            example test_case['name'] do
              expect do
                Starry.send("parse_#{ test_case['header_type'] }", field_value)
              end.to raise_error(Starry::ParseError)
            end
          else
            data = parse_test(test_case['expected'], test_case['header_type'])
            example test_case['name'] do
              output = Starry.send("parse_#{ test_case['header_type'] }", field_value)
              expect(output).to eq(data)
            end
          end
        rescue NotImplementedTypeError
        end
      end
    end
  end
end

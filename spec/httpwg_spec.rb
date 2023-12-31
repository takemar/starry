require 'json'
require_relative 'parse_httpwg_format'

RSpec.describe 'structured-field-tests' do
  describe 'parse' do
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

  describe 'serialize' do
    Dir.glob('./structured-field-tests/*.json') do |f|
      test_cases = JSON.parse(File.read(f))
      context(File.basename(f, '.*')) do
        test_cases.map do |test_case|
          next if test_case['must_fail']
          data = parse_test(test_case['expected'], test_case['header_type'])
          field_value = (test_case['canonical'] || test_case['raw']).join(', ')
          example test_case['name'] do
            output = Starry.serialize(data).to_s
            expect(output).to eq(field_value)
          end
        rescue NotImplementedTypeError
        end
      end
    end
  end
end

RSpec.describe 'structured-field-tests/serialisation-tests' do
  Dir.glob('./structured-field-tests/serialisation-tests/*.json') do |f|
    test_cases = JSON.parse(File.read(f))
    context(File.basename(f, '.*')) do
      test_cases.map do |test_case|
        data = parse_test(test_case['expected'], test_case['header_type'])
        if test_case['must_fail']
          example test_case['name'] do
            expect do
              Starry.serialize(data)
            end.to raise_error(Starry::SerializeError)
          end
        else
          field_value = test_case['canonical'].join(', ')
          example test_case['name'] do
            output = Starry.serialize(data).to_s
            expect(output).to eq(field_value)
          end
        end
      rescue NotImplementedTypeError
      end
    end
  end
end

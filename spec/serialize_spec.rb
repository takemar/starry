require 'json'
require_relative 'parse_test_format'

RSpec.describe 'Stella.serialize' do
  context 'structured-field-tests' do
    Dir.glob('./structured-field-tests/*.json') do |f|
      test_cases = JSON.parse(File.read(f))
      context(File.basename(f, '.*')) do
        test_cases.map do |test_case|
          next if test_case['must_fail']
          data = parse_test(test_case['expected'], test_case['header_type'])
          field_value = (test_case['canonical'] || test_case['raw']).join(', ')
          example test_case['name'] do
            output = Stella.serialize(data)
            expect(output).to eq(field_value)
          end
        rescue NotImplementedTypeError
        end
      end
    end

    context('serialisation-tests') do
      Dir.glob('./structured-field-tests/serialisation-tests/*.json') do |f|
        test_cases = JSON.parse(File.read(f))
        context(File.basename(f, '.*')) do
          test_cases.map do |test_case|
            data = parse_test(test_case['expected'], test_case['header_type'])
            if test_case['must_fail']
              example test_case['name'] do
                expect do
                  Stella.serialize(data)
                end.to raise_error
              end
            else
              field_value = test_case['canonical'].join(', ')
              example test_case['name'] do
                output = Stella.serialize(data)
                expect(output).to eq(field_value)
              end
            end
          rescue NotImplementedTypeError
          end
        end
      end
    end
  end
end

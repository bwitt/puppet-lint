# Public: Check the manifest tokens for double quoted strings that contain
# a single variable only and record a warning for each instance found.
#
# https://puppet.com/docs/puppet/latest/style_guide.html#quoting
VAR_TYPES = Set[:VARIABLE, :UNENC_VARIABLE]

PuppetLint.new_check(:only_variable_string) do
  def check
    tokens.each do |start_token|
      next unless start_token.type == :DQPRE && start_token.value == ''

      # whitespace inside the braces (`"${ foo }"`) makes the variable a NAME
      var_token = start_token.next_code_token
      next unless VAR_TYPES.include?(var_token.type) || var_token.type == :NAME

      eos_token = var_token.next_code_token
      loop do
        case eos_token&.type
        when :LBRACK
          3.times { eos_token = eos_token&.next_code_token }
        when :DQPOST
          if eos_token.value == ''
            break if eos_token.next_code_token && eos_token.next_code_token.type == :FARROW

            notify(
              :warning,
              message: 'string containing only a variable',
              line: var_token.line,
              column: var_token.column,
              start_token:,
              var_token:,
              end_token: eos_token,
              description: 'Check the manifest tokens for double quoted strings that contain a single variable only and record a warning for each instance found.',
              help_uri: 'https://puppet.com/docs/puppet/latest/style_guide.html#quoting',
            )
          end
          break
        else
          break
        end
      end
    end
  end

  def fix(problem)
    # remove any whitespace inside the braces along with the quotes
    start_idx = tokens.index(problem[:start_token])
    var_idx = tokens.index(problem[:var_token])
    last_idx = tokens.index(problem[:end_token].prev_code_token)
    end_idx = tokens.index(problem[:end_token])
    (tokens[start_idx...var_idx] + tokens[(last_idx + 1)..end_idx]).each { |token| remove_token(token) }

    problem[:var_token].type = :VARIABLE
  end
end

# Public: Check the manifest for unquoted node names and record a warning for
# each instance found.
#
# No style guide reference
NODE_NAME_PART_TYPES = Set[:DOT, :NAME, :NUMBER].freeze

PuppetLint.new_check(:unquoted_node_name) do
  def check
    node_tokens = tokens.select { |token| token.type == :NODE }
    node_tokens.each do |node|
      node_token_idx = tokens.index(node)
      node_lbrace_tok = tokens[node_token_idx..].find { |token| token.type == :LBRACE }
      if node_lbrace_tok.nil?
        notify(
          :error,
          check: :syntax,
          message: 'Syntax error (try running `puppet parser validate <file>`)',
          line: node.line,
          column: node.column,
          description: 'Check for any syntax error and record an error of each instance found.',
          help_uri: nil,
        )
        next
      end

      node_lbrace_idx = tokens.index(node_lbrace_tok)

      # a dotted node name (e.g. foo.example.com) is lexed as several tokens, so only report its first part
      invalid_tokens = tokens[node_token_idx..node_lbrace_idx].select do |token|
        token.type == :NAME && token.value != 'default' && token.prev_token.type != :DOT
      end

      invalid_tokens.each do |token|
        notify(
          :warning,
          message: 'unquoted node name found',
          line: token.line,
          column: token.column,
          token:,
          description: 'Check the manifest for unquoted node names and record a warning for each instance found.',
          help_uri: nil,
        )
      end
    end
  end

  def fix(problem)
    token = problem[:token]
    while NODE_NAME_PART_TYPES.include?(token.next_token&.type)
      token.value += token.next_token.value
      remove_token(token.next_token)
    end
    token.type = :SSTRING
  end
end

require 'spec_helper'

class DummyCheckPlugin < PuppetLint::CheckPlugin
  def check
    # Since we're calling `tokens` from a `check` method, we should get our own Array object.
    # If we add an extra token to it, PuppetLint::Data.tokens should remain unchanged.
    tokens << :extra_token
  end

  def fix
    tokens << :fix_token
  end
end

class DummyFixPlugin < PuppetLint::CheckPlugin
  NAME = :dummy_fix

  def check
    notify(:warning, message: 'foo', line: 1, column: 1, token: tokens[1])
  end

  def fix(problem)
    tokens.insert(tokens.index(problem[:token]), :fix_token)
  end
end

describe PuppetLint::CheckPlugin do
  before(:each) do
    PuppetLint::Data.tokens = [:token1, :token2, :token3]
  end

  it 'returns a duplicate of the token array when called from check' do
    plugin = DummyCheckPlugin.new

    plugin.check

    # Verify that the global token array remains unchanged.
    expect(PuppetLint::Data.tokens).to eq([:token1, :token2, :token3])
  end

  it 'other methods can modify the tokens array' do
    plugin = DummyCheckPlugin.new

    plugin.fix

    expect(PuppetLint::Data.tokens).to eq([:token1, :token2, :token3, :fix_token])
  end

  context 'when the token of a problem has been removed by another fix' do
    it 'does not fix the problem' do
      plugin = DummyFixPlugin.new
      plugin.check
      PuppetLint::Data.tokens.delete(:token2)

      problems = nil
      expect { problems = plugin.fix_problems }.not_to raise_error
      expect(problems.first[:kind]).to eq(:warning)
      expect(PuppetLint::Data.tokens).to eq([:token1, :token3])
    end
  end
end

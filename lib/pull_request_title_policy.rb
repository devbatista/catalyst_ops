# frozen_string_literal: true

module PullRequestTitlePolicy
  AI_MARKERS = %w[
    ai
    ia
    codex
    copilot
    claude
    chatgpt
    gpt
    openai
    gemini
    cursor
    aider
    anthropic
    perplexity
  ].freeze

  AI_MARKER_PATTERN = AI_MARKERS.map { |marker| Regexp.escape(marker) }.join("|")
  BRACKETED_PREFIX_PATTERN = /\A\s*\[(?<marker>[^\]]+)\]/i
  DIRECT_PREFIX_PATTERN = /\A\s*(?<marker>#{AI_MARKER_PATTERN})\s*(?::|-|–|—|\|)/i

  module_function

  def valid?(title)
    invalid_reason(title).nil?
  end

  def invalid_reason(title)
    title = title.to_s

    if bracketed_ai_prefix?(title) || direct_ai_prefix?(title)
      "O título do PR não pode começar com marcador de IA, como [codex], [IA] ou Claude:."
    end
  end

  def bracketed_ai_prefix?(title)
    match = title.match(BRACKETED_PREFIX_PATTERN)
    return false unless match

    match[:marker].match?(/\b(?:#{AI_MARKER_PATTERN})\b/i)
  end

  def direct_ai_prefix?(title)
    title.match?(DIRECT_PREFIX_PATTERN)
  end
end

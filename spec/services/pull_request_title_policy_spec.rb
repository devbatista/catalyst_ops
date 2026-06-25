# frozen_string_literal: true

require "rails_helper"
require Rails.root.join("lib/pull_request_title_policy")

RSpec.describe PullRequestTitlePolicy do
  describe ".valid?" do
    it "bloqueia títulos iniciados com [codex]" do
      expect(described_class.valid?("[codex] Corrige menu de suporte")).to be(false)
    end

    it "bloqueia títulos iniciados com outros marcadores de IA entre colchetes" do
      forbidden_titles = [
        "[IA] Corrige menu de suporte",
        "[AI] Corrige menu de suporte",
        "[Claude] Corrige menu de suporte",
        "[Copilot] Corrige menu de suporte",
        "[ChatGPT] Corrige menu de suporte",
        "[OpenAI] Corrige menu de suporte",
        "[Gemini] Corrige menu de suporte"
      ]

      expect(forbidden_titles).to all(satisfy { |title| !described_class.valid?(title) })
    end

    it "bloqueia títulos iniciados com marcador textual de IA" do
      forbidden_titles = [
        "Codex: Corrige menu de suporte",
        "IA - Corrige menu de suporte",
        "AI | Corrige menu de suporte",
        "Claude — Corrige menu de suporte"
      ]

      expect(forbidden_titles).to all(satisfy { |title| !described_class.valid?(title) })
    end

    it "permite títulos sem marcador de IA no início" do
      allowed_titles = [
        "Corrige menu de suporte",
        "[suporte] Corrige dropdown do menu",
        "Corrige integração de IA no relatório"
      ]

      expect(allowed_titles).to all(satisfy { |title| described_class.valid?(title) })
    end
  end

  describe "GitHub Actions integration" do
    it "mantém o validador conectado ao workflow de PR" do
      workflow = Rails.root.join(".github/workflows/policy-window.yml").read

      expect(workflow).to include("ruby bin/validate_pr_title")
      expect(workflow).to include("- edited")
    end
  end
end

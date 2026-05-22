require "rails_helper"

RSpec.describe UserOnboardingProgress, type: :model do
  describe "associações" do
    it { should belong_to(:user) }
  end

  describe "validações" do
    subject(:progress) { build(:user_onboarding_progress) }

    it { should validate_presence_of(:user_id) }
    it { should validate_uniqueness_of(:user_id) }
    it { should validate_inclusion_of(:last_seen_step).in_array(UserOnboardingProgress::STEP_KEYS).allow_nil }
  end

  describe "progresso" do
    let(:progress) { create(:user_onboarding_progress) }

    it "marca etapa como concluída e informa se era nova" do
      expect(progress.complete_step!(:created_customer)).to be true
      expect(progress.complete_step!("created_customer")).to be false
      expect(progress).to be_completed_step(:created_customer)
      expect(progress.last_seen_step).to eq("created_customer")
    end

    it "normaliza e ignora etapas desconhecidas no hash salvo" do
      progress = create(:user_onboarding_progress, completed_steps: { created_customer: true, unknown: true })

      expect(progress.completed_steps).to eq("created_customer" => true)
    end

    it "calcula percentual de progresso" do
      progress.complete_step!(:created_customer)
      progress.complete_step!(:created_budget)

      expect(progress.progress_percentage).to eq(33)
    end

    it "finaliza quando todas as etapas são concluídas" do
      UserOnboardingProgress::STEP_KEYS.each { |step| progress.complete_step!(step) }

      expect(progress.reload.finished_at).to be_present
      expect(progress).to be_finished_all_steps
    end

    it "permite ocultar e retomar checklist" do
      progress.dismiss!
      expect(progress.dismissed_at).to be_present

      progress.resume!
      expect(progress.dismissed_at).to be_nil
    end

    it "levanta erro para etapa inválida" do
      expect { progress.complete_step!(:invalida) }.to raise_error(ArgumentError, "Invalid onboarding step: invalida")
    end
  end
end

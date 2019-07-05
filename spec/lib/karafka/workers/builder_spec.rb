# frozen_string_literal: true

# Test module that we use to check namespaced consumers
module TestModule
end

RSpec.describe Karafka::Workers::Builder do
  subject(:builder) { described_class.new(consumer_class) }

  let(:consumer_class) { double }

  describe '.new' do
    it 'assigns internally consumer_class' do
      expect(builder.instance_variable_get('@consumer_class')).to eq consumer_class
    end
  end

  describe '#build' do
    subject { builder.build }
    let(:base_worker) { Class.new(Karafka::BaseWorker) }

    before do
      Karafka::BaseWorker.instance_variable_set(:@base_worker, nil)
      base_worker
    end
    after { Karafka::BaseWorker.instance_variable_set(:@base_worker, nil) }


    context 'when the worker class already exists' do
      before { worker_class }

      context 'when it is on a root level' do
        let(:consumer_class) do
          class SuperConsumer
            self
          end
        end

        let(:worker_class) do
          class SuperWorker
            self
          end
        end

        it { is_expected.to eq worker_class }
      end

      context 'when it is in a module/class' do
        let(:consumer_class) do
          module TestModule
            class SuperConsumer
              self
            end
          end
        end

        let(:worker_class) do
          module TestModule
            class SuperWorker
              self
            end
          end
        end

        it { is_expected.to eq worker_class }
      end

      context 'when it is anonymous' do
        let(:consumer_class) { Class.new }
        let(:worker_class) { nil }

        it { is_expected.to be < base_worker }
      end
    end

    context 'when a given worker class does not exist' do
      context 'when it is on a root level' do
        let(:consumer_class) do
          class SuperSadConsumer
            self
          end
        end

        after { Object.__send__(:remove_const, :SuperSadWorker) }

        it 'expect to build it' do
          expect(subject.to_s).to eq 'SuperSadWorker'
        end

        it { is_expected.to be < base_worker }
      end

      context 'when it is in a module/class' do
        let(:consumer_class) do
          module TestModule
            class SuperSad2Consumer
              self
            end
          end
        end

        after { TestModule.__send__(:remove_const, :SuperSad2Worker) }

        it 'expect to build it' do
          expect(subject.to_s).to eq 'TestModule::SuperSad2Worker'
        end

        it { is_expected.to be < base_worker }
      end
    end
  end

  describe '#matcher' do
    it { expect(builder.send(:matcher)).to be_a Karafka::Helpers::ClassMatcher }
  end
end

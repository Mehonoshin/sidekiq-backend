# frozen_string_literal: true

RSpec.describe Karafka::Routing::Builder do
  subject(:builder) { described_class.new }

  ATTRIBUTES = %i[
    consumer
    worker
    deserializer
    interchanger
    responder
  ].freeze

  before { builder.clear }

  after { builder.clear }

  describe '#draw' do
    context 'when we run with 0.5 compatible simple topic style' do
      let(:topic1) { builder.first.topics.first }
      let(:topic2) { builder.last.topics.first }
      let(:consumer_group1) do
        builder.draw do
          topic :topic_name1 do
            # Here we should have instance doubles, etc but it takes
            # shitload of time to setup to pass to instance evaluation from instance variables,
            # so instead we check against constant names
            consumer Class.new(Karafka::BaseConsumer)
            backend :inline
            name 'name1'
            worker :worker1
            deserializer :deserializer1
            interchanger :interchanger1
            responder :responder1
          end
        end
      end
      let(:consumer_group2) do
        builder.draw do
          topic :topic_name2 do
            consumer Class.new(Karafka::BaseConsumer)
            backend :inline
            name 'name2'
            worker :worker2
            deserializer :deserializer2
            interchanger :interchanger2
            responder :responder2
          end
        end
      end

      before do
        consumer_group1
        consumer_group2
      end

      # This needs to have twice same name as for a non grouped in consumer group topics,
      # we build id based on the consumer group id, here it is virtual and built based on the
      # topic name
      it { expect(topic1.id).to eq "#{Karafka::App.config.client_id}_topic_name1_topic_name1" }
      it { expect(topic2.id).to eq "#{Karafka::App.config.client_id}_topic_name2_topic_name2" }
      it { expect(builder.size).to eq 2 }
      it { expect(topic1.name).to eq 'name1' }
      it { expect(topic1.backend).to eq :inline }
      it { expect(topic2.name).to eq 'name2' }
      it { expect(topic2.backend).to eq :inline }
      it { expect(builder.first.id).to eq "#{Karafka::App.config.client_id}_topic_name1" }
      it { expect(builder.last.id).to eq "#{Karafka::App.config.client_id}_topic_name2" }
    end

    context 'when we run with 0.6 simple topic style single topic groups' do
      let(:topic1) { builder.first.topics.first }
      let(:topic2) { builder.last.topics.first }
      let(:consumer_group1) do
        builder.draw do
          consumer_group :group_name1 do
            seed_brokers %w[kafka://localhost:9091]

            topic :topic_name1 do
              consumer Class.new(Karafka::BaseConsumer)
              backend :inline
              name 'name1'
              worker :worker1
              deserializer :deserializer1
              interchanger :interchanger1
              responder :responder1
            end
          end
        end
      end
      let(:consumer_group2) do
        builder.draw do
          consumer_group :group_name2 do
            seed_brokers %w[kafka://localhost:9092]

            topic :topic_name2 do
              consumer Class.new(Karafka::BaseConsumer)
              backend :inline
              name 'name2'
              worker :worker2
              deserializer :deserializer2
              interchanger :interchanger2
              responder :responder2
            end
          end
        end
      end

      before do
        consumer_group1
        consumer_group2
      end

      it { expect(topic1.id).to eq "#{Karafka::App.config.client_id}_group_name1_topic_name1" }
      it { expect(topic2.id).to eq "#{Karafka::App.config.client_id}_group_name2_topic_name2" }
      it { expect(builder.first.seed_brokers).to eq %w[kafka://localhost:9091] }
      it { expect(builder.last.seed_brokers).to eq %w[kafka://localhost:9092] }
      it { expect(builder.size).to eq 2 }
    end

    context 'when we run with 0.6 simple topic style multiple topic group' do
      let(:topic1) { builder.first.topics.first }
      let(:topic2) { builder.first.topics.last }

      before do
        builder.draw do
          consumer_group :group_name1 do
            seed_brokers %w[kafka://localhost:9091]

            topic :topic_name1 do
              consumer Class.new(Karafka::BaseConsumer)
              backend :inline
              name 'name1'
              worker :worker1
              deserializer :deserializer1
              interchanger :interchanger1
              responder :responder1
            end

            topic :topic_name2 do
              consumer Class.new(Karafka::BaseConsumer)
              backend :inline
              name 'name2'
              worker :worker2
              deserializer :deserializer2
              interchanger :interchanger2
              responder :responder2
            end
          end
        end
      end

      it { expect(topic1.id).to eq "#{Karafka::App.config.client_id}_group_name1_topic_name1" }
      it { expect(topic2.id).to eq "#{Karafka::App.config.client_id}_group_name1_topic_name2" }
      it { expect(builder.first.seed_brokers).to eq %w[kafka://localhost:9091] }
      it { expect(builder.size).to eq 1 }
    end

    context 'when it is an invalid route' do
      let(:invalid_route) do
        builder.draw do
          consumer_group '$%^&*(' do
            topic :topic_name1 do
              backend :inline
            end
          end
        end
      end

      it { expect { invalid_route }.to raise_error(Karafka::Errors::InvalidConfigurationError) }
    end
  end

  describe '#active' do
    let(:active_group) { instance_double(Karafka::Routing::ConsumerGroup, active?: true) }
    let(:inactive_group) { instance_double(Karafka::Routing::ConsumerGroup, active?: false) }

    before do
      builder << active_group
      builder << inactive_group
    end

    it 'expect to select only active consumer groups' do
      expect(builder.active).to eq [active_group]
    end
  end
end

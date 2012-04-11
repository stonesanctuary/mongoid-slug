require 'spec_helper'

module Mongoid
  module Slug
    describe Config do
      let(:config) do
        Config.new
      end

      describe 'builder' do
        context 'given a block' do
          let(:builder) do
            Proc.new {}
          end

          let(:config) do
            Config.new &builder
          end

          it 'defines a custom builder' do
            config.builder.should eql builder
          end
        end

        context 'not given a block' do
          it 'defines a default builder' do
            config.builder.should eql Config::BUILDER
          end
        end
      end

      describe '#event' do
        context 'if permanent' do
          let(:config) do
            Config.new :permanent => true
          end

          it 'returns :create' do
            config.event.should eql :create
          end
        end

        context 'if not permanent' do
          it 'returns :create' do
            config.event.should eql :save
          end
        end
      end

      describe '#renamed?' do
        context 'if renamed' do
          let(:config) do
            Config.new :as => :foo
          end

          it 'returns true' do
            config.should be_renamed
          end
        end

        context 'if not renamed' do
          it 'returns false' do
            config.should_not be_renamed
          end
        end

        describe '#reserved_words' do
          context 'if no words are reserved' do
            it 'is empty' do
              config.reserved_words.should be_empty
            end
          end
        end
      end
    end
  end
end

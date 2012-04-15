require 'spec_helper'

module Mongoid
  module Slug
    describe Criterion do
      describe '.find' do
        context 'given a document' do
          let(:klass) do
            Book
          end

          let(:document) do
            klass.create :title => 'Foo'
          end

          before do
            Book.slug :title
          end

          it_behaves_like 'find'
        end

        context 'given an embedded document' do
          let(:klass) do
            Book.create.authors
          end

          let(:document) do
            klass.create :name => 'Foo'
          end

          before do
            Author.slug :name
          end

          it_behaves_like 'find'
        end

        context 'given a deeply embedded document' do
          let(:klass) do
            Person.create.relationships.create.partners
          end

          let(:document) do
            klass.create :name => 'Foo'
          end

          it_behaves_like 'find'
        end

        context 'given a document with a deprecated slug' do
          let!(:book) do
            Book.collection.insert 'title' => 'Foo', 'slug' => 'foo'
            Book.first
          end

          before do
            Book.slug :title
          end

          it 'finds by slug' do
            Book.find('foo').should eql book
          end
        end
      end
    end
  end
end

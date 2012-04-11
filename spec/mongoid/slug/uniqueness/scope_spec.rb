require 'spec_helper'

module Mongoid
  module Slug
    module Uniqueness
      describe Scope do
        subject do
          scope.build
        end

        context 'given an unscoped slug' do
          before do
            Book.slug :title
          end

          let(:document) do
            Book.new
          end

          let(:scope) do
            Scope.new document
          end

          it 'returns the document class' do
            subject.should eql document.class
          end
        end

        context 'given a scoped slug' do
          let(:document) do
            Book.new
          end

          let(:scope) do
            Scope.new document
          end

          context 'given association name' do
            before do
              Book.slug :title, :scope => 'publisher'
            end

            it 'scopes the document class by the reference field' do
              subject.should eq document.class.where('publisher_id' => nil)
            end
          end

          context 'given name of reference field' do
            before do
              Book.slug :title, :scope => 'publisher_id'
            end

            it 'scopes the document class by the reference field' do
              subject.should eq document.class.where('publisher_id' => nil)
            end
          end
        end

        context 'given a slug in an embedded document' do
          before do
            Author.slug :name
          end

          let(:siblings) do
            Book.new.authors
          end

          let(:scope) do
            Scope.new siblings.new
          end

          it 'returns the siblings of the document' do
            subject.should eq siblings
          end
        end

        context 'given a slug in a subclassing document' do
          before do
            Book.slug :title
          end

          let(:superclass) do
            Book
          end

          let(:document) do
            Class.new(superclass)
          end

          let(:scope) do
            Scope.new document.new
          end

          it 'returns the superclass' do
            subject.should eql superclass
          end
        end
      end
    end
  end
end

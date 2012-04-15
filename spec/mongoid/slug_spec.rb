require 'spec_helper'

module Mongoid
  describe Slug do
    describe '.slug' do
      context 'given no name' do
        before do
          Book.slug :title
        end

        it 'uses the default slug name' do
          Book.fields.should have_key Slug::Config::NAME
        end

        it 'defines a scope' do
          Book.should respond_to :by_slug
        end

        it 'defines a finder' do
          Book.should respond_to :find_by_slug
        end
      end

      context 'given a name' do
        let(:name) do
          'permalink'
        end

        before do
          Book.slug :title, :as => name
        end

        it 'uses the new name' do
          Book.fields.should have_key name
        end

        it 'aliases new name to slug' do
          Book.instance_methods.map(&:to_sym).should include :slug
        end

        it 'aliases attribute methods to slug' do
          Book.instance_methods.map(&:to_sym).should include :slug_was
        end

        it 'defines a scope' do
          Book.should respond_to "by_#{name}"
        end

        it 'defines a finder' do
          Book.should respond_to "find_by_#{name}"
        end
      end

      context 'with no index' do
        before do
          Book.slug :title
          Book.create_indexes
        end

        it 'does not define an index on the slug' do
          Book.index_information.should_not have_key 'book_1'
        end
      end

      context 'with an index' do
        context 'when not scoped' do
          before do
            Book.slug :title, :index => true
            Book.create_indexes
          end

          it 'defines a unique index on the slug' do
            Book.index_information['slug_1']['unique'].should be_true
          end
        end

        context 'when scoped' do
          before do
            Book.slug :title, :scope => :publisher, :index => true
            Book.create_indexes
          end

          it 'defines a unique index on the slug and scope' do
            Book.index_information['slug_1_publisher_1']['unique'].should be_true
          end
        end
      end
    end

    describe '.by_slug' do
      before do
        ActiveSupport::Deprecation.silenced = true
        Book.slug :title
      end

      after do
        ActiveSupport::Deprecation.silenced = false
      end

      context 'when a match exists' do
        let!(:book) do
          Book.create :title => 'foo'
        end

        it 'returns a criteria' do
          Book.by_slug('foo').should be_a Mongoid::Criteria
        end
      end

      it 'outputs a deprecation notice' do
        ActiveSupport::Deprecation.should_receive :warn
        Book.by_slug 'foo'
      end
    end

    describe '.find_by_slug' do
      before do
        ActiveSupport::Deprecation.silenced = true
        Book.slug :title
      end

      after do
        ActiveSupport::Deprecation.silenced = false
      end

      context 'when a match exists' do
        let!(:book) do
          Book.create :title => 'foo'
        end

        it 'finds the record' do
          Book.find_by_slug('foo').should eql book
        end
      end

      context 'when a match does not exist' do
        it 'returns nil' do
          Book.find_by_slug('foo').should be_nil
        end
      end

      it 'outputs a deprecation notice' do
        ActiveSupport::Deprecation.should_receive :warn
        Book.find_by_slug 'foo'
      end
    end

    describe '.find_by_slug!' do
      before do
        Book.slug :title
      end

      it 'delegates to find' do
        Book.should_receive :find
        ActiveSupport::Deprecation.silence do
          Book.find_by_slug! 'foo'
        end
      end

      it 'outputs a deprecation notice' do
        ActiveSupport::Deprecation.should_receive :warn
        Book.stub! :find
        Book.find_by_slug! 'foo'
      end
    end

    describe '#build_slug' do
      let(:book) do
        Book.new :slug => ['foo']
      end

      context 'given a slug with no history' do
        before do
          Book.slug :title
        end

        it 'overwrites existing slugs' do
          book.stub!(:find_unique_slug).and_return 'bar'
          book.build_slug
          book.slug.should eql ['bar']
        end

        it 'does not duplicate an existing slug' do
          book.stub!(:find_unique_slug).and_return 'foo'
          book.save
          book.build_slug
          book.slug.should =~ ['foo']
        end
      end

      context 'given a slug with history' do
        before do
          Book.slug :title, :history => true
        end

        it 'appends to existing slugs' do
          book.stub!(:find_unique_slug).and_return 'bar'
          book.build_slug
          book.slug.should eq ['foo', 'bar']
        end

        it 'does not duplicate an existing slug' do
          book.stub!(:find_unique_slug).and_return 'foo'
          book.save
          book.build_slug
          book.slug.should =~ ['foo']
        end
      end

      context 'given a deprecated slug' do
        before do
          Book.slug :title
        end

        let(:book) do
          Book.collection.insert 'title' => 'Foo', 'slug' => 'foo'
          Book.first
        end

        it 'overwrites existing slugs' do
          book.stub!(:find_unique_slug).and_return 'bar'
          book.build_slug
          book.slug.should eql ['bar']
        end

        it 'does not duplicate an existing slug' do
          book.stub!(:find_unique_slug).and_return 'foo'
          book.save
          book.build_slug
          book.slug.should =~ ['foo']
        end
      end
    end

    describe '#find_unique_slug_for' do
      context 'when not scoped' do
        before do
          Book.slug :title
        end

        let(:book) do
          Book.create :title => 'Foo'
        end

        context 'given no duplicate slug' do
          it 'finds a unique slug' do
            book.find_unique_slug_for('Bar').should eql 'bar'
          end
        end

        context 'given a duplicate slug' do
          before do
            Book.create :title => 'Bar'
          end

          it 'finds a unique slug' do
            book.find_unique_slug_for('Bar').should eql 'bar-1'
          end
        end

        it 'ignores current slug of document' do
          book.find_unique_slug_for('Foo').should eql 'foo'
        end
      end

      context 'when scoped' do
        before do
          Book.slug :title, :scope => :publisher
        end

        let(:publisher) do
          Publisher.create
        end

        let(:book) do
          Book.create :title => 'Foo', :publisher => publisher
        end

        context 'given no duplicate slug' do
          it 'finds a unique slug' do
            book.find_unique_slug_for('Bar').should eql 'bar'
          end
        end

        context 'given a duplicate slug' do
          before do
            Book.create :title => 'Bar', :publisher => publisher
          end

          it 'finds a unique slug' do
            book.find_unique_slug_for('Bar').should eql 'bar-1'
          end
        end

        it 'ignores documents not in current scope' do
          Book.create :title => 'Bar'
          book.find_unique_slug_for('Bar').should eql 'bar'
        end

        it 'ignores current slug of document' do
          book.find_unique_slug_for('Foo').should eql 'foo'
        end
      end

      context 'when embedded' do
        before do
          Author.slug :name
        end

        let(:book) do
          Book.create
        end

        let(:author) do
          book.authors.create :name => 'Foo'
        end

        context 'given no duplicate slug' do
          it 'finds a unique slug' do
            author.find_unique_slug_for('Bar').should eql 'bar'
          end
        end

        context 'given a duplicate slug' do
          before do
            book.authors.create :name => 'Bar'
          end

          it 'finds a unique slug' do
            author.find_unique_slug_for('Bar').should eql 'bar-1'
          end
        end

        it 'ignores documents with different parents' do
          Book.create.authors.create :name =>'Bar'
          author.find_unique_slug_for('Bar').should eql 'bar'
        end

        it 'ignores current slug of document' do
          author.find_unique_slug_for('Foo').should eql 'foo'
        end
      end
    end

    describe '#to_param' do
      before do
        Book.slug :title
      end

      context 'when slug is missing' do
        let!(:book) do
          Book.collection.insert 'title' => 'Foo'
          Book.first
        end

        it 'creates the slug' do
          book.to_param
          book.reload.slug.should eql ['foo']
        end
      end

      context 'when slug is a String' do
        let!(:book) do
          Book.collection.insert 'title' => 'Foo', 'slug' => 'foo'
          Book.first
        end

        it 'wraps the slug in an Array' do
          book.to_param
          book.reload.slug.should eql ['foo']
        end
      end
    end
  end
end

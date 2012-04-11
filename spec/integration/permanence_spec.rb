require 'spec_helper'

describe 'Permanent slugs' do
  before do
    Book.slug :title, :permanent => true
  end

  let(:book) do
    Book.create :title => 'Foo'
  end

  context 'when slugged fields change' do
    before do
      book.update_attributes :title => 'Bar'
    end

    it 'does not update the slug' do
      book.to_param.should eql 'foo'
    end
  end
end

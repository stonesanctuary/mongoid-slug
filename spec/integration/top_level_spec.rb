require 'spec_helper'

describe 'A top-level document with a slug' do
  let(:klass) do
    Book
  end

  let(:document) do
    klass.create :title => 'A Thousand Plateaus'
  end

  before do
    klass.slug :title
  end

  it 'generates a slug' do
    document.to_param.should eql 'a-thousand-plateaus'
  end

  it 'updates the slug' do
    document.update_attributes :title => 'Anti Oedipus'
    document.to_param.should eql 'anti-oedipus'
  end

  it 'appends a counter to non-unique slugs' do
    10.times do |x|
      dup = klass.create(:title => document.title)
      dup.to_param.should eql "#{document.to_param}-#{x + 1}"
    end
  end

  context 'when slugged fields have not changed' do
    before do
      document.save
    end

    it 'does not modify slug' do
      document.to_param.should eql 'a-thousand-plateaus'
    end
  end

  context 'when built slug has not changed' do
    before do
      document.update_attributes :title => 'a thousand plateaus'
    end

    it 'does not modify slug' do
      document.to_param.should eql 'a-thousand-plateaus'
    end
  end

  include_examples 'find'
end

require 'spec_helper'

describe 'An embedded document with a slug' do
  let(:parent) do
    Book.create
  end

  let(:klass) do
    parent.authors
  end

  let(:document) do
    klass.create :name => 'Gilles Deleuze'
  end

  before do
    Author.slug :name
  end

  it 'generates a slug' do
    document.to_param.should eql 'gilles-deleuze'
  end

  it 'updates the slug' do
    document.update_attributes :name => 'Felix Guattari'
    document.to_param.should eql 'felix-guattari'
  end

  it 'appends a counter to non-unique slugs' do
    10.times do |x|
      dup = klass.create(:name => document.name)
      dup.to_param.should eql "#{document.to_param}-#{x + 1}"
    end
  end

  include_examples 'find'
end

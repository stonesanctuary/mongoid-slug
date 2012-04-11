require 'spec_helper'

describe 'A deeply-embedded document with a slug' do
  let(:ancestor) do
    Person.create
  end

  let(:parent) do
    ancestor.relationships.create
  end

  let(:klass) do
    parent.partners
  end

  let(:document) do
    klass.create :name => 'John Doe'
  end

  it 'generates a slug' do
    document.to_param.should eql 'john-doe'
  end

  it 'updates the slug' do
    document.update_attributes :name => 'Jane Doe'
    document.to_param.should eql 'jane-doe'
  end

  it 'appends a counter to non-unique slugs' do
    10.times do |x|
      dup = klass.create(:name => document.name)
      dup.to_param.should eql "#{document.to_param}-#{x + 1}"
    end
  end

  it 'scopes by parent' do
    affair = ancestor.relationships.create
    lover  = affair.partners.create(:name => document.name)
    lover.to_param.should eql document.to_param
  end

  include_examples 'find'
end

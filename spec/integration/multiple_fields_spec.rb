# encoding: UTF-8

require 'spec_helper'

describe 'A slug with multiple fields and custom name' do
  let(:klass) do
    Person
  end

  let(:document) do
    klass.create(
      :first => 'Gilles',
      :last  => 'Deleuze')
  end

  it 'generates a slug' do
    document.to_param.should eql 'gilles-deleuze'
  end

  it 'updates the slug' do
    document.first = 'Félix'
    document.last  = 'Guattari'
    document.save
    document.to_param.should eql 'felix-guattari'
  end

  it 'appends a counter to non-unique slugs' do
    10.times do |x|
      dup = klass.create(:first => document.first, :last => document.last)
      dup.to_param.should eql "#{document.to_param}-#{x + 1}"
    end
  end

  include_examples 'find'
end

shared_examples 'find' do
  it 'finds by slug' do
    klass.find(document.to_param).should eql document
  end

  it 'finds by id as string' do
    klass.find(document.id.to_s).should eql document
  end

  it 'finds by id as array of strings' do
    klass.find([document.id.to_s]).should eql [document]
  end

  it 'finds by id as BSON::ObjectId' do
    klass.find(document.id).should eql document
  end

  it 'finds by id as an array of BSON::ObjectIds' do
    klass.find([document.id]).should eql [document]
  end

  it 'returns an empty array if given an empty array' do
    klass.find([]).should eql []
  end
end

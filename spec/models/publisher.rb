class Publisher
  include Mongoid::Document
  references_many :books
end

class Author
  include Mongoid::Document
  include Mongoid::Slug
  field :name
  embedded_in :book
end

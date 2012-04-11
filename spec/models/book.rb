class Book
  include Mongoid::Document
  include Mongoid::Slug
  field :title
  embeds_many :authors
  referenced_in :publisher
end

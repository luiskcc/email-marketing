class Prospect < ApplicationRecord
    validates :email, uniqueness: true, allow_nil: true, allow_blank: true

    belongs_to :user, optional: true

end

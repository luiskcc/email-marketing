class AddExtraFieldsToProspects < ActiveRecord::Migration[7.1]
  def change
    add_column :prospects, :search_term, :string
    add_column :prospects, :ranking, :integer
  end
end

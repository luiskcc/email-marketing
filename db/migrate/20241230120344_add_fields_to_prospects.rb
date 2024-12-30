class AddFieldsToProspects < ActiveRecord::Migration[7.1]
  def change
    remove_column :prospects, :index, :string

    add_column :prospects, :name, :string
    add_column :prospects, :surname, :string
    add_column :prospects, :email, :string
    add_column :prospects, :website, :string
    add_column :prospects, :business_name, :string
    add_column :prospects, :reviews_number, :integer
    add_column :prospects, :rating, :decimal
    add_column :prospects, :top_competitor, :string
    add_column :prospects, :industry, :string
    add_column :prospects, :address, :string
    add_column :prospects, :location, :string
  end
end

class ChangeEmailToTextInProspects < ActiveRecord::Migration[7.1]
  def up
    change_column :prospects, :email, :text
  end

  def down
    change_column :prospects, :email, :string
  end
end

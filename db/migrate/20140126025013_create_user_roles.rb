class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles, :id => false do |t|
      t.references :user, :role
    end
    
    add_index :user_roles, [:user_id, :role_id], :unique => true
  end
end
